# postgres11
postgres 11 With Latest PLJava Containerization With CentOS Base Image.
Install Docker From Yum Repositories.
git clone https://github.com/ramujagini/postgres11.git.
You Have Now Makefile, Dockerfile and docker-entrypoint.sh file.
Using Make Command You can build Image centospg112 and run a container pg11.
Step 1: "make build" (builds the image from Docker file).
Step 2: "make run" (instantiates The Container From Built Image).
If you do not have Make installed,  you have to execute Docker commands Manually from Makefile.
Output: Container starts with a running postgres with enabled PLJava Extension.