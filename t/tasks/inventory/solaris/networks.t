#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Test::Inventory;
use FusionInventory::Agent::Task::Inventory::Solaris::Networks;

my %ifconfig_tests = (
    'solaris-10' => [
        {
            IPMASK      => '255.0.0.0',
            DESCRIPTION => 'lo0',
            TYPE        => 'ethernet',
            STATUS      => 'Up',
            IPADDRESS   => '127.0.0.1'
        },
        {
            IPMASK      => '255.255.254.0',
            MACADDR     => '00:15:17:7a:60:31',
            STATUS      => 'Up',
            DESCRIPTION => 'aggr1',
            TYPE        => 'ethernet',
            IPADDRESS   => '130.79.0.1'
        },
        {
            IPMASK      => '255.255.255.128',
            MACADDR     => '00:15:17:7a:60:30',
            STATUS      => 'Up',
            DESCRIPTION => 'e1000g0',
            TYPE        => 'ethernet',
            IPADDRESS   => '130.79.0.2'
        },
        {
            IPMASK      => '255.255.255.128',
            MACADDR     => '00:15:17:7a:60:32',
            STATUS      => 'Up',
            DESCRIPTION => 'e1000g2',
            TYPE        => 'ethernet',
            IPADDRESS   => '130.79.0.3'
        },
        {
            IPMASK      => '255.255.255.0',
            MACADDR     => '00:15:17:7a:60:33',
            STATUS      => 'Up',
            DESCRIPTION => 'e1000g3',
            TYPE        => 'ethernet',
            IPADDRESS   => '192.168.19.1'
        },
        {
            IPMASK      => '255.255.255.224',
            MACADDR     => '00:15:17:8a:48:30',
            STATUS      => 'Up',
            DESCRIPTION => 'e1000g4',
            TYPE        => 'ethernet',
            IPADDRESS   => '130.79.255.1'
        },
        {
            IPMASK      => '255.255.255.0',
            MACADDR     => '00:15:17:6a:44:4c',
            STATUS      => 'Up',
            DESCRIPTION => 'igb0',
            TYPE        => 'ethernet',
            IPADDRESS   => '192.168.20.1'
        }
    ],
    'opensolaris' => [
        {
            IPMASK      => '255.0.0.0',
            DESCRIPTION => 'lo0',
            TYPE        => 'ethernet',
            STATUS      => 'Up',
            IPADDRESS   => '127.0.0.1'
        },
        {
            IPMASK      => '255.255.255.0',
            MACADDR     => '08:00:27:fc:ad:56',
            STATUS      => 'Up',
            DESCRIPTION => 'e1000g0',
            TYPE        => 'ethernet',
            IPADDRESS   => '192.168.0.41'
        },
        {
            DESCRIPTION => 'lo0',
            TYPE        => 'ethernet',
            STATUS      => 'Up',
        },
        {
            MACADDR     => '08:00:27:fc:ad:56',
            DESCRIPTION => 'e1000g0',
            TYPE        => 'ethernet',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'e1000g0:1',
            TYPE        => 'ethernet',
            STATUS      => 'Up',
        }
    ]

);

my %kstat_tests = (
    sample1 => 1000,
    sample2 => 1000,
    sample3 => 1000,
    sample4 => 0,
);

my %parsefcinfo_tests = (
    'sample-1' => [
        {
            FIRMWARE     => '05.03.02',
            STATUS       => 'Up',
            SPEED        => '4000',
            DRIVER       => 'qlc',
            DESCRIPTION  => 'HBA_Port_WWN_1 /dev/cfg/c0',
            MANUFACTURER => 'QLogic Corp.',
            MODEL        => 'QLE2462',
            WWN          => '200000e08b94b4a3'
        },
        {
            FIRMWARE     => '05.03.02',
            STATUS       => 'Up',
            SPEED        => '4000',
            DRIVER       => 'qlc',
            DESCRIPTION  => 'HBA_Port_WWN_2 /dev/cfg/c1',
            MANUFACTURER => 'QLogic Corp.',
            MODEL        => 'QLE2462',
            WWN          => '200100e08bb4b4a3'
        }
    ],
    'sample-2' => [
        {
            FIRMWARE     => '02.01.145',
            STATUS       => 'Up',
            SPEED        => '1000',
            DRIVER       => 'qlc',
            DESCRIPTION  => 'HBA_Port_WWN_1 /dev/cfg/c1',
            MANUFACTURER => 'QLogic Corp.',
            MODEL        => '2200',
            WWN          => '220000144f3eb274'
        },
        {
            FIRMWARE     => '03.03.28',
            STATUS       => 'Up',
            SPEED        => '2000',
            DRIVER       => 'qlc',
            DESCRIPTION  => 'HBA_Port_WWN_2 /dev/cfg/c2',
            MANUFACTURER => 'QLogic Corp.',
            MODEL        => 'QLA2340',
            WWN          => '200000e08b90682c'
        },
        {
            FIRMWARE     => '03.03.28',
            STATUS       => 'Down',
            SPEED        => undef,
            DRIVER       => 'qlc',
            DESCRIPTION  => 'HBA_Port_WWN_3 /dev/cfg/c3',
            MANUFACTURER => 'QLogic Corp.',
            MODEL        => 'QLA2340',
            WWN          => '200000e08b90b82b'
        }
    ]
);

plan tests =>
    2 * (scalar keys %ifconfig_tests)    +
        (scalar keys %kstat_tests)       +
    2 * (scalar keys %parsefcinfo_tests) +
    1;

my $inventory = FusionInventory::Test::Inventory->new();

foreach my $test (keys %ifconfig_tests) {
    my $file = "resources/generic/ifconfig/$test";
    my @interfaces = FusionInventory::Agent::Task::Inventory::Solaris::Networks::_parseIfconfig(file => $file);
    cmp_deeply(\@interfaces, $ifconfig_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'NETWORKS', entry => $_)
            foreach @interfaces;
    } "$test: registering";
}

foreach my $test (sort keys %kstat_tests) {
    my $file = "resources/solaris/kstat/$test";
    is(
        FusionInventory::Agent::Task::Inventory::Solaris::Networks::_getInterfaceSpeed(file => $file),
        $kstat_tests{$test},
        "$test: parsing"
    );
}

foreach my $test (keys %parsefcinfo_tests) {
    my $file = "resources/solaris/fcinfo_hba-port/$test";
    my @interfaces = FusionInventory::Agent::Task::Inventory::Solaris::Networks::_parsefcinfo(file => $file);
    cmp_deeply(\@interfaces, $parsefcinfo_tests{$test}, "$test fcinfo: parsing");
    lives_ok {
        $inventory->addEntry(section => 'NETWORKS', entry => $_)
            foreach @interfaces;
    } "$test fcinfo: registering";
}
