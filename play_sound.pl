#!/usr/bin/perl
use strict;
#use warnings;
use Win32::Sound;
my $sound=$ARGV[0];
if ($sound eq "login") {
	$sound="res\\login.wav";
}
elsif($sound eq "msg") {
	$sound="res\\ice.wav";
}
Win32::Sound::Play($sound);