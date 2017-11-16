#!/bin/bash

# Check if SSHd LogLevel is set to verbose, else change it, this is needed for the fingerprint recognition to work
if [ `grep -c 'LogLevel' /etc/ssh/sshd_config` -eq "0" ]; then
	echo "LogLevel VERBOSE" >> /etc/ssh/sshd_config;
	service sshd restart;
elif [ `grep -c '^LogLevel VERBOSE' /etc/ssh/sshd_config` -eq "0" ]; then
	sed -i 's/.*LogLevel.*/LogLevel VERBOSE/g' /etc/ssh/sshd_config;
	service sshd restart;
fi;

# SSH Key Fingerprint stuff
lastRsaKey=$(tac /var/log/secure | grep -m 1 'Found matching RSA key: .*');
fromIpAddress=$(who am i | awk '{print $5}' | tr -d '()');
rsaKey=$(echo ${lastRsaKey##* });

export sshUser=$(cat /root/.ssh/authorized_keys | while read KEY; do
	name=$(echo "$KEY" | cut -d ' ' -f3-);
	fingerprint=$(ssh-keygen -l -f /dev/stdin <<< $KEY | awk '{$1=""; print $2}');
	[ "${fingerprint}" == "${rsaKey}" ] && echo "${name##*- }"
done;);

# Get Server's IP Address
defaultInterface=$(route -n | awk '{ if ($1 == "0.0.0.0") print $8}';);
ipAddress=$(ip addr show ${defaultInterface} | grep -m1 "inet\b" | awk '{print $2}' | cut -d/ -f1;);

# Truncate SSH Key Comment for filename use
sshUserFileName=$(echo "${sshUser}" | tr -d ' ';);

# Telegram Settings
telegramGroupID="";
botToken="";
timeout="10";
url="https://api.telegram.org/bot${botToken}/sendMessage";
message="${sshUser} logged into `hostname` (${ipAddress}) from address ${fromIpAddress}";

# Sent login notification to Telegram group
curl -s --max-time ${timeout} -d "chat_id=${telegramGroupID}&disable_web_page_preview=1&parse_mode=markdown&text=${message}" ${url} >/dev/null

#############
## History ##
#############

# Append to history, don't overwrite it
shopt -s histappend;

# Verify command substitutions before the shell executes them
shopt -s histverify;

# Check for bash version
if [ `echo ${BASH_VERSION%\(*} | cut -d '.' -f1,2 | tr -d '.'` -ge "43" ]; then
	export HISTFILESIZE="-1";
	export HISTSIZE="-1";
else
	# Values have to be different else bash lower than 4.2 wont append to history file
	# http://git.savannah.gnu.org/cgit/bash.git/diff/CWRU/changelog?id=495aee441b75276e38c75694ccb455bb6463fdb9
	# 8/13
	export HISTFILESIZE="50000";
	export HISTSIZE="20000";
fi;
	
export HISTIGNORE="";
export HISTTIMEFORMAT="(%d-%h-%y %H:%M) ";

# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups

# After each command, save and reload history
[ `echo ${PROMPT_COMMAND} | grep -c "history"` -eq 0 ] && export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}";

historyPath="${HOME}/.history/${sshUserFileName}";
mkdir -p ${historyPath};
export HISTFILE=${historyPath}/.bash_history;

# Check if history file exists, otherwise add entry else history wont work (bash 4.1 or less)
[ ! -f ${HISTFILE} ] && echo "# Start of History File" > ${HISTFILE};
