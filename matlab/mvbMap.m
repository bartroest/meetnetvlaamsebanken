function catalog = mvbMap(varargin)
%MVBMAP  Shows a map with stations from Meetnet Vlaamse Banken.
%
%   This script shows a map with the locations of stations from Meetnet
%   Vlaamse Banken (Flemish Banks Monitoring Network API). The catalog is
%   optionally returned in a struct.
%
%   A login token is required, which can be obtained with MVBLOGIN. A login
%   can be requested freely from https://meetnetvlaamsebanken.be/
%
%   Syntax:
%   varargout = mvbMap(varargin);
%
%   Input: For <keyword,value> pairs call mvbMap() without arguments.
%   varargin  =
%       token: <weboptions object>
%           Weboptions object containing the accesstoken. Generate this
%           token via mvbLogin.
%       language: 
%       apiurl: url to Meetnet Vlaamse Banken API.
%       epsg_out: EPSG code for the map's coordinate system. E.g.:
%           4326 (WGS'84)
%           25831 (ETRS89 / UTM zone 31N)
%           31370 (Belge Lambert'72, default)
%           28992 (Rijksdriehoek/Amersfoort)
%
%   Output:
%   varargout =
%       catalog: struct
%           Contains overview of locations, parameters and meta-data.
%
%   Example
%   mvbMap('token',token);
%
%   See also: MVBLOGIN, MVBCATALOG, MVBTABLE, MVBGETDATA.

%% Copyright notice
%   --------------------------------------------------------------------
%   Copyright (C) 2021 KU Leuven
%       Bart Roest
%
%       bart.roest@kuleuven.be 
%       l.w.m.roest@tudelft.nl
%
%       KU Leuven campus Bruges,
%       Spoorwegstraat 12,
%       8200 Bruges,
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
% Created: 18 Jan 2021
% Created with Matlab version: 9.9.0.1538559 (R2020b) Update 3

% $Id: $
% $Date: $
% $Author: $
% $Revision: $
% $HeadURL: $
% $Keywords: $

%% Input arguments
OPT.apiurl='https://api.meetnetvlaamsebanken.be/V2/';
OPT.token=weboptions;
OPT.epsg_map=31370;
OPT.language=3;

% return defaults (aka introspection)
if nargin==0;
    catalog = {OPT};
    return
elseif nargin==1;
    OPT.token=varargin{1};
else
    % overwrite defaults with user arguments
    OPT = setproperty(OPT, varargin);
end

% if ischar(OPT.language);
%     if strncmpi(OPT.language,'NL',1);
%         OPT.language=1;
%     elseif strncmpi(OPT.language,'FR',1);
%         OPT.language=2;
%     elseif strncmpi(OPT.language,'EN',1);
%         OPT.language=3;
%     else
%         fprintf(1,'Unknown language option "%s", using EN-GB instead. \n',OPT.language);
%         OPT.language=3;
%     end
% elseif isscalar(OPT.language) && OPT.language >=1 && OPT.language <=3;
%     %Use number
% else
%     fprintf(1,'Unknown language option "%s", using EN-GB instead. \n',OPT.language);
%     OPT.language=3;
% end

%% Login Check
% Check if login is still valid!
response=webread([OPT.apiurl,'ping'],OPT.token);
if isempty(response.Customer) %Check if login has expired.
    fprintf(1,['Your login token is invalid, please login using mvbLogin \n'...
        'Use the obtained token from mvbLogin in this function. \n']);
    catalog=cell(nargout);
    return
end
%% Get Catalog
catalog = mvbCatalog(OPT.token);
%% Create a Map figure
if ~exist('plotMapTiles.m','file')==2
    error('Map plot function not found, sign up to or update OpenEarthTools');
end
[~,ax,~]=plotMapTiles('xlim',[ 2.2934, 3.3673],'ylim',[51.0880,51.5950],'epsg_out',OPT.epsg_map);
if OPT.epsg_map==31370;
    xlim([1e4 9e4]);
end
xlabel(ax,'Easting [m]');
ylabel(ax,'Northing [m]');
title(ax,'Locations of Measurement Stations');

%% Plot stations
for n = 1:length(catalog.Locations);
    ll=str2num(catalog.Locations(n).PositionWKT(8:end-1)); %#ok<ST2NM>
    [x,y]=convertCoordinates(ll(1),ll(2),'CS1.code',4326,'CS2.code',OPT.epsg_map);
    plot(x,y,'xk');
    %text(x,y,{ctl.Locations(n).ID;ctl.Locations(n).Name(OPT.language).Message});
    text(x,y,{catalog.Locations(n).ID})
end

% %% Print
% print(fullfile(fileparts(mfilename('fullpath')),['map_',OPT.epsg_map]),'-dpng')
