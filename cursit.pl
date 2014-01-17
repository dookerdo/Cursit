#!/usr/bin/perl -w

use strict;
use Curses::UI;
use PAWR;

package main;
### CURSES OBJECT ###
our $cui = new Curses::UI(-color_support => 1);

### REDDIT VARS ###
our $active_sub = "all";
our $listnum = 50;
our @current_list;
my $reddit = PAWR->new();
my $user = '';
my $password = '';


### WINDOW1 ###
our $win1 = $cui->add(
	'win1', 'Window',
	-title => 'REDDIT VIEWA!',
	-border => 1,
	#-y => 1,
	-bfg => 'red',
);

our $win2 = $cui->add(
	'win2', 'Window',
	-title => 'Reader',
	-border => 1,
	-bfg => 'yellow',
);
### CONT ###
our $cont = $win1->add('mycontainer', 'Container',);


### MENU ####
my @menu = (
	{-label => 'File', -submenu =>[{ -label => 'Exit  ^Q', -value => \&exit_dialog}]},
	{-label => 'Options', 
	-submenu =>[
		{-label => 'Set User', -value=> \&set_user_dialog},
		{-label => 'Refresh', -value=> \&get_listing},
		{-label => 'Set Subreddit', -value=> \&set_sub},
		{-label => 'Set # to return', -value=> \&set_listreturn},
		{-label => 'Go win2', -value=> \&goto_story},


	]
	},
);

##############

my $menu = $cui->add(
	'menu','Menubar',
	-menu => \@menu,
	-fg => "blue",
);

### REDDIT STUFF ###

### SUBROUTINES ###############
###VVVVVVVVVVVVVVVVVVVVVVV#####
sub textmepls(){
	my @holder = @{(shift)};
	my $retu;
	$retu = "*"x50 . "\n";

	#HEADER
	if($holder[0]->{'selftext'}){$retu .= $holder[0]->{'selftext'}. "\n"}
	else{$retu.= $holder[0]->{'url'} . "\n";}
	$retu .= "*"x20 . " COMMENTS " . "*"x20 . "\n";
	@holder = @{$holder[1]};

	#REPLIES
	my $counterx;
	my %stuff;
	for(my $x=0; $x < $#holder;$x++){
		$counterx = 1;
		%stuff = %{$holder[$x]->{'data'}};
		$retu .= get_tree(\%stuff,$counterx);
		#SEPARATES COMMENT TREES
		$retu .= "="x60 . "\n";
	}	

	return $retu;	
}

sub get_tree(){
	my %stuff = %{(shift)};
	my $counterx = shift;
	my $text = '';
	if($stuff{'author'}){
		$stuff{'body'} =~ s/&gt/\\n|/g;
		$text .= "\n[$counterx] - " . $stuff{'author'} . "\n" . $stuff{'body'} . "\n\n";
		if($stuff{'replies'}){
			foreach(@{$stuff{'replies'}->{'data'}->{'children'}}){
				$text .= &get_tree($_->{'data'},$counterx+1);
				#$text .= &get_tree($stuff{'replies'}->{'data'}->{'children'}[0]->{'data'});
		
			}
		}
	}
	return $text;
}

sub subcoms(){
	my %stuff = %{(shift)};
	my $retu = shift;
	my $rep = ${$stuff{'replies'}->{'data'}->{'children'}}[0]->{'data'};
	if($rep){$$retu .= "\n2)     [" . $rep->{'author'} . "]\n"  . $rep->{'body'} . "\n"}

}
sub goto_story{
	$win2->delete('mytextviewer1');
	my $comment = $reddit->get_comments({'id'=>$current_list[shift]->{'id'},'depth'=>5,'limit'=>90});
	my $text = ""; 
	if(${$comment}[0]->{'selftext'}){$text = ${$comment}[0]->{'selftext'}}
	else{$text = "NO SELFTEXT: ${$comment}[0]->{'url'}"}
	#$text .= "\n" . "***"x20 . "\n";
	$text = &textmepls($comment);
	#foreach(@{${$comment}[1]}){if($_->{'data'}->{'body'}){$text .= $_->{'data'}->{'body'};$text .= "\n" . "--"x40 . "\n";}}
	my $textviewer = $win2->add(
		'mytextviewer1', 'TextViewer',
		-text => $text,
		-wrapping => 1,
	);	
	$cui->set_binding(sub {$win1->focus()}, "\cB");
	$textviewer->focus;
}
# Gets listing of specific subreddit.
sub get_sub{
	my @listing = $reddit->get_subreddit({'sort' => 'hot','limit' => $main::listnum,'subreddit'=> $main::active_sub,});
	return @listing;
}

########################


### MENU ITEMS & FUNCTIONS ###
sub exit_dialog(){
	my $return = $cui->dialog( 
		-message => "Do you really want to quit?",
		-title =>  "Are you sure???",
		-buttons => ['yes','no'],
	);

	exit(0) if $return;
}

sub set_user_dialog(){
	my $return = $cui->question(
		-question => "Enter username:",
		-title => "Fa! Who goes there?",
	);
	my $pass;	
	if($return){
		$main::user = $return;
		$pass = $cui->question(
			-question => "Enter password:",
			-title => "What's your password?",
		);
	if($pass){$main::password = $pass}
	}
	
}

### Updates window with listing

#NEED TO FINISH!
sub get_listing(){
	$cont->delete('tester');
	@current_list = &get_sub;
	my %wow;
	for(1..($listnum)){ 
		$wow{$_} = "<bold>$_)</bold> [". $current_list[$_-1]->{'score'};
		$wow{$_} .= "] ";
		if($active_sub eq "all"){$wow{$_} .= "|<dim>" . $current_list[$_-1]->{'subreddit'} . "</dim>| ";}
		$wow{$_} .= "{" . $current_list[$_-1]->{'score'}."} " . substr($current_list[$_-1]->{'title'},0,60)
	}; #creating %wow hash for -labels

	my $list = $cont->add(
		'tester', 'Listbox',
		-title => $active_sub,
		-border => 1,
		-bfg => 'green',
		-values => [1..$listnum],
		-labels => \%wow,
		-vscrollbar => 1,
		#-onchange => \&goto_story($list=get_active_id()),#$x->("XXXXX:"),#\&goto_story,#($listing[$listnum-1]->{'selftext'}),
	);
	$list->onChange(sub{&goto_story($list->id());$list->clear_selection();});
	$cont->draw;
	$cont->focus;
}

sub set_sub(){
	my $return = $cui->question(
		-question => "Choose Subreddit:",
		-title => 'Choose ze sub!',
	);
	if($return){$main::active_sub = $return;}
	&get_listing;
}

sub set_listreturn(){
	my $return = $cui->question(
		-question => "How many, guvna??",
		-title => "Select how many posts to return (currently $main::listnum)",
	);
	if($return){$main::listnum = $return;}
	&get_listing;
}

sub refresh(){&get_listing;}


####################


$win1->draw;
$cont->focus;

$cui->set_binding(sub {$menu->focus()}, "\cX");
$cui->set_binding( \&exit_dialog , "\cQ");
$cui->set_binding(sub {$menu->focus()}, "\cF");




### MAINLOOP ###
$cui->mainloop();
