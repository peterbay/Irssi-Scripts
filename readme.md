Simple IRSSI scripts

scripts/csfd.pl
  
    call: `csfd [movie name]
    
    return: list of movies from www.csfd.cz
    
    dependencies: 
      use pQuery;
      use URI::Escape;

scripts/jizdni_rady.pl

    Ostrava
      call: `spoj [from station] -- [to station]
    
    other cities
      call: `spoj [city] -- [from station] -- [to station]
    
    return: list of dpo [bus, tram or trolley bus] links

    list if available cities
      pid, praha, idsjmk, odis, idol, zvon, vlaky, vlak, autobusy, autobus, vlakyautobusy, vlakyautobusymhd,
      vlakyautobusymhdvse, vse, letadla, adamov, as, benesov, beroun, bilina, blansko, brandys, brno, bruntal,
      breclav, bystrice, caslav, ceskalipa, ceskebudejovice, ceskytesin, dacice, decin, domazlice, duchcov,
      dvurkralove, frydekmistek, havirov, havlickuvbrod, hodonin, horice, hradeckralove, hranice, cheb, 
      chomutov, chrudim, jablonec, jachymov, jicin, jihlava, jindrichuvhradec, kadan, karlovyvary, karvina,
      kladno, klasterecnadohri, klatovy, kolin, kostelecnadorlici, kralupy, krnov, kromeriz, kutnahora, kyjov,
      liberec, litomerice, litomysl, louny, lovosice, marianskelazne, melnik, milevsko, mladaboleslav, 
      mnisekpodbrdy, most, nachod, neratovice, novemestonamorave, novyjicin, nymburk, olomouc, opava,
      orlova, ostrava, ova, dpo, ostrov, pardubice, pelhrimov, pisek, plzen, policka, praha, prostejov, prelouc,
      prerov, prestice, pribram, rokycany, roudnice, rychnov, slany, sokolov, strakonice, stribro, studenka, 
      spindleruvmlyn, steti, sumperk, tabor, tachov, teplice, trutnov, trebic, trinec, turnov, tynistenadorlici,
      uherskehradiste, ustinadlabem, valasskemezirici, varnsdorf, velkemezirici, vimperk, vlasim, vrchlabi, 
      vsetin, vyskov, zabreh, zlin, znojmo, zamberk, zatec, zdarnadsazavou
    
    dependencies:
      use pQuery;
      use URI::Escape;

scripts/labka.pl

    call: `labka rss
    
    return: rss feeds from https://labka.cz/wiki/feed.php
    
    dependencies:
      install LWP::Protocol::https
      use LWP::UserAgent;
      use XML::Simple;

scripts/wiki.pl

    call: `wiki [search string]
    
    return: list of results from https://cs.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch=[search string]
    
    dependencies:
      install LWP::Protocol::https
      use LWP::UserAgent;
      use JSON qw( decode_json );
      use URI::Escape;

scripts/utf8.pl

    call: text with utf-8 encoding
    
    return: text converted to windows-1250
    
    dependencies:
      use Encode::Guess;
      use Text::Iconv;
