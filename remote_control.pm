package remote_control;
use network;
use Win32::Process;

sub get_data{
	my $data=shift;
	my $from=shift;
	my $g=shift;
	my $flag=shift;

	if ($flag eq 'vnc_control') {
		if ($data=~m|^vnc_control: 用户请求桌面控制连接!|) {
			$result = Win32::GUI::MessageBox(0,"$g->{display}->{msgbox_text_Agree_with_Remote_Control}$from?","$from $g->{display}->{msgbox_text_ask_vnc_control}",0x0004|0x0020|0x40000);
			if($result == 6) { 
				my $out_ip=$g->{api}->{ip};
				my $port=$g->{command}->{local_vnc_port};
				while (!network::test_server_port($g->{command}->{local_vnc_port})) {
					$g->{command}->{local_vnc_port}++;
				}
				$g->{run_sub_process}->{'!!vnc_client!!'}->{$from}=vnc_client($g->{command}->{local_vnc_port});
				my $local_ip=network::get_local_ip();
				if ($local_ip eq $out_ip) {
					$g->{api}->sendcommand($from,"vnc_control: 控制端已经打开。等待连接：$local_ip $g->{command}->{local_vnc_port}");
				}else{
					$g->{api}->sendcommand($from,"vnc_control: 控制端已经打开。测试网络：$local_ip $out_ip $g->{command}->{local_vnc_port}");
				}
				
				}
			if($result == 7) { 
				$g->{api}->sendcommand($from,"vnc_control: 不同意用户请求连接!");
			}
			return;   
		}
		if($data=~m|^vnc_control: 控制端已经打开。等待连接：(.*?)\s+(.*)|) {
					my $ip=$1;
					my $port=$2;			
					$g->{run_sub_process}->{'!!vnc_server!!'}=vnc_server($ip,$port);
					Win32::GUI::MessageBox(0,
						"$from$g->{display}->{msgbox_text_agree_ask}\r\n",
						"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
					);
					$g->{window}->{mainwin}->serv->Text("$g->{display}->{msgbox_text_vnc_control}");
					$g->{window}->{mainmenu}->{vnc}->Enabled(1);
					return 1;
		}
		if($data=~m|^vnc_control: 控制端已经打开。测试网络：(.*?)\s+(.*?)\s+(.*)|) {
					my $remote_local_ip=$1;
					my $remote_out_ip=$2;
					my $port=$3;
					my $out_ip=$g->{api}->{ip};
					if ($out_ip eq $remote_out_ip) {
						$g->{run_sub_process}->{'!!vnc_server!!'}=vnc_server($remote_local_ip,$port);
					}else{
						$g->{run_sub_process}->{'!!vnc_server!!'}=vnc_server($remote_out_ip,$port);
					}
					Win32::GUI::MessageBox(0,
						"$from$g->{display}->{msgbox_text_agree_ask}\r\n",
						"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
					);
					$g->{window}->{mainwin}->serv->Text("$g->{display}->{msgbox_text_vnc_control}");
					$g->{window}->{mainmenu}->{vnc}->Enabled(1);
					return 1;
		}
		if($data=~m|^vnc_control: 不同意用户请求连接!|){
			Win32::GUI::MessageBox(0,
				"$from$g->{display}->{msgbox_text_not_agree_request}!\r\n",
				"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$g->{window}->{mainmenu}->{vnc}->Change(-text =>"(&V)vnc$g->{display}->{text_connect_ask}");
			$g->{window}->{mainmenu}->{vnc}->Enabled(1);
			$g->{switch}->{mvnc}=0;
			$g->{window}->{mainwin}->serv->Text("$g->{display}->{text_services_not_connect}");
			return 1;
		}
		if($data=~m|^vnc_control: 用户断开连接!|){
			Win32::GUI::MessageBox(0,
				"$from$g->{display}->{msgbox_text_cut_connect}!\r\n",
				"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$g->{run_sub_process}->{'!!vnc_client!!'}->{$from}->Kill(0);
			return 1;  
		}
		if($data=~m|^vnc_control: 管理端断开连接!|){
			Win32::GUI::MessageBox(0,
				"$from$g->{display}->{msgbox_text_cut_connect}!\r\n",
				"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$g->{run_sub_process}->{'!!vnc_server!!'}->Kill(0);
			return 1;  
		}
	}
	elsif($flag eq 'dos_control'){
		if ($data=~m|^dos_control: 用户请求连接!|) {
			$result = Win32::GUI::MessageBox(0,"$g->{display}->{msgbox_text_Agree_with_Remote_Control}$from?","$from$g->{display}->{msgbox_text_ask_dos_control}",0x0004|0x0020|0x40000);
			if($result == 6) { 
				my $out_ip=$g->{api}->{ip};
				my $port=$g->{command}->{local_dos_port};
				while (!network::test_server_port($g->{command}->{local_dos_port})) {
					$g->{command}->{local_dos_port}++;
				}
				$g->{run_sub_process}->{'!!dos_client!!'}->{$from}=$g->{api}->runperlfile("kongzhi.pl","$out_ip $port",1);
				my $local_ip=network::get_local_ip();
				if ($local_ip eq $out_ip) {
					$g->{api}->sendcommand($from,"dos_control: 控制端已经打开。等待连接：$local_ip $g->{command}->{local_dos_port}");
				}else{
					$g->{api}->sendcommand($from,"dos_control: 控制端已经打开。测试网络：$local_ip $out_ip $g->{command}->{local_dos_port}");
				}
			}
			if($result == 7) {
				$g->{api}->sendcommand($from,"dos_control: 不同意用户请求连接!");
			}
			return 1;
		}
		if($data=~m|^dos_control: 控制端已经打开。等待连接：(.*?)\s+(.*)|) {
					my $ip=$1;
					my $port=$2;			
					$g->{run_sub_process}->{'!!dos_server!!'}=$g->{api}->runperlfile("beikong.pl","$ip $port");
					Win32::GUI::MessageBox(0,
						"$from$g->{display}->{msgbox_text_agree_ask}\r\n",
						"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
					);
					$g->{window}->{mainwin}->serv->Text("$g->{display}->{msgbox_text_dos_control}");
					$g->{window}->{mainmenu}->{cmdservices}->Enabled(1);
					return 1;
		}
		if($data=~m|^dos_control: 控制端已经打开。测试网络：(.*?)\s+(.*?)\s+(.*)|) {
					my $remote_local_ip=$1;
					my $remote_out_ip=$2;
					my $port=$3;
					my $out_ip=$g->{api}->{ip};
					if ($out_ip eq $remote_out_ip) {
						$g->{run_sub_process}->{'!!dos_server!!'}=$g->{api}->runperlfile("beikong.pl","$remote_local_ip $port");
					}else{
						$g->{run_sub_process}->{'!!dos_server!!'}=$g->{api}->runperlfile("beikong.pl","$remote_out_ip $port");
					}
					Win32::GUI::MessageBox(0,
						"$from$g->{display}->{msgbox_text_agree_ask}\r\n",
						"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
					);
					$g->{window}->{mainwin}->serv->Text("$g->{display}->{msgbox_text_dos_control}");
					$g->{window}->{mainmenu}->{cmdservices}->Enabled(1);
					return 1;
		}
		if($data=~m|^dos_control: 用户断开连接!|){
			Win32::GUI::MessageBox(0,
				"$from$g->{display}->{msgbox_text_cut_dos_connect}!\r\n",
				"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$g->{run_sub_process}->{'!!dos_client!!'}->{$from}->Kill(0);
			return 1;  
		}
		if($data=~m|^dos_control: 不同意用户请求连接!|){
			Win32::GUI::MessageBox(0,
				"$from$g->{display}->{msgbox_text_not_agree_request}!\r\n",
				"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$g->{window}->{mainmenu}->{cmdservices}->Change(-text =>"(&S)$g->{display}->{msgbox_text_ask_dos_control}");
			$g->{switch}->{mcmd}=0;
			$g->{window}->{mainwin}->serv->Text("$g->{display}->{text_services_not_connect}");
			$g->{window}->{mainmenu}->{cmdservices}->Enabled(1);
			return 1;
		}
		if($data=~m|^dos_control: 管理端断开连接!|){
			Win32::GUI::MessageBox(0,
				"$from$g->{display}->{msgbox_text_cut_connect}!\r\n",
				"$g->{display}->{msgbox_title_ts}",0x0040|0x40000
			);
			$g->{run_sub_process}->{'!!dos_server!!'}->Kill(0);
			return 1;  
		}
	}else{
		return 0;
	}

}

sub vnc_client{
	my $port=shift;
	Win32::Process::Create(
				my $pro,
				'vncviewer.exe',
				"vncviewer.exe /listen $port",
				0,
				NORMAL_PRIORITY_CLASS,
				".") or die "Cant create vnc_client\n";
	return $pro;
}

sub vnc_server{
	my $ip=shift;
	my $port=shift;
	Win32::Process::Create(
		my $pro,
		"WinVNC.exe",
		"WinVNC.exe",
		0,
		NORMAL_PRIORITY_CLASS,
		".") or die "Cant create vnc_server\n";
	select(undef,undef,undef,0.2);##如果没有停顿，可能导致vnc无法正确连接客户端
	Win32::Process::Create(
		my $pro2,
		"WinVNC.exe",
		"WinVNC.exe -connect $ip:$port",
		0,
		NORMAL_PRIORITY_CLASS,
		".") or die "vnc_server Cant connect to client\n";
	return $pro;
}

1;

