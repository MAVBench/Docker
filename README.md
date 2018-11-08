
This repo contains relavant files for either pulling the existing docker image (almost 99.99% likely what you need) or building our docker from scratch on jetson-tx2. Note that docker should be used as step toward familiarzing yourself with MAVBench. If you are serious about using MAVBench to do research, please use the stand alone build [MAVBench](https://github.com/MAVBench/tx2) to get access to various utilities such as profiling tools. 

## Building It
# Companion Computer 

This computer is responsible for running the compute intensive workloads.

## System Requirements
**Hardware**:  
+ Jetson TX2  

**Software**:  
+ Ubuntu: 16.04  
+ JetPack (Nvidia SDK): 3.2 (We have only tested our setup with 3.2 but we suspect, it'll work with higher versions as well)

**For lazy but happy**
1. Install Docker on TX2 by following the instructions bellow.  
https://github.com/Technica-Corporation/Tegra-Docker

2. Install docker-compose.
```bash
sudo pip install docker-compose;
```
3. In case you encoutner docker permission issue.
```bash
sudo usermod -a -G docker $USER;
```

4. clone our repo
```bash
git clone git@github.com:MAVBench/Docker.git mavbench_docker_repo;
```

4. Pull the Existing Docker Image
```bash
cd mavbench_docker_repo;
docker pull zaddan/mavbench:$tag #(find the tags here https://hub.docker.com/r/zaddan/mavbench/tags/)
```
## Building From Scatch (most likely, you must skip this step. Mainly for Internal use)
**copying over cuda libraries**
1. Some of our packages require access to cuda, hence we need to 
include them in the docker context
```bash
cd mavbench_docker_repo;
which nvcc ;#(to find where cuda is installed usually /usr/local/cuda. Note that when copying over, make sure to set the destination name as cuda as shown bellow);
cp -r ${cuda_folder} cuda;
cp -r libcuda.so .;
``` 
2. Building our Docker Image**
```bash
 docker-compose build ros-service-kinetic; 
```

## Running it
1. Get the command to run the docker.
```bash
  cd mavbech_docker_repo;
  xhost + ;#making sure your xservr is accepting connections from other hosts
  ./tx2-docker run ${docker image name) #(e.g. zaddan/mavbench/$tag) (note that tx2-docker is highly inspired by https://github.com/Technica-Corporation/Tegra-Docker)
  ```
  3. cpy paste the commands echod by the above tx2-docker and you should see shell promp: 
  root@tegra-ubuntu. once in the container, you can launch our applications.

 4. Sourcing the Catkin Workspace and relevant environment variables**
```bash
source ~/tx2/build_scripts/companion_setup_env_var.sh
source ~/tx2/catkin_ws/devel/setup.bash 
```
5. Running the Benchmarks
```bash
roslaunch $pkg_name $launch_file #example: roslaunch package_delivery package_delivery.launch
```
Example of all our packages and applications:
    roslaunch package_delivery package_delivery.launch 
    roslaunch package_delivery scanning.launch 
    roslaunch mapping_and_sar mapping.launch 
    roslaunch mapping_and_sar sar.launch 
    roslaunch follow_the_leader follow_the_leader.launch 
