Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$imageExtensions = @(
    ".jpg", ".jpeg", ".png", ".gif", ".bmp",
    ".tif", ".tiff", ".heic", ".heif", ".webp", ".dng"
)

$shellApplication = New-Object -ComObject Shell.Application
$shellFolderCache = @{}

function Get-PhotoDate {
    param([System.IO.FileInfo]$File)

    $photoDate = $null
    $usedFallback = $false

    try {
        $directoryPath = $File.DirectoryName

        if (-not $shellFolderCache.ContainsKey($directoryPath)) {
            $shellFolderCache[$directoryPath] =
                $shellApplication.Namespace($directoryPath)
        }

        $shellFolder = $shellFolderCache[$directoryPath]

        if ($null -ne $shellFolder) {
            $shellItem = $shellFolder.ParseName($File.Name)

            if ($null -ne $shellItem) {
                $metadataDate = $shellItem.ExtendedProperty(
                    "System.Photo.DateTaken"
                )

                if ($metadataDate -is [DateTime]) {
                    $photoDate = [DateTime]$metadataDate
                }
                elseif ($null -ne $metadataDate) {
                    $metadataText = [string]$metadataDate
                    $parsedDate = [DateTime]::MinValue

                    $parsedSuccessfully = [DateTime]::TryParse(
                        $metadataText,
                        [Globalization.CultureInfo]::CurrentCulture,
                        [Globalization.DateTimeStyles]::AllowWhiteSpaces,
                        [ref]$parsedDate
                    )

                    if (-not $parsedSuccessfully) {
                        $parsedSuccessfully = [DateTime]::TryParse(
                            $metadataText,
                            [Globalization.CultureInfo]::InvariantCulture,
                            [Globalization.DateTimeStyles]::AllowWhiteSpaces,
                            [ref]$parsedDate
                        )
                    }

                    if ($parsedSuccessfully) {
                        $photoDate = $parsedDate
                    }
                }
            }
        }
    }
    catch {
        $photoDate = $null
    }

    if ($null -eq $photoDate) {
        $photoDate = $File.LastWriteTime
        $usedFallback = $true
    }

    return [PSCustomObject]@{
        Date         = $photoDate
        UsedFallback = $usedFallback
    }
}

function Show-Information {
    param(
        [string]$Message,
        [string]$Title = "Photo Sorter"
    )

    [System.Windows.Forms.MessageBox]::Show(
        $form,
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Show-ErrorMessage {
    param([string]$Message)

    [System.Windows.Forms.MessageBox]::Show(
        $form,
        $Message,
        "Photo Sorter - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

# Main window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Photo Sorter"
$form.Size = New-Object System.Drawing.Size(640, 445)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Sort photos by the date they were taken"
$titleLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    15,
    [System.Drawing.FontStyle]::Bold
)
$titleLabel.Location = New-Object System.Drawing.Point(20, 18)
$titleLabel.Size = New-Object System.Drawing.Size(590, 35)
$form.Controls.Add($titleLabel)

$descriptionLabel = New-Object System.Windows.Forms.Label
$descriptionLabel.Text = @"
Choose a folder containing your photos. They will be organised into folders
such as "2026\2026-01" directly inside the selected folder.
"@
$descriptionLabel.Location = New-Object System.Drawing.Point(22, 60)
$descriptionLabel.Size = New-Object System.Drawing.Size(580, 50)
$form.Controls.Add($descriptionLabel)

$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text = "Photo folder:"
$folderLabel.Location = New-Object System.Drawing.Point(22, 120)
$folderLabel.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($folderLabel)

$folderTextBox = New-Object System.Windows.Forms.TextBox
$folderTextBox.Location = New-Object System.Drawing.Point(22, 148)
$folderTextBox.Size = New-Object System.Drawing.Size(460, 28)
$form.Controls.Add($folderTextBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Location = New-Object System.Drawing.Point(495, 146)
$browseButton.Size = New-Object System.Drawing.Size(105, 32)
$form.Controls.Add($browseButton)

$recursiveCheckBox = New-Object System.Windows.Forms.CheckBox
$recursiveCheckBox.Text = "Include photos inside subfolders"
$recursiveCheckBox.Location = New-Object System.Drawing.Point(22, 195)
$recursiveCheckBox.Size = New-Object System.Drawing.Size(330, 28)
$recursiveCheckBox.Checked = $true
$form.Controls.Add($recursiveCheckBox)

$modeLabel = New-Object System.Windows.Forms.Label
$modeLabel.Text = "What should happen to the original photos?"
$modeLabel.Location = New-Object System.Drawing.Point(22, 235)
$modeLabel.Size = New-Object System.Drawing.Size(370, 25)
$form.Controls.Add($modeLabel)

$modeComboBox = New-Object System.Windows.Forms.ComboBox
$modeComboBox.Location = New-Object System.Drawing.Point(22, 263)
$modeComboBox.Size = New-Object System.Drawing.Size(330, 30)
$modeComboBox.DropDownStyle =
    [System.Windows.Forms.ComboBoxStyle]::DropDownList

[void]$modeComboBox.Items.Add("Move photos (default)")
[void]$modeComboBox.Items.Add("Copy photos")
$modeComboBox.SelectedIndex = 0
$form.Controls.Add($modeComboBox)

$propertyLabel = New-Object System.Windows.Forms.Label
$propertyLabel.Text =
    "Photo metadata is not edited. The original Creation time is preserved."
$propertyLabel.Location = New-Object System.Drawing.Point(22, 305)
$propertyLabel.Size = New-Object System.Drawing.Size(580, 25)
$propertyLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($propertyLabel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Location = New-Object System.Drawing.Point(22, 355)
$statusLabel.Size = New-Object System.Drawing.Size(410, 28)
$form.Controls.Add($statusLabel)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Sorting"
$startButton.Location = New-Object System.Drawing.Point(445, 345)
$startButton.Size = New-Object System.Drawing.Size(155, 42)
$startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$startButton.ForeColor = [System.Drawing.Color]::White
$startButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$form.Controls.Add($startButton)

$browseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description =
        "Select the folder containing the photos you want to sort"
    $folderBrowser.ShowNewFolderButton = $false

    if (
        $folderBrowser.ShowDialog($form) -eq
        [System.Windows.Forms.DialogResult]::OK
    ) {
        $folderTextBox.Text = $folderBrowser.SelectedPath
    }
})

$startButton.Add_Click({
    $sourceFolder = $folderTextBox.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($sourceFolder)) {
        Show-ErrorMessage "Please select a folder first."
        return
    }

    if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) {
        Show-ErrorMessage "The selected folder does not exist."
        return
    }

    $sourceFolder = [System.IO.Path]::GetFullPath(
        $sourceFolder
    ).TrimEnd("\")

    $startButton.Enabled = $false
    $browseButton.Enabled = $false
    $modeComboBox.Enabled = $false
    $recursiveCheckBox.Enabled = $false

    $statusLabel.Text = "Searching for photos..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        if ($recursiveCheckBox.Checked) {
            $allFiles = Get-ChildItem `
                -LiteralPath $sourceFolder `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue
        }
        else {
            $allFiles = Get-ChildItem `
                -LiteralPath $sourceFolder `
                -File `
                -ErrorAction SilentlyContinue
        }

        # Keep supported images and ignore already-sorted photos in:
        # Source\YYYY\YYYY-MM\YYYYMMDD_001.ext
        $photoFiles = @(
            $allFiles | Where-Object {
                $file = $_

                $isSupported =
                    $imageExtensions -contains
                    $file.Extension.ToLowerInvariant()

                $isAlreadySorted = $false
                $monthDirectory = $file.Directory

                if (
                    $null -ne $monthDirectory -and
                    $null -ne $monthDirectory.Parent -and
                    $null -ne $monthDirectory.Parent.Parent
                ) {
                    $yearDirectory = $monthDirectory.Parent

                    $yearParentPath = [System.IO.Path]::GetFullPath(
                        $yearDirectory.Parent.FullName
                    ).TrimEnd("\")

                    $isDirectlyInsideSource =
                        $yearParentPath -ieq $sourceFolder

                    $hasYearFolderName =
                        $yearDirectory.Name -match '^\d{4}$'

                    $hasMonthFolderName =
                        $monthDirectory.Name -match
                        '^\d{4}-(0[1-9]|1[0-2])$'

                    $yearMatchesMonth =
                        $monthDirectory.Name.StartsWith(
                            $yearDirectory.Name + "-"
                        )

                    $hasSortedFileName =
                        $file.BaseName -match '^\d{8}_\d{3,}$'

                    if (
                        $isDirectlyInsideSource -and
                        $hasYearFolderName -and
                        $hasMonthFolderName -and
                        $yearMatchesMonth -and
                        $hasSortedFileName
                    ) {
                        $isAlreadySorted = $true
                    }
                }

                $isSupported -and (-not $isAlreadySorted)
            }
        )

        if ($photoFiles.Count -eq 0) {
            Show-Information @"
No unsorted supported image files were found.

Photos already arranged as YYYY\YYYY-MM\YYYYMMDD_001 are ignored.
"@
            $statusLabel.Text = "No unsorted photos found"
            return
        }

        $records = New-Object System.Collections.Generic.List[object]
        $fallbackCount = 0
        $scanNumber = 0

        foreach ($file in $photoFiles) {
            $scanNumber++
            $statusLabel.Text =
                "Reading photo dates: $scanNumber of $($photoFiles.Count)"
            [System.Windows.Forms.Application]::DoEvents()

            $dateResult = Get-PhotoDate -File $file

            if ($dateResult.UsedFallback) {
                $fallbackCount++
            }

            $records.Add([PSCustomObject]@{
                File                    = $file
                PhotoDate               = $dateResult.Date
                UsedFallback            = $dateResult.UsedFallback
                OriginalCreationTimeUtc = $file.CreationTimeUtc
            })
        }

        $isCopyMode = $modeComboBox.SelectedIndex -eq 1

        if ($isCopyMode) {
            $actionName = "Copy"
            $actionDescription = @"
Copies of the photos will be placed into the date folders.
The originals will remain in their current locations.
"@
        }
        else {
            $actionName = "Move"
            $actionDescription = @"
The original photos will be sorted and moved into date folders.
"@
        }

        $confirmationText = @"
Found $($records.Count) photo(s).

ACTION: $actionName

$actionDescription

The photos will be organised directly inside:

$sourceFolder

Do you want to continue?
"@

        $confirmation = [System.Windows.Forms.MessageBox]::Show(
            $form,
            $confirmationText,
            "Confirm Photo Sorting",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if (
            $confirmation -ne
            [System.Windows.Forms.DialogResult]::Yes
        ) {
            $statusLabel.Text = "Cancelled"
            return
        }

        $sortedRecords = @(
            $records | Sort-Object `
                @{ Expression = { $_.PhotoDate } },
                @{ Expression = { $_.File.FullName } }
        )

        $dailyCounters = @{}
        $logLines = New-Object System.Collections.Generic.List[string]

        $logLines.Add("Photo Sorter log")
        $logLines.Add("Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $logLines.Add("Selected folder: $sourceFolder")
        $logLines.Add("Action: $actionName")
        $logLines.Add("")

        $successCount = 0
        $errorCount = 0
        $warningCount = 0
        $itemNumber = 0

        foreach ($record in $sortedRecords) {
            $itemNumber++
            $file = $record.File
            $photoDate = $record.PhotoDate

            $statusLabel.Text =
                "Sorting photo $itemNumber of $($sortedRecords.Count)"
            [System.Windows.Forms.Application]::DoEvents()

            try {
                # Example destination: Source\2026\2026-01
                $yearFolderName = $photoDate.ToString("yyyy")
                $yearFolder = Join-Path $sourceFolder $yearFolderName

                $monthFolderName = $photoDate.ToString("yyyy-MM")
                $monthFolder = Join-Path $yearFolder $monthFolderName

                $dateKey = $photoDate.ToString("yyyyMMdd")

                [System.IO.Directory]::CreateDirectory($monthFolder) |
                    Out-Null

                if (-not $dailyCounters.ContainsKey($dateKey)) {
                    $largestExistingNumber = 0

                    $existingFiles = Get-ChildItem `
                        -LiteralPath $monthFolder `
                        -File `
                        -ErrorAction SilentlyContinue

                    $namePattern =
                        "^" + [Regex]::Escape($dateKey) + "_(\d{3,})\."

                    foreach ($existingFile in $existingFiles) {
                        if ($existingFile.Name -match $namePattern) {
                            $existingNumber = [int]$Matches[1]

                            if (
                                $existingNumber -gt
                                $largestExistingNumber
                            ) {
                                $largestExistingNumber = $existingNumber
                            }
                        }
                    }

                    $dailyCounters[$dateKey] =
                        $largestExistingNumber
                }

                do {
                    $dailyCounters[$dateKey]++
                    $sequenceNumber = $dailyCounters[$dateKey]
                    $numberText = $sequenceNumber.ToString("D3")

                    $newFileName =
                        "${dateKey}_${numberText}$($file.Extension.ToLowerInvariant())"

                    $targetPath = Join-Path $monthFolder $newFileName
                }
                while (Test-Path -LiteralPath $targetPath)

                if ($isCopyMode) {
                    Copy-Item `
                        -LiteralPath $file.FullName `
                        -Destination $targetPath `
                        -ErrorAction Stop
                }
                else {
                    Move-Item `
                        -LiteralPath $file.FullName `
                        -Destination $targetPath `
                        -ErrorAction Stop
                }

                $creationTimePreserved = $true

                try {
                    [System.IO.File]::SetCreationTimeUtc(
                        $targetPath,
                        $record.OriginalCreationTimeUtc
                    )
                }
                catch {
                    $creationTimePreserved = $false
                    $warningCount++
                }

                $notes = ""

                if ($record.UsedFallback) {
                    $notes += " [Used Modified Date]"
                }

                if (-not $creationTimePreserved) {
                    $notes += " [Could not restore Creation time]"
                }

                $logLines.Add(
                    "OK | $($file.FullName) | $targetPath$notes"
                )
                $successCount++
            }
            catch {
                $errorCount++
                $logLines.Add(
                    "ERROR | $($file.FullName) | $($_.Exception.Message)"
                )
            }
        }

        # Delete empty folders after moving.
        $deletedFolderCount = 0

        if (-not $isCopyMode) {
            $statusLabel.Text = "Removing empty folders..."
            [System.Windows.Forms.Application]::DoEvents()

            $folders = @(
                Get-ChildItem `
                    -LiteralPath $sourceFolder `
                    -Directory `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue |
                Sort-Object { $_.FullName.Length } -Descending
            )

            foreach ($folder in $folders) {
                try {
                    # Never follow or delete junctions/symbolic links.
                    if (
                        ($folder.Attributes -band
                        [System.IO.FileAttributes]::ReparsePoint) -ne 0
                    ) {
                        continue
                    }

                    $contents = @(
                        [System.IO.Directory]::EnumerateFileSystemEntries(
                            $folder.FullName
                        )
                    )

                    if ($contents.Count -eq 0) {
                        Remove-Item `
                            -LiteralPath $folder.FullName `
                            -Force `
                            -ErrorAction Stop

                        $deletedFolderCount++
                        $logLines.Add(
                            "DELETED EMPTY FOLDER | $($folder.FullName)"
                        )
                    }
                }
                catch {
                    $logLines.Add(
                        "COULD NOT DELETE FOLDER | $($folder.FullName) | $($_.Exception.Message)"
                    )
                }
            }
        }

        $logTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $logPath = Join-Path `
            $sourceFolder `
            "PhotoSorter_Log_$logTimestamp.txt"

        $logLines.Add("")
        $logLines.Add("Successfully processed: $successCount")
        $logLines.Add("Errors: $errorCount")
        $logLines.Add("Creation-time warnings: $warningCount")
        $logLines.Add("Used Modified Date: $fallbackCount")
        $logLines.Add("Empty folders deleted: $deletedFolderCount")

        $logLines | Set-Content `
            -LiteralPath $logPath `
            -Encoding UTF8

        $statusLabel.Text = "Finished"

        $completionMessage = @"
Photo sorting is complete.

Successfully processed: $successCount
Errors: $errorCount
Creation-time warnings: $warningCount
Used Modified Date: $fallbackCount
Empty folders deleted: $deletedFolderCount

Inside:
$sourceFolder

Log file:
$logPath
"@

        Show-Information $completionMessage "Photo Sorting Complete"
    }
    catch {
        $statusLabel.Text = "Error"
        Show-ErrorMessage $_.Exception.Message
    }
    finally {
        $startButton.Enabled = $true
        $browseButton.Enabled = $true
        $modeComboBox.Enabled = $true
        $recursiveCheckBox.Enabled = $true
    }
})

[void]$form.ShowDialog()

if ($null -ne $shellApplication) {
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject(
        $shellApplication
    )
}
