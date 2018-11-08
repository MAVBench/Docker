
This repo contains relavant files for either pulling the existing docker image (almost 99.99% likely what you need) or building our docker from scratch on jetson-tx2. Note that docker should be used as step toward familiarzing yourself with MAVBench. If you are serious about using MAVBench to do research, please use the stand alone build [MAVBench](https://github.com/MAVBench/tx2) since utility for profiling is always available there. 
TODO: update the mavbench-apps submodule to use the latest updates

## Cloning the Repo and Installing Prereqs
**Installing Docker on TX2**
https://github.com/Technica-Corporation/Tegra-Docker

**Installing docker-compose**
sudo pip install docker-compose

**Incase you encountered docker persmission issue**
sudo usermod -a -G docker $USER

**cloning the repo**
git clone git@github.com:MAVBench/Docker.git mavbench_docker_repo


## Pulling the Existing Docker Image
- cd mavbench_docker_repo
- docker pull zaddan/mavbench:$tag (find the tags here https://hub.docker.com/r/zaddan/mavbench/tags/)

## Building From Scatch (most likely, you must skip this step. Mainly for Internal use)
**copying over cuda libraries**
some of our packages require access to cuda, hence we need to 
include them in the docker context
- cd mavbench_docker_repo
- which nvcc (to find where cuda is installed usually /usr/local/cuda. Note that when copying over, make sure to set the destination name as cuda as shown bellow)
- cp -r ${cuda_folder} cuda
- cp -r libcuda.so .
 
**Building our Docker Image**
    docker-compose build ros-service-kinetic; 


## How to Run
  1. cd mavbech_docker_repo
  2. xhost + //making sure your xservr is accepting connections from other hosts
  2. ./tx2-docker run ${docker image name) (e.g. zaddan/mavbench/$tag) (note that tx2-docker is highly inspired by https://github.com/Technica-Corporation/Tegra-Docker)
  3. cpy paste the commands echod by the above tx2-docker and you should see shell promp: 
  root@tegra-ubuntu. once in the container, you can launch our applications.

Note: step 2 should run the docker instead. so we need to figure out why it's not

**sourcing the Catkin Workspace and relevant environment variables**
source ~/tx2/build-scripts/companion_setup_env_var.sh
source ~/tx2/catkin_ws/devel/setup.bash 

**Running the Benchmarks**
roslaunch $pkg_name $launch_file (add some explanation for pre_mission stuff)
for example:
    roslaunch package_delivery package_delivery.launch 
    roslaunch package_delivery scanning.launch 
    roslaunch mapping_and_sar mapping.launch 
    roslaunch mapping_and_sar sar.launch 
    roslaunch follow_the_leader follow_the_leader.launch 
