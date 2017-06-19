# == Class: elasticsearch::repo
#
# This class exists to install and manage yum and apt repositories
# that contain elasticsearch official elasticsearch packages
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
#   class { 'elasticsearch::repo': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Phil Fenstermacher <mailto:phillip.fenstermacher@gmail.com>
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
class btelasticsearch::repo {

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  if $btelasticsearch::ensure == 'present' {
    if versioncmp($btelasticsearch::repo_version, '5.0') >= 0 {
      $_repo_url = 'https://artifacts.elastic.co/packages'
      case $::osfamily {
        'Debian': {
          $_repo_path = 'apt'
        }
        default: {
          $_repo_path = 'yum'
        }
      }
    } else {
      $_repo_url = 'http://packages.elastic.co/elasticsearch'
      case $::osfamily {
        'Debian': {
          $_repo_path = 'debian'
        }
        default: {
          $_repo_path = 'centos'
        }
      }
    }

    $_baseurl = "${_repo_url}/${btelasticsearch::repo_version}/${_repo_path}"
  } else {
    case $::osfamily {
      'Debian': {
        $_baseurl = undef
      }
      default: {
        $_baseurl = 'absent'
      }
    }
  }

  case $::osfamily {
    'Debian': {
      include ::apt
      Class['apt::update'] -> Package[$btelasticsearch::package_name]

      apt::source { 'elasticsearch':
        ensure   => $btelasticsearch::ensure,
        location => $_baseurl,
        release  => 'stable',
        repos    => 'main',
        key      => {
          'id'     => $::btelasticsearch::repo_key_id,
          'source' => $::btelasticsearch::repo_key_source,
        },
        include  => {
          'src' => false,
          'deb' => true,
        },
        pin      => $btelasticsearch::repo_priority,
      }
    }
    'RedHat', 'Linux': {
      # Versions prior to 3.5.1 have issues with this param
      # See: https://tickets.puppetlabs.com/browse/PUP-2163
      if versioncmp($::puppetversion, '3.5.1') >= 0 {
        Yumrepo['elasticsearch'] {
          ensure => $btelasticsearch::ensure,
        }
      }
      yumrepo { 'elasticsearch':
        descr    => 'elasticsearch repo',
        baseurl  => $_baseurl,
        gpgcheck => 1,
        gpgkey   => $::btelasticsearch::repo_key_source,
        enabled  => 1,
        proxy    => $::btelasticsearch::repo_proxy,
        priority => $btelasticsearch::repo_priority,
      } ~>
      exec { 'elasticsearch_yumrepo_yum_clean':
        command     => 'yum clean metadata expire-cache --disablerepo="*" --enablerepo="elasticsearch"',
        refreshonly => true,
        returns     => [0, 1],
      }
    }
    'Suse': {
      if $::operatingsystem == 'SLES' and versioncmp($::operatingsystemmajrelease, '11') <= 0 {
        # Older versions of SLES do not ship with rpmkeys
        $_import_cmd = "rpm --import ${::btelasticsearch::repo_key_source}"
      } else {
        $_import_cmd = "rpmkeys --import ${::btelasticsearch::repo_key_source}"
      }

      exec { 'elasticsearch_suse_import_gpg':
        command => $_import_cmd,
        unless  =>
          "test $(rpm -qa gpg-pubkey | grep -i 'D88E42B4' | wc -l) -eq 1",
        notify  => Zypprepo['elasticsearch'],
      }

      zypprepo { 'elasticsearch':
        baseurl     => $_baseurl,
        enabled     => 1,
        autorefresh => 1,
        name        => 'elasticsearch',
        gpgcheck    => 1,
        gpgkey      => $::btelasticsearch::repo_key_source,
        type        => 'yum',
      } ~>
      exec { 'elasticsearch_zypper_refresh_elasticsearch':
        command     => 'zypper refresh elasticsearch',
        refreshonly => true,
      }
    }
    default: {
      fail("\"${module_name}\" provides no repository information for OSfamily \"${::osfamily}\"")
    }
  }

}
