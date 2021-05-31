function [varargout] = mvbGetAll(varargin)
%MVBGETALL Gets all available timeseries from Meetnet Vlaamse Banken API.
%
%   mvbGetAll retreives all currently available timeseries from the API of
%   Meetnet Vlaamse Banken (Flemish Banks Monitoring Network API).
%   All data (including meta-data) is returned in a struct.
%   Meetnet Vlaamse Banken (Flemish Banks Monitoring Network API) only
%   accepts requests for timeseries <=365 days. This script runs several
%   subsequent GET requests to obtain a longer time series.
%
%   A login token is required, which can be obtained with MVBLOGIN. A login
%   can be requested freely from https://meetnetvlaamsebanken.be/
%
%   Syntax:
%   [time, value] = mvbGetAll(<keyword>, <value>, token);
%
%   Input: For <keyword,value> pairs call mvbGetAll() without arguments.
%   varargin =
%       start: 'string'
%           Start time string in format: 'yyyy-mm-dd HH:MM:SS' (the time
%           part is optional).
%       end: 'string'
%           End time string, same format as start.
%       token: <weboptions object>
%           Weboptions object containing the accesstoken. Generate this
%           token via mvbLogin. If no token is given or invalid, the user
%           is prompted for credentials.
%       language: string of preferred meta data language: 'NL','FR'or 'EN'
%       apiurl: url to Meetnet Vlaamse Banken API.
%
%   Output:
%   varargout = 
%       MVB: Struct containing all the data.
%
%   Example
%   MVB=mvbGetAll('token',token);
%
%   See also: MVBLOGIN, MVBCATALOG, MVBMAP, MVBTABLE, MVBGETDATA.

%% Copyright notice
%   --------------------------------------------------------------------
%   Copyright (C) 2021 KU Leuven
%       Bart Roest
%
%       bart.roest@kuleuven.be
%       l.w.m.roest@tudelft.nl
%
%       KU Leuven campus Bruges,
%       Spoorwegstraat 12
%       8200 Bruges
%       Belgium
%
%   This library is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This library is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this library.  If not, see <http://www.gnu.org/licenses/>.
%   --------------------------------------------------------------------

% This tool is part of <a href="http://www.OpenEarth.eu">OpenEarthTools</a>.
% OpenEarthTools is an online collaboration to share and manage data and
% programming tools in an open source, version controlled environment.
% Sign up to recieve regular updates of this function, and to contribute
% your own tools.

%% Version <http://svnbook.red-bean.com/en/1.5/svn.advanced.props.special.keywords.html>
% Created: 20 April 2021
% Created with Matlab version: 9.5.0.1067069 (R2018b) Update 4

% $Id: $
% $Date: $
% $Author: $
% $Revision: $
% $HeadURL: $
% $Keywords: $

%%
OPT.apiurl='https://api.meetnetvlaamsebanken.be/V2/'; %Base URL
OPT.token=weboptions;
OPT.language=3;
OPT.start='1970-01-01 00:00:00'; % Start time
OPT.end=datestr(now,'yyyy-mm-dd'); % End time
OPT.log=1; %Logfile ID.

% return defaults (aka introspection)
if nargin==0;
    varargout = {OPT};
    return
elseif odd(nargin);
    OPT.token = varargin{end}; %Assume token is the last input argument.
    varargin = varargin(1:end-1);
end
% overwrite defaults with user arguments
OPT = setproperty(OPT, varargin);

% Set meta-data language
if ischar(OPT.language);
    if strncmpi(OPT.language,'NL',1);
        OPT.language=1;
    elseif strncmpi(OPT.language,'FR',1);
        OPT.language=2;
    elseif strncmpi(OPT.language,'EN',1);
        OPT.language=3;
    else
        fprintf(fid,'Unknown language option "%s", using EN-GB instead. \n',OPT.language);
        OPT.language=3;
    end
elseif isscalar(OPT.language) && OPT.language >=1 && OPT.language <=3;
    %Use number
else
    fprintf(fid,'Unknown language option "%s", using EN-GB instead. \n',OPT.language);
    OPT.language=3;
end

if ischar(OPT.log);
	%Filename: open file for writing
	fid=fopen(OPT.log,'w+');
elseif OPT.log <= 3
	%Output to command window; 1: standard, 2: error, 3: warning.
	fid=OPT.log;
else
	warning('Logfile invalid');
	fid=1;
end
%% code
% Check if login is still valid!
response=webread([OPT.apiurl,'ping'],OPT.token);
if isempty(response.Customer) %If login has expired.
    fprintf(fid,['Your login token is invalid, please login using mvbLogin \n'...
        'Use the obtained token from mvbLogin in this function. \n']);
    varargout=cell(nargout);
    return
end

%% Input check
% Get the catalog
ctl=mvbCatalog('token',OPT.token);

% Define struct to populate
MVB=struct;

% Determine all locations and write meta-data.
fprintf(fid,'Writing meta-data\n');
for n=1:length(ctl.Locations);
    MVB.(ctl.Locations(n).ID).meta=struct(...
        'name',ctl.Locations(n).Name(OPT.language).Message,...
        'description',ctl.Locations(n).Description(OPT.language).Message,...
        'position',str2num(ctl.Locations(n).PositionWKT(8:end-1))); %#ok<ST2NM>
end


% Write available data to struct.
fprintf(fid,'Writing data\n');
for n=1:length(ctl.AvailableData);
    fprintf(fid,'Processing %s, %3i of %3i\n',ctl.AvailableData(n).ID,n,length(ctl.AvailableData));
    % get the time series.
    [t,v]=mvbGetData('id',ctl.AvailableData(n).ID,'start',OPT.start,'end',OPT.end,'token',OPT.token);
    MVB.(ctl.AvailableData(n).Location).(ctl.AvailableData(n).Parameter)=struct(...
        'meta',[],...
        'time',t,...
        'value',v);
    % get meta-data for parameter.
    m=find(strcmp({ctl.Parameters.ID},ctl.AvailableData(n).Parameter));
    MVB.(ctl.AvailableData(n).Location).(ctl.AvailableData(n).Parameter).meta=struct(...
        'name',ctl.Parameters(m).Name(OPT.language).Message,...
        'unit',ctl.Parameters(m).Unit,...
        'type',ctl.ParameterTypes.(['x',num2str(ctl.Parameters(m).ParameterTypeID)]).Name(OPT.language).Message);
end
varargout={MVB};
fprintf(fid,'Done!\n');

end
%EOF