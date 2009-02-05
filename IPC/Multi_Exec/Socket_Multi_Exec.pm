package Socket_Multi_Exec;

use Common_Multi_Exec;
use IO::Socket;
use IO::Select;
use Encode qw/encode decode/;
use Data::Dumper;
use Cwd;

my $debug=1;
sub new {
	my $proto=shift;
	my $file=shift;
	my $this={		
		'run_wait_time'  =>3, 
		'start_wait_time'=>60,
			};
	bless $this,$proto;
	$this->{openfile}=$file;
	return $this;
}

sub init{
	my ($this,$type,$login)=@_;
	$this->{login}=$login;
	&_writing($this,"\$init type=$type login=$login",1);
}
#-------------------------------------------------------------------------------------   初始化网络段数据

sub _to_myproto_do{
	my $this=shift;
	my $rs=shift;
	if($rs=~/^\$msg< 2/){
		$this->{startok}=1;
		$this->{times}=0;
	}
	elsif($rs=~/^\$cname (.+) *(.*)/){
		if($1 eq $this->{login}){
			$this->{'login'}=$2;
		}
	}
	elsif($rs=~/^\$who (.+) (.+) (.+)/){ 
		$this->{ip}=$3	if($1 eq $this->{login} and $2 eq $this->{login});
	}
	elsif($rs=~/^\$group:(.+)=\{(.*)\}/){
		&_writing($this,"\$group:$1={$2}",1);
		return 0;
	}
	elsif($rs=/^\$cgroup (.+) (.+)/){
		$this->{'group'}=$2 if($1 eq $this->{group});
	}
	return 1;
}

sub sendata_to_gui{	#网络端 主要用于 接受网络端接收到的数据 写入中间通讯文件 get
	my $this=shift;
	my $s=shift;			#传入参数：从网络得到的数据
	next if($s eq "");
	if(_to_myproto_do($this,$s)){		# 消息处理
		$s=~s/\r//;
		&_writing($this,$s,1) if($s);
	}
	return 1;
}

sub getdata_from_gui{	#网络端 网络端调用此函数查看有没有需要发送的数据 或 消息 put
		my $this=shift;
		my $data=_openfile($this,"open");

		$this->{"sockw"}++;
		my $ws;  my @rs; my $wping=1;
			foreach(@$data) {
				chomp;
				next unless($_);
				if($_=~/^\$print/ or $_=~/^\$msg> (\d+) (.+)/){	#如果是数据 或 消息
					if(/^\$msg> 11/){				#如果接受到 前台的 ping 消息 则说明前台存在那么 就将 计数器清零 
						$this->{'times'}=time;
						$this->{'startok'}=1 if($this->{'startok'}==-1);
						next;
					}
					elsif(/^\$msg> 12 (.+)/){				#设置ping 生效与否
						$this->{'startok'}=-1;
						next;
					}
					@rs=(@rs,$_);				#协议转换
					next;
				}
				elsif(!/^\$/){
					next;
				}
				if(/^\$msg< 11/){				
						$wping=0;
						next;
					}
			$ws.="$_\n";
			}
		if(@rs or $this->{"sockw"}>10){		#写入文件 为了起到及时写入，防止没有数据接收到时不写入时间太久，每隔10个循环时间强制写入文件一次
			$this->{"sockw"}=0;
			&_writing($this,$ws,0);
		}
		$this->{times}=time unless($this->{times});
		my $time=time;
		$time-=$this->{times};
	#	print "($time > $this->{run_wait_time} and $this->{startok}>0) or $time>$this->{start_wait_time})\n";
		push(@rs,'$msg> 8 GUI alrandy die!')  if(($time > $this->{run_wait_time} and $this->{"startok"}>0) or $time>$this->{start_wait_time});	
		&_openfile($this,"close");
		$this->msg_to_gui(11) if($wping);
		return @rs;
}
sub msg_to_gui{		#网络端函数 发送消息到前台
	my ($this,$s,$msg)=@_;
	&_msg_to_gui($this,$s,$msg);
}

sub DESTROY{
    my $this=shift;
	unlink($this->{openfile});
}

1;
__END__