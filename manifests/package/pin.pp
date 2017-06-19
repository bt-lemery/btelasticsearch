# == Class: elasticsearch::package::pin
#
# Controls package pinning for the Elasticsearch package.
#
# === Parameters
#
# This class does not provide any parameters.
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'elasticsearch::package::pin': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
# === Authors
#
# * Tyler Langlois <mailto:tyler@elastic.co>
#
class btelasticsearch::package::pin {

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  case $::osfamily {
    'Debian': {
      include ::apt

      if ($btelasticsearch::ensure == 'absent') {
        apt::pin { $btelasticsearch::package_name:
          ensure => $btelasticsearch::ensure,
        }
      } elsif ($btelasticsearch::version != false) {
        apt::pin { $btelasticsearch::package_name:
          ensure   => $btelasticsearch::ensure,
          packages => $btelasticsearch::package_name,
          version  => $btelasticsearch::version,
          priority => 1000,
        }
      }

    }
    'RedHat', 'Linux': {

      if ($btelasticsearch::ensure == 'absent') {
        $_versionlock = '/etc/yum/pluginconf.d/versionlock.list'
        $_lock_line = '0:elasticsearch-'
        exec { 'elasticsearch_purge_versionlock.list':
          command => "sed -i '/${_lock_line}/d' ${_versionlock}",
          onlyif  => [
            "test -f ${_versionlock}",
            "grep -F '${_lock_line}' ${_versionlock}",
          ],
        }
      } elsif ($btelasticsearch::version != false) {
        yum::versionlock {
          "0:elasticsearch-${btelasticsearch::pkg_version}.noarch":
            ensure => $btelasticsearch::ensure,
        }
      }

    }
    default: {
      warning("Unable to pin package for OSfamily \"${::osfamily}\".")
    }
  }
}
