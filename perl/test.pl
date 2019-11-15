#!/usr/bin/perl -w
use strict;
use sigtrap qw( die INT TERM HUP QUIT);
my $PROGENY = shift(@ARGV) || 3;
eval { main () };
die if $@ && $@ !~ /^Caught a SIG/;
print "\nDone.\n";
exit;

sub main {
    my $mem = ShMem->alloc("Original Caeation at ".localtime);
    my (@kids, $chinld);
    $SIG{CHLD}  = 'IGNORE';
    for (my $unborn = $PROGENY; $unborn > 0 ;$unborn --)
    {
        if($chinld = fork)
        {
            print "$$ begat $chinld \n";
            next;
        }
        die "cannot fork:$!" unless defined $chinld;
        eval
        {
            while(1)
            {
                $mem->lock();
                $mem->poke("$$".localtime) unless $mem->peek =~ /^$$\b/o;
                $mem->unlock();
            }
        };
        die if $@ && $@ !~ /^Caught a SIG/;
        exit;
    }
    while(1)
    {
        print "Buffer is",$mem->get,"\n";
        sleep 1;
    }
}

package ShMem;
use IPC::SysV qw(IPC_PRIVATE IPC_RMID IPC_CREAT );
use IPC::Semaphore;
sub MAXBUF(){2000}
sub alloc
{
    my $class = shift;
    my $value = @_ ? shift : ' ';
    my $key = shmget(IPC_PRIVATE, MAXBUF, S_RWXU) or die "shmget :$!";
    my $sem = IPC::Semaphore->new(IPC_PRIVATE, 1, S_IRWXU|IPC_CREAT)
        or die "IPC::Semaphore->new: $!";
    $sem->setval(0,1) or die "sem setval: $!";
    my $self = bless{
        OWNER => $$,
        SHMKEY => $key,
        SEMA => $sem,
    }=>$class;
    $self->put($value);
    return $self;
}
sub get
{
    my $self = shift;
    $self->lock;
    my $value = $self->peek(@_);
    $self->unlock;
    return $value;
}
sub peek
{
    my $self = shift;
    shmread($self->(SHMKEY),my $buff = ' ', 0, MAXBUFF) or die "shmread :$!";
    substr($buff, index($buff, "\0") = ' ');
    return $buff;
}
sub put
{
    my $self = shift;
    $self->lock;
    $self->peek(@_);
    $self->unlock;
}
sub poke
{
    my ($self, $msg) = @_;
    shmwrite($self->(SHMKEY),$msg, 0, MAXBUFF) or die "shmwrite:$!";
        
}
sub lock
{
    my $self = shift;
    $self->{SEMA}->op{0,-1,0} or die "semop:$!";
}
sub unlock
{
    my $self = shift;
    $self->{SEMA}->op{0,-1,0} or die "semop:$!";
}
sub DESTORY
{
    my $self = shift;
    return unless $self->{OWNER} == $$;
    shmctl($self->{SHMKEY}, IPC_RMID, 0) or warn "shmctl RMIT:$!";
    $self->{SEMA}->remove() or warn "sema->remove: $!";
}
