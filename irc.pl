use strict;
use lib "IPC/Multi_Exec";
use Socket_Multi_Exec;
use Data::Dumper;

my $sme=new Socket_Multi_Exec(pop(@ARGV));
my $debug=1;
my $sock;
my $this={
	'irchost' => 'irc.freenode.net',
	'login'   => 'keli',
	'group'   => '#c',
	'timeout' => 0.5,
	 'send_dn'=>400,
	 'display'=>1,
	'ircport' => 6667,
};
foreach(@ARGV){
	s/[; ]+$//;
	if(/(.+)=(.+)/){
		$this->{$1}=$2;
	}
}
$sme->init("irc",$this->{login});

#print Dumper $this;
&starts();

sub starts{
#建立一个新的socket
	    my $line;
		print "connet  $this->{'irchost'} : $this->{'ircport'}....\n" if($debug);
		$sock=new IO::Socket::INET(PeerAddr => $this->{'irchost'},
			                        PeerPort => $this->{'ircport'},
				                    Proto    => 'TCP') or &msg("connect err!");
		my $select=IO::Select->new($sock);
		&msg("connect ok!");
		&login_services();
		print "user: $this->{'login'} login ok\n" if($debug);
		&msg("user: $this->{'login'} login ok");
		&join_group() if($this->{'group'} ne "");
	
		print  $sock "USERHOST $this->{'login'}\r\n";
		while(1){
#进入循环，第一步：判断sock是否有数据到达
			while($select->can_read(0)){
				$line=<$sock>;
				if($line=~/^:(.+)!.+ PRIVMSG .+ :exit $this->{'login'} now!(!&!)*/){
					&_exit("1 close msg from $1");
				}
				elsif($line=~/^PING(.+)/i){
						print $sock "PING $1\r\n";
				}
				elsif($line ne ""){ #如果接收到数据
					#$line=~s/!&!/\r/g if($line=~/!&!/);
					last if($line=~/^:.+ PONG .+ :/);
						print $line if($debug);
						&getdata($line);
						$line="";
					}
				else{
					print"$this->{login} \tRemotehost lost this subject is exit now !!!\n" if($debug);
					&msg("Remotehost lost!");
					exit(0);
				} #当$sock里面能读取数据但是读出数据为空时,证明本irc连接已经中断。所以关闭本连接。

			}
#第二步：读取命令文件，判断是否有需要自己发送的数据
			if(my @data=$sme->getdata_from_gui()){	
			foreach $line (@data) {
				$line=myproto_to_irc($line);
				if($line=~/^\$msg> (\d+) *(.*)/){
						if($1==8){
							&_exit("2、退出信息来自前台");
						}
						elsif($1==6){
							&join_group($2);
						}
						print $line;
				}
				else{my $ng=$this->{'send_dn'};
					if($line=~/^PRIVMSG (.+) :(.+)/ and length($line) >$ng){
							$sme->msg_to_gui(12);
							$this->{'sendto'}=$1;
							$line=$2;
							$line.="!&!" if(! $line=~/!&!$/ and $line=~/!&!/);
							my $i=0;
							for ($i;$i<length($line);$i+=$ng) {	
								sleep(1);
								my $s=substr($line,$i,$ng);
								my $sn=length($s);
								if($s=~/!&!/){
									my $n=rindex($s,"!&!");
									my $str=substr($s,0,$n+3);
									$i=$i-($ng-$n);
									$s=$str;
								}
								print "PRIVMSG $this->{'sendto'} :$s\n\n";
								#$s=decode("euc-cn",$s);
								print  $sock "PRIVMSG $this->{'sendto'} :$s\n" or &msg("Remotehost lost!");
								last if($sn<$ng);				
							}
					}
					else{
							#$line=decode("euc-cn",$line);
							print "/$line\n" if($debug);
							print  $sock $line or &msg("Remotehost lost!");
							if($line=~/^names/i){
							$sme->msg_to_gui(12);
								while (1) {
									$_=<$sock>;
									&getdata($_);
									print;
				       				last if($_=~/:.+:End of \/NAMES list\./i);
								}
							}

					}
				}
			}
			}
#第三步：程序暂停一段时间，准备进入下一次循环
            $line="";
			select(undef,undef,undef,$this->{'timeout'});
		}
}

sub _exit{
	my $temp=shift;
	print $sock "QUIT bye! now !\n";
	close($sock);
	print "socket is exit ok !  $temp\n" if($debug);
	&msg("close msg from: $temp") and sleep(1) if($temp ne "2、退出信息来自前台");
	unlink($this->{openfile}) or die "unlink err";	
	exit;
}

sub join_group{
	my $group=shift;
	$group=$this->{'group'} if($group eq undef);
	print $sock "JOIN $group\r\n";
		while (1) {
			$_=<$sock>;
			&getdata($_);
			print ;
       	    last if($_=~/:.+:End of \/NAMES list\./i);
			&msg("Remotehost lost!") if($_ eq "");
		}#到此为止连接服务器的工作已经结束.此后的数据多为聊天信息.
		print "\t\t--------use $this->{'login'} join $this->{'group'} ok!--------\n" if($debug);
		&msg("$this->{'login'} join $group ok!");
}

sub login_services{
#向服务器发送用户名，发送组，进入讨论区
		print  $sock "NICK $this->{'login'}\r\n";
		print  $sock "USER $this->{'login'} 8 * :HEOL ALL\r\n";
		while(my $line=<$sock>){
			print "$line\n" if($debug);
			if($line=~/004/){
				last;
			}
			elsif($line=~/433/){
			$this->{'login'}.="_".int(rand(100));
			&getdata("$line <$this->{'login'}>");
				#sleep(1);
				&login_services();
				return;
			}
		}
}
####################################################################################
sub getdata{
	my $s=shift;
	$s=irc_to_myproto($s);
	$sme->sendata_to_gui($s) if($s);
	return ;
}

sub irc_to_myproto{		#网络端函数	协议转换 
	my $s=shift;
	my $rs=0;
			if($s=~/:(.+)?!.+ PRIVMSG ([^\s]+) :(.+)/){    #如果是聊天信息
				my ($user,$send,$data)=($1,$2,$3);
				$rs="\$scanf $1 $2 $3";
				if($1=~m|freenode-connect|){
					return 0;
				}
			}
			elsif($s=~/^:(.+)?!.+ JOIN :([^\s]+)/){		#如果是登录信息
				$rs="\$join $1 $2";
			}			
			elsif($s=~/^:(.+)?!.+ QUIT :([^\s]+)/){		#如果是退出信息
				$rs="\$quit $1";
			}
			elsif($s=~/:(.+)?!.+ PART (.+) :/){			#如果是退出讨论组消息
				$rs="\$quit $1 $2";
			}
			elsif($s=~/^:.+433 \* (.+) :Nickname is already in use.*<(.+)>/s){	#如果是用户名被占用信息
				print "NICKname $1 is already use.\n";
				print "NICKname and login now is $this->{'login'}\n";
				$rs="\$cname $this->{'login'}";
			}
			elsif($s=~/:.+ 302 .+@(\S+)/){  #取的用户ip信息
				$rs="\$who $this->{login} $this->{login} $1";
			}
			elsif($s=~/^:.+ 352 [\S+] (\#.+) n=(.+) ([^\S]+) [\S]+ ([^\s]+) H :(.+)/){	#如果是用户说明信息
				#$rs="\$who $4 $2 $3";		# 用户名，最原始的的登录名， ip地址 
			}
			elsif($s=~/^:.+ 353 .+ (\#.+) :(.+)\r/i){			#如果是讨论组用户列表信息
				&adduser($1,$2);
				#$rs="\$group:$1={$2}";
			}
			elsif($s=~/:.+ 366 $this->{'login'} ([^\s]+) :End of \/NAMES list\./i){	#如果是列表结束信息
				$rs="\$group:$1={$this->{userlist}->{$1}}";
			}
			elsif($s=~/^:.+ 470 $this->{'login'} $this->{'group'} (.+) :Forwarding to another channel/){	#讨论组转向
				$rs="\$cgroup $this->{'group'} $1";
			}
			elsif($s=~/^:(.+)!.+ NICK :(.+)/){					#用户更改名称
				$rs="\$cname $1 $2";
			}
			elsif($s=~/:.+ 433 $this->{'login'} (.+) :Nickname is already in use./){	#更改昵称失败
				$this->msg_to_gui(10,"The nickname “$1” is already in use, please to pick a new one.");
			}
			else{return 0;};
	return $rs;
}

sub myproto_to_irc{	#网络端 协议转换
	my $s=shift;
		if($s=~/^\$print ([^\s]+) (.+)/){
			$s="PRIVMSG $1 :$2\n";	
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
		}
	return $s;
}

sub adduser{	# 网络段 用户列表暂存函数 该函数为网络段函数 由于获取用户列表时没有办法一次得到全部用户列表，所以需要将用户列表写入一个临时哈希等待列表完整时处理
	my $group=shift;
	my $s=shift;
	if($group){
		$this->{userlist}->{$group}.=$s;
	}
}

sub msg{			# 网络端 网络段消息 转换
	my $msg=shift;
	my $rs;
		if($msg eq "Remotehost lost!"){ #无故掉线重联
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

	$sme->msg_to_gui($rs);
	exit if($rs==4);
}