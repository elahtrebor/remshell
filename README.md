This utility runs on Windows and allows you to pipe local data over to remote hosts via SSH.
For windows hosts where you can't or don't want to install some tools it allows you to use remote command line tools.

Example:

type myfile.txt || grep -i somedata |sort|uniq

This would allow you to read the local windows file data into a pipe and send it remote to the far end executing grep, sort, and uniq on the data piped.
Then returns the stdout.

