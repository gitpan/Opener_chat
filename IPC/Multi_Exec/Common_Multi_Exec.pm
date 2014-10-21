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

sub _msg_to_gui{		#����˺��� ������Ϣ��ǰ̨
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

=h1  Э��˵����
1����������  $scanf name group data				=~/^\$scanf ([^\s]+) ([^\s]+) (.+)/        $1=data_from_names , $2=data
2���������ݣ�$print name send_string     		=~/^\$print ([^\s]+) (.+)/       	    $1=senddata_to_name, $2=data
3��ǰ̨���յ�����Ϣ��$msg< n string                     =~/^\$msg< (\d+) (.+)/                      $1=��Ϣ��ţ� $2��Ϣ˵�� 
    n=0    ����ʧ��                             $msg< 0 connect err!               
    n=1    ���ӳɹ�                             $msg< 1 socket connect ok!
    n=2    ��½�ɹ�                             $msg< 2 login ok!
    n=3    ����б�ɹ�                         $msg< 3 [..] 
    n=4    ��������Ͽ�                         $msg< 4 reboot...
    n=5    �������û�����ռ�� ���û�������      $msg< 5 name newname
    n=6    ���û���½                           $msg< 6 [..]
    n=7    �û��˳�������                       $msg< 7 [..]
    n=8    socket�����˳�                       $msg< 8 socket die close\t $msg
	n=9    ������������							$msg< 9 ""
	n=10   ��¼��������ʧ����Ϣ					$msg< 10 The nickname ��ls007�� is already in use, please to pick a new one.
    n=11   ping ˵�������̨������				$msg< 11 ping
	n=12   ��ͣ�Է���ping����˳����� ������ֵ  stop ok
	n=55   �������û�����						$msg< 55 [..]
    n=77   �û����߻��Ƴ�������					$msg< 77 [..]
	n=13   ����ĳһ���̳ɹ�					    $msg< 13 taskname
	n=14   ������perl����ʧ��					$msg< 14 taskname
	n=15   ���������Ϣ							$msg< 15 [0:���ӷ�����ʧ�ܣ�1�����°汾 2 û�з����°汾 3 �������]

4����̨�յ�����Ϣ��$msg> n string                     =~/^\$msg> (\d+) (.+)/          
	n=0		����
	n=1     ����                
	n=2     ����              
	n=3     ͨ�����������»�ȡ�����û��б�    
	n=4     ����
	n=5		�����û���
	n=6		��������
	n=7		�˳�ĳһ������ 
	n=8		ǰ̨�����˳�   						$msg> 8 exit now!
	n=11	ping ˵�������̨������				$msg> 11 ping
	n=12	��ͣ�Է���ping����˳����� ������ֵ stop ok
5������
$group:name={}		  �������б�				=~/^\$group:(.+)=\{(.+)\}/
$join name group	  �����û�����				=~/^\$join (.+) (.+)/
$quit name group	  ���û��˳�				=~/^\$quit (.+) (.*)/
$cname name	newname	  �û�����ռ�û������û�����=~/^\$cname (.+) *(.*)/
$cgroup oldgname newname	�������ض���		
$who $1 $2 $3		  �������û���¼��Ϣ  �û�������ԭʼ���û�����ip��ַ
$init $1			  ǰ̨��ʼ���û��� ��Ӧ������������͵���Ϣ

$VERSIONUPDATA:1/0 string	���°汾 1������и��� 0����Ҫ����
($shell@cmd&R# command)		���ݵ�������ʽ
=cut


=h2 ���Գ���
