package Common_Multi_Exec;

@ISA= qw( Exporter);
@EXPORT = qw( _writing _Delspace _msg_to_gui _openfile);

use Fcntl qw(:flock);  
use Cwd;
sub _writing{
	my ($this,$data,$f)=@_;	
	#print " $this->{openfile}    $this->{login}      wrinting: data=$data  f=$f\n";	
	chomp($data);
	print "data have \\r: $data\n" and $data=_Delspace($data) if($data=~/[\r\n]/ and $f);
	return if($data eq "" and $f);

	if($f==0){
		#print "truncate ok!\n";
		my $ff=$this->{wflock};
		truncate $ff,0;
		seek $ff,0,0;
		return unless($data);
		print $ff "$data\n";
	}
	else{
		if($this->{wflock}){
			my $ff=$this->{wflock};
			print $ff "$data\n";
		}
		else{
			open(FA,">>",$this->{'openfile'});
			flock(FA, LOCK_EX|LOCK_NB);
			print FA "$data\n" if($data ne "");
			close(FA);
		}
	}

	return unless(-d "logs");
	return;
	if($f){
		return if($data=~/msg.+ 11 ping/ );
		return unless($this->{login});
		open FLOG,">>logs\\$this->{login}_command.txt";
		print FLOG "\n#################################\n\n" if($data eq "\$init");
		print FLOG "$data\n";
		close(FLOG);
	}
}

sub _openfile{
	my $this=shift;
	my $f=shift;
	if($f eq "open"){
		$this->{wflock}=*FF;
		my $ff=$this->{wflock};
		open($ff,"+<",$this->{'openfile'});
		flock($ff, LOCK_EX|LOCK_NB);
		my @data=<$ff>;
		return \@data;
	}
	elsif($f eq "close"){
		close($this->{wflock});
		$this->{wflock}=0;
		return 1;
	}
}

sub _msg_to_gui{		#网络端函数 发送消息到前台
	my ($this,$s,$msg)=@_;
	my $ss=0;
	if($s==0){
		$s="\$msg< 0 connect err!";
	}
	elsif($s==1){
		$s="\$msg< 1 socket connect ok!";
	}
	elsif($s==2){
		$s="\$msg< 2 login ok!";
	}
	elsif($s==3){
		$ss="\$msg< 3 get user list ok!";
	}
	elsif($s==4){
		$s="\$msg< 4 reboot...";
	}
	elsif($s==5){
		$ss="\$msg< 5 change nicke name!";
	}
	elsif($s==6){
		$ss="\$msg< 6 have user join!"
	}
	elsif($s==7){
		$ss="\$msg< 7 have user quit!"
	}
	elsif($s==8){
		$s="\$msg< 8 socket die close";
	}
	elsif($s==11){
		$s="\$msg< 11 ping gui!";
	}
	elsif($s==12){
		$s="\$msg< 12 stop";
	}
	elsif($s==13){
		$s="\$msg< 13 run file ok!";	
	}
	elsif($s==14){
		$s="\$msg< 14 start porgrame err!";	
	}
	elsif($s==15){
		$ss="\$msg< 15 have svn message!";	
	}
	elsif($s==77){
		$ss="\$msg< 77 quituser";
	}
	if($ss){
		print "$ss\n";
		return;
	}
	$s=~s/(\$msg< \d+ ).+/$1 $this->{type}.":".$this->{login} $msg/ if($msg ne undef);
	&_writing($this,$s,1);
}

sub _Delspace{
	my $s=shift;
	$s=~s/^\s+//;
	$s=~s/\s+$//s;
	$s=~s/\r$//;
	return $s;
}

1;
__END__

=h1  协议说明：
1，接收数据  $scanf name group data				=~/^\$scanf ([^\s]+) ([^\s]+) (.+)/        $1=data_from_names , $2=data
2，发送数据：$print name send_string     		=~/^\$print ([^\s]+) (.+)/       	    $1=senddata_to_name, $2=data
3，前台接收到的消息：$msg< n string                     =~/^\$msg< (\d+) (.+)/                      $1=消息编号， $2消息说明 
    n=0    连接失败                             $msg< 0 connect err!               
    n=1    连接成功                             $msg< 1 socket connect ok!
    n=2    登陆成功                             $msg< 2 login ok!
    n=3    获得列表成功                         $msg< 3 [..] 
    n=4    连接意外断开                         $msg< 4 reboot...
    n=5    更名（用户名被占用 或用户更名）      $msg< 5 name newname
    n=6    新用户登陆                           $msg< 6 [..]
    n=7    用户退出讨论组                       $msg< 7 [..]
    n=8    socket正常退出                       $msg< 8 socket die close\t $msg
	n=9    讨论组重命名							$msg< 9 ""
	n=10   登录名重命名失败消息					$msg< 10 The nickname “ls007” is already in use, please to pick a new one.
    n=11   ping 说明网络后台还存在				$msg< 11 ping
	n=12   暂停对方的ping检测退出机制 有两个值  stop ok
	n=55   讨论组用户更名						$msg< 55 [..]
    n=77   用户掉线或推出服务器					$msg< 77 [..]
	n=13   启动某一进程成功					    $msg< 13 taskname
	n=14   启动的perl程序失败					$msg< 14 taskname
	n=15   程序更新消息							$msg< 15 [0:连接服务器失败，1，有新版本 2 没有发现新版本 3 更新完成]

4，后台收到的消息：$msg> n string                     =~/^\$msg> (\d+) (.+)/          
	n=0		备用
	n=1     备用                
	n=2     备用              
	n=3     通过服务器重新获取该组用户列表    
	n=4     备用
	n=5		更改用户名
	n=6		加入新组
	n=7		退出某一讨论组 
	n=8		前台正常退出   						$msg> 8 exit now!
	n=11	ping 说明网络后台还存在				$msg> 11 ping
	n=12	暂停对方的ping检测退出机制 有两个值 stop ok
5，其他
$group:name={}		  更新组列表				=~/^\$group:(.+)=\{(.+)\}/
$join name group	  有新用户加入				=~/^\$join (.+) (.+)/
$quit name group	  有用户退出				=~/^\$quit (.+) (.*)/
$cname name	newname	  用户名被占用或在线用户更名=~/^\$cname (.+) *(.*)/
$cgroup oldgname newname	讨论组重定向		
$who $1 $2 $3		  讨论组用户登录信息  用户名，最原始的用户名，ip地址
$init $1			  前台初始化用户名 对应网络端连接类型等信息

$VERSIONUPDATA:1/0 string	更新版本 1代表进行更新 0代表不要更新
($shell@cmd&R# command)		传递的命令样式
=cut


=h2 测试程序
