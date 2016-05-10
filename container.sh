#!/bin/bash

###############################################################################
# Docker Container Lifecycle Management										  #
#                                                                             #
# Version 0.1, Copyright (C) 2015 Gregory D. Horne                            #
#                                 (horne at member dot fsf dot org)           #
#                                                                             #
# Licensed under the terms of the GNU General Public License (GPL) v2         #
###############################################################################

###############################################################################
# Display information banner.												  #
###############################################################################

function display_banner() {

	echo
	echo "Docker Container Lifecycle Management"
	echo "version 0.1, Copyright (C) 2015 Gregory D. Horne"
	echo
	echo "Docker Container Lifecycle Management comes with ABSOLUTELY NO"
	echo "WARRANTY;for details read the LICENSE file."
	echo "This is free software, and you are welcome to redistribute it"
	echo "under certain conditions; read the LICENSE for details."

	# application specific name / branding / license / disclaimer may be
	# added as echo statements; leave two blank echo statements afterwards

	# change/delete port and volume keys and values as appropriate in the
	# 'create container' section of manage_container()

	echo
	echo
}

###############################################################################
# Process container lifecycle management requests.							  #
#																			  #
# Parameters:																  #
# 	${1}: command															  #
# 	${2}: container instance name (optional only for command 'status')		  #
# 	${3}: container image name (optional)									  #
# 	${4}: host file system share (optional)									  #
###############################################################################

function manage_container() {

	local retcode=0
	
	if [[ ${1} != "attach" && ${1} != "create" && ${1} != "detach" && \
		${1} != "kill" && ${1} != "pause" && ${1} != "unpause" && \
		${1} != "start" && ${1} != "stop" && ${1} != "status" ]]
	then
		echo "Error: invalid command/action. Type 'container.sh --help'"
		exit -1
	elif [[ ${1} != "status" && -z ${2} ]]
	then
		echo -n "Error: 'container ${1}' requires a container name or "
		echo "id as the second argument"
		echo "       (e.g.) container ${1} toolbox"
	fi

	case ${1} in
		attach)
			if [[ -z `docker ps --filter=name=${2} | \
				grep --ignore-case paused` && \
			       	-z `docker ps --all=true | grep ${2} | \
				grep --ignore-case exited` ]]
			then
				echo "Attaching to existing container [${2}]."
				echo "Press ENTER to continue."
				docker attach ${2}
			else
				echo "Error: Container [${2}] is not running."
				retcode=-1
			fi
			;;
		create)
			if [[ -z `docker ps --all=true | grep ^${2}` ]]
			then
				echo "Building/fetching container image [${3}]."
				if [[ -z `docker images | \
					grep ^${3%:*} | \
				       	cut -d\  -f1` ]]
				then
					if [[ ! -z `echo ${3} | grep /`  ]]
					then
						docker pull ${3}
					else
						docker build -t ${3} .
					fi
				fi
				echo "Creating container [${2}]."
				if [[ -z ${4} ]]
				then
					docker run \
							--detach=true \
							--hostname=${2} \
							--interactive=true \
							--tty=true \
							--publish=80:80 \
							--name=${2} \
							${3}
				else
					docker run \
							--detach=true \
							--hostname=${2} \
							--interactive=true \
							--tty=true \
							--publish=80:80 \
							--name=${2} \
							--volume=${4}:/fully_qualified_datashare_path \
							${3}
				fi
			else
				echo -n "Error: Container with name [${2}] "
				echo "already exists."
				retcode=-1
			fi
			;;
		kill)
			if [[ ! -z `docker ps --filter=name=${2} | grep ${2}` ]]
			then
				if [[ -z `docker ps --filter=name=${2} | \
					grep --ignore-case paused` ]]
				then
					echo "Terminating container [${2}]."
					docker stop ${2} > /dev/null 2>&1
					docker rm ${2} > /dev/null 2>&1
				elif [[ ! -z `docker ps --filter=name=${2} | \
					grep --ignore-case paused` ]]
				then
					echo -n "Error: Container [${2}] must be running or stopped."
				fi
			elif [[ ! -z `docker ps --all | grep ${2}` ]]
			then
				echo "Terminating container [${2}]."
				docker rm ${2} > /dev/null 2>&1
			else
				echo "Error: Container [${2}] does not exist."
				retcode=-1
			fi
			;;
		pause)
			if [[ ! -z `docker ps --filter=name=${2}` ]]
			then
				if [[ ! -z `docker ps --all --filter=name=${2} | grep ${2} | \
					grep --ignore-case --invert-match paused` &&  \
					! -z `docker ps --all --filter=name=${2} | grep ${2} | \
					grep --ignore-case --invert-match exited` ]]
				then
					echo "Pausing container [${2}]."
					docker pause ${2} > /dev/null 2>&1
				elif [[ -z `docker ps --all --filter=name=${2} | grep ${2}` ]]
				then
					echo "Error: Container [${2}] does not exist."
				else
					echo -n "Error: Container [${2}] is not running and cannot be stopped."
					retcode=-1
				fi
			elif [[ ! -z `docker ps --all | grep ${2}` ]]
			then
				echo -n "Error: Container [${2}] is not running and cannot be stopped."
			else
				echo "Error: Container [${2}] does not exist."
				retcode=-1
			fi
			;;	
		unpause)
			if [[ ! -z `docker ps --filter=name=${2} | \
				grep --ignore-case paused` ]]
			then
				echo "Unpausing container [${2}]."
				docker unpause ${2} > /dev/null 2>&1
			elif [[ ! -z `docker ps --all | grep ${2}` ]]
			then
				echo "Error: Container [${2}] is not paused."
			else
				echo "Error: Container [${2}] does not exist."
				retcode=-1
			fi
			;;
		start)
			if [[ -z `docker ps --filter=name=${2} | grep ${2}` && \
				! -z `docker ps --all --filter=name=${2} | grep ${2}` ]]
			then
				echo "Starting container [${2}]."
				docker start ${2} > /dev/null 2>&1
			elif [[ !  -z `docker ps --all --filter=name=${2} | grep ${2} | \
				grep --ignore-case paused` ]]
			then
				echo "Error: Container [${2}] is already running."
			elif [[ ! -z `docker ps --all --filter=name=${2} | grep ${2} | \
				grep --ignore-case paused` ]]
			then
				echo "Error: Container [${2}] is paused."
			else
				echo "Error: Container [${2}] does not exist."
				retcode=-1
			fi
			;;
		stop)
			if [[ -z `docker ps --filter=name=^${2} | \
				grep --ignore-case paused` && \
				-z `docker ps --all | grep ^${2} | \
				grep --ignore-case exited` ]]
			then
				echo "Stopping container [${2}]."
				docker stop ${2} > /dev/null 2>&1
			elif [[ ! -z `docker ps --all | grep ^${2}` ]]
			then
				echo "Error: Container [${2}] is not running."
			else
				echo "Error: Container [${2}] does not exist."
				retcode=-1
			fi
			;;
		status)
			if [ -z ${2} ]
			then
				docker ps -a
			elif [[ ! -z `docker ps --all --filter=name=${2} | grep ${2}` ]]
			then
				docker ps --all --filter=name=${2}
			else
				echo "Error: Container [${2}] does not exist."
			fi
			;;
		*)
			echo -n "Error: container ${1}: invalid command"
			echo "Type 'container.sh --help'"
			retcode=-1
			;;
	esac

	return ${retcode}
}

###############################################################################
# Display usage information.                                                  #
###############################################################################

function display_usage() {
	echo
	echo -e -n "Usage: ${0} [-h | --help | -v | --version]|"
	echo "<action> [<container> | <container> [<argument>*]]"
	echo 
	echo "options:"
	echo -e "\t-h, --help\n\t\tDisplay this help information."
	echo -e "\t-v, --version\n\t\tDisplay version information"
	echo
	echo -e "action"
	echo -e "\tcreate\tcreate a new container from an existing image"
	echo -e "\t\t./containter.sh create <container> <image_name> [<host_directory>]"
	echo -e "\tkill\tterminate an existing container"
	echo -e "\t\t./container.sh kill <container>"
	echo -e "\tpause\tpause a running container"
	echo -e "\t\t./container.sh pause <container>"
	echo -e "\tunpause\tunpause an existing container"
	echo -e "\t\t./container.sh unpause <container>"
	echo -e "\tstart\tstart an existing container"
	echo -e "\t\t./container.sh start <container>"
	echo -e "\tstop\tstop a running container"
	echo -e "\t\t./container.sh stop <container>"
	echo -e -n "\tstatus\tdisplay the current status of an existing "
	echo "container or all containers"
	echo -e "\t\t./container.sh [<container>]"
	echo -e "container\n\t\t<container name>\n\t\t<container id>"
	echo
}

###############################################################################
# Display version information.                                                #
###############################################################################

function display_version() {

	echo
	echo "Docker Container Lifecycle Management"
	echo "version 0.1, Copyright (C) 2015 Gregory D. Horne"
	echo
}

###############################################################################
# Parse command line arguments and dispatch appropriate handler function.     #
###############################################################################

if [ $# -lt 1 ]
then
	display_banner
	display_usage
	exit 1
elif [[ ${1} == "-h" || ${1} == "--help" ]]
then
	display_banner
	display_usage
	exit 0
elif [[ ${1} == "-v" || ${1} == "--version" ]]
then
	display_version
	exit 0
elif [[ $# -gt 0 && $# -lt 5 ]]
then
	manage_container ${1} ${2} ${3} ${4}
	exit $?
fi

