#--------------------------------------------------------------#
#Section 1 
#Define Variables That Are Used Throughout The Script.
#--------------------------------------------------------------#


#Path can be changed to whatever path you want to use on your servers.
$Path = "C:\admin\dcdiaglogs"

#Date can be changed or reformatted.
$Date = (Get-Date).ToString(“MM/dd/yyyy”).Replace(“/”,”-“)

#Source can be changed to whichever source you want to use.
$Source = "DCDIAG"

#EventID can be changed to whichever event ID you want to use. (1-65535)
$EventID = 65535

#LogName can be changed to whichever log you want to write to. (ex: Application, Security, etc...)
$LogName = "System"

#EntryTypeError can be changed to whichever entry type you want to use for DCDIAG errors. (ex: Informational, Warning, etc...)
$EntryTypeError = "Error"

#EntryTypeSuccess can be changed to whichever entry type you want to use for successful DCDIAGs without errors. I recommend keeping this Information.
$EntryTypeSuccess = "Information"

#MessageError should be changed to an error message that is meaningful to you. This is only an example.
$MessageError = "DCDIAG Detected Errors in Active Directory. Check $Path\$date.txt for full dcdiag results."

#MessageSuccess should be changed to a successful message that is meaningful to you. This is only an example.
$MessageSuccess = "DCDIAG ran and did not detect the word $Pattern in the log file."

#Pattern can be changed to whatever word you want to look for in the dcdiag file that gets generated.
$Pattern = "fail"

#$FileAgeLimit can be changed to however long you want to retain dcdiag records. Set to 30 by default.
$FileAgeLimit = "-30"

#Todays date. $Date is formatted, whereas $TodaysDate is not formatted. I do not recommend changing this.
$TodaysDate = Get-Date

#Variable for deleting files older than todays date - $FileAgeLimit.
$DeleteFilesOlderThan = $TodaysDate.AddDays($FileAgeLimit)

#Default AD NTDS Directory
$NTDSDirectory = "c:\windows\NTDS"


#--------------------------------------------------------------#
#Section 2
#Determine Whether The Server Is An AD Server Or Not
#--------------------------------------------------------------#


#Verify whether the server is an AD server or not by checking if c:\windows\NTDS exists. If it does not exist, the code exits immediately.
if([IO.Directory]::Exists($NTDSDirectory))
{
    #Do Nothing
}
else
{
    exit
}


#--------------------------------------------------------------#
#Section 3
#Create Directories & Event Log Sources If Necessary
#--------------------------------------------------------------#


#Check if the $Path directory exists. If the directory exists, nothing happens. If the directory does not exist, it is created.
if([IO.Directory]::Exists($Path))
{
    #Do Nothing
}
else
{
    New-Item -ItemType directory -Path $Path
}

#Check if the event log source $Source exists. If the source exists, nothing happens. If the source does not exist, it is created.
if ([System.Diagnostics.EventLog]::SourceExists($Source) -eq $False) 
{
    New-EventLog -LogName $LogName -Source $Source
}
else
{
    #Do Nothing
}


#--------------------------------------------------------------#
#Section 4
#Run DCDIAG
#--------------------------------------------------------------#


#Run a full, verbose, DCDIAG and output the results to a txt file called $Date.txt in $Path. /c = full DCDIAG. /v = verbose.
dcdiag /c /v | out-file -FilePath $("$Path\$Date.txt")


#--------------------------------------------------------------#
#Section 5
#Check DCDIAG For Errors
#--------------------------------------------------------------#


#Parse the $Date.txt file for any variation of the word $Pattern. If $Pattern is detected, create an $EntryTypeError in the $LogName event log with event ID $EventID.
#If $Pattern is not detected, create an $EntryTypeSuccess in $LogName event log with event ID $EventID
if(Get-ChildItem "$Path\$Date.txt" | Select-String -pattern $Pattern -quiet)
{
      Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryTypeError -Message $MessageError
}
else
{
      Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryTypeSuccess -Message $MessageSuccess
}

#You should create a task in your monitoring system that checks the $LogName event logs for event ID $EventID, and alerts you if the event is detected. 
#You can also add code to use powershell to send you an email if that is preferred. Sample Powershell Send-MailMessage code is below.
#The sample code has not been tested and is commented out since I do not require emails for these alerts.

#Send-MailMessage -From 'User01 ' -To 'User02 ', 'User03 ' -Subject 'DCDIAG Failed' -Body $MessageError -Attachments $Path\$Date.txt -Priority High -SmtpServer 'smtp.domain.com'

#--------------------------------------------------------------#
#Section 6
#Delete Old DCDIAG Files
#--------------------------------------------------------------#


#Parse the $Path directory for files older than 30 days. If any files exist that are older than 30 days, they are deleted.
Get-ChildItem $Path | Where-Object { $_.LastWriteTime -lt $DeleteFilesOlderThan } | Remove-Item
