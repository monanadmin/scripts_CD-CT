
import netCDF4 as nc
import numpy as np
import re
import sys


def main(data_dir, file_in, file_out, levels=[1000, 975, 950, 925, 900, 875, 850, 825, 700, 600, 500, 400, \
    300, 250, 200, 150, 100, 70, 50, 30, 20, 15]):
    """
    This function takes in the data directory, input file name, and output file name.
    It reads the input NetCDF file, groups variables based on their names,
    creates a new NetCDF file with dimensions and variables copied from the input file,
    and saves the concatenated variables to the new NetCDF file.

    Parameters:
    data_dir (str): The directory where the input and output NetCDF files are located.
    file_in (str): The name of the input NetCDF file.
    file_out (str): The name of the output NetCDF file.

    Returns:
    None
    """

    nc_file_in = nc.Dataset(f'{data_dir}/{file_in}', 'r')
    # Save the concatenated variables to a new NetCDF file
    nc_file_out = nc.Dataset(f'{data_dir}/{file_out}', 'w')

    dimensions_4D = ('time', 'level', 'latitude', 'longitude')
    # Group variables based on their names
    variable_groups = {}
    first_hpa_variable = ''
    for name, variable in reversed(list(nc_file_in.variables.items())):  # reverse to be consistent to levels
        # if 'hPa' in name or name in dimensions_4D:
        if 'hPa' in name:
            variable_type = re.split('_.\d*hPa', name)[0]  # Extract the variable type (e.g., '15hPa', '20hPa')
            first_hpa_variable = variable_type if first_hpa_variable == '' else first_hpa_variable  
        else:
            variable_type = name.lower()
        if variable_type not in variable_groups:
            variable_groups[variable_type] = [variable]
        else:
            variable_groups[variable_type].append(variable)

    level_dimension_size = len(variable_groups[first_hpa_variable]) 

    # Copy dimensions Time, latitude, longitude
    for dim_name, dim_type in nc_file_in.dimensions.items():
        if dim_name.lower() in ['time', 'latitude', 'longitude']:
            nc_file_out.createDimension(dim_name.lower(), dim_type.size)
    nc_file_out.createDimension('level', level_dimension_size)
    

    # Copy variables
    for variable_type, variables in variable_groups.items():
        print(f'Creating var {variable_type}')
        if variable_type == 'level':
            new_variable = nc_file_out.createVariable(variable_type, variables[0].dtype, (variable_type) )
            new_variable.setncatts({k: variables[0].getncattr(k) for k in variables[0].ncattrs()})
            new_variable[:] = range(level_dimension_size, 0, -1) if levels is None else levels
            new_variable.setncattr('positive', "down")
            new_variable.setncattr('units', "hPa")
        # if its variables with on isobaric level per variable
        elif len(variables) == level_dimension_size:
            new_variable = nc_file_out.createVariable(variable_type, variables[0].dtype, dimensions_4D)
            new_variable.setncatts({k: variables[0].getncattr(k) for k in variables[0].ncattrs()})
            if 'vertically interpolated' in  new_variable.getncattr('long_name'):
                new_long_name = new_variable.getncattr('long_name').split('vertically interpolated')[0].strip()
            elif 'interpolated' in  new_variable.getncattr('long_name'):
                new_long_name = new_variable.getncattr('long_name').split('interpolated')[0].strip()
            elif '1000 hPa' in  new_variable.getncattr('long_name'):
                new_long_name = new_variable.getncattr('long_name').split('1000 hPa')[0].strip()
            else:
                new_long_name = new_variable.getncattr('long_name')
            new_long_name += ' interpolated'
            new_variable.setncattr('long_name', new_long_name)
            
            for i in range(level_dimension_size):
                new_variable[:,i,:,:] = variables[i][:]
        else:
            # Create an empty list to store lowercase dimensions
            lowercase_dimensions = []
        
            # Iterate through each object in the tuple
            for obj in variables[0].dimensions:
                # Access the 'dimensions' attribute and convert to lowercase
                lowercase_dimensions.append(obj.lower())
                # Convert the list of lowercase dimensions to a tuple
    
            lowercase_dimensions_tuple = tuple(lowercase_dimensions)            
            # variable_type in ('latitude', 'longitude', 'Time'):
            new_variable = nc_file_out.createVariable(variable_type, variables[0].dtype, lowercase_dimensions_tuple)
            new_variable.setncatts({k: variables[0].getncattr(k) for k in variables[0].ncattrs()})
            new_variable[:] = variables[0][:]

    nc_file_out.close()
    nc_file_in.close()


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 4:
        print(f"Usage: python {sys.argv[0]} <workdir> <filein> <fileout>")
        sys.exit(1)

    main(sys.argv[1], sys.argv[2], sys.argv[3])
