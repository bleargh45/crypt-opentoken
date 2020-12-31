#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Test::Differences;
use MIME::Base64;
use Crypt::OpenToken;

###############################################################################
# TEST DATA
my @test_data = (
    {   # Generated by PingId PHP Integration Kit
        password_base64 => 'YTY2QzlNdk04ZVk0cUpLeUNYS1crMTlQV0RldWMzdGg=',
        token => 'T1RLAQAwciArHYl0DprhUtzpyOWP_2B-UwAAABR4nEvLz7dNSiziAmIgXQUAK3AFcA**',
        data  => {
            foo => 'bar',
            bar => 'baz',
        },
    },
);

###############################################################################
# How many tests are we running?
eval { require Crypt::NULL; }
    or plan skip_all => 'Crypt::NULL not installed';
plan tests => (scalar @test_data * 2);

###############################################################################
# Decryption; can we parse an OpenToken generated by another implementation?
decryption: {
    foreach my $suite (@test_data) {
        my $token    = $suite->{token};
        my $data     = $suite->{data};
        my $password = decode_base64($suite->{password_base64});

        my $factory   = Crypt::OpenToken->new(password => $password);
        my $decrypted = $factory->parse($token);
        eq_or_diff $decrypted->data(), $data,
            'NULL; decrypt externally generated data';
    }
}

###############################################################################
# Round-trip; if we encrypt/decrypt the data, do we get the data back out?
round_trip: {
    foreach my $suite (@test_data) {
        my $token    = $suite->{token};
        my $data     = $suite->{data};
        my $password = decode_base64($suite->{password_base64});

        my $factory   = Crypt::OpenToken->new(password => $password);
        my $encrypted = $factory->create(Crypt::OpenToken::CIPHER_NULL, $data);
        my $decrypted = $factory->parse($encrypted);
        eq_or_diff $decrypted->data(), $data,
            'NULL; encryption/decryption round-trip';
    }
}
