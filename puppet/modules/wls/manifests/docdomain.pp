define wls::docdomain($mdwHome         = undef,
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

	$docOracleHome   = "${mdwHome}/oracle_doc1"
	$logoutput = true
     	# check if the doc install was successfull
#     	$found1 = oracle_exists( $docOracleHome )
#     	if $found1 == undef {
#       		$continue1 = false
#     	} else {
#       		if ( $found1 ) {
#         		$continue1 = true
#       		} else {
#         	notify {"doc ${title} ${docOracleHome} does not exists":}
#         	$continue1 = false
#       		}
#     	}


# change set_middleware_env.sh and weblogic_installation.properties file to point to correct documaker home directory
#if ( $continue1 ) {
      file { "/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/set_middleware_env.sh":
       source  => "${puppetDownloadMntPoint}/Documaker/set_middleware_env.sh",
	owner	=> $user,
	group	=> $group,
#       require => Exec["install doc ${title}"],
	ensure => present,
      }

      file { "/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/weblogic_installation.properties":
       source  => "${puppetDownloadMntPoint}/Documaker/weblogic_installation.properties",
	owner	=> $user,
	group	=> $group,
	mode => 0777,
#       require => Exec["install doc ${title}"],
	ensure => present,
      }

    exec { "run wls_create_domain.sh script":
      command         => "wls_create_domain.sh",
      user            => $user,
      group           => $group,
      cwd	      => '/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/',
      path            => "/opt/oracle/middleware11g/wlserver_10.3/common/bin/:/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
      logoutput       => $logoutput,
      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain',
      require         => [File ["/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/weblogic_installation.properties"],File ["/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/set_middleware_env.sh"]],
    }

    exec { "run wls_add_correspondence.sh script":
      command         => "wls_add_correspondence.sh",
      user            => $user,
      group           => $group,
      cwd	      => '/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts',
      path            => "/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/:opt/oracle/middleware11g/wlserver_10.3/common/bin/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
      logoutput       => $logoutput,
#      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/',
      require         => Exec["run wls_create_domain.sh script"],
    }

    exec { "run startWebLogic.sh script":
      command         => "nohup startWebLogic.sh &",
      user            => $user,
      group           => $group,
      cwd	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/bin',
      path            => "/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/bin/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
      logoutput       => $logoutput,
      require         => Exec["run wls_add_correspondence.sh script"],
#      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/',
    }

   exec {"wait for wls retries":
   require => Exec["run startWebLogic.sh script"],
   command => "/usr/bin/wget --spider --tries 60 --retry-connrefused http://20.20.20.20:7001/console/",
  }
#             exec { "wait for wls":
#		require => Exec["wait for wls retries"],
#               command     => "/bin/sleep 60",
#               refreshonly => true,
#             }

    exec { "run create_users_groups.sh script":
      command         => "create_users_groups.sh",
      user            => $user,
      group           => $group,
      cwd	      => '/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts',
      path            => "/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
      logoutput       => $logoutput,
      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/',
#     require         => Exec["wait for wls"],
      require => Exec["wait for wls retries"],
   }


    exec { "run create_users_groups_correspondence_example.sh script":
      command         => "create_users_groups_correspondence_example.sh",
      user            => $user,
      group           => $group,
      cwd	      => '/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts',
      path            => "/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
      logoutput       => $logoutput,
      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/',
      require         => Exec["run create_users_groups.sh script"],
    }

    exec { "run startManagedWebLogic.sh jms_server script":
      command         => "nohup startManagedWebLogic.sh jms_server &",
      user            => $user,
      group           => $group,
      cwd	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/bin',
      path            => "/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/bin/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
      logoutput       => $logoutput,
      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain/',
      require         => Exec["run create_users_groups_correspondence_example.sh script"],
    }

#    exec { "run docserver.sh start script":
#      command         => "docserver.sh start",
#      user            => $user,
#      group           => $group,
#      cwd	      => '/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/',
#      path            => "/opt/oracle/middleware11g/wlserver_10.3/common/bin/:/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
#      logoutput       => $logoutput,
#      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain',
#      require         => Exec["run startManagedWebLogic.sh jms_server script"],
#    }

#    exec { "run docfactory.sh start script":
#      command         => "docfactory.sh start",
#      user            => $user,
#      group           => $group,
#      cwd	      => '/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/',
#      path            => "/opt/oracle/middleware11g/wlserver_10.3/common/bin/:/opt/oracle/middleware11g/oracle_doc1/documaker/j2ee/weblogic/oracle11g/scripts/:/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
#      logoutput       => $logoutput,
#      creates	      => '/opt/oracle/middleware11g/user_projects/domains/idocumaker_domain',
#      require         => Exec["run docserver.sh start script"],
#    }
#}
}