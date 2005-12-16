#!/usr/bin/perl -wT
#
# ==========================================================================
#
# ZoneMinder Panasonic KX-HCM10 Control Script, $Date$, $Revision$
# Copyright (C) 2003, 2004, 2005  Philip Coombes
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# ==========================================================================
#
# This script continuously monitors the recorded events for the given
# monitor and applies any filters which would delete and/or upload 
# matching events
#
use strict;

# ==========================================================================
#
# These are the elements you can edit to suit your installation
#
# ==========================================================================

# None

# ==========================================================================

use ZoneMinder;
use Getopt::Long;
use Device::SerialPort;

use constant LOG_FILE => ZM_PATH_LOGS.'/zmcontrol-kx-hcm10.log';

$| = 1;

$ENV{PATH}  = '/bin:/usr/bin';
$ENV{SHELL} = '/bin/sh' if exists $ENV{SHELL};
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

sub Usage
{
	print( "
Usage: zmcontrol-kx-hcm10.pl <various options>
");
	exit( -1 );
}

my $arg_string = join( " ", @ARGV );

my $address;
my $command;
my ( $speed, $step );
my ( $xcoord, $ycoord );
my ( $width, $height );
my ( $panspeed, $tiltspeed );
my ( $panstep, $tiltstep );
my $preset;

if ( !GetOptions(
	'address=s'=>\$address,
	'command=s'=>\$command,
	'speed=i'=>\$speed,
	'step=i'=>\$step,
	'xcoord=i'=>\$xcoord,
	'ycoord=i'=>\$ycoord,
	'width=i'=>\$width,
	'height=i'=>\$height,
	'panspeed=i'=>\$panspeed,
	'tiltspeed=i'=>\$tiltspeed,
	'panstep=i'=>\$panstep,
	'tiltstep=i'=>\$tiltstep,
	'preset=i'=>\$preset
	)
)
{
	Usage();
}

if ( !$address )
{
	Usage();
}

my $log_file = LOG_FILE;
open( LOG, ">>$log_file" ) or die( "Can't open log file: $!" );
open( STDOUT, ">&LOG" ) || die( "Can't dup stdout: $!" );
select( STDOUT ); $| = 1;
open( STDERR, ">&LOG" ) || die( "Can't dup stderr: $!" );
select( STDERR ); $| = 1;
select( LOG ); $| = 1;

print( $arg_string."\n" );

srand( time() );

sub printMsg
{
	my $msg = shift;
	my $msg_len = length($msg);

	print( $msg );
	print( "[".$msg_len."]\n" );
}

sub sendCmd
{
	my $cmd = shift;

	my $result = undef;

	printMsg( $cmd, "Tx" );

	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;
	$ua->agent( "ZoneMinder Control Agent/".ZM_VERSION );

	#print( "http://$address/$cmd\n" );
	my $req = HTTP::Request->new( GET=>"http://$address/$cmd" );
	my $res = $ua->request($req);

	if ( $res->is_success )
	{
		$result = !undef;
	}
	else
	{
		print( "Error check failed: '".$res->status_line()."'\n" );
	}

	return( $result );
}

sub cameraReset
{
	print( "Camera Reset\n" );
	my $cmd = "nphRestart?PAGE=Restart&Restart=OK";
	sendCmd( $cmd );
}

sub moveUp
{
	print( "Move Up\n" );
	my $cmd = "nphControlCamera?Direction=TiltUp";
	sendCmd( $cmd );
}

sub moveDown
{
	print( "Move Down\n" );
	my $cmd = "nphControlCamera?Direction=TiltDown";
	sendCmd( $cmd );
}

sub moveLeft
{
	print( "Move Left\n" );
	my $cmd = "nphControlCamera?Direction=PanLeft";
	sendCmd( $cmd );
}

sub moveRight
{
	print( "Move Right\n" );
	my $cmd = "nphControlCamera?Direction=PanRight";
	sendCmd( $cmd );
}

sub moveMap
{
	my ( $xcoord, $ycoord, $width, $height ) = @_;
	print( "Move Map to $xcoord,$ycoord\n" );
	my $cmd = "nphControlCamera?Direction=Direct&NewPosition.x=$xcoord&NewPosition.y=$ycoord&Width=$width&Height=$height";
	sendCmd( $cmd );
}

sub zoomTele
{
	print( "Zoom Tele\n" );
	my $cmd = "nphControlCamera?Direction=ZoomTele";
	sendCmd( $cmd );
}

sub zoomWide
{
	print( "Zoom Wide\n" );
	my $cmd = "nphControlCamera?Direction=ZoomWide";
	sendCmd( $cmd );
}

sub focusNear
{
	print( "Focus Near\n" );
	my $cmd = "nphControlCamera?Direction=FocusNear";
	sendCmd( $cmd );
}

sub focusFar
{
	print( "Focus Far\n" );
	my $cmd = "nphControlCamera?Direction=FocusFar";
	sendCmd( $cmd );
}

sub focusAuto
{
	print( "Focus Auto\n" );
	my $cmd = "nphControlCamera?Direction=FocusAuto";
	sendCmd( $cmd );
}

sub presetClear
{
	my $preset = shift || 1;
	print( "Clear Preset $preset\n" );
	my $cmd = "nphPresetNameCheck?Data=$preset";
	sendCmd( $cmd );
}

sub presetSet
{
	my $preset = shift || 1;
	print( "Set Preset $preset\n" );
	my $cmd = "nphPresetNameCheck?PresetName=$preset&Data=$preset";
	sendCmd( $cmd );
}

sub presetGoto
{
	my $preset = shift || 1;
	print( "Goto Preset $preset\n" );
	my $cmd = "nphControlCamera?Direction=Preset&PresetOperation=Move&Data=$preset";
	sendCmd( $cmd );
}

sub presetHome
{
	print( "Home Preset\n" );
	my $cmd = "nphControlCamera?Direction=HomePosition";
	sendCmd( $cmd );
}

if ( $command eq "move_con_up" )
{
	moveUp();
}
elsif ( $command eq "move_con_down" )
{
	moveDown();
}
elsif ( $command eq "move_con_left" )
{
	moveLeft();
}
elsif ( $command eq "move_con_right" )
{
	moveRight();
}
elsif ( $command eq "move_map" )
{
	moveMap( $xcoord, $ycoord, $width, $height );
}
elsif ( $command eq "zoom_con_tele" )
{
	zoomTele();
}
elsif ( $command eq "zoom_con_wide" )
{
	zoomWide();
}
elsif ( $command eq "focus_con_near" )
{
	focusNear();
}
elsif ( $command eq "focus_con_far" )
{
	focusFar();
}
elsif ( $command eq "focus_auto" )
{
	focusAuto();
}
elsif ( $command eq "focus_man" )
{
	#focusMan();
}
elsif ( $command eq "preset_home" )
{
	presetHome();
}
elsif ( $command eq "preset_set" )
{
	presetSet( $preset );
}
elsif ( $command eq "preset_goto" )
{
	presetGoto( $preset );
}
else
{
	print( "Error, can't handle command $command\n" );
}