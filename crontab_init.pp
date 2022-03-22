# /etc/puppet/modules/cronjob/manifests/init.pp
#
# installs cronjob with specified title (set command in params.pp)
# pass hour or minute through as variables
#
define cronjob (
  $job = $title,
  $run_command = undefined,
  $ensure = present,
  $cronjob_minute = undef,
  $cronjob_hour = undef
)
{
  case $job {
    puppet: {
      $cronjob_command = "nice -n 15 puppet agent --onetime --no-daemonize --logdest syslog > /dev/null 2>&1"
      $use_hour = '*'
    }
    carbonate: {
      $cronjob_command = "/usr/bin/sv once carbonate"
    }
    default: {
      if $run_command == 'undefined' {
        fail("Unsupported cronjob title: ${cronjob::job}")
      }
      else {
        $cronjob_command = $run_command
      }
    }
  }
  if !(defined('$use_hour')) {
    $use_hour = $cronjob_hour
  }
  if !(defined('$use_minute')) {
    $use_minute = fqdn_rand(60, $job)
  }
  if !(defined('$use_ensure')) {
    $use_ensure = $ensure
  }
  cron { $job:
    ensure      => $use_ensure,
    environment => 'PATH=/usr/bin:/usr/local/sbin',
    command     => $cronjob_command,
    user        => 'root',
    minute      => $use_minute,
    hour        => $use_hour,
  }
}
