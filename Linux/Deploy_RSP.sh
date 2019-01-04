#! /bin/sh

export ANT_HOME=/opt/tibco/ant/apache-ant-1.7.1
export PATH=$ANT_HOME/bin:$PATH

clear

#echo "******************************** Welcome to ***********************************"
#banner Autodeployer
#echo "*************************** by Bikram Agarwal *********************************"


############################################################################################
############################################################################################
#### Declaring variables. Make your changes here only.

## Properties that need to be changed as per request

Domain_Name="rspdomain"
New_App_Name="RSP"
#Stream_Name="RSP_Tentative_UUI_October_BLD"
#Stream_Name="RSP_R2011.07.23-1.12.0_BLD"
Stream_Name="RSP"

## Properties that need to be changed only the first time

Accu_User="vsubram4"

## Constant Properties. Don't edit them.

Wls_User="weblogic"
Wls_Pass="esgcm0nly"
Amp_User="ampadm"
Amp_Pass="Dont4Get"
Wls_Home="/opt/bea/wls10_3/user_projects/domains"

## Logging settings

LOG_DIR=/home/vsubram4/autodeploy
currTime=$(date +"%m%d%y%H%M%S")
LOG_FILE_NAME="${LOG_DIR}/${New_App_Name}_${Accu_User}_${currTime}.log"

#### No modifications hereafter
############################################################################################
############################################################################################

HOME=`pwd`
NOW=$(date +"%Y-%m-%d");
clear;
echo "Properties entered for deploy are -"
echo "Domain_Name = $Domain_Name"
echo "New_App_Name = $New_App_Name"
echo "Stream_Name = $Stream_Name"
echo
#### Gettting the build

rm -rf dist/*

echo "Please enter Accurev password:"
accurev login -n $Accu_User
accurev pop -R -O -v $Stream_Name -L . /./dist/rsp.zip;

cd dist
unzip rsp.zip

if [ ! -f deploy/rsp_act.ear ]; then
	echo "Error generating the rsp_act.ear file. Terminating autodeploy...!!!"
	exit
fi

cd template
echo
echo "****************************************************"
cat buildversion.properties
echo "****************************************************"
cd
echo
stringD=$Domain_Name

# loop for different domains

loopval="1"
while [ "$loopval" != "end" ]
do
	echo
	echo "loop " $loopval
	locator=`expr index "$stringD" ','`
	if [ "$locator" = 0 ]
	then
		domain1=$stringD
		loopval="end"
		echo "For domain $domain1"
	else
		let "locator -= 1"
		domain1=`expr substr "$stringD" 1 $locator`
		echo "For domain $domain1"
		let "loopval += 1"
	fi

dom=$(expr substr "$domain1" 10 2)

if [ $((((10#$dom))%2)) -eq 0 ]; then
	Server_Name=RSP-VMware.unix
else
	Server_Name=devrsp03.unix
fi
dev=$(expr substr "$Server_Name" 7 2)

Admin_Url="http://${Server_Name}.gsm1900.org:80${dom}/console/login/LoginForm.jsp"

echo "
<project name=\"Jsch_Alternate\" basedir=\".\" default=\"list\">

<taskdef name=\"sshexec\" classname=\"org.apache.tools.ant.taskdefs.optional.ssh.SSHExec\">
	<classpath>
                <pathelement location=\"/opt/tibco/ant/apache-ant-1.7.1/lib/jsch-0.1.42.jar\"/>
        </classpath>
</taskdef>

<taskdef name=\"scp\" classname=\"org.apache.tools.ant.taskdefs.optional.ssh.Scp\">
	<classpath>
                <pathelement location=\"/opt/tibco/ant/apache-ant-1.7.1/lib/jsch-0.1.42.jar\"/>
        </classpath>
</taskdef>

<target name=\"list\">
	<sshexec host=\"${Server_Name}\"
		 username=\"${Wls_User}\"
		 password=\"${Wls_Pass}\"
		 trust=\"true\"
		 command=\"ls ${Wls_Home}/${domain1}/servers/rspmanagedserver_a/stage\"/>
</target>

<target name=\"Copy_autodeploy.xml\">
	<scp file=\"autodeploy_$domain1.xml\" todir=\"${Wls_User}:${Wls_Pass}@${Server_Name}:/home/weblogic/\" trust=\"true\"/>
</target>

<target name=\"undeploy\" depends=\"Copy_autodeploy.xml\">
	<sshexec host=\"${Server_Name}\"
		 username=\"${Wls_User}\"
		 password=\"${Wls_Pass}\"
		 trust=\"true\"
		 command=\"export CLASSPATH=/opt/bea/wls10_3/wlserver_10.3/server/lib/weblogic.jar; /opt/bea/wls10_3/jdk1.6.0_12/bin/java weblogic.WLST ${Wls_Home}/${domain1}/unlock.py; /opt/bea/wls10_3/modules/org.apache.ant_1.6.5/bin/ant -file autodeploy_$domain1.xml undeploy; /opt/bea/wls10_3/jdk1.6.0_12/bin/java weblogic.WLST ${Wls_Home}/${domain1}/activate.py\"/>
</target>

<target name=\"bounce\">
	<sshexec host=\"${Server_Name}\"
		 username=\"${Wls_User}\"
		 password=\"${Wls_Pass}\"
		 trust=\"true\"
		 command=\"cd ${Wls_Home}/${domain1}/; sh stop_server_a.sh; sh start_server_a.sh; tail -f out.server_a\"/>
</target>

<target name=\"Copy_rsp_act.ear\">
	<echo>Copying the latest rsp_act.ear to the server</echo>
	<scp file=\"dist/deploy/rsp_act.ear\" todir=\"${Wls_User}:${Wls_Pass}@${Server_Name}:${Wls_Home}/${domain1}/applications/\" trust=\"true\"/>
</target>

<target name=\"deploy\" depends=\"Copy_autodeploy.xml,Copy_rsp_act.ear\">
	<echo>Deployment of the application starting....</echo>
	<sshexec host=\"${Server_Name}\"
		 username=\"${Wls_User}\"
		 password=\"${Wls_Pass}\"
		 trust=\"true\"
		 command=\"export CLASSPATH=/opt/bea/wls10_3/wlserver_10.3/server/lib/weblogic.jar; /opt/bea/wls10_3/jdk1.6.0_12/bin/java weblogic.WLST ${Wls_Home}/${domain1}/unlock.py; /opt/bea/wls10_3/modules/org.apache.ant_1.6.5/bin/ant -file autodeploy_$domain1.xml deploy\"/>
</target>

<target name=\"log\">
	<sshexec host=\"${Server_Name}\"
		 username=\"${Wls_User}\"
		 password=\"${Wls_Pass}\"
		 trust=\"true\"
		 command=\"cd ${Wls_Home}/${domain1}/; tail -100 out.server_a\"/>
</target>

<target name=\"amberpoint\">
	<echo>Copying the Services xml file</echo>
	<scp file=\"dist/manage/amberpoint/xml/managed-services.xml\" todir=\"${Amp_User}:${Amp_Pass}@${Server_Name}:/opt/ap/AmberPointScripts/config/DEV${dev}_${dom}/\" trust=\"true\"/>
	<echo>Running the AmberPoint Script...</echo>
	<sshexec host=\"${Server_Name}\"
		 username=\"${Amp_User}\"
		 password=\"${Amp_Pass}\"
		 trust=\"true\"
		 command=\"export AP_HOME=/opt/ap/6.1.2.3/SMSJava_6.1.2.3; export AP_TMOBILE_HOME=/opt/ap/AmberPointScripts; cd \$AP_TMOBILE_HOME; /opt/bea/wls10_3/modules/org.apache.ant_1.6.5/bin/ant -file buildNEW2.xml buildAgentDomain -Denv=DEV${dev}_${dom} -DSPHERE_USER=weblogic -DSPHERE_PASS=weblogic -DAGENT_USER=weblogic -DAGENT_PASS=weblogic\"/>
</target>

</project>
" > build_$domain1.xml;

f_bounce()
{
echo "
###############################################################################################

WEBLOGIC SERVER BEING RESTARTED.
PRESS CTRL+C ONCE THE \"Server started in RUNNING mode\" MSG APPEARS ON SCREEN TO CONTINUE...

###############################################################################################
"

ant -file build_$domain1.xml bounce
}

while true;
	do
	echo "Press --> 1 <-- to run FULL RSP deployment ..."
	echo "Press --> 2 <-- to run ONLY Amberpoint scripts..."
	echo "Press --> 3 <-- to ONLY bounce the weblogic server..."
	echo "Press --> 4 <-- to Quit the Script..."
	read response;
	if [ -z "${response}" ]; then
		clear;
		echo "INVALID entry. Please provide mentioned input ..."
	elif [ ${response} = "1" ]; then

echo "Listing environments already deployed in ${domain1} -
"

ant -file build_$domain1.xml list

echo "
Enter the name of the application you want to undeploy..."
echo "Just press enter without any other letter to skip undeploy...
"
read Old_App_Name
ver=${Old_App_Name##*_}

#### Creating the build.xml file for deployment machine

echo "
<project name=\"RSP_Undeploy\" basedir=\".\" default=\"undeploy\">

<taskdef name=\"wldeploy\" classname=\"weblogic.ant.taskdefs.management.WLDeploy\">
	<classpath>
		<pathelement location=\"/opt/bea/wls10_3/wlserver_10.3/server/lib/weblogic.jar\"/>
	</classpath>
</taskdef>

<target name=\"Init\">
	<property name=\"WLS_DOMAIN\" value=\"${domain1}\"/>
	<property name=\"WLS_PATH\" value=\"${Wls_Home}\"/>
	<property name=\"OLD_NAME\" value=\"${Old_App_Name}\"/>
	<property name=\"NEW_NAME\" value=\"${New_App_Name}\"/>
	<property name=\"ADMIN_URL\" value=\"${Admin_Url}\"/>
</target>

<target name=\"undeploy\" depends=\"Init\">
	<echo>Backing up existing rsp_act.ear</echo>
	<move file=\"${Wls_Home}/${domain1}/applications/rsp_act.ear\" tofile=\"${Wls_Home}/${domain1}/applications/rsp_act.ear.${ver}\" failonerror=\"false\"/>
	<wldeploy
		action=\"undeploy\" verbose=\"true\" debug=\"true\"
		name=\"\${OLD_NAME}\"
		user=\"weblogic\" password=\"weblogic\"
		adminurl=\"\${ADMIN_URL}\" targets=\"rspmanagedserver_a\"
		failonerror=\"false\" />

	<delete includeemptydirs=\"true\">
		<fileset dir=\"${Wls_Home}/${domain1}/servers/rspmanagedserver_a/stage\" includes=\"rsp_act*\"/>
	</delete>

</target>

<target name=\"deploy\" depends=\"Init\">

	<wldeploy
		action=\"deploy\" verbose=\"true\" debug=\"true\"
		name=\"\${NEW_NAME}\" source=\"\${WLS_PATH}/\${WLS_DOMAIN}/applications/rsp_act.ear\"
		user=\"weblogic\" password=\"weblogic\"

		adminurl=\"\${ADMIN_URL}\" targets=\"rspmanagedserver_a\" />
</target>

</project>
" > autodeploy_$domain1.xml;

#### Undeploying the Application

if [ -n "${Old_App_Name}" ]; then
echo "Undeploying the application ${Old_App_Name}"

ant -file build_$domain1.xml undeploy

Return_Val=$?
if [ $Return_Val -ne 0 ];then
echo "Undeploy of ${Old_App_Name} failed. Terminating..."
exit
fi

else
echo "Skipping the undeployment...."
fi

echo "Press y/Y to do server bounce. Else, just press Enter"
read bounce
if [ -n "${bounce}" ]; then
	f_bounce
fi

#### Deploying the Application

echo "Press ENTER to start deployment of $New_App_Name"
read StartDepl

ant -file build_$domain1.xml deploy &

slept=0
limit=1500
deploy_check()
{
while [ ${slept:-0} -le $limit ]; do
    sleep 60 && slept=`expr ${slept:-0} + 60`
    if [ $$ = "`ps -o ppid= -p $!`" ]; then
        echo "Deploy process is still running. $slept seconds since deploy started."
    else
        wait $! && echo "Application ${New_App_Name} deployed successfully" || echo "Deployment of ${New_App_Name} failed"
        break
    fi
done
}

deploy_check

if [ $$ = "`ps -o ppid= -p $!`" ]; then
   echo "Deploy process did not finish in $slept seconds. Here's the log."
   ant log
   echo "Do you want to kill the process? Press Ctrl+C to kill. Press Enter to continue."
   read log
limit=`expr ${limit} + 300`
   deploy_check
fi

echo "Press Y and Enter to run AmberPoint script. Press ONLY Enter to exit."
read amp;
if [ -n "${amp}" ]; then
	ant -file build_$domain1.xml amberpoint
fi

elif [ ${response} = "2" ]; then

	echo "Running the Amberpoint scripts only".
	ant -file build_$domain1.xml amberpoint

elif [ ${response} = "3" ]; then

	f_bounce

elif [ ${response} = "4" ];	then
	echo
	echo "Terminating the script. Have a good day. :-)"
	sleep 1;
	break;
else
	clear;
	echo "INVALID entry. Please provide mentioned input ..."
fi
done
stringD=${stringD#*,}
done
exit
