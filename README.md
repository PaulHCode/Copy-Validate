# Copy-Validate


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

