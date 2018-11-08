This document describes the steps necessary for building MAVBench docker toolset.    
Note: Please read until the end before setting up your system.   
Note: Please setup the companion computer before the host.  

[comment]: <p align="center"> 
# Companion Computer 

This computer is responsible for running the compute intensive workloads.

## System Requirements
**Hardware**:  
+ Jetson TX2  

**Software**:  
+ Ubuntu: 16.04  
+ JetPack (Nvidia SDK): 3.2 (We have only tested our setup with 3.2 but we suspect, it'll work with higher versions as well)  

## Building It 
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

4. Clone our repo
```bash
git clone git@github.com:MAVBench/Docker.git mavbench_docker_repo;
```

5. Pull the Existing Docker Image
```bash
cd mavbench_docker_repo;
docker pull zaddan/mavbench:$tag #(find the tags here https://hub.docker.com/r/zaddan/mavbench/tags/)
```
**Building From Scatch**   
Note: Mainly for Internal developers. 
1. Copy over cuda libraries. Some of our packages require access to cuda, hence we need to 
include them in the docker context
```bash
cd mavbench_docker_repo;
which nvcc ;#(to find where cuda is installed usually /usr/local/cuda. Note that when copying over, make sure to set the destination name as cuda as shown bellow);
cp -r ${cuda_folder} cuda;
cp -r libcuda.so .;
``` 
2. Building our Docker Image.
```bash
 docker-compose build ros-service-kinetic; 
```

# Host Computer 
This computer is responsible for running the drone/environment simulators + autopilot subsystem).

Please take a look at the host computer build pprovided in the [here](https://github.com/MAVBench/MAVBench/blob/master/docs/read_me/building.md).


