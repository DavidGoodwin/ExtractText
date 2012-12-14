package Mail::SpamAssassin::Plugin::ExtractText::OpenXML;

# $Id: OpenXML.pm,v 1.5 2009/06/30 16:39:18 jonas Exp $

use strict;
use Archive::Zip;
use IO::String;
use Encode;
use HTML::Entities;

sub _extract_word {
	my ($exttext,$files) = @_;
	return 'no document' unless ($files->{'word/document.xml'});
	my $charset = ($files->{'word/document.xml'} =~ /<\?xml(?: [^>]*?)*? encoding="([^"]+)"/i) ? $1 : 'detect';
	$files->{'word/document.xml'} = decode($charset,$files->{'word/document.xml'});
	$files->{'word/document.xml'} =~ s/<\/?w:p(?: [^>]*?)?\/?>/\n/gsi;
	$files->{'word/document.xml'} =~ s/<w:pBdr>.*?<\/w:pBdr>/\n/gsi;
	$files->{'word/document.xml'} =~ s/<w:instrText(?: [^>]*)?>.*?<\/w:instrText>/ /gsi;
	$files->{'word/document.xml'} =~ s/<[^>]*>/ /gs;
	$files->{'word/document.xml'} =~ s/\r\n/\n/gs;
	$files->{'word/document.xml'} =~ s/\r/\n/gs;
	$files->{'word/document.xml'} =~ s/\t+/ /g;
	$files->{'word/document.xml'} =~ s/  +/ /g;
	$files->{'word/document.xml'} =~ s/\n +/\n/gs;
	$files->{'word/document.xml'} =~ s/ \n/\n/gs;
	$files->{'word/document.xml'} =~ s/\n\n\n+/\n\n/gs;
	return ('',decode_entities($files->{'word/document.xml'}));
}

sub Extract {
	my ($exttext,$object) = @_;
	if ($object->{file} && !defined($object->{data})) {
		my $fh;
		return 'file error' unless (open($fh,'<',$object->{file}));
		my $fd = join('',<$fh>);
		close($fh);
	}
	return unless ($object->{data});
	my $dat = IO::String->new($object->{data});
	return 'data error' unless ($dat);
	my $zip = Archive::Zip->new();
	return 'zip error' unless ($zip);
	my $r = $zip->readFromFileHandle($dat);
	return "zip data error $r" if ($r);
	my %contents = ();
	my $tsz = 0;
	my $tfc = 0;
	foreach my $file ($zip->members) {
		next unless ($file);
		next unless (my $fn = $file->fileName);
		next unless (defined(my $fc = $file->contents));
		$contents{lc($fn)} = $fc;
		$tsz += length($fc);
		$tfc ++;
	}
	return 'no data' unless (%contents);
	$zip = undef;
	$dat = undef;
	return _extract_word($exttext,\%contents) if (($object->{type} && $object->{type} =~ /word/i) || ($object->{name} && $object->{name} =~ /\.do[tc].?$/i));
	return 'unknown type';
}

1;