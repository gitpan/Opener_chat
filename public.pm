package public;

@ISA= qw( Exporter);
@EXPORT = qw(runperlfile tomkdir);

sub runperlfile{
	use Win32::Process;
	my ($pro,$pare)=@_;			
	system("start perl $pro $pare"); print "start perl $pro $pare\n"; return;
		my $id=Win32::Process::Create(				
		my $p_id,
		"$^X",
		"perl $pro $pare",
		0,
		($xian eq undef)?CREATE_NO_WINDOW:CREATE_NEW_CONSOLE,
		".") or print "start task $1 err!" and 	$this->msg_to_gui(14,$pro);		
		$this->msg_to_gui(13,$pro);
	return $p_id;
}

sub tomkdir{
	my $s=shift;
	if($s=~/\\/){
		my @dir=split(/\\/,$s);
		$s="";
		foreach  (@dir) {
			$s.="$_\\";
			mkdir($s);
		}
	}
	else{
		mkdir($s);
	}
}
1;
__END__

