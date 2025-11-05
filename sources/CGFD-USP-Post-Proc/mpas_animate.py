
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script to create animations of scalar fields (and optionally vectors) on native MPAS grids

Based on: mpas_plot.py
Created: Oct 2025 by  Danilo Couto de Souza
Last edited: Oct 2022

Usage examples:
  # Animate surface variable
  python mpas_animate.py -f "history.*.nc" -v surface_pressure -o animation.mp4
  
  # Animate 3D variable at level 10
  python mpas_animate.py -f "history.*.nc" -v theta -l 10 -o temp_animation.mp4
  
  # Animate with wind vectors (u,v)
  python mpas_animate.py -f "history.*.nc" -v theta -l 10 -u uReconstructZonal -v_wind uReconstructMeridional -o wind_animation.mp4
  
  # Specify time range
  python mpas_animate.py -f "history.*.nc" -v surface_pressure --tmin 0 --tmax 10 -o animation.gif

"""

import math
import os
import glob
import argparse
from multiprocessing import Pool, cpu_count

import xarray as xr
import numpy as np

import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import cartopy.crs as ccrs

from tqdm import tqdm

# Derived variables mapping (from mpas_plot.py)
derived_variables = {
    'latCell': ['latitude'],
    'lonCell': ['longitude'],
    'latVertex': ['latitudeVertex'],
    'lonVertex': ['longitudeVertex'],
    'areaCell': ['area', 'resolution'],
}


def add_mpas_mesh_variables(ds, full=True, **kwargs):
    """Add derived variables to MPAS dataset (from mpas_plot.py)"""
    for v in ds.data_vars:
        if v not in derived_variables:
            continue

        newvs = derived_variables[v]

        for newv in newvs:
            if newv in ds:
                continue

            if 'lat' in v or 'lon' in v:
                ds[newv] = xr.apply_ufunc(np.rad2deg, ds[v])
                ds[newv] = ds[newv].where(ds[newv] <= 180.0, ds[newv] - 360.0)
                ds[newv].attrs['units'] = 'degrees'

            elif newv == 'area':
                radius_circle = ds.attrs.get('sphere_radius', 1.0)
                if radius_circle == 1:
                    correction_rad_earth = 6371220.0
                else:
                    correction_rad_earth = 1

                ds[newv] = (ds[v] / 10 ** 6) * correction_rad_earth**2
                ds[newv].attrs['units'] = 'km^2 (assuming areaCell in m^2)'
                ds[newv].attrs['long_name'] = 'Area of the cell in km^2'

            elif newv == 'resolution':
                radius_circle = ds.attrs.get('sphere_radius', 1.0)
                if radius_circle == 1.0:
                    correction_rad_earth = 6371220.0
                else:
                    correction_rad_earth = 1

                area = (ds[v] / 10 ** 6) * correction_rad_earth**2
                ds[newv] = 2 * (xr.apply_ufunc(np.sqrt, area / math.pi))
                ds[newv].attrs['units'] = 'km'
                ds[newv].attrs['long_name'] = 'Resolution of the cell (approx)'

    return ds


def open_mpas_file(file, **kwargs):
    """Open MPAS file and add derived variables"""
    ds = xr.open_dataset(file)
    ds = add_mpas_mesh_variables(ds, **kwargs)
    return ds


def add_cartopy_details(ax, zorder=1):
    """Add coastlines and gridlines to map"""
    ax.coastlines(resolution='10m', zorder=zorder+1, linewidth=0.1)
    gl = ax.gridlines(draw_labels=True, alpha=0.5, linestyle='--',
                      zorder=zorder+2, linewidth=0.5)
    gl.top_labels = False
    gl.right_labels = False


def get_vim_vmax(da, clip=False):
    """Returns good vmin and vmax values to plot da field"""
    truemaxval = da.max().values
    trueminval = da.min().values

    if (trueminval <= 0) and (truemaxval > 0):
        if truemaxval > abs(trueminval):
            slice = da.values[da.values > 0]
        else:
            slice = -da.values[da.values <= 0]
        sigma = np.std(slice)
        m = np.mean(slice)
        if clip:
            maxval = min(truemaxval, m+4*sigma)
        else:
            maxval = truemaxval
        minval = -maxval
    elif (truemaxval >= 0):
        minval = trueminval
        sigma = np.std(da.values)
        m = np.mean(da.values)
        if clip:
            maxval = min(truemaxval, m+4*sigma)
        else:
            maxval = truemaxval
    else:
        maxval = truemaxval
        sigma = np.std(da.values)
        m = np.mean(da.values)
        if clip:
            minval = max(trueminval, m-4*sigma)
        else:
            minval = trueminval

    return minval, maxval


def set_plot_kwargs(da=None, clip=False, list_darrays=None, **kwargs):
    """Set plot kwargs including colorbar limits"""
    plot_kwargs = {k: v for k, v in kwargs.items()
                   if k in ['cmap', 'vmin', 'vmax']
                   and v is not None}

    if 'cmap' not in plot_kwargs:
        plot_kwargs['cmap'] = 'Spectral'

    vmin = plot_kwargs.get('vmin', None)
    if vmin is None:
        if da is not None:
            vmin, _ = get_vim_vmax(da, clip)
        elif list_darrays is not None:
            vmin = np.min([v.min() for v in list_darrays if v is not None])

    if vmin is not None:
        plot_kwargs['vmin'] = vmin

    vmax = plot_kwargs.get('vmax', None)
    if vmax is None:
        if da is not None:
            _, vmax = get_vim_vmax(da, clip)
        elif list_darrays is not None:
            vmax = np.max([v.max() for v in list_darrays if v is not None])

    if vmax is not None:
        plot_kwargs['vmax'] = vmax

    return plot_kwargs


def colorvalue(val, da, vmin=None, vmax=None, cmap='Spectral'):
    """Get color for a value based on colormap and range"""
    cm = mpl.colormaps[cmap]
    if vmin is None:
        vmin = da.min().values
    if vmax is None:
        vmax = da.max().values

    if vmin == vmax:
        norm_val = mpl.colors.Normalize(vmin=vmin - 1, vmax=vmax + 1, clip=True)(val)
    else:
        norm_val = mpl.colors.Normalize(vmin=vmin, vmax=vmax, clip=True)(val)

    return cm(norm_val)


def add_colorbar(axs, fig=None, label=None, extend='both', **plot_kwargs):
    """Add colorbar to figure with extend option"""
    if fig is None:
        fig = plt.gcf()

    try:
        x = axs[0, 0]
    except:
        try:
            x = axs[0]
            n = len(axs)
        except:
            axs = np.array([axs]).reshape([1, 1])
        else:
            axs = axs.reshape([n, 1])

    cbar = fig.colorbar(
        mpl.cm.ScalarMappable(
            norm=mpl.colors.Normalize(vmin=plot_kwargs['vmin'],
                                      vmax=plot_kwargs['vmax'], clip=True),
            cmap=plot_kwargs['cmap']),
        ax=axs[:, :], shrink=0.6, extend=extend)
    cbar.ax.locator_params(nbins=10)
    if label is not None:
        cbar.set_label(label)

    return


def _process_cell(args):
    """Helper function to process a single cell (for parallel execution)"""
    cell, da_values, ds_grid_dict, plot_kwargs, plotEdge = args
    
    value = da_values[cell]
    vertices = ds_grid_dict['verticesOnCell'][cell]
    num_sides = ds_grid_dict['nEdgesOnCell'][cell]
    
    if 0 in vertices[:num_sides]:
        return None  # Border cell
    
    vertices = vertices[:num_sides] - 1
    lats = ds_grid_dict['latitudeVertex'][vertices]
    lons = ds_grid_dict['longitudeVertex'][vertices]
    
    # Get color
    vmin = plot_kwargs['vmin']
    vmax = plot_kwargs['vmax']
    cmap = plot_kwargs.get('cmap', 'Spectral')
    cm = mpl.colormaps[cmap]
    
    if vmin == vmax:
        norm_val = mpl.colors.Normalize(vmin=vmin - 1, vmax=vmax + 1, clip=True)(value)
    else:
        norm_val = mpl.colors.Normalize(vmin=vmin, vmax=vmax, clip=True)(value)
    
    color = cm(norm_val)
    
    # Check for polygons at the border of the map (+/- 180 longitude)
    if lons.max() > 170 and lons.min() < -170:
        lons = np.where(lons >= 170.0, lons - 360.0, lons)
    
    if plotEdge:
        edgecolor = 'grey'
        lw = 0.05
    else:
        edgecolor = None
        lw = None
    
    return (lons, lats, color, edgecolor, lw)


def _render_frame(args):
    """Render a single frame in parallel (more efficient than parallelizing cells)"""
    frame_idx, file, vname, level, u_var, v_var, plotEdge, gridfile, plot_kwargs, stride, \
    lat_min, lat_max, lon_min, lon_max, dpi, extend = args
    
    # Create figure for this frame
    fig = plt.figure(figsize=(12, 8))
    ax = plt.axes(projection=ccrs.PlateCarree())
    
    # Set map extent
    if (lat_min is not None and lat_max is not None and 
        lon_min is not None and lon_max is not None):
        ax.set_extent([lon_min, lon_max, lat_min, lat_max], crs=ccrs.PlateCarree())
    else:
        ax.set_extent([-180.0, 180, -90.0, 90.0], crs=ccrs.PlateCarree())
    
    add_cartopy_details(ax, zorder=2)
    
    # Load data
    ds_frame = open_mpas_file(file)
    da_frame = ds_frame[vname].isel(Time=0)
    
    if level is not None:
        da_frame = da_frame.isel(nVertLevels=level)
    
    # Plot cells
    if 'nCells' in da_frame.dims:
        plot_cells_mpas_fast(da_frame, ds_frame, ax, plotEdge, 
                           gridfile=gridfile, show_progress=False, n_jobs=1, **plot_kwargs)
    
    # Plot wind vectors if requested
    if u_var is not None and v_var is not None:
        u_frame = ds_frame[u_var].isel(Time=0)
        v_frame = ds_frame[v_var].isel(Time=0)
        
        if level is not None:
            u_frame = u_frame.isel(nVertLevels=level)
            v_frame = v_frame.isel(nVertLevels=level)
        
        add_wind_vectors(ax, ds_frame, u_frame, v_frame, stride=stride)
    
    # Set title
    filename = os.path.basename(file)
    title = f'{vname}'
    if level is not None:
        title += f' (Level {level})'
    title += f'\n{filename}'
    ax.set_title(title, fontsize=12)
    
    # Add colorbar
    units = ds_frame[vname].attrs.get('units', '')
    add_colorbar(ax, fig=fig, label=f'{vname} ({units})', extend=extend, **plot_kwargs)
    
    # Save frame to temporary file
    temp_file = f'_temp_frame_{frame_idx:04d}.png'
    fig.savefig(temp_file, dpi=dpi, bbox_inches='tight')
    plt.close(fig)
    
    return temp_file


def plot_cells_mpas_fast(da, ds, ax, plotEdge=False, gridfile=None, show_progress=True, n_jobs=1, **plot_kwargs):
    """
    Plot cells on MPAS grid (optimized for animation - no edge plotting by default)
    
    Parameters:
    -----------
    n_jobs : int, ignored (kept for compatibility, parallelization is done at frame level)
    """
    # GTM: check if grid properties needed for plotting are in ds
    grid_properties = ['verticesOnCell', 'nEdgesOnCell']

    if set(grid_properties).issubset(set(ds.keys())):
        ds_grid = ds
    else:
        try:
            ds_grid = open_mpas_file(gridfile)
            if not set(grid_properties).issubset(set(ds_grid.keys())):
                raise RuntimeError(f"Recovery of {grid_properties} failed.")
        except:
            raise RuntimeError(f"{grid_properties} not found in dataset or grid file.")

    cells = ds['nCells'].values
    
    # Always use sequential processing (parallelization is at frame level now)
    cell_iterator = tqdm(cells, desc="    Plotting cells", leave=False) if show_progress else cells
    
    for cell in cell_iterator:
        value = da.sel(nCells=cell)
        vertices = ds_grid['verticesOnCell'].sel(nCells=cell).values
        num_sides = int(ds_grid['nEdgesOnCell'].sel(nCells=cell))

        if 0 in vertices[:num_sides]:
            continue  # Border cell

        vertices = vertices[:num_sides] - 1
        lats = ds_grid['latitudeVertex'].sel(nVertices=vertices)
        lons = ds_grid['longitudeVertex'].sel(nVertices=vertices)

        color = colorvalue(value, da, vmin=plot_kwargs['vmin'], vmax=plot_kwargs['vmax'],
                          cmap=plot_kwargs.get('cmap', 'Spectral'))

        # Check for polygons at the border of the map (+/- 180 longitude)
        if max(lons) > 170 and min(lons) < -170:
            lons = xr.where(lons >= 170.0, lons - 360.0, lons)

        if plotEdge:
            edgecolor = 'grey'
            lw = 0.05
        else:
            edgecolor = None
            lw = None

        ax.fill(lons, lats, edgecolor=edgecolor, linewidth=lw, facecolor=color)


def add_wind_vectors(ax, ds, u_da, v_da, stride=10, scale=None, **kwargs):
    """
    Add wind vectors to the plot
    
    Parameters:
    -----------
    ax : matplotlib axis
    ds : xarray dataset with grid info
    u_da : xarray DataArray with u component (zonal)
    v_da : xarray DataArray with v component (meridional)
    stride : int, plot every Nth vector to avoid overcrowding
    scale : float, scaling factor for arrows
    """
    # Get cell centers
    lats = ds['latitude'].values[::stride]
    lons = ds['longitude'].values[::stride]
    
    # Get wind components
    u = u_da.values[::stride]
    v = v_da.values[::stride]
    
    # Remove NaN values
    mask = ~(np.isnan(u) | np.isnan(v))
    lats = lats[mask]
    lons = lons[mask]
    u = u[mask]
    v = v[mask]
    
    # Plot quiver
    if scale is None:
        scale = np.nanmax(np.sqrt(u**2 + v**2)) * 50
    
    ax.quiver(lons, lats, u, v, 
             transform=ccrs.PlateCarree(),
             scale=scale, 
             width=0.002,
             headwidth=3,
             headlength=4,
             color='black',
             alpha=0.7,
             zorder=10)


def load_mpas_files(file_pattern):
    """
    Load multiple MPAS files and sort by time
    
    Parameters:
    -----------
    file_pattern : str, glob pattern for files (e.g., "history.*.nc")
    
    Returns:
    --------
    list of file paths sorted by name
    """
    files = sorted(glob.glob(file_pattern))
    if len(files) == 0:
        raise FileNotFoundError(f"No files found matching pattern: {file_pattern}")
    return files


def create_animation(file_pattern, vname, 
                     outfile='animation.mp4',
                     level=None,
                     u_var=None, v_var=None,
                     plotEdge=False,
                     clip=False,
                     gridfile=None,
                     lat_min=None, lat_max=None, 
                     lon_min=None, lon_max=None,
                     tmin=None, tmax=None,
                     fps=5,
                     dpi=150,
                     stride=15,
                     n_jobs=1,
                     extend='both',
                     **kwargs):
    """
    Create animation of MPAS field from multiple files
    
    Parameters:
    -----------
    file_pattern : str, glob pattern for input files
    vname : str, variable name to plot
    outfile : str, output file (mp4, gif, etc)
    level : int, vertical level (None for surface variables)
    u_var, v_var : str, u and v wind component variable names (optional)
    plotEdge : bool, whether to plot cell edges
    clip : bool, whether to clip outliers
    gridfile : str, additional grid file if needed
    lat_min, lat_max, lon_min, lon_max : float, map extent
    tmin, tmax : int, time indices to animate
    fps : int, frames per second
    dpi : int, dots per inch for output
    stride : int, stride for wind vectors
    """
    
    # Load files
    print(f"Loading files matching: {file_pattern}")
    files = load_mpas_files(file_pattern)
    print(f"Found {len(files)} files")
    
    # Load first file to get grid info and set up plot
    ds = open_mpas_file(files[0])
    
    if vname not in ds.data_vars:
        print(f'Variable {vname} not found in dataset')
        print('Available variables:', list(ds.keys())[:20], '...')
        return
    
    # Check if variable has vertical levels
    has_levels = 'nVertLevels' in ds[vname].dims
    
    if has_levels and level is None:
        print(f"Variable {vname} has vertical levels but no level specified.")
        print(f"Using level 0 by default. Available levels: {ds['nVertLevels'].values}")
        level = 0
    
    if not has_levels and level is not None:
        print(f"Warning: Variable {vname} is a surface field. Ignoring level parameter.")
        level = None
    
    # Check wind variables
    plot_wind = (u_var is not None) and (v_var is not None)
    if plot_wind:
        if u_var not in ds.data_vars or v_var not in ds.data_vars:
            print(f"Wind variables {u_var} or {v_var} not found. Skipping wind vectors.")
            plot_wind = False
    
    # Collect all data arrays for consistent colorbar
    print("\n" + "="*60)
    print("STEP 1: Loading all time steps to determine color scale")
    print("="*60)
    all_data = []
    for file in tqdm(files, desc="Loading files"):
        ds_temp = open_mpas_file(file)
        da_temp = ds_temp[vname].isel(Time=0)
        if level is not None:
            da_temp = da_temp.isel(nVertLevels=level)
        all_data.append(da_temp)
    
    # Apply time range if specified
    if tmin is not None or tmax is not None:
        tmin = tmin if tmin is not None else 0
        tmax = tmax if tmax is not None else len(all_data)
        all_data = all_data[tmin:tmax]
        files = files[tmin:tmax]
        print(f"Applied time range: frames {tmin} to {tmax}")
    
    # Set plot kwargs with consistent color scale
    plot_kwargs = set_plot_kwargs(da=None, clip=clip, list_darrays=all_data, **kwargs)
    
    print(f"\n{'='*60}")
    print(f"STEP 2: Rendering frames")
    print(f"{'='*60}")
    print(f"  Number of frames: {len(files)}")
    print(f"  Color scale: vmin={plot_kwargs['vmin']:.3e}, vmax={plot_kwargs['vmax']:.3e}")
    print(f"  Colormap: {plot_kwargs['cmap']}")
    print(f"  FPS: {fps}")
    print(f"  DPI: {dpi}")
    if plot_wind:
        print(f"  Wind vectors: YES (stride={stride})")
    else:
        print(f"  Wind vectors: NO")
    
    if n_jobs > 1:
        # Parallel frame rendering (MUCH MORE EFFICIENT!)
        print(f"  Parallel workers: {n_jobs}")
        print(f"  Mode: Each worker renders complete frames")
        
        # Prepare arguments for parallel processing
        args_list = [
            (i, files[i], vname, level, u_var if plot_wind else None, v_var if plot_wind else None,
             plotEdge, gridfile, plot_kwargs, stride, lat_min, lat_max, lon_min, lon_max, dpi, extend)
            for i in range(len(files))
        ]
        
        # Render frames in parallel
        with Pool(processes=n_jobs) as pool:
            temp_files = list(tqdm(pool.imap(_render_frame, args_list), 
                                  total=len(files), desc="  Rendering frames"))
        
        # Create animation from temporary PNG files
        print(f"\n{'='*60}")
        print(f"STEP 3: Combining frames into animation")
        print(f"{'='*60}")
        
        # Read images and create animation
        from PIL import Image
        images = [Image.open(f) for f in temp_files]
        
        print(f"  Saving animation to: {outfile}")
        if outfile.endswith('.gif'):
            images[0].save(outfile, save_all=True, append_images=images[1:], 
                          duration=int(1000/fps), loop=0, optimize=False)
            print(f"  Format: GIF")
        else:
            # For MP4, use ffmpeg via subprocess or imageio
            try:
                import imageio
                with imageio.get_writer(outfile, fps=fps) as writer:
                    for img_file in tqdm(temp_files, desc="  Writing video"):
                        img = imageio.imread(img_file)
                        writer.append_data(img)
                print(f"  Format: MP4 (using imageio)")
            except ImportError:
                print("  Warning: imageio not found, using ffmpeg directly")
                # Fall back to using ffmpeg directly via subprocess
                import subprocess
                with open('_temp_filelist.txt', 'w') as f:
                    for i, img_file in enumerate(temp_files):
                        f.write(f"file '{img_file}'\n")
                        f.write(f"duration {1.0/fps}\n")
                subprocess.run(['ffmpeg', '-f', 'concat', '-safe', '0', '-i', '_temp_filelist.txt',
                              '-c:v', 'libx264', '-pix_fmt', 'yuv420p', outfile, '-y'],
                             check=True)
                os.remove('_temp_filelist.txt')
                print(f"  Format: MP4 (using ffmpeg)")
        
        # Clean up temporary files
        print(f"  Cleaning up {len(temp_files)} temporary files...")
        for f in temp_files:
            os.remove(f)
        
        print(f"\n{'='*60}")
        print(f"SUCCESS! Animation saved to:")
        print(f"  {os.path.abspath(outfile)}")
        print(f"{'='*60}")
            
    else:
        # Sequential animation (original matplotlib animation approach)
        print(f"  Mode: Sequential (use -j > 1 for parallel speedup)")
        
        # Set up figure and axis
        fig = plt.figure(figsize=(12, 8))
        ax = plt.axes(projection=ccrs.PlateCarree())
        
        # Set map extent
        if (lat_min is not None and lat_max is not None and 
            lon_min is not None and lon_max is not None):
            ax.set_extent([lon_min, lon_max, lat_min, lat_max], crs=ccrs.PlateCarree())
        else:
            ax.set_extent([-180.0, 180, -90.0, 90.0], crs=ccrs.PlateCarree())
        
        add_cartopy_details(ax, zorder=2)
        
        # Add colorbar
        units = ds[vname].attrs.get('units', '')
        add_colorbar(ax, fig=fig, label=f'{vname} ({units})', extend=extend, **plot_kwargs)
        
        # Animation update function
        def update_frame(frame_idx):
            print(f"\n=== Frame {frame_idx+1}/{len(files)} ===")
            filename = os.path.basename(files[frame_idx])
            print(f"  File: {filename}")
            
            ax.clear()
            print("  Clearing axis and adding map details...")
            add_cartopy_details(ax, zorder=2)
            
            # Set extent again (cleared by ax.clear())
            if (lat_min is not None and lat_max is not None and 
                lon_min is not None and lon_max is not None):
                ax.set_extent([lon_min, lon_max, lat_min, lat_max], crs=ccrs.PlateCarree())
            else:
                ax.set_extent([-180.0, 180, -90.0, 90.0], crs=ccrs.PlateCarree())
            
            # Load data for this frame
            print(f"  Loading data...")
            ds_frame = open_mpas_file(files[frame_idx])
            da_frame = ds_frame[vname].isel(Time=0)
            
            if level is not None:
                da_frame = da_frame.isel(nVertLevels=level)
            
            # Plot cells
            if 'nCells' in da_frame.dims:
                print(f"  Plotting {len(ds_frame['nCells'])} cells...")
                plot_cells_mpas_fast(da_frame, ds_frame, ax, plotEdge, 
                                   gridfile=gridfile, show_progress=True, n_jobs=1, **plot_kwargs)
            else:
                print(f"  Warning: Cannot plot variable with dimensions {da_frame.dims}")
                return
            
            # Plot wind vectors if requested
            if plot_wind:
                print(f"  Adding wind vectors...")
                u_frame = ds_frame[u_var].isel(Time=0)
                v_frame = ds_frame[v_var].isel(Time=0)
                
                if level is not None:
                    u_frame = u_frame.isel(nVertLevels=level)
                    v_frame = v_frame.isel(nVertLevels=level)
                
                add_wind_vectors(ax, ds_frame, u_frame, v_frame, stride=stride)
            
            # Set title
            title = f'{vname}'
            if level is not None:
                title += f' (Level {level})'
            title += f'\n{filename}'
            ax.set_title(title, fontsize=12)
            
            print(f"  Frame {frame_idx+1}/{len(files)} complete!")
        
        # Create animation
        print(f"\n{'='*60}")
        print(f"STEP 3: Generating animation frames")
        print(f"{'='*60}")
        anim = animation.FuncAnimation(fig, update_frame, frames=len(files), 
                                      interval=1000/fps, repeat=True)
        
        # Save animation
        print(f"\n{'='*60}")
        print(f"STEP 4: Saving animation")
        print(f"{'='*60}")
        print(f"  Output file: {outfile}")
        
        if outfile.endswith('.gif'):
            writer = animation.PillowWriter(fps=fps)
            print(f"  Format: GIF (using PillowWriter)")
        else:
            writer = animation.FFMpegWriter(fps=fps, bitrate=1800)
            print(f"  Format: MP4 (using FFMpegWriter)")
        
        print(f"  Saving... (this may take a while)")
        anim.save(outfile, writer=writer, dpi=dpi)
        plt.close()
        
        print(f"\n{'='*60}")
        print(f"SUCCESS! Animation saved to:")
        print(f"  {os.path.abspath(outfile)}")
        print(f"{'='*60}")


if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawTextHelpFormatter)
    
    parser.add_argument(
        "-f", "--files", type=str, required=True,
        help="File pattern for MPAS data files (e.g., 'history.*.nc')",
    )
    
    parser.add_argument(
        "-o", "--outfile", type=str, default='mpas_animation.mp4',
        help="Output animation file (mp4, gif, etc)",
    )
    
    parser.add_argument(
        "-v", "--var", type=str, required=True,
        help="Variable to animate",
    )
    
    parser.add_argument(
        "-l", "--level", type=int, default=None,
        help="Vertical level (for 3D variables only)",
    )
    
    parser.add_argument(
        "-u", "--u_wind", type=str, default=None,
        help="U (zonal) wind component variable name (optional)",
    )
    
    parser.add_argument(
        "-v_wind", "--v_wind", type=str, default=None,
        help="V (meridional) wind component variable name (optional)",
    )
    
    parser.add_argument(
        "-g", "--grid", type=str, default='no',
        help="Draw grid edges: yes or no (default: no for better performance)",
    )
    
    parser.add_argument(
        "-c", "--clip", type=str, default='no',
        help="Clip values greater than (expected_val + 4*std): yes or no",
    )
    
    parser.add_argument(
        "-gf", "--gridfile", type=str, default=None,
        help="Additional file containing grid properties",
    )
    
    # Map extent
    parser.add_argument("-lat_min", type=float, default=None, 
                       help="Minimum latitude for zoom")
    parser.add_argument("-lat_max", type=float, default=None, 
                       help="Maximum latitude for zoom")
    parser.add_argument("-lon_min", type=float, default=None, 
                       help="Minimum longitude for zoom")
    parser.add_argument("-lon_max", type=float, default=None, 
                       help="Maximum longitude for zoom")
    
    # Time range
    parser.add_argument("--tmin", type=int, default=None,
                       help="Starting time index (default: 0)")
    parser.add_argument("--tmax", type=int, default=None,
                       help="Ending time index (default: all)")
    
    # Animation parameters
    parser.add_argument("--fps", type=int, default=5,
                       help="Frames per second (default: 5)")
    parser.add_argument("--dpi", type=int, default=150,
                       help="DPI for output (default: 150)")
    parser.add_argument("--stride", type=int, default=15,
                       help="Stride for wind vectors (plot every Nth vector, default: 15)")
    
    # Parallelization
    parser.add_argument("-j", "--jobs", type=int, default=1,
                       help="Number of parallel workers for cell plotting (default: 1, use -1 for all CPUs)")
    
    # Color scale
    parser.add_argument("--vmin", type=float, default=None,
                       help="Minimum value for color scale (e.g., 90000 for pressure)")
    parser.add_argument("--vmax", type=float, default=None,
                       help="Maximum value for color scale (e.g., 103500 for pressure)")
    parser.add_argument("--cmap", type=str, default='Spectral',
                       help="Colormap name (default: Spectral). Examples: viridis, plasma, coolwarm, RdBu_r")
    parser.add_argument("--extend", type=str, default='both',
                       help="Colorbar extend option: 'both', 'neither', 'min', 'max' (default: both)")
    
    args = parser.parse_args()
    
    # Parse grid option
    plotEdge = args.grid.lower() in ['yes', 'y']
    
    # Parse clip option
    clip = args.clip.lower() in ['yes', 'y']
    
    # Determine number of jobs
    n_jobs = args.jobs
    if n_jobs == -1:
        n_jobs = cpu_count()
        print(f"Using all available CPUs: {n_jobs}")
    elif n_jobs > 1:
        print(f"Using {n_jobs} parallel workers")
    
    # Create animation
    create_animation(
        file_pattern=args.files,
        vname=args.var,
        outfile=args.outfile,
        level=args.level,
        u_var=args.u_wind,
        v_var=args.v_wind,
        plotEdge=plotEdge,
        clip=clip,
        gridfile=args.gridfile,
        lat_min=args.lat_min,
        lat_max=args.lat_max,
        lon_min=args.lon_min,
        lon_max=args.lon_max,
        tmin=args.tmin,
        tmax=args.tmax,
        fps=args.fps,
        dpi=args.dpi,
        stride=args.stride,
        n_jobs=n_jobs,
        vmin=args.vmin,
        vmax=args.vmax,
        cmap=args.cmap,
        extend=args.extend,
    )
