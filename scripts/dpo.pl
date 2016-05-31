#!/usr/bin/perl

use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use pQuery;
use URI::Escape;

use vars qw($VERSION %IRSSI);

$VERSION = '0.01';
%IRSSI = (
	authors     => "Petr Vavrin",
	contact     => "pb.pb\@centrum.cz",
	name        => "dpo",
	description => "description",
);

sub on_public {
	my ( $server, $message, $nick, $hostmask, $channel ) = @_;
	my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
	my $isprivate = !defined $channel;
	my $dst = $isprivate ? $nick : $channel;

	return unless $message =~ /^${cp}dpo\s+(.+)\s+--\s+(.+)$/;

	my ( $from, $to ) = ( $1, $2 );

	my @inputParams = ();
	push ( @inputParams, "f=" . &sanitize ( $from ) );
	push ( @inputParams, "t=" . &sanitize ( $to ) );

	my $searchParams = join "&", @inputParams;

	my $jrLink = "http://jizdnirady.idnes.cz/ostrava/spojeni/?af=true&submit=1&" . $searchParams;

	my $jrPage = pQuery ( $jrLink );

	my $warningFrom = $jrPage->find( ".from-box strong.red" )->text() || "";
	my $warningTo   = $jrPage->find( ".to-box strong.red" )->text() || "";

	for ( $warningFrom, $warningTo ){
		s/^\s+|\s+$//g;
	}

	if ( $warningFrom ne "" ){
		$server->send_message ( $dst, $nick . ": Odkud - " . $from . " - !!! " . $warningFrom, 0 );

	} elsif ( $warningTo ne "" ){
		$server->send_message ( $dst, $nick . ": Kam - " . $to . " - !!! " . $warningTo, 0 );

	} else {

	$jrPage->find ( "table.results" )
	    ->each ( sub {
      
		my $result   = pQuery( $_ );
		my $date     = $result->find( ".date" )->text();
		my $responseRow = "";
        
		$result->find( "tr" )->each (
		
			sub { 
			    my $row     = pQuery( $_ );
			    my $station = $row->find( "td:eq(2)" )->text() || ""; 
			    my $in      = $row->find( "td:eq(3)" )->text() || "";
			    my $out     = $row->find( "td:eq(4)" )->text() || "";
			    my $desc    = $row->find( "td:eq(5)" )->text() || "";
			    my $info    = $row->find( "td:last" )->text() || "";
			    my $vehicle = $row->find( "td:last img" )->attr('title') || "";

			    for ( $station, $in, $out, $desc, $info ){
				s/^\s*>\s*$//g;
				s/^\s*|\s*$//g;
			    }

			    if ( $vehicle =~ /esun/ ){
				$vehicle = "";
			    }

			    my $vehicleInfo = $vehicle . " " . $info;
			    $vehicleInfo =~ s/^\s+|\s+$//g;
			    if ( $vehicleInfo ne "" ){
				$vehicleInfo = " [" . $vehicleInfo . "]";
			    }

			    if ( $in eq "" && $out ne "" ){
				$responseRow .= $out . " -> " . $station . $vehicleInfo . " "; 

			    } elsif ( $in ne "" && $out eq "" ){
				$responseRow .= $station . " " . $in . $vehicleInfo . " | ";

			    } elsif ( $in ne "" && $out ne "" ){
				$responseRow .= $station . " " . $in  .  " | " . $out . " -> " . $station . $vehicleInfo . " ";

			    }
			}
		);

		my $answer = $date . " - " . $responseRow;
		$answer =~ s/\s+\|\s+$//g;

		$server->send_message ( $dst, $nick . ": " . $answer, 0 );

	    } );
	}
}

sub sanitize {

  my ( $text ) = @_;
  return &uri_escape ( $text );

}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`'); 
