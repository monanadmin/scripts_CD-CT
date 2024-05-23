import unittest
import shutil
import os
import numpy as np
import netCDF4 as nc
import sys

# Get the parent directory of the current directory
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
# Append the parent directory to the sys.path list
# It turns running eas, without need to configure PYTHONPATH or VSCODE launch.json
sys.path.append(os.path.join(parent_dir, 'scripts'))

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
        self.nc_file_in.createVariable('temp_1000hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('rucuten_15hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('rucuten_20hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('rucuten_1000hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('height_15hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('height_20hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('height_1000hPa', np.float32, ('time', 'level', 'latitude', 'longitude'))
        self.nc_file_in.createVariable('t2m', np.float32, ('time', 'level', 'latitude', 'longitude'))
        

        # Write some sample data
        self.nc_file_in['time'][...] = np.arange(num_times_in)
        self.nc_file_in['latitude'][...] = np.arange(num_lats_in)
        self.nc_file_in['longitude'][...] = np.arange(num_lons_in)
        self.nc_file_in['level'][...] = np.arange(num_levels_in)
        self.nc_file_in['temp_15hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['temp_20hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['temp_1000hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['rucuten_15hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['rucuten_20hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['rucuten_1000hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['height_15hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['height_20hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['height_1000hPa'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        self.nc_file_in['t2m'][...] = np.random.rand(num_times_in, num_levels_in, num_lats_in, num_lons_in)
        
        self.nc_file_in['temp_15hPa'].setncattr('long_name', 'Temperature vertically interpolated to 15 hPa')
        self.nc_file_in['temp_20hPa'].setncattr('long_name', 'Temperature vertically interpolated to 20 hPa')
        self.nc_file_in['temp_1000hPa'].setncattr('long_name', 'Temperature vertically interpolated to 1000 hPa')
        self.nc_file_in['rucuten_15hPa'].setncattr('long_name', 'Tendency of zonal wind due to cumulus convection 15 hPa')
        self.nc_file_in['rucuten_20hPa'].setncattr('long_name', 'Tendency of zonal wind due to cumulus convection 20 hPa')
        self.nc_file_in['rucuten_1000hPa'].setncattr('long_name', 'Tendency of zonal wind due to cumulus convection 1000 hPa')
        self.nc_file_in['height_15hPa'].setncattr('long_name', 'Geometric height interpolated to 15 hPa')
        self.nc_file_in['height_20hPa'].setncattr('long_name', 'Geometric height interpolated to 20 hPa')
        self.nc_file_in['height_1000hPa'].setncattr('long_name', 'Geometric height interpolated to 1000 hPa')
        self.nc_file_in['t2m'].setncattr('long_name', '2-meter temperature')
        
        self.nc_file_in.sync()

    def tearDown(self):
        self.nc_file_in.close()
        shutil.rmtree(self.data_dir,ignore_errors=True)

    def test_variables(self):
        print("Running tests for joining levels of variables")
        levels_in = [1000, 20, 15]
        main(self.data_dir, self.filename_in, self.filename_out, levels=levels_in)
        nc_file_out = nc.Dataset(self.data_dir+self.filename_out, 'r')
        
        # checking new dimensions are equals, except level
        self.assertEqual(nc_file_out.dimensions['time'].size, 3)
        self.assertEqual(nc_file_out.dimensions['latitude'].size, 2)
        self.assertEqual(nc_file_out.dimensions['longitude'].size, 2)
        self.assertEqual(nc_file_out.dimensions['level'].size, 3)
        
        # checking the dimensions has the same values, except level
        self.assertTrue(all(nc_file_out['time'][...] == self.nc_file_in['time'][...]))
        self.assertTrue(all(nc_file_out['latitude'][...] == self.nc_file_in['latitude'][...]))
        self.assertTrue(all(nc_file_out['longitude'][...] == self.nc_file_in['longitude'][...]))
        self.assertTrue(np.all(nc_file_out['level'][...].data == levels_in))

        # checking 2d variables are the same
        self.assertTrue(np.all(nc_file_out['t2m'][:] == self.nc_file_in['t2m'][:]))
        
        # checking new dimensions for 3d variables
        self.assertTrue(nc_file_out['temp'].shape == (3, 3, 2, 2))
        
        # checking data for the new dimension 'level'
        self.assertTrue(np.all(nc_file_out['temp'][:,0,:,:].data == self.nc_file_in['temp_1000hPa'][:,0,:,:].data))
        self.assertTrue(np.all(nc_file_out['temp'][:,1,:,:].data == self.nc_file_in['temp_20hPa'][:,0,:,:].data))
        self.assertTrue(np.all(nc_file_out['temp'][:,2,:,:].data == self.nc_file_in['temp_15hPa'][:,0,:,:].data))
        
        # checking the long_name removes the string 'vertically interpolated to xx hPa'
        self.assertEqual(nc_file_out['temp'].getncattr('long_name'), 'Temperature interpolated')
        self.assertEqual(nc_file_out['rucuten'].getncattr('long_name'), 'Tendency of zonal wind due to cumulus convection interpolated')
        self.assertEqual(nc_file_out['height'].getncattr('long_name'), 'Geometric height interpolated')
        self.assertEqual(nc_file_out['t2m'].getncattr('long_name'), '2-meter temperature')

        nc_file_out.close()
    

def main_tests():
    test_suite = unittest.TestSuite()
    test_suite.addTest(unittest.makeSuite(TestMainFunction))
    test_runner = unittest.TextTestRunner()
    result = test_runner.run(test_suite)
    return result

if __name__ == '__main__':
    main_tests()