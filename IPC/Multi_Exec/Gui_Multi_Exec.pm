package Gui_Multi_Exec;

use Common_Multi_Exec;
use Data::Dumper;

sub new{	#�ú���Ϊǰ̨��ʼ������ ���ý���һ������ ��ʼ������
	my ($proto,$exchangef)=@_;
	my $this={		
		'run_wait_time'  =>3, 
		'start_wait_time'=>60,
		};
	$this->{openfile}=$exchangef;
	bless $this,$proto;
	return $this;
}

#-------------------------------------------------------------------------------------

sub msg_to_socket{   #ǰ̨ ������Ϣ�������  ������������� 1 ��Ϣ���� 2 ��Ϣ����  ע��ģ���ڲ����ú��������������Ч 
	my ($this,$n,$s)=@_;
	$s="\$msg> $n $s";
	&_writing($this,$s,1);
}

sub senddata_to_socket{		#ǰ̨���� ��������  ������� ���������� 1 ���Ͷ��� 2 ��������  ע�� ���������û�и��� �ͽ����Ͷ����Ϊ��ǰ�� ������Ĳ����������͵����� sendata
    my $this=shift;
	my ($sendto,$data)=@_;
	if($data eq undef){
		$data=$sendto;
		$sendto=$this->{'group'};
	}
	return if($data eq "\n");
	$sendto=_Delspace($sendto) if($sendto=~/\s|\r/);
	chomp($data);
		$data=~s/\r\n|\n/!&!/sg;				#������͵������г���\r\n or \n ���滻Ϊ ��&��
		print "send :$data\n" if($debug);
		$data="\$print $sendto $data";			
	&_writing($this,$data,1);
}

sub sendcommand_to_socket{  #��������		sendcommand
	my $this=shift;
	my ($sendto,$data)=@_;
	$data='($shell@cmd&R# '."$data)";
	&senddata($this,$sendto,$data);
}

sub getdata_from_socket{		#ǰ̨����  ��ȡ����    ������ã������ⲿ���ã� ���� �����Ǹ������������ û�д������ʱ Ϊ��ǰ�� getdata
    my ($this)=@_;
	$this->{times}=time unless($this->{times});
	my $times=time;
	$times=$times-$this->{times};   

	if(-e $this->{'openfile'} ){
		my $data=_openfile($this,"open");
		my %h;  my %msg;   #%h ���������Ϣ ���� 1 Ⱥ����Ϣ 2 ����˽����Ϣ 3 �����������Ϣ��������  %msg ��Ŵ��ݸ�ǰ̨����Ϣ
		my $ws; my $wping=1;
		$this->{'guiw'}++;
			foreach (@$data) {
				chomp;
				next unless($_);
				if($_=~/^\$scanf ([^\s]+) ([^\s]+) (.+)/){	#����ǽ��յ�������
				#print "$_\n";
					my ($user,$g,$data)=($1,$2,$3);
					$data=~s/!&!/\r\n/g if($data=~/!&!/);			#������ܵ�������Ϊ��&����ת��Ϊ\r\n
						if($g eq $this->{"login"}){		#�����˽������
							if(!($data=~/\(\$shell\@cmd&R\# (.+)\)/)){
								%h->{2}->{$user}.="$data\n";	#ע�� ����˽������ Ϊ����Ⱥ����Ϣ�����ر� ���û���ǰ��� ><: ��ʾһ��һ̸��
							}
							else{
								%h->{3}->{$user}.=$1;
							}
						}
						else{					#����Ǹ������������		
								%h->{1}->{$g}->{$user}.="$data\n"; 	
						}
					next ;
				}
				elsif($_=~/^\$msg< (\d+) *(.*)/){	#������ڲ���Ϣ
						if($1==11){
							$this->{'times'}=time;
							$this->{'startok'}=1 if($this->{'startok'}==-1);
							next;
						}
						elsif($1==12){
							$this->{'startok'}=-1;
							next;
						}
						elsif($1==8){
							unlink($this->{openfile});
						}
						%msg->{$1}=$2;
						next;
				}
				elsif($_=~/^\$join (.+) (.+)/){		#����ǵ�¼��Ϣ
						my ($name,$g)=($1,lc($2));
						push(@{%msg->{6}->{$g}},$name);  #����¼��Ϣ���ͳ� 6 ����Ϣ ��Ӧ������Ϊ��½�û��б� ���ַ��� ÿ���û��ÿո�ֿ���
						next;
				}
				elsif($_=~/^\$quit ([^\s]+) *(.*)/){#������˳���Ϣ
						my ($name,$g)=($1,lc($2));
						if($g eq undef){
							push(@{%msg->{77}},$name);	       #���û����߻��˳���������Ϣ���ͳ� 77 ����Ϣ ��Ӧ������Ϊ�˳��û��б� ���ַ��� ÿ���û��ÿո�ֿ���
						}
						else{
							push(@{%msg->{7}->{$g}},$name);	   #���û��˳�����������Ϣ���ͳ� 7 ����Ϣ ��Ӧ������Ϊ�˳��û��б� ���ַ��� ÿ���û��ÿո�ֿ���
						}
					next ;
				}
				elsif(/^\$cname ([^\s]+) *(.*)/){			#����Ǹ�����Ϣ
						if($2){
							%msg->{55}->{$1}=$2;
						}
						else{
							%msg->{5}=$1;
							$this->{'login'}=%msg->{5};
						}
						next;
				}
				elsif(/^\$cgroup (.+) (.+)/){
						%msg->{9}->{$1}=$2;
						$this->{'group'}=$2;
						next;
				}
				elsif($_=~/^\$group:(.+)=\{(.*)\}/){	#��������Ա�б���Ϣ
					    my ($g,$userlist)=(lc($1),$2); 
						next if($userlist=~/^\s+$/ or $userlist eq undef);
						$this->{'startok'}=1;
						$this->{'times'}=time;
						$times=0;
						my @garray=split(/\s+/,$userlist);
							%msg->{3}->{$g}=\@garray;				#3����ϢΪ�������û��б������Ϣ
							next;
				}
				elsif(/^\$who (.+) (.+) (.+)/){
					if($1 eq $this->{login}){
						$this->{ip}=$3;
						%msg->{33}=$this->{ip};
						next;
					}
				}
				elsif(/^\$init (.+)/){
					my @a=split(/ /,$1);
					foreach  (@a) {
						if(/(.+)=(.+)/){
							$this->{$1}=$2;
						}
					}
					%msg->{-1}="$this->{type}:$this->{login}";
					next;
				}
				elsif($_=~/^\$msg> 11 (.*)/){	
						$wping=0;
						next;
				}
		$ws.="$_\n";	
			}
		if(%h or %msg or $this->{'guiw'}>10){
			&_writing($this,$ws,0);
			$this->{'guiw'}=0;
		}
		print "$times>$this->{run_wait_time} and $this->{'startok'}>0) or $times > $this->{start_wait_time}\n";
		$this->msg_to_gui(8) if(($times>$this->{run_wait_time} and $this->{'startok'}>0) or $times > $this->{start_wait_time});
		&_openfile($this,"close");
		$this->msg_to_socket(11,"ping soket!") if($wping);
	return (\%h ,\%msg);
	}
	else{
		print "else $this->{startok}==1 or $times > $this->{start_wait_time}\n";
		if($this->{startok}==1 or $times > $this->{start_wait_time}){
			$this->msg_to_gui(8);
		}
		return;
	}
}

sub getuserlist{	#	ǰ̨���� �����û��б� �����øú����� ����˽��ᷢ�� �����б�����ȡ�����µ��û��б���Ϣ���б���Ϣ���� ����˵� 3 ����Ϣ ����ǰ̨
	my $this=shift;
	my $group=shift;
	if($group eq undef){				#Ϊ�˺���ǰ�İ汾���ݣ��Դ���Ĳ������д���
		$group=$this->{'group'};		#���û�и�����Ҫ�û��б��������������$group����Ϊ��ϣ$this->{'group'}
	}
	$this->msg_to_socket(3,$group);
}

sub joingroup{		#	ǰ̨���� �ⲿ�������� �������� ������� ��������
	my ($this,$group)=@_;
	return if($group eq undef);
	$this->{'group'}=$group;
	$this->msg_to_socket(6,$group);
}
sub changelogin{	#�ı��¼��
	my ($this,$login)=@_;
	$this->msg_to_socket(5,$login);
}
sub exitgroup{
	my ($this,$group)=@_;
	$this->msg_to_socket(7,$group);
}
#-------------------------------------------------------------------------------------

sub updata{	#updata_programme
	my ($this,$have)=@_;
	&_writing($this,"\$VERSIONUPDATA:$have",1);
}
#-------------------------------------------------------------------------------------

sub quit{		#ǰ̨�����˳�ʱ���ô˺������Է��� ��Ϣ������� ʹ��رս��̡�
	my $this=shift;
    $this->msg_to_socket(8,"exit!");
	return 1;
}

sub msg_to_gui{		#����˺��� ������Ϣ��ǰ̨
	my ($this,$s,$msg)=@_;
	&_msg_to_gui($this,$s,$msg);
	print "msg_to_gui  $s $msg\n";
}

sub DESTROY{
    my $this=shift;
#	unlink($this->{openfile});
}

1;
__END__