#!/bin/sh

#Copyright (C) 2015-2021, Wazuh Inc.
# Install functions for Wazuh
# Wazuh.com (https://github.com/wazuh)

patch_version(){
        rm -rf $PREINSTALLEDDIR/etc/shared/ssh > /dev/null 2>&1
}
WazuhSetup(){
    patch_version
}

InstallSELinuxPolicyPackage(){

    if command -v semodule > /dev/null && command -v getenforce > /dev/null; then
        if [ -f selinux/wazuh.pp ]; then
            if [ $(getenforce) != "Disabled" ]; then
                cp selinux/wazuh.pp /tmp && semodule -i /tmp/wazuh.pp
                rm -f /tmp/wazuh.pp
                semodule -e wazuh
            fi
        fi
    fi
}

WazuhUpgrade()
{
    # Encode Agentd passlist if not encoded

    passlist=$PREINSTALLEDDIR/agentless/.passlist

    if [ -f $passlist ] && ! base64 -d $passlist > /dev/null 2>&1; then
        cp $passlist $passlist.bak
        base64 $passlist.bak > $passlist

        if [ $? = 0 ]; then
            echo "Agentless passlist encoded successfully."
            rm -f $passlist.bak
        else
            echo "ERROR: Couldn't encode Agentless passlist."
            mv $passlist.bak $passlist
        fi
    fi

    # Remove/relocate existing SQLite databases
    rm -f $PREINSTALLEDDIR/var/db/.profile.db*
    rm -f $PREINSTALLEDDIR/var/db/.template.db*
    rm -f $PREINSTALLEDDIR/var/db/agents/*

    if [ -f "$PREINSTALLEDDIR/var/db/global.db" ]; then
        cp $PREINSTALLEDDIR/var/db/global.db $PREINSTALLEDDIR/queue/db/
        if [ -f "$PREINSTALLEDDIR/queue/db/global.db" ]; then
            chmod 640 $PREINSTALLEDDIR/queue/db/global.db
            chown wazuh:wazuh $PREINSTALLEDDIR/queue/db/global.db
            rm -f $PREINSTALLEDDIR/var/db/global.db*
        else
            echo "Unable to move global.db during the upgrade"
        fi
    fi

    # Remove existing SQLite databases for Wazuh DB, only if upgrading from 3.2..3.6

    MAJOR=$(echo $USER_OLD_VERSION | cut -dv -f2 | cut -d. -f1)
    MINOR=$(echo $USER_OLD_VERSION | cut -d. -f2)

    if [ $MAJOR = 3 ] && [ $MINOR -lt 7 ]
    then
        rm -f $PREINSTALLEDDIR/queue/db/*.db*
    fi
    rm -f $PREINSTALLEDDIR/queue/db/.template.db

    # Remove existing SQLite databases for vulnerability-detector

    rm -f $PREINSTALLEDDIR/wodles/cve.db
    rm -f $PREINSTALLEDDIR/queue/vulnerabilities/cve.db

    # Migrate .agent_info and .wait files before removing deprecated socket folder

    if [ -d $PREINSTALLEDDIR/queue/ossec ]; then
        if [ -f $PREINSTALLEDDIR/queue/ossec/.agent_info ]; then
            mv -f $PREINSTALLEDDIR/queue/ossec/.agent_info $PREINSTALLEDDIR/queue/sockets/.agent_info
        fi
        if [ -f $PREINSTALLEDDIR/queue/ossec/.wait ]; then
            mv -f $PREINSTALLEDDIR/queue/ossec/.wait $PREINSTALLEDDIR/queue/sockets/.wait
        fi
        rm -rf $PREINSTALLEDDIR/queue/ossec
    fi

    # Move rotated logs to new folder and remove the existing one

    if [ -d $PREINSTALLEDDIR/logs/ossec ]; then
        if [ "$(ls -A $PREINSTALLEDDIR/logs/ossec)" ]; then
            mv -f $PREINSTALLEDDIR/logs/ossec/* $PREINSTALLEDDIR/logs/wazuh
        fi
        rm -rf $PREINSTALLEDDIR/logs/ossec
    fi

    # Remove deprecated Wazuh tools

    rm -f $PREINSTALLEDDIR/bin/ossec-control
    rm -f $PREINSTALLEDDIR/bin/ossec-regex
    rm -f $PREINSTALLEDDIR/bin/ossec-logtest
    rm -f $PREINSTALLEDDIR/bin/ossec-makelists
    rm -f $PREINSTALLEDDIR/bin/util.sh
    rm -f $PREINSTALLEDDIR/bin/rootcheck_control
    rm -f $PREINSTALLEDDIR/bin/syscheck_control
    rm -f $PREINSTALLEDDIR/bin/syscheck_update

    # Remove old Wazuh daemons

    rm -f $PREINSTALLEDDIR/bin/ossec-agentd
    rm -f $PREINSTALLEDDIR/bin/ossec-agentlessd
    rm -f $PREINSTALLEDDIR/bin/ossec-analysisd
    rm -f $PREINSTALLEDDIR/bin/ossec-authd
    rm -f $PREINSTALLEDDIR/bin/ossec-csyslogd
    rm -f $PREINSTALLEDDIR/bin/ossec-dbd
    rm -f $PREINSTALLEDDIR/bin/ossec-execd
    rm -f $PREINSTALLEDDIR/bin/ossec-integratord
    rm -f $PREINSTALLEDDIR/bin/ossec-logcollector
    rm -f $PREINSTALLEDDIR/bin/ossec-maild
    rm -f $PREINSTALLEDDIR/bin/ossec-monitord
    rm -f $PREINSTALLEDDIR/bin/ossec-remoted
    rm -f $PREINSTALLEDDIR/bin/ossec-reportd
    rm -f $PREINSTALLEDDIR/bin/ossec-syscheckd

    # Remove existing ruleset version file

    rm -f $PREINSTALLEDDIR/ruleset/VERSION

    # Remove old Active Response scripts

    rm -f $PREINSTALLEDDIR/active-response/bin/firewall-drop.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/default-firewall-drop.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/pf.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/npf.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/ipfw.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/ipfw_mac.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/firewalld-drop.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/disable-account.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/host-deny.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/ip-customblock.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/restart-ossec.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/route-null.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/kaspersky.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/ossec-slack.sh
    rm -f $PREINSTALLEDDIR/active-response/bin/ossec-tweeter.sh

    # Remove deprecated ossec-init.conf file and its link
    if [ -f /etc/ossec-init.conf ]; then
        rm -f $PREINSTALLEDDIR/etc/ossec-init.conf
        rm -f /etc/ossec-init.conf
    fi

    # Replace and delete ossec group along with ossec users
    OSSEC_GROUP=ossec
    if (grep "^ossec:" /etc/group > /dev/null 2>&1) || (dscl . -read /Groups/ossec > /dev/null 2>&1)  ; then
        find $PREINSTALLEDDIR -group $OSSEC_GROUP -user root -exec chown root:wazuh {} \;
        find $PREINSTALLEDDIR -group $OSSEC_GROUP -exec chown wazuh:wazuh {} \;
    fi
    ./src/init/delete-oldusers.sh $OSSEC_GROUP

    # Remove unnecessary `execa` socket
    if [ -f "$DIRECTORY/queue/alerts/execa" ]; then
        rm -f $DIRECTORY/queue/alerts/execa
    fi
}
