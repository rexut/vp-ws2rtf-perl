#!/usr/bin/perl
# V.Pohlers created 23.03.2010
# kleiner CP/M-Wordstar-Konverter
# 03.08.2010 sup, super, header, footer

#$ARGV[0] ||= 'd:\dvd109\hobby\cpm\mumath\doc\MY6.TXT';	# Testdatei f. Entwicklung
#$ARGV[1] ||= 1;

die <<HELP unless @ARGV;
Aufruf: ws2rtf.pl datei.ws [/d]
konvertiert Wordstar-Text-Dateien ins RTF-Format
ein optionaler 2. Parameter ersetzt die Zeichen [\\]{|}~ durch Umlaute ÄÖÜäöüß
HELP

#Dateiendung für Ausgabedatei
($OUT = $ARGV[0]) =~ s/\..*/.rtf/i;

#2.Paramter für deutsche Umlaute (vorerst bel. Parameter)
$umlaute = $ARGV[1]?1:0;

open IN, "<$ARGV[0]";
binmode(IN);

# Datei komplett einlesen
undef $/;
$file_content = <IN>; 
close IN;

# generell 7. Bit zurücksetzen
$file_content = pack "C*", map {$_ & 127} unpack "C*", $file_content;
@in=split /\x0d\x0a/, $file_content;

open OUT, ">$OUT";
#binmode OUT;
print "Schreibe $OUT ..";

print OUT '{\rtf1\ansi\ansicpg1252\deff0\deflang1031{\fonttbl{\f0\fmodern\fprq1\fcharset0 Courier New;}}';
print OUT '\viewkind4\uc1\pard\f0\fs20\ltrch ',"\n"; #f0 = Font, fs20 = Schriftgröße 1ß

# Standart unter CP/M ist:
# Ausgelegt für 12 Zoll Blattlänge (ca. A4 hoch)
# 
# Zeilen/Blatt           (.pl)                   72 
# Zeilenabstand abhängig 
#  vom Drucker, meist                            1/6 Zoll
# oberer Rand            (.mt)                   3
# Kopfabstand            (.hm)                   2
# unterer Rand           (.mb)                   8
# Fußabstand             (.fm)                   2
# Druckrandverschiebung  (.po)                   0
# Drucken Seitennummer   (.op)                   ein
# Seitennummern-Spalte   (.pc)                   32 

#while (<IN>) {
foreach (@in) {
	if (/^\.\w/) { dotkdo() }		# dot-Kommando
	else {
		changechars ();
		s/\x0d\x0a/\\par\x0d\x0a/g;
		print OUT $_, "\\par\n";
		last if $last;
	}
}

print OUT '}';
close OUT;

# DOT-Kommandos (n = Zeilen, m = Zeichen bzw. Spalte)    
# .PLn  Setzen Zeilen pro Blatt                          
# .MTn  Setzen oberer Rand                               
# .MBn  Setzen unterer Rand                              
# .HMn  Setzen Kopfabstand                               
# .FMn  Setzen Fußabstand                               
# .PCm  Setzen Seiten-Nr.- Spalte                          
# .PA   Vorschub neue Seite                                
# .CPn  eventüll neue Seite                                
# .HE.. Kopfzeile                                        
# .FO.. Fußzeile                                           
# .OP   Seitennummerdruck aus                               
# .PN   Seitennummerdruck ein                               
# .PNr  Seitennummer setzen                                
# .POm  Verschiebung linker Druckrand                    
# .IGtext Kommentarzeile                                 
# ..text  Kommentarzeile                                 

sub dotkdo {
	if (/^\.pl\s*(\d+)/i) { }				# .pl72		Anz. Zeilen
		# 15 = oberer Rand (.mt) 3
		# +Kopfabstand     (.hm) 2
		# +unterer Rand    (.mb) 8
		# +Fußabstand      (.fm) 2
	elsif (/^\.pa/i)      { print OUT '\page ' }		# .pa		Vorschub neue Seite
	elsif (/^\.mt/i)      { }
	elsif (/^\.mb/i)      { }
	elsif (/^\.hm/i)      { }
	elsif (/^\.fm/i)      { }
	elsif (/^\.he(\s*.*)/i)      { $_=$1; changechars(); s/\#/\\chpgn /; 
					print OUT '{\header\f0\fs20 ', $_, '}' }	# Header
	elsif (/^\.fo(\s*.*)/i)      { $_=$1; changechars(); s/\#/\\chpgn /; 
					print OUT '{\footer\f0\fs20 ', $_, '}' }	# Footer
	else { print "\nunknown dot $_"; 
#		print OUT changechars ($_),"\\par\n" 
	};
}

# s.a. http://www.moon-soft.com/program/FORMAT/text/wordst.htm
sub changechars {
	my $line = $_;
	$conv = '';
	
	#Epson-Steurcodes (Bit7 ist schon weg!)
	$line =~ s/\x1b\x01\x1c/ü/g;	#81 ü
	$line =~ s/\x1b\x04\x1c/ä/g;	#84 ä
	$line =~ s/\x1b\x14\x1c/ö/g;	#84 ö
	$line =~ s/\x1b\x61\x1c/ß/g;	#E1 ß
	$line =~ s/\x1b\x0e\x1c/Ä/g;	#81 Ä
	$line =~ s/\x1b\x1a\x1c/Ü/g;	#81 Ü
	$line =~ s/\x1b\x19\x1c/Ö/g;	#81 Ö
	
	for ($i=0;$i<length($line);$i++) {
		$char = substr($line,$i,1);
		if ($char eq "\x00") {$char = '' }			# fix the print position
			
		elsif ($char eq "\x02") { $bold = ! $bold; 
			$char = ($bold?'\b ':'\b0 '); }			# Fett 
		elsif ($char eq "\x04") { $double = ! $double; 
			$char = ($double?'\b ':'\b0 '); }		# double strike printing on/off toggle
		elsif ($char eq "\x14") { $superscript = ! $superscript; 
			$char = ($superscript?'\super ':'\nosupersub '); }	# superscript on/off toggle
		elsif ($char eq "\x16") { $subscript = ! $subscript; 
			$char = ($subscript?'\sub ':'\nosupersub '); }	# double strike printing on/off toggle
		elsif ($char eq "\x19") { $char = '\page ' }		# neue Seite
		elsif ($char eq "\x1E") { $char = '' }			# inactive soft hyphen 
		elsif ($char eq "\x1F") { $char = '-' }			# active soft hyphen
		elsif ($char eq "\x1A") { $last = 1; last }		# Dateiende
		elsif ($char eq "\x0a") {}
		elsif ($char eq "\x0d") {}
		elsif ($char eq "\x13") {$underline = ! $underline; 
			$char = ($underline?'\ul ':'\ulnone '); }	# underline
		elsif ($char eq "\x08") { $char = '\\expnd-7\\expndtw-200 '.substr($conv, -1).'\\expnd0\\expndtw0 ';
					substr($conv, -1) = '';	}	# overprint previous character
		elsif ($char eq "\x09") {$char = '\tab '}		# tab character
		elsif ($char eq "\x19") { $char = '\page ' }		# neue Seite
		elsif ($char eq "\x0f") { $char = ' ' }			# binding space. printed as a space.

		elsif ($char eq "\x01") { $char = '\charscalex66 ' }		# alternate font
		elsif ($char eq "\x0e") { $char = '\charscalex100 ' }		# return to the normal character width

		elsif (ord($char) < 32) { printf "\nunknown char %d = %xh", ord($char), ord($char) }
				
		# Zeichenersetzung für RTF
		if ($umlaute) {
			#deutsche Umlaute
			#\'c4\'d6\'dc\'e4\'f6\'fc\'df  Ae Oe Ue ae oe ue sz
			if ($char eq '[') {$char = '\\\'c4' }	# Ä
			elsif ($char eq '\\'){$char = '\\\'d6' }	# Ö
			elsif ($char eq ']') {$char = '\\\'dc' }	# Ü
			elsif ($char eq '{') {$char = '\\\'e4' }	# ä
			elsif ($char eq '|') {$char = '\\\'f6' }	# ö
			elsif ($char eq '}') {$char = '\\\'fc' }	# ü
			elsif ($char eq '~') {$char = '\\\'df' }	# ß
		} else {
			#\{ geschweifte Klammer auf
			#\} geschweifte Klammer zu
			if ($char eq '{') {$char = '\\{' }
			elsif ($char eq '}') {$char = '\\}' }
			elsif ($char eq '\\'){$char = '\\\\' }
		}

		$conv .= $char;
	}
	$_ = $conv;
}
