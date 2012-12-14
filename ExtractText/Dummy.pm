=head1 NAME

Dummy - Output debug stuff.

=head1 SYNOPSIS

	extracttext_module      dummy  Mail::SpamAssassin::Plugin::ExtractText::Dummy
	extracttext_use         dummy  .test test/test
	extracttext_dummy_test         Testing... One two three.
	
=head1 DESCRIPTION

This is an extractor plugin for Mail::SpamAssassin::Plugin::ExtractText.

It is meant as an example of the structure of such plugins, and does not
actually extract anything.

=cut

package Mail::SpamAssassin::Plugin::ExtractText::Dummy;

# $Id: Dummy.pm,v 1.3 2009/06/30 16:52:07 jonas Exp $

use strict;

my %config = ();

sub Extract {
	my ($exttext,$object) = @_;
	my $key;
	foreach $key (keys %{$object}) {
		$exttext->dbg('Dummy Extract Obj: %s=%s',$key,$object->{$key});
	}
	foreach $key (keys %config) {
		$exttext->dbg('Dummy Extract Cfg: %s=%s',$key,join('|',@{$config{$key}}));
	}
	return "Can't!";
}

sub Configure {
	my ($exttext,$key,@vals) = @_;
	return 0 unless ($key =~ /test/);
	$exttext->dbg('Dummy Configure: %s=%s',$key,join('|',@vals));
	$config{$key} = \@vals;
	return 1;
}

1;
