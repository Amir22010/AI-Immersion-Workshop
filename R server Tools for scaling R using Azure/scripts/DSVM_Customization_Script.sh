#######################################################################################################################################
#######################################################################################################################################
## THIS SCRIPT CUSTOMIZES THE DSVM BY ADDING HADOOP AND YARN, INSTALLING R-PACKAGES, AND DOWNLOADING DATA-SETS FOR AI Immersion -
## Scaling R on Azure tutorial.
#######################################################################################################################################
#######################################################################################################################################

#!/bin/bash
printf "Setting up hadoop ... \n"
source /etc/profile.d/hadoop.sh

#######################################################################################################################################
## Setup autossh for hadoop service account
#######################################################################################################################################
echo -e 'y\n' | ssh-keygen -t rsa -P '' -f ~hadoop/.ssh/id_rsa
cat ~hadoop/.ssh/id_rsa.pub >> ~hadoop/.ssh/authorized_keys
chmod 0600 ~hadoop/.ssh/authorized_keys
chown hadoop:hadoop ~hadoop/.ssh/id_rsa
chown hadoop:hadoop ~hadoop/.ssh/id_rsa.pub
chown hadoop:hadoop ~hadoop/.ssh/authorized_keys

#######################################################################################################################################
## Start up several services, yarn, hadoop, rstudio server
#######################################################################################################################################
printf "Starting services ... \n"
systemctl start hadoop-namenode hadoop-datanode hadoop-yarn rstudio-server

#######################################################################################################################################
## MRS Deploy Setup
#######################################################################################################################################
printf "Setting up MRS Operationalization ... \n"
cd /home/remoteuser
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/backend_appsettings.json
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/webapi_appsettings.json

mv backend_appsettings.json /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.BackEnd/appsettings.json
mv webapi_appsettings.json /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.WebAPI/appsettings.json

cp /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.WebAPI/autoStartScriptsLinux/*    /etc/systemd/system/.
cp /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.BackEnd/autoStartScriptsLinux/*   /etc/systemd/system/.
systemctl enable frontend
systemctl enable rserve
systemctl enable backend
systemctl start frontend
systemctl start rserve
systemctl start backend

#######################################################################################################################################
# Copy data and code to VM
#######################################################################################################################################
printf "Downloading spark configuration files ... \n"

# Copy Spark configuration files & shell script
cd /home/remoteuser
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/spark-defaults.conf
mv spark-defaults.conf /dsvm/tools/spark/current/conf
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/log4j.properties
mv log4j.properties /dsvm/tools/spark/current/conf

printf "Downloading code files ... \n"
## DOWNLOAD ALL CODE FILES
cd /home/remoteuser
mkdir  Data Code
mkdir Code/RDeployment Code/RIntro Code/ROnAzure

cd /home/remoteuser
cd Code/RDeployment
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/RDeployment-AzureML.Rmd
wget http://vpgeneralblob.blob.core.windows.net/aitutorial/RDeployment-mrsdeploy.r

cd /home/remoteuser
cd Code/RIntro
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/RIntro-data-structures.Rmd
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/RIntro-dplyr.Rmd
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/RIntro-functions.Rmd

cd /home/remoteuser
cd Code/ROnAzure
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/ROnAzure-doAzureParallel.R
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/1-Clean-Join-Subset.r
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/2-Train-Test-Subset.r
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/SetComputeContext.r


printf "Downloading data files ... \n"
## DOWNLOAD ALL DATA FILES
cd /home/remoteuser
cd Data
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/manhattan_df.rds
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/logitModelSubset.RData

# Airline data
cd /home/remoteuser
cd Data
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/AirlineData/WeatherSubsetCsv.tar.gz
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/AirlineData/AirlineSubsetCsv.tar.gz
gunzip WeatherSubsetCsv.tar.gz
gunzip AirlineSubsetCsv.tar.gz
tar -xvf WeatherSubsetCsv.tar
tar -xvf AirlineSubsetCsv.tar
rm WeatherSubsetCsv.tar AirlineSubsetCsv.tar

printf "Copying files to HDFS ... \n"
## Copy data to HDFS
cd /home/remoteuser
cd Data

# Make hdfs directories and copy things over to HDFS
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/rserve2
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/rserve2/Predictions
/opt/hadoop/current/bin/hadoop fs -chmod -R 777 /user/RevoShare/rserve2

/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser/Data
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser/Models
/opt/hadoop/current/bin/hadoop fs -copyFromLocal * /user/RevoShare/remoteuser/Data


#######################################################################################################################################
#######################################################################################################################################
printf "Installing R packages ... \n"

# Install R packages
cd /home/remoteuser
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/InstallPackages.R

cd /usr/bin
Revo64-9.0 --vanilla --quiet  <  /home/remoteuser/InstallPackages.R

#######################################################################################################################################
#######################################################################################################################################
printf "Changing directory ownership ... \n"

## Change ownership of some of directories
cd /home/remoteuser 
chown -R remoteuser Code Data

su hadoop -c "/opt/hadoop/current/bin/hadoop fs -chown -R remoteuser /user/RevoShare/rserve2" 
su hadoop -c "/opt/hadoop/current/bin/hadoop fs -chown -R remoteuser /user/RevoShare/remoteuser" 

printf "Done! \n"
#######################################################################################################################################
#######################################################################################################################################
## END
#######################################################################################################################################
#######################################################################################################################################
