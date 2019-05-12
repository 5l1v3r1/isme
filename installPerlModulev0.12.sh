echo "--------------------------------------------"
echo "ISME: Starting to install perl modules"
echo "--------------------------------------------"
echo "ISME: Uncompressing local archives"
cd PerlModuleSource
tar -zxvf libdnet-1.11.tar.gz
tar -zxvf HTTP-Message-6.02.tar.gz
tar -zxvf libwww-perl-6.03.tar.gz
tar -zxvf LWP-Protocol-https-6.02.tar.gz
tar -zxvf Mozilla-CA-20111025.tar.gz
tar -zxvf Net-RawIP-0.25.tar.gz
tar -zxvf Net-Subnets-0.21.tar.gz
echo "ISME: Installing libdnet"
cd libdnet-1.11
./configure
make
make install
cd ..
echo "ISME: Installing perl modules"
echo "--------------------------------------------"
echo "ISME: Next local module: HTTP-Message-6.02"
cd HTTP-Message-6.02
perl Makefile.PL
make
make install
cd ..
echo "ISME: Next local module: libwww-perl-6.03"
cd libwww-perl-6.03
perl Makefile.PL
make
make install
cd ..
echo "ISME: Next local module: LWP-Protocol-https-6.02"
cd LWP-Protocol-https-6.02
perl Makefile.PL
make
make install
cd ..
echo "ISME: Next local module: Mozilla-CA-20111025"
cd Mozilla-CA-20111025
perl Makefile.PL
make
make install
cd ..
echo "ISME: Next local module: Net-RawIP-0.25"
cd Net-RawIP-0.25
perl Makefile.PL
make
make install
cd ..
echo "ISME: Next local module: Net-Subnets-0.21"
cd Net-Subnets-0.21
perl Makefile.PL
make
make install
cd ..
echo "ISME: Next modules through Internet"
perl -MCPAN -e 'install Crypt::SSLeay'
perl -MCPAN -e 'install Net::Libdnet' 
perl -MCPAN -e 'install Net::Netmask'
perl -MCPAN -e 'install Net::Ping'
perl -MCPAN -e 'install Net::TFTP'
perl -MCPAN -e 'install Net::DNS'
perl -MCPAN -e 'install Net::DHCP::Packet'
perl -MCPAN -e 'install HTML::Parser'
perl -MCPAN -e 'install Tk'
perl -MCPAN -e 'install Net::OpenSSH'
perl -MCPAN -e 'install Net::SSH'
perl -MCPAN -e 'install Carp'
perl -MCPAN -e 'install Digest::MD5'
echo "--------------------------------------------"
echo "ISME: DONE"
echo "--------------------------------------------"
