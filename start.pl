#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use Data::Dumper;
use public;

find(\&deltmpf,"tmp\\");
sub deltmpf{
	return unless(/\w.+_\d{7}\.txt/);
	print "del tmpfile: $_\n";
	unlink $_;
}

BEGIN {
use Fcntl qw(:flock);               # for the LOCK_* constants
mkdir("tmp") unless(-d "tmp");
open(FH, ">tmp\\pid.txt") ;
#flock(FH, LOCK_EX|LOCK_NB) or exit(0);
print FH $$;
#close(FH);
}
END{
	close(FH);
}

my $g={};
my @set=&getini();
#die Dumper $list;

my $i;
my $runfile="";
my $tmpdir="tmp";
&tomkdir ($tmpdir) unless(-d $tmpdir);
my $allfile;
my $key;
	foreach(@set){
		chomp;
		next if($_ eq "" or /^\#/);
		if(/\[(.+)\]/){
			return if(lc($1) eq "end");
			$key=$1;
			next;
		}
	my $exchangef="$tmpdir\\".$i++.".txt";
	if(lc($key) eq "irc"){
		$runfile="irc.pl";
	}
	elsif(lc($key) eq "msn"){
		$runfile="msn.pl";
	}
	elsif(lc($key) eq "qq"){
		$runfile="qq.pl";
	}
	$g->{api}->{$runfile}->{$i}="$_ $exchangef";
	$allfile.="$exchangef ";
}

print "(proscenium.pl,$allfile); \n";
&runperlfile("proscenium.pl",$allfile); 
foreach my $run (keys %{$g->{api}}) {
	foreach  (keys %{$g->{api}->{$run}}) {
	my $parameter=$g->{api}->{$run}->{$_};
	print "($run,$parameter); \n";
	&runperlfile($run,$parameter); 
	}
}
exit;


sub getini{
	my $key;			# 关键字 这里指的是 配置文件中 用方括号括起来的字符串
	open(INIFILE,"setlogin.ini");
	my @all=<INIFILE>;
	close INIFILE;
	return @all;
}