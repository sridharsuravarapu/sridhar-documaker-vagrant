#Sridhar-documaker-vagrant

The reference implementation of https://github.com/biemond/biemond-orawls to build documaker in a Highly Available Clustered Documaker domain.
optimized for linux, Solaris and the use of Hiera

##Also support many native puppet WebLogic types like
- wls_machine
- wls_server
- wls_cluster
- and many others

##Details
- CentOS 6.5 vagrant box
- Puppet 3.5.0
- Vagrant >= 1.41
- Oracle Virtualbox >= 4.3.6
- WLS 10.3.6 PSU 8
- Documaker 12.3
- Soa 11g

creates a clustered 12.3 version of Documaker using 10.3.6 WebLogic cluster ( admin,node1,node2 )

site.pp is located here:
https://github.com/sridharsuravarapu/sridhar-documaker-vagrant/blob/master/puppet/manifests/site.pp

https://github.com/sridharsuravarapu/sridhar-documaker-vagrant/tree/master/puppet/hieradata

Add the all the Oracle binaries to /software

edit Vagrantfile and update the software share
- admin.vm.synced_folder "/Users/sridharsuravarapu/Software", "/software"
- node1.vm.synced_folder "/Users/sridharsuravarapu/Software", "/software"
- node2.vm.synced_folder "/Users/sridharsuravarapu/Software", "/software"


##used the following software ( located under the software share )
- jdk-7u60-linux-x64.tar.gz

weblogic 10.3.6  ( located under the software share )
- wls1036_generic.jar
- p18040640_1036_Generic.zip ( 10.3.6.0.8 BSU Patch)

Soa 11.1.1.6.0
- ofm_soa_generic_11.1.1.6.0_disk1_1of2.zip ( SOA Suite 11.1.1.6.0 )
- ofm_soa_generic_11.1.1.6.0_disk1_2of2.zip ( SOA Suite 11.1.1.6.0 )
- p16702086_111160_Generic.zip ( SOA Suite 11.1.1.6.0 OPatch )
- p16366204_111160_Generic.zip ( SOA Suite 11.1.1.6.0 OPatch )

Oracle Documaker Enterprise Edition v12.3.0 (32-bit) for Linux x86
- V44079-01.zip

##Using the following facts ( VagrantFile )

- environment => "development"
- vm_type     => "vagrant"

When to override the default oracle OS user or don't want to use the user_projects domain folder use the following facts
- override_weblogic_user          => "wls"

##Startup the images

###admin server
vagrant up admin

###node1
vagrant up node1

###node2
vagrant up node2


##javaexec_log branch

this javaexec_log branch logs all java executions.
see an example log at https://gist.github.com/dportabella/10372181

      $ git clone https://github.com/biemond/biemond-orawls-vagrant
      $ cd biemond-orawls-vagrant
      $ git checkout javaexec_log
      $ mkdir log_puppet_weblogic
      $ chmod a+rwx log_puppet_weblogic
      $ vagrant up admin
      $ cat log_puppet_weblogic/log.txt