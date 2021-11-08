#!/bin/bash
backup_dir="backups"
current_conf="config.txt"
ezproxy_full_path=""
ezproxy_config_name="config.txt"
google_sheet=""
current_google_csv="current_google.csv"
custom_stanzas_header="custom_stanzas_header.txt"
header="header.txt"
old_google_csv="old_google.csv"
production="false"
rebuild="false"
stanza_dir="oclc-ezproxy-database-stanzas/stanzas"

#backup config file before we overwrite it
backup_config() {
  if [[ ! -d $backup_dir ]]; then
    mkdir $backup_dir
  fi
  local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  cp -a $current_conf ${backup_dir}/config-${timestamp}
  cp -a $current_google_csv $old_google_csv
}

#compare hash of files to see if they have changed
check_hash() {
  local original_sha=$(sha1sum $1 | awk '{print $1}')
  local new_sha=$(sha1sum $2 | awk '{print $1}')
  #echo $original_sha " : " $new_sha
  if [[ "$original_sha" != "$new_sha" ]];
  then
    echo "csv changed: yes"
  else
    echo "csv changed: no"
  fi
}

#pull in any changes made to the google csv and compare to old csv
compare_csv() {
  if [[ -f "$current_google_csv" && -f "$old_google_csv" ]]; 
  then
    curl -L -o $current_google_csv $google_sheet
    if [[ $(grep 'Error 400 (Bad Request)' $current_google_csv | wc -l) -eq 0 ]]; then
      local changed=$(check_hash $current_google_csv $old_google_csv)
      echo "changed is: "$changed
      if [ "$changed" == "yes" ]; then
        rebuild="true"
      fi
    else
      rebuild="false"
      echo "bad request"
    fi
  else
    #the files are not set up yet
    curl -L -o $current_google_csv $google_sheet
    cp -a $current_google_csv $old_google_csv
  fi
}

#pull stanza repo from github
pull_repo() {
  if [ "$(cd $stanza_dir && git pull)" != "Already up-to-date." ];
  then
      echo "changed repo is: true"
      rebuild="true"
  else
      echo "changed repo is: false"
  fi
}

#rebuild the config file if changes were made to git repo or google csv
rebuild_config() {
cat $header > $current_conf
cat $custom_stanzas_header >> $current_conf
echo "
##################################################
#       Automated Stanzas are as follows:        #
##################################################
" >> $current_conf
#sort the csv file by 4th column which is a priority column, then by the 2nd column which is the stanza name
sort -t, -k4,4n -k2,2 $current_google_csv |
while IFS=', ' read -r -a array;
do
  if [ "${array[0]}" == "TRUE" ];
  then
    echo -e "\n" >> $current_conf
    local array[1]=$(echo ${array[1]} | tr -d '[:space:]')
    cat "${stanza_dir}/${array[1]}/stanza.txt"  >> $current_conf
  fi
done

#trim all return lines down to a single return line in config file
sed -i '/^$/N;/^\n$/D' $current_conf
}

replace_config_in_ezproxy_dir() {
  cp -a ${current_conf} ${ezproxy_full_path}/${ezproxy_config_name}
}

restart_ezproxy() {
  cd ${ezproxy_full_path}; ./ezproxy restart
}

main() {
  pull_repo
  compare_csv
  if [ "$rebuild" == "true" ]; then
    backup_config
    rebuild_config
    if [ "$production" == "true" ]; then
      replace_config_in_ezproxy_dir
      restart_ezproxy
    fi
  fi
}

main

exit 0
