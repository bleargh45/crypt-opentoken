#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use Test::Differences;
use Crypt::OpenToken;

###############################################################################
# Test to make sure that we can decrypt OpenTokens that were created by a
# separate implementation, verifying interoperability.  Also test a roundtrip
# of encryption/decryption, to make sure that we can encrypt our own
# OpenTokens.
#
# We can't, however, test to make sure that tokens that we generate are usable
# by a different OpenToken implementation; the IV is generated randomly each
# time you encrypt a token so there's no guarantee that we'd be able to create
# a token to compare against test data from another implementation.
###############################################################################

###############################################################################
### TEST DATA
###
### This test data was generated by the PingId PHP Integration Kit.
###############################################################################
my %data     = (foo => 'bar', bar => 'baz');
my $password = 'a66C9MvM8eY4qJKyCXKW+19PWDeuc3th';
my $aes128   = 'T1RLAQLYzm2R0wpOyyqdYp2RQ-t_Im7KLBA2RwUN-GrKzUY36XXJqPHYAAAg1Gg6bi9SwAZTWxp9SfUSSt7ypVAVqbQwS6Flw2cqhCI*';
my $aes256   = '';
my $des3     = 'T1RLAQMdbpCui_Mpsin3jAo2Qcr482eYwghHrjVaX6X4WAAAGBrFPLDACb_ZOnmNNKLj26R-dITesg-bdA**';
my $null     = 'T1RLAQAwciArHYl0DprhUtzpyOWP_2B-UwAAABR4nEvLz7dNSiziAmIgXQUAK3AFcA**';

###############################################################################
# TEST: AES-256
aes_256: {
    my $factory = Crypt::OpenToken->new(password => $password);

    TODO: {
        todo_skip 'AES-256 sample not available for testing', 2;
        local $TODO = 'AES-256 sample not available for testing';

        # decrypt the data from another OpenToken application
        compatibility: {
            my $decrypted = $factory->parse($aes256);
            eq_or_diff $decrypted->data(), \%data,
                'AES-256; decrypt externally generated data';
        }

        # encryption/decryption round-trip
        round_trip: {
            my $encrypted = $factory->create(
                Crypt::OpenToken::CIPHER_AES256, \%data,
            );
            my $decrypted = $factory->parse($encrypted);
            eq_or_diff $decrypted->data(), \%data,
                'AES-256; encryption/decryption round-trip';
        }
    }
}

###############################################################################
# TEST: AES-128
aes_128: {
    my $factory = Crypt::OpenToken->new(password => $password);

    # decrypt the data from another OpenToken application
    compatibility: {
        my $decrypted = $factory->parse($aes128);
        eq_or_diff $decrypted->data(), \%data,
            'AES-128; decrypt externally generated data';
    }

    # encryption/decryption round-trip
    round_trip: {
        my $encrypted = $factory->create(
            Crypt::OpenToken::CIPHER_AES128, \%data,
        );
        my $decrypted = $factory->parse($encrypted);
        eq_or_diff $decrypted->data(), \%data,
            'AES-128; encryption/decryption round-trip';
    }
}

###############################################################################
# TEST: DES3-156
des3_156: {
    SKIP: {
        my $has_des3_installed = eval {
            require Crypt::CBC;
            require Crypt::DES_EDE3;
        };
        skip 'DES3 crypto modules not installed', 2 unless $has_des3_installed;

        my $factory = Crypt::OpenToken->new(password => $password);

        # decrypt the data from another OpenToken application
        compatibility: {
            my $decrypted = $factory->parse($des3);
            eq_or_diff $decrypted->data(), \%data,
                'DES3-168; decrypt externally generated data';
        }

        # encryption/decryption round-trip
        round_trip: {
            my $encrypted = $factory->create(
                Crypt::OpenToken::CIPHER_DES3, \%data,
            );
            my $decrypted = $factory->parse($encrypted);
            eq_or_diff $decrypted->data(), \%data,
                'DES3-168; encryption/decryption round-trip';
        }
    }
}

###############################################################################
# TEST: NULL
null: {
    SKIP: {
        my $has_null_installed = eval {
            require Crypt::NULL;
        };
        skip 'NULL crypto module not installed', 2 unless $has_null_installed;

        my $factory = Crypt::OpenToken->new(password => $password);

        # decrypt the data from another OpenToken application
        compatibility: {
            my $decrypted = $factory->parse($null);
            eq_or_diff $decrypted->data(), \%data,
                'NULL; decrypt externally generated data';
        }

        # encryption/decryption round-trip
        round_trip: {
            my $encrypted = $factory->create(
                Crypt::OpenToken::CIPHER_NULL, \%data,
            );
            my $decrypted = $factory->parse($encrypted);
            eq_or_diff $decrypted->data(), \%data,
                'NULL; encryption/decryption round-trip';
        }
    }
}

###############################################################################
# TEST: invalid cipher
invalid_cipher: {
    my $factory = Crypt::OpenToken->new(password => $password);
    throws_ok { $factory->create(9999, \%data) }
        qr/unsupported OTK cipher; '9999'/;
}

