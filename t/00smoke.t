#!/usr/bin/perl

use Test::More qw(no_plan);

use lib "/opt/rt3/lib";
use RT;
ok(RT::LoadConfig);
ok(RT::Init, "Basic initialization and DB connectivity");

use File::Find;
File::Find::find({wanted => \&wanted}, 'lib');
sub wanted { /^.*\.pm\z/s && $_ !~ /Overlay/ && ok(require $_, "Requiring '$_'"); }

