#############################chat模块################################
package chat;
use Win32::GUI qw(MB_ICONINFORMATION MB_OK);
#use strict;
#use warnings;
########################################################################
#       chat窗口界面调用函数                                        #
########################################################################


sub new(){
	my $self=shift;
	my %in=@_;

    my $this = {};
	foreach (keys %in) {
		$this->{$_}=$in{$_};
	}
	bless $this;
	$this->{name}=$this->{"nickname"};
    $this->{icon} = new Win32::GUI::Icon('res\ice.ico');
    $this->{win} = Win32::GUI::Window->new (
		-name   => 'mainWin2',
		-size   => [505, 380],
		-onTerminate=>sub{$this->{win}->Hide(); return 0;},
    );
	$this->{win}->Center();
	$this->{edit} = $this->{win}->AddRichEdit(
		-name    => 'CB1',
		-pos => [ 2, 20 ],
		-size => [ 495, 200 ],
		-vscroll => 1,
		-keepselection => 1, 
		-autovscroll => 1,
		-readonly => 1,
		-multiline     => 1 ,
	);

	$this->{win}->Change(-onResize=>sub{
						 my $h=$this->{win}->Height();
						 my $w=$this->{win}->Width();
	#					 $this->{win}->CB1->Move(2,20);
						 $this->{win}->CB1->Resize($w-20,$h-150);
	#                     $this->{win}->CB1->Height($h-500);
						 $this->{win}->CB2->Move(2,$h-120);
						 $this->{win}->CB2->Resize($w-20,50);
						 $this->{win}->sendbutton->Move($w-80,$h-60);}
						 );
	$this->{win}->Change(-onActivate=>sub {
		print "active chat\n";
		$this->{win}->CB2->SetFocus();
		return 0;}
		);

	 $this->{win}->AddTextfield (
		-name    => 'CB2',
		-pos => [ 2, 260 ],
		-multiline   => 1,
		-vscroll   => 1,
		-autovscroll => 1,
		-size => [ 495, 50 ],
		); 

	$this->{buttonsend}=$this->{win}->AddButton(
		-pos => [ 430, 320 ],
		-name   => "sendbutton",
		-size => [ 40, 20 ],
		-title => $this->{display}->{button1_sendtext},
		-onClick => sub{send_chat($this); 
						return 0; 	
						},
		);
	$this->{acc}= new Win32::GUI::AcceleratorTable(
					"Return"   =>sub {send_chat($this); 
									  return 0; },
					'esc'      =>sub {$this->{win}->Hide(); return 0;}
					);
	$this->{win}->Change(-accel=>$this->{acc});
	$this->{win}->ChangeIcon($this->{icon});
	return $this;
}



sub recvchat{
	my $self=shift;
    $recvchatnickname=shift;
	$recvchattext=shift;
	my $time=main::gettime();
	$recvchattext=~s/\n$//;
	$self->{edit}->SetSel(length($self->{edit}->Text()), length($self->{edit}->Text()));
	$self->{edit}->SetCharFormat(-color => hex("006400"));
	$self->{edit}->ReplaceSel($time." ".$recvchatnickname."\r\n");
    $self->{edit}->SetCharFormat(-color => hex("000000"));
	$self->{edit}->ReplaceSel($recvchattext."\r\n");
	#$self->{edit}->ReplaceSel("\r\n");
	############聊天记录写文件##############
	$self->write_logs($time,$recvchatnickname.$recvchattext."\n")
	########################################

}
sub write_logs{
	my ($this,$time,$s)=@_;
	return	if($this->{savelogs}==0);
	my $tempname=$this->{name};
    $tempname=~s/^@//;
	my $open=$this->{address}->{type_name};
	$open=~s/(.+):(.+)/$1\\$2/;
	$open="Chats\\$open";
	if(-d $open){ 
		open(LOGS,">>$open\\$tempname.txt");
		print LOGS "$time\n";
		print LOGS $s;
		close LOGS;
	}
	else{
		&tomkdir($open);
		write_logs(@_);
	}	
}
sub tomkdir{
	my $s=shift;
	my @dir=split(/\\/,$s);
	$s="";
	foreach  (@dir) {
		$s.="$_\\";
		mkdir($s);
	}
}

sub send_chat{
	my $this=shift;
	my $sendchat=$this->{win}->CB2->Text();
    unless($sendchat){
		Win32::GUI::MessageBox (0, "$this->{display}->{msgbox_text_err_send_msgnot_space}!");
		$this->{win}->CB2->SetFocus();
		}
	else{
		my $time=main::gettime();
		$this->{win}->CB2->Text('');
		$this->{edit}->SetSel(length($this->{edit}->Text()), length($this->{edit}->Text()));
		$this->{edit}->SetCharFormat(-color => hex("006400"));
		$this->{edit}->ReplaceSel($time." <$this->{display}->{display_text_youself}:>"."\r\n");
		$this->{edit}->SetCharFormat(-color => hex("000000"));
		$this->{edit}->ReplaceSel($sendchat."\r\n");
		#$this->{edit}->ReplaceSel("\r\n");
			############聊天记录写文件##############
		my $tempname=$this->{name};
		$tempname=~s/^@//;
		$this->write_logs($time,"<$this->{display}->{display_text_youself}:>".$sendchat."\n");
			########################################
		$this->{address}->senddata_to_socket($tempname,$sendchat);
		return 1;
		}
}

sub show(){
	my $self=shift;
#	print "调试用 开始调用SHOW   t=$t\n";
	$self->{win}->Text("$self->{title}$this->{display}->{diplay_text_chating}");
	$self->{win}->CB2->SetFocus();
	$self->{win}->Show();
    #$self->{q};
}

1;
__END__

