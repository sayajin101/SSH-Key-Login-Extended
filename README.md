# SSH Key Login Extended
* SSH Key  Login Alert, with key specific Bash History &amp; Telegram Alert

* Create a Telegram bot using Botfather (https://telegram.me/BotFather)
* Change the variables for the "telegramGroupID" & "botToken" in the "sshLoginExtended.sh" file

* Put the "sshLoginExtended.sh" script in /etc/profile.d/sshLoginExtened.sh

- Its recogmended that you disable password logins as this will defeat
- the purpoise of this script since it will be bypassed if a non-key login is used.
- To do that edit "/etc/ssh/sshd_config" and modify the below options as below
  - ChallengeResponseAuthentication no
  - PasswordAuthentication no
