#!/usr/bin/perl
#
# wlanscan.pl
# version 0.3
#
# Written by Joey Kelly
# joeykelly.net
#
# copyright 2016
# GPL version 2
#
# I want to get and display a table of available APs.
# I did this on NetBSD once, let's see if I can replicate it on Linux.


use strict;
use warnings;

use 5.010;


my $wifi = shift || die "What is the wifi interface? Pass it as an argument to this script. Example: ./wlanscan.pl wlan0\n";
chomp $wifi;

my $iwlist = '/usr/sbin/iwlist';
my $ifconfig = '/sbin/ifconfig';

# let's bounce the interface first
system "$ifconfig $wifi down";
system "$ifconfig $wifi up";


open my $scanresult, "$iwlist $wifi scan |" or die "couldn't execute $iwlist $wifi";
my $scan = do { local $/; <$scanresult> };

my @cell = split(/Cell/,$scan);
# lose the leading bogus entry
$_ = shift @cell;


# we got the raw scan results, so let's say it all out
# ...but the next step would be to put the data into a hashref so we can manipulate it afterward
foreach my $cell (@cell) {
  my ($mac, $channel, $essid, $encryption, $mode, $signalnumbers, $signalquality, $security) = ('','','','','','','','');
  
  # ought to use the MAC address as a hash key, since it's more likely to be unique than an SSID
  if ( $cell =~ /Address:\ ([A-Z0-9]{2}:[A-Z0-9]{2}:[A-Z0-9]{2}:[A-Z0-9]{2}:[A-Z0-9]{2}:[A-Z0-9]{2})/ ) {
    $mac = $1;
  }
  if ( $cell =~ /Channel:(\d+)/ ) {
    $channel = $1;
  }
  if ( $cell =~ /ESSID:"(\w+)"/i ) {
    $essid = $1;
  }
  $essid = '<hidden>' unless $essid;
  if ( $cell =~ /Encryption\ key:(\w+)/ ) {
    $encryption = $1;
  }
  if ( $cell =~ /Mode:(\w+)/ ) {
    $mode = $1;
  }
  if ( $cell =~ /Signal\ level=(-\d+\ dBm)/ ) {
    $signalnumbers = $1;
  }
  if ( $cell =~ /Quality=(\d+\/\d+)/ ) {
    $signalquality = $1;
  }
  #
  # OK, here's where it gets weird
  unless ( $cell =~ /WPA/ ) {
    $security = 'WEP';
  }
  if ( $cell =~ /IE:\ IEEE\ 802\.11i\/WPA2 Version\ 1/ ) {
    $security = 'WPA2 v1';
  }
  if ( $cell =~ /IE:\ IEEE\ 802\.11i\/WPA2 Version\ 2/ ) {
    $security = 'WPA2 v2';
  }
  if ( $cell =~ /IE:\ WPA\ Version\ 1/ ) {
    if ($security) {
      $security .= ' and WPA1';
    } else {
      $security = 'WPA1';
    }
  }
  # our fall-through
  $security = 'none' unless $encryption eq 'on';

  say "essid: $essid\n";
  say "channel: $channel\n";
  say "MAC: $mac\n";
  say "mode: $mode\n";
  say "encrypted: $encryption\n";
  say "security: $security\n";
  say "signal: $signalnumbers\n";
  say "quality: $signalquality\n";
  say "\n";
}

my $cells = @cell;
say "number of cells seen: $cells\n" if $cells;
  
