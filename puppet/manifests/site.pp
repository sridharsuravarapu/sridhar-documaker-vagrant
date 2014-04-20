# test
#
# one machine setup with weblogic 10.3.6 with BSU
# needs jdk7, orawls, orautils, fiddyspence-sysctl, erwbgy-limits puppet modules
#

node 'admin.example.com' {
  
  include os
  include ssh
  include java
  include orawls::weblogic, orautils
  include bsu
  include fmw
  include opatch
  include domains
  include nodemanager, startwls, userconfig
  include users
  # include groups
  # include machines
  # include managed_servers
  # include managed_servers_channels
  # include clusters
  # include file_persistence
  # include jms_servers
  # include jms_saf_agents
  # include jms_modules
  # include jms_module_subdeployments
  # include jms_module_quotas
  # include jms_module_cfs
  # include jms_module_queues_objects
  # include jms_module_topics_objects
  # include foreign_server_objects
  # include foreign_server_entries_objects
  # include saf_remote_context_objects
  # include saf_error_handlers
  # include saf_imported_destination
  # include saf_imported_destination_objects
  # include pack_domain

  Class[java] -> Class[orawls::weblogic]
}  

# operating settings for Middleware
class os {

  $default_params = {}
  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances, $default_params)

  exec { "create swap file":
    command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8192",
    creates => "/var/swap.1",
  }

  exec { "attach swap file":
    command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
    require => Exec["create swap file"],
    unless => "/sbin/swapon -s | grep /var/swap.1",
  }

  #add swap file entry to fstab
  exec {"add swapfile entry to fstab":
    command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
    require => Exec["attach swap file"],
    user => root,
    unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  }

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = oracle
  user { 'wls' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/wls",
    comment    => 'wls user created by Puppet',
    managehome => true,
    require    => Group['dba'],
  }

  $install = [ 'binutils.x86_64','unzip.x86_64']


  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'wls'     => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
               },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class ssh {
  require os


  file { "/home/wls/.ssh/":
    owner  => "wls",
    group  => "dba",
    mode   => "700",
    ensure => "directory",
    alias  => "wls-ssh-dir",
  }
  
  file { "/home/wls/.ssh/id_rsa.pub":
    ensure  => present,
    owner   => "wls",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["wls-ssh-dir"],
  }
  
  file { "/home/wls/.ssh/id_rsa":
    ensure  => present,
    owner   => "wls",
    group   => "dba",
    mode    => "600",
    source  => "/vagrant/ssh/id_rsa",
    require => File["wls-ssh-dir"],
  }
  
  file { "/home/wls/.ssh/authorized_keys":
    ensure  => present,
    owner   => "wls",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["wls-ssh-dir"],
  }        
}

class java {
  require os

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-openjdk.x86_64" ]

  package { $remove:
    ensure  => absent,
  }

  include jdk7

  # $javas = ["/usr/java/jdk1.7.0_51/jre/bin/java", "/usr/java/jdk1.7.0_51/bin/java"]
  # $LOG_DIR='/tmp/log_puppet_weblogic'

  jdk7::install7{ 'jdk1.7.0_51':
      version                   => "7u51" , 
      fullVersion               => "jdk1.7.0_51",
      alternativesPriority      => 18000, 
      x64                       => true,
      downloadDir               => "/var/tmp/install",
      urandomJavaFix            => true,
      rsakeySizeFix             => true,
      cryptographyExtensionFile => "UnlimitedJCEPolicyJDK7.zip",
      sourcePath                => "/software",
  }
  # ->
  # file { $LOG_DIR:
  #   ensure  => directory,
  #   mode    => '0777',
  # }
  # ->
  # file { "$LOG_DIR/log.txt":
  #   ensure  => file,
  #   mode    => '0666'
  # }
  # ->
  # javaexec_debug {$javas: }
  # ->
  # exec { 'java_debug start provisioning':
  #   command => "${javas[0]} -version '+++ start provisioning +++'"
  # }
}

# log all java executions:
define javaexec_debug() {
  exec { "patch java to log all executions on $title":
    command => "/bin/mv ${title} ${title}_ && /bin/cp /vagrant/puppet/files/java_debug ${title} && /bin/chmod +x ${title}", 
    unless  => "/usr/bin/test -f ${title}_",
  }
}


class bsu{
  require orawls::weblogic
  $default_params = {}
  $bsu_instances = hiera('bsu_instances', {})
  create_resources('orawls::bsu',$bsu_instances, $default_params)
}

class fmw{
  require bsu
  $default_params = {}
  $fmw_installations = hiera('fmw_installations', {})
  create_resources('orawls::fmw',$fmw_installations, $default_params)
}

class opatch{
  require fmw,bsu,orawls::weblogic
  $default_params = {}
  $opatch_instances = hiera('opatch_instances', {})
  create_resources('orawls::opatch',$opatch_instances, $default_params)
}

class domains{
  require orawls::weblogic, opatch

  $default_params = {}
  $domain_instances = hiera('domain_instances', {})
  create_resources('orawls::domain',$domain_instances, $default_params)

  $domain_address = hiera('domain_adminserver_address')
  $domain_port    = hiera('domain_adminserver_port')

  orautils::nodemanagerautostart{"autostart weblogic 11g":
    version     => hiera('wls_version'),
    wlHome      => hiera('wls_weblogic_home_dir'),
    user        => hiera('wls_os_user'),
    jsseEnabled => true,
  }

  wls_setting { 'default':
    user               => hiera('wls_os_user'),
    weblogic_home_dir  => hiera('wls_weblogic_home_dir'),
    connect_url        => "t3://${domain_address}:${domain_port}",
    weblogic_user      => hiera('wls_weblogic_user'),
    weblogic_password  => hiera('domain_wls_password'),
  }
  wls_setting { 'domain2':
    user               => hiera('wls_os_user'),
    weblogic_home_dir  => hiera('wls_weblogic_home_dir'),
    connect_url        => "t3://${domain_address}:7011",
    weblogic_user      => hiera('wls_weblogic_user'),
    weblogic_password  => hiera('domain_wls_password'),
  }


}

class nodemanager {
  require orawls::weblogic, domains

  $default_params = {}
  $nodemanager_instances = hiera('nodemanager_instances', {})
  create_resources('orawls::nodemanager',$nodemanager_instances, $default_params)
}

class startwls {
  require orawls::weblogic, domains,nodemanager

  $default_params = {}
  $control_instances = hiera('control_instances', {})
  create_resources('orawls::control',$control_instances, $default_params)
}

class userconfig{
  require orawls::weblogic, domains, nodemanager, startwls 
  $default_params = {}
  $userconfig_instances = hiera('userconfig_instances', {})
  create_resources('orawls::storeuserconfig',$userconfig_instances, $default_params)
} 

class users{
  require userconfig
  $default_params = {}
  $user_instances = hiera('user_instances', {})
  create_resources('wls_user',$user_instances, $default_params)
}

class groups{
  require users
  $default_params = {}
  $group_instances = hiera('group_instances', {})
  create_resources('wls_group',$group_instances, $default_params)
}

class machines{
  require groups
  $default_params = {}
  $machines_instances = hiera('machines_instances', {})
  create_resources('wls_machine',$machines_instances, $default_params)
}

define wlst_yaml_provider()
{
  $type            = $title
  $apps            = hiera('weblogic_apps')
  $apps_config_dir = hiera('apps_config_dir')

  $apps.each |$app| { 
    $allHieraEntriesYaml = loadyaml("${apps_config_dir}/${app}/${type}/${app}_${type}.yaml")
    if $allHieraEntriesYaml != undef {
      if $allHieraEntriesYaml["${type}_instances"] != undef {
          create_resources("wls_${type}",$allHieraEntriesYaml["${type}_instances"])
      }  
    }
  }  
}

class managed_servers{
  require machines
  wlst_yaml_provider{'server':} 
}

class managed_servers_channels{
  require managed_servers
  wlst_yaml_provider{'server_channel':} 
}

class datasources{
  require managed_servers_channels
  wlst_yaml_provider{'datasource':} 
}

class clusters{
  require datasources
  wlst_yaml_provider{'cluster':} 
}

class file_persistence{
  require datasources

  $default_params = {}
  $file_persistence_folders = hiera('file_persistence_folders', {})
  create_resources('file',$file_persistence_folders, $default_params)

  wlst_yaml_provider{'file_persistence_store':} 
}

class jms_servers{
  require file_persistence
  wlst_yaml_provider{'jmsserver':} 
}

class jms_saf_agents{
  require jms_servers
  wlst_yaml_provider{'safagent':} 
}

class jms_modules{
  require jms_saf_agents
  wlst_yaml_provider{'jms_module':} 
}

class jms_module_subdeployments{
  require jms_modules
  wlst_yaml_provider{'jms_subdeployment':} 
}

class jms_module_quotas{
  require jms_module_subdeployments
  wlst_yaml_provider{'jms_quota':} 
}

class jms_module_cfs{
  require jms_module_quotas
  wlst_yaml_provider{'jms_connection_factory':} 
}

class jms_module_queues_objects{
  require jms_module_cfs
  wlst_yaml_provider{'jms_queue':} 
}

class jms_module_topics_objects{
  require jms_module_queues_objects
  wlst_yaml_provider{'jms_topic':} 
}

class saf_remote_context_objects {
  require jms_module_topics_objects
  wlst_yaml_provider{'saf_remote_context':} 
}

class saf_error_handlers {
  require saf_remote_context_objects
  wlst_yaml_provider{'saf_error_handler':} 
}

class saf_imported_destination {
  require saf_error_handlers
  wlst_yaml_provider{'saf_imported_destination':} 
}

class saf_imported_destination_objects {
  require saf_imported_destination
  wlst_yaml_provider{'saf_imported_destination_object':} 
}

class foreign_server_objects{
  require saf_imported_destination_objects
  wlst_yaml_provider{'foreign_server':} 
}

class foreign_server_entries_objects{
  require foreign_server_objects
  wlst_yaml_provider{'foreign_server_object':} 
}

class pack_domain{
  require foreign_server_entries_objects
  $default_params = {}
  $pack_domain_instances = hiera('pack_domain_instances', $default_params)
  create_resources('orawls::packdomain',$pack_domain_instances, $default_params)
}


