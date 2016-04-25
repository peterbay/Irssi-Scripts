#!/usr/bin/perl

use strict;
use warnings;

use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use JSON qw( decode_json );
use POSIX;
use POSIX qw(strftime);     # formatted date and time

# ------------------------------------------------------------------------------
# --- token for getting account state -------------------------------------------
# ------------------------------------------------------------------------------
my $fioToken  = ''; # !!! TOKEN MUST BE INSERTED !!!
# ------------------------------------------------------------------------------
my $fioFormat = 'json'; # !!! DON'T CHANGE THIS VALUE !!!

# ------------------------------------------------------------------------------
# --- IRSSI PART 
# ------------------------------------------------------------------------------

use vars qw($VERSION %IRSSI);

$VERSION = '0.01';
%IRSSI = (
	authors     => "Petr Vavrin",
	contact     => "pb.pb\@centrum.cz",
	name        => "fio bank account info",
	description => "script for reporting about bank account",
);

sub on_public {
	my ( $server, $message, $nick, $hostmask, $channel ) = @_;
	my $cp = Irssi::settings_get_str ( 'bot_cmd_prefix' );
	my $isprivate = !defined $channel;
	my $dst = $isprivate ? $nick : $channel;

	return unless $message =~ /^${cp}banka$/;

  my $bankInfo = getFioReport ();

  if ( $bankInfo !~ /accountId/ ){
    $server->send_message ( $dst, $nick . ": " . $bankInfo, 0 );

  }
}

sub sanitize {

  my ( $text ) = @_;
  return &uri_escape ( $text );

}

Irssi::signal_add('message public', 'on_public');
Irssi::signal_add('message private', 'on_public');

Irssi::settings_add_str('bot', 'bot_cmd_prefix', '`'); 

# ------------------------------------------------------------------------------
# --- internal functions
# ------------------------------------------------------------------------------

sub getFioReport {

  my $report = '';

  my $nowDate     = strftime ( '%Y-%m-%d', localtime() );
  my $pastDate    = strftime ( '%Y-%m-%d', localtime( time - 2592000 ) ); # now - 30 days
  my $periodsLink = getFioLink ( "PERIODS", ( "datum od" => $pastDate, "datum do" => $nowDate ) );
  my $ua          = LWP::UserAgent->new ( ssl_opts => { verify_hostname => 0 } );
  my $response    = $ua->get ( $periodsLink );

  if ( $response->is_success ) {
  
  	my $jsonString       = $response->decoded_content;
    my $json             = decode_json            ( $jsonString );
    my $trData           = extractTransactionData ( $json       );
    my $accountInfo      = accountInfo            ( $trData     );
    my $transactionsInfo = stringifyTransactions  ( $trData     );
  
    $report = $accountInfo . " TRANSACTIONS: " . $transactionsInfo;
  
    return $report;
  
  }
}

sub accountInfo {

  my ( $trData ) = @_;

  # available keys -> idLastDownload, bic, accountId, bankId, idList, closingBalance, dateEnd, dateStart, currency, idFrom, yearList, iban, idTo, openingBalance
  my $accountTemplate = '[account: {accountId} / {bankId}, {dateStart} -> {openingBalance} {currency}, {dateEnd} -> {closingBalance} {currency}]';

  if ( defined ( $trData->{ 'info' } ) && defined ( $trData->{ 'info' }->{ 'dateStart' } ) && defined ( $trData->{ 'info' }->{ 'dateEnd' } ) ){
    
    $trData->{ 'info' }->{ 'dateStart' } = reformatDate ( $trData->{ 'info' }->{ 'dateStart' } );
    $trData->{ 'info' }->{ 'dateEnd'   } = reformatDate ( $trData->{ 'info' }->{ 'dateEnd'   } );
    
    foreach my $key ( keys %{$trData->{ 'info' }} ){
      my $value = $trData->{ 'info' }->{ $key };  
      $accountTemplate =~ s/\{$key\}/$value/g;
    }
  }
  return $accountTemplate;
}

sub stringifyTransactions {

  my ( $trData ) = @_;
  
  # available keys -> idTransfer, bankName, vs, ks, idUser, message, type, date, counterName, amount, currency, bankCode, idInstruction, counter, comment
  
  my $transactionTemplate  = '{date} -> {amount} {currency} {counterName}';
  my $transactionDelimiter = ' | ';
  my $transactionList      = '';
  
  if ( defined ( $trData->{ 'transactions' } ) ){
  
    foreach my $tr ( @{$trData->{ 'transactions' }} ){
      $tr->{ 'date' } = reformatDate ( $tr->{ 'date' } );
    
      if ( ! defined ( $tr->{ 'counterName' } ) ){
        $tr->{ 'counterName' } = $tr->{ 'counter' } . '/' . $tr->{ 'bankCode' };
      }
    
      my $entry = $transactionTemplate;
      
      foreach my $key ( keys %{$tr} ){
        my $value = $tr->{ $key };  
        $entry =~ s/\{$key\}/$value/g;
      }
      
      $transactionList .= ( $transactionList eq '' ) ? $entry : $transactionDelimiter . $entry;
    }
  }
  return $transactionList;
}


sub extractTransactionData {

  my $json = shift @_;

  my $transactionData; 

  if ( defined ( $json->{ 'accountStatement' } ) ){
  
    if ( defined ( $json->{ 'accountStatement' }->{ 'info' } ) ){
      $transactionData->{ 'info' } = $json->{ 'accountStatement' }->{ 'info' };
    } 
  
    if ( defined ( $json->{ 'accountStatement' }->{ 'transactionList' } ) && defined ( $json->{ 'accountStatement' }->{ 'transactionList' }->{ 'transaction' } ) ){

      my $transaction = $json->{ 'accountStatement' }->{ 'transactionList' }->{ 'transaction' };
      
      if ( ref $transaction eq 'ARRAY' ){

        my $transactionId = 0;

        foreach my $trans ( @{$transaction} ){

          foreach my $columns ( keys %{$trans} ) {
        
            if ( $columns =~ /^column/ && defined ( $trans->{ $columns }->{ 'name' } ) && defined ( $trans->{ $columns }->{ 'value' } ) ){
              my $columnName      = $trans->{ $columns }->{ 'name' };
              my $columnShortName = columnShortName ( $columnName );
                
              $transactionData->{ 'transactions' }[ $transactionId ]->{ $columnShortName } = $trans->{ $columns }->{ 'value' };
            }
          }
          $transactionId++;
        }
      }
    }
  }
  return $transactionData;
}


sub columnShortName {

  my ( $columnName ) = @_;
  
  if ( $columnName =~ /ID pohybu/                ) { return 'idTransfer'; }
  if ( $columnName =~ /Datum/                    ) { return 'date'; }
  if ( $columnName =~ /Objem/                    ) { return 'amount'; }
  if ( $columnName =~ /M.na/                     ) { return 'currency'; }
  if ( $columnName =~ /Proti..et/                ) { return 'counter'; }
  if ( $columnName =~ /N.zev proti..tu/          ) { return 'counterName'; }
  if ( $columnName =~ /ID pokynu/                ) { return 'idInstruction'; }
  if ( $columnName =~ /U.ivatelsk. identifikace/ ) { return 'idUser'; }
  if ( $columnName =~ /Koment../                 ) { return 'comment'; }
  if ( $columnName =~ /K.d banky/                ) { return 'bankCode'; }
  if ( $columnName =~ /Zpr.va pro p..jemce/      ) { return 'message'; }
  if ( $columnName =~ /N.zev banky/              ) { return 'bankName'; }
  if ( $columnName =~ /Typ/                      ) { return 'type'; }
  if ( $columnName =~ /KS/                       ) { return 'ks'; }
  if ( $columnName =~ /VS/                       ) { return 'vs'; }
  
  return $columnName;
  
}

sub getFioLink {

  my ( $type, %params ) = @_; 
  my $fioUrlTemplate;

  for ( $type ){
    s/^\s+|\s+$//g;
    $_ = uc ( $_ );
  }

  if ( $type eq "PERIODS" ) {
    $fioUrlTemplate = 'https://www.fio.cz/ib_api/rest/periods/{token}/{datum od}/{datum do}/transactions.{format}';
  
  } elsif ( $type eq "BY-ID" ) {
    $fioUrlTemplate = 'https://www.fio.cz/ib_api/rest/by-id/{token}/{year}/{id}/transactions.{format}';

  } elsif ( $type eq "LAST" ) {
    $fioUrlTemplate = 'https://www.fio.cz/ib_api/rest/last/{token}/transactions.{format}';

  } else {
    # -- UNKNOWN TYPE
  
  }

  return makeFioLink ( $fioUrlTemplate, %params );

}

sub makeFioLink {

  my ( $fioUrlTemplate, %params ) = @_;
  my $params;
  
  for ( $fioUrlTemplate ){
    s/\{token\}/$fioToken/g;
    s/\{format\}/$fioFormat/g;
  }

  foreach my $key ( keys %params ){
    my $value = $params{ $key };
    $fioUrlTemplate =~ s/\{$key\}/$value/g;
  
  }
  
  return $fioUrlTemplate;

}

sub reformatDate {

  my ( $date ) = @_;
  
  for ( $date ){
    s/^(\d+-\d+-\d+).*/$1/g;
  }
  
  return $date;
}

