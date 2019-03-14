# Author: Ramu Jagini
FROM centos:latest

#Creating Postgres User
RUN useradd postgres -d /var/lib/pgsql
RUN echo "postgres" | passwd postgres --stdin

#Installing Prerequisites for Postgres installation and Pljava Compilations.
RUN set -x; \
yum install -y java-1.8.0-openjdk.x86_64; \
yum install -y gcc\* ;\
yum install -y https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm ;\
yum install -y postgresql11\* --skip-broken;\
yum install -y maven ;\
yum install -y git ;\
yum install -y openssl-devel.x86_64;\
yum install -y sudo;\
echo "export JAVA_HOME=/usr/lib/jvm/$(ls -l /usr/lib/jvm | grep ^d | awk '{print $9}')" > /root/.bash_profile;\
export JAVA_HOME=/usr/lib/jvm/$(ls -l /usr/lib/jvm | grep ^d | awk '{print $9}');

#Java Location Tried to by identified dynamically as yum repos keep updated
#RUN JAVA_HOME=$(update-alternatives --display java | grep point | sed 's?^.* ??' | sed 's/\/jre/:/g' | cut -d ':' -f1);\
#echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bash_profile;\
#export JAVA_HOME=$JAVA_HOME;

#Setting Up Env Variables to persist intermediate containers while docker flow execution.
ENV PGHOME /usr/pgsql-11
ENV PGDATABASE postgres
ENV PGUSER postgres
ENV PGPORT 5432
ENV PGLOCALEDIR /usr/pgsql-11/share/locale
ENV MANPATH $MAN_PATH:/usr/pgsql-11/share/man
ENV PGDATA /var/lib/pgsql/11/data
ENV PATH $PATH:$PGHOME/bin:$PGHOME/lib

#Copy The Open SSL rpm seperately to postgres as those will not come along with pg binaries, and these are needed for PLJava Complilation.
RUN mkdir -p $PGHOME/include;\
cp -pR /usr/include/openssl/ $PGHOME/include/openssl;\
chown postgres:postgres -R $PGHOME;\

#Modify The ldconfig File for PLJava
echo -e "$(grep JAVA_HOME /root/.bash_profile | cut -d '=' -f2)/jre/lib/amd64\n\
$(grep JAVA_HOME /root/.bash_profile | cut -d '=' -f2)/jre/lib/amd64/server\n\
$PGHOME/lib\n"\
>>/etc/ld.so.conf; \

#Get PLJava From ramujagini git hub of version 1.5.3, and use maven to compile and build PLJava.
git clone https://github.com/ramujagini/pljava.git; \
chmod -R 777 pljava; \
cd pljava; \
mvn -Pwnosign -Dnar.cores=1 clean install; \
cp -pr /pljava/pljava-so/target/nar/pljava-so-1.6.0-SNAPSHOT-amd64-Linux-gpp-plugin/lib/amd64-Linux-gpp/plugin/libpljava-so-1.6.0-SNAPSHOT.so /usr/pgsql-11/lib/pljava.so; \
cp -pr /pljava/pljava/target/pljava-1.6.0-SNAPSHOT.jar /usr/pgsql-11/share/extension/pljava--1.5.3.jar; \

#Generate install.sql File for Creating pljava Extension as It is removed from pljava totally and the installation with out install.sql will be revised in further versions of docker files.
echo -e "-- Note: as of PL/Java 1.5.0, this file is obsolescent and not needed to install\n \
-- PL/Java. See "Installing into PostgreSQL" at the project web site for current\n \
-- installation instructions that do not involve this file. This will eventually\n \
-- grow out of date and be removed.\n \
--\n \
-- You can generate a local copy of the web site with 'mvn site site:stage' and\n \
-- point a web browser at target/site/staging/install/install.html for the\n \
-- installation instructions offline.\n \
\n \
CREATE SCHEMA sqlj;\n \
GRANT USAGE ON SCHEMA sqlj TO public;\n \
\n \
CREATE FUNCTION sqlj.java_call_handler()\n \
  RETURNS language_handler AS 'pljava'\n \
  LANGUAGE C;\n \
\n \
CREATE TRUSTED LANGUAGE java HANDLER sqlj.java_call_handler;\n \
\n \
CREATE FUNCTION sqlj.javau_call_handler()\n \
  RETURNS language_handler AS 'pljava'\n \
  LANGUAGE C;\n \
\n \
CREATE LANGUAGE javaU HANDLER sqlj.javau_call_handler;\n \
\n \
CREATE TABLE sqlj.jar_repository(\n \
        jarId           SERIAL PRIMARY KEY,\n \
        jarName         VARCHAR(100) UNIQUE NOT NULL,\n \
        jarOrigin   VARCHAR(500) NOT NULL,\n \
        jarOwner        NAME NOT NULL,\n \
        jarManifest     TEXT\n \
);\n \
GRANT SELECT ON sqlj.jar_repository TO public;\n \
\n \
CREATE TABLE sqlj.jar_entry(\n \
        entryId     SERIAL PRIMARY KEY,\n \
        entryName       VARCHAR(200) NOT NULL,\n \
        jarId           INT NOT NULL REFERENCES sqlj.jar_repository ON DELETE CASCADE,\n \
        entryImage  BYTEA NOT NULL,\n \
        UNIQUE(jarId, entryName)\n \
);\n \
GRANT SELECT ON sqlj.jar_entry TO public;\n \
\n \
CREATE TABLE sqlj.jar_descriptor(\n \
        jarId           INT REFERENCES sqlj.jar_repository ON DELETE CASCADE,\n \
        ordinal         INT2,\n \
        PRIMARY KEY (jarId, ordinal),\n \
        entryId     INT NOT NULL REFERENCES sqlj.jar_entry ON DELETE CASCADE\n \
);\n \
GRANT SELECT ON sqlj.jar_descriptor TO public;\n \
\n \
CREATE TABLE sqlj.classpath_entry(\n \
        schemaName      VARCHAR(30) NOT NULL,\n \
        ordinal         INT2 NOT NULL,\n \
        jarId           INT NOT NULL REFERENCES sqlj.jar_repository ON DELETE CASCADE,\n \
        PRIMARY KEY(schemaName, ordinal)\n \
);\n \
GRANT SELECT ON sqlj.classpath_entry TO public;\n \
\n \
CREATE TABLE sqlj.typemap_entry(\n \
        mapId           SERIAL PRIMARY KEY,\n \
        javaName        VARCHAR(200) NOT NULL,\n \
        sqlName         NAME NOT NULL\n \
);\n \
GRANT SELECT ON sqlj.typemap_entry TO public;\n \
\n \
CREATE FUNCTION sqlj.install_jar(VARCHAR, VARCHAR, BOOLEAN) RETURNS void\n \
        AS 'org.postgresql.pljava.management.Commands.installJar'\n \
        LANGUAGE java SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.install_jar(BYTEA, VARCHAR, BOOLEAN) RETURNS void\n \
        AS 'org.postgresql.pljava.management.Commands.installJar'\n \
        LANGUAGE java SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.replace_jar(VARCHAR, VARCHAR, BOOLEAN) RETURNS void\n \
        AS 'org.postgresql.pljava.management.Commands.replaceJar'\n \
        LANGUAGE java SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.replace_jar(BYTEA, VARCHAR, BOOLEAN) RETURNS void\n \
        AS 'org.postgresql.pljava.management.Commands.replaceJar'\n \
        LANGUAGE java SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.remove_jar(VARCHAR, BOOLEAN) RETURNS void\n \
        AS 'org.postgresql.pljava.management.Commands.removeJar'\n \
        LANGUAGE java SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.set_classpath(VARCHAR, VARCHAR) RETURNS void\
        AS 'org.postgresql.pljava.management.Commands.setClassPath'\
        LANGUAGE java SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.get_classpath(VARCHAR) RETURNS VARCHAR\n \
        AS 'org.postgresql.pljava.management.Commands.getClassPath'\n \
        LANGUAGE java STABLE SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.add_type_mapping(VARCHAR, VARCHAR) RETURNS void\n \
        AS 'org.postgresql.pljava.management.Commands.addTypeMapping'\n \
        LANGUAGE java SECURITY DEFINER;\n \
\n \
CREATE FUNCTION sqlj.drop_type_mapping(VARCHAR) RETURNS void\n \
        AS 'org.postgresql.pljava.management.Commands.dropTypeMapping'\n \
        LANGUAGE java SECURITY DEFINER;" \
>/usr/pgsql-11/share/extension/pljava--1.5.3.sql

#Create A Pljava Control File For Loading Extension Into Database.
RUN echo -e "# pljava extension\n\
comment = 'PL/Java bundled as an extension'\n\
default_version = '1.5.3'\n\
relocatable = false\n"\
>/usr/pgsql-11/share/extension/pljava.control; \

#Create a Password File and initiate a cluster in pg instance using initdb
echo -e 'postgres' >$PGHOME/pass.conf; \
sudo su - postgres -c "$PGHOME/bin/initdb --pwfile $PGHOME/pass.conf -U postgres -E utf8 -D $PGDATA" ;\

#allow all ips as a trust authentication, can be changed to as your wish
echo "host    all             all             0.0.0.0/0            trust" >> $PGDATA/pg_hba.conf ;\

#Adding Few of Mandatory Parameters for PLJava to be loaded into PG Cluster Databases.
echo -e "dynamic_library_path= '/usr/pgsql-11/lib:\$libdir'\n\
pljava.classpath= '/usr/pgsql-11/share/extension/pljava--1.5.3.jar'\n\
pljava.vmoptions = '-Xms32M -Xmx64M -XX:ParallelGCThreads=2'\n\
pljava.libjvm_location = '/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.201.b09-2.el7_6.x86_64/jre/lib/amd64/server/libjvm.so'\n\
listen_addresses = '*'\n"\
>> $PGDATA/postgresql.conf;\

#Modifying the postgres OS Users's bash profile as it will setup the complete Env after logged into container
echo -e "[ -f /etc/profile ] && source /etc/profile\n \
export PGHOME=$PGHOME \n \
export PGDATABASE=postgres\n \
export PGUSER=postgres\n \
export PGPORT=5432\n \
export PGLOCALEDIR=\$PGHOME/share/locale\n \
export MANPATH=\$MAN_PATH:\$PGHOME/share/man\n \
PGDATA=$PGDATA \n \
export PGDATA\n \
# If you want to customize your settings,\n \
# Use the file below. This is not overridden\n \
# by the RPMS.\n \
[ -f /opt/pgsql/.pgsql_profile ] && source /opt/pgsql/.pgsql_profile\n \
$(grep JAVA_HOME /root/.bash_profile) \n \
export JRE_HOME=$JAVA_HOME/jre\n \
export PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin:\$JRE_HOME/lib/amdb64:\$JRE_HOME/lib/amdb64/server:\$PGHOME/bin:\$PGHOME/lib\n" \
>/var/lib/pgsql/.bash_profile; \

#Making sure all the postgres binaries and libs and data directories are owned by postgres os user.
chown postgres:postgres -R /var/lib/pgsql/.bash_profile $PGHOME $PGDATA ;

#Start The Postgres Instance
RUN sudo su - postgres -c "$PGHOME/bin/pg_ctl start -D $PGDATA"; \

#Connect To Postgres instance as postgres user to postgres database and load pljava extension, similarly the pljava extension has to be loaded onto users' requried databases.
sudo su - postgres -c "$PGHOME/bin/psql -c 'create EXTENSION pljava';"; \
exit

#Exposing the Docker constainer pg port to Server/Vm's port.
EXPOSE 5432:5432

#Copying And SettingUp Entrypoint
COPY docker-entrypoint.sh /var/lib/pgsql/
RUN ln -s /var/lib/pgsql/docker-entrypoint.sh /; \
chmod 755 /docker-entrypoint.sh;
ENTRYPOINT ["/docker-entrypoint.sh"]

#Login Command, as an entrypoint to Docker.
CMD ["postgres"]
