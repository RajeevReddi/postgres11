# postgres11
postgres 11 With Latest PLJava Containerization With CentOS Base Image. <br>
Install Docker From Yum Repositories. <br>
git clone https://github.com/ramujagini/postgres11.git. <br>
You Have Now Makefile, Dockerfile and docker-entrypoint.sh file. <br>
Using Make Command You can build Image centospg112 and run a container pg11. <br>
Step 1: "make build" (builds the image from Docker file). <br>
Step 2: "make run" (instantiates The Container From Built Image). <br>
If you do not have Make installed,  you have to execute Docker commands Manually from Makefile. <br>
Output: Container starts with a running postgres with enabled PLJava Extension. <br>
