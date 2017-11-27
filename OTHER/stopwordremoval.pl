###########################################################################
#  stoplist sub function -- FROM  Text::NSP
###########################################################################
sub stop_word_removal { 

    my $stop_regex = "";
    my $stop_mode = "AND";
    my $opt_stop = "stoplist-nsp.regex";

    open ( STP, $opt_stop ) ||
        die ("Couldn't open the stoplist file $opt_stop\n");
    
    while ( <STP> ) {
	chomp; 
	
	if(/\@stop.mode\s*=\s*(\w+)\s*$/) {
	   $stop_mode=$1;
	   	if(!($stop_mode=~/^(AND|and|OR|or)$/)) {
			print STDERR "Requested Stop Mode $1 is not supported.\n";
			exit;
	   	}
	   	next;
	} 
	
		# accepting Perl Regexs from Stopfile
		s/^\s+//;
		s/\s+$//;
	
		#handling a blank lines
		if(/^\s*$/) { next; }
	
	 	#check if a valid Perl Regex
    	if(!(/^\//)) {
	   		print STDERR "Stop token regular expression <$_> should start with '/'\n";
			exit;
        }
        if(!(/\/$/)) {
		   print STDERR "Stop token regular expression <$_> should end with '/'\n";
		   exit;
        }

        #remove the / s from beginning and end
    	s/^\///;
    	s/\/$//;
        
		#form a single big regex
    	$stop_regex.="(".$_.")|";
    }

    if(length($stop_regex)<=0) {
		print STDERR "No valid Perl Regular Experssion found in Stop file $opt_stop";
		exit;
    }
    
    chop $stop_regex;
    
    # making AND a default stop mode
    if(!defined $stop_mode) {
		$stop_mode="AND";
    }
    
    close STP;
    
    return $stop_regex; 
}
