use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use XML::Feed;
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
    s/^\s+|\s+$//g;
    uc ( $_ );
  }
  
  if ( $command eq "RSS" ){
  
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    my $response = $ua->get("https://labka.cz/wiki/feed.php");
  
    if ($response->is_success) {
      my $xml = $response->decoded_content;  # or whatever
     
      my $feed = XML::Feed->parse(\$xml);

      foreach ($feed->entries) {
      
#         my $answerEncoded = $converter->convert ( $answer );
      
        $server->send_message ( $dst, $nick . ": RSS - " . $_->title, 0 );
        #   print $_->content->body, "\n";
      }
     
    } else {
      $server->send_message ( $dst, $nick . ": ERROR - " . $response->status_line, 0 );
    }
  
  }

	$server->send_message ( $dst, $nick . ": " . $answerEncoded, 0 );
}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`');
