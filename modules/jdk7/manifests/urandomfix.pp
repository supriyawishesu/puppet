# jdk7::urandomfix
#
# On Linux low entropy can cause certain operations to be very slow.
# Encryption operations need entropy to ensure randomness. Entropy is
# generated by the OS when you use the keyboard, the mouse or the disk.
#
# If an encryption operation is missing entropy it will wait until
# enough is generated.
#
# three options
#  use rngd service (this class)
#  set java.security in JDK ( jre/lib/security )
#  set -Djava.security.egd=file:/dev/./urandom param
#
class jdk7::urandomfix () {

  case $::kernel {
    Linux   : { $path = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:' }
    default : { fail("Unrecognized operating system") }
  }

  # set the Exec defaults
  Exec {
    path      => $path,
    logoutput => true,
    user      => 'root',
  }

  package { "rng-tools": ensure => present, }

  case $osfamily {
    RedHat       : {
      exec { "set urandom /etc/sysconfig/rngd":
        command => "sed -i -e's/EXTRAOPTIONS=\"\"/EXTRAOPTIONS=\"-r \\/dev\\/urandom -o \\/dev\\/random -b\"/g' /etc/sysconfig/rngd",
        unless  => "/bin/grep '^EXTRAOPTIONS=\"-r /dev/urandom -o /dev/random -b\"' /etc/sysconfig/rngd",
        require => Package["rng-tools"],
      }

      service { "start rngd service":
        name    => "rngd",
        enable  => true,
        ensure  => true,
        require => Exec["set urandom /etc/sysconfig/rngd"],
      }

      exec { "chkconfig rngd":
        command => "chkconfig --add rngd",
        require => Service["start rngd service"],
        unless  => "chkconfig | /bin/grep 'rngd'",
      }

    }
    Debian, Suse : {
      exec { "set urandom /etc/default/rng-tools":
        command => "sed -i -e's/#HRNGDEVICE=\\/dev\\/null/HRNGDEVICE=\\/dev\\/urandom/g' /etc/default/rng-tools",
        unless  => "/bin/grep '^HRNGDEVICE=/dev/urandom' /etc/default/rng-tools",
        require => Package["rng-tools"],
      }

      service { "start rng-tools service":
        name    => "rng-tools",
        enable  => true,
        ensure  => true,
        require => Exec["set urandom /etc/default/rng-tools"],
      }
    }
  }
}
