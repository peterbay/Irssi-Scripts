use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use XML::Simple;
use Text::Iconv;

use vars qw($VERSION %IRSSI);

$VERSION = '0.01';
%IRSSI = (
	authors     => "Petr Vavrin",
	contact     => "pb.pb\@centrum.cz",
	name        => "Labka",
	description => "description",
);

sub on_public {
	my ( $server, $message, $nick, $hostmask, $channel ) = @_;
	my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
	my $isprivate = !defined $channel;
	my $dst = $isprivate ? $nick : $channel;

	my $converter = Text::Iconv->new ( "utf-8", "windows-1250" );

	return unless $message =~ /^${cp}labka\s+(.*)$/;

	my ( $command ) = ( $1 );
	
	for ( $command ){
		s/^\s+|\s+$//;
	}
	$command = uc ( $command );

	if ( $command eq "RSS" ){

		my $itemCounter = 0;
		my $itemLimit   = 3;

		my $ua       = LWP::UserAgent->new ( ssl_opts => { verify_hostname => 0 } );
		my $response = $ua->get ( "https://labka.cz/wiki/feed.php" );

		if ( $response->is_success ) {
			my $xmlString  = $response->decoded_content;
			my $xmlSimple  = XML::Simple->new( );
			my $xmlData    = $xmlSimple->XMLin( $xmlString );

			if ( defined ( $xmlData->{ "channel" } ) ){
				my $channelTitle = defined ( $xmlData->{ "channel" }->{ "title" } ) ? $xmlData->{ "channel" }->{ "title" } : "";
				$server->send_message ( $dst, $nick . ": RSS Channel - " . $converter->convert ( $channelTitle ), 0 );

			}

			if ( defined ( $xmlData->{ "item" } ) ){

				 foreach my $item ( @{$xmlData->{ "item" }} ){

					my $itemTitle = defined ( $item->{ "title" } ) ? $item->{ "title" } : "";
					my $itemDate  = defined ( $item->{ "dc:date" } ) ? $item->{ "dc:date" } : "";

					for ( $itemDate ){
						s/\+.*$//g;
						s/T/ /g;
					}

					if ( $itemCounter < $itemLimit ){
						$server->send_message ( $dst, $nick . ": RSS - " . $converter->convert ( $itemDate . " - " . $itemTitle ), 0 );
					}

					$itemCounter++;

				}
			}
		} else {
			$server->send_message ( $dst, $nick . ": ERROR - " . $response->status_line, 0 );
		}
	}
}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`');
