#!/bin/bash

function main ()
{
	OUT=/tmp/audit
	if [ -d $OUT ] ; then
		echo 'Delete /tmp/audit before proceeding.'
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

	FILE=""

   	FILE="/etc/shadow"
   	# make sure file exist and readable
   	if [ ! -f $FILE ]; then
  		echo "$FILE : does not exists"
   	elif [ ! -r $FILE ]; then
  		echo "$FILE: can not read"
   	fi

	BAKIFS=$IFS
	IFS=$(echo -en "\n\b")
	exec 3<&0
	exec 0<"$FILE"
	while read -r line
	do
		SinceLastChanged $line
	done
	exec 0<&3

	# restore $IFS which was used to determine what the field separators are
	IFS=$BAKIFS

	STRIPPEDOUT=${OUT:1}
        FPATH=/tmp/$HOSTNAME.audit.tgz

				#	tar -C / -czf $PWD/$HOSTNAME.audit.tar.gz $STRIPPEDOUT
        tar -czvf $FPATH $STRIPPEDOUT
        mv /tmp/$HOSTNAME.audit.tgz $STRIPPEDOUT
	rm $OUT/passwd.txt $OUT/shadow.txt $OUT/usergroups.txt $OUT/sulog.txt $OUT/SystemInfo.txt $OUT/lastlog.txt $OUT/services.txt $OUT/TCPwrappers.txt $OUT/fileperms.txt $OUT/worldwrite.txt $OUT/sudoers.txt $OUT/suid.txt $OUT/SSHInfo.txt $OUT/PS.txt $OUT/login.defs.txt $OUT/securetty.txt $OUT/rhosts.txt $OUT/syslog.txt $OUT/defaultlogin.txt $OUT/pamauth.txt $OUT/date-pw-last-chgd.txt $OUT/sambaconf.txt $OUT/selinux.txt $OUT/errors.txt

	return 0

}


function GetSELinux ()
{
	echo "Get RedHat SELinux status"
	/usr/sbin/sestatus
	return 0
}

function GetPAM ()
{
	cat /etc/pam.d/system-auth
	return 0
}

function LoginHistory ()
{
        echo "Login via TTY History:"
	lastlog
        echo "Login via Gnome History:"
        ck-history --log | grep user

	return 0

}

function GetPasswordFile()
{
	cat /etc/passwd
	return 0
}


function GetShadowFile ()
{
	cat /etc/shadow
	return 0
}

function GetSULog ()
{
	echo "/var/log/secure"
	tail --lines=5000 /var/log/secure
	echo "/var/log/auth.log"
	tail --lines=5000 /var/log/auth.log

}


function GetSystemInfo ()
{
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
	netstat -lntp
	return 0
}

function WorldWrite ()
{
	find / -type f -perm -2 -ls
	return 0
}

function GetUserGroups ()
{
	for user in `awk -F":" '{ print $1 }' /etc/passwd`; do
		id $user >> $OUT/usergroups.txt 2>>$OUT/errors.txt

	done

	return 0
}

function SinceLastChanged ()
{

  line="$@"


  F1=$(echo $line | awk '{ split($0,array,":") } END{print array[1]}')

  F3=$(echo $line | awk '{ split($0,array,":") } END{print array[3]}')


  if [ "$F3" != "" ]; then
      secs=`expr $F3 \* 86400`
			#SLC=$(echo $secs | awk '{ print strftime("%c",$1) }')
      SLC=$(date -d @$secs)
			#printf "The value of SLC is %s\n" $SLC
			#printf "User: %s password last changed on %s\n" $F1 $SLC

      echo $F1 "password last changed: "$SLC >> $OUT/date-pw-last-chgd.txt 2>>$OUT/errors.txt
  fi
}

function GetSamba ()
{
	if [ -f /etc/samba/smb.conf ] ; then
		cat /etc/samba/smb.conf > $OUT/sambaconf.txt
	elif [ -f /usr/local/samba/lib/smb.conf ] ; then
		cat /usr/local/samba/lib/smb.conf > $OUT/sambaconf.txt
		else
			echo "Samba config file smb.conf NOT FOUND!" >>$OUT/errors.txt
	fi
	return 0
}


function GetTCPWrappers ()
{

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
}

function GetFilePerm ()
{

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

	echo "Members of the sudoers file"
	cat /etc/sudoers

        return 0
}


function GetSUIDFiles ()
{

	find / -type f \( -perm -4000 -o -perm -2000 \) -ls
	return 0

}
function GetSSHInfo ()
{

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

      ps -ef

      return 0
}

function GetLoginDefs ()
{

	cat /etc/login.defs
	return 0

}

function GetSecureTTY ()
{

	cat /etc/securetty
	return 0

}

function FindRHOSTS()
{

	find / -name .rhosts -ls -exec cat '{}' \;
	return 0

}


function GetSyslog ()
{

	cat /etc/syslog.conf
	return 0

}


function GetDefaultLogin ()
{

	cat /etc/default/login
	return 0

}

main

exit 0
