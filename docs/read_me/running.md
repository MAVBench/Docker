This document describes the steps necessary for running the MAVBench toolset. 
# Companion Computer  

## Running It
1. Get the command to run the docker.
```bash
  cd mavbech_docker_repo;
  xhost + ;#making sure your xservr is accepting connections from other hosts
  ./tx2-docker run ${docker image name); #(e.g. zaddan/mavbench/$tag) (note that tx2-docker is highly inspired by https://github.com/Technica-Corporation/Tegra-Docker)
  ```
  2. Copy paste the commands echod by the above tx2-docker and you should see shell promp: 
  root@tegra-ubuntu. once in the container, you can launch our applications.

 3. Sourcing the Catkin Workspace and relevant environment variables
```bash
source ~/tx2/build_scripts/companion_setup_env_var.sh;
source ~/tx2/catkin_ws/devel/setup.bash; 
```
4. Running the Benchmarks
```bash
roslaunch $pkg_name $launch_file #example: roslaunch package_delivery package_delivery.launch;
```

**Example of all our packages and applications**   
    roslaunch package_delivery package_delivery.launch         
    roslaunch package_delivery scanning.launch    
    roslaunch mapping_and_sar mapping.launch    
    roslaunch mapping_and_sar sar.launch    
    roslaunch follow_the_leader follow_the_leader.launch     

# Host Computer
Please refer to the host computer instruction provided here.

