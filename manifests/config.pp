# == Class: elasticsearch::config
#
# This class exists to coordinate all configuration related actions,
# functionality and logical units in a central place.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'elasticsearch::config': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
class btelasticsearch::config {

  #### Configuration

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  if ( $btelasticsearch::ensure == 'present' ) {

    file {
      $btelasticsearch::configdir:
        ensure => 'directory',
        group  => $btelasticsearch::btelasticsearch_group,
        owner  => $btelasticsearch::btelasticsearch_user,
        mode   => '0644';
      $btelasticsearch::datadir:
        ensure => 'directory',
        group  => $btelasticsearch::btelasticsearch_group,
        owner  => $btelasticsearch::btelasticsearch_user;
      $btelasticsearch::logdir:
        ensure  => 'directory',
        group   => undef,
        owner   => $btelasticsearch::btelasticsearch_user,
        mode    => '0644',
        recurse => true;
      $btelasticsearch::plugindir:
        ensure => 'directory',
        group  => $btelasticsearch::btelasticsearch_group,
        owner  => $btelasticsearch::btelasticsearch_user,
        mode   => 'o+Xr';
      "${btelasticsearch::homedir}/lib":
        ensure  => 'directory',
        group   => $btelasticsearch::btelasticsearch_group,
        owner   => $btelasticsearch::btelasticsearch_user,
        recurse => true;
      $btelasticsearch::params::homedir:
        ensure => 'directory',
        group  => $btelasticsearch::btelasticsearch_group,
        owner  => $btelasticsearch::btelasticsearch_user;
      "${btelasticsearch::params::homedir}/templates_import":
        ensure => 'directory',
        group  => $btelasticsearch::btelasticsearch_group,
        owner  => $btelasticsearch::btelasticsearch_user,
        mode   => '0644';
      "${btelasticsearch::params::homedir}/scripts":
        ensure => 'directory',
        group  => $btelasticsearch::btelasticsearch_group,
        owner  => $btelasticsearch::btelasticsearch_user,
        mode   => '0644';
      "${btelasticsearch::params::homedir}/shield":
        ensure => 'directory',
        mode   => '0644',
        group  => '0',
        owner  => 'root';
      '/etc/elasticsearch/elasticsearch.yml':
        ensure => 'absent';
      '/etc/elasticsearch/logging.yml':
        ensure => 'absent';
      '/etc/elasticsearch/log4j2.properties':
        ensure => 'absent';
      '/etc/init.d/elasticsearch':
        ensure => 'absent';
    }

    if $btelasticsearch::params::pid_dir {
      file { $btelasticsearch::params::pid_dir:
        ensure  => 'directory',
        group   => undef,
        owner   => $btelasticsearch::btelasticsearch_user,
        recurse => true,
      }

      if ($btelasticsearch::service_providers == 'systemd') {
        $group = $btelasticsearch::btelasticsearch_group
        $user = $btelasticsearch::btelasticsearch_user
        $pid_dir = $btelasticsearch::params::pid_dir

        file { '/usr/lib/tmpfiles.d/elasticsearch.conf':
          ensure  => 'file',
          content => template("${module_name}/usr/lib/tmpfiles.d/elasticsearch.conf.erb"),
          group   => '0',
          owner   => 'root',
        }
      }
    }

    if ($btelasticsearch::service_providers == 'systemd') {
      # Mask default unit (from package)
      exec { 'systemctl mask elasticsearch.service':
        unless => 'test `systemctl is-enabled elasticsearch.service` = masked',
      }
    }

    $new_init_defaults = { 'CONF_DIR' => $btelasticsearch::configdir }
    if $btelasticsearch::params::defaults_location {
      augeas { "${btelasticsearch::params::defaults_location}/elasticsearch":
        incl    => "${btelasticsearch::params::defaults_location}/elasticsearch",
        lens    => 'Shellvars.lns',
        changes => template("${module_name}/etc/sysconfig/defaults.erb"),
      }
    }

    # Other OS than Linux may not have that sysctl
    if $::kernel == 'Linux' {
      sysctl { 'vm.max_map_count':
        value => '262144',
      }
    }

  } elsif ( $btelasticsearch::ensure == 'absent' ) {

    file { $btelasticsearch::plugindir:
      ensure => 'absent',
      force  => true,
      backup => false,
    }

  }

}
