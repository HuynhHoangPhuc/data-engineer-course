# Step-by-Step

## 1. Update system packages on Ubuntu
```bash
sudo apt update && sudo apt upgrade -y
```

## 2. Install OpenJDK for Hadoop
```bash
sudo apt install openjdk-11-jdk -y
```

Check the version to confirm the installation

```bash
java --version
```

## 3. Create a dedicated user for Hadoop

Create a user named `hadoop`

```bash
sudo adduser hadoop
```

Give the user sudo privileges:

```bash
sudo usermod -aG sudo hadoop
```

Switch to the hadoop user

```bash
su - hadoop
```

## 4. Configure passwordless SSH
Hadoop uses SSH to manage its services across nodes (or within a single node for pseudo-distributed mode, connecting to `localhost`)

Install and enable SSH

```bash
sudo apt install openssh-server openssh-client -y
sudo systemctl enable ssh
```

Generate an SSH keypair

```bash
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
```

Add the generated public key to the list of authorized keys for the user hadoop so it can log into itself (`localhost`) without a password

```bash
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Set the necessary permissions for the file to make sure only the owner of the file can read and write to it

```bash
chmod 600 ~/.ssh/authorized_keys
```

Verify the hadoop can SSH to localhost without being prompted for a password

```bash
ssh localhost
```

Exit the SSH session to return to your original prompt

```bash
exit
```

## 5. Download and extract Hadoop

Download Hadoop using wget

```bash
cd ~
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz
```

Extract the downloaded file

```bash
tar -xzf hadoop-*.tar.gz
```

Move the extracted folder to `/usr/local/` and rename it to `hadoop` for simplicity

```bash
sudo mv hadoop-3.4.1 /usr/local/hadoop
```

Ensure `hadoop` owns the `/usr/local/hadoop` directory and its contents

```bash
sudo chown -R hadoop:hadoop /usr/local/hadoop
```

## 6. Configure Hadoop environment variables

Open the `.bashrc` file for editing

```bash
vi ~/.bashrc
```

Add the following lines to the end of the file

```bash
# Hadoop Environment Variables
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_INSTALL=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
```

Set the environment variables for Java to allow other applications to find it

```bash
vi ~/.bashrc
```

Add the following lines

```bash
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$PATH:$JAVA_HOME/bin
```

Source the ~/.bashrc file to apply the changes made

```bash
source ~/.bashrc
```

Verify that the `JAVA_HOME` environment variable has been correctly set

```bash
echo  $JAVA_HOME
```

Verify Hadoop installation using

```bash
hadoop version
```

Verify that HADOOP_HOME is set correctly

```bash
echo $HADOOP_HOME
```

Explicitly set `JAVA_HOME` within Hadoop's configuration. Open the `hadoop-env.sh` file for editing

```bash
vi $HADOOP_HOME/etc/hadoop/hadoop-env.sh
```

Look for a line that starts with `# export JAVA_HOME=`. Uncomment it (remove the #) and set it to your `JAVA_HOME` path:

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

## 7. Configure Hadoop XML Files for Pseudo-Distributed Mode

Configure the core XML files located in `$HADOOP_HOME/etc/hadoop/`. These files dictate how Hadoop functions in pseudo-distributed mode.

Start by creating the directories Hadoop will use for HDFS data storage:

```bash
mkdir -p $HADOOP_HOME/hdfs/namenode
mkdir -p $HADOOP_HOME/hdfs/datanode
```

Then set the ownership of the directory and its contents to the hadoop user.

```bash
sudo chown -R hadoop:hadoop $HADOOP_HOME/hdfs
```

Now, edit the XML configuration files

* `core-site.xml`

    Open the `core-site.xml` file:
    ```bash
    vi $HADOOP_HOME/etc/hadoop/core-site.xml
    ```
    Replace the empty `<configuration></configuration>` tags with the following:
    ```xml
    <configuration>
        <property>
            <name>fs.defaultFS</name>
            <value>hdfs://localhost:9000</value>
            <description>The default file system URI</description>
        </property>
    </configuration>
    ```
    `hdfs://localhost:9000` tells Hadoop to use HDFS running on localhost at port 9000.

* `hdfs-site.xml`

    Open the `hdfs-site.xml` file:
    ```bash
    vi $HADOOP_HOME/etc/hadoop/hdfs-site.xml
    ```
    Add the following between the `<configuration></configuration>` tags:
    ```xml
    <configuration>
        <property>
            <name>dfs.replication</name>
            <value>1</value>
            <description>Default block replication.</description>
        </property>
        <property>
            <name>dfs.name.dir</name>
            <value>file:///usr/local/hadoop/hdfs/namenode</value>
            <description>Path on the local filesystem where the NameNode stores the namespace and transaction logs.</description>
        </property>
        <property>
            <name>dfs.data.dir</name>
            <value>file:///usr/local/hadoop/hdfs/datanode</value>
            <description>Path on the local filesystem where the DataNode stores its blocks.</description>
        </property>
    </configuration>
    ```
    This configuration sets up a single-replica HDFS environment using the data directories you created earlier.

* `mapred-site.xml`

    Open the `mapred-site.xml` file for edit:
    ```bash
    vi $HADOOP_HOME/etc/hadoop/mapred-site.xml
    ```
    Replace the empty `<configuration></configuration>` tags with:
    ```xml
    <configuration>
        <property>
            <name>mapreduce.framework.name</name>
            <value>yarn</value>
            <description>The runtime framework for MapReduce. Can be local, classic or yarn.</description>
        </property>
        <property>
            <name>yarn.app.mapreduce.am.env</name>
            <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
        </property>
        <property>
            <name>mapreduce.map.env</name>
            <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
        </property>
        <property>
            <name>mapreduce.reduce.env</name>
            <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
        </property>
    </configuration>
    ```
    This enables MapReduce to run on YARN and sets the appropriate environment variables.

* `yarn-site.xml`

    Finally, edit the yarn-site.xml file:
    ```bash
    vi $HADOOP_HOME/etc/hadoop/yarn-site.xml
    ```
    Add the following between the `<configuration></configuration>` tags:
    ```xml
    <configuration>
        <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
            <description>Auxilliary services required by the NodeManager.</description>
        </property>
    </configuration>
    ```
    This enables the shuffle service, which is necessary for running MapReduce jobs on YARN.

## 8. Format HDFS NameMode
Before HDFS can be used, the NameNode must be formatted. This step initializes the HDFS file system and sets up the directory structure defined in your `hdfs-site.xml`.

Run:

```bash
hdfs namenode -format
```

## 9. Start Hadoop services
Hadoop provides handy scripts to start both HDFS and YARN services.

Run the following script to start the NameNode, DataNode, and SecondaryNameNode:

```bash
start-dfs.sh
```

Next, start the ResourceManager and NodeManager:

```bash
start-yarn.sh
```

## 10. Verify that Hadoop daemons are running
To confirm that all Hadoop services started successfully, use the `jps` command. This tool lists all Java processes currently running on the system.

```bash
jps
```

## 11. Access Web UIs
Open a web browser and navigate to the Hadoop web interfaces:

* If you are running Hadoop locally on your own machine, use:

    * HDFS NameNode UI: http://localhost:9870

    * YARN ResourceManager UI: http://localhost:8088

* If your Hadoop is running on a remote server replace localhost with your server's public IP address:

    * HDFS NameNode UI: `http://<server-ip>:9870`

    * YARN ResourceManager UI: `http://<server-ip>:8088`

## 12. Stopping Hadoop services

Stop the YARN daemons by running:

```bash
stop-yarn.sh
```

Stop the HDFS daemons using:

```bash
stop-dfs.sh
```

Run jps again to confirm that all Hadoop processes have been terminated:

```
jps
```
