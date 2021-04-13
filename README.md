# Meetnet Vlaamse Banken

Package to download data from the Meetnet Vlaamse Banken API (Flemish Banks Monitoring network).
The Flemish Banks monitoring network consists of many measurement locations providing hydro-meteorological time-series. Measurement locations are situated on the Belgian Continental Shelf area and the Belgian coast.

To download data, an account is required which can be freely requested at: https://meetnetvlaamsebanken.be/

Currently scripts are available for Python and Matlab

The Python package contains 4 methods:
    ping: to ping the API and test for successfull login status.
    login: to log-in to the API.
    catalog: to fetch the catalog of measurement locations and parameters.
    get_data: to download time-series.
	
The Matlab package contains the following scripts and is also available in OpenEarthTools:
	mvbLogin: to log-in to the API.
	mvbCatalog: to fetch the catalog of measurement locations and parameters.
	mvbTable: to get a graphical overview of available data.
	mvbGetData: to download time-series.
	setproperty: OET prerequisite.