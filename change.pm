#############################¸ü¸ÄICONÄ£¿é################################
package change;
use warnings;
use Win32::Process;


sub changeicon{
	my $ni = shift; 
	my $icon   = shift;
	$ni->Change(-icon => $icon);
}


sub changeballoon
{
   my $ni = shift;
   my $value = shift;
   my $xian=shift;
		$ni->Change("-balloon_title" => "$xian");
		$ni->Change("-balloon_tip" => $value);
		$ni->Change("-balloon_timeouy" => 1000);
        $ni->ShowBalloon(1);
}



1;
__END__

