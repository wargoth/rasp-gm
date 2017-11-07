#!/usr/bin/perl 
#===============================================================================
#
#         FILE: wps2input.pl
#
#        USAGE: ./wps2input.pl  
#
#  DESCRIPTION: Update namelist.input.template with domain info from namelist.wps.template 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 24/02/14 17:23:52
#     REVISION: ---
#===============================================================================

# use strict;
use warnings;

# First, gather the required data from the WPS file
open (WPSFILE, "<", "namelist.wps.template") or die "ERROR: Can't open namelist.wps.template";
@wpsdata = <WPSFILE>;
for($line = 0; $line <= $#wpsdata; $line++){
  if( $wpsdata[$line] =~ m|^$| )                             { next; }
  if( $wpsdata[$line] =~ m|^.*parent_grid_ratio *= *(.*)|i ) { @parent_grid_ratio = split( / *,/, $1 ); }
  if( $wpsdata[$line] =~ m|^( *i_parent_start *= *.*)|i )    { $i_parent_start = $1; }
  if( $wpsdata[$line] =~ m|^( *j_parent_start *= *.*)|i )    { $j_parent_start = $1; }
  if( $wpsdata[$line] =~ m|^( *e_we *= *.*)|i )              { $e_we = $1; }
  if( $wpsdata[$line] =~ m|^( *e_sn *= *.*)|i )              { $e_sn = $1; }
  if( $wpsdata[$line] =~ m|^ *dx *= *([0-9]*)|i )            { $dx = $1; }
  if( $wpsdata[$line] =~ m|^ *dy *= *([0-9]*)|i )            { $dy = $1; }
}
close(WPSFILE);

open (TMPFILE, ">", "namelist.tmp" ) or die( "ERROR: Can't open namelist.tmp");

open (NLFILE, "<", "namelist.input.template") or die "ERROR: Can't open namelist.input.template";
@nldata = <NLFILE>;
for($line = 0; $line <= $#nldata; $line++){
  if( $nldata[$line] =~ m| *&time_control.*$|i )             { &copy_section(); }
  if( $nldata[$line] =~ m| *&physics.*$|i )                  { &copy_section(); }
  if( $nldata[$line] =~ m| *&noah_mp.*$|i )                  { &copy_section(); }
  if( $nldata[$line] =~ m| *&fdda.*$|i )                     { &copy_section(); }
  if( $nldata[$line] =~ m| *&dynamics.*$|i )                 { &copy_section(); }
  if( $nldata[$line] =~ m| *&bdy_control.*$|i )              { &copy_section(); }
  if( $nldata[$line] =~ m| *&grib2.*$|i )                    { &copy_section(); }
  if( $nldata[$line] =~ m| *&namelist_quilt.*$|i )           { &copy_section(); }
  if( $nldata[$line] =~ m| *&domains.*$|i )                  { &do_domain();    }
}
close(NLFILE);
close(TMPFILE);

# Move namelist.tmp back to namelist.input.template
`mv namelist.tmp namelist.input.template`;

# Copy namelist.wps.template to namelist.wps
`cp namelist.wps.template namelist.wps`;

# Update &domains Section
sub do_domain()
{
  our $nldata;
  our $line;

  print TMPFILE "$nldata[$line]";
  for($line++ ; $line <= $#nldata; $line++ ){
    if( $nldata[$line] =~ m| */ *$| ){   # End of Section
      if($line != $#nldata && $nldata[$line+1] =~ m|^[\t ]*$| ){   # Blank line
        print TMPFILE "\n";
        $line++;
      }
      return;
    }
    else{
      if( $nldata[$line] =~ m|^ *e_we[ \t]*= *.*$|i )                   { print TMPFILE "$e_we\n";                                                 next; }
      if( $nldata[$line] =~ m|^ *e_sn[ \t]*= *.*$|i )                   { print TMPFILE "$e_sn\n";                                                 next; }
      if( $nldata[$line] =~ m|^ *i_parent_start[ \t]*= *.*$|i )         { print TMPFILE "$i_parent_start\n";                                       next; }
      if( $nldata[$line] =~ m|^ *j_parent_start[ \t]*= *.*$|i )         { print TMPFILE "$j_parent_start\n";                                       next; }
      if( $nldata[$line] =~ m|^ *parent_grid_ratio[ \t]*= *.*$|i )      { print TMPFILE " parent_grid_ratio      = 1,    $parent_grid_ratio[1]\n"; next; }
      if( $nldata[$line] =~ m|^ *parent_time_step_ratio[ \t]*= *.*$|i ) { print TMPFILE " parent_time_step_ratio = 1,    $parent_grid_ratio[1]\n"; next; }
      if( $nldata[$line] =~ m|^ *max_time_step[ \t]*= *.*$|i )          { $t = ${dx}/100; $t1 = $t / $parent_grid_ratio[1];
                                                                          print TMPFILE " max_time_step          = $t,    $t1,\n";                 next; }
      if( $nldata[$line] =~ m|(^ *dx[ \t]*= *).*$|i )                   { $t = $dx /$parent_grid_ratio[1]; print TMPFILE "${1}${dx},    $t\n";     next; }
      if( $nldata[$line] =~ m|(^ *dy[ \t]*= *).*$|i )                   { $t = $dy /$parent_grid_ratio[1]; print TMPFILE "${1}${dy},    $t\n";     next; }
      print TMPFILE $nldata[$line];  # Copy any line not matching those above.
    }
  }
}



# Copy entire Section
sub copy_section
{
  our @nldata;  # NB Same @nldata as above
  our $line;    # NB Same $line as above

  for( ; $line <= $#nldata; $line++ ){
    print TMPFILE "$nldata[$line]";
    if( $nldata[$line] =~ m| */ *$| ){   # End of Section
      if($line != $#nldata && $nldata[$line+1] =~ m|^[\t ]*$| ){   # Blank line
        print TMPFILE "\n";
        $line++;
      }
      return;
    }
  }
}
