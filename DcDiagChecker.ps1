#Define variables that will be used throughout the script.
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

#EntryType can be changed to whichever entry type you want to use. (ex: Informational, Warning, etc...)
$EntryType = "Error"

#Message should be changed to a message that is meaningful to you. This is only an example.
$Message = "DCDIAG Detected Errors in Active Directory. Check $Path\$date.txt for full dcdiag results."

#Pattern can be changed to whatever word you want to look for in the dcdiag file that gets generated.
$Pattern = "fail"

#$FileAgeLimit can be changed to however long you want to retain dcdiag records. Set to 30 by default.
$FileAgeLimit = "-30"

#Todays date. $Date is formatted, whereas $TodaysDate is not formatted. I do not recommend changing this.
$TodaysDate = Get-Date

#Variable for deleting files older than todays date - $FileAgeLimit.
$DeleteFilesOlderThan = $TodaysDate.AddDays($FileAgeLimit)

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


#Run a full, verbose, DCDIAG and output the results to a txt file called $Date.txt in $Path. /c = full DCDIAG. /v = verbose.
dcdiag /c /v | out-file -FilePath $("$Path\$Date.txt")


#Parse the $Date.txt file for any variation of the word $Pattern. If $Pattern is detected, create an $EntryType in the $LogName event log with event ID $EventID.
if(Get-ChildItem "$Path\$Date.txt" | Select-String -pattern $Pattern -quiet)
{
      Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryType -Message $Message
}
else
{
    #Do Nothing
}

#You should create a task in your monitoring system that checks the $LogName event logs for event ID $EventID, and alerts you if the event is detected. You can also add code to use powershell
#to send you an email if that is preferred.

#Parse the $Path directory for files older than 30 days. If any files exist that are older than 30 days, they are deleted.
Get-ChildItem $Path | Where-Object { $_.LastWriteTime -lt $DeleteFilesOlderThan } | Remove-Item
