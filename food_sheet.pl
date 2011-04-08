#!/usr/bin/perl -w
#
# A simple positive feedback script to let me know when
#   I'm succeeding at managing my calorie intake, based
#   on a entries in a google spreadsheet. 

use strict;
use Net::Google::Spreadsheets;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Date::Manip;

my $un = 'dp@danielpacker.org';
my $pw = '#######';
my $key= '##################';
my $ws = 'RUNLOG';


# Connect
my $service = Net::Google::Spreadsheets->new(
  username => $un, password => $pw,
);

# find a spreadsheet by key
my $spreadsheet = $service->spreadsheet({ key => $key });

# find a worksheet by title
my $worksheet = $spreadsheet->worksheet({ title => $ws });

my @rows = $worksheet->rows({'sq' => 'food > 0' });

my $yesterday = yesterday();
  
# Read the data in the row
for my $row (@rows) { 
  my $content = $row->content;
  my $food = $content->{'food'} || 0;
  my $cals = $content->{'cals'} || '';
  my $date = $content->{'date'} || '';
  my $feedback_orig = $content->{'feedback'} || '';
  my @nums = split /[^\d]+/, $food;
  my $sum; $sum += $_ for grep { /^\d+\.?\d+?$/ } @nums;
  my $feedback = ($feedback_orig =~ /^\*/) ? $feedback_orig : feedback($sum);

 # Provide feedback
  if (($date eq $yesterday) && ($feedback eq 'PERFECT! :-D') && ($feedback_orig =~ /^[^\*]/))
  {
    $feedback = "*$feedback*";
    send_congrats();
  }

  if ($cals ne $sum || $feedback_orig ne $feedback)
  {
      $row->content({%$content, 'cals' => $sum, 'feedback' => $feedback})
  }
}
 
# Determine what kind of feedback to provide based on calorie range
sub feedback {
    my $cals = shift || 0;
    die "no cals" unless ($cals =~ /^\d+\.?\d+?$/);
    my $feedback = '';
    if     ($cals > 0    && $cals <= 1000 ) { $feedback = 'FAR TOO LOW' }
    elsif  ($cals > 1000 && $cals <= 1500 ) { $feedback = 'TOO LOW!' } 
    elsif  ($cals > 1500 && $cals <= 1750 ) { $feedback = 'LOW BUT GOOD' } 
    elsif  ($cals > 1750 && $cals <= 2000 ) { $feedback = 'PERFECT! :-D' } 
    elsif  ($cals > 2000 && $cals <= 2250 ) { $feedback = 'HIGH BUT GOOD' } 
    elsif  ($cals > 2250 && $cals <= 2750 ) { $feedback = 'TOO HIGH!' } 
    elsif  ($cals > 2750 && $cals <= 3500 ) { $feedback = 'FAR TOO HIGH!' } 
    elsif  ($cals > 3500 )                  { $feedback = 'EMERGENCY! CALL SOMEONE!' } 
    else                                    { $feedback = 'ERROR' }
    return $feedback;
} 

# utility method
use constant SCORES => {};
sub feedback_rating {
    my $score = shift || 0;
    die "invalid score" unless (($score =~ /-?[0-9]+/) && $score < 10);
    return SCORES->{$score};
}

# utility method
sub send_congrats {
    send_feedback((
        header => [
            To => '9178160124@txt.att.net',
            From => 'dp@danielpacker.org',
            Subject => 'CONGRATS ON YOUR PERFECT CALORIES TODAY!',
           ],
        body => "EXCELLENT JOB. KEEP UP THE GREAT WORK!\n",
    ));
}

# utility method
sub send_feedback {
    my %args = (@_);

  my $email = Email::Simple->create(
    %args
  );

  sendmail($email);
}

# utility method
sub get_date {
    my $date = `date +%m/%d/%Y`;
    chomp $date;
    return $date;
}

# utility method
sub yesterday {
    my $dateobj = ParseDate("today") or die "bad date";
    $dateobj = Date_ConvTZ($dateobj,"UTC","PDT");
    #my $today_str = UnixDate($dateobj, "%m/%d/%Y");
    #warn $today_str;
    my $yest = DateCalc($dateobj, "- 1day");
    my $yest_str = UnixDate($yest, "%m/%d/%Y");
    #warn $yest_str;
    $yest_str =~ s/^0//;
    return $yest_str;
}
    

