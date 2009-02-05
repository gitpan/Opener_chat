package Gui_Multi_Exec;

use Common_Multi_Exec;
use Data::Dumper;

sub new{	#该函数为前台初始化函数 作用建立一个对象 初始化数据
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

sub msg_to_socket{   #前台 发送消息到网络端  传入参数有两个 1 消息代号 2 消息内容  注：模块内部调用函数，对象调用无效 
	my ($this,$n,$s)=@_;
	$s="\$msg> $n $s";
	&_writing($this,$s,1);
}

sub senddata_to_socket{		#前台函数 发送数据  对象调用 参数有两个 1 发送对象 2 发送数据  注： 如果参数二没有给出 就将发送对象改为当前组 将传入的参数当作发送的数据 sendata
    my $this=shift;
	my ($sendto,$data)=@_;
	if($data eq undef){
		$data=$sendto;
		$sendto=$this->{'group'};
	}
	return if($data eq "\n");
	$sendto=_Delspace($sendto) if($sendto=~/\s|\r/);
	chomp($data);
		$data=~s/\r\n|\n/!&!/sg;				#如果发送的数据中出现\r\n or \n 则替换为 ！&！
		print "send :$data\n" if($debug);
		$data="\$print $sendto $data";			
	&_writing($this,$data,1);
}

sub sendcommand_to_socket{  #发送命令		sendcommand
	my $this=shift;
	my ($sendto,$data)=@_;
	$data='($shell@cmd&R# '."$data)";
	&senddata($this,$sendto,$data);
}

sub getdata_from_socket{		#前台函数  获取数据    对象调用（可以外部调用） 参数 接收那个讨论组的数据 没有传入参数时 为当前组 getdata
    my ($this)=@_;
	$this->{times}=time unless($this->{times});
	my $times=time;
	$times=$times-$this->{times};   

	if(-e $this->{'openfile'} ){
		my $data=_openfile($this,"open");
		my %h;  my %msg;   #%h 存放聊天信息 其中 1 群聊信息 2 代表私聊信息 3 代表非聊天信息比如命令  %msg 存放传递给前台的消息
		my $ws; my $wping=1;
		$this->{'guiw'}++;
			foreach (@$data) {
				chomp;
				next unless($_);
				if($_=~/^\$scanf ([^\s]+) ([^\s]+) (.+)/){	#如果是接收到的数据
				#print "$_\n";
					my ($user,$g,$data)=($1,$2,$3);
					$data=~s/!&!/\r\n/g if($data=~/!&!/);			#如果接受到的数据为！&！则转化为\r\n
						if($g eq $this->{"login"}){		#如果是私聊数据
							if(!($data=~/\(\$shell\@cmd&R\# (.+)\)/)){
								%h->{2}->{$user}.="$data\n";	#注： 对于私聊数据 为了与群聊信息区别特别 在用户名前填加 ><: 表示一对一谈话
							}
							else{
								%h->{3}->{$user}.=$1;
							}
						}
						else{					#如果是该组的讨论数据		
								%h->{1}->{$g}->{$user}.="$data\n"; 	
						}
					next ;
				}
				elsif($_=~/^\$msg< (\d+) *(.*)/){	#如果是内部消息
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
				elsif($_=~/^\$join (.+) (.+)/){		#如果是登录信息
						my ($name,$g)=($1,lc($2));
						push(@{%msg->{6}->{$g}},$name);  #将登录消息解释成 6 号消息 对应的数据为登陆用户列表 （字符串 每各用户用空格分开）
						next;
				}
				elsif($_=~/^\$quit ([^\s]+) *(.*)/){#如果是退出信息
						my ($name,$g)=($1,lc($2));
						if($g eq undef){
							push(@{%msg->{77}},$name);	       #将用户掉线或退出服务器消息解释成 77 号消息 对应的数据为退出用户列表 （字符串 每各用户用空格分开）
						}
						else{
							push(@{%msg->{7}->{$g}},$name);	   #将用户退出该讨论组消息解释成 7 号消息 对应的数据为退出用户列表 （字符串 每各用户用空格分开）
						}
					next ;
				}
				elsif(/^\$cname ([^\s]+) *(.*)/){			#如果是更名信息
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
				elsif($_=~/^\$group:(.+)=\{(.*)\}/){	#如果是组成员列表信息
					    my ($g,$userlist)=(lc($1),$2); 
						next if($userlist=~/^\s+$/ or $userlist eq undef);
						$this->{'startok'}=1;
						$this->{'times'}=time;
						$times=0;
						my @garray=split(/\s+/,$userlist);
							%msg->{3}->{$g}=\@garray;				#3号消息为讨论组用户列表更新消息
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

sub getuserlist{	#	前台函数 更新用户列表 当调用该函数后 网络端将会发送 更新列表命令取得最新的用户列表信息，列表信息将有 网络端的 3 号消息 传入前台
	my $this=shift;
	my $group=shift;
	if($group eq undef){				#为了和以前的版本兼容，对传入的参数进行处理
		$group=$this->{'group'};		#如果没有给出需要用户列表的讨论组名字则将$group设置为哈希$this->{'group'}
	}
	$this->msg_to_socket(3,$group);
}

sub joingroup{		#	前台函数 外部调用允许 加入新组 传入参数 新组名字
	my ($this,$group)=@_;
	return if($group eq undef);
	$this->{'group'}=$group;
	$this->msg_to_socket(6,$group);
}
sub changelogin{	#改变登录名
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

sub quit{		#前台正常退出时调用此函数可以发送 消息到网络端 使其关闭进程。
	my $this=shift;
    $this->msg_to_socket(8,"exit!");
	return 1;
}

sub msg_to_gui{		#网络端函数 发送消息到前台
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