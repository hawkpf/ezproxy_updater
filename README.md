# ezproxy_updater
Using bash to update ezproxy stanzas from OCLC

Initial set up:
1)Copy ezproxy's config.txt to the working directory as original_config.txt

2)Copy custom config settings from the upper most poriton of the original_config.txt file and insert it into header.txt, this would include your server settings, IncludeIP, ExcludeIP, NeverProxy and other configurations for EZProxy.  You can also add stanzas from OCLC that you needed to modify because it wasn't working properly which means EZProxy will read this record first even though it will appear later in your config file.

3)Run init.sh

init.sh creates the following files:
config_stanza_extract.txt    #list of stanzas from original_config.txt file that match OCLCs stanzas
subscribed_stanza.txt        #list of stanzas that are subscribed and registered in OCLCs stanzas
stanzas.csv                  #csv file that is exported to google drive to control subscriptions and trigger rebuilds                              of config.txt
foldernames.txt              #extract the stanzas names from git repo
original_stanzas.txt         #extract all stanza urls from original_config
custom_stanzas_header.txt    #extract full stanza blocks of customly written stanzas from original_stanzas
custom_stanzas.txt           #all of the urls of customly written stanzas extracted from original_stanzas
config.txt                   #final config file assembled from header.txt, custom_stanzas_header.txt and stanzas.csv


4)Create a new google sheet and import csv using the stanzas.csv file that was generated from init.sh

5)Highlight the entire TRUE/FALSE column, click insert, select checkbox

6)Select File in upper left -> publish to the web

7)Select Entire Document and Comma-sperated values (.csv)

8)Copy the link and put it in doWork.sh as google_sheet

9)Share with the people that will edit the file

10)Run doWork.sh once

11)Inspect config.txt file, once you're confidant that the new config.txt file is correct make a backup of your original config.txt file in your ezproxy directory then edit doWork.sh and change production to "true".  Next edit the ezproxy_full_path variable and add the full path to your ezproxy directory such as /opt/ezproxy

12)Set up a cronjob to run doWork.sh


doWork.sh creates the following files:
old_google.csv                #copy of google sheets .csv file to compare changes
current_google.csv            #most recent version of the google sheets .csv file
backups directory             #backup directory to save config files with date timestamp


#Google sheets may require a auth token to properly function in the future, here are some starter steps.
https://console.cloud.google.com/
create a new project
https://console.cloud.google.com/apis/library/sheets.googleapis.com
Enable Goolge Sheets API
https://console.cloud.google.com/iam-admin/serviceaccounts
Select the project that was created

todo:
push changes to google docs
purge outdated config files, keep a rolling 30 days?
