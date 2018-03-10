BSB_scripts
===========

Scripts for updating BSB maps in PD

This is a place to store a series of scripts ment to update BSB map files in Public domain, 
and to convert them into tiles in a TMS structure

As `tilers-tools` depends on `GDAL 1`, a bug-fix on `ubuntu-linux` (and similar systems) would be to downgrade `python-gdal` to version 1

Downgrading python-gdal
==========

On ubuntu-linux
`apt showpkg python-gdal` to get version string correctly

`sudo apt install python-gdal=<version 1 string>` downgrades the package


