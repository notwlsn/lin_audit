#!/bin/bash
#===============================================================================
#
#          FILE:  main.sh
#
#         USAGE:  ./main.sh
#
#   DESCRIPTION:  Linux Audit Program
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  Please do not modify this file without checking with
# Willson Camp (contact below).  Modifcation of variables
#	          could cause the script to remove files that it shouldn't.
#        AUTHOR:  Willson Camp
#
#       VERSION:  1.2.5c
#       CREATED:  September 15, 2019
#      REVISION:  Dec 24, 2019
#===============================================================================


function main ()
{
#===  FUNCTION  ================================================================
#          NAME: main
#   DESCRIPTION: Drives the functions to gather audit information.
#    PARAMETERS: None
#       RETURNS: 0
#===============================================================================

	OUT=/tmp/audit
	if [ -d $OUT ] ; then
		echo 'Please delete /tmp/audit before proceeding.'
		return 1
	else
		mkdir $OUT
		if [ $? -ne 0 ] ; then
			echo 'mkdir /tmp/audit failed.'
			return 1
		fi
	fi

	GetPasswordFile > $OUT/passwd.txt 2>>$OUT/errors.txt
	GetShadowFile > $OUT/shadow.txt 2>>$OUT/errors.txt
	GetUserGroups				# GetUserGroups writes to $OUT/usergroups
	GetSamba				# GetSamba writes to $OUT/sambaconf.txt
	GetSULog > $OUT/sulog.txt 2>>$OUT/errors.txt
	GetSystemInfo > $OUT/SystemInfo.txt 2>>$OUT/errors.txt
	LoginHistory > $OUT/lastlog.txt 2>>$OUT/errors.txt
	GetServices > $OUT/services.txt 2>>$OUT/errors.txt
	GetTCPWrappers > $OUT/TCPwrappers.txt 2>>$OUT/errors.txt
	GetFilePerm >$OUT/fileperms.txt 2>>$OUT/errors.txt
	WorldWrite > $OUT/worldwrite.txt 2>>$OUT/errors.txt
	SUInfo > $OUT/sudoers.txt 2>>$OUT/errors.txt
	GetSUIDFiles > $OUT/suid.txt 2>>$OUT/errors.txt
	GetSSHInfo > $OUT/SSHInfo.txt 2>>$OUT/errors.txt
	GetProcessInfo > $OUT/PS.txt 2>>$OUT/errors.txt
	GetLoginDefs > $OUT/login.defs.txt 2>>$OUT/errors.txt
	GetSecureTTY > $OUT/securetty.txt 2>>$OUT/errors.txt
	FindRHOSTS > $OUT/rhosts.txt 2>>$OUT/errors.txt
	GetSyslog > $OUT/syslog.txt 2>>$OUT/errors.txt
	GetDefaultLogin > $OUT/defaultlogin.txt 2>>$OUT/errors.txt
	GetPAM > $OUT/pamauth.txt 2>>$OUT/errors.txt
	GetSELinux > $OUT/selinux.txt 2>>$OUT/errors.txt

  # Begin code to calculate date password was last changed for each usr
	# Store shadow file name
	FILE=""

   	FILE="/etc/shadow"
   	# make sure file exist and readable
   	if [ ! -f $FILE ]; then
  		echo "$FILE : does not exists"
   	elif [ ! -r $FILE ]; then
  		echo "$FILE: can not read"
   	fi
	# read $FILE using the file descriptors

	# Set loop separator to end of line
	BAKIFS=$IFS
	IFS=$(echo -en "\n\b")
	exec 3<&0
	exec 0<"$FILE"
	while read -r line
	do
		# use $line variable to process line
		SinceLastChanged $line
	done
	exec 0<&3

	# restore $IFS which was used to determine what the field separators are
	IFS=$BAKIFS

        #End code to calculate date password was last changed for each usr

	STRIPPEDOUT=${OUT:1}
#echo -e $STRIPPEDOUT
        FPATH=/tmp/$HOSTNAME.audit.tgz

#echo -e $FPATH

#	tar -C / -czf $PWD/$HOSTNAME.audit.tar.gz $STRIPPEDOUT		#tar the deliverable
        tar -czvf $FPATH $STRIPPEDOUT
        mv /tmp/$HOSTNAME.audit.tgz $STRIPPEDOUT
	rm $OUT/passwd.txt $OUT/shadow.txt $OUT/usergroups.txt $OUT/sulog.txt $OUT/SystemInfo.txt $OUT/lastlog.txt $OUT/services.txt $OUT/TCPwrappers.txt $OUT/fileperms.txt $OUT/worldwrite.txt $OUT/sudoers.txt $OUT/suid.txt $OUT/SSHInfo.txt $OUT/PS.txt $OUT/login.defs.txt $OUT/securetty.txt $OUT/rhosts.txt $OUT/syslog.txt $OUT/defaultlogin.txt $OUT/pamauth.txt $OUT/date-pw-last-chgd.txt $OUT/sambaconf.txt $OUT/selinux.txt $OUT/errors.txt

	return 0

}


function GetSELinux ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetSELinux
#   DESCRIPTION:  Get status of SELinux (RedHat)
#    PARAMETERS:  none
#       RETURNS:  0
#===============================================================================
	echo "Get RedHat SELinux status"
	/usr/sbin/sestatus
	return 0

}

function GetPAM ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetPAM
#   DESCRIPTION:  Get /etc/pam.d/system-auth
#    PARAMETERS:  none
#       RETURNS:  0
#===============================================================================
	cat /etc/pam.d/system-auth
	return 0

}

function LoginHistory ()
{

#===  FUNCTION  ================================================================
#          NAME:  LoginHistory
#   DESCRIPTION:  Get the last login information for system users
#    PARAMETERS:  none
#       RETURNS:  0
#===============================================================================
        echo "Login via TTY History:"
	lastlog
        echo "Login via Gnome History:"
        ck-history --log | grep user

	return 0

}

function GetPasswordFile()
{
#===  FUNCTION  ================================================================
#          NAME:  GetPasswordFile
#   DESCRIPTION:  Gets the /etc/passwd file
#    PARAMETERS:  none
#       RETURNS:  0
#===============================================================================

	cat /etc/passwd
	return 0

}


function GetShadowFile ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetShadowFile
#   DESCRIPTION:  Gets the /etc/shadow file
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================
	cat /etc/shadow
	return 0

}    # ----------  end of function GetShadowFile  ----------



function GetSULog ()
{

#===  FUNCTION  ================================================================
# 	   NAME:  GetSULog
#   DESCRIPTION:  Gets /var/log/secure
#    PARAMETERS:  none
#       RETURNS:  0
#===============================================================================

	echo "/var/log/secure"
	tail --lines=5000 /var/log/secure
	echo "/var/log/auth.log"
	tail --lines=5000 /var/log/auth.log



}    # ----------  end of function GetSULog  ----------


function GetSystemInfo ()
{
#===  FUNCTION  ================================================================
#          NAME:  GetSystemInfo
#   DESCRIPTION:  Prints out basic system informatin including:
#		  name, version, network interfaces, routes, iptables, and more
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================

	echo "System Name and Version"
	lsb_release -a
        uname -a
	echo "Network Information"
	echo "DNS"
	cat /etc/resolv.conf
	echo "IP Configuration"
	ifconfig -a
	echo "Route Table"
	route -nv
	echo "Route Cache"
	route -Cn
	echo "IPTABLES"
	iptables -L
	echo "File System"
	cat /etc/fstab
	echo "Exported directories"
	cat /etc/exports

	return 0
}

function GetServices ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetServices
#   DESCRIPTION:  Get running network services
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================
	netstat -lntp
	return 0
}

function WorldWrite ()
{

#===  FUNCTION  ================================================================
#          NAME:  WorldWrite
#   DESCRIPTION:  Gets a list of world writable files
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================
	find / -type f -perm -2 -ls
	return 0
}

function GetUserGroups ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetUserGroups
#   DESCRIPTION:  Write all users' ID info to file
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================


	for user in `awk -F":" '{ print $1 }' /etc/passwd`; do
		id $user >> $OUT/usergroups.txt 2>>$OUT/errors.txt

	done

	return 0
}

function SinceLastChanged ()
{

#===  FUNCTION  ================================================================
#          NAME:  SinceLastChanged
#   DESCRIPTION:  Calculate date each user's password was last changed
#    PARAMETERS:  None
#       RETURNS:  0
# Shell script utility to read a shadow file line by line.
# and calculate the date each password was last changed
#===============================================================================


  line="$@" # get all args

# Get 1st field = user id
  F1=$(echo $line | awk '{ split($0,array,":") } END{print array[1]}')
# Get 3rd field in shadow file which is days lapsed since Jan 1, 1970 before  pw was last changed
  F3=$(echo $line | awk '{ split($0,array,":") } END{print array[3]}')

# Get readable date given seconds lapsed since Jan. 1, 1970
# by multiplying the number of days since Jan. 1, 1970 * the number of seconds in a day (86400)
# Note that the mult operator '*' must be escaped with '\'
  if [ "$F3" != "" ]; then
      secs=`expr $F3 \* 86400`
#printf "The value of secs is %s\n" $secs
#      SLC=$(echo $secs | awk '{ print strftime("%c",$1) }')
      SLC=$(date -d @$secs)
#printf "The value of SLC is %s\n" $SLC
#printf "User: %s password last changed on %s\n" $F1 $SLC


      echo $F1 "password last changed: "$SLC >> $OUT/date-pw-last-chgd.txt 2>>$OUT/errors.txt
  fi
}

function GetSamba ()
{
#===  FUNCTION  ================================================================
#	NAME:		GetSamba
#	DESCRIPTION: 	Gets the contents of Samba config, if it exists
#	PARAMETERS:	None
#	RETURNS:	0
#===============================================================================
	if [ -f /etc/samba/smb.conf ] ; then
		cat /etc/samba/smb.conf > $OUT/sambaconf.txt
	elif [ -f /usr/local/samba/lib/smb.conf ] ; then
		cat /usr/local/samba/lib/smb.conf > $OUT/sambaconf.txt
		else
			echo "Samba config file smb.conf NOT FOUND!" >>$OUT/errors.txt
	fi
	return 0
}    # ---------------  end of function GetSamba  ----------------/


function GetTCPWrappers ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetTCPWrappers
#   DESCRIPTION:  Gets the content of hosts.allow, hosts.deny, and hosts.equiv
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================

	echo 'Hosts Allow'
	if  [ -e /etc/hosts.allow ]; then
		echo && cat /etc/hosts.allow
	fi

	echo 'Hosts Deny'
	if  [ -e /etc/hosts.deny ]; then
		echo && cat /etc/hosts.deny
	fi

	echo 'Hosts equiv'
	if  [ -e /etc/hosts.eqiv ]; then
		echo && cat /etc/hosts.equiv
	fi


	return 0
}    # ----------  end of function TCPWrappers  ----------


function GetFilePerm ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetFilePerms
#   DESCRIPTION:  Get the file permissions for crtical system files and
#		  and directories.
#    PARAMETERS:  none
#       RETURNS:  0
#===============================================================================


      echo "SUDO"
      location=`whereis sudo|awk -F" " '{print $2}'`
      ls -l $location
      echo ""

      echo "SU"
      location=`whereis su|awk -F" " '{print $2}'`
      ls -l $location
      echo ""

      echo "passwd"
      location=`whereis passwd|awk -F" " '{print $2}'`
      ls -l $location
      echo ""

      echo "shadow"
      location=`whereis shadow|awk -F" " '{print $2}'`
      ls -l $location
      echo ""

      echo "TMP"
      ls -ld /tmp/*

return 0

}



function SUInfo ()
{

#===  FUNCTION  ================================================================
#          NAME:  SUInfo
#   DESCRIPTION:  Gets information on su and sudo
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================

	echo "Members of the sudoers file"
	cat /etc/sudoers

        return 0
}


function GetSUIDFiles ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetSUIDFiles
#   DESCRIPTION:  Gets all SUID/SGID files
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================
	find / -type f \( -perm -4000 -o -perm -2000 \) -ls
	return 0

}    # ----------  end of function GetSUIDFiles  ----------
function GetSSHInfo ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetSSHInfo
#   DESCRIPTION:  Gets information about the configuration of ssh
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================

      echo "sshd_config"
      cat /etc/ssh/sshd_config
      echo ""

      echo "ssh_config"
      cat /etc/ssh/ssh_config
      echo ""


      return 0
}


function GetProcessInfo ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetProcessInfo
#   DESCRIPTION:  Gets information about the current running processes
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================

      ps -ef

      return 0
}

function GetLoginDefs ()
{

#===  FUNCTION  ================================================================
#          NAME:  GetLoginDefs
#   DESCRIPTION:  Reads the contents of login.defs
#    PARAMETERS:  None
#       RETURNS:  0
#===============================================================================

	cat /etc/login.defs
	return 0

}    # ----------  end of function GetLoginDefs  ----------


function GetSecureTTY ()
{
#===  FUNCTION  ================================================================
#          NAME: GetSecureTTY
#   DESCRIPTION: Gets the output of /etc/securetty
#    PARAMETERS: None
#       RETURNS: 0
#===============================================================================

	cat /etc/securetty
	return 0

}    # ----------  end of function GetSecureTTY  ----------

function FindRHOSTS()
{
#===  FUNCTION  ================================================================
#          NAME: FindRHOSTS
#   DESCRIPTION: Finds the contents of all .rhost files
#    PARAMETERS: None
#       RETURNS: 0
#===============================================================================

	find / -name .rhosts -ls -exec cat '{}' \;
	return 0

}    # ----------  end of function FindRHOSTS ----------


function GetSyslog ()
{

#===  FUNCTION  ================================================================
#          NAME: GetSyslog
#   DESCRIPTION: Gets output of syslog.conf
#    PARAMETERS: None
#       RETURNS: 0
#===============================================================================

	cat /etc/syslog.conf
	return 0

}    # ----------  end of function GetSyslog  ----------


function GetDefaultLogin ()
{

#===  FUNCTION  ================================================================
#          NAME: GetDefaultLogin
#   DESCRIPTION: Get /etc/default/login
#    PARAMETERS: None
#       RETURNS: 0
#===============================================================================

	cat /etc/default/login
	return 0

}    # ----------  end of function GetDefaultLogin  ----------


main

exit 0
