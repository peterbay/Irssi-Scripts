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
  name        => "Link Title",
  description => "description",
);

sub on_public {
  my ( $server, $message, $nick, $hostmask, $channel ) = @_;
  my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
  my $isprivate = !defined $channel;
  my $dst = $isprivate ? $nick : $channel; 

  return unless $message =~ /(http(s)?:\/\/\S+)/;
  my $link = $1;

  my $ua = LWP::UserAgent->new ( ssl_opts => { verify_hostname => 0 } );
  $ua->agent('Mozilla/5.0');
  $ua->timeout(3);
  $ua->env_proxy;
  $ua->max_size ( 266144 );

  my $response = $ua->get ( $link );
  if ( $response->is_success ) {
    my $title = "";
    if ( defined ( $response->header ( "title" ) ) && $response->header ( "title" ) !~ /^\s*$/ ){
      $title = $response->header ( "title" );
    } else {
      my $html  = $response->decoded_content;
      $html =~ s/\n/ /g;
      
      if ( $html =~ /<title[^>+]>([^<]+)<\/title>/ ){
        $title = $1;
      } 
    }
    
    $server->send_message ( $dst, $nick . ": LINK TITLE: " . $response->header ( "title" ), 0 );

  } 
}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`');