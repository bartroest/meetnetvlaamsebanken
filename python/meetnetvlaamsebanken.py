# -*- coding: utf-8 -*-
"""
Package to download data from the Meetnet Vlaamse Banken API (Flemish Banks 
Monitoring network).
The Flemish Banks monitoring network consists of many measurement locations 
providing hydro-meteorological time-series. Measurement locations are situated 
on the Belgian Continental Shelf area and the Belgian coast.

To download data, an account is required which can be freely requested at
https://meetnetvlaamsebanken.be/

The package contains 4 methods:
    ping: to ping the API and test for successfull login status.
    login: to log-in to the API.
    catalog: to fetch the catalog of measurement locations and parameters.
    get_data: to download timeseries.

Created on Thu Aug 22 12:52:02 2019

@author: LWM Roest
@email: bart.roest@kuleuven.be
@email: l.w.m.roest@tudelft.nl
"""

#First test version for python MeetnetVlaamseBanken toolbox.
#The following packages are required:
import numpy as np
import requests
import json
#from datetime import datetime

#Default values:
#apiurl = "https://api.meetnetvlaamsebanken.be/"


#Routine for ping request
def ping(token="") :
    """Sends ping request to meetnet vlaamse banken API."""
    
    pingpath = "https://api.meetnetvlaamsebanken.be/V2/ping/"
#     if not exist(token):
#         token= " "
    headers = {"Authorization": "Bearer "+token}
    pingresponse = requests.get(pingpath, headers=headers, verify=True)
    print(pingresponse.text)
    pingstatus = json.loads(pingresponse.text)
    return pingstatus

#Routine to login to the API
def login(username,password):
    """Log-in to the API with supplied credentials."""
    
    loginpath = "https://api.meetnetvlaamsebanken.be/Token/"
#    postdata = {"grant_type": "password","username": input("username: "),
#                "password": input("Password: ")}
    postdata = {"grant_type": "password","username": username,
                "password": password}
    loginresponse = requests.post(loginpath, data=postdata, verify=True)
    jdata=(json.loads(loginresponse.text))
    token=jdata["access_token"]        
    return token

#Routine to fetch the catalog of data
def catalog(token):
    """Get the catalog of available stations and parameters."""
    catpath = "https://api.meetnetvlaamsebanken.be/V2/Catalog/"
    headers = {"authorization": "Bearer "+token}
    catresponse = requests.get(catpath, headers=headers, verify=True)
    ctl=json.loads(catresponse.content)
    return ctl

#Routine to fetch data
def get_data(token,stationparameter,tstart,tstop):
    """Get data from the API for the requested station and time-span."""
    
    # Test login status
    pingstatus = ping(token)
    if pingstatus["Customer"] is None:
        print("Your login token is invalid, please use login() to obtain a new" 
              " token.\n")
        return
    
    # Set default values
    getpath = "https://api.meetnetvlaamsebanken.be/V2/getData/"
    headers = {"authorization": "Bearer "+token}
    
    # Vector of start values. Max range per request is 365.00 days.
    # For longer time spans, multiple requests are issued.
    t_start=np.arange(np.datetime64(tstart), np.datetime64(tstop), 
                      np.timedelta64(365,"D"))
    
    v=np.array([])
    t=np.array([], dtype="datetime64[s]")
    
    for i in range(len(t_start)):
        if i is len(t_start)-1:
            t_stop = np.datetime64(tstop)
        else:
            t_stop = t_start[i+1]
        print("Retreiving data for ID: {0} from {1} to {2}\n".format(
                stationparameter, 
                np.datetime_as_string(t_start[i]),
                np.datetime_as_string(t_stop)))
                
        postdata= {"StartTime": np.datetime_as_string(t_start[i]), 
                   "EndTime": np.datetime_as_string(t_stop), 
                   "IDs": stationparameter}
        getresponse = requests.post(getpath, headers=headers, data=postdata, 
                                    verify=True)
        data=json.loads(getresponse.content)
        
        print(len(data['Values']))

        if data["Values"] is None: 
            # When ID is not found, data.Values will be empty
            print("Warning: empty result, ID %s not found! \n".format(
                    stationparameter))
            continue # Station not found, terminate execution.
            
        elif data["Values"][0]["Values"] is None: 
            # When ID is found, but no data is available in the time interval, 
            # the values are empty.
            print("ID {0} was found, but there is no data in this time"
                  " interval.\n".format(stationparameter));
            continue # continue to next request.
        
        else:
            nn=len(data["Values"][0]["Values"])
            vtemp=np.zeros(nn)
            ttemp=np.zeros(nn,dtype="datetime64[s]")
        
            for n in range(nn):
                vtemp[n]=float(data["Values"][0]["Values"][n]["Value"])
                #t[n]=datetime.strptime(dd["Values"][0]["Values"][n]["Timestamp"],"%Y-%m-%dT%H:%M:%S%z")
                #t[n]=datetime.fromisoformat(dd["Values"][0]["Values"][n]["Timestamp"])
                ttemp[n]=np.datetime64(data["Values"][0]["Values"][n]["Timestamp"][:-6])

            v=np.append(v, vtemp)
            t=np.append(t, ttemp)
    
    #Return only unique values! Repeated values are omitted.
    (t, idx)=np.unique(t, return_index=True)
    v=v[idx]

    return t, v, data

#EOF