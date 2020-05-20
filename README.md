<h1>Linux Auditing Program</h1>

Tested on RedHat, Ubuntu up to Trusty Tahr (14.04), and Solaris.

<h2> Instructions: </h2>

1. Log into the server using a root account

2. Verify file hash. Something like <pre> $ echo "FILEHASH filename" | md5sum -c </pre>

2. Copy lin_audit.sh to /

3. cd to /

4. Make lin_audit.sh executable: <pre> chmod +x lin_audit.sh </pre>

5. Run: <pre> ./lin_audit.sh </pre>

The audit script will place an output report when it finishes in /tmp/audit/

The report name will be in this format: <pre> $HOSTNAME.audit.tgz </pre> (in the case of Solaris, it will be a .tar.gz)
