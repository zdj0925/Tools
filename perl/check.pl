#!/usr/bin/perl
use strict;
use POSIX;
#use IO::Socket;
#use Devel::Peek;
use Getopt::Long;
#use Encode;


sub replace_error
{
    my $buf = shift;

    $buf =~ s/ERR_SUCCESS/0000/g;#/*³É¹¦*/
    $buf =~ s/SET_ERRORNO\(/Code:/g;
    return $buf;
}
sub check_memset 
{
    my $buf = shift;
    my @ptr =  split(/\(|,|\)/g, $buf);
    $ptr[1] =~ s/\s//g;
    $ptr[4] =~ s/\s//g;

    if($ptr[4] =~/$ptr[1]/i || $ptr[1] =~/$ptr[4]/i)
    {
         return "";
	 #return $buf;
    }
    return $buf;
    #return "";
}
sub write_file
{
    my $FB=shift;
    my $DATA=shift;
    open (FILE,">>",$FB)||die "can`t open the $FB file:$!\n";
    print (<FILE>,$DATA."\n");
    close FILE;
}

my $Fout = undef;
my $Fin  = undef;
GetOptions(
        'outfile=s' => \$Fout,
        'inputfile=s' => \$Fin,
);


open (DATA,"<",$Fin)||die "can`t open the $Fin file:$!\n";

my $Dline = undef;
while($Dline=<DATA>)
{
    my $Line = undef;
    #   $Line = replace_error($Dline);
    $Line = check_memset($Dline);
#    print $Fin.";".$Line;
    print $Line;

}
    close DATA;
