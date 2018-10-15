FROM arm64v8/ros:kinetic-perception-xenial


#copying cuda over
RUN mkdir /usr/local/cuda
COPY cuda /usr/local/cuda
COPY libcuda.so /usr/lib/aarch64-linux-gnu/

# update/upgrade and install relevant packages
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
RUN echo "deb-src http://packages.ros.org/ros/ubuntu xenial main" >> /etc/apt/sources.list.d/ros-latest.list
RUN apt-get update && apt-get -y upgrade &&\
    apt-get install -y wget vim sudo unzip devscripts build-essential apt-utils ssh-client autoconf

# install ros-kinetic-desktop-full
RUN apt-get install -y ros-kinetic-desktop-full ros-kinetic-rviz-visual-tools ros-kinetic-ompl

#--- we might need this (see if anything was upgraded at this step)
RUN apt-get -y upgrade 
SHELL ["/bin/bash", "-c"] #chaning shell

RUN cd ~ && git clone --recursive https://github.com/MAVBench/tx2.git

############
# ROS OpenCV (installation)
############
RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
           cd $base_dir/src &&\
           apt-get source ros-kinetic-opencv3 &&\
           cp $base_dir/src/opencv/modules/cudalegacy/src/graphcuts.cpp $base_dir/src/ros-kinetic-opencv3-3.3.1/modules/cudalegacy/src/graphcuts.cpp &&\
           cd $base_dir/src/ros-kinetic-opencv3-3.3.1 && \
           apt-get build-dep -y ros-kinetic-opencv3 &&\
           sed -i 's/\(\bdh_shlibdeps.*\)$/\1 --dpkg-shlibdeps-params=--ignore-missing-info/' debian/rules &&\
           dpkg-buildpackage -b -uc 
#
RUN  source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
     mkdir /usr/src/deb_mavbench &&\
     cp $base_dir/src/ros-kinetic-opencv3_3.3.1-5xenial_arm64.deb /usr/src/deb_mavbench/ &&\
     cd /usr/src/deb_mavbench/ &&\
     chmod a+wr /usr/src/deb_mavbench &&\
     apt-ftparchive packages . | gzip -c9 > Packages.gz &&\
     apt-ftparchive sources . | gzip -c9 > Sources.gz &&\
     chmod a+wr /etc/apt/sources.list.d/ros-latest.list &&\
     echo "deb file:/usr/src/deb_mavbench ./" >> /etc/apt/sources.list.d/ros-latest.list &&\
     sed -i -e "1,2s/^/#/g" /etc/apt/sources.list.d/ros-latest.list &&\
     apt-get update &&\
     apt-get remove -y ros-kinetic-opencv3 &&\
     apt-get install -y ros-kinetic-opencv3 --allow-unauthenticated &&\
     sed -i -e "s/#//g" /etc/apt/sources.list.d/ros-latest.list &&\
     apt-get update &&\
     apt-get install -y ros-kinetic-desktop-full ros-kinetic-rviz-visual-tools ros-kinetic-octomap* ros-kinetic-ompl &&\
     cp /opt/ros/kinetic/lib/aarch64-linux-gnu/pkgconfig/opencv-3.3.1-dev.pc /opt/ros/kinetic/lib/aarch64-linux-gnu/pkgconfig/opencv.pc 


#--- point cloud library
#RUN cd /usr/lib/aarch64-linux-gnu/ &&\
#    ln -sf tegra/libGL.so libGL.so
    
RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    cd $base_dir/src/pcl &&\
    cp $base_dir/build-scripts/lzf_image_io.cpp $base_dir/src/pcl/io/src/ 

RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    cd $base_dir/src/pcl && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-std=c++11" .. &&\
    cd $base_dir/src/pcl/build && make -j 4 &&\
    cd $base_dir/src/pcl/build && make -j 4 install
RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    cd $base_dir/build-scripts && chmod +x relocate_pcl.sh && ./relocate_pcl.sh


########
# AirSim 
########
RUN sudo apt-get install -y rsync
RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    cd $AirSim_base_dir &&\
    ./setup.sh && \
    ./build.sh


#COPY cuda /usr/local/cuda
#COPY libcuda.so /usr/lib/aarch64-linux-gnu/



########
# darknet 
########
RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    source /opt/ros/kinetic/setup.bash &&\
    cp $base_dir/build-scripts/darknet.patch $darknet_base_dir	 &&\
    cd $darknet_base_dir &&\ 
    git apply --whitespace=fix darknet.patch &&\
    sed -i 's/GPU=0/GPU=1/' Makefile &&\
    sed -i 's/OPENCV=0/OPENCV=1/' Makefile &&\
    sed -i 's/\(LDFLAGS+= -L\/usr\/local\/cuda\/lib64\)/\1 -L\/usr\/local\/cuda\/lib64\/stubs /' Makefile &&\
    cd $darknet_base_dir &&\
    export PATH="$PATH:/usr/local/cuda/bin" && \
	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64" &&\
    make -j3 &&\
    cd $darknet_base_dir && wget -nc https://pjreddie.com/media/files/yolov2.weights


########
# mavbench
########
RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    source /opt/ros/kinetic/setup.bash &&\
    mkdir -p $base_dir/catkin_ws/src &&\
    cd $base_dir/catkin_ws/ &&\
    catkin_make

RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    source /opt/ros/kinetic/setup.bash &&\
    cd $mavbench_apps_base_dir/deps/glog_catkin &&\
    git apply $base_dir/build-scripts/glog_catkin.patch 

RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    cd $base_dir/catkin_ws/src &&\
    ln -sf $mavbench_apps_base_dir mav-bench 

# mavbench-build
RUN source ~/tx2/build-scripts/companion_setup_env_var.sh &&\
    source /opt/ros/kinetic/setup.bash &&\
    source $base_dir/catkin_ws/devel/setup.bash &&\
    cd $base_dir/catkin_ws/ &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="catkin_simple" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="eigen_catkin" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="glog_catkin" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="eigen_checks" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mav_msgs" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mav_comm" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="nlopt" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mav_visualization" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="planning_msgs" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mav_trajectory_generation" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mav_trajectory_generation_ros" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="gflags_catkin" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="minkindr" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="minkindr_conversions" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mavbench_msgs" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="volumetric_map_base" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="volumetric_msgs" &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="profile_manager" -j3 &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="octomap_world" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="multiagent_collision_check" -j3 &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mavbench_msgs" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="octomap_server" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="future_collision" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="publish_imu" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="follow_trajectory" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="octomap_mapping" -j3 &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="depth_image_proc" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="package_delivery" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="airsim_img_publisher" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="kdtree" -j3 &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="nbvplanner" -j3 &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mapping_and_sar" -j3 && \

    catkin_make -DCATKIN_WHITELIST_PACKAGES="follow_the_leader" -j3


