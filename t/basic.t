use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::AlternateRoot;

my $app = sub {
    my $env = shift;
    return [ 200, [
        'Content-Length' => 0,
        'X-Path-Info'    => $env->{PATH_INFO},
        'X-Script-Name'  => $env->{SCRIPT_NAME},
    ], [] ];
};

# test the plain app to make sure our assumptions hold
test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/foobar/baz');
    is $res->header('x-path-info'), '/foobar/baz', 'path-info is the request path';
    is $res->header('x-script-name'), '', 'no script name yet';
};

# non-strict wrap
my $app2 = Plack::Middleware::AlternateRoot->new({ root => '/foo' })->wrap($app);
test_psgi $app2, sub {
    my $cb = shift;
    my $res = $cb->(GET '/foo/barbaz');
    is $res->header('x-path-info'), '/barbaz', 'path-info is path without the root';
    is $res->header('x-script-name'), '/foo', 'script-name is the root';

    $res = $cb->(GET '/static/foo/barbaz');
    is $res->header('x-path-info'), '/static/foo/barbaz', 'path_info unchanged';
    is $res->header('x-script-name'), '', 'script_info unchanged';
};

# strict wrap
my $app3 = Plack::Middleware::AlternateRoot->
    new({ root => '/foo', strict => 1 })->wrap($app);

test_psgi $app3, sub {
    my $cb = shift;
    my $res = $cb->(GET '/foo/barbaz');
    is $res->header('x-path-info'), '/barbaz', 'path-info still works';
    is $res->header('x-script-name'), '/foo', 'root still works';

    $res = $cb->(GET '/static/foo/barbaz');
    is $res->code, 500, 'got error';
    like $res->decoded_content,
        qr{could not process the request.*'/static/foo/barbaz'.*'/foo'},
            'error message contained PATH_INFO and root';
};








done_testing;
