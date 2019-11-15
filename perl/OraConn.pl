#!/oracle/product/11.2.0/perl/bin/perl
##!/oracle11g/product/11.2.0/perl/bin/perl -w
#perl script used to connect to Oracle
##!/usr/bin/perl -w
use strict;
use DBI;


my $secu_no="";
my $amt=0.00;
my @row = ();
my $tnsname="emcsdb";
my $username="cmbcemcs";
my $password="cmbcemcs";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $YYYYMMDD = sprintf("%04d%02d%02d", $year+1900, $mon+1, $mday);          
my $HHmmSS   = sprintf("%02d%02d%02d", $hour, $min, $sec);
my $serial_no= sprintf("serial_no%s%s",$YYYYMMDD, $HHmmSS);
my $orderid = sprintf("orderid%s%s20009",$YYYYMMDD, $HHmmSS);
my $ex_serial= sprintf("ex_serial%s%s20009", $YYYYMMDD, $HHmmSS);
system "clear";
print ("          商户方利息账号余额调整\n");
print ("请输商户号:");
chomp ($secu_no = <STDIN>);
print ("\n请输要增加的金额:");
chomp ($amt = <STDIN>);

my $dbh=DBI->connect("dbi:Oracle:$tnsname", $username, $password) or die "Cannot conenct db: $DBI::errstr\n";

my $sql = sprintf("UPDATE TBSECUACC SET CASH_BALA=CASH_BALA+%.2f, BALANCE = BALANCE+%.2f WHERE ACC_ATTR IN('6','A') AND SECU_NO = '%s' ", $amt, $amt, $secu_no);
print ("$sql \n");
my $sth=$dbh->prepare($sql);
$sth->execute() or die $DBI::errstr;

my $sql1 = sprintf( "SELECT trim(A.BANK_ACC), trim(B.BANK_ACC), B.BALANCE FROM TBSECUACC A, TBSECUACC B WHERE A.SECU_NO=B.SECU_NO and A.SECU_NO = '%s' and A.Acc_Attr = '6' and B.Acc_Attr = 'A' ", $secu_no);
print "$sql1 \n";

$sth=$dbh->prepare($sql1);
$sth->execute() or die $DBI::errstr;
my ($fee_acc, $bank_acc, $balance) = $sth->fetchrow_array();
print "$fee_acc, $bank_acc, amt =$balance\n ";

my $sql2 = sprintf("insert into tbnotice values ('%s', '%s', '%s', '%s', '%s', '%s', '503', '0', '%s', '%s', ' ', ' ', %.2f, '156', '0', %.2f, 0.00, ' ', ' ', 0.00, '利息同步', ' ', '0', '20009', '3', 100, 'A', ' ') ", $YYYYMMDD, $HHmmSS, $secu_no, $orderid, $ex_serial, $serial_no, $fee_acc, $fee_acc, $amt, $balance);
print "$sql2 \n";
$sth=$dbh->prepare($sql2);
$sth->execute() or die $DBI::errstr;
my $sql3 = sprintf("insert into tbpaymentinter values ('%s', '%s', '%s', '%s', '20009 ', '503', ' ', ' ', '9', '%s', '%s', '300903', ' ', ' ', '%s', '156', '0', %.2f, '%s', '0', %.2f, '%s', ' ', ' ', ' ', ' ', '1', '0000 ', '交易成功', '利息同步', ' ', ' ', ' ', 0.00, 0.00, 0.00, 0.00, ' ') ", $YYYYMMDD, $serial_no, $orderid,  $ex_serial, $YYYYMMDD, $HHmmSS, $secu_no, $amt,$fee_acc, $balance, $bank_acc);

print "$sql3 \n";
$sth=$dbh->prepare($sql3);
$sth->execute() or die $DBI::errstr;
$sth->finish();

$dbh->disconnect or warn "DB disconnect failed: $DBI::errstr\n";
print "Disconnected from Oracle databae!\n";


