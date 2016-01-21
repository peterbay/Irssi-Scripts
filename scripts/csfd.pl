use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use pQuery;
use URI::Escape;
use Text::Iconv;

use vars qw($VERSION %IRSSI);

$VERSION = '0.01';
%IRSSI = (
	authors     => "Petr Vavrin",
	contact     => "pb.pb\@centrum.cz",
	name        => "csfd",
	description => "description",
);

sub on_public {
	my ( $server, $message, $nick, $hostmask, $channel ) = @_;
	my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
	my $isprivate = !defined $channel;
	my $dst = $isprivate ? $nick : $channel;

	return unless $message =~ /^${cp}csfd\s+(.*)$/;

	my ( $searchString ) = ( $1 );
	my $answer = "";

	pQuery ( "http://www.csfd.cz/hledat/?q=" . uri_escape ( $searchString ) )
	    ->find ( "#search-films li" )
	    ->each ( sub {
		my $item = pQuery ( $_ );
		my $movieTitle = $item->find ( "h3" )->text;
		my $movieDescr = $item->find ( "p:eq(0)" )->text;
		if ( $movieTitle !~ /^\s*$/ ){
			if ( $answer ne "" ){
			    $answer .= ", ";
			}
			$answer .= $movieTitle . " [" . $movieDescr . "]";
		}
	});

	my $converter = Text::Iconv->new ( "utf-8", "windows-1250" );
	my $answerEncoded = $converter->convert ( $answer );

	$server->send_message ( $dst, $nick . ": " . $answerEncoded, 0 );
}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`');
