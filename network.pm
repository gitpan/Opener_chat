package network;
use strict;
use IO::Socket;

sub test_server_live{
	my $ip=shift;
	my $port=shift;
	my $sock = IO::Socket::INET->new(PeerAddr => $ip,
                                 PeerPort => $port,
                                 Proto    => 'tcp',
								 Timeout=>'0.1') or return 0;
	close($sock);
	return 1;
}

sub test_server_port{
	my $port=shift;
	my $sock = IO::Socket::INET->new(Listen    => 1,
									 LocalPort => $port,
									 Proto     => 'tcp') or return 0;
	close($sock);
	return 1;
}
sub get_local_ip{
	my $sock = IO::Socket::INET->new(PeerAddr => 'www.163.com',
                                 PeerPort => '80',
                                 Proto    => 'tcp');
	my $local_ip=$sock->sockhost(); 
	close($sock);
	return $local_ip;
}


sub test_net_env{

}
1;
