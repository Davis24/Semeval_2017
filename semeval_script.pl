#!/usr/bin/perl -w
######################################################################
#
#	semeval_script.pl
#	Megan Davis
#	10/7/2017
#
#   Utilizing Code from: 
#  	   Lingua::EN::Tagger
#	   Text::English
#   Text Used:   
#     SentiWords_1.0 - Guerini M., Gatti L. & Turchi M. “Sentiment Analysis: How to Derive Prior Polarities from SentiWordNet”. In Proceedings of the 2013 Conference on Empirical Methods in Natural Language Processing (EMNLP'13), pp 1259-1269. Seattle, Washington, USA. 2013.
#
########################################################################
#
#	ROLES
#	Megan Davis - Author of semeval_script.pl, and rules based implementation within powerpoint. Set up trello board.
#   Andrew Ward - Author of task information/introduction and proposed approach. In addition to providing suggestions on solutions implemented. (Also implemented code not included in code drop #1)
#	Kellan Childers -- Author of word2vec implementation, word2vec powerpoint details. Setup github project.
#
#  ALL CODE IN THIS PROGRAM IS AUTHORED BY MEGAN DAVIS UNLESS OTHERWISE SPECIFIED
#####################################################################
#	
#	How to Run:
#   1) Have semeval_script.pl, SentiWords_1.0 (can be found here https://hlt-nlp.fbk.eu/technologies/sentiwords), and dev-full.txt
#	2) Run perl semeval_script.pl dev-full.txt SCL-NMA/SCL-NMA.txt
#
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
use Text::English;
use Lingua::EN::Tagger;

$Data::Dumper::Sortkeys = 1;

# Files: Currently utilizes two files dev-full.txt, SCL-NMA.txt
my $filename = $ARGV[0];
my $filename2 = $ARGV[1];

# Variables
my $p = new Lingua::EN::Tagger; ## For a list of the tags it used (Penn Treebank) reference http://cpansearch.perl.org/src/ACOBURN/Lingua-EN-Tagger-0.28/README
my %DataHash; #Hash containing all the data
my %SentiWordHash;
#my %Results;

# Variables Not Being Used -- but still declaring to avoid run errors.

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

	### Claim ###
	$DataHash{$temparray[0]}{Claim} = text_sanitation($temparray[4]);
	#$DataHash{$temparray[0]}{Claim_Tagged} = $p->get_readable(text_sanitation($temparray[4]));

	### Reason ###
	$DataHash{$temparray[0]}{Reason} = text_sanitation($temparray[5]);
	my @temp_array_text = split (' ', $DataHash{$temparray[0]}{Reason});
	$DataHash{$temparray[0]}{Reason_Stemmed_Tagged} =$p->get_readable(text_sanitation(join (' ',Text::English::stem( @temp_array_text))));
	$DataHash{$temparray[0]}{Reason_Tagged} = $p->get_readable(text_sanitation($temparray[5]));

	### Warrant0 ###
	$DataHash{$temparray[0]}{Warrant0} = text_sanitation($temparray[1]);
	$DataHash{$temparray[0]}{Warrant0_Tagged} = $p->get_readable(text_sanitation($temparray[1]));
	@temp_array_text = split (' ', $DataHash{$temparray[0]}{Warrant0});
	$DataHash{$temparray[0]}{Warrant0_Stemmed_Tagged} =$p->get_readable(text_sanitation(join (' ',Text::English::stem( @temp_array_text))));
	
	### Warrant1 ###
	$DataHash{$temparray[0]}{Warrant1} = text_sanitation($temparray[2]);
	$DataHash{$temparray[0]}{Warrant1_Tagged} = $p->get_readable(text_sanitation($temparray[2]));
	@temp_array_text = split (' ', $DataHash{$temparray[0]}{Warrant1});
	$DataHash{$temparray[0]}{Warrant1_Stemmed_Tagged} =$p->get_readable(text_sanitation(join (' ',Text::English::stem( @temp_array_text))));

	### Value Assignment ###
	$DataHash{$temparray[0]}{Warrant0_Value} = 0;
	$DataHash{$temparray[0]}{Warrant1_Value} = 0;
	$DataHash{$temparray[0]}{Reason_Value} = 0;
	$DataHash{$temparray[0]}{Reason_Stemmed_Value} = 0;
	$DataHash{$temparray[0]}{Warrant0_Stemmed_Value} = 0;
	$DataHash{$temparray[0]}{Warrant1_Stemmed_Value} = 0;
	$DataHash{$temparray[0]}{Claim_Value} = 0;
	$DataHash{$temparray[0]}{CorrectLabel} = $temparray[3];
	$DataHash{$temparray[0]}{Debate_Title} = $temparray[6];
	$DataHash{$temparray[0]}{Debate_Info} = $temparray[7];
	$DataHash{$temparray[0]}{Answer} = -1;


	### Call to convert Tagger tags to SentiNet tags ###
	data_set_tag_mapping($temparray[0], 'Reason_Tagged');
	data_set_tag_mapping($temparray[0], 'Reason_Stemmed_Tagged');
	#data_set_tag_mapping($temparray[0], 'Claim_Tagged');
	data_set_tag_mapping($temparray[0], 'Warrant0_Tagged');
	data_set_tag_mapping($temparray[0], 'Warrant0_Stemmed_Tagged');
	data_set_tag_mapping($temparray[0], 'Warrant1_Stemmed_Tagged');
	data_set_tag_mapping($temparray[0], 'Warrant1_Tagged');

}
 
open($fh, '<', $filename2) or die "Could not open SentiWordNet File.";	
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

#Used to map the tags from Tagger to SentiNet's tags, 
sub data_set_tag_mapping
{
	my ($id, $key2) = @_;
	
	$DataHash{$id}{$key2} =~ s/\/(NNP|NNPS|NNS|NN)/#n/g;
	$DataHash{$id}{$key2} =~ s/\/(RBR|RBS|RP|RB)/#r/g;
	$DataHash{$id}{$key2} =~ s/\/(CD|JJR|JJS|JJ)/#a/g;
	$DataHash{$id}{$key2} =~ s/\/(MD|VBN|VBD|VBG|VBP|VBZ|VB)/#v/g;	
}

#Adds the Sentiment Values tags & Calls for data to be calculated
sub sentiment_value_tagging_senti
{
	foreach my $k (keys %DataHash)
	{
		foreach my $k2 (keys %SentiWordHash) 
		{
			data_value_tagging($k, 'Reason_Tagged', $k2);
			data_value_tagging($k, 'Reason_Stemmed_Tagged', $k2);
			#data_value_tagging($k, 'Claim_Tagged', $k2);
			data_value_tagging($k, 'Warrant0_Tagged', $k2);
			data_value_tagging($k, 'Warrant0_Stemmed_Tagged', $k2);
			data_value_tagging($k, 'Warrant1_Tagged', $k2);
			data_value_tagging($k, 'Warrant1_Stemmed_Tagged', $k2);
		}

		sentiment_value_calc_for_senti($k,'Reason_Tagged', 'Reason_Value');
		sentiment_value_calc_for_senti($k,'Reason_Stemmed_Tagged', 'Reason_Stemmed_Value',);
		#sentiment_value_calc_for_senti($k,'Claim_Tagged', 'Claim_Value');
		sentiment_value_calc_for_senti($k,'Warrant0_Tagged', 'Warrant0_Value');
		sentiment_value_calc_for_senti($k,'Warrant0_Stemmed_Tagged', 'Warrant0_Stemmed_Value');
		sentiment_value_calc_for_senti($k,'Warrant1_Tagged', 'Warrant1_Value');
		sentiment_value_calc_for_senti($k,'Warrant1_Stemmed_Tagged', 'Warrant1_Stemmed_Value');

	}
}

#Tags Value of Words
sub data_value_tagging{
	my ($key1, $key2, $sentikey) = @_;

	if($DataHash{$key1}{$key2} =~ m/\b($sentikey)\b/)
	{
		my $v = $SentiWordHash{$sentikey};
		$DataHash{$key1}{$key2} =~ s/\b($sentikey)\b/$1\($v\)/g;
		#print "$1 : $w \n";
	}
}

#Calculates
sub sentiment_value_calc_for_senti{
	my ($key1, $key2, $value) = @_;

	if($DataHash{$key1}{$key2} =~ /\b(n't#r|not#r|cannot#n|cannot#v|not#n|no\/DET)\b/)
	{
		#print "------\n";
		#print "Before: \n";
		my @split_text = split(' ',$DataHash{$key1}{$key2});
		#print Dumper \@split_text;
		for (my $array_element = 0; $array_element < scalar @split_text; $array_element++)
		{
			if($split_text[$array_element] =~ /\b(n't#r|not#r|cannot#n|cannot#v|not#n|no\/DET)\b/)
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
		$DataHash{$key1}{$key2} = join(" ", @split_text);
	}

	my @matches = ($DataHash{$key1}{$key2} =~ /-?[0-9]+\.?[0-9]+/g);

	if((scalar @matches) > 0)
	{
		foreach my $num (@matches)
		{	
			$DataHash{$key1}{$value} += $num;
		}

		$DataHash{$key1}{$value} = $DataHash{$key1}{$value} / count_while($DataHash{$key1}{$key2});
	}
}


sub count_while {
    my $text = $_[0]; 
    my $count = 0;
    $count++ while $text =~ /\S+/g; 
    return $count;
}
########################################################

#Subroutines called#
COMAPRISION_SHOWDOWN(); #5
accuracy(); #6

print_hash(); #-- Can be used to print out DataHash


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

	foreach my $k(keys %DataHash)
	{
		#Algorithm Step #5.1
		#my $warrant_0 = abs(($DataHash{$k}{Reason_Value} + $DataHash{$k}{Claim_Value}) - $DataHash{$k}{Warrant0_Value});
		#my $warrant_1 = abs(($DataHash{$k}{Reason_Value} + $DataHash{$k}{Claim_Value}) - $DataHash{$k}{Warrant1_Value});

	#my $warrant_0 = abs($DataHash{$k}{Reason_Value} - $DataHash{$k}{Warrant0_Value});
	#my $warrant_1 = abs($DataHash{$k}{Reason_Value} - $DataHash{$k}{Warrant1_Value});
	my $warrant_0 = abs($DataHash{$k}{Reason_Stemmed_Value} - $DataHash{$k}{Warrant0_Stemmed_Value});
	my $warrant_1 = abs($DataHash{$k}{Reason_Stemmed_Value} - $DataHash{$k}{Warrant1_Stemmed_Value});


		if($warrant_0 < $warrant_1)
		{
			$DataHash{$k}{Answer} = '0';
		}	
		elsif ($warrant_1 < $warrant_0) #Algorithm Step #5.2.2
		{
			$DataHash{$k}{Answer} = '1';
		}
		else #Algorithm Step #5.2.3
		{
			$DataHash{$k}{Answer} = '-1';	
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
	foreach my $key (keys %DataHash)
	{
		if($DataHash{$key}{Answer} eq $DataHash{$key}{CorrectLabel} )
		{
			$correctTotalLabels++;
		}
		else
		{
			print "------------------------\n";
			#print "ID: $DataHash{$key}{ID} \n ";
			#print "Debate Title: $DataHash{$key}{Debate_Title}\n";
			#print "Debate Info: $DataHash{$key}{Debate_Info} ";
			#print "Claim : $DataHash{$key}{Claim_Tagged}\n ";
			#print "Claim : $DataHash{$key}{Claim_Value}\n ";
			print "Reason_stem: $DataHash{$key}{Reason_Stemmed_Tagged}\n";
			print "Reason_stem: $DataHash{$key}{Reason_Stemmed_Value}\n ";
			#print "Reason: $DataHash{$key}{Reason_Tagged}\n ";
			#print "Reason: $DataHash{$key}{Reason_Value}\n ";
			#print "Warrant 0: $DataHash{$key}{Warrant0_Tagged}\n ";
			print "Warrant0_stemmed: $DataHash{$key}{Warrant0_Stemmed_Tagged}\n";
			print "Warrant0_stem_value: $DataHash{$key}{Warrant0_Stemmed_Value}\n";					
			
			#print "Warrant0 Value: $DataHash{$key}{Warrant0_Value}\n";					
			print "Warrant1_stemmed: $DataHash{$key}{Warrant1_Stemmed_Tagged}\n";
			print "Warrant1 Value_stemmed: $DataHash{$key}{Warrant1_Stemmed_Value}\n";					
			
			#print "Warrant 1: $DataHash{$key}{Warrant1_Tagged}\n";

			#print "Warrant1 Value: $DataHash{$key}{Warrant1_Value}\n";
			print "CorrectLabel: $DataHash{$key}{CorrectLabel}\n";	
			print "Answer: $DataHash{$key}{Answer}\n";
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
	#print Dumper \%DataHash;
	#print Dumper \%SentiWordHash;
	#print Dumper \%Word_Duplicate_Hash;
	print "########################################\n";
	#print Dumper \%WordSentimentHash;
	print "########################################\n";
}

## Sanatizes Text
sub text_sanitation{
	my $my_text = $_[0];
	$my_text =~ s/[0-9]{1,}[A-Za-z]+//g;
	#$my_text =~ s/[[:punct:]]//g;
	$my_text =~ s/-/ /g;
	$my_text =~ s/\bbe\b//g;
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

#Uses rand to 'guess' the answers
sub random_sample{
	foreach my $key (keys %DataHash)
	{
		my $tempRandom = rand();
		if($tempRandom > .5)
		{
			$DataHash{$key}{Answer} = '1';
		}
		else
		{
			$DataHash{$key}{Answer} = '0';
		}		
	}
}