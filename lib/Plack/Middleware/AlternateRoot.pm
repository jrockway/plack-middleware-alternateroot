package Plack::Middleware::AlternateRoot;
# ABSTRACT: rewrite SCRIPT_NAME and PATH_INFO to set your application's root
use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw(root strict);

our $VERSION;

sub call {
    my($self, $env) = @_;
    die 'need root for AlternateRoot' unless my $root = $self->root;
    if($env->{PATH_INFO} =~ m{^\Q$root\E}){
        $env->{PATH_INFO} =~ s{^\Q$root\E}{};
        $env->{SCRIPT_NAME} = $root;
    }
    else {
        die sprintf(
            "could not process the request, because the PATH_INFO ".
            "('%s') did not include the root ('%s').  ".
            "disable strict mode to allow this request\n",
            $env->{PATH_INFO}, $root,
        ) if $self->strict;
    }
    return $self->app->($env);
}

1;

__END__

=head1 SYNOPSIS

    builder {
        enable 'Plack::Middleware::AlternateRoot', root => '/foo', strict => 1;
        mount '/bar' => $app;
    }

    GET "http://myapp.com/foo/bar" --> response from $app

=head1 DESCRIPTION

Sometimes you are doing URL rewriting that your server might not
understand, perhaps on the frontend proxy.  This allows you to tell
your app where it is rooted, so it will properly generate links.

It works by looking for the root you specify at the front of
PATH_INFO.  If it's found, then it removes that part from PATH_INFO
and puts it in SCRIPT_NAME.  If it's not found, the request is passed
unmodified, unless you pass C<< strict => 1 >>.  Then an exception
will be thrown showing the root and PATH_INFO so you can debug your
setup.

=head1 CONFIGURATION

This is a standard piece of L<Plack::Middleware> and is used like any other.

It takes two arguments:

=head2 root

The root to look for in PATH_INFO.  It should probably contain a
leading slash, unless you are doing something strange.

This argument is mandatory.

=head2 strict

If you set this to a true value, requests without root at the front
will die.  If it's false, the default, then those requests will be
passed to the app unmodified.

This argument is optional and defaults to false.
