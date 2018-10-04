FROM arm64v8/ros:kinetic-perception-xenial


#copying cuda over
RUN mkdir /usr/local/cuda
COPY cuda /usr/local/cuda
COPY libcuda.so /usr/lib/aarch64-linux-gnu/
COPY relocate_pcl.sh /root 

#--- update/upgrade and install relevant packages
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
RUN echo "deb-src http://packages.ros.org/ros/ubuntu xenial main" >> /etc/apt/sources.list.d/ros-latest.list
RUN apt-get update && apt-get -y upgrade &&\
    apt-get install -y wget vim sudo unzip devscripts build-essential apt-utils ssh-client autoconf


#--- install ros-kinetic-desktop-full
RUN apt-get install -y ros-kinetic-desktop-full ros-kinetic-rviz-visual-tools


#--- we might need this (see if anything was upgraded at this step)
RUN apt-get -y upgrade 
SHELL ["/bin/bash", "-c"] #chaning shell


#--------- 
#--- ros opencv
#------------
RUN cd ~ && \
	git clone -b 3.1.0-with-cuda8 https://github.com/daveselinger/opencv opencv
RUN cd ~ && sudo apt-get source ros-kinetic-opencv3
RUN cp ~/opencv/modules/cudalegacy/src/graphcuts.cpp ~/ros-kinetic-opencv3-3.3.1/modules/cudalegacy/src/graphcuts.cpp

# Dependencies
RUN cd ~/ros-kinetic-opencv3-3.3.1 && \
	apt-get build-dep -y ros-kinetic-opencv3

# Now build (we ignore missing dependencies, because we have them on our system anyways)
RUN cd ~/ros-kinetic-opencv3-3.3.1 && \
sed -i 's/\(\bdh_shlibdeps.*\)$/\1 --dpkg-shlibdeps-params=--ignore-missing-info/' debian/rules && \
dpkg-buildpackage -b -uc

RUN mkdir /usr/src/deb && \
	cp ~/ros-kinetic-opencv3_3.3.1-5xenial_arm64.deb /usr/src/deb/
# 
RUN cd /usr/src/deb/ && \
	chmod a+wr /usr/src/deb && \
	apt-ftparchive packages . | gzip -c9 > Packages.gz && \
	apt-ftparchive sources . | gzip -c9 > Sources.gz && \
	chmod a+wr /etc/apt/sources.list.d/ros-latest.list && \
	echo "deb file:/usr/src/deb ./" >> /etc/apt/sources.list.d/ros-latest.list && \
	sed -i -e "1,2s/^/#/g" /etc/apt/sources.list.d/ros-latest.list && \
	apt-get update && \
	apt-get remove -y ros-kinetic-opencv3 && \
	apt-get install -y ros-kinetic-opencv3 --allow-unauthenticated && \
	sed -i -e "s/#//g" /etc/apt/sources.list.d/ros-latest.list && \
	apt-get update && \
	apt-get install -y ros-kinetic-desktop-full ros-kinetic-rviz-visual-tools


#--- point cloud library
RUN cd ~/ && git clone https://github.com/PointCloudLibrary/pcl.git && cd pcl &&\
    git checkout pcl-1.7.2rc2.1
COPY lzf_image_io.cpp /root/pcl/io/src/ 
RUN cd ~/pcl && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-std=c++11" ..
RUN cd ~/pcl/build && make -j 1
RUN cd ~/pcl/build && make -j 1 install

RUN cd ~/ && chmod +x relocate_pcl.sh && ./relocate_pcl.sh
#
##--- airsim
RUN cd ~/ && git clone https://github.com/hngenc/AirSim.git && \
    cd ~/AirSim && \ 
    git fetch origin && \
    git checkout -b future_darwing_dev origin/future_darwing_dev && \
    ./setup.sh
RUN apt-get install -y rsync
RUN cd ~/AirSim && ./build.sh


#--- darknet
RUN cd ~ && git clone https://github.com/pjreddie/darknet.git && cd darknet &&\
	git checkout d528cbdb7bf58c094026377aa80c26971d0ae1b0
COPY darknet.patch /root/darknet/	
RUN cd ~/darknet && git apply --whitespace=fix darknet.patch
RUN  cd ~/darknet &&  export PATH="$PATH:/usr/local/cuda/bin" && \
	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64" &&\
	cp /opt/ros/kinetic/lib/aarch64-linux-gnu/pkgconfig/opencv-3.3.1-dev.pc /opt/ros/kinetic/lib/aarch64-linux-gnu/pkgconfig/opencv.pc &&\
	sed -i 's/GPU=0/GPU=1/' Makefile && \
	sed -i 's/OPENCV=0/OPENCV=1/' Makefile &&\
    sed -i 's/\(LDFLAGS+= -L\/usr\/local\/cuda\/lib64\)/\1 -L\/usr\/local\/cuda\/lib64\/stubs /' Makefile &&\
    bash -c "source /opt/ros/kinetic/setup.bash ; make -j3"
RUN cd ~/darknet && wget https://pjreddie.com/media/files/yolov2.weights


## --- mavbench
RUN mkdir -p ~/catkin_ws/src
RUN cd ~/catkin_ws/
RUN source /opt/ros/kinetic/setup.bash && cd ~/catkin_ws &&  \  
    git clone --recursive  https://github.com/hngenc/mav-bench.git  &&  \
    cd mav-bench && \
    git checkout -b refactor origin/refactor &&\
    ./prereqs.sh 

#--- posibly fold this into prereqs.sh
RUN    cd /root/catkin_ws/src/glog_catkin && \
       git checkout de911f71cb832dcc0668bca56727b4b7b1e42126 && \
       git apply ../mav-bench/misc/glog_catkin.patch 

RUN cd /root/catkin_ws/src/mav_trajectory_generation && \
       git checkout ee318fc2478a04c85a95e96dedb4a7be6731720c

RUN cd /root/catkin_ws/src/mav_comm && \
        git checkout 521b2b21ffb6c86e724a9b6144b0171a371c9ee4 

RUN cd ~/catkin_ws/ && \ 
    source /opt/ros/kinetic/setup.bash && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="catkin_simple" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="eigen_catkin" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="eigen_checks" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="glog_catkin" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mav_msgs" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mav_comm" && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="nlopt" && \
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
    catkin_make -DCATKIN_WHITELIST_PACKAGES="multiagent_collision_check" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mavbench_msgs" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="octomap_server" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="future_collision" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="publish_imu" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="follow_trajectory" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="octomap_mapping" -j3 &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="depth_image_proc" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="package_delivery" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="airsim_img_publisher" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="kdtree" -j3 && \                         
    catkin_make -DCATKIN_WHITELIST_PACKAGES="nbvplanner" -j3 &&\
    catkin_make -DCATKIN_WHITELIST_PACKAGES="mapping_and_sar" -j3 && \
    catkin_make -DCATKIN_WHITELIST_PACKAGES="follow_the_leader" -j3
   

#--- probably need to delete the following
##RUN	cp ~/ros-kinetic-opencv3_3.3.1-5xenial_arm64.deb /usr/src/deb/ &&\
##    dpkg -i ~/ros-kinetic-opencv3_3.3.1-5xenial_arm64.deb 
##
