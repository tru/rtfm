#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';
use RT::FM::Test tests => 21;
$RT::Test::SKIP_REQUEST_WORK_AROUND = 1;

use RT;
my $logo;
BEGIN {
    $logo =
      -e $RT::MasonComponentRoot . '/NoAuth/images/bpslogo.png'
      ? 'bpslogo.png'
      : 'bplogo.gif';
}

use constant ImageFile => $RT::MasonComponentRoot . "/NoAuth/images/$logo";

use constant ImageFileContent => do {
    local $/;
    open my $fh, '<', ImageFile or die ImageFile.$!;
    binmode($fh);
    scalar <$fh>;
};

use RT::FM::Class;
my $class = RT::FM::Class->new($RT::SystemUser);
my ($ret, $msg) = $class->Create('Name' => 'tlaTestClass-'.$$,
			      'Description' => 'A general-purpose test class');
ok($ret, "Test class created");


my ($url, $m) = RT::Test->started_ok;
isa_ok($m, 'Test::WWW::Mechanize');
ok($m->login, 'logged in');
$m->follow_link_ok( { text => 'Configuration' } );
$m->title_is(q/RT Administration/, 'admin screen');
$m->follow_link_ok( { text => 'Custom Fields' } );
$m->title_is(q/Select a Custom Field/, 'admin-cf screen');
$m->follow_link_ok( { text => 'Create' } );
$m->submit_form(
    form_name => "ModifyCustomField",
    fields => {
        TypeComposite => 'Image-0',
        LookupType => 'RT::FM::Class-RT::FM::Article',
        Name => 'img'.$$,
        Description => 'img',
    },
);
$m->title_is(qq/Created CustomField img$$/, 'admin-cf created');
$m->follow_link( text => 'Applies to' );
$m->title_is(qq/Modify associated objects for img$$/, 'pick cf screenadmin screen');
$m->form_number(3);

my $tcf = (grep { /AddCustomField-/ } map { $_->name } $m->current_form->inputs )[0];
$m->tick( $tcf, 0 );         # Associate the new CF with this queue
$m->click('UpdateObjs');
$m->content_like( qr/Object created/, 'TCF added to the queue' );
$m->follow_link( text => 'RTFM');
$m->follow_link( text => 'Articles');
$m->follow_link( text => 'New Article');

$m->title_is(qq/Create an article in class.../);

$m->follow_link( url_regex => qr/Edit.html\?Class=1/ );
$m->title_is(qq/Create a new article/);

$m->content_like(qr/Upload multiple images/, 'has a upload image field');

$tcf =~ /(\d+)$/ or die "Hey this is impossible dude";
my $upload_field = "Object-RT::FM::Article--CustomField-$1-Upload";

diag("Uploading an image to $upload_field") if $ENV{TEST_VERBOSE};

$m->submit_form(
    form_name => "EditArticle",
    fields => {
        $upload_field => ImageFile,
        Name => 'Image Test '.$$,
        Summary => 'testing img cf creation',
    },
);

$m->content_like(qr/Article \d+ created/, "an article was created succesfully");

my $id = $1 if $m->content =~ /Article (\d+) created/;

$m->title_like(qr/Modify article #$id/, "Editing article $id");

$m->follow_link( text => $logo );
$m->content_is(ImageFileContent, "it links to the uploaded image");
