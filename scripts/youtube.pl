#!/usr/bin/perl

use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use LWP::UserAgent;

use vars qw($VERSION %IRSSI);

$VERSION = '0.01';
%IRSSI = (
  authors     => "Petr Vavrin",
  contact     => "pb.pb\@centrum.cz",
  name        => "Youtube Title",
  description => "description",
);

sub on_public {
  my ( $server, $message, $nick, $hostmask, $channel ) = @_;
  my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
  my $isprivate = !defined $channel;
  my $dst = $isprivate ? $nick : $channel; 

  return unless $message =~ /(youtube.com|youtu.be).*watch(\S+)/;
  my ( $youtubeServer, $params ) = ( $1, $2 );

  return unless $params =~ /(\?|&)v=([^&]+)/;
  my $videoId = $2;

  my $youtubeLink = "https://youtube.com/watch?v=" . $videoId;

  my $ua = LWP::UserAgent->new ( ssl_opts => { verify_hostname => 0 } );
  $ua->agent('Mozilla/5.0');
  $ua->timeout(3);
  $ua->env_proxy;

  my $response = $ua->get ( $youtubeLink );

  if ( $response->is_success ) {
    my $title = ( $response->header ( "title" ) =~ /^(.*) - YouTube/ ) ? $1 : "";
    $server->send_message ( $dst, $nick . ": YOUTUBE [" . $videoId . "] " . $title, 0 );

  } 
}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`');