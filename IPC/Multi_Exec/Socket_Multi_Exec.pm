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
#-------------------------------------------------------------------------------------   ��ʼ�����������

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

sub sendata_to_gui{	#����� ��Ҫ���� ��������˽��յ������� д���м�ͨѶ�ļ� get
	my $this=shift;
	my $s=shift;			#���������������õ�������
	next if($s eq "");
	if(_to_myproto_do($this,$s)){		# ��Ϣ����
		$s=~s/\r//;
		&_writing($this,$s,1) if($s);
	}
	return 1;
}

sub getdata_from_gui{	#����� ����˵��ô˺����鿴��û����Ҫ���͵����� �� ��Ϣ put
		my $this=shift;
		my $data=_openfile($this,"open");

		$this->{"sockw"}++;
		my $ws;  my @rs; my $wping=1;
			foreach(@$data) {
				chomp;
				next unless($_);
				if($_=~/^\$print/ or $_=~/^\$msg> (\d+) (.+)/){	#��������� �� ��Ϣ
					if(/^\$msg> 11/){				#������ܵ� ǰ̨�� ping ��Ϣ ��˵��ǰ̨������ô �ͽ� ���������� 
						$this->{'times'}=time;
						$this->{'startok'}=1 if($this->{'startok'}==-1);
						next;
					}
					elsif(/^\$msg> 12 (.+)/){				#����ping ��Ч���
						$this->{'startok'}=-1;
						next;
					}
					@rs=(@rs,$_);				#Э��ת��
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
		if(@rs or $this->{"sockw"}>10){		#д���ļ� Ϊ���𵽼�ʱд�룬��ֹû�����ݽ��յ�ʱ��д��ʱ��̫�ã�ÿ��10��ѭ��ʱ��ǿ��д���ļ�һ��
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
sub msg_to_gui{		#����˺��� ������Ϣ��ǰ̨
	my ($this,$s,$msg)=@_;
	&_msg_to_gui($this,$s,$msg);
}

sub DESTROY{
    my $this=shift;
	unlink($this->{openfile});
}

1;
__END__