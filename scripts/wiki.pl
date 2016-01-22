use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use JSON qw( decode_json );
use Text::Iconv;
use URI::Escape;

use vars qw($VERSION %IRSSI);

$VERSION = '0.01';
%IRSSI = (
	authors     => "Petr Vavrin",
	contact     => "pb.pb\@centrum.cz",
	name        => "Wiki",
	description => "description",
);

sub on_public {
	my ( $server, $message, $nick, $hostmask, $channel ) = @_;
	my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
	my $isprivate = !defined $channel;
	my $dst = $isprivate ? $nick : $channel;

	my $converter = Text::Iconv->new ( "utf-8", "windows-1250" );

	return unless $message =~ /^${cp}wiki\s+(.*)$/;

	my ( $searchTerm ) = ( $1 );
	
	my $ua       = LWP::UserAgent->new ( ssl_opts => { verify_hostname => 0 } );
	my $response = $ua->get ( "https://cs.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch=" . &uri_escape ( $searchTerm ) );

	if ( $response->is_success ) {
		my $jsonString  = $response->decoded_content;

		my $json = decode_json( $jsonString );

		if ( defined ( $json->{ "query" } ) && defined ( $json->{ "query" }->{ "search" } ) ){

	 		my $itemCounter = 0;
			my $itemLimit   = 5;

			$server->send_message ( $dst, $nick . ": WIKI search - " . $searchTerm, 0 );

			foreach my $entry ( @{$json->{ "query" }->{ "search" }} ){

				my $title   = defined ( $entry->{ "title"   } ) ? $entry->{ "title" } : "";
				my $snippet = defined ( $entry->{ "snippet" } ) ? $entry->{ "snippet" } : "";

				my $shortSnippet = $snippet;
				$shortSnippet =~ s/\.\s\s*[A-Z].*$//g;
				$shortSnippet =~ s/<[^>+>]+>//g;

				if ( length ( $shortSnippet ) > 50 ){
					$shortSnippet = substr ( $shortSnippet, 0, 60 ) . " ...";
				}

				if ( $itemCounter < $itemLimit ){
					$server->send_message ( $dst, $nick . ": WIKI - " . $converter->convert ( $title . " - " . $shortSnippet ), 0 );

				}
				$itemCounter++;
			}
		}
	} else {
		$server->send_message ( $dst, $nick . ": WIKI ERROR - " . $response->status_line, 0 );
	}
}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`');
