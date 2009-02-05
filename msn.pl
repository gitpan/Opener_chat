use lib "./lib";
use lib "IPC/Multi_Exec";
use MSN;

use Socket_Multi_Exec;
my $this={
	'login'   => '',
	'password'=> '',
};

my $sme=new Socket_Multi_Exec(pop(@ARGV));

foreach(@ARGV){
	s/[; ]+$//;
	if(/(.+)=(.+)/){
		$this->{$1}=$2;
	}
}
$sme->init("msn",$this->{login});

my $handle =$this->{login};
my $password = $this->{password};
print "handle =$handle  , password =$password \n";

#my $handle = 'lishang-007@163.com';
#my $password = 'lishang';
my $admin = 'lishang-007@163.com';

my $msn = new MSN( 'Handle' => $handle, 'Password' => $password );

$msn->setClientInfo( 'Client' => 'MSNC2' );
$msn->setClientCaps( 'Client-Name' => 'MSN Bot/1.0', 'Chat-Logging' => 'Y', 'Client-Template' => 'None' );
$msn->setMessageStyle( 'Effect' => 'BI', 'Color' => 'FF0000', 'Name' => 'MSN Bot' );

$msn->setHandler( 'Connected' => \&Connected );
$msn->setHandler( 'Message' => \&Message );

$msn->connect();
my $run = 1;
while( $run )
{
	$msn->do_one_loop();
	select(undef,undef,undef,0.5);
	my @data=$sme->getdata_from_gui();
	foreach  (@data) {
		$_=myproto_to_msn($_);
	#$msn->call(,$_) if($_);
	}
}


################################################
# handlers
################################################

sub Connected
{
	my $self = shift;
	$msn->call( $admin, "I am connected!", 'Effect' => 'BI', 'Color' => '00FF00', 'Name' => 'Your Bot' );
	&msg("connect ok!");
	&msg("user: $this->{'login'} login ok");
	print( "Connected\n" );
	my @all=$msn->getContactList("FL");
	my $userlist =join(" ",@all);
	my $rs="\$group:$handle={$userlist}";	
	$sme->sendata_to_gui($rs);
}

sub Message
{
	my( $self, $username, $name, $message, %style ) = @_;
	if( $message =~ /^!exit$/i )     				# exits the bot
	{
		$msn->disconnect( );
		$run = 0;
	}
	elsif( $message =~ /^!broadcast\s+(.*)$/i )  # sends a broadcast message
	{
		# example of a broadcast with style and P4 name
		$reply = $msn->broadcast( $1, 'Effect' => 'BI', 'Color' => '0000FF', 'Name' => 'Broadcaster' );
	}
	else                                         # repeats what the user said
	{
		getdata(\@_);
		$this->{self}=$self;
		#$self->sendMessage( $message, %style );
	}
}

#####################################################################################################################################################################
sub getdata{
	my $s=shift;
	$s=irc_to_myproto($s);
	$sme->sendata_to_gui($s);
	return ;
}

sub irc_to_myproto{		#网络端函数	协议转换 
	my $s=shift;
	my $rs=0;

	my $self=$s->[0];
	my $name=$s->[1];
	my $message=$s->[3];
	my %sytle=$s->[4];

	$rs="\$scanf $name $handle $message";
	print "$rs\n";

	return $rs;
}

sub myproto_to_msn{	#网络端 协议转换
	my $s=shift;
		if($s=~/^\$print ([^\s]+) (.+)/){
			$msn->call($1,$2);
		}
		elsif($s=~/^\$msg> (\d+) (.+)/){
			if($1==3){
				$s="names $2\n";	
			}
			elsif($1==5){
				$s="nick $2\n";	
			}
			elsif($1==7){
				$s="part $2\n";	
			}
			elsif($1==8){
				exit;
			}
		}
	return $s;
}

sub msg{			# 网络端 网络段消息 转换
	my $msg=shift;
	my $rs;
		if($msg eq "Remotehost lost!"){#无故掉线重联
				$rs=4;
		}
		elsif($msg=~/^close msg from/){
				$rs=8;
		}
		elsif($msg eq "connect ok!"){
				$rs=1;
		}
		elsif($msg=~/user: $this->{'login'} login ok/){
				$rs=2;
		}
		elsif($msg=~/$this->{'login'} join (.+) ok!/){
				$rs=3;
		}
		elsif($msg eq "connect err!"){
                $rs=0;
		}

	$sme->msg_to_gui($rs,"msn:: $handle  $msg");
	exit if($rs==4);
}