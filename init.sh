#!bin/bash
stanza_dir="oclc-ezproxy-database-stanzas/stanzas"
header="header.txt"
extract="config_stanza_extract.txt"
subscribed_stanza_list="subscribed_stanza.txt"
stanzas_csv="stanzas.csv"
stanza_list="foldernames.txt"
original_stanzas="original_stanzas.txt"
original_config="original_config.txt"
custom_stanzas_header="custom_stanzas_header.txt"
custom_stanzas="custom_stanzas.txt"
stanzas_git_repo="https://github.com/kent-state-university-libraries/oclc-ezproxy-database-stanzas.git"
final_config="config.txt"


#clone stanzas git repo
if [[ ! -d "oclc-ezproxy-database-stanzas"  ]]; then
  git clone $stanzas_git_repo
fi

#remove multiple return lines in config file
sed -i '/^$/N;/^\n$/D' $original_config

#build a list of stanzas from the current config file.
grep -P "^(?:U(?:RL)?\ )http(?:s)?:\/\/((?:www)?.*\.(?:.*)?)" $original_config | grep -ril  "$(awk '{print $2}')" $stanza_dir | cut -d'/' -f 3 | sort -uo $extract

grep -P "^(?:U(?:RL)?\ )http(?:s)?:\/\/((?:www)?.*\.(?:.*)?)" $original_config > $original_stanzas
#remove URL and http(s)://
sed -i -E 's/U(RL)? http(s)?:\/\///g' $original_stanzas
#remove first instance of a slash and anything after then sort
sed -i 's|/.*||' $original_stanzas
sort -uo $original_stanzas $original_stanzas


cat /dev/null > $custom_stanzas
while IFS= read -r -a array;
do
    if [ $( grep -ril "${array}" ./oclc-ezproxy-database-stanzas/stanzas/ | wc -l ) -eq 0 ];
    then
      echo $array >> $custom_stanzas
    fi
done < $original_stanzas

#build custom stanza blocks from original config
cat /dev/null > $custom_stanzas_header
echo "
##################################################
#         Custom Stanzas are as follows:         #
##################################################
" > $custom_stanzas_header
cat $custom_stanzas | xargs -I{} awk -vRS='\n\n' '/{}/{print $0, "\n"}' $original_config >> $custom_stanzas_header

#create complete list of stanzas from repo
ls oclc-ezproxy-database-stanzas/stanzas > $stanza_list

#add urls to staza list for easier identification when using the csv to control subscriptions
cat /dev/null > $stanzas_csv
while IFS= read -r -a array;
do
  a=$(grep -P "^(?:U(?:RL)?\ )http(?:s)?:\/\/((?:www)?.*\.(?:.*)?)" oclc-ezproxy-database-stanzas/stanzas/$array/stanza.txt  | sed -E 's/U(RL)? http(s)?:\/\///g' | sed 's|/.*||')

  echo -e "FALSE,"$array","$a >> $stanzas_csv
done < $stanza_list

cat /dev/null > $subscribed_stanza_list
while IFS= read -r -a array;
do
  echo -e "TRUE,"$array >> $subscribed_stanza_list
done < $extract

#replace false with true
while IFS= read -r -a array;
do
  stanza_name=$(echo $array | sed 's/TRUE,//')
  sed -i "s/FALSE,${stanza_name}/TRUE,${stanza_name}/g" $stanzas_csv
done < $subscribed_stanza_list

#build config file
cat $header > $final_config
cat $custom_stanzas_header >> $final_config
echo "
##################################################
#       Automated Stanzas are as follows:        #
##################################################
" >> $final_config
while IFS=', ' read -r -a array;
do
  if [ "${array[0]}" == "TRUE" ]
  then
    echo -e "\n" >> $final_config
    array[1]=$(echo ${array[1]} | tr -d '[:space:]')
    cat "${stanza_dir}/${array[1]}/stanza.txt"  >> $final_config
    fi
done < $stanzas_csv

#remove multiple return lines in config file
sed -i '/^$/N;/^\n$/D' $final_config

#add url to csv for easier identification


exit 0
