#!/bin/bash 

nedit \
./0.run_all.bash \
./1.install_monan.bash \
./2.pre_processing.bash \
./make_*.bash \
./3.run_model.bash \
./4.run_post.bash \
./setenv.bash \
./link_grib.csh \
./run_past2now.bash \
./stools/*.bash* \
./kit.bash &
