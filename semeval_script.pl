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

	$OverallHash{$num}{ID} = $temparray[0];

	$OverallHash{$num}{Claim} = text_sanitation($temparray[4]);
	$OverallHash{$num}{Reason} = text_sanitation($temparray[5]);
	$OverallHash{$num}{Warrant0} = text_sanitation($temparray[1]);
	$OverallHash{$num}{Warrant1} = text_sanitation($temparray[2]);
	$OverallHash{$num}{Warrant0_Sentiment} = 0;
	$OverallHash{$num}{Warrant1_Sentiment} = 0;
	$OverallHash{$num}{Reason_Value} = 0;
	$OverallHash{$num}{Claim_Value} = 0;


	$OverallHash{$num}{CorrectLabel} = $temparray[3];
	$OverallHash{$num}{Debate_Title} = $temparray[6];
	$OverallHash{$num}{Debate_Info} = $temparray[7];
	$OverallHash{$num}{Answer} = -1;
	$OverallHash{$num}{sentiment_value} = 0;

	$num++;	
}

#Reset Num
$num = 0;

## Open SCL-NMA Text file -- this has SO values for about 3200 items
open($fh, '<', $filename2) or die "Could not open";	
while(my $row = <$fh>)
{
	#my @temparray = split('\t',$row);
	#$WordSentimentHash{$num}{word} = $temparray[0];
	#$WordSentimentHash{$num}{score} = $temparray[1];

	#$WordSentimentHash{$num}{score} =~ s/\n//g;
	#$num++;
}

#Reset Num
open($fh, '<', $filename3) or die "Could not open";	
while(my $row = <$fh>)
{
	#type=strongsubj len=1 word1=abuse pos1=verb stemmed1=y priorpolarity=negative type=weaksubj
	my @temparray = split(' ',$row);
	
	$WordSentimentHash{$num}{word} = $temparray[2];
	$WordSentimentHash{$num}{score} = join ",", $temparray[0], $temparray[5];

	#MAKES THESE BETTER
	$WordSentimentHash{$num}{word} =~ s/word1=//g;
	$WordSentimentHash{$num}{score} =~ s/type=strongsubj,priorpolarity=negative/-1/g;
	$WordSentimentHash{$num}{score} =~ s/type=strongsubj,priorpolarity=positive/1/g;
	$WordSentimentHash{$num}{score} =~ s/type=strongsubj,priorpolarity=neutral/0/g;
	$WordSentimentHash{$num}{score} =~ s/type=weaksubj,priorpolarity=negative/-0.5/g;
	$WordSentimentHash{$num}{score} =~ s/type=weaksubj,priorpolarity=positive/0.5/g;
	$WordSentimentHash{$num}{score} =~ s/type=weaksubj,priorpolarity=neutral/0/g;
	$num++;
}

#positive
open($fh, '<', $filename4) or die "Could not open";	
while(my $row = <$fh>)
{

	$row =~ s/\n//g;
	$WordSentimentHash{$num}{word} = $row;
	$WordSentimentHash{$num}{score} = 0.5;

	$num++;
}

open($fh, '<', $filename5) or die "Could not open";	
while(my $row = <$fh>)
{

	$row =~ s/\n//g;
	$WordSentimentHash{$num}{word} = $row;
	$WordSentimentHash{$num}{score} = -0.5;

	$num++;
}


########################################################

#Subroutines called#
#Algorithm steps steps 3, 4, 5, 6
reason_claim_sentiment_value(); #3
#warrant_sentiment_set(); #4
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

#Calculating Sentiment Value
# Algorithm Step #3
# 1) For each of the sentiment values for the Reason_Claim_Combined
# 2) Adds values together to determine if negative or positive overall
sub reason_claim_sentiment_value{
	print "Beginning Sentiment Values\n";
	foreach my $k (keys %OverallHash)
	{
		foreach my $k2 (keys %WordSentimentHash) 
		{
			my $w = $WordSentimentHash{$k2}{word}; #assign word from sentiment to variable
			my $score = $WordSentimentHash{$k2}{score};
			#Tag Reason
			if($OverallHash{$k}{Reason} =~ m/\b$w\b/) #if the sentiment contains the word/phrase add the sentiment value
			{	
				$OverallHash{$k}{Reason} =~ s/\b$w\b/$w\_$score/g;
				
			}

			#Tag Claim
			if($OverallHash{$k}{Claim} =~ m/\b$w\b/) #if the sentiment contains the word/phrase add the sentiment value
			{
				$OverallHash{$k}{Claim} =~ s/\b$w\b/$w\_$score/g;
				
			}

			if($OverallHash{$k}{Warrant0} =~ m/\b$w\b/) #if the sentiment contains the word/phrase add the sentiment value
			{
				$OverallHash{$k}{Warrant0} =~ s/\b$w\b/$w\_$score/g;
				
			}

			if($OverallHash{$k}{Warrant1} =~ m/\b$w\b/) #if the sentiment contains the word/phrase add the sentiment value
			{
				$OverallHash{$k}{Warrant1} =~ s/\b$w\b/$w\_$score/g;
				
			}

			
		}

		$OverallHash{$k}{Reason} =~ s/\b([a-zA-Z]+'t|cannot|not|no)\b/$1\_AFTER_NEG/g;
		#$OverallHash{$k}{Reason} =~ s/\b(but|yet|however)\b/$1\_BEFORE_NEG/g;
		$OverallHash{$k}{Claim} =~ s/\b([a-zA-Z]+'t|cannot|not|no)\b/$1\_AFTER_NEG/g;
		#$OverallHash{$k}{Claim} =~ s/\b(but|yet|however)\b/$1\_BEFORE_NEG/g;
		$OverallHash{$k}{Warrant0} =~ s/\b([a-zA-Z]+'t|cannot|not|no)\b/$1\_AFTER_NEG/g;
		#$OverallHash{$k}{Warrant0} =~ s/\b(but|yet|however)\b/$1\_BEFORE_NEG/g;
		$OverallHash{$k}{Warrant1} =~ s/\b([a-zA-Z]+'t|cannot|not|no)\b/$1\_AFTER_NEG/g;
		#$OverallHash{$k}{Warrant1} =~ s/\b(but|yet|however)\b/$1\_BEFORE_NEG/g;

		############ Sentiment Value Tagging for Reason and Clain #######################
		sentiment_value_sub($k, 'Reason', 'Reason_Value');
		sentiment_value_sub($k, 'Claim', 'Claim_Value');
		sentiment_value_sub($k, 'Warrant0', 'Warrant0_Sentiment');				
		sentiment_value_sub($k, 'Warrant1', 'Warrant1_Sentiment');	
		print "---------------------\n";
		print "$OverallHash{$k}{ID} \n";
		print "$OverallHash{$k}{Warrant0_Sentiment} + $OverallHash{$k}{Warrant1_Sentiment}\n";
		$OverallHash{$k}{sentiment_value} = ($OverallHash{$k}{Reason_Value} + $OverallHash{$k}{Claim_Value});
		print "$OverallHash{$k}{sentiment_value}\n";
	}	
}

sub sentiment_value_sub{
	my ($key1, $key2, $value) = @_;

	if($OverallHash{$key1}{$key2} =~ /_AFTER_NEG/)
	{
			#print "------\n";
			#print "Before: \n";
			my @split_text = split(' ',$OverallHash{$key1}{$key2});
			#print Dumper \@split_text;
			for (my $array_element = 0; $array_element < scalar @split_text; $array_element++)
			{
				if($split_text[$array_element] =~ /_AFTER_NEG/)
				{
					#print "Contains NOT or CANNOT\n";
					for (my $sub_loop = $array_element + 1; $sub_loop < scalar @split_text; $sub_loop++)
					{
			#			print $split_text[$sub_loop];
			#			print " ";
						if($split_text[$sub_loop] =~ /_-/)
						{
							$split_text[$sub_loop] =~ s/_-/_/g;
						}
						elsif($split_text[$sub_loop] =~ /_/)
						{
							$split_text[$sub_loop] =~ s/_/_-/g;
						}
					}
				}
			}
			#print "\nAfter:\n ";
			#print Dumper \@split_text;
			$OverallHash{$key1}{$key2} = join(" ", @split_text);
	}
		
		
		#print "\nMatches:\n";
	my @matches = ($OverallHash{$key1}{$key2} =~ /-?[0-9]*\.?[0-9]*/g);
		#print scalar @matches;

	@matches = grep { $_ ne '' } @matches;
	@matches = grep { $_ ne '-' } @matches;
	@matches = grep { $_ ne '.' } @matches;
	#print Dumper \@matches;

	#print "\n Math \n";
	if((scalar @matches) > 0)
	{
		foreach my $num (@matches)
		{
			#print "VALUE: $value \n";
			#print " $num,";
			$OverallHash{$key1}{$value} += $num;
		}
			#print "\n Value: ";
			#print $OverallHash{$key1}{$value};
	}
}


#COMAPRISION SHOW DOWN (CAPS BECAUSE THIS IS IMPORTANT)
# Algorithm Step #5
# 1) Calculate which warrant is closer to the claim_reason_sentiment
# 2) Assigns the answer to Hash for comparision
sub COMAPRISION_SHOWDOWN{
	my $equal = 0;	

	foreach my $yellow(keys %OverallHash)
	{
		#Algorithm Step #5.1
		my $warrant_0 = abs($OverallHash{$yellow}{sentiment_value} - $OverallHash{$yellow}{Warrant0_Sentiment});
		my $warrant_1 = abs($OverallHash{$yellow}{sentiment_value} - $OverallHash{$yellow}{Warrant1_Sentiment});

		#print "$Z1 : $Z2\n";

		#Algorithm Step #5.2.1
		if($OverallHash{$yellow}{sentiment_value} == 0)
		{
			#$equal++;
		}

		if($warrant_0 < $warrant_1)
		{
			$OverallHash{$yellow}{Answer} = '0';
		}	
		elsif ($warrant_1 < $warrant_0) #Algorithm Step #5.2.2
		{
			$OverallHash{$yellow}{Answer} = '1';
		}
		else #Algorithm Step #5.2.3
		{
			$OverallHash{$yellow}{Answer} = '-1';	
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
			print "ID: $OverallHash{$key}{ID} \n ";
			print "Debate Title: $OverallHash{$key}{Debate_Title}\n";
			print "Debate Info: $OverallHash{$key}{Debate_Info} ";
			print "Claim : $OverallHash{$key}{Claim}\n ";
			print "Claim : $OverallHash{$key}{Claim_Value}\n ";
			print "Reason: $OverallHash{$key}{Reason}\n ";
			print "Reason: $OverallHash{$key}{Reason_Value}\n ";
			print "Claim + Reason Sentiment: $OverallHash{$key}{sentiment_value}\n";
			print "Warrant 0: $OverallHash{$key}{Warrant0}\n ";
			print "Warrant0 Value: $OverallHash{$key}{Warrant0_Sentiment}\n";					
			print "Warrant 1: $OverallHash{$key}{Warrant1}\n";
			print "Warrant1 Value: $OverallHash{$key}{Warrant1_Sentiment}\n";
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

#Calculates PMI 
#Must create unigram first
#Pass in Word1 and Word2
sub pointwise_mutual_information{
	#info from unigram
	my $word1= shift;
	my $word2 = shift;
	#info from bigram
	my $co_occur = shift;
	
	$word1 = $word1 / $unigram_frequency;
	$word2 = $word2 / $unigram_frequency;

	$co_occur = $co_occur / $bigram_frequency;

	print "Word1 Prob: $word1 \n";
	print "Word2 Prob: $word2 \n";
	print "Co_Occur Prob: $co_occur \n";

	my $PMI = log($co_occur / ($word1 * $word2))/log(2);

	print "PMI: $PMI";
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


