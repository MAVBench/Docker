This repo contains relavant files for building our docker from scratch on jetson-tx2

**Installing Docker on TX2**
https://github.com/Technica-Corporation/Tegra-Docker

**Installing docker-compose**
sudo pip install docker-compose

**Incase you encountered docker persmission issue**
sudo usermod -a -G docker $USER


**cloning the repo**
git clone git@github.com:MAVBench/Docker.git mavbench_docker_repo


**copying over cuda libraries**
some of our packages require access to cuda, hence we need to 
include them in the docker context
- cd mavbench_docker_repo
- which nvcc (to find where cuda is installed usually /usr/local/cuda. Note that when copying over, make sure to set the destination name as cuda as shown bellow)
- cp -r ${cuda_folder} cuda
- cp -r libcuda.so .
 

**Building our Docker Image**
    docker-compose build ros-service-kinetic; 
**Running our Docker Image**
  1. xhost + //making sure your xservr is accepting connections from other hosts
  2. ./tx2-docker run ${name of the folder that you are in now}_ros-service-kinetic (note that tx2-docker is executable provided by https://github.com/Technica-Corporation/Tegra-Docker)
  3. cpy paste the commands echod by the above tx2-docker and you should see shell promp: 
  root@tegra-ubuntu. once in the container, you can launch our applications.

Note: step 2 should run the docker instead. so we need to figure out why it's not

**sourcing the Catkin Workspace and relevant environment variables**
source ~/tx2/build-scripts/companion_setup_env_var.sh
source ~/tx2/catkin_ws/devel/setup.bash 

**Running the Benchmarks**
roslaunch $pkg_name $launch_file 
for example:
    roslaunch package_delivery package_delivery.launch 
    roslaunch package_delivery scanning.launch 
    roslaunch mapping_and_sar mapping.launch 
    roslaunch mapping_and_sar sar.launch 
    roslaunch follow_the_leader follow_the_leader.launch 
