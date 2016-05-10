# Docker Container Lifecycle Management at the Command Line

For ease of instantiating an instance of the container image a script named
'container.sh' can be used to manage the entire lifecycle. For Microsoft Windows
users it is recommended that [Git Bash](https://git-for-windows.github.io/) be
installed instead of the standard [Git](https://git-scm.com) software because
it provides an *nix-like command line environment.

Create the container, optionally mapping a host file system share for storage.
The file system share name '/home/me/statistics' is user selectable and host
file system dependent. If no local file system share is desired simply omit the
fourth argument '/home/me/data'. The container instance name 'toolbox',
in these instructions, is user selectable at time of creation.

     $ ./container.sh create toolbox [gdhorne/]sample-container /home/me/data

*Apple Mac OS X: /Users/username/directory*
*GNU/Linux: /home/username/directory*
*Microsoft Windows: /c/Users/directory (allegedly)*

Verify the container 'toolbox' has been successfully created and is running

     $ ./container.sh status

Stop the container 'toolbox'.

	$ ./container.sh stop toolbox

Start the container 'toolbox'.

	$ ./container.sh start toolbox

To learn more about the container lifecycle management features supported by 'container.sh' type,

	$ ./container.sh --help

The content of this README file may be used as part of your own documentation without attribution and
is not subject to the LICENSE accompanying the software.

