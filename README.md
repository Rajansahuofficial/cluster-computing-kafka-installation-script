Apache Kafka 3.4.0 -- Windows PowerShell Installer
Author: Rajan Sahu
Version: 1.0
Date: 2026-11-06

A PowerShell script that automates the setup of Apache Kafka 3.4.0 on
Windows using the ZooKeeper-based configuration.

The installer downloads Kafka, extracts it to C:\kafka, configures
ZooKeeper and the Kafka broker, creates their data directories, and adds
KAFKA_HOME to the current user's environment variables.
Features
- Checks that Java is available before installation.
- Checks for tar.exe, which is used to extract the Kafka archive.
- Downloads the Kafka 3.4.0 binary archive.
- Installs Kafka in C:\kafka.
- Configures ZooKeeper's dataDir.
- Configures Kafka's log.dirs.
- Creates the ZooKeeper and Kafka data directories.
- Sets the user-level KAFKA_HOME environment variable.
- Adds Kafka's Windows scripts directory to the user-level PATH.
- Checks Kafka's Windows batch files for references to wmic.
- Optionally opens ZooKeeper and Kafka in separate Command Prompt
  windows.
Requirements
- Windows 10 or Windows 11.
- An internet connection.
- PowerShell, run as Administrator.
- Java installed and available in PATH.
- A JDK is recommended so that both java and javac are available.
- tar.exe available in PATH (included with supported modern
  Windows installations).
Java note: The script checks for Java and warns if javac is
missing. It does not install Java or configure JAVA_HOME. Configure
your JDK before running the installer. Kafka 3.4.0 is an older
release; check the Apache Kafka documentation for Java-version
compatibility with your environment.

Files
  File                  Description
  install-kafka.ps1   PowerShell installer
README.md           Project documentation
Installation
1. Download or clone this repository
Using Git:
git clone <YOUR-GITHUB-REPOSITORY-URL>
cd <YOUR-REPOSITORY-FOLDER>
Alternatively, download the repository as a ZIP file from GitHub and
extract it.
2. Open PowerShell as Administrator
Search for PowerShell, right-click it, and select Run as
administrator. Navigate to the folder containing install-kafka.ps1.
3. Allow script execution for this PowerShell session
Set-ExecutionPolicy Bypass -Scope Process -Force
This changes the execution policy only for the current PowerShell
process.
4. Run the installer
.\install-kafka.ps1
The script will stop if C:\kafka already exists. If you have an
existing Kafka installation, back it up or rename that directory before
running the installer. The script does not overwrite it.
Start Kafka
After installation, start the two services in separate Command Prompt
windows.
1. Start ZooKeeper
Open the first CMD window and run:
cd /d C:\kafka
bin\windows\zookeeper-server-start.bat config\zookeeper.properties
Keep this window open.
2. Start the Kafka broker
Open a second CMD window and run:
cd /d C:\kafka
bin\windows\kafka-server-start.bat config\server.properties
Keep this window open too.
Optional: Open both services from the installer
You can ask the installer to open separate CMD windows for ZooKeeper and
Kafka:
.\install-kafka.ps1 -Start
The script waits briefly after opening ZooKeeper, then opens the Kafka
broker window. Check both windows for startup errors and keep them open
while using Kafka.
Verify the installation
Open a third CMD window.
1. Create a topic
cd /d C:\kafka
bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic test
2. List topics
bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092
You should see:
test
3. Start a producer
bin\windows\kafka-console-producer.bat --broker-list localhost:9092 --topic test
Type a message and press Enter, for example:
Hello Kafka
Learning Apache Kafka
This is my first Kafka message
4. Start a consumer
Open another CMD window and run:
cd /d C:\kafka
bin\windows\kafka-console-consumer.bat --topic test --bootstrap-server localhost:9092 --from-beginning
The consumer should display the messages sent by the producer.
Configuration and directories
The installer uses these paths:

  Item                         Path / setting
  Kafka installation           C:\kafka
Kafka environment variable   KAFKA_HOME=C:\kafka
ZooKeeper configuration      C:\kafka\config\zookeeper.properties
ZooKeeper data               C:\kafka\zookeeper-data
Kafka broker configuration   C:\kafka\config\server.properties
Kafka log data               C:\kafka\kafka-logs
Kafka broker address         localhost:9092
Example topic                test

The installer sets the following configuration values:
# config/zookeeper.properties
dataDir=C:/kafka/zookeeper-data
# config/server.properties
log.dirs=C:/kafka/kafka-logs
The user-level PATH entry added by the script is:
%KAFKA_HOME%\bin\windows
Close and reopen terminals after installation so they load the updated
environment variables.
Troubleshooting
java is not recognized
Install a JDK and add its bin directory to your Windows PATH. Open a
new terminal and check:
java -version
javac -version
javac is not recognized, but java works
Your Java runtime may be available while the JDK compiler directory is
missing from PATH. Add your JDK's bin directory to PATH. For
example, use the actual JDK installation path on your computer:
C:\Program Files\Java\jdk-<your-version>\bin
tar.exe is not recognized
The installer uses Windows tar.exe to extract the .tgz archive. Use
a supported Windows installation that includes tar.exe, or extract the
archive manually with an archive utility and adjust the installation
process.
C:\kafka already exists
The installer intentionally refuses to overwrite an existing
installation. Stop Kafka and ZooKeeper, back up the folder if needed,
and rename or move C:\kafka before running the installer again.
'wmic' is not recognized
Some older Kafka Windows batch scripts may call WMIC, which is
unavailable on some newer Windows installations. The installer checks
for WMIC references but does not automatically edit Kafka's batch
files.

If startup shows this error, inspect the exact batch file and the
command that invokes WMIC before changing anything. Do not assume that
adding a heap setting alone removes every WMIC dependency. If you need
to apply the workaround from your installation notes, the relevant file
is:
C:\kafka\bin\windows\kafka-server-start.bat
The notes specify this heap setting:
set KAFKA_HEAP_OPTS=-Xmx1G -Xms512M
This sets Kafka's Java heap size; it is not a general replacement for a
missing WMIC command. Back up the batch file before editing it.
Kafka broker does not start
- Confirm that ZooKeeper started successfully and is still running.
- Check the Kafka broker CMD window for the first error message.
- Confirm that port 9092 is not already in use.
- Check that the configured data directories are accessible.
Stopping Kafka
In the Kafka and ZooKeeper CMD windows, press Ctrl+C to stop each
service. Stop the Kafka broker first, then ZooKeeper.
Important notes
- This project installs Kafka 3.4.0, not the latest Kafka release.
- This setup uses ZooKeeper, as supported by the Kafka 3.4.0
  configuration used here.
- The installer does not install Java, Hadoop, or other external
  services.
- The installer does not create topics or run producer/consumer tests
  automatically; those steps are documented above.
- Review the script before running it, especially when running
  PowerShell as Administrator.
References
- Apache Kafka downloads
- Kafka 3.4.0 binary
  archive
Author
Rajan Sahu

If you find this project useful, you can ⭐ the repository on GitHub.
