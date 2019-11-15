#!/usr/bin/perl

use strict;
use POSIX;
use IO::Socket;
use Devel::Peek;
use Getopt::Long;
use Encode;
use Time::HiRes qw(gettimeofday);

my $start_time = gettimeofday;
my $addr =undef;# $ARGV[0] || '127.0.0.1';
my $port =undef;# $ARGV[1] || '46005';
my $file_name =undef;# $ARGV[2] || './ctl/10202.ctl';
my $trans_no = undef;
my $pack_head = undef;
my $pack_body = undef;
my $head = undef;
my $body = undef;
my @var;
my $col=0;
my $line=1;
my $SOH= pack("H*",'01');

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $YYYYMMDD = sprintf("%04d%02d%02d", $year+1900, $mon+1, $mday);
my $HHmmSS   = sprintf("%02d%02d%02d", $hour, $min, $sec);
#######################my $exserial = sprintf("595%08s%06s",);
my $str32 = rand_num(32);
my $str20 = rand_num(20);
my $str12 = rand_num(12);
my $str06 = rand_num(6);
my $encode = "gbk";

GetOptions(
    'ip=s' => \$addr,
    'port=s' => \$port,
    'file=s' => \$file_name,
);
open(FILE,"<",$file_name)||die"cannot open the file: $file_name \n";

my @linelist = <FILE>; 

close FILE;
foreach my $eachline(@linelist)
{
    @var = undef;
    $eachline =~ s/ //g;
    chomp($eachline);
    #### @var = split(/=/, $eachline, 2);
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
#    print "addr[$addr],port[$port],tran_no[$trans_no] \n";
#    print "col[$col],head [$head]\nbody [$body]\n";


$pack_body = $col.$SOH.$line.$SOH.$head.$body;

$pack_body =~ s/STR32/$str32/g;
$pack_body =~ s/STR20/$str20/g;
$pack_body =~ s/STR12/$str12/g;
$pack_body =~ s/STR06/$str06/g;
$pack_body =~ s/YYYYMMDD/$YYYYMMDD/g;
$pack_body =~ s/HHmmSS/$HHmmSS/g;
$pack_body =~ s//=/g;


$pack_body = encode($encode, decode('gbk',$pack_body));

$pack_head = sprintf("F009%05d",length($pack_body));

my $sock = IO::Socket::INET->new( PeerAddr => $addr, PeerPort => $port, Proto => 'tcp')  
    or die "Can't connect: $!\n";
my $send_size = $sock->send($pack_head.$pack_body);

$pack_head =~ s/$SOH/|/g;
$pack_body =~ s/$SOH/|/g;
print "\nsend data of length $send_size bytes, $pack_head \n$pack_body\n"; 

my $rsp =undef; 
my $recv_size = $sock->recv($rsp, 10240); 
print "Received $recv_size bytes, recv data $rsp\n"; 

$recv_size = $sock->recv($rsp, 10240); 
$line = encode('gbk',decode($encode,$rsp));
$line =~ s/$SOH/|/g;
print "Received $recv_size bytes, recv data $line\n"; 

$sock->close();
my $end_tiem = gettimeofday;
printf ("ºÄÊ± $end_tiem-$start_time = %lf\n", $end_tiem-$start_time);
sub rand_num
{
    my $a=shift;
    my $str;
    foreach (my $i = 0; $i< $a; ++$i)
    {
        $str = sprintf("%s%d",$str, int(rand(9)));
    }
    #print "rand no =[$str]\n";
    return $str;

}
