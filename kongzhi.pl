#!/usr/bin/perl
use strict;
use IO::Socket;
use IO::Select;
use Socket;

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
               "sendbuffer" => "",
               "session" => "",
	           "command" => "",
	          };
####变量定义结束####
$variables->{"host"}=$ARGV[0] || '192.168.1.100';
$variables->{"port"}=$ARGV[1] || 10008;

print "$g->{display}->{file_kongzhi_programe_is_runing}！\n";

###SOCKET监听连接###
######SOCKET监听成功即远控成功######
$variables->{"sock"} = IO::Socket::INET->new(  Listen     => 20,
                                               LocalPort  => $variables->{"port"},
								               Proto =>'TCP',
                                               Reuse => 1)
   or die "Can't create listening socket: $!\n";
print "SOCKET$g->{display}->{file_kongzhi_connect_ok}。。。\n";
$variables->{"session"} = $variables->{"sock"}->accept();
$variables->{"select"}=IO::Select->new($variables->{"session"});
print "$g->{display}->{file_kongzhi_send_cmd}>";

while($variables->{"session"}){
#循环处理部分
$variables->{"message"}=<STDIN>;
if($variables->{"message"} eq "\n"){
	print "$g->{display}->{file_kongzhi_send_cmd}>";	
	next;
}
$variables->{"session"}->send("$variables->{\"message\"}");
#my $info=$variables->{"command"};
$variables->{"session"}->recv($variables->{"command"},10000,0);

if($variables->{"command"}){
if($variables->{"command"} eq 'cls'){system("cls");}
if($variables->{"command"} eq 'exit'){close($variables->{"sock"});exit(1);}
print "$variables->{\"command\"}\n$g->{display}->{file_kongzhi_send_cmd}>";
}

}
close($variables->{"sock"});













 