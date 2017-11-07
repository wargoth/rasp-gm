#!/usr/bin/perl 
#===============================================================================
#
#         FILE: wrfsi2wps.pl
#
#        USAGE: ./wrfsi2wps.pl  
#
#  DESCRIPTION: convert wrfsi.nl to namelist.wps
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), PaulS
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 22/02/14 13:42:51
#     REVISION: ---
#===============================================================================

use warnings;

$BaseDir=$ENV{'BASEDIR'};
if ( !defined $BaseDir ){
	die "*** ERROR EXIT - You must export BASEDIR";
}

### READ RASP GRID DATA FROM NAMELIST FILE
open ( DATAFILE, "<", "wrfsi.nl" ) or die "*** ERROR EXIT - CAN'T OPEN wrfsi.nl";
@datalines = <DATAFILE>;
for ( $iiline=0 ; $iiline<=$#datalines ; $iiline++ ) {
  if ( $datalines[$iiline] =~ m|^ *RATIO_TO_PARENT * = * (.*) *$|i )    { @RATIO_TO_PARENT = split ( / *,/, $1 ) ; }
  if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_LLI * = * (.*) *$|i )  { @DOMAIN_ORIGIN_LLI = split ( / *,/, $1 ) ; }
  if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_LLJ * = * (.*) *$|i )  { @DOMAIN_ORIGIN_LLJ = split ( / *,/, $1 ) ; }
  if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_URI * = * (.*) *$|i )  { @DOMAIN_ORIGIN_URI = split ( / *,/, $1 ) ; }
  if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_URJ * = * (.*) *$|i )  { @DOMAIN_ORIGIN_URJ = split ( / *,/, $1 ) ; }
  if ( $datalines[$iiline] =~ m|^ *MOAD_KNOWN_LAT * = * ([^, ]*).*$|i ) { $MOAD_KNOWN_LAT = $1 ; }
  if ( $datalines[$iiline] =~ m|^ *MOAD_KNOWN_LON * = * ([^, ]*).*$|i ) { $MOAD_KNOWN_LON = $1 ; }
  if ( $datalines[$iiline] =~ m|^ *MOAD_STAND_LATS * = * (.*) *$|i )    { @MOAD_STAND_LATS = split ( / *,/, $1 ) ; }
  if ( $datalines[$iiline] =~ m|^ *MOAD_STAND_LONS * = * ([^, ]*).*$|i ){ $MOAD_STAND_LONS = $1 ; }
  if ( $datalines[$iiline] =~ m|^ *MOAD_DELTA_X * = * ([^, ]*).*$|i )   { $MOAD_DELTA_X = $1 ; }
  if ( $datalines[$iiline] =~ m|^ *MOAD_DELTA_Y * = * ([^, ]*).*$|i )   { $MOAD_DELTA_Y = $1 ; }
  if ( $datalines[$iiline] =~ m|^ *MAP_PROJ_NAME * = * ([^, ]*).*$|i )  { $MAP_PROJ_NAME = $1 ; }
}
close(DATAFILE);

### do sanity checks
if( ! defined $MOAD_KNOWN_LAT     || ! defined $MOAD_KNOWN_LON  || 
    ! defined $MOAD_STAND_LATS[0] || ! defined $MOAD_STAND_LONS || 
    ! defined $MAP_PROJ_NAME )
  { die "ERROR: MISSING DATA in DATAFILE $datafilename "; }
if( ! defined $RATIO_TO_PARENT[0]    ||
    ! defined  $DOMAIN_ORIGIN_LLI[0] || ! defined  $DOMAIN_ORIGIN_LLJ[0] ||
    ! defined  $DOMAIN_ORIGIN_URI[0] || ! defined  $DOMAIN_ORIGIN_URJ[0] )
  { die "ERROR: MISSING DATA FOR GRID 1 in DATAFILE $datafilename "; }
if( ! defined $RATIO_TO_PARENT[1]    ||
    ! defined  $DOMAIN_ORIGIN_LLI[1] || ! defined  $DOMAIN_ORIGIN_LLJ[1] ||
    ! defined  $DOMAIN_ORIGIN_URI[1] || ! defined  $DOMAIN_ORIGIN_URJ[1] )
  { die "ERROR: MISSING DATA FOR GRID 2 in DATAFILE $datafilename "; }

### Other programs (e.g. ij2latlon.PL) are only valid for tangent lambert projection
if( $MOAD_STAND_LATS[0] == $MOAD_STAND_LATS[1] && $MAP_PROJ_NAME =~ m|lambert|i )
  { $MOAD_STAND_LAT = $MOAD_STAND_LATS[0] ; }
else
  { die "ERROR: Use only Tangent Lambert Projection (STAND_LATS[0] must equal STAND_LATS[1])"; }

chomp($MOAD_DELTA_X);
chomp($MOAD_DELTA_Y);
chomp($MAP_PROJ_NAME);
chomp($MOAD_KNOWN_LAT);
chomp($MOAD_KNOWN_LON);
chomp($MOAD_STAND_LONS);

$e_we = ($DOMAIN_ORIGIN_URI[1] - $DOMAIN_ORIGIN_LLI[1]) * $RATIO_TO_PARENT[1] + 1;
$e_sn = ($DOMAIN_ORIGIN_URJ[1] - $DOMAIN_ORIGIN_LLJ[1]) * $RATIO_TO_PARENT[1] + 1;

# Make sure nest domain will fit
$needed_sn = (($e_sn - 1) / $RATIO_TO_PARENT[1] + $DOMAIN_ORIGIN_LLJ[1] + 5);
$max_URJ_1 = $DOMAIN_ORIGIN_URJ[0] - 5;
$needed_we = (($e_we - 1) / $RATIO_TO_PARENT[1] + $DOMAIN_ORIGIN_LLI[1] + 5);
$max_URI_1 = $DOMAIN_ORIGIN_URI[0] - 5;
if($needed_we > $DOMAIN_ORIGIN_URI[0]){
  print "Nest domain will not fit in W-E direction\n";
  print "Either increase DOMAIN_ORIGIN_URI[0] to $needed_we\n";
  print "Or decrease DOMAIN_ORIGIN_URI[1] to $max_URI_1\n";
}
if($needed_sn > $DOMAIN_ORIGIN_URJ[0]){
  print "Nest domain will not fit in S-N direction\n";
  print "Either increase DOMAIN_ORIGIN_URJ[0] to $needed_sn\n";
  print "Or decrease DOMAIN_ORIGIN_URJ[1] to $max_URJ_1\n";
}

# Output the results
$opfilename = "namelist.wps.template";
open ( WPSFILE, ">$opfilename" ) or die "*** ERROR EXIT - Can't open $opfilename";

print WPSFILE "&share\n";
print WPSFILE " wrf_core             = 'ARW'\n";
print WPSFILE " max_dom              = 2,\n";
print WPSFILE " start_date           = '2014-02-22_03:00:00', '2014-02-22_03:00:00',\n";
print WPSFILE " end_date             = '2014-02-22_18:00:00', '2014-02-22_18:00:00',\n";
print WPSFILE " interval_seconds     = 10800,\n";
print WPSFILE " io_form_geogrid      = 2,\n";
print WPSFILE "/\n\n";

print WPSFILE "&geogrid\n" ;
print WPSFILE " parent_id            = 1,      1,\n";
print WPSFILE " parent_grid_ratio    = $RATIO_TO_PARENT[0],     $RATIO_TO_PARENT[1],\n";
print WPSFILE " i_parent_start       = $DOMAIN_ORIGIN_LLI[0],     $DOMAIN_ORIGIN_LLI[1],\n";
print WPSFILE " j_parent_start       = $DOMAIN_ORIGIN_LLJ[0],     $DOMAIN_ORIGIN_LLJ[1],\n";
print WPSFILE " e_we                 = $DOMAIN_ORIGIN_URI[0],     $e_we,\n";
print WPSFILE " e_sn                 = $DOMAIN_ORIGIN_URJ[0],     $e_sn,\n";
print WPSFILE " geog_data_res        = '10m',  '2m',\n";
print WPSFILE " dx                   = $MOAD_DELTA_X,\n";
print WPSFILE " dy                   = $MOAD_DELTA_Y,\n";
print WPSFILE " map_proj             = $MAP_PROJ_NAME,\n";
print WPSFILE " ref_lat              = $MOAD_KNOWN_LAT,\n";
print WPSFILE " ref_lon              = $MOAD_KNOWN_LON,\n";
print WPSFILE " truelat1             = $MOAD_STAND_LAT,\n";
print WPSFILE " truelat2             = $MOAD_STAND_LAT,\n";
print WPSFILE " stand_lon            = $MOAD_STAND_LONS,\n";
print WPSFILE " GEOG_DATA_PATH       = '$BaseDir/geog'\n";       # These two MUST be in CAPS(!?!)
print WPSFILE " OPT_GEOGRID_TBL_PATH = '$BaseDir/RUN.TABLES'\n"; # for geogrid
print WPSFILE "/\n\n";

print WPSFILE "&ungrib\n";
print WPSFILE " out_format           = 'WPS',\n";
print WPSFILE " prefix               = 'UNGRIB',\n";
print WPSFILE "/\n\n";

print WPSFILE "&metgrid\n";
print WPSFILE " fg_name              = 'UNGRIB',\n";
print WPSFILE " io_form_metgrid      = 2,\n";
print WPSFILE " OPT_METGRID_TBL_PATH = '$BaseDir/RUN.TABLES'\n";
print WPSFILE "/\n\n";

close(WPSFILE);

