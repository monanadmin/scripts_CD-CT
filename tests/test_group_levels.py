# Tests generated automatically by Tabnine.
# TODO - fix tests

import unittest
import shutil
import os
import tempfile
import numpy as np
import netCDF4 as nc
from group_levels import main


class TestMainFunction(unittest.TestCase):

    def setUp(self):
        self.data_dir = './pytmp/'
        shutil.rmtree(self.data_dir,ignore_errors=True)
        os.mkdir(self.data_dir)
        
        self.num_levels_out = 3
        self.filename_in = 'input.nc'
        self.filename_out = 'output.nc'
        self.nc_file_in = nc.Dataset(self.data_dir+self.filename_in, 'w')

        # Create a sample input file with dimensions and variables
        num_times_in = 3
        num_lats_in = 2
        num_lons_in = 2
        num_levels_in = 1
        
        self.nc_file_in.createDimension('time', num_times_in)
        self.nc_file_in.createDimension('level', num_levels_in)
        self.nc_file_in.createDimension('latitude', num_lats_in)
        self.nc_file_in.createDimension('longitude', num_lons_in)

        self.nc_file_in.createVariable('time', np.float32, ('time',))
        self.nc_file_in.createVariable('level', np.float32, ('level',))
        self.nc_file_in.createVariable('latitude', np.float32, ('latitude',))
        self.nc_file_in.createVariable('longitude', np.float32, ('longitude',))
        self.nc_file_in.createVariable('temp_15hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('temp_20hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('temp_30hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('t2m', np.float32, ('time', 'level', 'latitude', 'longitude'))
        

        # Write some sample data
        self.nc_file_in['time'][...] = np.arange(num_times_in)
        self.nc_file_in['latitude'][...] = np.arange(num_lats_in)
        self.nc_file_in['longitude'][...] = np.arange(num_lons_in)
        self.nc_file_in['level'][...] = np.arange(num_levels_in)
        self.nc_file_in['temp_15hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['temp_20hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['temp_30hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['t2m'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)

    def tearDown(self):
        self.nc_file_in.close()
        shutil.rmtree(self.data_dir,ignore_errors=True)

    def test_variables(self):
        levels_in = [30, 20, 15]
        main(self.data_dir, self.filename_in, self.filename_out, levels=levels_in)
        nc_file_out = nc.Dataset(self.data_dir+self.filename_out, 'r')
        
        self.assertEqual(nc_file_out.dimensions['time'].size, 3)
        self.assertEqual(nc_file_out.dimensions['latitude'].size, 2)
        self.assertEqual(nc_file_out.dimensions['longitude'].size, 2)
        self.assertEqual(nc_file_out.dimensions['level'].size, 3)
        
        self.assertTrue(all(nc_file_out['time'][...] == self.nc_file_in['time'][...]))
        self.assertTrue(all(nc_file_out['latitude'][...] == self.nc_file_in['latitude'][...]))
        self.assertTrue(all(nc_file_out['longitude'][...] == self.nc_file_in['longitude'][...]))
        self.assertTrue(np.all(nc_file_out['level'][...].data == levels_in))

        self.assertTrue(np.all(nc_file_out['t2m'][:] == self.nc_file_in['t2m'][:]))
        self.assertTrue(nc_file_out['temp'].shape == (3, 3, 2, 2))
        self.assertTrue(np.all(nc_file_out['temp'][:,0,:,:].data == self.nc_file_in['temp_15hPa'][:,0,:,:].data))
        self.assertTrue(np.all(nc_file_out['temp'][:,1,:,:].data == self.nc_file_in['temp_20hPa'][:,0,:,:].data))
        self.assertTrue(np.all(nc_file_out['temp'][:,2,:,:].data == self.nc_file_in['temp_30hPa'][:,0,:,:].data))
        nc_file_out.close()
    

def main_tests():
    test_suite = unittest.TestSuite()
    test_suite.addTest(unittest.makeSuite(TestMainFunction))
    test_runner = unittest.TextTestRunner()
    result = test_runner.run(test_suite)
    return result

if __name__ == '__main__':
    main_tests()