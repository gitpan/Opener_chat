use Win32::GUI;

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

print "svnupdata programe.\n";
$openfile=$ARGV[0];
print &svnauto();

my @list;  my $time;
sub svnauto{
#	use LWP::Simple;
	use IO::Socket;
	my $host="192.168.1.220";
	my $page="ircVERSION.html";
#	my $url="http://$host//$page";
	my $VERSION=1.1;
	# 取得远程服务器的最新版本号

	my $sock=new IO::Socket::INET(
						PeerAddr =>$host,
						PeerPort=>80,
						Proto	 =>"tcp",
						Timeout  =>5) or &svnedit(0) and return "connect err";
print $sock "GET /$page HTTP/1.0 \n Accept: */* \n Host: $host\n\n";
my $content;
while(<$sock>){last if($_=~/Content-Type:/)}
while(<$sock>){$content.=$_; print "$_\n";}
close($sock);
#	my $content = get($url); 
	$content=~s/VERSION:([\d\.]+)//;
	my $nowsvn=$1;
	unless($nowsvn){
		&svnedit(0,"no find svn page!"); 
		return "no find svn";
	}
	@list=grep /\w/, sort split(/\n/,$content);
	# 分析是不是更新
	if($nowsvn >= $VERSION ){
		svnedit(1,$nowsvn);
		while(1){
			last if(&getsvnok());
			$time++;
			sleep(1);
			print "$time\n";
		}	
	}
	else{
		svnedit(2);
	}
exit;
}

sub getsvnok{
			open (F,$openfile);
			my @array=<F>;
			close(F);
			foreach  (@array) {
				if(/^\$VERSIONUPDATA:(.+)/){
					unlink ($openfile);
					if($1=~/^1/){
						&getnewfile(@list);	
						svnedit(3);
						return 1;
					}
					elsif($1=~/^0/){
						#print "取消更新 更新程序退出";
						return 2;
					}
				}
				elsif(/^\$msg> 8 .+/){
					exit;
				}
			}
			return 0;
}

sub svnedit{
	my ($n,$ms)=@_;
	my $s;
	if($n==0){
		$s="\$msg< 15 0 conecet err!";
	}
	elsif($n==1){
		$s="\$msg< 15 1 have new svn!";
	}
	elsif($n==2){
		$s="\$msg< 15 1 no find new svn!";
	}
	elsif($n==3){
		$s="\$msg< 15 3 updata ok!";
	}
	if($ms){
		$s="\$msg< 15 $n $ms";
	}
	&writing($s,1);
}

sub writing{	# 公共函数  将数据写入交换文件 参数有两个 1 写入的数据 2   写入方式 （0）为覆盖写入（1）为添加方式
	my $data=shift;
	my $f=shift;
	my $file;
	chomp($data);

	return if($data eq "" and $f);
	$file=$f?">>$openfile":">$openfile";
		open(FF,$file) or die "open file err! $data\n";
		print FF "$data\n" if($data ne "");
		close(FF);
#	if($f){
#		return if($data=~/11/);
#		open F,">>command.txt";
#		print F "$data\n";
#		close(F);
#	}
}

sub getnewfile{
	my @filelist=@_;
	use LWP::Simple;
	my $dir="http://192.168.1.220//test//";
	my $winf = new Win32::GUI::Window (
		-title    => "$g->{display}->{file_svnupdata_text}...",
	-hasminimize  =>0,
	-hasmaximize  =>0,
		-sizable  =>0,
		-topmost  =>1,
	    -size     => [350, 60],
	) or die "new Window";
	my $font1=Win32::GUI::Font->new(
		-size=>12,
	);
	$winf->AddLabel(
	-name => "online",
     -pos => [ 10,10],
    -size => [350,60],
    -text =>"",
	-font=>$font1,
-foreground=>0xff0000,
    );
	$winf->Center();
	$winf->Show();
my $i;	
	foreach my $url (@filelist) {
			$i++;
			$url=$dir.$url unless($url=~/^http/);
			my $content = get($url) or die "not get data!";
			$url=~/.+[\\|\/](.+)/;
			loadwindow($1,$i);
			next;
			open(F,">$1");
			binmode F  unless($url=~/\.txt$/);
			print F $content;
			close(F);
	}
$winf->Hide;
sub loadwindow{
	my ($file,$index)=@_;
	my $sum=@filelist;
	#print "升级: $file\n";
	select(undef,undef,undef,0.1);
	$winf->online->Text("$g->{display}->{file_svnupdata_text}: $index/$sum：$file");
}
}