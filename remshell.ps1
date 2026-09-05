$REMOTE_HOST = ""
if(!$REMOTE_HOST) { $REMOTE_HOST = "192.168.50.112" }

$REMOTE_USER = ""
if(!$REMOTE_USER) { $REMOTE_USER = "rhale" }

# Runs a command line on the remote host over SSH, optionally feeding it stdin.
# Relies on the user's own SSH keys/agent being configured (non-interactive auth).
function Invoke-Remote {
    param(
        [string]$RemoteCmd,
        [string]$StdinData = $null,
        [bool]$HasStdin = $false
    )

    if (!$REMOTE_HOST) {
        write-host "No REMOTE_HOST set. Use REMOTE_HOST=<host> first." -ForegroundColor Yellow
        return
    }

    # Build the ssh target: user@host when a user is set, otherwise just host
    # (falls back to whatever your ssh config specifies for that host).
    if ($REMOTE_USER) {
        $target = "$REMOTE_USER@$REMOTE_HOST"
    } else {
        $target = $REMOTE_HOST
    }

    # BatchMode=yes fails fast instead of prompting for a password when keys are missing.
    # NOTE: Windows OpenSSH does not support ControlMaster/ControlPath multiplexing
    # (it errors with "getsockname failed: Not a socket"), so each remote command
    # opens its own connection. Multiplexing intentionally left out for compatibility.
    $sshArgs = @(
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        $target,
        $RemoteCmd
    )

    if ($HasStdin) {
        # Pipe the captured local output into the remote command's stdin.
        $StdinData | & ssh @sshArgs
    } else {
        & ssh @sshArgs
    }
}

while ( 1 ) {
   # Write the prompt manually (no newline) so we get a bare '>' without the
   # ': ' that Read-Host appends to its prompt string.
   Write-Host "> " -NoNewline
   $cmdstr = Read-Host

   if ( $cmdstr -match "^exit"){
    exit
   }

   if ($cmdstr -match "^help"){
      write-host "REMOTE SHELL RESOURCE V1.0"
      write-host "COMMANDS/Examples:"
      write-host "REMOTE_HOST=192.168.0.32........Assigns remote"
      write-host "REMOTE_USER=rhale...............Assigns remote user"
      write-host "local cmd || remote cmd.........runs local, pipes stdout to remote"
      write-host "|| remote cmd...................runs command directly on remote"
      write-host "exit............................exits shell"
      write-host ""
      write-host "NOTE: You must install your own keys on remotes to work"
      write-host "NOTE: If piped local output has stray CR, append | tr -d '\r' on the remote side"
      continue
   }

   if ($cmdstr -match "^REMOTE_HOST="){
      # STRING EXTRACT THE REMOTE HOST AND ASSIGN AS THE REMOTE HOST
      $null = $cmdstr -match '=(.*)'
      $REMOTE_HOST = $matches[1].Trim()
      write-host "REMOTE_HOST set to $REMOTE_HOST"
      continue
   }

   if ($cmdstr -match "^REMOTE_USER="){
      # STRING EXTRACT THE REMOTE USER AND ASSIGN AS THE REMOTE USER
      $null = $cmdstr -match '=(.*)'
      $REMOTE_USER = $matches[1].Trim()
      write-host "REMOTE_USER set to $REMOTE_USER"
      continue
   }

   if ($cmdstr -match "\|\|"){
      # LOCAL || REMOTE  -- one-way boundary.
      # A leading || (empty local side) means: run the whole line on the remote.
      # Limit to 2 parts so pipes inside the remote side (grep|sort|uniq) survive.
      $parts = $cmdstr -split [regex]::Escape("||"), 2
      $LOCAL_CMD  = $parts[0].Trim()
      $REMOTE_CMD = $parts[1].Trim()

      if (!$REMOTE_CMD) {
         write-host "Nothing on the remote side of ||" -ForegroundColor Yellow
         continue
      }

      if ($LOCAL_CMD) {
         # Run the local command, capture its stdout, then stream it to the remote stdin.
         $localOutput = Invoke-Expression $LOCAL_CMD | Out-String
         Invoke-Remote -RemoteCmd $REMOTE_CMD -StdinData $localOutput -HasStdin $true
      } else {
         # Empty local side: just run the remote command with no stdin.
         Invoke-Remote -RemoteCmd $REMOTE_CMD -HasStdin $false
      }
      continue
   }

   # No || boundary: run entirely on the local machine.
   if ($cmdstr.Trim()) {
      Invoke-Expression $cmdstr
   }
}
