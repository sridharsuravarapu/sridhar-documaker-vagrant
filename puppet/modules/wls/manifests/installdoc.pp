
# == Define: wls::installdoc
#
# installs Oracle Documaker Enterprise Edition
#
# === Examples
#
#    $jdkWls11gJDK = 'jdk1.7.0_09'
#    $wls11gVersion = "1036"
#
#  case $operatingsystem {
#     CentOS, RedHat, OracleLinux, Ubuntu, Debian: {
#       $osMdwHome    = "/opt/wls/Middleware11gR1"
#       $osWlHome     = "/opt/wls/Middleware11gR1/wlserver_10.3"
#       $oracleHome   = "/opt/wls/"
#       $user         = "oracle"
#       $group        = "dba"
#     }
#     windows: {
#       $osMdwHome    = "c:/oracle/wls11g"
#       $osWlHome     = "c:/oracle/wls11g/wlserver_10.3"
#       $user         = "Administrator"
#       $group        = "Administrators"
#     }
#  }
#
#
#  Wls::Installdoc {
#    mdwHome      => $osMdwHome,
#    wlHome       => $osWlHome,
#    fullJDKName  => $jdkWls11gJDK,
#    user         => $user,
#    group        => $group,
#  }
#
#
#  wls::installdoc{'docPS5':
#    docFile1      => 'ofm_doc_generic_11.1.1.6.0_disk1_1of2.zip',
#  }
#
##
define wls::installdoc($mdwHome         = undef,
                       $wlHome          = undef,
                       $oracleHome      = undef,
                       $fullJDKName     = undef,
                       $docFile1        = undef,
                       $user            = 'oracle',
                       $group           = 'dba',
                       $downloadDir     = '/install',
                       $remoteFile      = true,
                       $puppetDownloadMntPoint  = undef,
                    ) {

        $execPath        = "/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path            = $downloadDir
        $docOracleHome   = "${mdwHome}/oracle_doc1"
        $oraInventory    = "${oracleHome}/oraInventory"

#	Entries added to support the silent_doc.xml.erb file by sridhar

	$docHostName	 = "docapp"
	$docOracleDBHost = "docdb"
	$docOracleDBPort = "1521"
	$docDB_Name	 = "IDMaker"
	$docServiceType	 = "SID"
	$docConnString   = "docdb:1521:IDMaker"
	$docDmkrDBUser  = "dmkr_admin"
	$docDmkrDBPass	= "Welcome01"
	$docDmkrDBCFMPass = "Welcome01"
	$docDBSystemName = "System 1"
	$docAsmDBUser	 = "docAsmDBUser"
	$docAsmDBPass	= "docAsmDBPass"
	$docAsmDBCfmPass  = "docAsmDBPass"
	$docAsmDBSystemName = "Assembly Line 1"
	$docUniqueAssemblyLineServiceName = "dmkr_asline_Assembly Line 1"
	$docASUser = "weblogic"
	$docASPass = "weblogic1"
	$docASCfmPass = "weblogic1"
	$docJmsProviderURL = "t3://jmsserver:11001"
	$docJmsPrincipal = "principal"
	$docJmsCredentials = "weblogic1"
	$docCfmCredentials = "weblogic1"
	$docWlProviderUrl = ":11001"
	$docHotFolder = "/opt/oracle/middleware11g/oracle_doc1/documaker/hotdirectory"
	$docSmtpHost= " "
	$docSmtpUser= " "
	$docSmtpPass= " "
	$docSmtpCfmPass= " "
	$docSmtpPort= " "
	$docSmtpSender= " "
	$docSmtpConditionConfigureMode= "false"
	$docUCMEnable= "False"
	$docUcmUser= "UCMUserid"
	$docUCMPass= " "
	$docUCMCfmPass= " "
	$docUCMStr= "http://ucmserver:4444"
	$docUCMConnStrPre= "http://"
	$docUCMConnStrPost= ":4444"
	$docUCMDocUrl= "http://ucmserver:16200//cs/groups/secure/documents/document/"
	$docUCMConditionConfigureMode= "false"
	$docUMSEnable= "False"
	$docUMSUsr= " "
	$docUMSPass= " "
	$docUMSCfmPass= " "
	$docUMSEndPoint= "http://umsserver:8001/sdpmessaging/parlayx/SendMessageService"
	$docUMSConditionConfMode= "false"
	$docDMWebServiceEndPoint= "http://idmserver_myguess:10001/DWSV0AL1/CompositionService?WSDL"
	$docApprovalProcessEndPoint= "http://soaserver:8001/soa-infra/services/default/iDMkr_Correspondence/correspondenceprocesses_client_ep?WSDL"
	$docApprovalBusinessRulesEndPoint= "http://soaserver:8001/soa-infra/services/default/iDMkrApprovalRulesProj/iDMkrApprovalRules_DecisionService_ep"
	

        $docInstallDir   = "linux64"
        $jreLocDir       = "/usr/java/${fullJDKName}"

        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               mode    => 0775,
               owner   => $user,
               group   => $group,
               backup  => false,
             }

     	# check if the doc already exists
     	$found = oracle_exists( $docOracleHome )
     	if $found == undef {
       		$continue = true
     	} else {
       		if ( $found ) {
         		$continue = false
       		} else {
         	notify {"wls::installdoc ${title} ${docOracleHome} does not exists":}
         	$continue = true
       		}
     	}

if ( $continue ) {

   if $puppetDownloadMntPoint == undef {
     $mountPoint =  "puppet:///modules/wls/"
   } else {
     $mountPoint =  $puppetDownloadMntPoint
   }

   wls::utils::orainst{'create doc oraInst':
            oraInventory    => $oraInventory,
            group           => $group,
   }

   $docTemplate =  "wls/silent_doc.xml.erb"

#   if ! defined(File["${path}/${title}silent_doc.xml"]) {
     file { "${path}/${title}silent_doc.xml":
       ensure  => present,
       content => template($docTemplate),
       require => Wls::Utils::Orainst ['create doc oraInst'],
     }
#   }

notify {"${path}/${title}silent_doc.xml location of silent install file, $jreLocDir JRE directory Location ":}

  # for performance reasons, download and install or just install it
  if $remoteFile == true {
     # doc file 1 installer zip
     if ! defined(File["${path}/${docFile1}"]) {
      file { "${path}/Documaker/${docFile1}":
       source  => "${mountPoint}/${docFile1}",
       require => File ["${path}/${title}silent_doc.xml"],
      }
     }
  }
   $command  = "-silent -response ${path}/${title}silent_doc.xml -waitforcompletion "

          # for performance reasons, download and install or just install it
      if $remoteFile == true {
         exec { "extract ${docFile1}":
          command => "unzip -o ${path}/Documaker/${docFile1} -d ${path}/doc",
          creates => "${path}/doc/ODEE12.3.00.23269linux64.zip",
          logoutput => true,
          require => [File ["${path}/${docFile1}"]],
         }
      } else {	
         exec { "extract ${docFile1}":
          command => "unzip -o ${puppetDownloadMntPoint}/Documaker/${docFile1} -d ${path}/doc",
          creates => "${path}/doc/ODEE12.3.00.23269linux64.zip",
          logoutput => true,
         }
      }
       exec { "extract ODEE12.3.00.23269linux64.zip":
          command => "unzip -o ${path}/doc/ODEE12.3.00.23269linux64.zip -d ${path}/doc",
          creates => "${path}/doc/ODEE12.3.00.23269linux64/Disk1",
          logoutput => false,
	  require => Exec["extract ${docFile1}"],
       }

      exec { "install doc ${title}":
          command     => "${path}/doc/Disk1/install/${docInstallDir}/runInstaller ${command} -invPtrLoc /etc/oraInst.loc -ignoreSysPrereqs -jreLoc ${jreLocDir}",
          require     => [File["${path}/${title}silent_doc.xml"],Exec["extract ${docFile1}"]],
          creates     => $docOracleHome,
          timeout     => 0,
      }
}
}
