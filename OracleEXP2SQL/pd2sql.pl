#!/oracle/product/11.2.0/perl/bin/perl
##!/oracle11g/product/11.2.0/perl/bin/perl -w
#perl script used to connect to Oracle
##!/usr/bin/perl -w
use strict;
use DBI;

my $tnsname="emcsdb";
my $username="cmbcemcs";
my $password="cmbcemcs";
#my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#my $YYYYMMDD = sprintf("%04d%02d%02d", $year+1900, $mon+1, $mday);          
#my $HHmmSS   = sprintf("%02d%02d%02d", $hour, $min, $sec);
#my $serial_no= sprintf("serial_no%s%s",$YYYYMMDD, $HHmmSS);
#my $orderid = sprintf("orderid%s%s20009",$YYYYMMDD, $HHmmSS);
#my $ex_serial= sprintf("ex_serial%s%s20009", $YYYYMMDD, $HHmmSS);
my  %HTBCFGInfo;

sub addsql 
{
    my $sql_buf = shift;
    my $where_buf= shift;
    return $sql_buf.' '.$where_buf;

}
sub dbopen
{
    my $USER = shift;
    my $PASSWD = shift;
    my $TNSNAME = shift;
    return my $db=DBI->connect("dbi:Oracle:$TNSNAME", $USER, $PASSWD) or die "Cannot conenct db: $DBI::errstr\n";
}
sub commit_work
{
    my $db = shift;
    $db->commit or die $DBI::errstr;
    $db->disconnect or warn "DB disconnect failed: $DBI::errstr";
}
sub select_sql
{
    my $db = shift;
    my $sql = shift;
    print ("$sql \n");

    my $sth=$db->prepare($sql);
    $sth->execute() or die $DBI::errstr;

    return $sth->fetchrow_array();
}
sub fatch2file
{
    my $db = shift;
    my $sql = shift;
    my $FN = shift;
    my $sth=$db->prepare($sql);
    $sth->execute() or die $DBI::errstr;
    print $FN;
    open(FOUT,">>$FN");
    while(my  @line=$sth->fetchrow_array)
    {
        $line[0] =~ s/\s+'/'/g;
        print FOUT ( $line[0]);
        print FOUT ( "\n" );
    }
}
sub main 
{
    my $SQL_CFG = shift;
    my $dbh = dbopen('cmbcemcs', 'cmbcemcs', 'emcsdb');
    #读取配置文件
    open(SQLCFG, "<", $SQL_CFG)||die "cannot open the file: $!\n";
    my @CFG_LINE = <SQLCFG>;
    my $lNO = 0;
    my $mksql= undef;

    foreach my $TB_CFG(@CFG_LINE)
    {
        #$TB_CFG=~ s/(^s+|s+$)//g; #去除两端空格
        chomp($TB_CFG);
        #@var = split(/=|#/, $TB_CFG);
        if ($TB_CFG=~ !/^\s*$/ || $TB_CFG=~ /^#/)
        {
            next;
        }
        my @TB_CFG_COLs= split (/\^/, $TB_CFG);
        #my $Data = undef;
        $mksql = "";
        print("++++++++++++$mksql++++++++++\n");
        $TB_CFG_COLs[0]=~ s/(^\s+|\s+$)//g; #去除两端空格
        $TB_CFG_COLs[1]=~ s/(^\s+|\s+$)//g; #去除两端空格
        $TB_CFG_COLs[2]=~ s/(^\s+|\s+$)//g; #去除两端空格
        $TB_CFG_COLs[3]=~ s/(^\s+|\s+$)//g; #去除两端空格

        $HTBCFGInfo{'NO_'.$lNO}      = $lNO;
        $HTBCFGInfo{'TB_'.$lNO}      = $TB_CFG_COLs[0];  #表名
        $HTBCFGInfo{'LOADFILE_'.$lNO}= $TB_CFG_COLs[1];  #导出文件名
        $HTBCFGInfo{'COL_'.$lNO}     = $TB_CFG_COLs[2];  #导出字段 默认全字段
        $HTBCFGInfo{'WHERE_'.$lNO}   = $TB_CFG_COLs[3];  #导出条件
        #$HTBCFGInfo{'SQL_'.$lNO}     = $TB_CFG_COLs[3];
        $HTBCFGInfo{'MKSQL_'.$lNO}   = sprintf("select 
            ('select ''insert into  ' || t.TABLE_NAME || ' (' ||
            listagg(t.COLUMN_NAME, ',') within
            group(order by t.COLUMN_ID) || ') values (''||''''''''||' ||
            listagg(t.COLUMN_NAME, '||'''''',''''''||') within
            group(order by t.COLUMN_ID) || '||'''''');'' from ' || t.TABLE_NAME) as sql
            from user_tab_columns t
            where table_name = upper('%s')
            group by (t.TABLE_NAME) ", $HTBCFGInfo{'TB_'.$lNO});
        #print($HTBCFGInfo{'MKSQL_'.$lNO});
        # print("\n");
        #根据表名得到导出语句
        $mksql = select_sql($dbh, $HTBCFGInfo{'MKSQL_'.$lNO}); # 生成查询语句
        $HTBCFGInfo{'SQL_'.$lNO} = $mksql." ".$HTBCFGInfo{'WHERE_'.$lNO};
        print("$TB_CFG_COLs[0]\n");
        print("$TB_CFG_COLs[1]\n");
        print("$TB_CFG_COLs[2]\n");
        print("$TB_CFG_COLs[3]\n");
        print("NO:[$HTBCFGInfo{'NO_'.$lNO}]\n");
        print("table:[$HTBCFGInfo{'TB_'.$lNO}]\n");
        print("FN:[$HTBCFGInfo{'LOADFILE_'.$lNO}]\n");
        print("COL:[$HTBCFGInfo{'COL_'.$lNO}]\n");
        print("where:[$HTBCFGInfo{'WHERE_'.$lNO}]\n");
        print("SQL:[$HTBCFGInfo{'SQL_'.$lNO}]\n");
        print("------------------------------\n");
        #执行导出语句并写入文件
        fatch2file($dbh, $HTBCFGInfo{'SQL_'.$lNO}, $HTBCFGInfo{'LOADFILE_'.$lNO});
        #$fatch2file($HTBCFGInfo{'LOADFILE_'.$lNO}, $Data);

        $lNO +=1;
    }
    

}
main('./list.txt');
print("end!\n");
