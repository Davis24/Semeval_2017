use warnings;
use strict;
use Data::Dumper qw(Dumper);
use Lingua::Stem qw(stem);



print  Lingua::Stem::get_locale;


my @words = ('trusted', 'another','businesses');
my $anon_array_of_stemmed_words = Lingua::Stem::stem(@words);

print Dumper \$anon_array_of_stemmed_words;