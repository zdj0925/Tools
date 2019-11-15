#!/usr/bin/perl

use strict;
use POSIX;
use IO::Socket;
use Devel::Peek;
use Getopt::Long;
use Encode;

my $addr =undef;
my $port =undef;
my $cfg_file =undef;# $ARGV[2] || './ctl/10202.ctl';
my $trans_no = undef;
my $data_file = undef;
my @var;

my $col=0;
my $line=1;
my $SOH= pack("H*",'01');
my $separator = undef;
my $encode = "gbk";

GetOptions(
    'ip=s' => \$addr,
    'port=s' => \$port,
    'file=s' => \$cfg_file,
);

my $MB = init();
my $PK = deal_data($MB);

sub rand_num
{
    my $a=shift;
    my $str;
    foreach (my $i = 0; $i< $a; ++$i)
    {
        $str = sprintf("%s%d",$str, int(rand(9)));
    }
    return $str;
}

sub init
{
    my $head = undef;
    my $body = undef;
    open(FILE,"<",$cfg_file)||die"cannot open the mfix file: $!\n";

    my @linelist = <FILE>; 

    close FILE;
    foreach my $eachline(@linelist)
    {
        @var = undef;
        $eachline =~ s/ //g;
        chomp($eachline);
        @var = split(/=|#/, $eachline);
        if ($eachline =~ !/^\s*$/ || $eachline =~ /^#/)
        {
            next;
        }
        if($var[0] eq "IPADDR" )
        {
            $addr = $var[1];
            next;
        }
        if($var[0] eq "PROT" )
        {
            $port = $var[1];
            next;
        }
        if($var[0] eq "DataFile" )
        {
            $data_file = $var[1];
            next;
        }
        if($var[0] eq "Separator" )
        {
            $separator = $var[1];
            next;
        }
        if($var[0] eq "Encoding" )
        {
            $encode = $var[1];
            next;
        }
        if($var[0] eq "FunctionId" )
        {
            $trans_no= $var[1];
            $head = $head.$var[0].$SOH;
            $body = $body.$var[1].$SOH;
            $col = $col + 1;
            next;
        }
        $head = $head.$var[0].$SOH;
        $body = $body.$var[1].$SOH;
        $col = $col + 1;
    }
    my $templetes = $col.$SOH.$line.$SOH.$head.$body;

    return $templetes;

}

sub deal_data 
{
    my $mb       = shift;
    my $str      = undef;
    my $dataline = undef;
    my $SB       = undef;
    my $num      = undef;
    my $field    = undef;

    open(DATA,"<", $data_file)||die"cannot open the data file: $!\n";

    while ($dataline = <DATA>)
    {
        $SB = $mb;
        #$dataline =~ s/$separator/ /g;
        if ($dataline=~ !/^\s*$/ || $dataline=~ /^#/)
        {
            next;
        }
        #print $dataline."\n";
        @var = split(/$separator/, $dataline);
        $num = 0;
        foreach(@var)
        {
            $field = sprintf("FIELD%02d", $num);
            $SB =~ s/$field/$var[$num]/g;
            $num = $num + 1;
        }
        $str = str_replace($SB );
        $SB  = encode($encode ,decode('gbk',$str));
        $str = str_package($SB);
        sock_send($addr, $port, $str);

    }

    close FILE;
}


sub sock_send
{
    my $IP   = shift;
    my $PORT = shift;
    my $PACK = shift;
    my $rsp  = undef; 
    my $sSIZE = undef;

    my $sock = IO::Socket::INET->new( PeerAddr => $IP, PeerPort => $PORT, Proto => 'tcp')  
        or die "Can't connect: $!\n";
    $sSIZE = $sock->send($PACK);

    $PACK =~ s/$SOH/|/g;
    print "\nsend data of length $sSIZE bytes, package:\n $PACK \n\n"; 

    $sSIZE = $sock->recv($rsp, 10240); 
    print "Received $sSIZE bytes, recv package :\n $rsp\n"; 

    $sSIZE = $sock->recv($rsp, 10240); 
    $PACK = encode('gbk',decode('utf8',$rsp));
    $PACK =~ s/$SOH/|/g;
    print "Received $sSIZE bytes, recv package :\n $PACK\n"; 

    $sock->close();
}

sub str_package
{
    my $pack_body = shift;
    my $pack_head = undef;
    my $package = undef;
    print $package;
    $pack_head = sprintf("F009%05d",length($pack_body));
    $package = $pack_head.$pack_body;
    return $package;
}

sub str_replace
{
    my $pack_buf = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $YYYYMMDD = sprintf("%04d%02d%02d", $year+1900, $mon+1, $mday);
    my $HHmmSS   = sprintf("%02d%02d%02d", $hour, $min, $sec);

    my $str02 = rand_num( 2);
    my $str04 = rand_num( 4);
    my $str06 = rand_num( 6);
    my $str08 = rand_num( 8);
    my $str10 = rand_num(10);
    my $str12 = rand_num(12);
    my $str20 = rand_num(20);
    my $str32 = rand_num(32);

    #print "$str32, $str20, $str12\n";

    $pack_buf =~ s/STR02/$str02/g;
    $pack_buf =~ s/STR04/$str04/g;
    $pack_buf =~ s/STR06/$str06/g;
    $pack_buf =~ s/STR08/$str08/g;
    $pack_buf =~ s/STR10/$str10/g;
    $pack_buf =~ s/STR12/$str12/g;
    $pack_buf =~ s/STR20/$str20/g;
    $pack_buf =~ s/STR32/$str32/g;

    $pack_buf =~ s/YYYYMMDD/$YYYYMMDD/g;
    $pack_buf =~ s/HHmmSS/$HHmmSS/g;

    return $pack_buf;
}
