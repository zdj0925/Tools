#!/usr/bin/perl -w

#BASE64зЊТы
use strict;
use MIME::Base64;
use Getopt::Long;

my $encstrings = 1;
my $decstrings = 2;
my $infilename;
my $outfilename;
my $glbstring;
GetOptions(
    'dec:s' => \$encstrings,
    'enc:s' => \$decstrings,
    'infile=s' => \$infilename,
    'outfile=s' => \$outfilename,
);

printf($encstrings, $decstrings);
if(defined($infilename)){
    open(FB,"<",$infilename);
    $glbstring = <FB>;
    close;
}
if(!defined($outfilename) && defined($infilename)){
    $outfilename = $infilename . ".out";
}
if(defined($decstrings)){
    printf("orignal string is '%s'\n",$decstrings);
    my $encode = encode_base64($decstrings);
    printf("after base64 encoded is '%s'\n", $encode);
}

if(defined($encstrings)){
    printf("orignal string is '%s'\n",$encstrings);
    my $decode = decode_base64($encstrings);
    printf("after base64 decoded is '%s'\n", $decode);
}

