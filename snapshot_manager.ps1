# Step 1: Create snapshots of all VMs on the disk and log the results locally
# Step 2: Notify your Slack channel of the snapshot creations
# Step 3: Purge older snapshots

## Create snapshots of all VMs on the disk and log the results locally
# Define log file path
$logFilePath = ""

# Initialize an empty log array
$log = @()

# Array of snapshot names
$snapshotNames = @("VM1", "VM2", "VM3") #replace with your VMs

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    
    # Get current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Create log entry
    $logEntry = "$timestamp - $message"
    
    # Output to console
    Write-Host $logEntry
    
    # Append to log file
    $logEntry | Out-File -FilePath $logFilePath -Append
}

# Function to create a checkpoint
function Create-Checkpoint {
    param (
        [string]$snapshotName
    )
    try {
        # take snapshot for each VM
        foreach ($VMName in $snapshotName) {
            Checkpoint-VM -Name $VMName -SnapshotName "Weekly Snapshot $((Get-Date).ToShortDateString())"
            Log-Message "Snapshot for $VMName creation completed successfully."
        }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Message "Error: $errorMessage"
    }
}

# Loop through each snapshot name and create a checkpoint
foreach ($snapshotName in $snapshotNames) {
    Create-Checkpoint -snapshotName $snapshotName
}


## Notify your Slack channel of the snapshot creations
# Slack webhook URL
$slackWebhookUrl = ""

$logContent = Get-Content -Path $logFilePath -Tail 1

# Message to post to Slack
$slackMessage = @{
    text = "Log Report: $logContent"
}

# Convert message to JSON
$jsonMessage = $slackMessage | ConvertTo-Json

# Send the message to Slack
Invoke-RestMethod -Uri $slackWebhookUrl -Method POST -ContentType "application/json" -Body $jsonMessage


## Purge older snapshots
# Set the number of most recent snapshots to keep
$keepSnapshots = #

# Get all the virtual machines on the disk
$vms = Get-VM

# Loop through each virtual machine and delete excess snapshots
foreach ($vm in $vms) {
    # Get all the snapshots for the virtual machine
    $snapshots = $vm | Get-VMSnapshot | Sort-Object -Property CreationTime -Descending

    # Determine the number of snapshots to delete
    $numSnapshotsToDelete = $snapshots.Count - $keepSnapshots

    # Delete the excess snapshots
    if ($numSnapshotsToDelete -gt 0) {
        $snapshotsToDelete = $snapshots[-$numSnapshotsToDelete..-1]
        foreach ($snapshot in $snapshotsToDelete) {
            Write-Output "Deleting snapshot $($snapshot.Name) for VM $($vm.Name)"
            $snapshot | Remove-VMSnapshot -Confirm:$false
        }
    } else {
        Write-Output "No snapshots to delete for VM $($vm.Name)"
    }
}

Exit 0 

