Simple IRSSI scripts

scripts/csfd.pl
  
    call: `csfd [movie name]
    
    return: list of movies from www.csfd.cz
    
    dependencies: 
      use pQuery;
      use URI::Escape;
      use Text::Iconv;

scripts/dpo.pl

    call: `dpo [from station] -- [to station]
    
    return: list of dpo [bus, tram or trolley bus] links
    
    dependencies:
      use pQuery;
      use URI::Escape;
      use Text::Iconv;
      
scripts/labka.pl

    call: `labka rss
    
    return: rss feeds from https://labka.cz/wiki/feed.php
    
    dependencies:
      install LWP::Protocol::https
      use LWP::UserAgent;
      use XML::Simple;
      use Text::Iconv;
  
  
