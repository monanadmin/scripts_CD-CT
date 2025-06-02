#!/bin/bash 

nedit \
./0.run_all.bash \
./1.install_monan.bash \
./2.pre_processing.bash \
./make_static.bash \
./make_degrib.bash \
./make_initatmos.bash \
./3.run_model.bash \
./4.run_post.bash \
./make_template.bash \
./setenv.bash \
./link_grib.csh \
./run_past2now.bash \
./kit.bash &
