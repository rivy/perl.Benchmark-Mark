#(emacs/sublime) -*- mode: perl; tab-width: 4; coding: dos; -*-
use strict;
use warnings;

my $output_filename = shift;
use Module::Build;

my $mb = Module::Build->current()->expand_template( $output_filename, [ <DATA> ] );

__END__
# #{{$module_name}}#-#{{$VERSION}}#

[![Build Status](https://travis-ci.org/rivy/perl.#{{$dist_name_dashed}}#.svg?branch=#{{$branch}}#)](https://travis-ci.org/rivy/#{{$dist_name_dashed}}#)

