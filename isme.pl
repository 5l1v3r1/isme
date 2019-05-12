# perl
# --------------------------------------------------------
# LICENCE
# This software is under GNU GENERAL PUBLIC LICENSE
# The detail could be found in the file LICENCE include
# in the same directory than isme.pl
# --------------------------------------------------------


use Tk; # http://search.cpan.org/~srezic/Tk/pod/UserGuide.pod
use Tk::Radiobutton;
use Tk::PNG;
use Tk::Photo;
use Tk::JPEG;
use Tk::NoteBook;
use Tk::ProgressBar;
use Tk::LabFrame;
use threads;
use threads::shared;


my $ListType = "";
my $EditorSelect = "";
my @IndexLaunch = "";
my $SelectLaunch = "";

my $CommandToLaunch = "";

my @TypeList = ("Scanner","Tools","Exploits","Editors");
my @ToolList = ("Cisco SCCP Phone: Ringer","Cisco SCCP Phone: Forwarder","Cisco phone: Extension mobility feauure abuse","Server: DHCP Starvation","Server: DNS subnet resolver","Server: TCP SYN Flood","SIP Flooder","SIP Fuzzing");

my @ScannerList = (
			"Generic",
			"SIP Scanner",	
			"VxWorks active debug mode detection",			
			);

my @ToolList = (
			"Aastra Web Bruteforcer",
			"Cisco Phone Forwarder",
			"Cisco Mobility Feature Abuse",
			"Cisco Phone Ringer",
			"Cisco Phone SSH Detector",
			"Cisco Phone: Having fun with SSH",
			"DHCP Starvation",
			"DNS Resolver",
			"Mitel Web Bruteforcer",
			"SNOM Web Bruteforcer",
			"Polycom Soundpoint Web Bruteforcer",
			"SIP Flooding",
			"SIP Fuzzer - Protos",
			"TCP SYN FLood",
			);


my @ExploitList = (
			"Aastra Web Disclosure",
			"Aastra Phone telnet hardcode password",
			"Alcatel OXO FTP DoS",
			"Avaya TFTP Disclosure",
			"Mitel Web Disclosure",
			"Mitel XSS",
			"Mitel Unauthenticated Command Execution",
			"Polycom HDX Telnet Authorization Bypass",
			"Polycom HTTP DoS",
			"Polycom Web Disclosure",
			"SNOM Call Remote Tapping",
			);

my @EditorsList = (
			"Aastra",
			"Alcatel",
			"Avaya",
			"Cisco",
			"Mitel",
			"Polycom",
			"Snom",
			);

my @SnomList = (
			"SNOM Call Remote Tapping",
			"SNOM Web Bruteforcer",
			);

my @PolycomList = (
			"Polycom HDX Telnet Authorization Bypass",
			"Polycom HTTP DoS",
			"Polycom Web Disclosure",
			"Polycom Soundpoint Web Bruteforcer",
			);

my @MitelList = (
			"Mitel Web Bruteforcer",
			"Mitel Web Disclosure",
			"Mitel XSS",
			"Mitel Unauthenticated Command Execution",
			);

my @CiscoList = (
			"Cisco Phone Forwarder",
			"Cisco Mobility Feature Abuse",
			"Cisco Phone Ringer",
			"Cisco Phone SSH Detector",
			"Cisco Phone: Having fun with SSH",
			"VxWorks active debug mode detection",
			);

my @AvayaList = (
			"Avaya TFTP Disclosure",
			"VxWorks active debug mode detection",
			);

my @AlcatelList = (
			"Alcatel OXO FTP DoS",
			"VxWorks active debug mode detection",
			);

my @AastraList = (
			"Aastra Phone telnet hardcode password",
			"Aastra Web Bruteforcer",
			"Aastra Web Disclosure",
			);

my $subweb_mw = MainWindow->new(
						-title => 'ISME (IP Phone Scanning Made Easy)');

#------------- MENU -------------------
my $menu_bar = $subweb_mw->Frame(
				-relief => 'groove',
				-borderwidth => 3,
#				-width => 40,
				)-> pack(
					-side=>'top',
					-fill => 'x'
					);
my $file_mb = $menu_bar->Menubutton(
				-text => 'File',
				)->pack(-side=>'left');
				
$file_mb->command(
	-label=>'Exit',
	-command => [$subweb_mw => 'destroy']
	);

my $about_mb = $menu_bar->Menubutton(
				-text => 'About',
				)->pack(-side=>'left');
				
$about_mb->command(
	-label=>'Version',
	-command => sub{&ABOUT},
	);


#------------- Button menu --------------
my $FrameButton = $subweb_mw -> Frame ();


my $ImageSelect = $FrameButton->Photo( 
									-format => 'jpeg',
									-file => "Image/IMG_select.jpg",
									 );	
my $ImageDetail = $FrameButton->Photo( 
									-format => 'jpeg',
									-file => "Image/IMG_oeil.jpg",
									 );									 
my $ImageLaunch = $FrameButton->Photo( 
									-format => 'jpeg',
									-file => "Image/IMG_launch.jpg",
									 );									 
my $ImageExit = $FrameButton->Photo( 
									-format => 'jpeg',
									-file => "Image/IMG_exit.jpg",
									 );										 
my $ButtonSelect = $FrameButton->Button (
					    				-image => $ImageSelect, 
									    -command => sub {&BUTTONSELECT},
										)->pack(-side => 'left');
my $ButtonDetail = $FrameButton->Button (
    								-image => $ImageDetail, 
								    -command => sub {&DETAILS}
									)->pack(-side => 'left');
my $ButtonLaunch = $FrameButton->Button (
    								-image => $ImageLaunch, 
								    -command => sub {&LAUNCH}
									)->pack(-side => 'left');
my $ButtonExit = $FrameButton->Button (
    								-image => $ImageExit, 
								    -command => [$subweb_mw => 'destroy']
									)->pack(-side => 'right');										
									
$FrameButton -> pack (-side => 'top', -anchor => 'w'); 

#-------------Select type of tool --------------
my $FrameListBox = $subweb_mw -> Frame ();
my $Frame11 = $FrameListBox -> Frame ();

my $Lbox11 = $Frame11 -> Listbox (
	-height  => 10,
	-width   => 10,
	-background => "#E8E8E8",
	-selectmode => 'single',
	);	
$Frame11 -> pack (-side => 'top', -anchor => 'w');
$Lbox11->insert('end', @TypeList );
$Lbox11->selectionSet(0);
$Lbox11->pack(-side => 'left', -fill => 'both', -expand => 1);

#-----------------------------------------------------------------------

my $Lbox12 = $Frame11 -> Listbox (
	-height  => 10,
	-width   => 10,
	-background => "#E8E8E8",	
	-selectmode => 'single',
	);	


my $scroll12 = $Frame11->Scrollbar(-command => ['yview', $Lbox12],	-background => "#E8E8E8",);
$Lbox12->configure(-yscrollcommand => ['set', $scroll12]);
$Lbox12->pack(-side => 'left');
$scroll12->pack(-side => 'right',-fill => 'both', -expand => 1);
$Frame11 -> pack (-side => 'left', -anchor => 'w');

#-----------------------------------------------------------------------
my $Frame13 = $FrameListBox -> Frame ();
my $Lbox13 = $Frame13 -> Listbox (
	-height  => 10,
	-width   => 37,
	-background => "#E8E8E8",
	-selectmode => 'single',
	);	


my $scroll13 = $Frame13->Scrollbar(-command => ['yview', $Lbox13],	-background => "#E8E8E8",);
$Lbox13->configure(-yscrollcommand => ['set', $scroll13]);
$Lbox13->pack(-side => 'left');
$scroll13->pack(-side => 'right',-fill => 'both', -expand => 1);
$Frame13 -> pack (-side => 'left', -anchor => 'w');	

$FrameListBox -> pack (-side => 'top', -anchor => 'w');	
#-------------------------------------------------------------------------

my $FrameText = $subweb_mw -> Frame ();

$TextWidget = $FrameText->Text(); 
$TextWidget->configure(-width => 62,-height => 5,-background => "#E8E8E8",);
my $scrollbarText = $FrameText ->Scrollbar(-command => ['yview', $TextWidget],	-background => "#E8E8E8",);

$TextWidget->configure(-yscrollcommand => ['set', $scrollbarText]);
$TextWidget->pack(-side => 'left', );#-fill => 'both', -expand => 1
$scrollbarText->pack(-side => 'right', -fill => 'y');

$FrameText  -> pack (-side => 'top');



#------------ LAUNCHING THE MAIN LOOP --------
MainLoop;
#------------ END OF THE GUI INTERFACE DEFINITION STUFF -------------------------------------


sub BUTTONSELECT
{
	my @index = $Lbox11->curselection();
	$Select=@TypeList[@index];

	if ($Select =~ /Scanner/)
	{
		$Lbox13->delete(0,end);
		$Lbox12->delete(0,end);
		$TextWidget -> delete('0.0', 'end');		
		$Lbox13->insert('end', @ScannerList );
		$Lbox13->selectionSet(1);
		$Lbox13->update;
		$ListType = "Scanner";	
	}
	elsif ($Select =~ /Tools/)
	{
		$Lbox13->delete(0,end);
		$Lbox12->delete(0,end);
		$TextWidget -> delete('0.0', 'end');
		$Lbox13->insert('end', @ToolList );
		$Lbox13->selectionSet(1);
		$Lbox13->update;	
		$ListType = "Tools";	
	}	
	elsif ($Select =~ /Exploits/)
	{
		$Lbox13->delete(0,end);
		$Lbox12->delete(0,end);
		$TextWidget -> delete('0.0', 'end');
		$Lbox13->insert('end', @ExploitList );
		$Lbox13->selectionSet(1);
		$Lbox13->update;
		$ListType = "Exploits";		
	}			
	if ($ListType =~ /Editors/)
	{
		my @index = $Lbox12->curselection();
		$Select=@EditorsList[@index];
		
		if ($Select =~ /Aastra/)
		{
			$Lbox13->delete(0,end);
			$TextWidget -> delete('0.0', 'end');
			$Lbox13->insert('end', @AastraList );
			$Lbox13->selectionSet(1);
			$Lbox13->update;
			$EditorSelect = "Aastra";	
		}
		elsif ($Select =~ /Alcatel/)
		{
			$Lbox13->delete(0,end);
			$TextWidget -> delete('0.0', 'end');
			$Lbox13->insert('end', @AlcatelList );
			$Lbox13->selectionSet(1);
			$Lbox13->update;	
			$EditorSelect = "Alcatel";
		}
		elsif ($Select =~ /Avaya/)
		{
			$Lbox13->delete(0,end);
			$TextWidget -> delete('0.0', 'end');
			$Lbox13->insert('end', @AvayaList );
			$Lbox13->selectionSet(1);
			$Lbox13->update;	
			$EditorSelect = "Avaya";
		}
		elsif ($Select =~ /Cisco/)
		{
			$Lbox13->delete(0,end);
			$TextWidget -> delete('0.0', 'end');
			$Lbox13->insert('end', @CiscoList );
			$Lbox13->selectionSet(1);
			$Lbox13->update;	
			$EditorSelect = "Cisco";
		}
		elsif ($Select =~ /Mitel/)
		{
			$Lbox13->delete(0,end);
			$TextWidget -> delete('0.0', 'end');
			$Lbox13->insert('end', @MitelList );
			$Lbox13->selectionSet(1);
			$Lbox13->update;	
			$EditorSelect = "Mitel";
		}
		elsif ($Select =~ /Polycom/)
		{
			$Lbox13->delete(0,end);
			$TextWidget -> delete('0.0', 'end');
			$Lbox13->insert('end', @PolycomList );
			$Lbox13->selectionSet(1);
			$Lbox13->update;	
			$EditorSelect = "Polycom";
		}
		elsif ($Select =~ /Snom/)
		{
			$Lbox13->delete(0,end);
			$TextWidget -> delete('0.0', 'end');
			$Lbox13->insert('end', @SnomList );
			$Lbox13->selectionSet(1);
			$Lbox13->update;	
			$EditorSelect = "Snom";
		}		
	}
	elsif ($Select =~ /Editors/)
	{
		$Lbox12->delete(0,end);
		$Lbox13->delete(0,end);
		$TextWidget -> delete('0.0', 'end');
		$Lbox12->insert('end', @EditorsList );
		$Lbox12->selectionSet(1);
		$Lbox12->update;
		$ListType = "Editors";		
	}			
		
}

sub IDENTIFYLBOX13SELECTION
{
	@IndexLaunch = $Lbox13->curselection();
	$SelectLaunch = "";
	
	if ($ListType =~ /Scanner/)
	{
		$SelectLaunch = @ScannerList[@IndexLaunch];
	}	
	elsif ($ListType =~ /Tools/)
	{
		$SelectLaunch = @ToolList[@IndexLaunch];				
	}
	elsif ($ListType =~ /Exploits/)
	{
		$SelectLaunch = @ExploitList[@IndexLaunch];		
	}	
	elsif ($ListType =~ /Editors/)
	{
		if ($EditorSelect =~ /Aastra/)
		{
			$SelectLaunch = @AastraList[@IndexLaunch];			
		}
		elsif ($EditorSelect =~ /Alcatel/)
		{
			$SelectLaunch = @AlcatelList[@IndexLaunch];			
		}
		if ($EditorSelect =~ /Avaya/)
		{
			$SelectLaunch = @AvayaList[@IndexLaunch];			
		}
		if ($EditorSelect =~ /Cisco/)
		{
			$SelectLaunch = @CiscoList[@IndexLaunch];			
		}
		if ($EditorSelect =~ /Mitel/)
		{
			$SelectLaunch = @MitelList[@IndexLaunch];			
		}
		if ($EditorSelect =~ /Polycom/)
		{
			$SelectLaunch = @PolycomList[@IndexLaunch];			
		}
		if ($EditorSelect =~ /Snom/)
		{
			$SelectLaunch = @SnomList[@IndexLaunch];			
		}
	}

}
sub LAUNCH
{
	&IDENTIFYLBOX13SELECTION;
	
	#-------- SCANNER LAUNCHER -----------------------------------------------
	if ($SelectLaunch =~ /Generic/)
	{
		$CommandToLaunch = "perl generic_scanner.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself. 		
	}
	elsif ($SelectLaunch =~ /VxWorks active debug mode detection/)
	{
		$CommandToLaunch = "perl Scanner/vxworks_active_debug_mode_detection.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself. 		
	}	
	elsif ($SelectLaunch =~ /SIP Scanner/)
	{
		$CommandToLaunch = "perl Scanner/sip_scanner.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself. 		
	}
	#-------- TOOLS LAUNCHER -------------------------------------------------	
	elsif ($SelectLaunch =~ /Aastra Web Bruteforcer/)
	{
		$CommandToLaunch = "perl tools/isme_aastrabruteforce.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself. 
	}
	elsif ($SelectLaunch =~ /Cisco Phone Forwarder/)
	{
		$CommandToLaunch = "perl tools/ciscophone_forwarder.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Cisco Mobility Feature Abuse/)
	{
		$CommandToLaunch = "perl tools/ciscophone_mobilityfeatureabuse.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Cisco Phone Ringer/)
	{
		$CommandToLaunch = "perl tools/ciscophone_ringer.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Cisco Phone: Having fun with SSH/)
	{
		$CommandToLaunch = "perl tools/ciscophone_ssh_fun.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Cisco Phone SSH Detector/)
	{
		$CommandToLaunch = "perl tools/ciscophone_ssh_default.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /DHCP Starvation/)
	{
		$CommandToLaunch = "perl tools/dhcpstarvation.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /DNS Resolver/)
	{
		$CommandToLaunch = "perl tools/dnsresolver.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Mitel Web Bruteforcer/)
	{
		$CommandToLaunch = "perl tools/isme_mitelbruteforce.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /SNOM Web Bruteforcer/)
	{
		$CommandToLaunch = "perl tools/isme_snombruteforce.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Polycom Soundpoint Web Bruteforcer/)
	{
		$CommandToLaunch = "perl tools/isme_soundpointbruteforce.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /SIP Flooding/)
	{
		$CommandToLaunch = "perl tools/SIP_Flooding.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /SIP Fuzzer - Protos/)
	{
		$CommandToLaunch = "perl tools/SipFuzzerProtos.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /TCP SYN FLood/)
	{
		$CommandToLaunch = "perl tools/tcpsynflood.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}

	
	#-------- EXPLOIT LAUNCHER ----------------------------------------------	
	elsif ($SelectLaunch =~ /Aastra Web Disclosure/)
	{
		$CommandToLaunch = "perl Exploits/aastra_web_disclosure.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Aastra Phone telnet hardcode password/)
	{
		$CommandToLaunch = "perl Exploits/aastra_phone_hardcode_telnet_password.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Alcatel OXO FTP DoS/)
	{
		$CommandToLaunch = "perl Exploits/Alcatel-OXO-FTP_DOS.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Avaya TFTP Disclosure/)
	{
		$CommandToLaunch = "perl Exploits/avaya_tftp_disclosure.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Mitel Web Disclosure/)
	{
		$CommandToLaunch = "perl Exploits/mitel_web_disclosure.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Mitel XSS/)
	{
		$CommandToLaunch = "perl Exploits/mitel_xss.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}	
	elsif ($SelectLaunch =~ /Mitel Unauthenticated Command Execution/)
	{
		$CommandToLaunch = "perl Exploits/Mitel15807-UnauthenticatedCommandExecution.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}	
	elsif ($SelectLaunch =~ /Polycom HDX Telnet Authorization Bypass/)
	{
		$CommandToLaunch = "perl Exploits/polycom_HDX_Telnet_Authorization_Bypass.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}
	elsif ($SelectLaunch =~ /Polycom HTTP DoS/)
	{
		$CommandToLaunch = "perl Exploits/polycomHTTPDoS.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}	
	elsif ($SelectLaunch =~ /Polycom Web Disclosure/)
	{
		$CommandToLaunch = "perl Exploits/polycomReg1.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}	
	elsif ($SelectLaunch =~ /SNOM Call Remote Tapping/)
	{
		$CommandToLaunch = "perl Exploits/snomCall.pl";
		$thr = threads->new(\&LAUNCHMODULE); # Create the tehreads
    	$thr->detach; # Execute the whole SETPACKET subfunction and kill himself.
	}	
}

sub DETAILS
{
	&IDENTIFYLBOX13SELECTION;

	#-------- SCANNER ----------------------------------------------	
	if ($SelectLaunch =~ /VxWorks active debug mode detection/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Some products based on VxWorks have the WDB target agent debug service enabled by default. This service provides read/write access to the device's memory and allows functions to be called.\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /SIP Scanner/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This module will try to detect if a SIP service is available on the specify IP address. This test will be done for UDP port 5060. Once a SIP service has been detected, the script will try to detect if the following services usually provided for administration are available or not: telnet, ssh, http, https and answer to ping. Administration services should be properly identified, encrypted and unreachable from public area.\n");
		$TextWidget  -> update ();			
	}

	#-------- TOOLS SECTION ----------------------------------------------	

	elsif ($SelectLaunch =~ /Aastra Web Bruteforcer/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /Cisco Phone Forwarder/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity to spoof a Cisco IP Phone identity in order to set a forward all on the original IP Phone.\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /Cisco Mobility Feature Abuse/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity to spoof a Cisco IP Phone identity in order to log him off extension mobility service.\n");
		$TextWidget  -> update ();				
	}
	elsif ($SelectLaunch =~ /Cisco Phone Ringer/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity make several Cisco IP Phone ring at the same time or in round robin mode.\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /Cisco Phone: Having fun with SSH/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity to create either information disclosure or deny of service through the connection of the IP Phone SSH service.\n");
		$TextWidget  -> update ();				
	}
	elsif ($SelectLaunch =~ /Cisco Phone SSH Detector/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity to detect if a SSH service with default credential is activated on a Cisco IP Phone.\n");
		$TextWidget  -> update ();				
	}
	elsif ($SelectLaunch =~ /DHCP Starvation/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Launch a DHCP starvation attack. Bypass portsecurity.\n");
		$TextWidget  -> update ();				
	}
	elsif ($SelectLaunch =~ /DNS Resolver/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Get servers name through their IP address once you've got the server subnet.\n");
		$TextWidget  -> update ();				
	}
	elsif ($SelectLaunch =~ /Mitel Web Bruteforcer/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity to detect if a web service with default credential is activated on a Mitel IP Phone.\n");
		$TextWidget  -> update ();				
	}
	elsif ($SelectLaunch =~ /SNOM Web Bruteforcer/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity to detect if a web service with default credential is activated on a SNOM IP Phone.\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /Polycom Soundpoint Web Bruteforcer/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "This tool provide the capacity to detect if a web service with default credential is activated on a Polycom Soundpoint IP Phone.\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /SIP Flooding/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Simple SIP Flooding tool.\n");
		$TextWidget  -> update ();				
	}
	elsif ($SelectLaunch =~ /SIP Fuzzer - Protos/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "GUI for protos SIP fuzzing tool.\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /TCP SYN FLood/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Simple TCP flooder.\n");
		$TextWidget  -> update ();			
	}
		
	#-------- EXPLOIT SECTION ----------------------------------------------	

	elsif ($SelectLaunch =~ /Aastra Phone telnet hardcode password/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Aastra IP Phones 6753i (at least) contain an hardcode telnet login/password.\n");
		$TextWidget  -> update ();		
	}
	elsif ($SelectLaunch =~ /Aastra Web Disclosure/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "The data disclosure vulnerability has been found in the section of 'Global SIP' of Aastra IP Phone software. The vulnerability allows the attacker to disclose the password of the SIP profile that is used to connect to ISP or PBX. To exploit the vulnerability and diclose the data we need to access the web GUI by through this url http://address/globalSIPsettings.html, or this one http://address/SIPsettingsLine1.html. we now have Caller ID, Authentication, Name, and Password. By editing the source code, we are able to see account name, password and SIP registrar fields in clear. All the needed information to sppof the identity of the user are available ...\n");
		$TextWidget  -> update ();		
	}
	elsif ($SelectLaunch =~ /Alcatel OXO FTP DoS/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Alcatel OXO FTP Space is limited. In version 8.0 and prior, no verification is done on the size of the file that can be uploaded on the OXO. If the file's size is bigger than the maximum size, the PBX will crash. It will take around 20 minutes to reboot.\n");
		$TextWidget  -> update ();	
	}
	elsif ($SelectLaunch =~ /Avaya TFTP Disclosure/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Avaya IPOL TFTP server provides access to several files containing sensible information about PBX configuration. This applicative module offer the possibility to get them, and thus, gain knowledge about system, user, extension, phone activity, voicemail passwords, ...\n\n");
		$TextWidget  -> update ();	
	}
	elsif ($SelectLaunch =~ /Mitel Web Disclosure/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "The data disclosure vulnerability has been found in section 'TempUserConfig1' of Mitel IP Phone software. The vulnerability allows the attacker to disclose the password of the SIP profile that is used to connect to ISP or PBX. To exploit the vulnerability and diclose the data we need to access the web GUI through this url http://address/TempUserConfig1. By editing the source code, we are able to see account name, password and SIP registrar fields in clear. All the needed information to spoof the identity of the user are available ...\n");
		$TextWidget  -> update ();	
	}
	elsif ($SelectLaunch =~ /Mitel XSS/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Cross Site Scripting vulnerability has been found in « TempUserConfigAddNew » URL : http://@IP/TempUserConfigAddNew) and allow remote user to inject arbitrary code.\n");
		$TextWidget  -> update ();	
	}	
	elsif ($SelectLaunch =~ /Mitel Unauthenticated Command Execution/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Mitel Audio and Web Conferencing (AWC) is a simple, cost-effective and scalable audio and web conferencing solution supporting upto 200 ports. ProCheckUp has discovered that the AWC web user interface is vulnerable to an unauthenticated command execution attack. Command execution allows Unix commands to be remotely executed with the permissions associated with the web service account. No authentication is required to exploit this vulnerability.\n");
		$TextWidget  -> update ();		
	}
	elsif ($SelectLaunch =~ /Polycom HDX Telnet Authorization Bypass/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "The Polycom HDX is a series of telecommunication and video devices. The telnet component of Polycom HDX  video endpoint devices is vulnerable to an authorization bypass when multiple simultaneous connections are repeatedly made to the service, allowing remote network attackers to gain full access to a Polycom command prompt without authentication.\n");
		$TextWidget  -> update ();			
	}
	elsif ($SelectLaunch =~ /Polycom HTTP DoS/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Polycom SoundPoint IP devices (IP phones) are vulnerable to Denial of Service attacks. Sending HTTP GET request with broken Authorization header effect a device restart after ~60 seconds.\n");
		$TextWidget  -> update ();			
	}	
	elsif ($SelectLaunch =~ /Polycom Web Disclosure/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "The data disclosure vulnerability found in the section of 'Lines' -> 'Line 1' of 'Polycom IP Phone' software. The vulnerability allows the attacker to disclosure the password of the username for the phone line that connected. To exploit the vulnerability and discluse the data we need to access to the 'Polycom IP Phone' by this url 'http://address/reg_1.htm'. Then we can see in the source code by the field 'reg.1.auth.password' and then we see the magic! thats is the password for the username by the sip server. Now if we already have the sip server, username and password so we can connect to it with any softphone and make our calls.\n");
		$TextWidget  -> update ();				
	}	
	elsif ($SelectLaunch =~ /SNOM Call Remote Tapping/)
	{
		$TextWidget -> delete('0.0', 'end');
		$TextWidget -> insert ("end", "Some Snom VoIP phones have a feature called -PCAP Trace- that allows, via the web interface, the start/stop and download of a PCAP file on the Snom VoIP phone. The Snom PCAP Trace feature does have limitations in that it the PCAP data is stored in a circular buffer because of memory limitations, and that enabling PCAP capture can impact the phone’s performance (no surprise here). Still, it is a scary feature that if not secured creates an attack vector where a remote attacker can literally tap your phone.

To start/stop a PCAP on the Snom VoIP phone, one just clicks on the -Start- or -Stop- buttons on the phone webpage. After the capture is complete, an attacker can then download the PCAP trace and extract the audio using Wireshark or the amazing command-line RTPbreak by Michele Dallachiesa.

So, combining the web page place call feature with the PCAP trace feature, an attacker can make a Snom VoIP phone call any number and then the attacker can capture the call remotely on the Snom VoIP phone. For the final touch, an attacker can also delete the call record of the last call made, thereby wiping the apparent record of the call, at least on the Snom VoIP phone itself.\n");
		$TextWidget  -> update ();			
	}	
}

sub ABOUT
{
	
	my $about_win = MainWindow->new(
						-title => 'ISME - About');



	my $labeled_frame = $about_win ->LabFrame(
										-label => "Version",
                                   		-labelside => "acrosstop"
                                   		)->pack(-side => 'top', -anchor => 'w');



#-------------------------------
	my $FrameImage = $labeled_frame->Frame ();
	my $ImageLogo = $FrameImage->Photo( 
										-format => 'jpeg',
										-file => "Image/lutin_logo.jpg",
										 );
	$FrameImage->Label(
					-image => $ImageLogo,
					-borderwidth => 2,
			        -relief      => 'sunken',
			             )->pack(-side => 'left');
	$FrameImage -> pack (-side => 'left', -anchor => 'w');
#-------------------------------
	my $FrameOrganizeLabel = $labeled_frame->Frame ();
		
	my $FrameTitle = $FrameOrganizeLabel -> Frame ();	
	my $Title = $FrameTitle->Label(
						-text => 'ISME (IP Phone Scanning Made Easy)',
						)->pack(-side => 'left');
	$FrameTitle -> pack (-side => 'top', -anchor => 'w');

	my $FrameVersion = $FrameOrganizeLabel -> Frame ();	
	my $Version = $FrameVersion->Label(
					-text => 'Version: 0.12'
					)->pack(-side => 'top');
	$FrameVersion -> pack (-side => 'top', -anchor => 'w');
	
	my $FrameDate = $FrameOrganizeLabel-> Frame ();	
	my $Date = $FrameDate->Label(
					-text => 'Date: 06/10/2013'
					)->pack(-side => 'top');
	$FrameDate -> pack (-side => 'top', -anchor => 'w');
	
	my $FrameAuthor = $FrameOrganizeLabel-> Frame ();	
	my $Author = $FrameAuthor->Label(
					-text => 'Author: Cedric Baillet'
					)->pack(-side => 'top');
	$FrameAuthor -> pack (-side => 'top', -anchor => 'w');
	
	my $FrameUrl = $FrameOrganizeLabel -> Frame ();	
	my $Url = $FrameUrl->Label(
					-text => 'Web: https://freecode.com/projects/ip-phone-scanning-made-easy-isme    '
					)->pack(-side => 'top');
	$FrameUrl -> pack (-side => 'top', -anchor => 'w');
	$FrameOrganizeLabel -> pack (-side => 'left', -anchor => 'w');
	
}
	
sub LAUNCHMODULE
{
	system ($CommandToLaunch);		
}
	
