#!/usr/bin/perl -w
######################################################################
#
#	semeval_script.pl
#	Megan Davis
#	10/7/2017
#
#   Utilizing Code from: 
#  	   Lingua::EN::Tagger
#   Text Used:   
#     SCL-NMA -- http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm ### Semeval-2016 Task 7: Determining Sentiment Intensity of English and Arabic Phrases. Svetlana Kiritchenko, Saif M. Mohammad, and Mohammad Salameh. In Proceedings of the International Workshop on Semantic Evaluation (SemEval ’16). June 2016. San Diego, California.
#
########################################################################
#
#	ROLES
#	Megan Davis - Author of semeval_script.pl, and procedural implementation within powerpoint. Set up trello board.
#   Andrew Ward - Author of task information/introduction and proposed approach. In addition to providing suggestions on solutions implemented. (Also implemented code not included in code drop #1)
#	Kellan Childers -- Author of word2vec implementation, word2vec powerpoint details. Setup github project.
#
#  ALL CODE IN THIS PROGRAM IS AUTHORED BY MEGAN DAVIS UNLESS OTHERWISE SPECIFIED
#####################################################################
#	
#	How to Run:
#   1) Have semeval_script.pl, SCL-NMA.txt, and dev-full.txt
#	2) Run perl semeval_script.pl dev-full.txt SCL-NMA/SCL-NMA.txt
#
#	ONLY TESTED ON WINDOWS 10  
#
#######################################################################
#
#
#	ALGORTHIM:
#	The algorithm follows the directions of those in the README file. Additional comments have been provided in the code. But ultimately reference the README points.
#
###############################################################################



# USE 
use warnings;
use strict;
use Data::Dumper qw(Dumper);
use Lingua::EN::Tagger; ## Currently not used in code #1 implementation
use Lingua::NegEx qw( negation_scope );

$Data::Dumper::Sortkeys = 1;

# Files: Currently utilizes two files dev-full.txt, SCL-NMA.txt
my $filename = $ARGV[0];
my $filename2 = $ARGV[1];
my $filename3 = $ARGV[2];
my $filename4 = $ARGV[3];
my $filename5 = $ARGV[4];

# Variables
my %OverallHash; #Hash containing all the data
my %WordSentimentHash; #Hash containing the data from SCL-NMA.txt
my %SentiWordHash;
my %Word_Duplicate_Hash;
my %Results;
my $num = 0; #Used assign a unique ID to hashes
my $negated_changed_values = 0;


# Variables Not Being Used -- but still declaring to avoid run errors.
my $p = new Lingua::EN::Tagger;
my %unigram;
my $unigram_frequency = 0;
my $all_text;
my %bigram;
my $bigram_frequency = 0;

################ 2 ####################################
#Open Dev-Full Text and read in the data/ preform text manipulations 
open(my $fh, '<', $filename) or die "Could not open";	
while(my $row = <$fh>)
{
	my @temparray = split('\t',$row);


	$OverallHash{$temparray[0]}{Claim} = text_sanitation($temparray[4]);
	$OverallHash{$temparray[0]}{Claim_Tagged} = $p->get_readable(text_sanitation($temparray[4]));
=begin my $array_ref = negation_scope($temparray[4]);
	if (scalar $array_ref > 0)
	{
		$OverallHash{$temparray[0]}{Claim_Negation_Scope} = join (',',@$array_ref);
		#print $OverallHash{$temparray[0]}{Reason_Negation_Scope} . "\n";
	}
=cut
	$OverallHash{$temparray[0]}{Reason} = text_sanitation($temparray[5]);
	$OverallHash{$temparray[0]}{Reason_Tagged} = $p->get_readable(text_sanitation($temparray[5]));
=begin	
	$array_ref = negation_scope($temparray[5]);
	if (scalar $array_ref > 0)
	{
		$OverallHash{$temparray[0]}{Reason_Negation_Scope} = join (',',@$array_ref);
		#print $OverallHash{$temparray[0]}{Reason_Negation_Scope} . "\n";
	}
=cut

	

	$OverallHash{$temparray[0]}{Warrant0} = text_sanitation($temparray[1]);
	$OverallHash{$temparray[0]}{Warrant0_Tagged} = $p->get_readable(text_sanitation($temparray[1]));
=begin
	$array_ref = negation_scope($temparray[1]);
	if (scalar $array_ref > 0)
	{
		$OverallHash{$temparray[0]}{Warrant0_Negation_Scope} = join (',',@$array_ref);
		#print $OverallHash{$temparray[0]}{Reason_Negation_Scope} . "\n";
	}
=cut
	$OverallHash{$temparray[0]}{Warrant1} = text_sanitation($temparray[2]);
	$OverallHash{$temparray[0]}{Warrant1_Tagged} = $p->get_readable(text_sanitation($temparray[2]));
=begin
	$array_ref = negation_scope($temparray[2]);
	if (scalar $array_ref > 0)
	{
		$OverallHash{$temparray[0]}{Warrant1_Negation_Scope} = join (',',@$array_ref);
		#print $OverallHash{$temparray[0]}{Reason_Negation_Scope} . "\n";
	}
=cut
	$OverallHash{$temparray[0]}{Warrant0_Value} = 0;
	$OverallHash{$temparray[0]}{Warrant1_Value} = 0;
	$OverallHash{$temparray[0]}{Reason_Value} = 0;
	$OverallHash{$temparray[0]}{Claim_Value} = 0;


	$OverallHash{$temparray[0]}{CorrectLabel} = $temparray[3];
	$OverallHash{$temparray[0]}{Debate_Title} = $temparray[6];
	$OverallHash{$temparray[0]}{Debate_Info} = $temparray[7];
	$OverallHash{$temparray[0]}{Answer} = -1;
	$OverallHash{$temparray[0]}{sentiment_value} = 0;	

	data_set_tag_mapping($temparray[0], 'Reason_Tagged');
	data_set_tag_mapping($temparray[0], 'Claim_Tagged');
	data_set_tag_mapping($temparray[0], 'Warrant0_Tagged');
	data_set_tag_mapping($temparray[0], 'Warrant1_Tagged');

}
 
open($fh, '<', $filename2) or die "Could not open";	
while(my $row = <$fh>)
{
	# lemma#PoS	prior_polarity_score
	if($row =~ m/(.*)\s-?+[0-9.]{2,}\n$/)
	{
		$row =~ s/\n//g;
		my @temparray = split('\t',$row);
		$SentiWordHash{$temparray[0]} = $temparray[1];
	}
}

sentiment_value_tagging_senti();

#Maps the tags
sub data_set_tag_mapping
{
	my ($id, $key2) = @_;
	
	$OverallHash{$id}{$key2} =~ s/\/(NNP|NNPS|NNS|NN)/#n/g;
	$OverallHash{$id}{$key2} =~ s/\/(RBR|RBS|RP|RB)/#r/g;
	$OverallHash{$id}{$key2} =~ s/\/(CD|JJR|JJS|JJ)/#a/g;
	$OverallHash{$id}{$key2} =~ s/\/(MD|VBN|VBD|VBG|VBP|VBZ|VB)/#v/g;	
}

#Adds the Sentiment Values tags & Calls for data to be calculated
sub sentiment_value_tagging_senti
{
	foreach my $k (keys %OverallHash)
	{
		foreach my $k2 (keys %SentiWordHash) 
		{
			data_value_tagging($k, 'Reason_Tagged', $k2);
			data_value_tagging($k, 'Claim_Tagged', $k2);
			data_value_tagging($k, 'Warrant0_Tagged', $k2);
			data_value_tagging($k, 'Warrant1_Tagged', $k2);
		}

		sentiment_value_calc_for_senti($k,'Reason_Tagged', 'Reason_Value', 'Reason_Negation_Scope');
		sentiment_value_calc_for_senti($k,'Claim_Tagged', 'Claim_Value', 'Claim_Negation_Scope');
		sentiment_value_calc_for_senti($k,'Warrant0_Tagged', 'Warrant0_Value', 'Warrant0_Negation_Scope');
		sentiment_value_calc_for_senti($k,'Warrant1_Tagged', 'Warrant1_Value', 'Warrant1_Negation_Scope');
	}
}

sub check_values{

}

#Tags Value of Words
sub data_value_tagging{
	my ($key1, $key2, $sentikey) = @_;

	if($OverallHash{$key1}{$key2} =~ m/\b($sentikey)\b/)
	{
		my $v = $SentiWordHash{$sentikey};
		$OverallHash{$key1}{$key2} =~ s/\b($sentikey)\b/$1\($v\)/g;
		#print "$1 : $w \n";
	}

}

#Calculates
sub sentiment_value_calc_for_senti{
	my ($key1, $key2, $value, $negation) = @_;

	if($OverallHash{$key1}{$key2} =~ /\b(n't#r|not#r|cannot#n|cannot#v)\b/)
	{
		#print "------\n";
		#print "Before: \n";
		my @split_text = split(' ',$OverallHash{$key1}{$key2});
		#print Dumper \@split_text;
		for (my $array_element = 0; $array_element < scalar @split_text; $array_element++)
		{
			if($split_text[$array_element] =~ /\b(n't#r|not#r|cannot#n|cannot#v)\b/)
			{
				#print "Contains NOT or CANNOT\n";
				for (my $sub_loop = $array_element + 1; $sub_loop < scalar @split_text; $sub_loop++)
				{
					#print $split_text[$sub_loop];
					#print " ";
					if($split_text[$sub_loop] =~ /\(-/)
					{
						$split_text[$sub_loop] =~ s/\(-/\(/g;
					}
					elsif($split_text[$sub_loop] =~ /\(/)
					{
						$split_text[$sub_loop] =~ s/\(/\(-/g;
					}
					
				}
			}
		}
		#print "\nAfter:\n ";
		#print Dumper \@split_text;
		$OverallHash{$key1}{$key2} = join(" ", @split_text);
	}


	my @matches = ($OverallHash{$key1}{$key2} =~ /-?[0-9]+\.?[0-9]+/g);

	if((scalar @matches) > 0)
	{
		foreach my $num (@matches)
		{	
			$OverallHash{$key1}{$value} += $num;
		}
	}
}

########################################################

#Subroutines called#
COMAPRISION_SHOWDOWN(); #5
accuracy(); #6

#print_hash(); #-- Can be used to print out OverallHash


############# Sub Routines ######################
#
#		There are two sub routine sections -- USED and NOT USED.
#		THESE ARE ORDER IN ALPHABETICAL ORDER.  
#		
#		USED -- Are currently active within the current runnable program
#		NOT USE -- Subroutines created that are not used in the current runnable program (But not worth deleting in case brought back to be used)
#
#
#################################################

######################## USED ###########################

#COMAPRISION SHOW DOWN (CAPS BECAUSE THIS IS IMPORTANT)
# Algorithm Step #5
# 1) Calculate which warrant is closer to the claim_reason_sentiment
# 2) Assigns the answer to Hash for comparision
sub COMAPRISION_SHOWDOWN{
	my $equal = 0;	

	foreach my $k(keys %OverallHash)
	{
		#Algorithm Step #5.1
		#my $warrant_0 = abs(($OverallHash{$k}{Reason_Value} + $OverallHash{$k}{Claim_Value}) - $OverallHash{$k}{Warrant0_Value});
		#my $warrant_1 = abs(($OverallHash{$k}{Reason_Value} + $OverallHash{$k}{Claim_Value}) - $OverallHash{$k}{Warrant1_Value});

		my $warrant_0 = abs($OverallHash{$k}{Reason_Value} - $OverallHash{$k}{Warrant0_Value});
		my $warrant_1 = abs($OverallHash{$k}{Reason_Value} - $OverallHash{$k}{Warrant1_Value});

		if($warrant_0 < $warrant_1)
		{
			$OverallHash{$k}{Answer} = '0';
		}	
		elsif ($warrant_1 < $warrant_0) #Algorithm Step #5.2.2
		{
			$OverallHash{$k}{Answer} = '1';
		}
		else #Algorithm Step #5.2.3
		{
			$OverallHash{$k}{Answer} = '-1';	
			$equal++;
		}
	}
	print "Instances in which warrants = 0.... : $equal \n";
}

#Checks how many claims were accurately tagged (currently using randomness baseline) 
#Algorithm Step #6
#-------------- Total Labels --------------
#Correct: 157 
#Total Labels: 317 
#Overall Accuracy: 49.5268138801262 
#The above data was generated using random_sample
sub accuracy{
	my $totalLabels = 0;
	my $correctTotalLabels = 0;
	foreach my $key (keys %OverallHash)
	{
		if($OverallHash{$key}{Answer} eq $OverallHash{$key}{CorrectLabel} )
		{
			$correctTotalLabels++;
		}
		else
		{
			print "------------------------\n";
			#print "ID: $OverallHash{$key}{ID} \n ";
			#print "Debate Title: $OverallHash{$key}{Debate_Title}\n";
			#print "Debate Info: $OverallHash{$key}{Debate_Info} ";
			#print "Claim : $OverallHash{$key}{Claim_Tagged}\n ";
			#print "Claim : $OverallHash{$key}{Claim_Value}\n ";
			print "Reason: $OverallHash{$key}{Reason_Tagged}\n ";
			print "Reason: $OverallHash{$key}{Reason_Value}\n ";
			print "Warrant 0: $OverallHash{$key}{Warrant0_Tagged}\n ";
			print "Warrant0 Value: $OverallHash{$key}{Warrant0_Value}\n";					
			print "Warrant 1: $OverallHash{$key}{Warrant1_Tagged}\n";
			print "Warrant1 Value: $OverallHash{$key}{Warrant1_Value}\n";
			print "CorrectLabel: $OverallHash{$key}{CorrectLabel}\n";	
			print "Answer: $OverallHash{$key}{Answer}\n";
			print "------------------------\n";
		}
		$totalLabels++;
	}


	my $accuracy = ($correctTotalLabels / $totalLabels) * 100;

	print "-------------- Total Labels --------------\n";
	print "Correct: $correctTotalLabels \n";
	print "Total Labels: $totalLabels \n";
	print "Overall Accuracy: $accuracy";
}

#Prints out hash using Dumper
sub print_hash{
	#my %tempHash = $_[0];
	print "########################################\n";
	#print Dumper \%unigram;
	print "########################################\n";
	#print Dumper \%bigram;
	print "########################################\n";
	print Dumper \%OverallHash;
	#print Dumper \%SentiWordHash;
	#print Dumper \%Word_Duplicate_Hash;
	print "########################################\n";
	#print Dumper \%WordSentimentHash;
	print "########################################\n";
}

## Sanatizes Text
sub text_sanitation{
	my $my_text = $_[0];
	#$my_text =~ s/n't/ not/g;
	$my_text =~ s/[0-9]{1,}[A-Za-z]+//g;
	#$my_text =~ s/[[:punct:]]//g;
	$my_text =~ s/\n+/\n/g;
	$my_text =~ s/\s+/ /g;
	$my_text = lc($my_text);
	return $my_text;
}

sub output_confidence_csv{
	my $csv_file = 'perl_confidence_interval.txt';
	open(my $fh, '>', $csv_file) or die "Could not open file '$csv_file' $!";
	# ID, TAG, CONFIDENCE
	#print $fh "My first report generated by perl\n";
	close $fh;
	#print "done\n";
}

################################################
#		NOT USED SUB ROUTINES
###############################################

# creates a bi-gram of $all_text
sub create_bigram{
	my @words = split(/\s/, $all_text);
	for(my $i = 0; $i < $#words; $i++)
	{
		my $temp_text = $words[$i] . " " . $words[$i + 1];	
		if(!exists($bigram{$temp_text}))
		{
			$bigram{$temp_text} = 1;
		}
		else
		{
			$bigram{$temp_text}++;
		}
		$bigram_frequency++;		
	}
}

#Creates a Unigram out of $all_text
sub create_unigram{
	my @words = split(/\s/, $all_text);
	for(my $i = 0; $i <= $#words; $i++)
	{
		if(!exists($unigram{$words[$i]}))
		{
			$unigram{$words[$i]} = 1;
		}
		else
		{
			$unigram{$words[$i]}++;
		}
		$unigram_frequency++;
	}
}

### THis bigram only pulls text that has certain tags -- Tag selection pulled from Thumbs Up Thumbs Down Paper
sub create_tagged_bigram{
	my @words = split(/\s/, $all_text);
	for(my $i = 0; $i < $#words; $i++)
	{
		my $temp_text = $words[$i] . " " . $words[$i + 1];	
		if($words[$i] =~ /(NN|NNS)/)
		{
			if($words[$i+1] =~ /JJ/)
			{
				if(!exists($bigram{$temp_text}))
				{
					$bigram{$temp_text} = 1;
				}
				else
				{
					$bigram{$temp_text}++;
				}
				$bigram_frequency++;
			}
		}
		elsif($words[$i] =~ /JJ/)
		{
			if($words[$i+1] =~ /(JJ|NNS|NN)/)
			{
				if(!exists($bigram{$temp_text}))
				{
					$bigram{$temp_text} = 1;
				}
				else
				{
					$bigram{$temp_text}++;
				}
				$bigram_frequency++;
			}
		}
	}
}

#Uses rand to 'guess' the answers
sub random_sample{
	foreach my $key (keys %OverallHash)
	{
		my $tempRandom = rand();
		if($tempRandom > .5)
		{
			$OverallHash{$key}{Answer} = '1';
		}
		else
		{
			$OverallHash{$key}{Answer} = '0';
		}		
	}
}


