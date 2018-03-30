#!/usr/bin/perl 
#===============================================================================
#
#         FILE: wzd2wps.pl
#
#        USAGE: ./wzd2wps.pl  
#
#  DESCRIPTION: convert namelist.wps.wzd to namelist.wps.template
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), PaulS
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 20/10/17
#     REVISION: ---
#===============================================================================

use warnings;

$BaseDir=$ENV{'BASEDIR'};
if ( !defined $BaseDir ){
	die "*** ERROR EXIT - You must export BASEDIR";
}

### READ RASP GRID DATA FROM NAMELIST FILE
$datafilename = "namelist.wps.wzd" ;
open ( DATAFILE, "<", $datafilename ) or die "*** ERROR EXIT - CAN'T OPEN $datafilename";

@datalines = <DATAFILE>;

$opfilename = "namelist.wps.template";
open ( OPFILE, ">$opfilename" ) or die "*** ERROR EXIT - Can't open $opfilename";

for ( $line=0 ; $line<=$#datalines ; $line++ ) {
  if( $datalines[$line] =~ m| *&share.*$|i )        { &do_share();     }
  if( $datalines[$line] =~ m| *&geogrid.*$|i)       { &chk_geogrid();  # Bombs out if error
                                                      &do_geogrid();   }
  if( $datalines[$line] =~ m| *&ungrib.*$|i)        { &do_ungrib(); }
  if( $datalines[$line] =~ m| *&metgrid.*$|i)       { &do_metgrid();   }
  if( $datalines[$line] =~ m| *&mod_levs.*$|i)      { &copy_section(); }
  if( $datalines[$line] =~ m| *&domain_wizard.*$|i) { &copy_section(); }
}  

close(DATAFILE);
close(OPFILE);
exit;

sub do_ungrib
{
  our @datalines;
  our $line;

  print OPFILE "$datalines[$line]";

  for ( $line++ ; $line<=$#datalines ; $line++ ) {
    if ( $datalines[$line] =~ m|^.*prefix.*=.*.*$|i ) {
      print OPFILE " prefix = 'UNGRIB',\n";
      next;
    }
    if( $datalines[$line] =~ m| */ *$| ){   # End of Section
      print OPFILE "/\n\n";
      return;
    }
    print OPFILE "$datalines[$line]";
  }
}

sub do_metgrid
{
  our @datalines;
  our $line;

  print OPFILE "$datalines[$line]";

  for ( $line++ ; $line<=$#datalines ; $line++ ) {
    if ( $datalines[$line] =~ m|^.*fg_name.*=.*.*$|i ) {
      print OPFILE " fg_name = 'UNGRIB',\n";
      next;
    }
    if ( $datalines[$line] =~ m|^ *opt_output_from_metgrid_path.*=.*.*$|i ) {
      next;
    }
    if ( $datalines[$line] =~ m|^.*opt_metgrid_tbl_path.*=.*.*$|i ) {
      print OPFILE " opt_metgrid_tbl_path = '". $BaseDir . "/RUN.TABLES',\n";
      next;
    }
    if( $datalines[$line] =~ m| */ *$| ){   # End of Section
      print OPFILE "/\n\n";
      return;
    }
    print OPFILE "$datalines[$line]";
  }
}

# Update interval_seconds in share section
sub do_geogrid
{
  our @datalines;
  our $line;

  print OPFILE "$datalines[$line]";

  for ( $line++ ; $line<=$#datalines ; $line++ ) {
    if ( $datalines[$line] =~ m|^.*geog_data_path.*=.*.*$|i ) {
      print OPFILE " GEOG_DATA_PATH = '" . $BaseDir . "/geog',\n";
      next;
    }
    if ( $datalines[$line] =~ m|^ *opt_geogrid_tbl_path.*=.*.*$|i ) {
      print OPFILE " OPT_GEOGRID_TBL_PATH = '" . $BaseDir . "/RUN.TABLES',\n";
      next;
    }
    if ( $datalines[$line] =~ m|^ *opt_output_from_geogrid.*$|i ) {
      next;
    }
    if( $datalines[$line] =~ m| */ *$| ){   # End of Section
      print OPFILE "/\n\n";
      return;
    }
    print OPFILE "$datalines[$line]";
  }
}


sub do_share
{
  our @datalines;
  our $line;

  print OPFILE "$datalines[$line]";

  for ( $line++ ; $line<=$#datalines ; $line++ ) {
    if ( $datalines[$line] =~ m|^ *interval_seconds.*=.* ([0-9]+),.*$|i ) {
      print OPFILE " interval_seconds = 10800,\n";
	  next;
    }
    if ( $datalines[$line] =~ m|^ *opt_output_from_geogrid.*$|i ) {
      next;
   	}
    if( $datalines[$line] =~ m| */ *$| ){   # End of Section
      print OPFILE "/\n\n";
      return;
    }
    print OPFILE "$datalines[$line]";
  }
}


# Copy entire Section
sub copy_section
{
  our @datalines;  # NB Same @nldata as above
  our $line;       # NB Same $line as above

  for( ; $line <= $#datalines; $line++ ){
    print OPFILE "$datalines[$line]";
    if( $datalines[$line] =~ m| */ *$| ){   # End of Section
      print OPFILE "\n";
      return;
    }
  }
}


# Remove (partial) ouput file & die
sub bomb
{
  $msg = @_;
  our $opfilename;

  `rm -f $opfilename`;
  die($msg);
}


# Sanity checks on geogrid
sub chk_geogrid
{
  our $datafilename;
  our @datalines;
  our $line;
  our $BaseDir;
  my  $l;

  for( $l = $line; $l <= $#datalines; $l++){
    if ( $datalines[$l] =~ m|^ *parent_grid_ratio * = * (.*) *$|i )  { @parent_grid_ratio = split ( / *,/, $1 ) ; }
    if ( $datalines[$l] =~ m|^ *i_parent_start * = * (.*) *$|i )     { @i_parent_start = split ( / *,/, $1 ) ; }
    if ( $datalines[$l] =~ m|^ *j_parent_start * = * (.*) *$|i )     { @j_parent_start = split ( / *,/, $1 ) ; }
    if ( $datalines[$l] =~ m|^ *e_we * = * (.*) *$|i )               { @e_we = split ( / *,/, $1 ) ; }
    if ( $datalines[$l] =~ m|^ *e_sn * = * (.*) *$|i )               { @e_sn = split ( / *,/, $1 ) ; }
    if ( $datalines[$l] =~ m|^ *ref_lat * = * ([^, ]*).*$|i )        { $ref_lat = $1 ; }
    if ( $datalines[$l] =~ m|^ *ref_lon * = * ([^, ]*).*$|i )        { $ref_lon = $1 ; }
    if ( $datalines[$l] =~ m|^ *truelat1 * = * ([0-9]+\.[0-9]+).*$|) { $true_lat1 = $1; }
    if ( $datalines[$l] =~ m|^ *truelat2 * = * ([0-9]+\.[0-9]+).*$|) { $true_lat2 = $1; }
    if ( $datalines[$l] =~ m|^ *stand_lon * = * ([^, ]*).*$|i )      { $stand_lon = $1 ; }
    if ( $datalines[$l] =~ m|^ *dx * = * ([^, ]*).*$|i )             { $dx = $1 ; }
    if ( $datalines[$l] =~ m|^ *dy * = * ([^, ]*).*$|i )             { $dy = $1 ; }
    if ( $datalines[$l] =~ m|^ *map_proj * = * ([^, ]*).*$|i )       { $map_proj = $1 ; }
  }

  ### do sanity checks
  if( ! defined $ref_lat   || ! defined $ref_lon    || 
      ! defined $true_lat1 || ! defined $true_lat2  ||
	  ! defined $stand_lon || ! defined $map_proj )
    { &bomb( "ERROR: MISSING DATA in DATAFILE" . $datafilename); }
  if( ! defined $parent_grid_ratio[0] ||
      ! defined  $i_parent_start[0]   || ! defined  $j_parent_start[0] ||
      ! defined  $e_we[0]             || ! defined  $e_sn[0] )
    { &bomb("ERROR: MISSING DATA FOR GRID 1 in DATAFILE" . $datafilename ); }
  if( ! defined $parent_grid_ratio[1]    ||
      ! defined  $i_parent_start[1] || ! defined  $j_parent_start[1] ||
      ! defined  $e_we[1]              || ! defined  $e_sn[1] )
    { &bomb("ERROR: MISSING DATA FOR GRID 2 in DATAFILE" . $datafilename ); }

  ### Other programs (e.g. ij2latlon.PL) are only valid for tangent lambert projection
  if( $true_lat1 != $true_lat2 || $map_proj !~ m|lambert|i )
    { &bomb("ERROR: Use only Tangent Lambert Projection with true_lat1 == true_lat2"); }

  chomp($dx);
  chomp($dy);
  chomp($map_proj);
  chomp($ref_lat);
  chomp($ref_lon);
  chomp($stand_lon);

  # Make sure nest domain will fit
  $needed_we = (($e_we[1] - 1) / $parent_grid_ratio[1] + $i_parent_start[1] + 5);
  if($needed_we > $e_we[0]){
    &bomb("Nest domain will not fit in W-E direction\n");
  }
  $needed_sn = (($e_sn[1] - 1) / $parent_grid_ratio[1] + $j_parent_start[1] + 5);
  if($needed_sn > $e_sn[0]){
    &bomb("Nest domain will not fit in S-N direction\n");
  }

  # Check size is OK
  if(($e_we[1]-1)%$parent_grid_ratio[1] != 0){
    &bomb("W-E extent ($e_we[1] - 1) not divisible by nest ratio ($parent_grid_ratio[1])");
  }
  if(($e_sn[1]-1)%$parent_grid_ratio[1] != 0){
    &bomb("S-N extent ($e_sn[1] - 1) not divisible by nest ratio ($parent_grid_ratio[1])");
  }

  print "geogrid check OK\n";
  return;
}


