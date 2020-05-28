#!/bin/bash
#
GUI_USER=$(who | grep console | grep -v '_mbsetupuser' | awk '{print $1}')

DESTINATION_FOLDER="/Applications/splunk/etc/apps/"
SPLUNK_INSTALL_PATH="/Applications/"
# SPLUNK_DOWNLOAD_URL="https://files.cmdreporter.com/splunk-support/splunk-7.2.6-c0bf0f679ce9-darwin-64.tgz"
SPLUNK_DOWNLOAD_URL="https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86&platform=macos&version=8.0.2&product=splunk&filename=splunk-8.0.2-a7f645ddaf91-darwin-64.tgz&wget=true"
# SPLUNK_DOWNLOAD_MD5="95adddd0009d136aba0541c742c70805" # MD5 (splunk-7.2.6-c0bf0f679ce9-darwin-64.tgz)
SPLUNK_DOWNLOAD_MD5="3455ecd41860b9ee6afd34673f6fa1f7"


INFOSEC_APP_URL="https://files.cmdreporter.com/splunk-support/infosec-app-for-splunk_140-custom.tgz"
INFOSEC_APP_MD5="169a43a0c72bee0826150134d470a08a"

CIM_APP_URL="https://files.cmdreporter.com/splunk-support/splunk-sa-cim.tgz"
CIM_APP_MD5="805c259ff4511218392fc20a845fb3fc"

MISSLE_APP_URL="https://files.cmdreporter.com/splunk-support/missle-map.tgz"
MISSLE_APP_MD5="f0141b6bb4943c0261a6f57907495d12"

SANKEY_VIS_APP_URL="https://files.cmdreporter.com/splunk-support/sankey-diagram-app.tgz"
SANKEY_VIS_APP_MD5="181d05bc4ab3d055f16a87d46db045ef"

FORCE_VIS_APP_URL="https://files.cmdreporter.com/splunk-support/force-directed-viz.tgz"
FORCE_VIS_APP_MD5="f2244b40befb14a8fc728d5b9542d763"

PUNCHCARD_VIS_APP_URL="https://files.cmdreporter.com/splunk-support/punchcard-visuals.tgz"
PUNCHCARD_VIS_APP_MD5="2418e12a627d72e5b9ce5dd81566001c"

INDEX_CONFIG_BASE64="W2NtZHJlcG9ydGVyXQpjb2xkUGF0aCA9ICRTUExVTktfREIvY21kcmVwb3J0ZXIvY29sZGRiCmVuYWJsZURhdGFJbnRlZ3JpdHlDb250cm9sID0gMAplbmFibGVUc2lkeFJlZHVjdGlvbiA9IDAKaG9tZVBhdGggPSAkU1BMVU5LX0RCL2NtZHJlcG9ydGVyL2RiCm1heFRvdGFsRGF0YVNpemVNQiA9IDMwNzIwCnRoYXdlZFBhdGggPSAkU1BMVU5LX0RCL2NtZHJlcG9ydGVyL3RoYXdlZGRiCg=="

cleanup_finish(){
  rm /tmp/splunk.tgz
}
trap cleanup_finish EXIT


check_for_root_privs(){
  if [[ $(whoami) != root ]]; then
    echo "## Need root privs to install, please run script again with sudo"
    exit 1
  fi
}

confirm_user_choice(){
  echo "This script will install a local splunk server and supporting addons for splunk dashboards"
  echo "The install location is $SPLUNK_INSTALL_PATH/splunk"
  echo "#"
  echo -n "Would you like to continue? (y|n): "
  read userResponse

  case "$userResponse" in
    y|Y)
      echo "yes"
    ;;
    n|N)
      echo "no"
      exit 1
    ;;
    *)
      echo "unknown input"
      exit 1
    ;;
  esac
}

curl_zip_file(){
  downloadURL="$1"
  downloadOutputFile="$2"
  expectedMD5="$3"
  echo "# Downloading $downloadURL"
  /usr/bin/curl -L -o "$downloadOutputFile" "$downloadURL"
  if [[ $? != 0 ]]; then
    echo "## Failed to download $downloadOutputFile (curl command), exiting"
    exit 1
  fi

  if [[ -n $expectedMD5 ]]; then
    #statements
    if [[ $(md5 -q "$downloadOutputFile") != "$expectedMD5" ]]; then
      echo "## Failed to download $downloadOutputFile (md5 check), exiting"
      echo "## Expected $expectedMD5 and got $(md5 -q /tmp/splunk.tgz)"
      exit 1
    fi
  fi

}

install_splunk_enterprise(){

  curl_zip_file "$SPLUNK_DOWNLOAD_URL" "/tmp/splunk.tgz" "$SPLUNK_DOWNLOAD_MD5"


  mkdir "$SPLUNK_INSTALL_PATH/splunk"
  # Untar splunk to the correct location
  tar -xvzf /tmp/splunk.tgz -C "$SPLUNK_INSTALL_PATH"

  # Make sure root and wheel are the owners of the opt files
  chown -R "$GUI_USER" "$SPLUNK_INSTALL_PATH/splunk/"


  ### Check to make sure splunk is installed at all
  if [[ -e "$SPLUNK_INSTALL_PATH" ]]; then
    echo "## Splunk - installed, continuing config script"
    ln -s /Applications/splunk/bin/splunk /usr/local/bin/splunk
  else
    echo "## Splunk - Not installed at $SPLUNK_INSTALL_PATH, exiting"
    exit 1
  fi
}

install_cmdReporter_splunk_TA(){
  mkdir -p "$DESTINATION_FOLDER"
  rm -rf /tmp/TA-cmdReporter
  curl_zip_file "https://github.com/cmdSecurity/TA-cmdReporter/archive/master.zip" "/tmp/TA-cmdReporter.zip" 
  unzip /private/tmp/TA-cmdReporter.zip -d /tmp/TA-cmdReporter
  mv /private/tmp/TA-cmdReporter/TA-cmdReporter-master/TA-cmdreporter "$DESTINATION_FOLDER"
  chown -R "$GUI_USER" "$DESTINATION_FOLDER"

  rm -rf /tmp/TA-cmdReporter*

}

install_Splunk_infosec_app(){
  curl_zip_file  "$INFOSEC_APP_URL" "/tmp/infosec-app-for-splunk.tgz" "$INFOSEC_APP_MD5"
  tar -xvzf "/tmp/infosec-app-for-splunk.tgz" -C "$DESTINATION_FOLDER"
  chown -R "$GUI_USER" "$DESTINATION_FOLDER"

  rm "/tmp/infosec-app-for-splunk.tgz"
}

install_Splunk_CIM(){
  local tempFile="/tmp/splunk-cim-app.tgz"
  curl_zip_file  "$CIM_APP_URL" "$tempFile" "$CIM_APP_MD5"
  tar -xvzf "$tempFile" -C "$DESTINATION_FOLDER"
  chown -R "$GUI_USER" "$DESTINATION_FOLDER"

  rm "$tempFile"
  unset tempFile
}

install_missle_visual(){
  local tempFile="/tmp/splunk-missle-app.tgz"

  curl_zip_file  "$MISSLE_APP_URL" "$tempFile" "$MISSLE_APP_MD5"
  tar -xvzf "$tempFile" -C "$DESTINATION_FOLDER"
  chown -R "$GUI_USER" "$DESTINATION_FOLDER"

  rm "$tempFile"
  unset tempFile
}

install_force_directed_visual(){
  local tempFile="/tmp/splunk-force-directed-app.tgz"

  curl_zip_file  "$FORCE_VIS_APP_URL" "$tempFile" "$FORCE_VIS_APP_MD5"
  tar -xvzf "$tempFile" -C "$DESTINATION_FOLDER"
  chown -R "$GUI_USER" "$DESTINATION_FOLDER"

  rm "$tempFile"
  unset tempFile
}

install_sankey_visual(){
  local tempFile="/tmp/splunk-sankey-visual-app.tgz"

  curl_zip_file  "$SANKEY_VIS_APP_URL" "$tempFile" "$SANKEY_VIS_APP_MD5"
  tar -xvzf "$tempFile" -C "$DESTINATION_FOLDER"
  chown -R "$GUI_USER" "$DESTINATION_FOLDER"

  rm "$tempFile"
  unset tempFile
}

install_punchcard_visual(){
  local tempFile="/tmp/splunk-punchcard-visual-app.tgz"

  curl_zip_file  "$PUNCHCARD_VIS_APP_URL" "$tempFile" "$PUNCHCARD_VIS_APP_MD5"
  tar -xvzf "$tempFile" -C "$DESTINATION_FOLDER"
  chown -R "$GUI_USER" "$DESTINATION_FOLDER"

  rm "$tempFile"
  unset tempFile
}

configure_inputs_conf(){
  # Editing defaults to to make it easier on new splunk users
  # sed -i .bak '/^# index/d' "$DESTINATION_FOLDER/TA-cmdreporter/default/inputs.conf"
  sed -i .bak 's/^# //g' "$DESTINATION_FOLDER/TA-cmdreporter/default/inputs.conf"
  rm "$DESTINATION_FOLDER"/TA-cmdreporter/default/inputs.conf.bak

  echo "$INDEX_CONFIG_BASE64" | base64 -D -o "$DESTINATION_FOLDER"/TA-cmdreporter/default/indexes.conf
}

configure_splunk_props_exclude(){
  # Editing defaults to to make it easier on new splunk users
  sed -i .bak 's/^#TRANSFORMS-set/TRANSFORMS-set/g' "$DESTINATION_FOLDER/TA-cmdreporter/default/props.conf"
  rm "$DESTINATION_FOLDER/TA-cmdreporter/default/props.conf.bak"
}

check_if_splunk_enterprise_installed(){
  # Sanity check if splunk is installed already
  if [[ ! -e "$SPLUNK_INSTALL_PATH/splunk/bin/splunk" ]]; then
    echo "## Installing Splunk enterprise in $SPLUNK_INSTALL_PATH/Splunk"
    sleep 2
    install_splunk_enterprise
  else
    echo "## Splunk already installed at: $SPLUNK_INSTALL_PATH"
    echo "## Continuing without installing splunk enterprise"
  fi
}

check_for_root_privs
confirm_user_choice
check_if_splunk_enterprise_installed
install_cmdReporter_splunk_TA
install_Splunk_infosec_app
install_Splunk_CIM
install_missle_visual
install_sankey_visual
install_force_directed_visual
install_punchcard_visual

configure_inputs_conf
configure_splunk_props_exclude
chown -R "$GUI_USER" "$DESTINATION_FOLDER"
sudo -u "$GUI_USER" "$SPLUNK_INSTALL_PATH/splunk/bin/splunk" start --accept-license
echo "######################"
echo "/Applications/splunk/bin/splunk has been symlinked to /usr/local/bin/splunk"
echo "to (start|stop|restart) splunk open a new terminal window and:"
echo "splunk (start|stop|restart)"
echo "the splunk web console can be reached at: http://127.0.0.1:8000"
echo "### NOTE:"
echo "### The infosec application uses accelerated data models and data may not appear for up to 15 minutes depending on your hardware speed"
echo "### This script has enabled acceleration on all relevant data models in splunk, no action is required"
echo "######################"
echo -n "press return to open the data model acceleration status page"
read userConfirm
open "http://localhost:8000/en-US/app/InfoSec_App_for_Splunk/infosec_stats"