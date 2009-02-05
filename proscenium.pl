use strict;
use Win32;
use Win32::GUI qw(MB_OK HWND_TOP SWP_SHOWWINDOW SWP_NOMOVE SWP_NOSIZE SWP_SHOWWINDOW MB_YESNOCANCEL MB_YESNO);
use warnings;
use lib "IPC/Multi_Exec";
use Gui_Multi_Exec;
use chat;
use remote_control;
use change;
use public;

use Data::Dumper;

my $g={
		debug=>'0',
		default_language=>'chinese',
		select_RichEdit=>"",
		tv_Selection=>"",
		run_sub_process=>{},
		private_chat_windows=>{},
		command=>{
			'cmd'=>0,
			'admin_name'=>"",
			'local_dos_port'=>10000,
			'local_vnc_port'=>15500,
			'tag1' =>0,
			'tag2' =>0,
		},
		tmp=>{
			startok=>0,
			privatew=>[],
		},
		switch=>{ 
			'msn'  => 1,
			'mautorun' => 0,
			'msound'   => 1,
			'mballoon' => 1,
			'mcmd'	   => 0,
			'mvnc'	   => 0,
			'closef'   =>-1,
		    'changeicon'=> 1,
		},
		userlist=>{},
		RichEdit=>{},
		setting=>{},
	};
my $api=Gui_Multi_Exec->new();

&getini();
&get_language_text();
sub get_language_text{
	my $language_file;
	if ($g->{switch}->{language}) {
		$language_file="language\\".$g->{switch}->{language};
		if (-f $language_file) {
			parse_language_file($language_file);
		}else{
			$language_file="language\\".$g->{default_language};
			parse_language_file($language_file);
		}
	}else{
		$language_file="language\\".$g->{default_language};
		parse_language_file($language_file);
	}
}

sub parse_language_file{
	my $l_file=shift;
	open(F,"$l_file");
	while(<F>){
		if(/\{(.+)\}=(.+)/){
			$g->{display}->{$1}=$2;
		}
	}
	close(F);
}

my $Menu = Win32::GUI::Menu->new(
	"(&E)$g->{display}->{menu_edit}"                => "Edit",
	" > (&E)$g->{display}->{menu_edit}"             => { -name => "Edit1",    -onClick => \&setini },
	" > (&C)$g->{display}->{menu_cls}"              => {                      -onClick =>\&cls_richbox},
	" > (&N)$g->{display}->{menu_chage_nick}"       => { -name => 'chage_nick',-onClick => \&chage_nick },
    " > -"                    => 0,
	" > (&S)$g->{display}->{menu_sound}"            => { -name => 'sound', -onClick => \&sound_ok},
	" > (&Q)$g->{display}->{menu_balloon}"          => { -name => 'qq', -onClick => \&balloon_ok},
	" > (&L)$g->{display}->{menu_savelog}"	        => { -name =>'sn'     ,   -onClick =>\&savelogs_ok},
    " > -"                    => 0,
	" > (&G)$g->{display}->{menu_updatauser}"       => { -name =>'menu_updatauser' , -onClick => sub {} },
	" > (&M)$g->{display}->{menu_hidwindow}"	    => { -onClick =>\&hidwindow},
	" > (&X)$g->{display}->{menu_quit}"			    => {   -onClick =>\&exit_win },
	"(&U)$g->{display}->{menu_refresh}"             => "Refresh",
	" > (&F)$g->{display}->{menu_refprogram}"       => { -name => "Ref",      -onClick => \&svn },
	"(&H)$g->{display}->{menu_help}"                => "Help",
	" > (&S)$g->{display}->{menu_doshelp}"			=> { -name => "cmdservices",  -onClick => \&dos_connect},
	" > (&V)$g->{display}->{menu_vnchelp}"			=> { -name => 'vnc'   ,   -onClick => \&vnc_connect },
	" > (&A)$g->{display}->{menu_about}"            => { -name => "About",    -onClick => \&IRC_OnAbout },
);

$Menu->{chage_nick}->Enabled(0);
$Menu->{menu_updatauser}->Enabled(0);
$g->{window}->{mainmenu}=$Menu;

my $Menus = Win32::GUI::Menu->new(
	"Item Menu"          => "Item",
	"> $g->{display}->{menu_about}"			=> { -name => "AboutLabel",  -onClick => \&IRC_OnAbout },
	"> $g->{display}->{menu_autorun}"		=> { -name => "autorun",     -onClick =>'autorun_part' },
	"> $g->{display}->{menu_hidwindow}"		=>{-name =>	 "mint"	,		-onClick =>\&hidwindow},
	"> $g->{display}->{menu_quit}"			=> { -name => "Exitprogram",  -onClick => \&exit_win},
);

my $icon = new Win32::GUI::Icon('res\ice.ico');
my $iconchange = new Win32::GUI::Icon('res\icechange.ico');
my $w_class = new Win32::GUI::Class(
       -name => "Perlirc",
       -icon => $icon,
);

my $mainWin = new Win32::GUI::Window (
    -name     => "IRC",
    -title    => $g->{display}->{form1_title},
    #-pos      => [100, 100],
	-menu     => $Menu,
    -size     => [800, 580],
	-toolwindow => 0,
	-class  => $w_class,
) or die "new Window";

$g->{window}->{mainwin}=$mainWin;

my $Edit=$mainWin->AddRichEdit(
    -name    => "logs",
    -pos   => [170,20],
    -size  => [840,640],
	-vscroll => 1,
	-autovscroll => 1,
	-keepselection => 1,
	-readonly => 1,
	-multiline     => 1 ,
#	-visible =>0,
);


$mainWin->AddLabel(
	-name => "online",
    -pos => [ 10, 5],
    -size => [ 180, 15 ],
    -text => "$g->{display}->{label1_onlineuser}:",
    );

$mainWin->AddLabel(
	-name => "info",
    -pos => [ 460, 5],
    -size => [ 200, 15 ],
    -text => "$g->{display}->{label2_servicestitle}:",
    );

$mainWin->AddLabel(
	-name => "serv",
    -pos => [ 520, 5],
    -size => [ 200, 15 ],
    -text => "$g->{display}->{label3_servicesinfo1}",
    );

$mainWin->AddTreeView(
    -name        => 'list',
    -pos     => [10,20],
    -size    => [150,650],
    -rootlines   => 1,
    -lines       => 1,
    -buttons     => 1,
    -onNodeClick => \&treeview_dispInfo,
    -onDblClick  => \&list_DblClick,
) or die "new TreeView";

$mainWin->AddLabel(
    -name => 'nickname',
    -pos => [10,670],
    -size => [150,20],
	-text => "$g->{display}->{label4_nickname}:",
);

$mainWin->AddLabel(
    -name => 'IRCSer',
    -pos => [10,690],
    -size => [250,20],
	-text => "$g->{display}->{label5_ircser}:",
);

$mainWin->AddLabel(
    -name => 'Channel',
    -pos => [10,710],
    -size => [150,20],
	-text => "$g->{display}->{label6_channel}:",
);

$mainWin->AddTextfield(
	-name => "myText",
    -pos => [170,670],
	-multiline => 1,
	-vscroll   => 1,
	-autovscroll => 1,
	-size => [780,50],
);

$mainWin->AddButton (
    -name    => "sendText",
    -pos     => [960,680],
    -text    => $g->{display}->{button1_sendtext},
    -default => 1,
    -tabstop => 1,
    -group   => 1,
	-ok      => 1,
	-size => [40,20],
    -onClick  => 'send_Text',      
);


my $ni = $mainWin->AddNotifyIcon(
            -name => "NI",
			-icon => $icon,
			-tip => $g->{display}->{notifyicon1_tip},
			-balloon         => $g->{switch}->{mballoon},
			-balloon_tip     => $g->{display}->{notifyicon1_texttip},
			-balloon_title   => "$g->{display}->{notifyicon1_texttitle}",
			-balloon_timeout => "1000",
			-balloon_icon => 'info',
			-onClick => sub {
							if($g->{command}->{'tag2'}==1){	   #打开私聊窗体
								$g->{command}->{'tag2'}=0;
								if(@{$g->{tmp}->{privatew}}){
									my $name=shift @{$g->{tmp}->{privatew}};
									$g->{private_chat_windows}->{$name}->show();
								}
								if(@{$g->{tmp}->{privatew}}){
									$g->{command}->{'tag2'}=1;
								}
							}
							else{						   # 打开共聊窗体
								if($g->{command}->{'tag1'}==1){ # 如果存在共聊信息 停止煽动的图标
									$g->{command}->{'tag1'}=0;
								}
								$mainWin->Minimize();
								$mainWin->Show(); #unless ($mainWin->IsVisible());					
							}#nini
						},
			-onRightClick =>sub{ 
				if($mainWin->IsVisible()){
					$Menus->{mint}->Change(-text =>"$g->{display}->{menus_mint1}");
				}
				else{
					$Menus->{mint}->Change(-text =>"$g->{display}->{menus_mint2}");
				}
				$mainWin->TrackPopupMenu($Menus->{Item},Win32::GUI::GetCursorPos());
				return 1;},
			);
my $main_acce = new Win32::GUI::AcceleratorTable(
		"Return"   => sub {
						send_Text();
						return 0;},
		#"Ctrl-S" => "sText",
		#"Shift-A"=>sub {print "test\n";},
);
$mainWin->Change(-accel=>$main_acce);
$mainWin->AddTimer('updatelogs',500);
$mainWin->AddTimer('circulator',500);

#77777777777777777777777777777777777777777777777777ssssssssssssssssssssssssssssssssssss
#&new();
&initice();
&show();
Win32::GUI::Dialog();

#sub new(){
#	my $self=shift;
#	my %tittle=@_;
#	my $this = {main_win=>$mainWin,
#				accel=>$main_acce,
#				debug=>'',
#				run_sub_process=>{},
#				g=>$g,
#				};
#	foreach (keys %tittle) {
#		$this->{$_}=$tittle{$_};
#	}
#	bless $this;
#	return $this;
#}
#初始化,程序
sub initice(){
	my @all=@ARGV;	
	foreach  (@all) {
		my $api;
		$api=Gui_Multi_Exec->new($_);
		$g->{api}->{$_}=$api;
	}
#	$mainWin->nickname->Text("$g->{display}->{label4_nickname}:$g->{showname}");
	$mainWin->IRCSer->Text("$g->{display}->{label5_ircser}:$g->{display}->{label5_ircser_text}");
	$mainWin->Channel->Text("$g->{display}->{label6_channel}:$g->{display}->{label6_channel_text}");
}

#显示窗口
sub show(){
	&inithash_to_menu();
	$mainWin->Center();
	$mainWin->Show();
	################################
		$mainWin->Disable();
		LoadingWindow::Show($mainWin);
		start_splash_window();
		LoadingWindow::Close();
		$mainWin->Enable();
		$mainWin->BringWindowToTop();
		$g->{switch}->{active}=1;
		$mainWin->myText->SetFocus();
		$ni->HideBalloon(1);
#		&runperlfile("svnupdata.pl");
}
########################################################################################################################################################################################


sub IRC_Activate{
	print "active\n";
	$g->{switch}->{active}=1;	
	if($g->{command}->{'tag1'}==1){ # 如果存在共聊信息 停止煽动的图标
		$g->{command}->{'tag1'}=0;
	}
	$mainWin->myText->SetFocus();
	return 0;
}

sub IRC_Deactivate{
	print "deactive\n";
	$g->{switch}->{active}=0;
	#$mainWin->Minimize();
}
sub IRC_Resize(){
	my $h=$mainWin->Height();
	my $w=$mainWin->Width();
	print "宽：".$w."        "."高：".$h."\n";
	$mainWin->list->Height($h-150);
	$mainWin->nickname->Move(10,$h-120);
	$mainWin->IRCSer->Move(10,$h-100);
	$mainWin->Channel->Move(10,$h-80);
	if($Edit->IsVisible()){
		$mainWin->logs->Resize($w-170-20,$h-150) if($Edit);
	}
	else{
		foreach  (keys %{$g->{RichEdit}->{$api->{type_name}}}) {
			my $Edit=$g->{RichEdit}->{$api->{type_name}}->{$_};	
			$Edit->Resize($w-170-20,$h-150) if($Edit);
		}
	}
	$mainWin->myText->Move(170,$h-120);
	$mainWin->myText->Resize($w-170-80,50);
	$mainWin->sendText->Move($w-60,$h-100);
	if($mainWin->myText->Width<=0){$mainWin->sendText->Resize(0,0);}else{$mainWin->sendText->Resize(40,20);}
}

sub IRC_OnAbout {
  Win32::GUI::MessageBox(0,
     "$g->{display}->{msgbox1_text1}\r\n".
    # "$g->{display}->{msgbox1_text2}:0531-67672121\r\n".
	 "http://www.opener.asia",
     "$g->{display}->{msgbox1_text3}...",
	  MB_ICONINFORMATION | MB_OK,
  );
  0;
}
#
#sub IRC_Minimize {
##	my $yt=$g->{switch}->{mintime} if($g->{switch}->{mintime});
##	$g->{switch}->{mintime}=time;   # 保存最小化最大化时的时间
##if($yt and $g->{switch}->{mintime}-$yt<=2){
##	&IRC_Terminate();
##}
#	print "call Minimize sub\n" if($g->{debug});
#	return 1;
#}

sub IRC_Terminate{
	if($g->{switch}->{closef}==-1){
		my $ret = Win32::GUI::MessageBox (0, "$g->{display}->{msgbox2_text1}？",
						       "$g->{display}->{msgbox_title_ts}", MB_ICONQUESTION |MB_YESNO);
		if($ret!=6){
			$g->{switch}->{closef}=1;
			&chageseting('Winclose_or_min',1);
		}
		else{
			$g->{switch}->{closef}=0;
			&chageseting('Winclose_or_min',0);
		}
		return &IRC_Terminate();
	}
	elsif($g->{switch}->{closef}==0){   
		$mainWin->Hide();
		return 0;
	}
	elsif($g->{switch}->{closef}){
		exit_win();
	}
}

sub treeview_dispInfo{
	 my ($tv, $node) = @_;
		$g->{tv_Selection}="";

		my %node_info =$tv->GetItem($node);
		my $chald=$node_info{-children};
		my $pnode = $tv->GetParent($node);
		my %pnode_info =$tv->GetItem($pnode);
		my $type_name=$pnode_info{-text};
		my $group=$node_info{-text};
		if($pnode and $chald){
			my $Edit;
			my @size;
			if($mainWin->logs->IsVisible()){
				$Edit=$mainWin->logs;
			}
			else{
				$Edit=$g->{select_RichEdit};
			}
				$Edit->Hide();
				@size=($Edit->Width ,$Edit->Height);
			
			$Edit=$g->{select_RichEdit}=$g->{RichEdit}->{$type_name}->{$group};
			$Edit->Resize(@size);
			$Edit->Show();
			$mainWin->nickname->Text("$g->{display}->{label4_nickname}:$type_name");
			#$mainWin->IRCSer->Text("$g->{display}->{label5_ircser}:$g->{display}->{label5_ircser_text}");
			$mainWin->Channel->Text("$g->{display}->{label6_channel}:$group");
		}
		return 1 if($chald);
#		return 1 if $pnode == 0;
		$g->{tv_Selection}=$node;
}

#双击列表框的一项
sub list_DblClick{
	if($g->{tv_Selection} eq ""){
		return 1;
	}
	my @apath=get_tree_path($g->{tv_Selection});
	my $uname=$apath[0];
	@apath=reverse(@apath);
	my $tempname=join(" ",@apath);
	my $typename=$apath[0];
	unless (defined $g->{private_chat_windows}->{$uname}->{win}) {
		foreach  (keys %{$g->{api}}) {
			$api=$g->{api}->{$_};	
			last if($typename eq $api->{type_name});
			#last if($tempname=~s/$api->{type_name} //);
		}
		$g->{private_chat_windows}->{$tempname}=new chat(
			'title'	  =>$tempname,
			'nickname'=>$uname,
			'address'=>$api,
			'savelogs'=>$g->{switch}->{msn},
			'display' =>$g->{display},	
		);
	}
	$g->{private_chat_windows}->{$tempname}->show($g->{private_chat_windows}->{$tempname}->{win});
}

sub get_tree_path{
	my $node=shift;
	my @allpath;
	while($node) {
		my %item_info = $mainWin->list->GetItem($node);
		my $name = $item_info{-text};
		push(@allpath,$name);
		$node = $mainWin->list->GetParent($node);
	}
	return @allpath;

}


sub circulator_Timer{			# 用与主进程中需要时间等待 一定值后结束的情况
	if($g->{switch}->{balloon}){			#显示气球框3秒
		$g->{switch}->{balloon}++;
		if($g->{switch}->{balloon}>7){
			$ni->ShowBalloon(0);
			$g->{switch}->{balloon}=0;
		}
	}

	if($g->{command}->{'tag1'}==1 or $g->{command}->{'tag2'}==1 or $g->{switch}->{changeicon}==0){	# 用于图标闪烁
		if($g->{switch}->{changeicon}){
			change::changeicon($ni,$iconchange);
			$g->{switch}->{changeicon}=0;
		}
		else{
			change::changeicon($ni,$icon);
			$g->{switch}->{changeicon}=1;
		}
	}
}

sub gettime{
	my($sec,$min,$hour,$day,$mon,$year) = localtime();
	$mon++;$year += 1900;
	my $time = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year,$mon,$day,$hour,$min,$sec);
	$time=~s/:\d\d$//;
	return $time;
}

sub updatelogs_Timer(){
#	$g->{startime}=times();
#	my $times=$g->{startime} -$g->{endtime};
#	print  "............$times\n";
#	$g->{endtime}=$g->{startime};

	foreach  (keys %{$g->{api}}) {
		$api=$g->{api}->{$_};
		if($api->{close}){
			delete $g->{api}->{$_};
			next;
		}
		my ($logs,$msg)=$api->getdata_from_socket();
		foreach my $gname (keys %{$logs->{1}}) {   				#print "群聊信息\n";
				my $mp=$logs->{1}->{$gname};
				foreach  (keys %$mp) {
					my $s=$mp->{$_};
					chomp $s;
					my $time=gettime();
					my $log="<$_:>$s";
					my $Edit=$g->{RichEdit}->{$api->{type_name}}->{$gname};
					#print "$Edit=\$g->RichEdit}->{$api->{type_name}}->{$gname};\n";
					next unless ($Edit);
					$Edit->SetSel(length($Edit->Text()),length($Edit->Text()));
					$Edit->SetCharFormat(-color => hex("006400"));
					$Edit->ReplaceSel($time." <$_:>"."\r\n");
					$Edit->SetCharFormat(-color => hex("000000"));
					$Edit->ReplaceSel("$s\r\n");				
					if(! ($mainWin->IsVisible()) or $g->{switch}->{active}==0){
						&runperlfile("play_sound.pl","msg") if($g->{switch}->{msound});
						if($g->{switch}->{mballoon}){
							change::changeballoon($ni,"$g->{display}->{balloon_chagetext1} $api->{type_name} $gname",$g->{display}->{balloon_text_new_message});
							$g->{switch}->{balloon}=1;
						}
						if($g->{command}->{'tag1'}!=1){
							$g->{command}->{'tag1'}=1;
						}
					}
					############公共聊天记录写文件##############
					&write_logs($time,$log);			
					########################################
			}
		}
		foreach (keys %{$logs->{2}}) {				# 私人聊天信息
			my $s=$logs->{2}->{$_};	
				my $slog="<$_:>$s";
				
				if (defined $g->{private_chat_windows}->{$_}->{win}) {	}
				else{
					$g->{private_chat_windows}->{$_}=new chat(
					    'title'   =>$_,
						'nickname'=>$_,
						'address'=>$api,
    				   'savelogs'=>$g->{switch}->{msn},
						'display' =>$g->{display},
					);
				}
			  if($g->{private_chat_windows}->{$_}->{win}->IsVisible()){
				  $g->{private_chat_windows}->{$_}->{win}->Minimize();
				  $g->{private_chat_windows}->{$_}->show();
  				  $g->{private_chat_windows}->{$_}->{win}->SetFocus();
			  }
			  else{     &runperlfile("play_sound.pl","msg") if($g->{switch}->{msound});
						if($g->{switch}->{mballoon}){
							change::changeballoon($ni,"$g->{display}->{balloon_chagetext_getmessage}$_",$g->{display}->{balloon_text_new_message});
							$g->{switch}->{balloon}=1;
						}
						if($g->{command}->{'tag2'}!=1 ){	
							$g->{command}->{'tag2'}=1;
						}
						my $pushok=1;
						foreach  my $have (@{$g->{tmp}->{privatew}}) {
							$pushok=0 if($_ eq $have);
						}
			  		push(@{$g->{tmp}->{privatew}},$_) if($pushok);   	#pppppppppppppppppppppp
			  }
			$g->{private_chat_windows}->{$_}->recvchat("<$_:>",$s);
		}
		foreach my $name (keys %{$logs->{3}}) {  # 命令消息
			my $s=$logs->{3}->{$name};	
			if($s=~/^dos_control:/){
				remote_control::get_data($s,$name,$g,"dos_control");
			}
			elsif($s=~/^vnc_control:/){
				remote_control::get_data($s,$name,$g,"vnc_control");
			}
			elsif($s=~/^Command_from_commander:/){
				#command::get_data($s,$name,$g);	
			}
		}
	print Dumper $msg if($msg);
	foreach (sort keys %$msg) {

		my $mp=$msg->{$_};
#		unless($api->{type_name}){
#			$api->{type_name}=$msg->{-1};
#		}
		my $u=$g->{userlist}->{$api->{type_name}};

		if($_<0){		# 初始化
		print "{type_name}=$msg->{$_}\n";
			$api->{type_name}=$msg->{$_};
		}
		elsif($_==0){		# 网络连接失败					
			Win32::GUI::MessageBox(0,
			"$g->{display}->{msgbox_text1_notconnect}！\r\n",
			"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			exit_win();
		}
		elsif($_==1){	#网络连接成功
		}
		elsif($_==2){	#登录服务器成功 			
			$g->{tmp}->{startok}=1;
		}
		elsif($_==3){
			my $u=$g->{userlist}->{$api->{type_name}}={};
			foreach my $gname (keys %$mp) {
				my $garray=$mp->{$gname};
				foreach  (@$garray) {
					next if(/^\s*$/);
					if($gname eq $api->{login}){
						$u->{$_}=1;
					}
					else{
						$u->{$gname}->{$_}=1;
					}
				}
				my $Edit = $mainWin->AddRichEdit(
					-pos   => [170,20],
					-size  => [840,640],
					-vscroll => 1,
					-autovscroll => 1,
					-keepselection => 1,
					-readonly => 1,
					-multiline  => 1 ,
					-visible =>0,
				);
			$g->{RichEdit}->{$api->{type_name}}->{$gname}=$Edit;
			}
			&renewal_userlist();
		}
		elsif($_==4){	#连接意外断开
			Win32::GUI::MessageBox(0,
			"$g->{display}->{msgbox_text1_notconnect}！\r\n",
			"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$g->{tmp}->{startok}=1;
			#$api->start();
		}
		elsif($_==5){	#登录名修改
			$_="$g->{display}->{label4_nickname}:".$msg->{$_};
			Win32::GUI::MessageBox(0,
			"$g->{display}->{msgbox_text_user_already_in_use} $_！\r\n",
			"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$mainWin->nickname->Text($_); 
		}
		elsif($_==55){	#讨论组用户更名
			$msg->{$_}=~/(.+) (.+)/;
			foreach my $gname (keys %$u) {	# 循环该用户内所有的组
				if(exists $u->{$gname}->{$1}){
					delete $u->{$gname}->{$1};
					$u->{$gname}->{$2}=1;
				}
			}
			&renewal_userlist();
		}
		elsif($_==6){	#添加新用户
			foreach my $gname (keys %$mp) {
				my $garray=$mp->{$gname};
				foreach  (@$garray) {
					next if(/^\s*$/);
					$u->{$gname}->{$_}=1;
				}
			}
			&renewal_userlist();
		}
		elsif($_==7){	#删除用户
			foreach my $gname (keys %$mp) {
				my $garray=$mp->{$gname};
				foreach  (@$garray) {
					next if(/^\s*$/);
					delete $u->{$gname}->{$_};
				}
			}
			&renewal_userlist();
		}
		elsif($_==77){	#删除掉线用户
			foreach my $gname (keys %$u) {	# 循环该用户内所有的组 删除这些用户
				foreach  (@$mp) {
					next if(/^\s*$/);
					delete $u->{$gname}->{$_} if(exists $u->{$gname}->{$_});
				}
			}
			&renewal_userlist();
		}
		elsif($_==8){	#网络端退出
			$api->{close}=1;
			#$mainWin->updatelogs->Kill(1);
			Win32::GUI::MessageBox(0,
			"$api->{type_name} $g->{display}->{msgbox_text_connect_err}！\r\n",
			"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			#$api->init();
		}
		elsif($_==9){	#讨论组更名
			foreach my $gname (keys %$mp) {
				my $newgn=$mp->{$gname};
				print "$gname chageto $newgn\n";
			}
			#$mainWin->Channel->Text("$g->{display}->{label6_channel}:".$msg->{$_});			#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
		}
		elsif($_==10){	#更改用户名失败 ，该用户名已被占用
			Win32::GUI::MessageBox(0,
			"$msg->{$_}\r\n",
			"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
		}
		elsif($_==13){ #启动某一进程成功
			$msg->{$_}="run $msg->{$_} ok!";
		}
		elsif($_==14){
			if($msg->{$_}=~/^sockstage\.pl/){
				Win32::GUI::MessageBox(0,
				"$msg->{$_} $g->{display}->{msgbox_text_runfile_err}\r\n",
				"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
				);
				exit_win();
			}
		}
		elsif($_==15){	#版本更新程序状态
				$msg->{$_}=~/(\d) (.+)/;
				if($1==3){
					my $ret = Win32::GUI::MessageBox (0, "$g->{display}->{msgbox_text_undata_ok}!",
                       "$g->{display}->{msgbox_title_ts}", 0x0040|0x40000);
				}
				elsif($1==2){
					print "没有发现新版本！\n";
					if($g->{switch}->{"svnx"}){
						Win32::GUI::MessageBox(0,
						 "$g->{display}->{msgbox_text_nofind_new_svn}!\r\n",
						 "$g->{display}->{msgbox_title_ts}",0x0040|0x40000
						 );
					}
					$g->{switch}->{"svnx"}=0;
				}
				elsif($1==1){					# 版本低了需要更新启动更新程序
					# 提示信息
					$ni->Change("-balloon_title" => "$g->{display}->{balloon_chagetext_updata_programe}");
					$ni->Change("-balloon_tip" =>"$g->{display}->{balloon_chagetext_updata_programe2} $2 " );
					$ni->Change("-balloon_timeouy" => 1000);
				    $ni->ShowBalloon(1);
					my $ret = Win32::GUI::MessageBox (0, "$g->{display}->{msgbox_text_havenew_svn}？",
						       "$g->{display}->{msgbox_title_ts}", MB_ICONQUESTION |MB_YESNO);
					if($ret==6){
						$api->updata(1);
					}
					else{
						$api->updata(0);
					}
				}
				elsif($1==0){
					if($g->{switch}->{"svnx"}){
						Win32::GUI::MessageBox(0,
						 "$g->{display}->{msgbox_text_connect_svnservice_err}!\r\n",
						 "$g->{display}->{msgbox_title_ts}",0x0040|0x40000
						 );
					}
				}
		}
		#print $api->{type_name}." $_ :".$msg->{$_}."\n" if(exists $api->{type_name});
	}
	}
}

#-----------------内部调用的函数-----------------#
sub svn{
	&runperlfile("svnupdata.pl");
	$g->{switch}->{"svnx"}=1;
}
sub tv_text{
	my $node=shift;
	my %pnode_info =$mainWin->list->GetItem($node);
	my $item = $pnode_info {-text};
	return $item;
}

#sub get_user_group_nambe{
#	my $h=shift;
#	foreach  (keys %$h) {
#		if(ref $h->{$_} eq "HASH")){
#			$g->{user_group_sum}++;
#			&get_user_group_nambe($h->{$_});
#		}
#	}
#	return $g->{user_group_sum};
#}

sub renewal_userlist{
	my $online=$mainWin->list->GetCount();
	#$g->{user_group_sum}=0;
	#$online-=get_user_group_nambe($g->{userlist});
	$mainWin->online->Text("$g->{display}->{label1_onlineuser}:".$online);

	my $this=$g->{userlist}->{$api->{type_name}};
	my $pnode=$mainWin->list->GetRoot();
	my $item=tv_text($pnode);
	while($item) {
		last if($api->{type_name} eq $item);
		$item=tv_text($pnode=$mainWin->list->GetNextSibling($pnode));
	}
	&Align($this,$pnode,$api->{type_name});
}

sub Align{
	my ($this,$pnode,$text)=@_;		# 哈希 treeview项 显示的文字
	my ($node,$item);
	my $tv=$mainWin->list;
	
	if($pnode){							# 如果存在父辈指针则取出第一个孩子的 text
		my %item_info = $tv->GetItem($pnode);
		$item =tv_text($node=$tv->GetChild($pnode));
	}
	else{								# 如果不存在就创建他
		$pnode = $tv->InsertItem(
					-text =>$text,
		);
		$item=0;
	}

	foreach  (sort keys %$this) {
		if($item){					# 如果treeview 列表没结束
#		print "now=$_ item=$item \n";
			if(lc($_) lt lc($item)){			# 添加用户
				$node=$tv->GetPrevSibling($node);
				$node=0xFFFF0001 if($node==0);
				$node=$tv-> InsertItem(
					-parent => $pnode,
					-item   => $node,
					-text   => $_,
				);
				print "add $_\n";
				$item=$_;
				redo;
			}
			elsif(lc($_) gt lc($item)){		# 删除用户
				# $tv->Select($node);
				my $node_next=$tv->GetNextSibling($node);
				my %item_info = $tv->GetItem($node_next);
				print "delete $item\n";
				$tv->DeleteItem($node);
				$node=$node_next;
				$item = $item_info{-text};
				redo;
			}
		}
		else{
				$node=$tv-> InsertItem(
					-parent => $pnode,
					-text   => $_,
				);
		}
		if(ref $this->{$_} eq "HASH"){	
			&Align($this->{$_},$node,$_);	
		}
		$node=$tv->GetNextSibling($node);
		my %item_info = $tv->GetItem($node);
		$item = $item_info{-text};
	}
}


#发送聊天信息
sub send_Text(){
	my $self=shift;
	my $time=gettime();
	my $tempname=$mainWin->nickname->Text();
	$tempname=~s/^$g->{display}->{label4_nickname}://;
	my $s_text=$mainWin->myText->Text();
	if($s_text){
		$s_text=~s/[\r\n||\n]$//g;
		my $Edit=$g->{select_RichEdit};
		$Edit->SetSel(length($Edit->Text()),length($Edit->Text()));
		$Edit->SetCharFormat(-color => hex("006400"));
		$Edit->ReplaceSel("$time"." <".$tempname.":>"."\r\n");
		$Edit->SetCharFormat(-color => hex("000000"));
		$Edit->ReplaceSel("$s_text\r\n");
		#$s_text = decode("euc-cn", $s_text);
		$api->senddata_to_socket($s_text);
		############聊天记录写文件##############
		&write_logs($time,"<$g->{display}->{display_text_youself}:>".$mainWin->myText->Text());
		$mainWin->myText->Text('');
		########################################
    
	}
	else{
		Win32::GUI::MessageBox (0, "$g->{display}->{msgbox_text_err_send_msgnot_space}!");
		$mainWin->myText->SetFocus();
		return 1;}
}

sub write_logs{
	return if($g->{switch}->{msn}==0);
	my ($time,$s)=@_;
	my $month=substr($time,0,10);
	my $open=$api->{type_name};
	$open=~s/(.+):(.+)/$1\\$2/;
	$open="Chats\\$open";
	if(-d $open){ 
		open(LOGS,">>$open\\$month.txt");
		print LOGS "$time\n";
		print LOGS "$s\n";
		close LOGS;
	}
	else{
		&tomkdir($open);
		#&write_logs($time,$s);
	}

}
#sub tomkdir{
#	my $s=shift;
#	my @dir=split(/\\/,$s);
#	$s="";
#	foreach  (@dir) {
#		$s.="$_\\";
#		mkdir($s);
#	}
#}
sub setini(){
	use settings;
	my $set=new settings($g->{display});
	$set->show();
}

#取配置信息
sub getini{
	my $key;			# 关键字 这里指的是 配置文件中 用方括号括起来的字符串
	open(INIFILE,"settings.ini");
	while(<INIFILE>){
		$g->{switch}->{msn}=$1 if(/Savelogs_ok=(\d)/i);
		$g->{switch}->{msound}=$1 if(/Sound_ok=(\d)/i);
		$g->{switch}->{mballoon}=$1 if(/Balloon_ok=(\d)/i);
		$g->{switch}->{mautorun}=$1 if(/Autorun=(\d)/i);
		$g->{switch}->{closef}=$1 if(/Winclose_or_min=(\d)/i);
		$g->{switch}->{language}=$1 if(/Language=(.+)/i);
	}
	close INIFILE;
	return $g->{setting};
}

#ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
sub inithash_to_menu{
	$Menu->{sn}->Checked($g->{switch}->{msn});
	$Menus->{autorun}->Checked($g->{switch}->{mautorun});
	$Menu->{sound}->Checked($g->{switch}->{msound});
	$Menu->{qq}->Checked($g->{switch}->{mballoon});
}

sub chageseting{
	my ($m,$s)=@_;
	open(F,"settings.ini");
	my @alls=<F>;
	close(F);
	foreach  (@alls) {
		$_="$m=$s\n" if($_=~/^$m=/);
	}
	push(@alls,"$m=$s\n") unless(grep /^$m/, @alls);
	open(FF,">settings.ini");
	print FF @alls;
	close(FF);
}

sub cls_richbox{
	$mainWin->logs->Text('');
}
sub chage_nick{
	return;
	my $s=inputbox();
	$api->changelogin();
}
sub autorun_part{
	use Cwd;
	use Win32::TieRegistry;
	my $reg= new Win32::TieRegistry 'LMachine\SOFTWARE\Microsoft\Windows\CurrentVersion\Run';
	my $dir=getcwd();
	$dir=~s/\//\\/g;
	if($g->{switch}->{mautorun}){
		$Menus->{autorun}->Checked(0);
		$g->{switch}->{mautorun}=0;
		 $reg->DELETE("opener_irc");
	}
	else{
		$Menus->{autorun}->Checked(1);
		$g->{switch}->{mautorun}=1;
		$reg->SetValue("opener_irc","$dir\\irc.pl");
	}
	&chageseting("Autorun",$g->{switch}->{'mautorun'});	#将是否自动运行写入配置文件    聊天信息保存关键字为Autorun
}
sub sound_ok{
	if($g->{switch}->{'msound'}){
		$Menu->{sound}->Checked(0);
		$g->{switch}->{'msound'}=0;
	}
	else{
		$Menu->{sound}->Checked(1);
		$g->{switch}->{'msound'}=1;
	}
	&chageseting("Sound_ok",$g->{switch}->{'msound'});	#将声音开关写入配置文件    聊天信息保存关键字为Sound_ok
}

sub balloon_ok{
	if($g->{switch}->{'mballoon'}){
		$Menu->{qq}->Checked(0);
		$g->{switch}->{'mballoon'}=0;
	}
	else{
		$Menu->{qq}->Checked(1);
		$g->{switch}->{'mballoon'}=1;
	}
	&chageseting("Balloon_ok",$g->{switch}->{'mballoon'});	#将气球写入配置文件    聊天信息保存关键字为Balloon_ok
}
sub savelogs_ok{
	if($g->{switch}->{msn}){	#设置菜单显示和 保存设置到哈希
		$Menu->{sn}->Checked(0);
		$g->{switch}->{msn}=0;
	}
	else{
		$Menu->{sn}->Checked(1);
		$g->{switch}->{msn}=1;
	}
	
	foreach  (keys %{$g->{private_chat_windows}}) {	#通知 私聊窗体 聊天记录的写入方式。
	print "chat:  $_\n";
		$g->{private_chat_windows}->{$_}->{savelogs}=$g->{switch}->{msn};
	}

	&chageseting("Savelogs_ok",$g->{switch}->{msn});	#将是否保存聊天信息写入配置文件   聊天信息保存关键字为Savelogs_ok

}

sub hidwindow{
	if($mainWin->IsVisible()){
		$mainWin->Hide();
	}
	else{
		$mainWin->Show();
	}
}

sub vnc_connect{
	if($g->{switch}->{mvnc}){
		$Menu->{vnc}->Change(-text =>"(&V)vnc$g->{display}->{text_connect_ask}");
		$g->{switch}->{mvnc}=0;
		$g->{run_sub_process}->{'!!vnc_server!!'}->Kill(0);
		$api->sendcommand_to_socket($g->{command}->{"admin_name"},"vnc_control: $g->{display}->{text_user_stop_connect}!");
		$g->{window}->{mainwin}->serv->Text("$g->{display}->{text_services_not_connect}");
	}
	else{
		get_system_admin();
		if($g->{command}->{"admin_name"}){
			$api->sendcommand_to_socket($g->{command}->{"admin_name"},"vnc_control: $g->{display}->{text_disk_connect_ask}!");
			$mainWin->serv->Text("$g->{display}->{text_vnc_connecting}.....");
			$g->{window}->{mainmenu}->{vnc}->Enabled(0);
			$Menu->{vnc}->Change(-text =>"(&V)$g->{display}->{text_stop_vnc_connect}");
			$g->{switch}->{mvnc}=1;
		}else{
			Win32::GUI::MessageBox(0,
				 "$g->{display}->{text_nofind_admin}\r\n",
				 "$g->{display}->{msgbox_title_ts}",0x0040|0x40000);
		}
	}
}

sub dos_connect{
	if($g->{switch}->{mcmd}){
		$Menu->{cmdservices}->Change(-text =>"(&S)dos$g->{display}->{text_connect_ask}");
		$g->{switch}->{mcmd}=0;
		$g->{run_sub_process}->{'!!dos_server!!'}->Kill(0);
		$api->sendcommand_to_socket($g->{command}->{"admin_name"},"dos_control: $g->{display}->{text_user_stop_connect}!");
		$g->{window}->{mainwin}->serv->Text("$g->{display}->{text_services_not_connect}");
	}
	else{
		get_system_admin();
		if($g->{command}->{"admin_name"}){
			$api->sendcommand_to_socket($g->{command}->{"admin_name"},"dos_control: $g->{display}->{text_connect_ask}!");
			$mainWin->serv->Text("$g->{display}->{text_dos_connect}.....");
			$g->{window}->{mainmenu}->{cmdservices}->Enabled(0);
			$Menu->{cmdservices}->Change(-text =>"(&S)$g->{display}->{text_stop_dos_connect}");
			$g->{switch}->{mcmd}=1;
		}
		else{	
			Win32::GUI::MessageBox(0,
			 "$g->{display}->{text_nofind_admin}!\r\n",
			 "$g->{display}->{msgbox_title_ts}",0x0040|0x40000);
		}
	}
}

sub get_system_admin{
	my $count=$mainWin->list->GetCount();
	for (my $i=0;$i<$count ;$i++) {
		if($mainWin->list->GetText($i)=~/^openeradmin|^\@openeradmin$/){
			$g->{command}->{"admin_name"}=$mainWin->list->GetText($i);
			$g->{command}->{"admin_name"}=~s/^\@//;
		}
	}
}

##########调试用隐藏DOS窗口######
my ($DOS) = Win32::GUI::GetPerlWindow();
#Win32::GUI::Hide($DOS) unless($g->{debug});
	
sub exit_win{
	$mainWin->Hide();
	$ni->Remove();
	undef $mainWin;
	undef $ni;
	if ($g->{run_sub_process}->{'!!dos_server!!'}) {
		$g->{run_sub_process}->{'!!dos_server!!'}->Kill(0);
		$api->sendcommand_to_socket($g->{command}->{"admin_name"},"dos_control: $g->{display}->{text_user_stop_connect}!");
	}
	if ($g->{run_sub_process}->{'!!vnc_server!!'}) {
		$g->{run_sub_process}->{'!!vnc_server!!'}->Kill(0);
		$api->sendcommand_to_socket($g->{command}->{"admin_name"},"vnc_control: $g->{display}->{text_user_stop_connect}!");
	}
	foreach  (keys %{$g->{run_sub_process}->{'!!vnc_client!!'}}) {
		if ($g->{run_sub_process}->{'!!vnc_client!!'}->{$_}) {
			$g->{run_sub_process}->{'!!vnc_client!!'}->{$_}->Kill(0);
			$g->{api}->sendcommand_to_socket($_,"vnc_control: $g->{display}->{text_admin_stop_connect}!");
		}
	}
	foreach  (keys %{$g->{run_sub_process}->{'!!dos_client!!'}}) {
		if ($g->{run_sub_process}->{'!!dos_client!!'}->{$_}) {
			$g->{run_sub_process}->{'!!dos_client!!'}->{$_}->Kill(0);
			$g->{api}->sendcommand_to_socket($_,"dos_control: $g->{display}->{text_admin_stop_connect}!");
		}
	}
	foreach  (keys %{$g->{api}}) {
		$api=$g->{api}->{$_};
		$api->quit();
		delete $g->{api}->{$_};
	}
	exit(0);
}

sub start_splash_window{
	LoadingWindow::SetRange(100);
	my $login;
	$login=&runperlfile("play_sound.pl","login") if($g->{switch}->{msound});
	while(!$g->{tmp}->{startok}){
		LoadingWindow::Step();
		select(undef,undef,undef,0.1);
	}
	#$login->Kill(0);
}

package LoadingWindow;
our $win;

sub Show {
    my $parent = shift;
    $win = Win32::GUI::Window->new(
        -parent      => $parent,        
        -title       => "$g->{display}->{text_user_list_loading} ...",
        -size        => [200,50],
        -toolwindow  => 1,
		-sizable => 0,
        -resizable => 0,
        #-onTerminate => sub {$terminate = 1; 1;},
    ) or die "new Lwindow";
    $win->Center($parent);
    $win->AddProgressBar(
        -name => 'PB',
        -size => [$win->ScaleWidth(),$win->ScaleHeight()],
        -smooth => 0,
    ) or die "new Lprogress";
    $win->PB->SetStep(1);

    $win->Show();
    Win32::GUI::DoEvents();

    return 1;
}

sub SetRange {
    $win->PB->SetRange(0, shift) if $win;
    return 1;
}

sub Step {

    $win->PB->StepIt() if $win;
    Win32::GUI::DoEvents();
    return 0;
}

# Hide the min-window, and free any resources
# it is using;  prepare for it to be used again
sub Close {
    if($win) {
        Win32::GUI::DoEvents();
        $win->Hide();
        Win32::GUI::DoEvents();
        undef $win;
    }
    return 1;
}
