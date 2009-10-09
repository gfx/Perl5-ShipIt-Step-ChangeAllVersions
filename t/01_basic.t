#!perl -w

use strict;
use Test::More tests => 16;

use constant new_version => '0.001_01';

BEGIN{ # Fake Term::ReadLine, which is hard coded in ShipIt::Util
    package Term::ReadLine;
    sub new{ bless {}, shift }
    sub readline{ ::new_version() };
    $INC{'Term/ReadLine.pm'} = __FILE__;
}

use ShipIt;
use ShipIt::VC;
use ShipIt::Step::ChangeAllVersions;

chdir 't/test' or die "Cannot chdir: $!";

{
    package ShipIt::VC::Dummy;

    sub new { bless {} } # intentinaly one-arg bless
    sub exists_tagged_version{ 0 }

    no warnings 'redefine';
    *ShipIt::VC::new = \&ShipIt::VC::Dummy::new;
}

my $conf  = ShipIt::Conf->parse('.shipit');
my $state = ShipIt::State->new($conf);

close STDOUT;

my $stdout = '';
open STDOUT, '>', \$stdout;

foreach my $step( $conf->steps ){
    ok $step->run($state), $step;

    if($step->isa('ShipIt::Step::ChangeAllVersions')){
        is $step->changed_version_variable->{'Foo.pm'}, 1, 'VERSION variable in Foo.pm';
        is $step->changed_version_variable->{'Bar.pm'}, 1, 'VERSION variable in Bar.pm';

        is $step->changed_version_section->{'Foo.pm'}, 1, 'VERSION section in Foo.pm';
        is $step->changed_version_section->{'Bar.pm'}, 1, 'VERSION section in Bar.pm';
        is $step->changed_version_section->{'Baz.pod'}, 1, 'VERSION section in Baz.pod';
    }
}

like $stdout, qr/^Update \s+ \$VERSION/xms;
like $stdout, qr/^Update \s+ the \s+ VERSION \s+ section/xms;

require './Foo.pm';
require './Bar.pm';

{
    no warnings 'once';

    is $Foo::VERSION, new_version, '$Foo::VERSION has been updated';
    is $Bar::VERSION, new_version, '$Bar::VERSION has been updated';

    isnt $Bar::version, new_version, '$version is not touched';
    isnt $Bar::Version, new_version, '$Version is not touched';
}

# revert chnages for the next test :)

if($ENV{DONT_REMOVE_CHANGED_FILES}){
    rename 'Foo.pm'  => 'Foo.pm.bak';
    rename 'Bar.pm'  => 'Bar.pm.bak';
    rename 'Baz.pod' => 'Baz.pod.bak';
}

ok rename 'Foo.pm~'  => 'Foo.pm';
ok rename 'Bar.pm~'  => 'Bar.pm';
ok rename 'Baz.pod~' => 'Baz.pod';

