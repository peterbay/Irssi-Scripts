use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use Encode::Guess;
use Text::Iconv;

use vars qw($VERSION %IRSSI);

$VERSION = '0.01';
%IRSSI = (
	authors     => "Petr Vavrin",
	contact     => "pb.pb\@centrum.cz",
	name        => "utf8",
	description => "description",
);

sub on_public {
	my ( $server, $message, $nick, $hostmask, $channel ) = @_;
	my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
	my $isprivate = !defined $channel;
	my $dst = $isprivate ? $nick : $channel;

	my $converter = Text::Iconv->new ( "utf-8", "windows-1250" );

	my $messageEncoding = guess_encoding ( $message, 'utf-8' );

	if ( $messageEncoding =~ /utf8|utf-8/ ){
		$server->send_message ( $dst, $nick . ": UTF8 -  " . $converter->convert ( $message ), 0 );
	}
}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`');
