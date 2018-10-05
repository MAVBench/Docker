This repo contains relavant files for building our docker from scratch on jetson-tx2 (Note: We plan to release the docker by Micro conference 2018(Oct 20th). Please stay tuned)

**Installing Docker on TX2**
https://github.com/Technica-Corporation/Tegra-Docker

**Installing docker-compose**
sudo pip install docker-compose

**Incase you encountered docker persmission issue**
sudo usermod -a -G docker $USER

**Building our Docker Image**
    docker-compose build ros-service-kinetic; 
**Running our Docker Image**
  1. xhost + //making sure your xservr is accepting connections from other hosts
  2. ./tx2-docker run ${name of the folder that you are in now}_ros-service-kinetic (note that tx2-docker is executable provided by https://github.com/Technica-Corporation/Tegra-Docker)
  3. cpy paste the commands echod by the above tx2-docker and you should see shell promp: 
  root@tegra-ubuntu. once in the container, you can launch our applications.

Note: step 2 should run the docker instead. so we need to figure out why it's not

**sourcing the Catkin Workspace**
source ~/catkin_ws/devel/setup.bash 

**Running the Benchmarks**
roslaunch $pkg_name $launch_file 
for example:
    roslaunch package_delivery package_delivery.launch 
    roslaunch package_delivery scanning.launch 
    roslaunch mapping_and_sar mapping.launch 
    roslaunch mapping_and_sar sar.launch 
    roslaunch follow_the_leader follow_the_leader.launch 
