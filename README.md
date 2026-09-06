This utility runs on Windows and allows you to pipe local data over to remote hosts via SSH.
For windows hosts where you can't or don't want to install some tools it allows you to use remote command line tools.
Note this requires ssh keys being installed locally on windows to allow for seamless piping.

To install SSH keys on windows type:  ssh-keygen
Then distribute the key to the far end .ssh/authorized_keys file.

<pre>
Example:

powershell -f remshell.ps1
>
>type myfile.txt || grep -i somedata |sort|uniq

This would allow you to read the local windows file data into a pipe and send it remote to the far end executing grep, sort, and uniq on the data piped.
Then returns the stdout.



C:\Users\myuser>powershell -f remshell.ps1
> help
REMOTE SHELL RESOURCE V1.0
COMMANDS/Examples:
REMOTE_HOST=192.168.0.32........Assigns remote
REMOTE_USER=myusername...............Assigns remote user
local cmd || remote cmd.........runs local, pipes stdout to remote
|| remote cmd...................runs command directly on remote
exit............................exits shell

NOTE: You must install your own keys on remotes to work
NOTE: If piped local output has stray CR, append | tr -d '\r' on the remote side


