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
#����һ���µ�socket
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
#����ѭ������һ�����ж�sock�Ƿ������ݵ���
			while($select->can_read(0)){
				$line=<$sock>;
				if($line=~/^:(.+)!.+ PRIVMSG .+ :exit $this->{'login'} now!(!&!)*/){
					&_exit("1 close msg from $1");
				}
				elsif($line=~/^PING(.+)/i){
						print $sock "PING $1\r\n";
				}
				elsif($line ne ""){ #������յ�����
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
				} #��$sock�����ܶ�ȡ���ݵ��Ƕ�������Ϊ��ʱ,֤����irc�����Ѿ��жϡ����Թرձ����ӡ�

			}
#�ڶ�������ȡ�����ļ����ж��Ƿ�����Ҫ�Լ����͵�����
			if(my @data=$sme->getdata_from_gui()){	
			foreach $line (@data) {
				$line=myproto_to_irc($line);
				if($line=~/^\$msg> (\d+) *(.*)/){
						if($1==8){
							&_exit("2���˳���Ϣ����ǰ̨");
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
#��������������ͣһ��ʱ�䣬׼��������һ��ѭ��
            $line="";
			select(undef,undef,undef,$this->{'timeout'});
		}
}

sub _exit{
	my $temp=shift;
	print $sock "QUIT bye! now !\n";
	close($sock);
	print "socket is exit ok !  $temp\n" if($debug);
	&msg("close msg from: $temp") and sleep(1) if($temp ne "2���˳���Ϣ����ǰ̨");
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
		}#����Ϊֹ���ӷ������Ĺ����Ѿ�����.�˺�����ݶ�Ϊ������Ϣ.
		print "\t\t--------use $this->{'login'} join $this->{'group'} ok!--------\n" if($debug);
		&msg("$this->{'login'} join $group ok!");
}

sub login_services{
#������������û����������飬����������
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

sub irc_to_myproto{		#����˺���	Э��ת�� 
	my $s=shift;
	my $rs=0;
			if($s=~/:(.+)?!.+ PRIVMSG ([^\s]+) :(.+)/){    #�����������Ϣ
				my ($user,$send,$data)=($1,$2,$3);
				$rs="\$scanf $1 $2 $3";
				if($1=~m|freenode-connect|){
					return 0;
				}
			}
			elsif($s=~/^:(.+)?!.+ JOIN :([^\s]+)/){		#����ǵ�¼��Ϣ
				$rs="\$join $1 $2";
			}			
			elsif($s=~/^:(.+)?!.+ QUIT :([^\s]+)/){		#������˳���Ϣ
				$rs="\$quit $1";
			}
			elsif($s=~/:(.+)?!.+ PART (.+) :/){			#������˳���������Ϣ
				$rs="\$quit $1 $2";
			}
			elsif($s=~/^:.+433 \* (.+) :Nickname is already in use.*<(.+)>/s){	#������û�����ռ����Ϣ
				print "NICKname $1 is already use.\n";
				print "NICKname and login now is $this->{'login'}\n";
				$rs="\$cname $this->{'login'}";
			}
			elsif($s=~/:.+ 302 .+@(\S+)/){  #ȡ���û�ip��Ϣ
				$rs="\$who $this->{login} $this->{login} $1";
			}
			elsif($s=~/^:.+ 352 [\S+] (\#.+) n=(.+) ([^\S]+) [\S]+ ([^\s]+) H :(.+)/){	#������û�˵����Ϣ
				#$rs="\$who $4 $2 $3";		# �û�������ԭʼ�ĵĵ�¼���� ip��ַ 
			}
			elsif($s=~/^:.+ 353 .+ (\#.+) :(.+)\r/i){			#������������û��б���Ϣ
				&adduser($1,$2);
				#$rs="\$group:$1={$2}";
			}
			elsif($s=~/:.+ 366 $this->{'login'} ([^\s]+) :End of \/NAMES list\./i){	#������б������Ϣ
				$rs="\$group:$1={$this->{userlist}->{$1}}";
			}
			elsif($s=~/^:.+ 470 $this->{'login'} $this->{'group'} (.+) :Forwarding to another channel/){	#������ת��
				$rs="\$cgroup $this->{'group'} $1";
			}
			elsif($s=~/^:(.+)!.+ NICK :(.+)/){					#�û���������
				$rs="\$cname $1 $2";
			}
			elsif($s=~/:.+ 433 $this->{'login'} (.+) :Nickname is already in use./){	#�����ǳ�ʧ��
				$this->msg_to_gui(10,"The nickname ��$1�� is already in use, please to pick a new one.");
			}
			else{return 0;};
	return $rs;
}

sub myproto_to_irc{	#����� Э��ת��
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

sub adduser{	# ����� �û��б��ݴ溯�� �ú���Ϊ����κ��� ���ڻ�ȡ�û��б�ʱû�а취һ�εõ�ȫ���û��б�������Ҫ���û��б�д��һ����ʱ��ϣ�ȴ��б�����ʱ����
	my $group=shift;
	my $s=shift;
	if($group){
		$this->{userlist}->{$group}.=$s;
	}
}

sub msg{			# ����� �������Ϣ ת��
	my $msg=shift;
	my $rs;
		if($msg eq "Remotehost lost!"){ #�޹ʵ�������
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