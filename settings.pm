#############################irc配置模块################################
package settings;
#use strict;
#use warnings;
use Win32::GUI qw(MB_ICONINFORMATION MB_OK);
#use main;
########################################################################
#       irc配置窗口界面调用函数                                        #
########################################################################
my $g={};
sub create_win{
my $i=1;
my $A = new Win32::GUI::AcceleratorTable(
     "Tab" => sub { settings::changeSetFocus(); },
	"Return" => sub { settings::hip_enter(); },
 );
my $icon2 = new Win32::GUI::Icon('res\\ice.ico');
my $class2 = new Win32::GUI::Class(
       -name => "setting",
       -icon => $icon2,
);
my $win = Win32::GUI::Window->new (
    -name   => 'mainWin3',
    -title =>"IRC".$g->{display}->{menu_edit},
    -size   => [350, 220],
	-accel => $A,
    -hasmaximize => 0,
    -controlbox =>0,
	-sizable => 0,
    -resizable => 0,
	-class=>$class2,
    );

$win->Center();

$win->AddGroupbox(
    -name  => 'GB',
    -title => "IRC$g->{display}->{menu_edit}",
    -pos   => [20,10],
    -size  => [300, 160],
);




$win->AddTextfield (
    -name    => 'CB1',
    -pos => [ 45, 30 ],
    -size => [ 180, 20 ],
	-prompt => [ "$g->{display}->{label5_ircser}:",50 ],
	-readonly => 1,
    ); 



$win->AddTextfield (
    -name    => 'CB2',
    -pos => [ 45, 50 ],
    -size => [ 180, 20 ],
	-prompt => [ "$g->{display}->{button1_port}:",50 ],
	-text => "6667",
	-number => 1,
	-readonly => 1,
    ); 


$win->AddTextfield (
    -name    => 'CB3',
    -pos => [ 45, 70 ],
    -size => [ 180, 20 ],
	-prompt => [ "$g->{display}->{label6_channel}:",50 ],
	-readonly => 1,
    ); 



$win->AddTextfield (
    -name    => 'CB4',
    -pos => [ 45, 90 ],
    -size => [ 180, 20 ],
	-prompt => [ "$g->{display}->{label4_nickname}:",50 ],
    ); 

my $buttonexit=$win->AddButton(
    -pos => [ 250, 130 ],
    -name   => "exitbutton",
    -size => [ 40, 20 ],
    -title => $g->{display}->{menu_cancel},
	-onClick => 'settings::hidewindow',
    );
my $buttonok=$win->AddButton(
    -pos => [ 60, 130 ],
    -name   => "ok",
    -size => [ 40, 20 ],
    -title => $g->{display}->{menu_ok},
	-onClick => 'settings::settingfinish',
    );
#sub mainWin_Terminate {
#	$win->Hide();
##	return -1;
#}
#sub mainWin_Minimize {
#    $win->Disable();
#    $win->Hide();
#    Win32::GUI::Hide($DOS); #hide the DOS console window
#    return 1;
#}


###########调试用隐藏DOS窗口######
#my ($DOS) = Win32::GUI::GetPerlWindow();
#Win32::GUI::Hide($DOS);
sub show(){
	 #显示窗体
	if(-e "settings.ini"){my @ini=getini();
		#print @ini;
		if($ini[0]){$win->CB1->Text($ini[0]);}
		if($ini[1]){$win->CB2->Text($ini[1]);}
		if($ini[2]){$win->CB3->Text($ini[2]);}
		if($ini[3]){$win->CB4->Text($ini[3]);}
	}
	$win->CB1->SetFocus();
	if($win->CB1->Text()=~/^irc.freenode.net$/){$win->CB1->Text("$g->{display}->{label5_ircser_text}");}
	if($win->CB3->Text()=~/^\#opener(.*)/){$win->CB3->Text("$g->{display}->{label6_channel_text}$1");}
	$win->Show ();

	$A;
	#$win->DoModal();
	#Win32::GUI::Dialog();
}


sub hidewindow {
	$win->Hide ();
	return 1;
}

sub settingfinish {
	##打开或建立配置文件##
	open(SETFILE,">settings.ini");
		if ($win->CB1->Text()=~m/白帽子聊天服务器/) {
		print SETFILE "Server=irc.freenode.net\n";
		print SETFILE "Port=6667\n";
	}else{
		print SETFILE "Server=".$win->CB1->Text()."\n";
		print SETFILE "Port=".$win->CB2->Text()."\n";
	}
	if ($win->CB3->Text()=~m/公共聊天频道(.*)/) {
		print SETFILE "Channel=#opener$1\n";
	}else{
		print SETFILE "Channel=".$win->CB3->Text()."\n";
	}
	print SETFILE "Nickname=".$win->CB4->Text()."\n";
	close SETFILE;
	Win32::GUI::MessageBox(0,
     "$g->{display}->{menu_edit_ok}!",
     "$g->{display}->{menu_edit}",
	  MB_ICONINFORMATION | MB_OK,
  );
	$win->Hide();
	return 1;
	#return -1;
}


sub getini{
	my @seting;
	open(INIFILE,"settings.ini");
	while(<INIFILE>){
		chomp $_;
		$seting[0]=$1 if($_=~/Server=(\S+)/);
		$seting[1]=$1 if($_=~/Port=(\S+)/);
		$seting[2]=$1 if($_=~/Channel=(\S+)/);
		$seting[3]=$1 if($_=~/Nickname=(\S+)/);
	}
	close INIFILE;
	return @seting;
}


sub changeSetFocus{
	while(1){
	if($i==0){$win->CB1->SetFocus();}
	if($i==1){$win->CB2->SetFocus();}
	if($i==2){$win->CB3->SetFocus();}
	if($i==3){$win->CB4->SetFocus();}
	if($i==4){$win->ok->SetFocus();}
	if($i==5){$win->exitbutton->SetFocus();}
	$i++;
	if($i==6){$i=0;}
	last;
	}

}

sub hip_enter{
if($i==5){settings::settingfinish;}
if($i==0){settings::hidewindow;}
}
}

sub new(){
	my $self=shift;
	my $dis=shift;
	my $this = {};
$g->{display}=$dis;
	bless $this;
	&create_win();
	return $this;
}

1;
__END__
