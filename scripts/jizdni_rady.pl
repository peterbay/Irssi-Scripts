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

        my $defaultJr = "ostrava";
        my $inputJr = "";
        my $from = "";
        my $to = "";

        return unless $message =~ /^${cp}spoj/;

        if ( $message =~ /^${cp}spoj\s*(.*)\s*--\s*(.*)\s*--\s*(.*)\s*$/ ){
          ( $inputJr, $from, $to ) = ( $1, $2, $3 );

        } elsif ( $message =~ /^${cp}spoj\s*(.*)\s*--\s*(.*)\s*$/ ){
          $inputJr = $defaultJr;
          ( $from, $to ) = ( $1, $2 );

        }

        for ( $inputJr, $from, $to ){
          s/^\s+|\s+$//g;

        }

        if ( $from =~ // ){
          $server->send_message ( $dst, $nick . ": empty JR", 0 );
          &showHelp( $server, $dst, $nick );
          return;

        }

        if ( $from =~ /^\s*$/ ){
          $server->send_message ( $dst, $nick . ": empty FROM", 0 );
          &showHelp ( $server, $dst, $nick );
          return;

        }

        if ( $to =~ /^\s*$/ ){
          $server->send_message ( $dst, $nick . ": empty TO", 0 );
          &showHelp ( $server, $dst, $nick );
          return;

        }

        my @jrList = ( 
          "pid praha", "idsjmk", "odis", "idol", "zvon", "vlaky vlak", "autobusy autobus", "vlakyautobusy", 
          "vlakyautobusymhd", "vlakyautobusymhdvse vse", "letadla", 
          "adamov", "as", "benesov", "beroun", "bilina", "blansko", "brandys", "brno", 
          "bruntal", "breclav", "bystrice", "caslav", "ceskalipa", "ceskebudejovice", 
          "ceskytesin", "dacice", "decin", "domazlice", "duchcov", "dvurkralove", 
          "frydekmistek", "havirov", "havlickuvbrod", "hodonin", "horice", 
          "hradeckralove", "hranice", "cheb", "chomutov", "chrudim", "jablonec", 
          "jachymov", "jicin", "jihlava", "jindrichuvhradec", "kadan", "karlovyvary", 
          "karvina", "kladno", "klasterecnadohri", "klatovy", "kolin", 
          "kostelecnadorlici", "kralupy", "krnov", "kromeriz", "kutnahora", "kyjov", 
          "liberec", "litomerice", "litomysl", "louny", "lovosice", "marianskelazne", 
          "melnik", "milevsko", "mladaboleslav", "mnisekpodbrdy", "most", "nachod", 
          "neratovice", "novemestonamorave", "novyjicin", "nymburk", "olomouc", "opava",
          "orlova", "ostrava ova dpo", "ostrov", "pardubice", "pelhrimov", "pisek", 
          "plzen", "policka", "praha", "prostejov", "prelouc", "prerov", "prestice", 
          "pribram", "rokycany", "roudnice", "rychnov", "slany", "sokolov", "strakonice", 
          "stribro", "studenka", "spindleruvmlyn", "steti", "sumperk", "tabor", 
          "tachov", "teplice", "trutnov", "trebic", "trinec", "turnov", 
          "tynistenadorlici", "uherskehradiste", "ustinadlabem", "valasskemezirici", 
          "varnsdorf", "velkemezirici", "vimperk", "vlasim", "vrchlabi", "vsetin", 
          "vyskov", "zabreh", "zlin", "znojmo", "zamberk", "zatec", "zdarnadsazavou" );

        my @jrSelected = ();

        JRLOOP: foreach my $jrNames ( @jrList ){
          my @names = split / /, $jrNames;
          foreach my $name ( @names ){
            if ( $name =~ /^${inputJr}$/i  ){
              push ( @jrSelected, $names[0] );
              last JRLOOP;

            } elsif ( $name =~ /${inputJr}/i ){
              push ( @jrSelected, $names[0] );
            }
          }
        }

        my $countSelected = scalar @jrSelected;
        my $jr = "";

        if ( $countSelected == 0 ){
          $server->send_message ( $dst, $nick . ": Unknown timetable name - '" . $inputJr . "'", 0 );

        } elsif ( $countSelected == 1 ){
          $jr = $jrSelected[0];

        } else {
          $server->send_message ( $dst, $nick . ": Please specify timetable name - '" . ( join ", ", @jrSelected ) . "'", 0 );
          return;

        }

	my @inputParams = ();
	push ( @inputParams, "f=" . &sanitize ( $from ) );
	push ( @inputParams, "t=" . &sanitize ( $to ) );

	my $searchParams = join "&", @inputParams;

	my $jrLink = "http://jizdnirady.idnes.cz/" . $jr . "/spojeni/?af=true&submit=1&" . $searchParams;

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

sub showHelp {

  my ( $server, $dst, $nick ) = @_;

  $server->send_message ( $dst, $nick . ": INPUT FORMAT - for selected TIMETABLE - `spoj TIMETABLE -- FROM -- TO", 0 );
  $server->send_message ( $dst, $nick . ": INPUT FORMAT - for OSTRAVA - `spoj FROM -- TO", 0 );

}

sub sanitize {

  my ( $text ) = @_;
  return &uri_escape ( $text );

}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`'); 
