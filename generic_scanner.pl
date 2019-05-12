# perl
#--------------------------------------------------------------------------------#
# ISME: Ip phone Scanning Made Easy
# This script should test Cisco IP Phone embedded web server to bring a more 
# complete information thant a simple scan.
#
# Proper syntax to launch:
# sudo isme.pl 
#--------------------------------------------------------------------------------#
# LICENCE
# This software is under GNU GENERAL PUBLIC LICENSE
# The detail could be found in the file LICENCE include
# in the same directory than isme.pl
#--------------------------------------------------------------------------------#
#



use LWP::UserAgent; # http://search.cpan.org/~gaas/libwww-perl-6.03/lib/LWP/UserAgent.pm
use Net::Ping; # http://search.cpan.org/~smpeters/Net-Ping-2.36/lib/Net/Ping.pm
use Net::Netmask; # http://search.cpan.org/dist/Net-Netmask/
use Net::TFTP; # http://search.cpan.org/~gbarr/Net-TFTP-0.16/TFTP.pm
use IO::Socket;
use Net::Libdnet::Arp;
use Net::Subnets;

use Tk; # http://search.cpan.org/~srezic/Tk/pod/UserGuide.pod
use Tk::Radiobutton;
use Tk::PNG;

# IP Address of scanned ip phone.
my $Address_alive="";
my $url="";

# Variable where servers IP address will stocked once found.
my $Tftp_server_IP;
my $dhcp_server_IP;
my $dns_server_IP;
my $CUCM1_server_IP;
my $CUCM2_server_IP;

my $IPPhone_Type; # IP Phone model.
my $hostname; # name of the IP Phone 
my $hostname_complet; #name of the IP Phone config file.
my $IPPhone_DN; # IP Phone number
my $GARP; # IP PHone GARP config parameter. If enable, MITM is easy.
my $ConfigFile; # Get the config file trough TFTP or not ?

my $port_to_test; # port to test.
my $port_status; # Open: tested port is active. Closed, well port closed.
my $Editor_identification; #contains the editor associated to the device mac address.

my $port5060UDPfound=0; # Used to determine if the port is found or not.
my $port5060TCPfound=0; # Used to determine if the port is found or not.
my $port5061UDPfound=0; # Used to determine if the port is found or not.
my $port5061TCPfound=0; # Used to determine if the port is found or not.
my $port2000TCPfound=0; # Used to determine if the port is found or not.

my $CiscoIPPhoneFound=0; #Used to determine which result to print.

my $Mac_Address="";
my $MacKnown=0;
my $Editor_identification="";

my $IPAdressAliveNoWeb=0;
my $IPAdressAliveWeb=0;
my $IPAdressAliveWebCisco=0;
my $AddressDead=0;

my $HistoryFile=""; # name of the file where sucessful scans will be log
my $HystoryFileToLoad="";# name of the file to load from hystory menu.

my $ScanActivate = 0; # once the scan is start no action can be done until finished.

my $WebServerBanner = ""; # content the web banner grab in the function GRAB_WEB_BANNER

my $FilterResultsInTextWidget =""; # COntains the output show in TextWidget following the filtering of results. Used to save the result if needed.

my $HistoryVariable;




# Declaring functions for network analyzing stuff. Thus no argument passing for function. Its all full available variable.
my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
$ua->timeout(3);	
$p=Net::Ping->new("icmp");

#---------- Starting to draw the GUI INTERFACE -----------------------------------------------
# Main windows declaration.
my $mw = MainWindow->new(-title => 'Generic Scanner');

my $menu_bar = $mw->Frame(
	-relief => 'groove',
	-borderwidth => 3,
	-width => 40,
#	-background => 'purple',
	)-> pack(
		-side=>'top',
		-fill => 'x'
		);
my $file_mb = $menu_bar->Menubutton(
			-text => 'File',
			)->pack(
				-side=>'left'
				);
$file_mb->command(
		-label=>'Launch scanning',
		-command => sub {
							# Subnet testing
							if ($SubnetToScan =~ /[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}\/[0-9]{1,2}/)

							{
								&LAUNCH_SCANNING;	
							}
							else
							{
								$mw->Dialog(-title => 'WARNING', 	
											-text => 'Bad IP Subnet syntax !',
											)->Show( );
   							}
						}
		);
$file_mb->command(
		-label=>'Save logs',
		-command => sub {&SAVEFILTERRESULTS}
		);

$file_mb->command(
		-label=>'Exit',
		-command => sub {exit}
		);

#-----Next menu item	
$file_mb = $menu_bar->Menubutton(
			-text => 'History',
			)->pack(
				-side=>'left'
				);
$file_mb->command(
			-label=>"Open saved scans",
			-command => sub {&OPEN_SAVED_FILE}
			);

$file_mb->command(
			-label=>"Delete saved scans",
			-command => sub {&DELETE_SAVED_FILE}
			);

#-----Next menu item	
$file_mb = $menu_bar->Menubutton(
			-text => 'Filter',
			)->pack(
				-side=>'left'
				);
$file_mb->command(
			-label=>"SEE ALL LOGS",
			-command => sub {&FILTERALLIP}
			);
$file_mb->command(
			-label=>"5060 UDP (SIP): Open",
			-command => sub {&FILTERSIPUDPOPEN}
			);
$file_mb->command(
			-label=>"5061 UDP (SIPS): Open",
			-command => sub {&FILTERSIPSUDPOPEN}
			);
$file_mb->command(
			-label=>"5060 TCP (SIP): Open",
			-command => sub {&FILTERSIPTCPOPEN}
			);
$file_mb->command(
			-label=>"5061 TCP (SIPS): Open",
			-command => sub {&FILTERSIPSTCPOPEN}
			);
$file_mb->command(
			-label=>"2000 TCP (SCCP): Open",
			-command => sub {&FILTERSCCPTCPOPEN}
			);
$file_mb->command(
			-label=>"Web server available",
			-command => sub {&FILTERWEBSERVER}
			);	
$file_mb->command(
			-label=>"Cisco IP Phones",
			-command => sub {&FILTERCISCOPHONE}
			);	
			

					
			
#-------------DEFAULT WIDTH 79 --------------
my $FrameTOP = $mw -> Frame ();
$FrameTOP->Label(
	-text => 'Subnet to scan (192.168.1.0/24):'
	)->pack(-side => 'left');
my $TextLabel = $FrameTOP -> Entry(
	-textvariable => \$SubnetToScan
	)->pack(-side => 'left');
$FrameTOP -> pack (-side => 'top', -anchor => 'w');


#-------------
my $FrameMIDDLE2 = $mw -> Frame (-width => 40, -height => 20);

my $TextWidget = $FrameMIDDLE2  -> Text(); 
$TextWidget->configure(-height => 20);

my $scrollbar = $FrameMIDDLE2 ->Scrollbar(-command => ['yview', $TextWidget]);

$TextWidget->configure(-yscrollcommand => ['set', $scrollbar]);
$TextWidget->pack(-side => 'left', -fill => 'both', -expand => 1);
$scrollbar->pack(-side => 'right', -fill => 'y');
$FrameMIDDLE2  -> pack (-side => 'top');

#-------------
my $FrameMIDDLE3 = $mw -> Frame (-width => 40, -height => 15);

my $ListBoxMIDDLE3 = $FrameMIDDLE3->Listbox( 
										-width => 26,
										-height => 15,
										-selectmode => "browse" # Only one item can be selected at a time
										 );
my $ScrollbarLB = $FrameMIDDLE3 ->Scrollbar(-command => ['yview', $ListBoxMIDDLE3]);
$ListBoxMIDDLE3->configure(-yscrollcommand => ['set', $ScrollbarLB]);

$ScrollbarLB->pack(-side => 'left', -fill => 'y');
$ListBoxMIDDLE3->pack(-side => 'left');

my $TextWidgetSpec = $FrameMIDDLE3 -> Text(); 
$TextWidgetSpec->configure(-width => 50, -height => 15);
my $scrollbar = $FrameMIDDLE3 ->Scrollbar(-command => ['yview', $TextWidgetSpec]);
$TextWidgetSpec->configure(-yscrollcommand => ['set', $scrollbar]);
$TextWidgetSpec->pack(-side => 'left', -fill => 'both', -expand => 1);
$scrollbar->pack(-side => 'right', -fill => 'y');

$FrameMIDDLE3  -> pack (-side => 'top');
#-------------
my $FrameMIDDLE4 = $mw -> Frame (-width => 40, -height => 15);
$FrameMIDDLE4->Button(
	-width => 79,
	-text    => 'Show details of selected IP address',
#	-activebackground => 'red',
#	-background => 'red',
	-command => sub {&PRINT_SELECTED_SUCCESSFUL_ADDRESS}
	)->pack(-side => 'bottom', -expand => 1, -fill => 'both');

$FrameMIDDLE4  -> pack (-side => 'top');

#------------ LAUNCHING THE MAIN LOOP --------
MainLoop;
#------------ END OF THE GUI INTERFACE DEFINITION STUFF -------------------------------------




#-----------------------------------------------------------------------------
# Sub function area

# sub LAUNCH_SCANNING - function piloting scan stuff.
# sub GRAB_WEB_BANNER - grab banner from web server detected on non cisco ip phone.
# sub AnalyzeHTML - analyze the HTML code from main page of cisco ip phone web server.
# sub FIND_SERVERS - analyze IP Phone web page contaning information about servers.
# sub TFTP - get the config file associated to a cisco IP Phone. Config file is create in the directory "CiscoIpPhoneConfigFile".
# sub PRINT_RESULTS
# sub TEST_PORT - test specific network ports for IP Address not identified as a cisco IP phone.
# sub GET_MAC - get mac address associated with the IP address detected as alive but not identified as a cisco IP Phone.
# sub WARNING - display a new windows informing the user that nothing could be done while scanning.
# sub LOAD_HISTORY
# sub PRINT_SELECTED_SUCCESSFUL_ADDRESS. Associated to main interface bottom button.
# sub DELETE_SAVED_FILE
# sub OPEN_SAVED_FILE
# sub FILTERSIPUDPOPEN - filter the result through the menu filter.			
# sub FILTERSIPSUDPOPEN - filter the result through the menu filter.			
# sub FILTERSIPTCPOPEN - filter the result through the menu filter.
# sub FILTERSIPSTCPOPEN - filter the result through the menu filter.
# sub FILTERSCCPTCPOPEN - filter the result through the menu filter.
# sub FILTERWEBSERVER - filter the result through the menu filter.
# sub FILTERCISCOPHONE
# sub SAVEFILTERRESULTS
# sub SAVETOCSV - unused right now.

#-----------------------------------------------------------------------------



sub LAUNCH_SCANNING
{
	
	$ScanActivate = 1; # scan is active, no more actions are alowwed.
	
	# emptying GUI to see only new scan information.
	$ListBoxMIDDLE3->delete (0,'end');
	$TextWidget -> delete('0.0', 'end');
	$TextWidgetSpec -> delete('0.0', 'end');
	$FilterResultsInTextWidget="";
	my $GoingOut = 1;
	
	#---- Creating a table with all the IP adresses -------
	my $sn = Net::Subnets->new;
   	my ( $lowipref, $highipref ) = $sn->range( \$SubnetToScan );
    my $lowIP = $$lowipref;
	my $highIP = $$highipref;
	my $listref = $sn->list( \( $lowIP, $highIP ) );
    
    
    my $block = Net::Netmask->new( "$SubnetToScan" );
		
	my $network_address    = $block->base();
	#my $first_valid        = $block->nth(1);
	#my $last_valid         = $block->nth( $block->size - 2 );
	#my $broadcast_address  = $block->broadcast();
		
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = $year + 1900;
	$HistoryFile="scan_history/".$year."-".$mon."-".$mday."-".$hour."h".$min."mn -".$network_address.".isme";
	open (MYHISTORYFILE, ">>$HistoryFile");
				
	#Incrementation jump. I'm too lazy to make it proper on the whole function :-(
		
		$TextWidget -> insert ("end","-------------------------------------------------------------------------------\n");
		$TextWidget -> insert ("end","Cisco IP Phone Scanner Launched.\n");
		$TextWidget -> insert ("end","Scanned network:$network_address.\n");
		$TextWidget -> insert ("end","Be patient, it takes several minutes to test all IP addresses.\n");
		$TextWidget -> insert ("end","\n");
		$TextWidget  -> update ();
		$TextWidget  -> see ('end');
		
		foreach my $scan_address ( @{ $listref } ) 
		{
				# Initialization.
				$Address_alive = $scan_address;
				#$Address_alive=$_;
				
				$hostname="";
				$hostname_complet="";
				$Tftp_server_IP="";
				$dhcp_server_IP="";
				$dns_server_IP="";
				$CUCM1_server_IP="";
				$Editor_identification="";
		
				$port5060UDPfound=0;
				$port5060TCPfound=0;
				$port5061UDPfound=0;
				$port5061TCPfound=0;
				$port2000TCPfound=0;
				
				$CiscoIPPhoneFound=0;
				
				$Mac_Address="Unknown";
				$MacKnown=0;
				$Editor_identification="Unknown";
				
				$AddressDead=0;
				$IPAdressAliveNoWeb=0;
				$IPAdressAliveWeb=0;
				$IPAdressAliveWebCisco=0;
				
				$SmarterQualificationIS=0;
				$SmarterQualification = "";
				
				if ($p->ping($Address_alive)) 
				{					
						$url='http://'.$Address_alive;
						
						$ua->credentials( $netloc, "ISMEtesting", "test", "testit" );
						if ($request = new HTTP::Request('GET', $url))
						{
							$response = $ua->request($request);
							$content = $response->content();		
 
							#Case 1: No web server available. Probably not an IP Phone.
							if ($content =~ /Connection refused/)
							{
								# Printing parameter.
								$IPAdressAliveNoWeb=1;
		
								&GET_MAC;
								&TEST_PORT;
								
								# Add IP address detected as alive in the list box.
								$ListBoxMIDDLE3->insert('end',"$Address_alive");
								$ListBoxMIDDLE3->yviewMoveto( 1 );
							}
							
							elsif (($content =~ /timed out/) || ($content =~ /timeout/))
							{
 
								# Printing parameter.
								$IPAdressAliveNoWeb=1;
								&GET_MAC;
								&TEST_PORT;
								
								# Add IP address detected as alive in the list box.
								$ListBoxMIDDLE3->insert('end',"$Address_alive");	
								$ListBoxMIDDLE3->yviewMoveto( 1 );
							}
							
							#Case 2: Web server available. Potentially a Cisco IP Phone.
							else
					 		{		
								# Analyzing web page.
								if (($content =~ /Cisco IP Phone/) || ($content =~ /Cisco Unified IP Phone/) || ($content =~ /Cisco Systems/) || ($content =~ /Cisco Systems, Inc. IP Phone/))
								{
									# initialisation of $hostname item.
									$hostname = "";
									&AnalyzeHTML;	
									
									$hostname_complet=$hostname.".cnf.xml";
									&FIND_SERVERS;
									
									#print "IP adresse $Address_alive alive. Cisco Device Web server available.\n";
									$CiscoIPPhoneFound=1;
									
									# Add IP address detected as alive in the list box.
									$ListBoxMIDDLE3->insert('end',"$Address_alive - Cisco Phone");
									$ListBoxMIDDLE3->yviewMoveto( 1 );
								}
								else
								{
									$url='https://'.$Address_alive;
						
									if ($request = new HTTP::Request('GET', $url))
									{
										$response = $ua->request($request);
										$content = $response->content();
										if ($content =~ /Cisco Unified Wireless/)
										{
											# initialisation of $hostname item.
											$hostname = "";
											&AnalyzeHTML;	
											
											$hostname_complet=$hostname.".cnf.xml";
											&FIND_SERVERS;
											
											#print "IP adresse $Address_alive alive. Cisco Device Web server available.\n";
											$CiscoIPPhoneFound=1;
											
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive - Cisco Phone");
											$ListBoxMIDDLE3->yviewMoveto( 1 );
										}
										elsif ($content =~ /CP-7985/)
										{
											# initialisation of $hostname item.
											$hostname = "";
											&AnalyzeHTML;	
											
											$hostname_complet=$hostname.".cnf.xml";
											&FIND_SERVERS_7985;
											
											#print "IP adresse $Address_alive alive. Cisco Device Web server available.\n";
											$CiscoIPPhoneFound=1;
											
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive - Cisco Phone");
											$ListBoxMIDDLE3->yviewMoveto( 1 );
										}										
										elsif ($content =~ /OmniPCX \for Enterprise/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "OmniPCX for Enterprise";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
#											eval { &GRAB_WEB_BANNER;} or die (@_); 

																						
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");	
											$ListBoxMIDDLE3->yviewMoveto( 1 );										
										}											
										elsif ($content =~ /Alcatel-Lucent OmniVista 4760 NMS/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Alcatel-Lucent OmniVista 4760 NMS";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}
										
										elsif ($content =~ /Alcatel-Lucent OmniTouch 8660/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Alcatel-Lucent OmniTouch 8660";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");	
											$ListBoxMIDDLE3->yviewMoveto( 1 );										
										}	
										elsif ($content =~ /Alcatel-Lucent Omnitouch 8400/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Alcatel-Lucent Omnitouch 8400";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}										
										elsif ($content =~ /Cisco Unified Contact Center Express/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Cisco Unified Contact Center Express";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}
										elsif ($content =~ /CISCO Codec/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "CISCO Codec";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}
										elsif ($content =~ /Codian MCU/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Codian MCU";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}																														
										elsif ($content =~ /7450/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Aastra Management 7450";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}
										elsif ($content =~ /Cisco Unified Communications Manager/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Cisco Unified Communications Manager";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}
										elsif ($content =~ /VMware ESX Server/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "VMware ESX Server";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");
											$ListBoxMIDDLE3->yviewMoveto( 1 );											
										}
										elsif ($content =~ /Cisco Unified Presence/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Cisco Unified Presence";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");	
											$ListBoxMIDDLE3->yviewMoveto( 1 );										
										}
										elsif ($content =~ /Cisco Unity Connection/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "Cisco Unity Connection";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											}; 
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");	
											$ListBoxMIDDLE3->yviewMoveto( 1 );										
										}
										elsif ($content =~ /CyberGuard Management Console/)
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$SmarterQualificationIS=1;
											$SmarterQualification = "CyberGuard Management Console";
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											}; 
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");	
											$ListBoxMIDDLE3->yviewMoveto( 1 );										
										}												
										else
										{								
											# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
											$IPAdressAliveWeb=1;
											&GET_MAC;
											&TEST_PORT;
											eval
											{
												local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
												alarm 30;
												&GRAB_WEB_BANNER;
												alarm 0;
											};
			
											# Add IP address detected as alive in the list box.
											$ListBoxMIDDLE3->insert('end',"$Address_alive");	
											$ListBoxMIDDLE3->yviewMoveto( 1 );										
										}										
									}
									else
									{								
									# printing parameter. IP Alive, web server available but Cisco IP Phone not recognize.
									$IPAdressAliveWeb=1;
									&GET_MAC;
									&TEST_PORT;
									eval
									{
										local $SIG{ALRM} = sub { die "alarm\n" }; # N.B. : \n obligatoire
										alarm 30;
										&GRAB_WEB_BANNER;
										alarm 0;
									};
									
	
									# Add IP address detected as alive in the list box.
									$ListBoxMIDDLE3->insert('end',"$Address_alive");
									$ListBoxMIDDLE3->yviewMoveto( 1 );
									}	
								}
							 	
					 		}
				 		}
				 		else
						{
							&GET_MAC;
							&TEST_PORT;
				 			#break;
				 		}
				}
				else 
				{
						# Printing parameter
				        $AddressDead=1;
				        #print "IP adresse $Address_alive request timeout.\n";
				}
				&PRINT_RESULTS;		
		}
		close (MYHISTORYFILE);
		$ScanActivate = 0; # scan is finished, other actions are allowed.
		$TextWidget -> insert ("end","-------------------------------------------------------------------------------\n");
		$TextWidget -> insert ("end","Scan of network $network_address is OVER.\n");
		$TextWidget -> insert ("end","-------------------------------------------------------------------------------\n\n\n\n\n");	
	
}



sub GRAB_WEB_BANNER
{
	my $LocalPort ="80";
	my $LocalProto = "tcp";
	$WebServerBanner = "";

	my $LocalSock = IO::Socket::INET->new(
					PeerAddr => $Address_alive,
	                PeerPort => $LocalPort,
	                Proto    => $LocalProto,
	                Timeout => 3
	                );
	                	
	my $LocalRequest = "HEAD / HTTP/1.1\015\012\n";

	print $LocalSock $LocalRequest;	
	my @lines;
	my @lines=<$LocalSock>;

	foreach $BannerLine (@lines) 
	{
		chomp ($BannerLine);
		$WebServerBanner=$WebServerBanner.$BannerLine."\n";		
	}
	close($LocalSock);
}

			 
sub AnalyzeHTML
{
		if($content =~ /Model Number<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([\+\/0-9A-Za-z-]+)<\/B><\/TD>/) 
		{
			# working out model type if the web page is in english.
			$IPPhone_Type = $1;
			# print "IP Phone type: $1\n";
		}
		elsif($content =~ /Model Number<\/B><\/TD>\W\W<td width=20><\/TD>\W\W<TD><B><strong>([\+\/0-9A-Za-z-]+)<\/strong><\/B><\/TD>/) 
		{
			# working out model type if the web page is in english.
			$IPPhone_Type = $1;
			# print "IP Phone type: $1\n";
		}
		elsif($content =~ /Model Number<\/b><\/td> <td><b>([\+\/0-9A-Za-z-]+)<\/b><\/td>/) 
		{
			# working out model type if the web page is in english.
			$IPPhone_Type = $1;
			# print "IP Phone type: $1\n";
		}
		
		elsif($content =~ /Numéro du modèle<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([\+\/0-9A-Za-z-]+)<\/B><\/TD>/) 
		{
			# working out model type if the web page is in french.
			$IPPhone_Type = $1;
			#print "IP Phone type: $1\n";
		}

		else
		{
			$IPPhone_Type = "Unknown";
			# print "IP Phone type: Unknown\n";
		}	
		#--------------------------------	
		if($content =~ /Host Name<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in english.
			$hostname = $1;
		}
		elsif($content =~ /Host Name<\/B><\/TD><td width=20><\/TD><TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in english.
			$hostname = $1;
		}
		elsif($content =~ /Host Name<\/B><\/TD>\W\W<td width=20><\/TD>\W\W<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in english.
			$hostname = $1;
		}				
		elsif($content =~ /Nom d'hôte<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in french.
			$hostname = $1;
		}
		elsif($content =~ /Nom hôte<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in french.
			$hostname = $1;
		}
		elsif($content =~ /Nom système<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in french.
			#print "Hostname: $1\n";
			$hostname = $1;
		}		
		else 
		{
				#print "Hostname: Unknown\n";
				$hostname = "Unknown";
		}

		#--------------------------------
		if($content =~ /Phone DN<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in english.
			$IPPhone_DN = $1;
		}
		elsif($content =~ /Phone DN 1<\/B><\/TD>\W\W<TD width=20><\/TD>\W\W<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in english.
			$IPPhone_DN = $1;
		}	
		elsif($content =~ /Numéro de téléphone<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9A-Za-z]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in french.
			$IPPhone_DN = $1;
		}
		#7985G
		elsif($content =~ /Phone DN<\/b><\/td> <td><b>([0-9A-Za-z]+)<\/b><\/td>/)
		{
			# working hostname type if the web page is in french.
			$IPPhone_DN = $1;
		}		
		else 
		{
				# print "Phone number: Unknown\n";
				$IPPhone_DN = "Unknown";
		}
		if($content =~ /Version<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9A-Za-z.-]+)<\/B><\/TD>/)
		{
			# working hostname type if the web page is in english.
			$Version = $1;
		}
		elsif($content =~ /App Load ID<\/b><\/td> <td><b>([0-9A-Za-z.-]+)<\/b><\/td>/)
		{
			# working hostname type if the web page is in english.
			$Version = $1;
		}		
}

sub FIND_SERVERS
{
	print "Je rentre ds find server\n";	
	# this url contains most servers ip address.
	my $Url_Detection_TFTP="http://".$Address_alive."/CGI/Java/Serviceability?adapter=device.statistics.configuration";
	my $Url_Detection_TFTP2="http://".$Address_alive."/NetworkConfiguration";
	my $Url_Detection_7985="http://".$Address_alive."/cisco_network_conf.ssi";

		
	my $request_tftp = new HTTP::Request('GET', $Url_Detection_TFTP);
	my $response_tftp = $ua->request($request_tftp);
	my $content_tftp = $response_tftp->content();

	if (($content_tftp =~ /Error 404/) || ($content_tftp =~ /401/) || ($content_tftp =~ /Object Not Found/)|| ($content_tftp =~ /Protected Object/))
	{
#	print "Je rentre ds request2\n";	
		$request_tftp = new HTTP::Request('GET', $Url_Detection_TFTP2);
		$response_tftp = $ua->request($request_tftp);
		my $content_tftp = $response_tftp->content();	
		
		if (($content_tftp =~ /Error 404/) || ($content_tftp =~ /401/) || ($content_tftp =~ /Object Not Found/))
		{
			$request_tftp = new HTTP::Request('GET', $Url_Detection_7985);
			$response_tftp = $ua->request($request_tftp);
			my $content_tftp = $response_tftp->content();		
		}		
	}
	
	
	
	if ($content_tftp =~ /Serveur TFTP 1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$Tftp_server_IP = $1;
		&TFTP;

	}
	elsif ($content_tftp =~ /TFTP Server 1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$Tftp_server_IP = $1;
		&TFTP;
	}
	elsif ($content_tftp =~ /TFTP Server 1<\/b><\/td>\W\W<td width=20><\/td>\W\W<td><b>([0-9.]+)<\/b><\/td>/)
	{
		$Tftp_server_IP = $1;
		&TFTP;
	}
	elsif ($content_tftp =~ /TFTP Server 1<\/B><\/TD>\W\W<td width=20><\/TD>\W\W<TD><B>([0-9.]+)<\/B><\/TD>/)
	{
		$Tftp_server_IP = $1;
		&TFTP;
	}
	elsif ($content_tftp =~ /TFTP Server 1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.]+)<\/B><\/TD>/)
	{
		$Tftp_server_IP = $1;
		&TFTP;
	}
	#7985
	elsif ($content_tftp =~ /TFTP Server 1<\/b><\/td> <td><b>([0-9.a-zA-Z]+)<\/b><\/td>/)
	{
		$Tftp_server_IP = $1;
		&TFTP;
	}
	elsif ($content_tftp =~ /TFTP Server 1<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$dhcp_server_IP = $1;
	}	

	if ($content_tftp =~ /Serveur DHCP<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$dhcp_server_IP = $1;
	}
	elsif ($content_tftp =~ /DHCP Server<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$dhcp_server_IP = $1;
	}
	elsif ($content_tftp =~ /DHCP Server<\/b><\/td>\W\W<td width=20><\/td>\W\W<td><b>([0-9.a-zA-Z]+)<\/b><\/td>/)
	{
		$dhcp_server_IP = $1;
	}
	elsif ($content_tftp =~ /DHCP Server<\/B><\/TD>\W?<td width=20><\/TD>\W?<TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$dhcp_server_IP = $1;
	}
	# 7985<tr><td><b>DHCP Server</b></td> <td><b>192.168.100.10</b></td>
	elsif ($content_tftp =~ /DHCP Server<\/b><\/td> <td><b>([0-9.a-zA-Z]+)<\/b><\/td>/)
	{
		$dhcp_server_IP = $1;
	}
			
	#---------------------------------	
	if ($content_tftp =~ /Serveur DNS 1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$dns_server_IP = $1;
	}
	elsif ($content_tftp =~ /DNS Server 1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$dns_server_IP = $1;
	}
	elsif ($content_tftp =~ /DNS Server 1<\/b><\/td>\W\W<td width=20><\/td>\W\W<td><b>([0-9.a-zA-Z]+)<\/b><\/td>/)
	{
		$dns_server_IP = $1;
	}		
	elsif ($content_tftp =~ /DNS Server 1<\/B><\/TD><td width="20"><\/TD><TD><B>([0-9.a-zA-Z]+)<\/B><\/TD>/)
	{
		$dns_server_IP = $1;
	}
	elsif ($content_tftp =~ /DNS Server 1<\/b><\/td>\W\W<td width="20"><\/td>\W\W<td><b>([0-9.a-zA-Z]+)<\/b><\/td>/)
	{
		$dns_server_IP = $1;
	}
	#7985
	elsif ($content_tftp =~ /DNS Server 1<\/b><\/td> <td><b>([0-9.a-zA-Z]+)<\/b><\/td>/)
	{
		$dns_server_IP = $1;
	}	

	if ($content_tftp =~ /Unified CM 1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z -_]+)<\/B><\/TD>/)
	{
		$CUCM1_server_IP = $1;
	}
	elsif ($content_tftp =~ /CallManager 1<\/b><\/td>\W\W<td width=20><\/td>\W\W<td><b>([0-9.a-zA-Z -_]+)<\/b><\/td>/)
	{
		$CUCM1_server_IP = $1;
	}
	elsif ($content_tftp =~ /CallManager 1<\/B><\/TD>\W\W<td width=20><\/TD>\W\W<TD><B>([0-9.a-zA-Z -_]+)<\/B><\/TD>/)
	{
		$CUCM1_server_IP = $1;
	}	
	
	elsif ($content_tftp =~ /CUCM Server1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9a-zA-Z -_]+)<\/B><\/TD>/)
	{
		$CUCM1_server_IP = $1;
	}
	elsif ($content_tftp =~ /Serveur CUCM1<\/B><\/TD><td width=20><\/TD><TD><B>([0-9a-zA-Z -_]+)<\/B><\/TD>/)
	{
		$CUCM1_server_IP = $1;
	}
	#7985
	elsif ($content_tftp =~ /Unified CM 1<\/b><\/td> <td><b>([0-9.a-zA-Z]+)<\/b><\/td>/)
	{
		$CUCM1_server_IP = $1;
	}	
	
	if ($content_tftp =~ /GARP actif<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z ]+)<\/B><\/TD>/)
	{
		if ($1 == "Non")
		{
			$GARP = "Disable";
		}
		else
		{
			$GARP = "Enable";
		}
	}
	elsif ($content_tftp =~ /GARP Enabled<\/B><\/TD><td width=20><\/TD><TD><B>([0-9.a-zA-Z ]+)<\/B><\/TD>/)
	{
		if ($1 == "No")
		{
			$GARP = "Disable";
		}
		else
		{
			$GARP = "Enable";
		}
	}
	elsif ($content_tftp =~ /GARP Enabled<\/b><\/td>\W\W<td width=20><\/td>\W\W<td><b>([a-zA-Z ]+)<\/b><\/td>/)
	{
		if ($1 == "No")
		{
			$GARP = "Disable";
		}
		else
		{
			$GARP = "Enable";
		}
	}			
}
sub TFTP
{
    $tftp = Net::TFTP->new($Tftp_server_IP, BlockSize => 1024);
    $tftp->ascii;
    my $error = "";
    my $hostname_dest_final="CiscoIpPhoneConfigFile/".$hostname_complet;
    $tftp->get($hostname_complet, $hostname_dest_final);
#    $ConfigFile="Download sucessful ($hostname_complet)";
    $error=$tftp->error;
    if ($error =~ /Transfer Timeout/)
    {
    	$ConfigFile="TFTP Transfer timeout";
    }
	else
    {
    	$ConfigFile="Download sucessful ($hostname_complet)";
    }
    
}
# 7921  https://192.168.11.17/index.html

sub TEST_PORT
{	
	#---TCP 5060---------------
	my $port5060TCP = IO::Socket::INET -> new (
             Proto => "tcp",
		     Timeout => 3,
             PeerAddr => $Address_alive,
             PeerPort => "5060" );

	if ($port5060TCP)
	{	
		# print that TCP port 5060 has been found.
		$port5060TCPfound=1;
	}
	close ($port5060TCP);
	
	
	#---UDP 5060---------------
	my $icmp_timeout=2;	
	
	my $icmp_sock = new IO::Socket::INET(Proto=>"icmp");
	my $read_set = new IO::Select();
	$read_set->add($icmp_sock);
		
	my $buf="hello";
	my $sock = new IO::Socket::INET(
		PeerAddr=>$Address_alive,
    	PeerPort=>"5060" ,
    	Proto=>"udp");
	 # Send the buffer and close the UDP socket.
    $sock->send("$buf");
    close($sock);
    
    # Wait for incoming packets.
    ($new_readable) = IO::Select->select($read_set, undef, undef, $icmp_timeout);
    # Set the arrival flag.
    $icmp_arrived = "0";
	
	# For every socket we had received packets (In our case only one - icmp_socket)
    foreach $socket (@$new_readable)
    {
    	# If we have captured an icmp packages, Its probably "destination unreachable"
        if ($socket == $icmp_sock)
        {
        	# Set the flag and clean the socket buffers
            $icmp_arrived = "1";
            $icmp_sock->recv($buffer,50,0);
        }
    }
    if ( $icmp_arrived == "0" )
    {
         # print that UDP port 506O has been found.
         $port5060UDPfound=1;
    }
	# Close the icmp sock
	close($icmp_sock);
	
		
	#---TCP 5061---------------
	my $port5061TCP = IO::Socket::INET -> new (
             Proto => "tcp",
		     Timeout => 3,
             PeerAddr => $Address_alive,
             PeerPort => "5061" );

	if ($port5061TCP)
	{	
		# print that TCP port 5061 has been found.
		$port5061TCPfound=1;
	}
	close ($port5061TCP);
	

	#---UDP 5061---------------
	my $icmp_timeout=2;	
	
	$icmp_sock = new IO::Socket::INET(Proto=>"icmp");
	$read_set = new IO::Select();
	$read_set->add($icmp_sock);
		
	my $buf="hello";
	my $sock = new IO::Socket::INET(
		PeerAddr=>$Address_alive,
    	PeerPort=>"5061" ,
    	Proto=>"udp");
	 # Send the buffer and close the UDP socket.
    $sock->send("$buf");
    close($sock);
    
    # Wait for incoming packets.
    ($new_readable) = IO::Select->select($read_set, undef, undef, $icmp_timeout);
    # Set the arrival flag.
    $icmp_arrived = "0";
	
	# For every socket we had received packets (In our case only one - icmp_socket)
    foreach $socket (@$new_readable)
    {
    	# If we have captured an icmp packages, Its probably "destination unreachable"
        if ($socket == $icmp_sock)
        {
        	# Set the flag and clean the socket buffers
            $icmp_arrived = "1";
            $icmp_sock->recv($buffer,50,0);
        }
    }
    if ( $icmp_arrived == "0" )
    {
		# print that UDP port 5061 has been found.
		$port5061UDPfound=1;
    }
	# Close the icmp sock
	close($icmp_sock);


	#---- TEST 2000 TCP ---------
	my $port2000TCP = IO::Socket::INET -> new (
             Proto => "tcp",
		     Timeout => 3,
             PeerAddr => $Address_alive,
             PeerPort => "2000" );

	if ($port2000TCP)
	{	
		# print that TCP port 2000 has been found.
		$port2000TCPfound=1;
	}
	close ($port2000TCP);			
}      
sub GET_MAC
{
#-- ROLE DESCRIPTION ------------------------------------
# This function will find the mac address associated to the IP conatains in Âddress_live.
# Once doe, it will try to find the device editor by parsing the file mac_cosntructeurs.txt
#--------------------------------------------------------

	my $to_analyze="";
	$Editor_identification="Unknown";
	$Mac_Address="Unknown";
	$MacKnown=0;
	my $racine="";
	my $h = Net::Libdnet::Arp->new;
	
	$Mac_Address = $h->get($Address_alive);
#	print "Get MAC: $Mac_Address\n";

	my @split_macaddress = split (/[:]/, $Mac_Address);
	$racine=@split_macaddress[0].@split_macaddress[1].@split_macaddress[2];	
	# passing caracters to upper case
	$racine =uc ($racine);
	
	if ($racine != "")
	{	
	 	open (MYFILE2,'isme_data/mac_constructeurs.txt');
	 	while (<MYFILE2>)
	 	{
			my $loc = 0;
			$loc = index($_, $racine); # if $loc = -1 the string is not found.
				
			if ($loc >= 0)
			{
				$MacKnown=1;
				$to_analyze=$_;
			}
		}			
		close (MYFILE2);

		my @contain_editor = split (/[\*]/, $to_analyze);
		$Editor_identification=@contain_editor[1];
		chomp($Editor_identification);	
	}		
}

sub PRINT_RESULTS
{
	my $content="";
	$TextWidget -> insert ("end","-------------------------------------------------------------------------------\n");
	if ($AddressDead==1)
	{
			$TextWidget -> insert ("end","IP adresse $Address_alive request timeout.\n");
        #print "IP adresse $Address_alive request timeout.\n";
	}
	else
	{
		if ($CiscoIPPhoneFound==1)
		{	
			# Result if Cisco IP Phone is identified
			$TextWidget -> insert ("end","CISCO IP PHONE DETAILS:\n");
			$TextWidget -> insert ("end","IP Phone Type: $IPPhone_Type\n");
			$TextWidget -> insert ("end","IP Address: $Address_alive alive\n");
			$TextWidget -> insert ("end","Hostname: $hostname\n");
			$TextWidget -> insert ("end","Version: $Version\n");
			$TextWidget -> insert ("end","Phone number: $IPPhone_DN\n");
			$TextWidget -> insert ("end","Gratuitous ARP: $GARP\n");
			$TextWidget -> insert ("end","Config file: $ConfigFile\n");
			$TextWidget -> insert ("end","\n");
			
			$TextWidget -> insert ("end","FOUND FOLLOWING SERVERS OF IPT INFRASTRUCTURE:\n");
			$TextWidget -> insert ("end","DHCP Server: $dhcp_server_IP\n");
			$TextWidget -> insert ("end","DNS Server : $dns_server_IP\n");
			$TextWidget -> insert ("end","CUCM Server: $CUCM1_server_IP\n");
			$TextWidget -> insert ("end","TFTP Server: $Tftp_server_IP\n");
			$TextWidget -> insert ("end","\n");
			$content="CISCO IP PHONE DETAILS:*IP Phone Type: $IPPhone_Type*IP Address: $Address_alive alive*Hostname: $hostname*Version: $Version*Phone number: $IPPhone_DN*Gratuitous ARP: $GARP*Config file: $ConfigFile* *FOUND FOLLOWING SERVERS OF IPT INFRASTRUCTURE:*DHCP Server: $dhcp_server_IP*DNS Server : $dns_server_IP*CUCM Server: $CUCM1_server_IP*TFTP Server: $Tftp_server_IP*\n";
			
			$FilterResultsInTextWidget="CISCO IP PHONE DETAILS:\n";
			$FilterResultsInTextWidget="IP Phone Type: $IPPhone_Type\n";
			$FilterResultsInTextWidget="IP Address: $Address_alive alive\n";
			$FilterResultsInTextWidget="Hostname: $hostname\n";
			$FilterResultsInTextWidget="Version: $Version\n";
			$FilterResultsInTextWidget="Phone number: $IPPhone_DN\n";
			$FilterResultsInTextWidget="Gratuitous ARP: $GARP\n";
			$FilterResultsInTextWidget="Config file: $ConfigFile\n";
			$FilterResultsInTextWidget="\n";
			$FilterResultsInTextWidget="FOUND FOLLOWING SERVERS OF IPT INFRASTRUCTURE:\n";
			$FilterResultsInTextWidget="DHCP Server: $dhcp_server_IP\n";
			$FilterResultsInTextWidget="DNS Server : $dns_server_IP\n";
			$FilterResultsInTextWidget="CUCM Server: $CUCM1_server_IP\n";
			$FilterResultsInTextWidget="TFTP Server: $Tftp_server_IP\n";
			$FilterResultsInTextWidget="\n";	
			# save to history file
			print MYHISTORYFILE $content;			
		}
		else
		{
			if ($IPAdressAliveNoWeb==1)
			{
				$TextWidget -> insert ("end","IP adresse: $Address_alive alive.\n");
				$TextWidget -> insert ("end","No web server available.\n");
				$content="IP adresse: $Address_alive alive.*No web server available.*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."IP adresse: $Address_alive alive.\n";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."No web server available.\n";
			}
			elsif ($IPAdressAliveWeb==1)
			{
				$TextWidget -> insert ("end","IP adresse: $Address_alive alive.\n");
				$TextWidget -> insert ("end","Web server available.\n");
				$content="IP adresse: $Address_alive alive.*Web server available.*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."IP adresse: $Address_alive alive.\n";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."Web server available.\n";
				
				$TextWidget -> insert ("end","Web Server Banner: \n");
				$TextWidget -> insert ("end","--------------------------------------- \n");
				$TextWidget -> insert ("end","$WebServerBanner");
				$TextWidget -> insert ("end","--------------------------------------- \n");
				$content=$content."Web Server Banner: *--------------------------------------- *";
				$content=$content.$WebServerBanner."*--------------------------------------- *";
				$content =~ s/\n/\*/g;# Find \n and replace by * 
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."Web Server Banner: \n";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."--------------------------------------- \n";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."$WebServerBanner\n";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."--------------------------------------- \n";	
				
				if ($SmarterQualificationIS ==1)
				{
					$TextWidget -> insert ("end","Smarter Input: $SmarterQualification\n");	
					$content=$content."Smarter Input: $SmarterQualification*";
					$FilterResultsInTextWidget=$FilterResultsInTextWidget."Smarter Input: $SmarterQualification*";
				}	
		
			}		
		
			if ($MacKnown==0)
			{	
				$TextWidget -> insert ("end","Device editor: $Editor_identification\n");
				$content=$content."Device editor: $Editor_identification*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."Device editor: $Editor_identification\n";
			}
			elsif ($MacKnown==1)
			{		
				$TextWidget -> insert ("end","Device editor: $Editor_identification\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."Device editor: $Editor_identification\n";
				$content=$content."Device editor: $Editor_identification\\n*";
			}	
	
			$TextWidget -> insert ("end","MAC Address: $Mac_Address\n");
			$content=$content."MAC Address: $Mac_Address*";
			$FilterResultsInTextWidget=$FilterResultsInTextWidget."MAC Address: $Mac_Address\n";
			
	
			# Result if no Cisco IP Phone is identified
			if ($port5060UDPfound==1)
			{	
				$TextWidget -> insert ("end","5060 UDP (SIP): Open or Filter\n");
				$content=$content."5060 UDP (SIP): Open or Filter*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5060 UDP (SIP): Open or Filter\n";
			}
			else
			{	
				$TextWidget -> insert ("end","5060 UDP (SIP): Close\n");
				$content=$content."5060 UDP (SIP): Close*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5060 UDP (SIP): Close\n";
			}
			if ($port5061UDPfound==1)
			{	
				$TextWidget -> insert ("end","5061 UDP (SIPS): Open or Filter\n");
				$content=$content."5061 UDP (SIPS): Open or Filter*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5061 UDP (SIPS): Open or Filter\n";
			}
			else
			{	
				$TextWidget -> insert ("end","5061 UDP (SIPS): Close\n");
				$content=$content."5061 UDP (SIPS): Close*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5061 UDP (SIPS): Close\n";
			}
			
			if ($port5060TCPfound==1)
			{	
				$TextWidget -> insert ("end","5060 TCP (SIP): Open\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5060 TCP (SIP): Open\n";
				$content=$content."5060 TCP (SIP): Open*";
			}
			else
			{	
				$TextWidget -> insert ("end","5060 TCP (SIP): Close\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5060 TCP (SIP): Close\n";
				$content=$content."5060 TCP (SIP): Close*";
			}
			if ($port5061TCPfound==1)
			{	
				$TextWidget -> insert ("end","5061 TCP (SIPS): Open\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5061 TCP (SIPS): Open\n";
				$content=$content."5061 TCP (SIPS): Open*";
			}
			else
			{	
				$TextWidget -> insert ("end","5061 TCP (SIPS): Close\n");
				$content=$content."5061 TCP (SIPS): Close*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."5061 TCP (SIPS): Close\n";
			}
			if ($port2000TCPfound==1)
			{	
				$TextWidget -> insert ("end","2000 TCP (SCCP): Open\n");
				$content=$content."2000 TCP (SCCP): Open*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."2000 TCP (SCCP): Open\n";
			}
			else
			{	
				$TextWidget -> insert ("end","2000 TCP (SCCP): Close\n");
				$content=$content."2000 TCP (SCCP): Close*";
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."2000 TCP (SCCP): Close\n";
			}
	
			
			# save to history file
			$content=$content."*\n";
			print MYHISTORYFILE $content;			
		}
	}
	$TextWidget  -> update ();	
	$TextWidget  -> see ('end');	
}

sub PRINT_SELECTED_SUCCESSFUL_ADDRESS
{
	
	if ($ScanActivate == 0)
	{
		my $FoundLocal="";
		$TextWidgetSpec->delete('0.0', 'end');
		
		open (MYHISTORYFILE,"$HistoryFile");
		my $LbSelectedItem = $ListBoxMIDDLE3->curselection;
		my $ActiveIP = $ListBoxMIDDLE3 -> get($LbSelectedItem);
		
		if ($ActiveIP =~ /Cisco/)
		{
			my @split_ActiveIP = split (/[ - ]/, $ActiveIP);
			$ActiveIP=@split_ActiveIP[0];	
		}
	
		while (<MYHISTORYFILE>)
		{
			my $line="";		
			if ($_ =~ /$ActiveIP/)
		 	{
		 		$line=$_;
		 	}
			my @split_line = split (/[*]/, $line);
			foreach (@split_line)
			{
				my $text=$_;
				$TextWidgetSpec -> insert ('end',"$text\n");
			}
		}
		$TextWidgetSpec->update();
		close(MYHISTORYFILE);
	}
	elsif ($ScanActivate == 1)
	{
		# Forbidden while the scan is not completed
		&WARNING;	
	}	
}

sub WARNING
{
	
	$mw->Dialog(-title => 'WARNING', 	
				-text => 'Scanning is under completion. No action allowed until it\'s finished. !',
				)->Show( );
}

sub LOAD_HISTORY
{
	
	if($ScanActivate == 0)
	{
		$ListBoxMIDDLE3->delete (0,'end');
		$TextWidget -> delete('0.0', 'end');
		$TextWidgetSpec -> delete('0.0', 'end');
		
		#attetion la variable contenant le nom du fichier doit venir du menu principal.
		#$HistoryFile = "scan_history/192.168.0.0.txt";
		
		open (FINDIP, "$HistoryFile");
		
		while (<FINDIP>)
		{
			my $LocalLine = $_;
			my $LocalIP="";
			if ($LocalLine =~ /alive/)
			{
				if ($LocalLine =~ /CISCO IP PHONE/)
				{	
					my @TabSplit = split (/[*]/, $LocalLine);
					my @split2= split (/[ ]/, @TabSplit[2]);
					$LocalIP = @split2[2];				
				}
				else
				{
					my @TabSplit = split (/[*]/, $LocalLine);
					my @split2= split (/[ ]/, @TabSplit[0]);
					$LocalIP = @split2[2];
				}
				$ListBoxMIDDLE3->insert('end',"$LocalIP");
			}
		}
		$ListBoxMIDDLE3->update();		
			
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
}


sub OPEN_SAVED_FILE
{
	if($ScanActivate == 0)
	{
		my $types = [ ['isme files', '.isme']];
		my $OpenSavedFile = $mw->getOpenFile(-filetypes => $types,
	                              -defaultextension => '.isme',
	                              -initialdir => "scan_history"
	                              );
		$HistoryFile=$OpenSavedFile;
		&LOAD_HISTORY;
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
}

sub DELETE_SAVED_FILE
{
	if($ScanActivate == 0)
	{
		my $types = [ ['isme files', '.isme']];
		my $FileToDelete = $mw->getOpenFile(-filetypes => $types,
	                              -defaultextension => '.isme',
	                              -initialdir => "scan_history"
	                              );
		unlink ("$FileToDelete");
		
		my $subwin2 = $mw->Toplevel;
		
		#-- POP UP WINDOWS to inform user of the result-----
		$subwin2->title("INFORMATIONAL");
		my $menu_bar = $subwin2->Frame(
			-borderwidth => 3,
			-width => 5,
			)-> pack(
				-side=>'top',
				-fill => 'x'
				);
		my $file_mb = $menu_bar->Menubutton(
				-text => 'File',
				)->pack(
					-side=>'left'
					);
		$file_mb->command(
				-label=>'Exit',
				-command => sub {$subwin2->destroy}
			);
	
		my $FrameTxt = $subwin2 -> Frame (-width => 5, -height => 2);
	
		my $TextLabel = $FrameTxt -> Text(); 
		$TextLabel->configure(-height =>2);
		$TextLabel->pack(-side => 'left');
		$FrameTxt -> pack (-side => 'top');	
		$TextLabel -> insert ("end","$FileToDelete has been deleted.");
		$TextLabel -> update ();
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
}

sub FILTERSIPUDPOPEN
{
	if ($ScanActivate == 0)
	{
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";
		$TextWidget->insert('end',"TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIP UDP PORT\n");
		$FilterResultsInTextWidget=$FilterResultsInTextWidget."TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIP UDP PORT\n";
		
		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			my $ToFind = "5060 UDP (SIP): Open or Filter";
			my $loc = 0;
			$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.
			
			if ($loc >= 0)
			{
				my @splitAnalyze= split (/[*]/, $LineToAnalyze);
				$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
				foreach $line (@splitAnalyze)
				{
					$TextWidget->insert('end',"$line\n");
					$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
				}	
			}
		}	
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
}	

sub FILTERSIPSUDPOPEN
{
	if ($ScanActivate == 0)
	{
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";
		$TextWidget->insert('end',"TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIPS UDP PORT\n");
		$FilterResultsInTextWidget=$FilterResultsInTextWidget."TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIPS UDP PORT\n";

		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			my $ToFind = "5061 UDP (SIPS): Open or Filter";
			my $loc = 0;
			$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.
			
			if ($loc >= 0)
			{
				my @splitAnalyze= split (/[*]/, $LineToAnalyze);
				$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
				foreach $line (@splitAnalyze)
				{
					$TextWidget->insert('end',"$line\n");
					$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
				}	
			}
		}	
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
}

sub FILTERSIPTCPOPEN
{
	if ($ScanActivate == 0)
	{
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";
		$TextWidget->insert('end',"TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIP TCP PORT\n");
		$FilterResultsInTextWidget=$FilterResultsInTextWidget."TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIP TCP PORT\n";

		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			my $ToFind = "5060 TCP (SIP): Open";
			my $loc = 0;
			$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.
			
			if ($loc >= 0)
			{
				my @splitAnalyze= split (/[*]/, $LineToAnalyze);
				$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
				foreach $line (@splitAnalyze)
				{
					$TextWidget->insert('end',"$line\n");
					$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
				}	
			}
		}	
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
}	

sub FILTERSIPSTCPOPEN
{
	if ($ScanActivate == 0)
	{
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";
		$TextWidget->insert('end',"TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIPS TCP PORT\n");
		$FilterResultsInTextWidget=$FilterResultsInTextWidget."TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SIPS TCP PORT\n";

		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			my $ToFind = "5061 TCP (SIPS): Open";
			my $loc = 0;
			$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.
			
			if ($loc >= 0)
			{
				my @splitAnalyze= split (/[*]/, $LineToAnalyze);
				$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
				foreach $line (@splitAnalyze)
				{
					$TextWidget->insert('end',"$line\n");
					$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
				}	
			}
		}	
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
}

sub FILTERSCCPTCPOPEN
{
	if ($ScanActivate == 0)
	{
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";
		$TextWidget->insert('end',"TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SCCP PORT\n");
		$FilterResultsInTextWidget=$FilterResultsInTextWidget."TRYING TO FIND IDENTIFIED DEVICES WITH OPEN SCCP PORT\n";

		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			my $ToFind = "2000 TCP (SCCP): Open";
			my $loc = 0;
			$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.
			
			if ($loc >= 0)
			{
				my @splitAnalyze= split (/[*]/, $LineToAnalyze);
				$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
				foreach $line (@splitAnalyze)
				{
					$TextWidget->insert('end',"$line\n");
					$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
				}	
			}
		}
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
	
}

sub FILTERWEBSERVER
{
	if ($ScanActivate == 0)
	{	
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";
		$TextWidget->insert('end',"TRYING TO FIND IDENTIFIED DEVICES WITH EMBEDDED WEB SERVERS\n");
		$FilterResultsInTextWidget=$FilterResultsInTextWidget."TRYING TO FIND IDENTIFIED DEVICES WITH EMBEDDED WEB SERVERS\n";

		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			my $ToFind = "Web server available";
			my $loc = 0;
			$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.
			
			if ($loc >= 0)
			{
				my @splitAnalyze= split (/[*]/, $LineToAnalyze);
				$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
				foreach $line (@splitAnalyze)
				{
					$TextWidget->insert('end',"$line\n");
					$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
				}	
			}
		}
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
		
}

sub FILTERCISCOPHONE
{
	if ($ScanActivate == 0)
	{	
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";
		$TextWidget->insert('end',"TRYING TO FIND IDENTIFIED DEVICES WITH EMBEDDED WEB SERVERS\n");
		$FilterResultsInTextWidget=$FilterResultsInTextWidget."TRYING TO FIND IDENTIFIED DEVICES WITH EMBEDDED WEB SERVERS\n";

		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			my $ToFind = "CISCO IP PHONE DETAILS";
			my $loc = 0;
			$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.
			
			if ($loc >= 0)
			{
				my @splitAnalyze= split (/[*]/, $LineToAnalyze);
				$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
				foreach $line (@splitAnalyze)
				{
					$TextWidget->insert('end',"$line\n");
					$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
				}	
			}
		}
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}
		
}

sub FILTERALLIP
{

	if ($ScanActivate == 0)
	{	
		$FilterResultsInTextWidget="";
		$TextWidget -> delete('0.0', 'end');
		$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
		$FilterResultsInTextWidget="-------------------------------------------------------------------------------\n";

		open (TOFILTER, "$HistoryFile");
		while (<TOFILTER>)
		{
			my $LineToAnalyze=$_;
			
			my @splitAnalyze= split (/[*]/, $LineToAnalyze);
			$TextWidget->insert('end',"-------------------------------------------------------------------------------\n");
			$FilterResultsInTextWidget=$FilterResultsInTextWidget."-------------------------------------------------------------------------------\n";
			foreach $line (@splitAnalyze)
			{
				$TextWidget->insert('end',"$line\n");
				$FilterResultsInTextWidget=$FilterResultsInTextWidget.$line."\n";
			}	
		}
	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}	
}

sub SAVEFILTERRESULTS
{
	if($ScanActivate == 0)
	{
		my $FileToSave = $mw->getSaveFile(
								-defaultextension => '.txt',
	                            -initialdir => "user_data"
	                              );

		open (TOSAVE, ">>$FileToSave");
		print TOSAVE $FilterResultsInTextWidget;
		close (TOSAVE);

	}
	elsif ($ScanActivate == 1)
	{
		&WARNING;	
	}	
}	

sub SAVETOCSV
{
	# done through analysis of *HistoryFile information.
	open (TOFILTER, "$HistoryFile");
		
	my @AliveCiscoTable;
	my @AliveOtherTable;
	my $counter=0;
	while (<TOFILTER>)
	{
		my $LineToAnalyze=$_;
		my $ToFind = "CISCO IP PHONE DETAILS";
		my $loc = 0;
			
		$loc = index($LineToAnalyze, $ToFind); # if $loc = -1 the string is not found.

		if ($loc >= 0)
		{
			# search and replace every * by a ;
			$LineToAnalyze =~ s/\*/;/g; 
			@AliveCiscoTable[$counter]=$LineToAnalyze;
			$counter++;
								print "$LineToAnalyze\n";
		}
		else
		{
				
			# search and replace every * by a ;
			$LineToAnalyze =~ s/\*/;/g; 
			@AliveOtherTable[$counter]=$LineToAnalyze;
			$counter++;
		}
	}	
	open (TOSAVE, '>>SaveData.txt');
	foreach $line (@AliveCiscoTable)
	{
		print TOSAVE $line;	
	}
	foreach $line (@AliveOtherTable)
	{
		print TOSAVE $line;	
	}
	close (TOSAVE); 	
}


