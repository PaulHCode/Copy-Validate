<#
.Synopsis
   Copies files and validates the hashes are the same and the source and destination.  If they are different then it re-copies until hashes match.
.DESCRIPTION
   Copies files and validates the hashes are the same and the source and destination.  If they are different then it re-copies.
   Hash validation is bandwidth intensive if being performed over the network.  Hash computation requires significant CPU.
.PARAMETER SourceFolder
    The location to copy from
.PARAMETER DestinationFolder
    The location to copy to
.PARAMETER Files
    Which files to copy.  If not defined then all files are copied.
.PARAMETER Log
    The full path and filename of where to log success/failure to.  If not defined then no longs are stored.
.PARAMETER Recurse
    Copies all files and folders recursively below the source to the destination in the same folder structure.  If the folder structure does not exist in the destination it is created.
.EXAMPLE
   Copy-Validate -Source C:\folder1\ -Destination D:\folder2\

   Copies all files and validates they are correct. If the hashes don't match then it re-copies until it is correct.
.EXAMPLE
   Copy-Validate -Source C:\folder1\ -Destination D:\folder2\ -Files @('file1.txt',"*.html") -Recurse

   Copies file1.txt and all files ending in .html anywhere in folder1 or any of the child directories. If the hashes don't match then it re-copies until it is correct.
#>
function Copy-Validate {
    [CmdletBinding()]
    [Alias("robovalidate")]

    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateScript({ test-path $_ })]
        [string]
        $SourceFolder,
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [ValidateScript({ test-path $_ })]
        [string]
        $DestinationFolder,
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string[]]
        $Files,
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 3)]
        [ValidateScript({ test-path $_ })]
        [string]
        $Log, #Log to $Log only if $Log is defined
        [Parameter(Mandatory = $false)]
        [switch]
        $Recurse
    )
    Begin {
    }
    Process {
        #calculate all files based on literal and *
        #if it contains '*' then do -like, otherwise treat it as a literal
        #Loop through each file
        #calculate the hash of the source file
        #Loop while hashes don't match
        #copy the file
        #calculate the hash of the destionation file


        #Calculate all files to work on
        If ($null -eq $Files) {
            $FilesToProcess = Get-ChildItem $SourceFolder -Recurse:$Recurse -File
        }
        Else {
            $FilesToProcess = @()
            $FilesWithAsterisk = $Files | Where-Object { $_.contains('*') }
            $FilesToProcess += $Files | Where-Object { $_ -notin $FilesWithAsterisk } | ForEach-Object { Join-Path $SourceFolder $_ }
        
            $FilesToProcess += $FilesWithAsterisk | ForEach-Object { Get-ChildItem $SourceFolder -Filter $_ -Recurse:$Recurse }
        }

        If ($Log) {
            "The files to be copied are: $FilesToProcess" | Out-File $Log -Append
        }
        #FilesToProcess now has all the files to copy.  

        $roboSwitches = @("/Z", "/NJH", "NJS")
        If ($Recurse) { $roboSwitches += "/E" }
        If ($Log) { $roboSwitches += @("/TEE", "/Log+:$Log") }

        #Loop through each source file
        $count = 0
        ForEach ($FileToCopy in $FilesToProcess.FullName) {
            Write-Progress -Activity "Copying files from $SourceFolder to $DestinationFolder" -PercentComplete ($count / $($FilesToProcess.Count) * 100) -CurrentOperation "($count/$($FilesToProcess.Count)) - $FileToCopy"
            $SourceHash = Get-FileHash -LiteralPath $($FileToCopy)
            $additionalPath = Split-Path $($FileToCopy.replace($SourceFolder, "")) -Parent #give me the part after $SourceFolder without the file at the end
            $ToFolder = Join-Path $DestinationFolder $additionalPath #everything beyond $SourceFolder, so if it recursed it could be other stuff
            $FromFolder = Split-Path $FileToCopy -Parent
            $Filename = Split-Path $FileToCopy -Leaf
            $roboSplat = @("$FromFolder", "$ToFolder", "$Filename") + $roboSwitches
            #"roboSplat = $roboSplat"
            If (Test-Path $(Join-Path $ToFolder $Filename)) {
                $DestinationHash = Get-FileHash -LiteralPath $(Join-Path $ToFolder $Filename)
            }
            Else {
                $DestinationHash = $Null
            }
            New-DestinationPath $ToFolder
            While ($($SourceHash.hash) -ne $($DestinationHash.hash)) {
                robocopy $roboSplat | Out-Null
                $DestinationHash = Get-FileHash -LiteralPath $(Join-Path $ToFolder $Filename)

                If ($($SourceHash.hash) -ne $($DestinationHash.hash)) {
                    "There was a hash mismatch - re-copying" | Write-Host -ForegroundColor Red -BackgroundColor Black
                }
                #"SourceHash      = $($SourceHash.hash)"
                #"DestinationHash = $($DestinationHash.hash)"
            }
            $count++
        }
        
    }
    End {
        
    }
}

Function New-DestinationPath {
    [cmdletbinding()]
    param(
        [string]
        $Path
    )
    If (!(Test-Path $Path)) {
        If (!(Test-Path (Split-Path $Path -Parent))) {
            "Parent folder    $(Split-Path $Path -Parent) does not exist, calling New-DestinationPath on parent" | Write-Verbose
            New-DestinationPath (Split-Path $Path -Parent)
        }
        "Parent folder    $(Split-Path $Path -Parent) exists: $(Test-Path $(Split-Path $Path -Parent))" | Write-Verbose
        "Trying to create $Path" | Write-Verbose
        $Null = New-Item -Path $Path -ItemType Directory 
    }
}



