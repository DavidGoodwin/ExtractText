=head1 NAME

ExtractText - extracts text from documenmts.

=head1 SYNOPSIS

	loadplugin Mail::SpamAssassin::Plugin::ExtractText /usr/local/etc/mail/spamassassin/plugins/ExtractText.pm

	extracttext_mime_magic    yes

	extracttext_external      antiword     {CS:UTF-8} /usr/local/bin/antiword -t -w 0 -m UTF-8.txt -
	extracttext_use           antiword     .doc application/(?:vnd\\.?)?ms-?word.*

	extracttext_module        openxml      Mail::SpamAssassin::Plugin::ExtractText::OpenXML
	extracttext_use           openxml      .docx .dotx .dotm application/(?:vnd\\.?)openxml.*?word.*
	extracttext_use           openxml      .doc .dot application/(?:vnd\\.?)?ms-?word.*

	extracttext_external      unrtf        {CS:UTF-8} {CF:<{\\[:=-.*?-=:\\]}>} /usr/local/bin/unrtf -t ExtractText.tags --nopict
	extracttext_use           unrtf        .doc .rtf application/rtf text/rtf
  
	extracttext_external      odt2txt      {CS:UTF-8} {CF:\\[--\\s+\\S+:\\s.*?--\\]} /usr/local/bin/odt2txt --encoding=UTF-8 ${file}
	extracttext_use           odt2txt      .odt .ott application/.*?opendocument.*text
	extracttext_use           odt2txt      .sdw .stw application/(?:x-)?soffice application/(?:x-)?starwriter

	extracttext_module        dummy        Mail::SpamAssassin::Plugin::ExtractText::Dummy
	extracttext_dummy_test1                one two three
	extracttext_dummy_test2                four five

	header                    DOC_NO_TEXT  X-ExtractText-Flags =~ /(?:antiword|openxml|unrtf|odt2txt)_Notext/
	describe                  DOC_NO_TEXT  Document without text
	score                     DOC_NO_TEXT  0.5

=head1 DESCRIPTION

This module uses external tools or plugins to extract text from message parts,
and then sets the text as the rendered part.

How to extract text from what is completely configuarable, and bases on a
part's MIME type and file name and optionally also the part's content.

=head1 REQUIREMENT

=over

=item *
SpamAssassin

=item *
IO::String;

=item *
Text::ParseWords

=item *
IPC::Run3

=item *
Encode

=item *
Encode::Detect

=back

=head2 Optional

=over

=item *
File::MimeInfo::Magic

=item *
freedesktop mime database

=back

=head1 CONFIGURATION

In the configuration options, \ is used as an escape character. To include an
actual \ (in regexes for example), use \\.

=head2 Options

=over

=item extracttext_log_to_stderr

Makes the plugin write debug and information to STDERR as well as using the
normal SpamAssassin calls.

=item extracttext_log_msgid

Makes the plugin include the Message-ID in debug and information output.

=item extracttext_log_text

Makes the plugin log all extracted text.

=item extracttext_mime_magic

Specifies wether to use File::MimeInfo::Magic to get canonical MIME types, to
try extracting text from parts with erroneous MIME type declarations, and to
set MIME types for new objects when a plugin didn't.

=item extracttext_mime_database

Sepcifies where the freedesktop MIME database is located.

=back

=head2 Tools

=over

=item extracttext_use

Specifies what tool to use for what message parts.

The general syntax is

	extracttext_use  <name>  <specifiers>

=over

=item name

the internal name of a tool.

=item specifiers

File extension and regular expressions for file names and MIME
types. The regular experssions are anchored to beginning and end.

=back

=head3 Examples

	extracttext_use  antiword  .doc application/(?:vnd\\.?)?ms-?word.*
	extracttext_use  openxml   .docx .dotx .dotm application/(?:vnd\\.?)openxml.*?word.*
	extracttext_use  openxml   .doc .dot application/(?:vnd\\.?)?ms-?word.*
	extracttext_use  unrtf     .doc .rtf application/rtf text/rtf

=item extracttext_external

Defines an external tool. The tool must read a document on standard input or
from a file and write text to standard output.

The general syntax is

	extracttext_external <name> [options] <command> [parameters]

=over

=item name

The internal name of this tool.

=item command

The full path to the external command to run.

=item parameters

Parameters for the external command. The string ${file} in a
parameter will be replaced with the file name of a temporary file
containing the document.

=item options

See below

=back

=head3 Examples

	extracttext_external  antiword  {CS:UTF-8} /usr/local/bin/antiword -t -w 0 -m UTF-8.txt -
	extracttext_external  unrtf     {CS:UTF-8} {CF:<{\\[:=-.*?-=:\\]}>} /usr/local/bin/unrtf -t ExtractText.tags --nopict
	extracttext_external  odt2txt   {CS:UTF-8} /usr/local/bin/odt2txt --encoding=UTF-8 ${file}

=item extracttext_module

Defines a plugin module. The module must implement the function Extract.

The general syntax is

	extracttext_module <name> [options] <package> [path]

=over

=item name

The internal name of this tool.

=item package

The full package name of the module.

=item path

The full path to the module. If this is not specified, it will be
searched for in @INC. If the package name defines the module as a sub
module of this module, it will also be searched for in the sub
directory of this module.

=item options

See below

=back

=head3 Example

	extracttext_module  openxml  Mail::SpamAssassin::Plugin::ExtractText::OpenXML

=item options

The general syntax for options to extracttext_external and extracttext_module
is

	{Option:value}

=over

=item CharSet

Character set used for decoding the text. Defaults do 'detect'
for extracttext_external. A setting of <xml> means to get the
character set from an XML header.

=item CommentFilter

A regular expression removing text.

=back

=back

=head2 Metadata

The plugin adds some pseudo headers to the message. These headers are seen by
the bayes system, and can be used in normal SpamAssassin rules.

The headers are also available as template tags as noted below.

=head3 Example

The fictional example headers below are based on a message containing this:

=over

=item 1
A perfectly normal PDF.

=item 2
An OpenXML document with a word document inside.
Neither Office document contains text.

=back

=head3 Headers

=over

=item X-ExtractText-Chars

Tag: _EXTRACTTEXTCHARS_

Contains a count of characters that were extracted.

	X-ExtractText-Chars: 10970

=item X-ExtractText-Words

Tag: _EXTRACTTEXTWORDS_

Contains a count of "words" that were extracted.

	X-ExtractText-Chars: 1599

=item X-ExtractText-Tools

Tag: _EXTRACTTEXTTOOLS_

Contains chains of tools used for extraction.

	X-ExtractText-Tools: pdftohtml openxml_antiword

=item X-ExtractText-Types

Tag: _EXTRACTTEXTTYPES_

Contains chains of MIME types for parts found during extraction.

	X-ExtractText-Types: application/pdf; application/vnd.openxmlformats-officedocument.wordprocessingml.document, application/ms-word

=item X-ExtractText-Extensions

Tag: _EXTRACTTEXTEXTENSIONS_

Contains chains of canonicalized file extensions (not from headers) for parts
found during extraction.

	X-ExtractText-Extensions: pdf docx_doc

=item X-ExtractText-Flags

Tag: _EXTRACTTEXTFLAGS_

Contains notes from the plugin.

	X-ExtractText-Flags: openxml_NoText

=back

=head3 Rules

Example:

	header    PDF_NO_TEXT  X-ExtractText-Flags =~ /pdftohtml_Notext/
	describe  PDF_NO_TEXT  PDF without text
	score     PDF_NO_TEXT  0.25

=head1 PLUGINS

A plugin is a simple module that implements a function called Extract.

I suggest that plugins have package names like this:

	Mail::SpamAssassin::Plugin::ExtractText::*

If the plugin need to be configured, this can be done with the function
Configure.

=head2 Extract

=head3 Call

The Extract function looks like this:

	sub Extract($extracttext,$object)

=over

=item $extracttext

The calling Mail::SpamAssassin::Plugin::ExtractText object.

=item $object

A decoded or extracted document object (see below).

=back

=head3 Return

Extract should return this (any return parameter may be undef):

	($error,$text,\@newobjects)

=over

=item $error

An error message if applicable.

=item $text

The extrated text, if any.

=item \@newobjects

An array reference of objects that should be processed by this plugin.

=back

=head2 Configure

Note: any extractor implementing Configure must be defined before any
configuration lines it is supposed to handle.

The optional Configure function is called when keys of the following format
if encountered in the spamassassin configuration:

	extracttext_<tool>_<key>

If any values are specified, they are split by white space. To avoid this use
quotes (") or escape with "\". To include an actual \, use \\.

=over

=item <tool>

The internal name of an extractor implemented as a module.

=item <key>

A string conforming to SpamAssassin configuration key format.

=back

=head3 Call

The Configure function looks like this:

	sub Configure($extracttext,$key,@values)

=over

=item $extracttext

The calling Mail::SpamAssassin::Plugin::ExtractText object.

=item $key

The (down cased) configuration key.

=item @values

The values following the key (if any).

=back

=head3 Return

Configure should return true if it handled the key and false otherwise.

=head2 Objects

A document object is a hash reference with the following contents.

=over

=item data

The raw data in a scalar reference.

=item file

The data file (this will be deleted).

=item type

MIME Type.

=item name

File name.

=back

Either data or file must be present.

A plugin must be able to handle both data and file.

=cut

package Mail::SpamAssassin::Plugin::ExtractText;

# $Id: ExtractText.pm,v 1.25 2009/07/10 13:58:14 jonas Exp $

use strict;
use base 'Mail::SpamAssassin::Plugin';
use Mail::SpamAssassin::Util ();
use IO::String;
use Text::ParseWords;
use IPC::Run3;
use Encode;
use Encode::Detect;

sub new {
	my ($class,$mailsa) = @_;
	$class = ref($class) || $class;
	my $self = $class->SUPER::new($mailsa);
	bless($self,$class);
	$self->{match} = [];
	$self->{tools} = {};
	$self->{magic} = 0;
	$self->{modul} = {};
	$self->{canon} = {};
	$self->{depth} = 32;
	$self->register_method_priority('post_message_parse',-1);
	return $self;
}

sub _logmsg {
	my $self = shift;
	my $lev = shift;
	my $msg = shift;
	for (my $i=0;$i<@_;$i++) { $_[$i] = '' unless (defined($_[$i])); }
	$msg = $self->{curmid} ? sprintf("extracttext: %s $msg",$self->{curmid},@_) : sprintf("extracttext: $msg",@_);
	print STDERR "[$lev] $msg\n" if ($self->{stderr});
	return $msg;
}

sub dbg {
	my $self = shift;
	Mail::SpamAssassin::Plugin::dbg($self->_logmsg('dbg',@_));
}

sub info {
	my $self = shift;
	Mail::SpamAssassin::Plugin::info($self->_logmsg('inf',@_));
}

sub isch {
	my $self = shift;
	warn($self->_logmsg('err',@_));
}


sub parse_config {
	my ($self,$pars) = @_;
	return 0 if ($pars->{user_config});
	return 0 unless ($pars->{key} =~ /^extracttext_(.+)$/i);
	my $key = lc($1);
	my @val = shellwords($pars->{value});
	if ($key eq 'use') {
		my $tool = lc(shift @val);
		return 0 unless ($tool && @val);
		while (@val) {
			my $what = shift @val;
			if ($what ne '') {
				my $where;
				if ($what =~ /.+\/.+/) {
					$where = 'type';
				} else {
					$where = 'name';
					$what = ".*\\$what"  if ($what =~ /^\.[a-zA-Z0-9]+$/);
				}
				push @{$self->{match}}, {where=>$where,what=>$what,tool=>$tool};
				$self->dbg('use: %s %s %s',$tool,$where,$what);
			}
		}
	} elsif ($key =~ /^external|module$/) {
		my $name = lc(shift @val);
		return 0 unless ($name && @val);
		if ($self->{tools}->{$name}) {
			$self->isch('Tool exists: %s',$name);
			return 0;
		}
		my $tool = {name=>$name,type=>$key};
		while (@val && $val[0] =~ /^\{(.*?)\}$/) {
			my $cmd = $1;
			my $val = 1;
			if ($cmd =~ /^(.*?):(.*)$/) {
				$cmd = $1;
				$val = $2;
			}
			if ($cmd =~ /^C(?:har)?S(?:et)?$/i) {
				$tool->{charset} = $val;
			} elsif ($cmd =~ /^C(?:omment)?F(?:ilter)?$/i) {
				$tool->{comrexp} = [] unless ($tool->{comrexp});
				push @{$tool->{comrexp}}, $val;
			} else {
				$self->isch('Bad tool config: %s %s',$tool->{name},$cmd);
				return 0;
			}
			shift @val;
		}
		return 0 unless (@val);
		$tool->{spec} = \@val;
		if ($tool->{type} eq 'external') {
			unless (-x $tool->{spec}->[0]) {
				$self->isch('Missing tool: %s %s',$tool->{name},$tool->{spec}->[0]);
				return 0;
			}
			$tool->{charset} = 'detect' unless ($tool->{charset});
		} elsif ($tool->{type} eq 'module') {
			my $package = $tool->{spec}->[0];
			my $path = $tool->{spec}->[1];
			unless ($package) {
				$self->isch('Bad module: %s',$tool->{name});
				return 0;
			}
			unless (defined($self->{modul}->{$package})) {
				unless ($path) {
					$self->{modul}->{$package} = eval("require $package;");
					unless ($self->{modul}->{$package} || substr($package,0,length(__PACKAGE__)+2) ne __PACKAGE__.'::') {
						$path = __FILE__;
						$path =~ s/\.pm$//;
						$path .= substr($package,length(__PACKAGE__),length($package)).'.pm';
						$path =~ s/::/\//g;
					}
				}
				if ($path) {
					$self->{modul}->{$package} = eval{ require $path; };
					$self->isch('Error loading module: %s %s %s',$package,$path,$@) unless ($self->{modul}->{$package});
				} else {
					$self->isch('Error loading module: %s %s',$package,$@) unless ($self->{modul}->{$package});
				}
			}
			return 0 unless ($self->{modul}->{$package});
		} else {
			return 0;
		}
		$self->{tools}->{$name} = $tool;
		$self->dbg('%s: %s "%s"',$key,$name,join('","',@{$tool->{spec}}));
	} elsif ($key =~ /^
			(?:use_?)?(?:mime_?)?(magic)		|
			(?:log_?(?:to_?)?)?(stderr)		|
			log_?(msgid)				|
			log_?(text)
			$/x) {
		$key = $+;
		if (!@val) {
			$self->{$key} = 1;
		} elsif ($val[0] =~ /^no?|f(?:alse)?|off?|[-+]?0+$/i) {
			$self->{$key} = 0;
		} elsif ($val[0] =~ /^y(?:es)?|t(?:rue)?|on|[-+]\d+$/i) {
			$self->{$key} = 1;
		}
		$self->dbg('set: %s=%s',$key,$self->{$key});
	} elsif (@val && $key =~ /^
			(mime)(?:_?dir|(?:_?data)?(?:_?base)?|(?:_?db)?)?
			$/x) {
		$key = $+;
		$self->{$key} = $val[0];
		$self->dbg('set: %s=%s',$key,$self->{$key});
	} elsif (@val && $val[0] =~ /^\d+$/ && $key =~ /^
			(?:max_?)?(depth)
			$/x) {
		$key = $+;
		$self->{$key} = $val[0];
		$self->dbg('set: %s=%u',$key,$self->{$key});
	} elsif ($key =~ /^([^_]+)_(.+)$/) {
		my $name = $1;
		$key = $2;
		return 0 unless ($self->{tools}->{$name});
		return 0 unless ($self->{tools}->{$name}->{type} eq 'module');
		return 0 unless (@{$self->{tools}->{$name}->{spec}});
		my $package = $self->{tools}->{$name}->{spec}->[0];
		my $eval = sprintf('$ok=(%s->can("Configure") && %s::Configure($self,$key,@val));',$package,$package);
		$self->dbg('Module eval: %s %s',$name,$eval);
		my $ok = 0;
		eval($eval);
		$self->isch("Module configure eval error: %s ? %s",$package,$@) if ($@);
		return 0 unless ($ok);
	} else {
		return 0;
	}
	$self->inhibit_further_callbacks();
	return 1;
}

sub _read_mime {
	my ($self) = @_;
	return 0 unless ($self->{mime});
	$self->dbg('MIME database: %s',$self->{mime});
	my %types = ();
	my $cc = 0;
	my $fh = undef;
	if (opendir($fh,$self->{mime})) {
		my @bases = ();
		while (my $d = readdir($fh)) {
			push @bases, $d unless ($fh =~ /^\.+$/);
		}
		closedir($fh);
		foreach my $base (@bases) {
			$fh = undef;
			next unless (opendir($fh,$self->{mime}.'/'.$base));
			while (my $f = readdir($fh)) {
				next unless ($f =~ /^(.+?)\.xml$/i);
				my $type = lc("$base/$1");
				next unless ($type && $type !~ /^\s+$/);
				my $tryp = $type;
				$tryp =~ s/[^\/a-z0-9]+//g;
				$types{$type} = 1;
				next if ($self->{canon}->{$tryp});
				$self->{canon}->{$tryp} = $type;
				$cc ++;
			}
			closedir($fh);
		}
	}
	$fh = undef;
	if (open($fh,'<',$self->{mime}.'/globs2')) {
		while (my $l = <$fh>) {
			next if ($l =~ /^\s*#/);
			$l =~ s/[\r\n]+//gs;
			next unless ($l =~ /^\d+:(.+?):/);
			my $type = lc($1);
			next unless ($type && $type !~ /^\s+$/);
			my $tryp = $type;
			$tryp =~ s/[^\/a-z0-9]+//g;
			$types{$type} = 1;
			next if ($self->{canon}->{$tryp});
			$self->{canon}->{$tryp} = $type;
			$cc ++;
		}
		close($fh);
	}
	$fh = undef;
	if (open($fh,'<',$self->{mime}.'/globs')) {
		while (my $l = <$fh>) {
			next if ($l =~ /^\s*#/);
			$l =~ s/[\r\n]+//gs;
			next unless ($l =~ /^(.+?):/);
			my $type = lc($1);
			next unless ($type && $type !~ /^\s+$/);
			my $tryp = $type;
			$tryp =~ s/[^\/a-z0-9]+//g;
			$types{$type} = 1;
			next if ($self->{canon}->{$tryp});
			$self->{canon}->{$tryp} = $type;
			$cc ++;
		}
		close($fh);
	}
	$fh = undef;
	if (open($fh,'<',$self->{mime}.'/subclasses')) {
		while (my $l = <$fh>) {
			next if ($l =~ /^\s*#/);
			$l =~ s/[\r\n]+//gs;
			foreach my $type (split(/\s+/,lc($l))) {
				next unless ($type && $type !~ /^\s+$/);
				my $tryp = $type;
				$tryp =~ s/[^\/a-z0-9]+//g;
				next if ($self->{canon}->{$tryp});
				$self->{canon}->{$tryp} = $type;
				$cc ++;
			}
		}
		close($fh);
	}
	$fh = undef;
	if (open($fh,'<',$self->{mime}.'/aliases')) {
		while (my $l = <$fh>) {
			next if ($l =~ /^\s*#/);
			$l =~ s/[\r\n]+//gs;
			my @alst = split(/\s+/,lc($l));
			pop @alst while (@alst && $alst[$#alst] =~ /^\s*$/);
			shift @alst while (@alst && $alst[0] =~ /^\s*$/);
			next unless (@alst);
			my $typt = '';
			foreach my $type (@alst) {
				next unless ($type && $type !~ /^\s+$/);
				next unless ($types{$type});
				$typt = $type;
				last;
			}
			$typt = $alst[$#alst] ;
			foreach my $type (@alst) {
				next unless ($type && $type !~ /^\s+$/);
				my $tryp = $type;
				$tryp =~ s/[^\/a-z0-9]+//g;
				next if ($self->{canon}->{$tryp});
				$self->{canon}->{$tryp} = $typt;
				$cc ++;
			}
		}
		close($fh);
	}
	return $cc;
}

sub finish_parsing_end {
	my ($self,$pars) = @_;
	if ($self->{magic}) {
		eval{ use File::MimeInfo::Magic (); };
		$self->{magic} = $@ ? 0 : 1;
		$self->{magic} = File::MimeInfo::Magic->new() if ($self->{magic});
	}
	unless ($self->{mime}) {
		foreach my $bd (('/usr/local/share','/usr/share')) {
			next unless ((-d $bd) && ((-f "$bd/mime/globs") || (-f "$bd/mime/globs2") || (-f "$bd/mime/aliases")));
			$self->{mime} = "$bd/mime";
			last;
		}
	}
	$self->_read_mime;
	#foreach my $tool (values %{$self->{tools}}) {
	#	next if bad
	#	$tool->{ok} = 1;
	#}
	#foreach my $tool (keys %{$self->{tools}}) {
	#	delete $self->{tools}->{$tool} unless ($self->{tools}->{$tool}->{ok});
	#}
}

sub _get_canon {
	my ($self,$type) = @_;
	return $type unless ($type);
	my $tryp = $type;
	$tryp =~ s/[^\/a-z0-9]+//g;
	return $self->{canon}->{$tryp} if ($self->{canon}->{$tryp});
	return $self->{magic}->mimetype_canon($type) if ($self->{magic});
	return $type;
}

sub _get_magic {
	my ($self,$data) = @_;
	return undef unless ($data && $$data && $self->{magic});
	my $dath = IO::String->new($data);
	my $magt = $self->{magic}->magic($dath);
	$dath->close();
	return $magt;
}

sub _tmpfile {
	my ($object,$tmp,$err) = @_;
	unless ($$tmp) {
		if ($object->{file}) {
			$$tmp = $object->{file};
		} else {
			my ($path,$file) = Mail::SpamAssassin::Util::secure_tmpfile();
			if ($path && $file) {
				$$tmp = $path;
				print $file ${$object->{data}};
				$$err = 2 unless (close($file));
			} else {
				$$err = 1;
			}
			$$tmp = '#' if ($$err);
		}
	}
	return $$tmp;
}


sub trick_taint {
    my $match = $_[0] =~ /^(.*)$/s;
    return $1;
}


sub _extract_external {
	my ($self,$object,$tool) = @_;
	my $ok = 0;
	my ($extracted,$error);
	my @cmd = @{$tool->{spec}};
	my $tmp;
	my $err = 0;
         my @clean_cmd;

	for (my $i=0;$i<@cmd;$i++) {
	     $cmd[$i] =~ s/\$\{f(?:ile)?\}/_tmpfile($object,\$tmp,\$err)/gei;
              $self->dbg('%s', $cmd[$i]);
              $clean_cmd[$i] = trick_taint($cmd[$i]);
	     if ($err) {
		$self->isch('Temp file error!');
		return 0;
	    }
	}

        my $sin;
	if ($tmp) {
		my $es = '';
		$sin = \$es;
	} else {
            die('configuration issue (prehaps ${file} is missing?)');
	}

	$self->dbg('External call: %s "%s"',$tool->{name},join('","',@cmd));
	eval { $ok = run3(\@clean_cmd, undef,\$extracted,\$error); }; warn $@ if $@;
	my $ret = $?;
	if ($ret || !$ok || $error) {
		$error = '?' unless ($error);
		$error =~ s/^[\s\r\n]+//s;
		$error =~ s/[\s\r\n]+$//s;
		$error =~ s/[\r\n]+/; /gs;
		$error =~ s/\s+/ /g;
		$self->info('External extraction command: "%s"',join('","',@cmd));
		$self->info('External extraction object: %s %s "%s"',$object->{data}?length($object->{data}):'-',$object->{type},$object->{name});
		$self->info('External extraction error: %s %u %s',$tool->{name},$ret,$error);
	}
	unlink($tmp) if ($tmp && !$object->{file});
	return 0 if ($ret || !$ok || ($error && !$extracted));
	return (1,$extracted);
}

sub _extract_module {
	my ($self,$object,$tool) = @_;
	my $package = $tool->{spec}->[0];
	return 0 unless ($self->{modul}->{$package});
	my ($extracted,$error,$newobjects);
	my $eval = sprintf('($error,$extracted,$newobjects)=%s::Extract($self,$object);',$package);
	$self->dbg('Module eval: %s %s',$tool->{name},$eval);
	eval($eval);
	my $ret = $@;
	$self->info("Module extraction eval error: %s ? %s",$package,$@) if ($ret);
	$self->info('Module extraction object: %s %s "%s"',$object->{data}?length($object->{data}):'-',$object->{type},$object->{name}) if ($ret || $error);
	$self->info("Module extraction error: %s %s ? %s",$tool->{name},$package,$error) if ($error);
	return 0 if ($ret || $error);
	return (1,$extracted,$newobjects);
}

sub _extract_object {
	my ($self,$object,$tool) = @_;
	my ($ok,$extracted,$objects);
	if ($tool->{type} eq 'external') {
		($ok,$extracted,$objects) = $self->_extract_external($object,$tool);
	} elsif ($tool->{type} eq 'module') {
		($ok,$extracted,$objects) = $self->_extract_module($object,$tool);
	} else {
		$self->isch('Bad tool type:',$tool->{type});
		return 0;
	}
	return 0 unless ($ok);
	if ($tool->{charset}) {
		my $chrs;
		if (lc($tool->{charset}) eq '<xml>') {
			$chrs = ($extracted =~ /<\?xml(?: [^>]*?)*? encoding="([^"]+)"/i) ? $1 : 'detect';
		} else {
			$chrs = $tool->{charset};
		}
		eval{ $extracted=decode($chrs,$extracted); };
		$self->dbg('Decode failed: %s',$@) if ($@);
	}
	if ($tool->{comrexp}) {
		foreach my $comrexp (@{$tool->{comrexp}}) {
			$extracted =~ s#$comrexp##gsi;
		}
	}
	$extracted = '' if ($extracted =~ /^[\s\r\n]*$/s);
	if (defined($extracted) && $extracted ne '') {
		$self->info('Extracted %u chars using %s',length($extracted),$tool->{name});
		foreach my $l (split(/[\r\n]+/,$extracted)) {
			next unless ($l =~ /\S/);
			$self->{text}
				? $self->info('Text: %s',encode('ISO-8859-1',$l))
				: $self->dbg('Text: %s',encode('ISO-8859-1',$l));
		}
	} else {
		$self->info('No text extracted');
	}
	return (1,$extracted,$objects);
}

sub _get_type {
	my ($self,$object,$norec) = @_;
	my ($type,$mtype);
	if ($object->{type}) {
		$mtype = $self->_get_canon($object->{type});
		$mtype = $object->{type} unless ($mtype);
		$type = $mtype unless ($mtype eq 'application/octet-stream');
	};
	if (!$type && $self->{magic}) {
		$type = $self->{magic}->globs($object->{name}) if ($object->{name});
		$type = $self->{magic}->globs($object->{file}) if (!$type && $object->{file});
	}
	$type = $mtype if (!$type && $mtype);
	return $type ? ($type) : ();
}
sub _get_extension {
	my ($self,$object) = @_;
	my $fext;
	if ($self->{magic} && $object->{type} && $object->{type} ne 'application/octet-stream') {
		$fext = $self->{magic}->extensions($object->{type});
		$fext =~ s/^\.// if ($fext);
	}
	if (!$fext && $object->{name} && $object->{name} =~ /\.([^.\\\/]+)$/) {
		$fext = $1;
	}
	if (!$fext && $object->{file} && $object->{file} =~ /\.([^.\\\/]+)$/) {
		$fext = $1;
	}
	return $fext ? ($fext) : ();
}

sub _extract {
	my ($self,$coll,$part,$type,$name,$data,$tool) = @_;
	my $object = {
		data	=> $data,
		type	=> $type,
		name	=> $name,
		depth	=> 1,
	};
	my @types = $self->_get_type($object);
	my @fexts = $self->_get_extension($object);
	my @tools = ($tool->{name});
#	$part->{ExtractText_Decoded_Size} = length($$data);
	my ($ok,$extracted,$objects) = $self->_extract_object($object,$tool);
	return 0 unless ($ok);
	my $text = (defined($extracted)) ? $extracted : '';
	while (defined($objects) && @{$objects}) {
		$object = shift @{$objects};
		next if ($object->{depth} >= $self->{depth});
		if ($object->{file} && !$object->{name}) {
			$object->{name} = $object->{file};
			$object->{name} =~ s/^.*[\\\/]//;
		}
		if ($self->{magic}) {
			$object->{type} = $self->{magic}->globs($object->{name}) if (!$object->{type} && $object->{name});
			$object->{type} = $self->_get_magic($object->{data}) if (!$object->{type} && $object->{data});
			$object->{type} = $self->{magic}->magic($object->{file}) if (!$object->{type} && $object->{file});
			if (!$object->{name} && $object->{type}) {
				my $ext = $self->{magic}->extensions($object->{type});
				$object->{name} = 'ExtractTextExtracted'.$ext if ($ext);
			}
		}
		push @types, $self->_get_type($object);
		push @fexts, $self->_get_extension($object);
		if ($object->{type} || $object->{name}) {
			$self->dbg('Object: %s %s',$object->{type},$object->{name});
			my %checked = ();
			foreach my $match (@{$self->{match}}) {
				next unless ($self->{tools}->{$match->{tool}});
				next if ($checked{$match->{tool}});
				if ($match->{where} eq 'name') {
					next unless (defined($object->{name}) && $object->{name} =~ m#^$match->{what}$#i);
					$self->dbg('Match: name "%s" =~ "%s"',$object->{name},$match->{what});
				} elsif ($match->{where} eq 'type') {
					next unless (defined($object->{type}) && $object->{type} =~ m#^$match->{what}$#i);
					$self->dbg('Match: type "%s" =~ "%s"',$object->{type},$match->{what});
				} else {
					next;
				}
				my $moreobjects;
				$checked{$match->{tool}} = 1;
				($ok,$extracted,$moreobjects) = $self->_extract_object($object,$self->{tools}->{$match->{tool}});
				next unless ($ok);
				push @tools, $self->{tools}->{$match->{tool}}->{name};
				$text .= $extracted if (defined($extracted));
				if ($moreobjects) {
					foreach my $mobj (@{$moreobjects}) {
						$mobj->{depth} = $object->{depth} + 1;
					}
					push @{$objects}, @{$moreobjects};
				}
			}
		}
		unlink($object->{file}) if ($object->{file});
	}
	if ($text eq '') {
		push @{$coll->{flags}}, join('_',$tool->{name},'NoText');
	} else {
		$coll->{chars} += length($text);
		$coll->{words} += scalar @{[split(/\W+/s,$text)]} - 1;
		$part->set_rendered($text) ;
	}
#	$part->{ExtractText_Text_Size} = length($text);
	if (@types) {
		push @{$coll->{types}}, join(', ',@types) ;
#		$part->{ExtractText_Types} = [@types];
#		$part->{ExtractText_Type} = $types[0];
	}
	if (@fexts) {
		push @{$coll->{extensions}}, join('_',@fexts) ;
#		$part->{ExtractText_Extensions} = [@fexts];
#		$part->{ExtractText_Extension} = $fexts[0];
	}
	push @{$coll->{tools}}, join('_',@tools) ;
#	$part->{ExtractText_Tools} = [@tools];
#	$part->{ExtractText_Extension} = $tools[0];
	return 1;
}

sub _check_extract {
	my ($self,$coll,$checked,$part,$decoded,$data,$type,$name) = @_;
	return 0 unless (defined($type) || defined($name));
	foreach my $match (@{$self->{match}}) {
		next unless ($self->{tools}->{$match->{tool}});
		next if ($checked->{$match->{tool}});
		if ($match->{where} eq 'name') {
			next unless (defined($name) && $name =~ m#^$match->{what}$#i);
			$self->dbg('Match: name "%s" =~ "%s"',$name,$match->{what});
		} elsif ($match->{where} eq 'type') {
			next unless (defined($type) && $type =~ m#^$match->{what}$#i);
			$self->dbg('Match: type "%s" =~ "%s"',$type,$match->{what});
		} else {
			next;
		}
		unless ($$decoded) {
			$$data = $part->decode();
			$$decoded = 1;
		}
		last unless ($$data);
		$checked->{$match->{tool}} = 1;
		return 1 if ($self->_extract($coll,$part,$type,$name,$data,$self->{tools}->{$match->{tool}}));
	}
	return 0;
}

sub _put_metadata {
	my ($self,$msg,$name,$value) = @_;
	$msg->put_metadata($name,$value);
	$self->dbg('%s: %s',$name,$value);
}

sub post_message_parse {
	my ($self,$pars) = @_;
	my $msg = $pars->{'message'};
	return 0 unless ($msg);
	if ($self->{msgid}) {
		my $cmid = $msg->get_pristine_header('Message-ID');
		$self->{curmid} = $cmid ? $cmid : '-';
		$self->{curmid} =~ s/[\s\r\n]+//s;
	}
	my %collect = (
		tools		=> [],
		types		=> [],
		extensions	=> [],
		flags		=> [],
		chars		=> 0,
		words		=> 0,
	);
	foreach my $part ($msg->find_parts('.*',1,1)) {
		next unless ($part->is_leaf);
		my ($rmt,$rtd) = $part->rendered;
		next if (defined($rtd));
		my %checked = ();
		my $dat = undef;
		my $dec = 0;
		my $typ = $part->{type};
		my $nam = $part->{name};
		$self->dbg('Part: %s %s',$typ,$nam);
		next if ($self->_check_extract(\%collect,\%checked,$part,\$dec,\$dat,$typ,$nam));
		my $mag = $self->_get_canon($typ);
		if ($mag && $mag ne $typ) {
			$self->dbg('Canon: %s',$mag);
			next if ($self->_check_extract(\%collect,\%checked,$part,\$dec,\$dat,$mag));
		}
		$mag = $part->{magic_mime_type};
		if (!$mag && $self->{magic}) {
			unless ($dec) {
				$dat = $part->decode();
				$dec = 1;
			}
			if ($dat) {
				$mag = $self->_get_magic(\$dat);
				$part->{magic_mime_type} = $mag if ($mag);
			}
		}
		if ($mag && $mag ne $typ) {
			$self->dbg('Magic: %s',$mag);
			next if ($self->_check_extract(\%collect,\%checked,$part,\$dec,\$dat,$mag));
		}
		next if ($self->_check_extract($msg,$part,\$dec,\$dat,'',''));
		$self->dbg('Not extracted');
	}
	$self->_put_metadata($msg,'X-ExtractText-Words',$collect{words});
	$self->_put_metadata($msg,'X-ExtractText-Chars',$collect{chars});
	$self->_put_metadata($msg,'X-ExtractText-Tools',join(' ',@{$collect{tools}})) if (@{$collect{tools}});
	$self->_put_metadata($msg,'X-ExtractText-Types',join('; ',@{$collect{types}})) if (@{$collect{types}});
	$self->_put_metadata($msg,'X-ExtractText-Extensions',join(' ',@{$collect{extensions}})) if (@{$collect{extensions}});
	$self->_put_metadata($msg,'X-ExtractText-Flags',join(' ',@{$collect{flags}})) if (@{$collect{flags}});
	return 1;
}

sub parsed_metadata {
	my ($self,$pars) = @_;
	my $pms = $pars->{permsgstatus};
	return 0 unless ($pms);
	my $msg = $pms->get_message;
	return 0 unless ($msg);
	foreach my $tag (('Words','Chars','Tools','Types','Extensions','Flags')) {
		my $v = $msg->get_metadata("X-ExtractText-$tag");
		$pms->set_tag("ExtractText$tag",defined($v)?$v:'');
		#$self->dbg('Tag: %s=%s',"ExtractText$tag",$v);
	}
	return 1;
}

1;

