%% @author Bob Ippolito <bob@redivi.com>
%% @copyright 2006 Bob Ippolito

%% @doc Geolocation by IP address.

-module(egeoip).
-author('bob@redivi.com').

-behaviour(gen_server).

%% record access API
-export([get/2]).

%% gen_server based API
-export([start/0, start/1, stop/0, lookup/1, reload/0, reload/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, terminate/2, code_change/3,
	handle_info/2]).

%% in-process API
-export([new/1, new/0]).
-export([lookup/2]).

%% implementation
-export([seek_country/2]).
-export([ip2long/1]).
-export([country_code/1, country_code3/1, country_name/1]).
-export([get_record/2]).

-define(GEOIP_COUNTRY_BEGIN, 16776960).
-define(GEOIP_STATE_BEGIN_REV0, 16700000).
-define(GEOIP_STATE_BEGIN_REV1, 16000000).
-define(GEOIP_STANDARD, 0).
-define(GEOIP_MEMORY_CACHE, 1).
-define(GEOIP_SHARED_MEMORY, 2).
-define(STRUCTURE_INFO_MAX_SIZE, 20).
-define(DATABASE_INFO_MAX_SIZE, 100).
-define(GEOIP_COUNTRY_EDITION, 106).
-define(GEOIP_PROXY_EDITION, 8).
-define(GEOIP_ASNUM_EDITION, 9).
-define(GEOIP_NETSPEED_EDITION, 10).
-define(GEOIP_REGION_EDITION_REV0, 112).
-define(GEOIP_REGION_EDITION_REV1, 3).
-define(GEOIP_CITY_EDITION_REV0, 111).
-define(GEOIP_CITY_EDITION_REV1, 2).
-define(GEOIP_ORG_EDITION, 110).
-define(GEOIP_ISP_EDITION, 4).
-define(SEGMENT_RECORD_LENGTH, 3).
-define(STANDARD_RECORD_LENGTH, 3).
-define(ORG_RECORD_LENGTH, 4).
-define(MAX_RECORD_LENGTH, 4).
-define(MAX_ORG_RECORD_LENGTH, 300).
-define(GEOIP_SHM_KEY, 16#4f415401).
-define(US_OFFSET, 1).
-define(CANADA_OFFSET, 677).
-define(WORLD_OFFSET, 1353).
-define(FIPS_RANGE, 360).
-define(GEOIP_UNKNOWN_SPEED, 0).
-define(GEOIP_DIALUP_SPEED, 1).
-define(GEOIP_CABLEDSL_SPEED, 2).
-define(GEOIP_CORPORATE_SPEED, 3).
-define(GEOIP_COUNTRY_CODES, {
"AP", "EU", "AD", "AE", "AF", "AG", "AI", "AL", "AM", "AN", "AO", "AQ",
"AR", "AS", "AT", "AU", "AW", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH",
"BI", "BJ", "BM", "BN", "BO", "BR", "BS", "BT", "BV", "BW", "BY", "BZ", "CA",
"CC", "CD", "CF", "CG", "CH", "CI", "CK", "CL", "CM", "CN", "CO", "CR", "CU",
"CV", "CX", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG",
"EH", "ER", "ES", "ET", "FI", "FJ", "FK", "FM", "FO", "FR", "FX", "GA", "GB",
"GD", "GE", "GF", "GH", "GI", "GL", "GM", "GN", "GP", "GQ", "GR", "GS", "GT",
"GU", "GW", "GY", "HK", "HM", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN",
"IO", "IQ", "IR", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM",
"KN", "KP", "KR", "KW", "KY", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS",
"LT", "LU", "LV", "LY", "MA", "MC", "MD", "MG", "MH", "MK", "ML", "MM", "MN",
"MO", "MP", "MQ", "MR", "MS", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA",
"NC", "NE", "NF", "NG", "NI", "NL", "NO", "NP", "NR", "NU", "NZ", "OM", "PA",
"PE", "PF", "PG", "PH", "PK", "PL", "PM", "PN", "PR", "PS", "PT", "PW", "PY",
"QA", "RE", "RO", "RU", "RW", "SA", "SB", "SC", "SD", "SE", "SG", "SH", "SI",
"SJ", "SK", "SL", "SM", "SN", "SO", "SR", "ST", "SV", "SY", "SZ", "TC", "TD",
"TF", "TG", "TH", "TJ", "TK", "TM", "TN", "TO", "TP", "TR", "TT", "TV", "TW",
"TZ", "UA", "UG", "UM", "US", "UY", "UZ", "VA", "VC", "VE", "VG", "VI", "VN",
"VU", "WF", "WS", "YE", "YT", "CS", "ZA", "ZM", "ZR", "ZW", "A1", "A2", "O1"}).
-define(GEOIP_COUNTRY_CODES3, {
"AP","EU","AND","ARE","AFG","ATG","AIA","ALB","ARM","ANT","AGO","AQ","ARG",
"ASM","AUT","AUS","ABW","AZE","BIH","BRB","BGD","BEL","BFA","BGR","BHR","BDI",
"BEN","BMU","BRN","BOL","BRA","BHS","BTN","BV","BWA","BLR","BLZ","CAN","CC",
"COD","CAF","COG","CHE","CIV","COK","CHL","CMR","CHN","COL","CRI","CUB","CPV",
"CX","CYP","CZE","DEU","DJI","DNK","DMA","DOM","DZA","ECU","EST","EGY","ESH",
"ERI","ESP","ETH","FIN","FJI","FLK","FSM","FRO","FRA","FX","GAB","GBR","GRD",
"GEO","GUF","GHA","GIB","GRL","GMB","GIN","GLP","GNQ","GRC","GS","GTM","GUM",
"GNB","GUY","HKG","HM","HND","HRV","HTI","HUN","IDN","IRL","ISR","IND","IO",
"IRQ","IRN","ISL","ITA","JAM","JOR","JPN","KEN","KGZ","KHM","KIR","COM","KNA",
"PRK","KOR","KWT","CYM","KAZ","LAO","LBN","LCA","LIE","LKA","LBR","LSO","LTU",
"LUX","LVA","LBY","MAR","MCO","MDA","MDG","MHL","MKD","MLI","MMR","MNG","MAC",
"MNP","MTQ","MRT","MSR","MLT","MUS","MDV","MWI","MEX","MYS","MOZ","NAM","NCL",
"NER","NFK","NGA","NIC","NLD","NOR","NPL","NRU","NIU","NZL","OMN","PAN","PER",
"PYF","PNG","PHL","PAK","POL","SPM","PCN","PRI","PSE","PRT","PLW","PRY","QAT",
"REU","ROU","RUS","RWA","SAU","SLB","SYC","SDN","SWE","SGP","SHN","SVN","SJM",
"SVK","SLE","SMR","SEN","SOM","SUR","STP","SLV","SYR","SWZ","TCA","TCD","TF",
"TGO","THA","TJK","TKL","TLS","TKM","TUN","TON","TUR","TTO","TUV","TWN","TZA",
"UKR","UGA","UM","USA","URY","UZB","VAT","VCT","VEN","VGB","VIR","VNM","VUT",
"WLF","WSM","YEM","YT","SCG","ZAF","ZMB","ZR","ZWE","A1","A2","O1"}).
-define(GEOIP_COUNTRY_NAMES, {
"Asia/Pacific Region", "Europe", "Andorra", "United Arab Emirates",
"Afghanistan", "Antigua and Barbuda", "Anguilla", "Albania", "Armenia",
"Netherlands Antilles", "Angola", "Antarctica", "Argentina", "American Samoa",
"Austria", "Australia", "Aruba", "Azerbaijan", "Bosnia and Herzegovina",
"Barbados", "Bangladesh", "Belgium", "Burkina Faso", "Bulgaria", "Bahrain",
"Burundi", "Benin", "Bermuda", "Brunei Darussalam", "Bolivia", "Brazil",
"Bahamas", "Bhutan", "Bouvet Island", "Botswana", "Belarus", "Belize",
"Canada", "Cocos (Keeling) Islands", "Congo, The Democratic Republic of the",
"Central African Republic", "Congo", "Switzerland", "Cote D'Ivoire", "Cook
Islands", "Chile", "Cameroon", "China", "Colombia", "Costa Rica", "Cuba", "Cape
Verde", "Christmas Island", "Cyprus", "Czech Republic", "Germany", "Djibouti",
"Denmark", "Dominica", "Dominican Republic", "Algeria", "Ecuador", "Estonia",
"Egypt", "Western Sahara", "Eritrea", "Spain", "Ethiopia", "Finland", "Fiji",
"Falkland Islands (Malvinas)", "Micronesia, Federated States of", "Faroe
Islands", "France", "France, Metropolitan", "Gabon", "United Kingdom",
"Grenada", "Georgia", "French Guiana", "Ghana", "Gibraltar", "Greenland",
"Gambia", "Guinea", "Guadeloupe", "Equatorial Guinea", "Greece", "South Georgia
and the South Sandwich Islands", "Guatemala", "Guam", "Guinea-Bissau",
"Guyana", "Hong Kong", "Heard Island and McDonald Islands", "Honduras",
"Croatia", "Haiti", "Hungary", "Indonesia", "Ireland", "Israel", "India",
"British Indian Ocean Territory", "Iraq", "Iran, Islamic Republic of",
"Iceland", "Italy", "Jamaica", "Jordan", "Japan", "Kenya", "Kyrgyzstan",
"Cambodia", "Kiribati", "Comoros", "Saint Kitts and Nevis", "Korea, Democratic
People's Republic of", "Korea, Republic of", "Kuwait", "Cayman Islands",
"Kazakstan", "Lao People's Democratic Republic", "Lebanon", "Saint Lucia",
"Liechtenstein", "Sri Lanka", "Liberia", "Lesotho", "Lithuania", "Luxembourg",
"Latvia", "Libyan Arab Jamahiriya", "Morocco", "Monaco", "Moldova, Republic
of", "Madagascar", "Marshall Islands", "Macedonia",
"Mali", "Myanmar", "Mongolia", "Macau", "Northern Mariana Islands",
"Martinique", "Mauritania", "Montserrat", "Malta", "Mauritius", "Maldives",
"Malawi", "Mexico", "Malaysia", "Mozambique", "Namibia", "New Caledonia",
"Niger", "Norfolk Island", "Nigeria", "Nicaragua", "Netherlands", "Norway",
"Nepal", "Nauru", "Niue", "New Zealand", "Oman", "Panama", "Peru", "French
Polynesia", "Papua New Guinea", "Philippines", "Pakistan", "Poland", "Saint
Pierre and Miquelon", "Pitcairn Islands", "Puerto Rico",
"Palestinian Territory",
"Portugal", "Palau", "Paraguay", "Qatar", "Reunion", "Romania",
"Russian Federation", "Rwanda", "Saudi Arabia", "Solomon Islands",
"Seychelles", "Sudan", "Sweden", "Singapore", "Saint Helena", "Slovenia",
"Svalbard and Jan Mayen", "Slovakia", "Sierra Leone", "San Marino", "Senegal",
"Somalia", "Suriname", "Sao Tome and Principe", "El Salvador", "Syrian Arab
Republic", "Swaziland", "Turks and Caicos Islands", "Chad", "French Southern
Territories", "Togo", "Thailand", "Tajikistan", "Tokelau", "Turkmenistan",
"Tunisia", "Tonga", "East Timor", "Turkey", "Trinidad and Tobago", "Tuvalu",
"Taiwan", "Tanzania, United Republic of", "Ukraine",
"Uganda", "United States Minor Outlying Islands", "United States", "Uruguay",
"Uzbekistan", "Holy See (Vatican City State)", "Saint Vincent and the
Grenadines", "Venezuela", "Virgin Islands, British", "Virgin Islands, U.S.",
"Vietnam", "Vanuatu", "Wallis and Futuna", "Samoa", "Yemen", "Mayotte",
"Serbia and Montenegro", "South Africa", "Zambia", "Zaire", "Zimbabwe",
"Anonymous Proxy","Satellite Provider","Other"}).

-record(geoipdb, {type = ?GEOIP_COUNTRY_EDITION,
		  record_length = ?STANDARD_RECORD_LENGTH,
		  segments = 0,
		  data = nil}).

-record(geoip, {country_code, country_code3, country_name, region,
		city, postal_code, latitude, longitude, area_code, dma_code}).

%% geoip record API

get(R, country_code) ->
    R#geoip.country_code;
get(R, country_code3) ->
    R#geoip.country_code3;
get(R, country_name) ->
    R#geoip.country_name;
get(R, region) ->
    R#geoip.region;
get(R, city) ->
    R#geoip.city;
get(R, postal_code) ->
    R#geoip.postal_code;
get(R, latitude) ->
    R#geoip.latitude;
get(R, longitude) ->
    R#geoip.longitude;
get(R, area_code) ->
    R#geoip.area_code;
get(R, dma_code) ->
    R#geoip.dma_code;
get(R, List) when is_list(List) ->
    [get(R, X) || X <- List].

%% server API


reload() ->
    reload(city).

reload(FileName) ->
    case new(FileName) of
	{ok, NewState} ->
	    gen_server:call(?MODULE, {reload, NewState});
	Error ->
	    Error
    end.

start() ->
    start(city).

start(FileName) ->
    gen_server:start_link(
      {local, ?MODULE}, ?MODULE, FileName, []).

stop() ->
    gen_server:cast(?MODULE, stop).

init(FileName) ->
    new(FileName).

lookup(Address) ->
    gen_server:call(?MODULE, {lookup, Address}).

%% gen_server callbacks

handle_call({lookup, Address}, _From, State) ->
    Res = lookup(State, Address),
    {reply, Res, State};
handle_call({restart, NewState}, _From, _State) ->
    {reply, ok, NewState}.

handle_cast(stop, State) ->
    {stop, normal, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    State.

handle_info(Info, State) ->
    error_logger:info_report([{'INFO', Info}, {'State', State}]),
    {noreply, State}.

%% Implementation

new() ->
    new(city).

new(city) ->
    new(priv_path(["GeoLiteCity.dat.gz"]));
new(Path) ->
    Data = load_file(Path),
    read_structures(Data, size(Data) - 3, ?STRUCTURE_INFO_MAX_SIZE).

lookup(D, Addr) when is_list(Addr) ->
    lookup(D, ip2long(Addr));
lookup(D, Addr) ->
    get_record(D, Addr).

read_structures(_Data, _, 0) ->
    error;
read_structures(Data, Seek, N) ->
    <<_:Seek/binary, Delim:3/binary, _/binary>> = Data,
    case Delim of
	<<255, 255, 255>> ->
	    <<_:Seek/binary, _:3/binary, Type, _/binary>> = Data,
	    Segments = case Type of
			   ?GEOIP_REGION_EDITION_REV0 ->
			       ?GEOIP_STATE_BEGIN_REV0;
			   ?GEOIP_REGION_EDITION_REV1 ->
			       ?GEOIP_STATE_BEGIN_REV1;
			   _ ->
			       read_segments(Type, Data, Seek + 4)
		       end,
	    Length = case Type of
			 ?GEOIP_ORG_EDITION ->
			     ?ORG_RECORD_LENGTH;
			 ?GEOIP_ISP_EDITION ->
			     ?ORG_RECORD_LENGTH;
			 _ ->
			     ?STANDARD_RECORD_LENGTH
		     end,
	    Rec = #geoipdb{type = Type,
			   segments = Segments,
			   record_length = Length,
			   data = Data},
	    {ok, Rec};
	_ ->
	    read_structures(Data, Seek - 1, N - 1)
    end.

get_record(D, Ip) ->
    case seek_country(D, Ip) of
	{ok, SeekCountry} ->
	    get_record(D, Ip, SeekCountry);
	Error ->
	    Error
    end.


get_record(D, _Ip, SeekCountry) ->
    Length = D#geoipdb.record_length,
    Segments = D#geoipdb.segments,
    Seek = SeekCountry + (((2 * Length) - 1) * Segments),
    <<_:Seek/binary, CountryNum, D0/binary>> = D#geoipdb.data,
    Country = country_code(CountryNum),
    Country3 = country_code3(CountryNum),
    CountryName = country_name(CountryNum),
    {Region, D1} = split_null(D0),
    {City, D2} = split_null(D1),
    {Postal, D3} = split_null(D2),
    <<RawLat:24/little, RawLon:24/little, D4/binary>> = D3,
    Lat = (RawLat / 10000) - 180,
    Lon = (RawLon / 10000) - 180,
    Type = D#geoipdb.type,
    {DmaCode, AreaCode} = get_record_ex(Type, Country, D4),
    Record = #geoip{country_code = Country,
		    country_code3 = Country3,
		    country_name = CountryName,
		    region = Region,
		    city = City,
		    postal_code = Postal,
		    latitude = Lat,
		    longitude = Lon,
		    dma_code = DmaCode,
		    area_code = AreaCode},
    {ok, Record}.
				  
get_record_ex(?GEOIP_CITY_EDITION_REV1, "US", <<Combo:24/little, _/binary>>) ->
    {Combo div 1000, Combo rem 1000};
get_record_ex(_, _, _) ->
    {0, 0}.
    


seek_country(D, Ip) ->
    seek_country(D, Ip, 0, 31).

seek_country(_D, _Ip, _Offset, -1) ->
    error;
seek_country(D, Ip, Offset, Depth) ->
    RecordLength = D#geoipdb.record_length,
    RB = 8 * RecordLength,
    Seek = 2 * RecordLength * Offset,
    Data = D#geoipdb.data,
    <<_:Seek/binary, X0:RB/little, X1:RB/little, _/binary>> = Data,
    Segments = D#geoipdb.segments,
    X = if (Ip band (1 bsl Depth)) == 0 -> X0;
	   true -> X1
	end,
    if (X >= Segments) -> {ok, X};
       true -> seek_country(D, Ip, X, Depth - 1)
    end.

find_null(<<0, _/binary>>, Index) ->
    Index;
find_null(<<_, Rest/binary>>, Index) ->
    find_null(Rest, 1 + Index).

split_null(Data) ->
    Length = find_null(Data, 0),
    <<String:Length/binary, 0, Rest/binary>> = Data,
    {String, Rest}.

country_code(Number) when Number > 0 ->
    Codes = ?GEOIP_COUNTRY_CODES,
    if Number > size(Codes) ->
	    "";
       true ->
	    element(Number, Codes)
    end;
country_code(_) ->
    "".

country_code3(Number) when Number > 0 ->
    Codes = ?GEOIP_COUNTRY_CODES3,
    if Number > size(Codes) ->
	    "";
       true ->
	    element(Number, Codes)
    end;
country_code3(_) ->
    "".

country_name(Number) when Number > 0 ->
    Names = ?GEOIP_COUNTRY_NAMES,
    if Number > size(Names) ->
	    "";
       true ->
	    element(Number, Names)
    end;
country_name(_) ->
    "".
    
read_segments(Type, Data, Seek) when Type == ?GEOIP_CITY_EDITION_REV0;
				     Type == ?GEOIP_CITY_EDITION_REV1;
				     Type == ?GEOIP_ORG_EDITION;
				     Type == ?GEOIP_ISP_EDITION;
				     Type == ?GEOIP_ASNUM_EDITION ->
    Bits = ?SEGMENT_RECORD_LENGTH * 8,
    <<_:Seek/binary, Segments:Bits/little, _/binary>> = Data,
    Segments.

ip2long(Address) when is_integer(Address) ->
    Address;
ip2long(Address) when is_list(Address) ->
    {ok, Tuple} = inet_parse:address(Address),
    ip2long(Tuple);
ip2long({B3, B2, B1, B0}) ->
    (B3 bsl 24) bor (B2 bsl 16) bor (B1 bsl 8) bor B0;
ip2long({W7, W6, W5, W4, W3, W2, W1, W0}) ->
    (W7 bsl 112) bor (W6 bsl 96) bor (W5 bsl 80) bor (W4 bsl 64) bor
	(W3 bsl 48) bor (W2 bsl 32) bor (W1 bsl 16) bor W0.
    

priv_path(Components) ->
    {file, Here} = code:is_loaded(?MODULE),
    AppDir = filename:dirname(filename:dirname(Here)),
    filename:join([AppDir, "priv" | Components]).

load_file(Path) ->
    case file:read_file(Path) of
	{ok, Raw} ->
	    case filename:extension(Path) of
		".gz" ->
		    zlib:gunzip(Raw);
		_ ->
		    Raw
	    end
    end.
