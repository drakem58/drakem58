#!/usr/local/bin/perl

use vars qw($debug);
###################################################################
#
# Configuration File. All modified variables will be in this file
#
##################################################################
do "/bkup/hbu/hbu.conf";

####################################################################
# Oracle HotBackup/EMC BCV/Veritas Netbackup Script (hbu)
####################################################################

# This script can only be executed by root.
die "$0 must be run as root!" unless $> == 0;

umask 022;

$|=1; # flush output buffer after every print()

#use strict;
####################################################################
# Configuration
####################################################################

# System
# definitely needs to be changed/reviewed for new systems


use POSIX qw(strftime);
use File::Copy;
use File::Compare;
use Fcntl qw(:flock);
use Getopt::Std;

use vars qw( $opt_h $opt_m );

my $errors = 0;
my $original_arch_format = $arch_format;

####################################################################
# prototypes - needed before any subs are defined
####################################################################
sub main();
sub appcmd($);
sub apponly_backup();
sub full_backup();
sub arch_backup();
sub bcv_establish();
sub bcv_split();
sub check_remote();
sub trigger_remote();
sub copy_logs($$;$);
sub clean_dir($);
sub get_oldest_log();
sub get_current_log();
sub symcli($;$);
sub get_tblspaces();
sub sqlplus($);
sub bpcmd($);
sub date();
sub lock($);
sub unlock($);
sub usage();
sub trace($);

main;

sub main()
   {

   my %mode = ( full => "+<", arch => "+<", apponly => "+<" );

   foreach ( keys %locks ) { $mode{$_} = "+>" unless -w $locks{$_} };
   open(LCK_FULL,$mode{full}.$locks{full}) or die "Can't open lockfile: $!";
   open(LCK_ARCH,$mode{arch}.$locks{arch}) or die "Can't open lockfile: $!";
   open(LCK_APPONLY,$mode{apponly}.$locks{apponly}) or die "Can't open lockfile: $!";

   getopts('hm:');
   
   if ( $opt_h ) { usage; }
   elsif ( $opt_m eq 'full' ) { full_backup; }
   elsif ( $opt_m eq 'arch' ) { arch_backup; }
   elsif ( $opt_m eq 'apponly' ) { apponly_backup; }
   elsif ( $opt_m ) { print("$0: illegal mode -- ".$opt_m."\n"); usage;}
   else {print("$0: illegal syntax\n"); usage; }

   close(LCK_FULL);
   close(LCK_ARCH);
   close(LCK_APPONLY);
 
   }

sub apponly_backup()
   {

   # check for bcv_lockfile - abort if found
   lock('apponly');

   check_remote;

   bcv_establish;
   
   # Stops and Verify App before Splitting the BCV
   appcmd(qq{ $AppStopScript }) if $AppStopScript ne '';
   #appcmd(qq{ $AppVerifyStopScript });

   eval { bcv_split; };
   my $split_rc = $@;

   # Starts and Verifies App After Splitting the BCV
   appcmd(qq{ $AppStartScript }) if $AppStopScript ne '';
   #appcmd(qq{ $AppVerifyStartScript });

   trigger_remote unless $split_rc;

   unlock('apponly');
   trace "unlocked lock files";
   return 1;
   }

sub full_backup()
{
    
    # check for bcv_lockfile - abort if found
    lock('full');
    
    check_remote;
    
    bcv_establish;
    
    my %logseq = ();
    $str_previous_sid = '';
    
    {
        $ENV{ORACLE_SID} = $sid;
        trace("Oracle Sid = $sid");                 
        my $dest = "$bkup_dir/$sid/archive_dest/hbu";
        trace ("Backup Archive Log Destination: $dest");
        trace(" switching logfile for $sid");         
        #sqlplus("alter system archive log current;");  
        trace ("Backup Archive Log Destination: $dest");
        clean_dir($dest) if $clean_dir eq 1;        
        $logseq{$sid} = get_current_log;
        trace "current/active archive log = $logseq{$sid}";
        if ( $ORACLE_RAC =~ m/enabled/ ){
            trace "INSIDE ORACLE_RAC: previous sid : $str_previous_sid current sid: $sid";
            if ( $str_previous_sid eq '' ) {
                trace "INSIDE IF COMP: previous sid : $str_previous_sid current sid: $sid";
                sqlplus("alter system archive log current;"); 
                sqlplus("alter database backup controlfile to '$dest/control.$datestamp';"); 
                foreach my $tblspc (get_tblspaces)
                { sqlplus("alter tablespace $tblspc begin backup;"); }
            }
        }else{
            trace "INSIDE RAC ELSE: previous sid : $str_previous_sid current sid: $sid";
            foreach my $tblspc (get_tblspaces)
            { sqlplus("alter tablespace $tblspc begin backup;"); } 
        }
        $str_previous_sid = $sid;
        trace "previous sid : $str_previous_sid current sid: $sid";
    }
    # Stops and Verify App before Splitting the BCV
    if ($DB_and_APP_Backup =~ m/enabled/i){
        appcmd(qq{ $AppStopScript }) if $AppStopScript ne '';
        #appcmd(qq{ $AppVerifyStopScript });
    }
    
    eval { bcv_split; };
    my $split_rc = $@;
    
    # Starts and Verifies App After Splitting the BCV
    if ($DB_and_APP_Backup =~ m/enabled/i){
        appcmd(qq{ $AppStartScript }) if $AppStartScript ne '';
        #appcmd(qq{ $AppVerifyStartScript });
    }
    
    $str_previous_sid = '';
    foreach my $sid (@ora_sid)
    {
        $ENV{ORACLE_SID} = $sid;
        # Add check for RAC with 2nd oracle instance
        # Add If for second SID, If 2nd SID then skip alter tablespace begin backup
        
        if ( $ORACLE_RAC =~ m/enabled/ ){
            if ( $str_previous_sid eq '' ) {
                foreach my $tblspc (get_tblspaces)
                    { sqlplus("alter tablespace $tblspc end backup;"); }
                sqlplus("alter system archive log current;"); 
            }
        }else{
            foreach my $tblspc (get_tblspaces)
                { sqlplus("alter tablespace $tblspc end backup;"); }
                sqlplus("alter system archive log current;"); 
        }
        $str_previous_sid = $sid;
        trace "previous sid : $str_previous_sid current sid: $sid";
        # END If for second SID, If 2nd SID then skip alter tablespace end backup
        trace("calling copy_logs with sid,$logseq{$sid}");
        copy_logs($sid,$logseq{$sid});
        trace ("returned from copy_logs");
        #trace("END BACKUP: switching logfile for $sid");
        #sqlplus("alter system switch logfile current;");  
    }
    
    
    trigger_remote unless $split_rc;
    bpcmd(qq{bpbackup -w -p $bp_policy -s $bp_sched -h $bp_client -S $bp_master -L $hbu_log $bkup_dir/*/archive_dest});
    
    #trigger_remote unless $split_rc;
    
    unlock('full');
    trace "unlocked lock files";
    return 1;
}   # END OF full_backup()

  
sub arch_backup() {
    lock('arch');
    
   
        trace("hbu.conf arch_dst = $arch_dst"); 
        trace("hbu.conf arch_src = $arch_src"); 
        trace("hbu.conf arch_dup = $arch_dup");
        $arch_dst_conf = 'ND' if $arch_dst eq '';
        $arch_src_conf = 'ND' if $arch_src eq '';
        $arch_dup_conf = 'ND' if $arch_dup eq '';
        trace("arch_dst_conf -->$arch_dst_conf<--");
        trace("arch_src_conf -->$arch_src_conf<--");
        trace("arch_dup_conf -->$arch_dup_conf<--");
        #sqlplus("alter system archive log current;");  
    
   foreach my $sid ( @ora_sid ) {
        trace ("arch_backup : $sid ");
        #trace("hbu.conf arch_dst = $arch_dst"); 
        #trace("hbu.conf arch_src = $arch_src");
        #trace("hbu.conf arch_dup = $arch_dup"); 
        $arch_dst = "$bkup_dir/$sid/arch/hbu" if $arch_dst_conf eq 'ND';
        $arch_src = "$ora_logs/$sid/arch" if $arch_src_conf eq 'ND';
        $arch_dup = "$bkup_dir/$sid/arch" if $arch_dup_conf eq 'ND';
        trace("arch_dst = $arch_dst"); 
        trace("arch_src = $arch_src"); 
        trace("arch_dup = $arch_dup"); 
        $ENV{ORACLE_SID} = $sid;
        sqlplus("alter system archive log current;") if $sid eq $ora_sid[0];  
        my $oldest_online = get_oldest_log;
        trace("sid:$sid");
        trace("oldest_online:$oldest_online");
        trace("passing the following to copy_logs function: $sid,0,$oldest_online-1");
        trace("calling sub function copy_logs" );
        my @logs = copy_logs($sid,0,$oldest_online-5);
        # only run backups if there are files to backup
        # and only delete the old logs if they were backed up successfully
        if(@logs) {
            my $listfile = "/tmp/hbu.list.$$";
            open LISTFILE, ">$listfile" or die "couldn't create $listfile: $?";
            trace("TEST: $arch_dst/$_");
            print LISTFILE map { "$arch_dst/$_\n" } @logs
            or die "couldn't write to $listfile: $?";
            close LISTFILE;
                $rac_hbu_log = '';
                $rac_hbu_log = $hbu_log  . "_" . $sid ;
            if ( bpcmd( qq{bpbackup -w -p $bp_policy -s $bp_sched -h $bp_client -S $bp_master -L $rac_hbu_log -f $listfile} )
            and !($debug & 16) ) {
                foreach my $file (@logs) {
                    trace("deleting $arch_src/$file"); unlink("$arch_src/$file");
                    trace("deleting $arch_dst/$file"); unlink("$arch_dst/$file");
                    trace("deleting $arch_dup/$file"); unlink("$arch_dup/$file");
                }
            }
            unlink $listfile;
        }
    }
    unlock('arch');
    return 1;
}
 
sub bcv_establish()
   {
   foreach $sym_dg(@array_sym_dg){
        return if symcli("symmir -g $sym_dg verify -synched");
        symcli("symmir -g $sym_dg verify -split")
                or die "BCVs not split; can't re-establish";
        #symcli("symmir -g $sym_dg establish -noprompt");
        my $symapi_lock_count = 0;
        # code 2 -> CLI_C_DB_FILE_IS_LOCKED
        #while (symcli("symmir -g $sym_dg establish -noprompt",2) && $symapi_lock_count < 10 ) {
        while (symcli("symmir -g $sym_dg establish -noprompt",2) ){
            if ($symapi_lock_count < 10 ) {
                trace("SYMAPI DB Locked, Will Retry every minute for 10 minutes");
                trace("Sleeping 60 seconds... then retry BCV Est ");
                sleep 10;
                $symapi_lock_count++;
                trace("symapi_lock_count-->$symapi_lock_count");
           }
        }
        # code 27 -> CLI_C_NOT_ALL_SYNCINPROG
        while ( symcli("symmir -g $sym_dg verify -syncinprog",27) ) { sleep 60; }
        symcli("symmir -g $sym_dg verify -synched")
                or die "BCV re-establish failed";
        sleep 60;
        }
   }

sub bcv_split()
   {
   foreach $sym_dg(@array_sym_dg){
        symcli("symmir -g $sym_dg verify -synched")
                or die "BCVs not synched; can't initiate split";
        symcli("symmir -g $sym_dg -instant split -noprompt");
        symcli("symmir -g $sym_dg verify -split")
                or die "BCV split failed";
   }
   }



sub check_remote()
   {
        trace("trigger_remote <  $sshcmd $nbuuser\@$nbuhost $sudocmd /sbin/vxdg list  >") ;
        my @vxdg_list =`$sshcmd $nbuuser\@$nbuhost "$sudocmd /sbin/vxdg list" `;
        foreach my $str_vxdg_list (@vxdg_list){
                if ( $str_vxdg_list =~ m/$vxdgname/i ){
                        trace (" ERROR: Veritas Volume Group already imported on $nbuhost, exiting " );
                        die "ERROR: Veritas Volume Group already imported on $nbuhost, exiting ";
                }else{
                        next;
                }
        }
   }

sub trigger_remote()
   {
   trace("trigger_remote <  $sshcmd $nbuuser\@$nbuhost $sudocmd /appl/backup-scripts/$complex_name/$complex_name-bcv-backup-wrapper >") ;
   do
      {
      my @out = qx{ $sshcmd $nbuuser\@$nbuhost $sudocmd /appl/backup-scripts/$complex_name/$complex_name-bcv-backup-wrapper 2>&1 };
      my $rc = $?/256;
      if ($rc) { $errors++;print(@out,"\nrc=$rc\n") }
      return ($rc == 0);
      }
   unless ($debug & 32);

   }

sub copy_logs($$;$)
{
    my ($sid,$start_seq,$end_seq) = (shift,shift,shift);
    #trace("arch_format=$arch_format");
    #$arch_format = $sid if $arch_format eq '';  # commented out  by Ken G 10/19
    # Original Code
    #    $arch_format = $sid if $arch_format eq '' and $ORACLE_RAC !~ m/enabled/i;  # NewLine added for Oracle RAC implementation
    #   #$arch_format = $sid;  # added by Ken G 10/19
    #    trace("arch_format=$arch_format");
    trace("$sid,$start_seq,$end_seq inside copy_logs");
    trace("Oracle SID-->$sid");
    trace("Original Arch Format-->$arch_format");
    # NEW CODE SECTION
    trace("ORACLE_RAC-->$ORACLE_RAC");
    #if ( ($ORACLE_RAC =~ m/enabled/i) && ($arch_format ne '' ) ){
    if ( ($ORACLE_RAC =~ m/enabled/i) && ( $arch_format eq 'arch_' )){
        #arch_2_515_602173182.log
        #$archlog_fmt = '%s_%d_%d.log';                # for generating filenames from seq no.s
        #$archlog_pat = '_(\d+)_(\d+)\.log$';             # for extracting seq no.s from filenames
        #$arch_format = 'arch_';                # Log Format Parameter. Leave blank if format is $sid_####.arc
        $arch_format = 'arch_' . substr($sid,(length $sid) - 1,1);
        trace("Oracle Rac arch_format-->$arch_format");
    }elsif ( ($ORACLE_RAC =~ m/enabled/i) && ( $arch_format eq '' ) ) {
        $arch_format = $sid;
        trace("arch_format=$arch_format");
    }else{
        #$arch_format = $sid if $arch_format eq '' and $ORACLE_RAC !~ m/enabled/i;  # NewLine added for Oracle RAC implementation
        $arch_format = $sid if $arch_format eq '';
        #$arch_format = $sid;  # added by Ken G 10/19
        trace("arch_format=$arch_format");
        trace("$sid,$start_seq,$end_seq inside copy_logs");
        trace("$sid");
        trace("$arch_format");
    }
        # END OF NEW CODE SECTION
    my $first_log = sprintf($archlog_fmt,$arch_format,$start_seq);
    my $last_log = $end_seq ? sprintf($archlog_fmt,$arch_format,$end_seq) : chr(255);

        my $arch_dst_conf = 'ND' if $arch_dst eq '';
        my $arch_src_conf = 'ND' if $arch_src eq '';
        my $arch_dup_conf = 'ND' if $arch_dup eq '';

    trace("hbu.conf arch_src = $arch_src");
    trace("hbu.conf arch_dst = $arch_dst");
    trace("hbu.conf arch_dup = $arch_dup");
    $arch_src = "$ora_logs/$sid/arch" if $arch_src_conf eq 'ND';
    $arch_dst = "$bkup_dir/$sid/arch/hbu"  if $arch_dst_conf eq 'ND';
    $arch_dup = "$bkup_dir/$sid/arch" if $arch_dup_conf eq 'ND';
    trace("arch_src = $arch_src");
    trace("arch_dst = $arch_dst");
    trace("arch_dup = $arch_dup");
    opendir(LOGDIR,$arch_src);
    trace("$first_log");
    trace("$last_log");
    trace("$arch_format$archlog_pat");
    my @logs = sort grep { /$arch_format$archlog_pat/
        and $_ ge $first_log
        and $_ le $last_log } readdir(LOGDIR);
    trace (" @logs ");
    closedir(LOGDIR);
    trace join(', ',@logs);
    unless ($debug & 32)
    {
        for ( @logs )
        {
            #trace("copying $_ to $arch_dst");
            trace("linking $arch_dup/$_ to $arch_dst/$_");
            if ( -f "$arch_dst/$_" )
                { next if compare("$arch_src/$_","$arch_dst/$_",64*1024) == 0; }
            # On systems  with arch duplexing, we link from archduplex/sid/arch to
            # archduplex/sid/hbu to save space/time
            
                if($duplex_state =~m/disabled/i){
                    trace("copying $arch_src/$_ to $arch_dst/$_");
                    #copy("$arch_src/$_","$arch_dst/$_") or die "couldn't copy file: $?";
                    link("$arch_src/$_","$arch_dst/$_") or die "couldn't copy file: $?";
                }else{
                    trace("linking $arch_dup/$_ to $arch_dst/$_");
                    link("$arch_dup/$_","$arch_dst/$_") or die "couldn't link file: $?";
                }
        }
        trace("comparing Original Arch Format with Current");
        trace("Original-->$original_arch_format");
        trace("Current-->$arch_format");
        if ( $original_arch_format ne $arch_format ){
            $arch_format = $original_arch_format;
            trace("Resetting arch_format--> $arch_format");
        }
        return @logs;
    }
}  # end of copy_logs

sub clean_dir($)
   {
   my $dir = shift;
   chomp $dir;
   die "$dir exists and is not a directory" if ( -e $dir and ! -d $dir );
   trace("clean_dir < $dir >");
   return if ($debug & 16);
   unless ( -d $dir )
      {
      system("mkdir -p $dir");
      chown($ora_nuid, $ora_ngid, $dir);
      }
   opendir(DIR,$dir) or die "can't open directory $dir";
   my @files = grep { ! /^(\.|\.\.)$/ } readdir(DIR);
   closedir(DIR);
   foreach (@files) { unlink "$dir/$_" };
   }

sub get_oldest_log()
   {
        my @res = grep /^#,/,
#        sqlplus(q{select '#,'||ltrim(min(a.sequence#)) from v$log a, v$instance b where a.status='INACTIVE' AND a.thread#=b.thread#;});
        sqlplus(q{select '#,'||ltrim(min(a.sequence#)) from v$log a, v$instance b where a.ARCHIVED='YES' AND a.thread#=b.thread#;});
        return (split /,/, $res[0])[1]
   }

sub get_current_log()
   {
        my @res = grep /^#,/,
        sqlplus(q{select '#,'||ltrim(min(a.sequence#)) from v$log a, v$instance b where a.status='CURRENT' AND a.thread#=b.thread#;});
}

sub get_tblspaces()
   {
        my @rows = grep /^#,/,
        sqlplus(q{select '#,'||RTRIM(tablespace_name)||',' from sys.dba_tablespaces where status='ONLINE'
        minus 
        select '#,'||RTRIM(tablespace_name)||',' from sys.dba_temp_files;});
        return map { (split(/,/))[1] } @rows;
   }

sub sqlplus($)
   {
        my $sql = shift;
        chomp $sql;
        trace ("connect $ora_con\@$ENV{ORACLE_SID}");
        #trace ("connect $ora_con\@$sid");
        trace "sqlplus < $sql >";
       do
        {
            my @out = grep { ! /^Connected\.$/ } qx{
            $ora_home/bin/sqlplus -s /nolog 2>&1 <<'EOF'
            set termout off
            set echo off
            set feedback off
            set pagesize 0
            set linesize 1024
            connect $ora_con\@$ENV{ORACLE_SID}
            set termout on
            $sql
            EOF
        };

      my $rc = $?/256;
      $rc ||= grep /^ORA-\d+:/,@out;
      if ($rc) { $errors++;print(@out,"\nrc=$rc\n") }
      foreach ( @out ) { chomp; s/\s+$//; };
      return @out;
      }
   unless ($debug & 1);
   }

sub symcli($;$)
   {
   local $ENV{SYMAPI_WAIT_FOR_BCV_BG_SPLIT} = 'TRUE';
   my $cmd = shift;
   my $alt_rc = shift || 0;
   trace "symcli < $sshcmd $symuser\@$symhost  $sudocmd $symcli/$cmd >";
   do
      {
      my @out = qx{ $sshcmd $symuser\@$symhost  $sudocmd $symcli/$cmd 2>&1 };
      my $rc = $?/256;
      if ($rc and $rc != $alt_rc) { $errors++;print(@out,"\nrc=$rc\n") }
      return ($rc == 0 or $rc == $alt_rc);
      }
   unless ($debug & 4);
   }

sub bpcmd($)
   {
   my $bpcmd = shift;
   chomp $bpcmd;

   opendir(DIR, $bp_bin) or die "Can't open $bp_bin: $!";

   trace "exec < $bp_bin/$bpcmd >";
   do
      {
      my @out = qx{ $bp_bin/$bpcmd 2>&1 };
      my $rc = int($?/256);
      if ($rc) { $errors++;print(@out,"rc=$rc\n") };
      return (!$rc);
      }
   unless ($debug & 8);
   }

sub appcmd($)
   {
   my $appcmd = shift;
   chomp $appcmd;
   trace "exec < $appcmd >";
   do
      {
      my @out = qx{ $appcmd 2>&1 };
      my $rc = int($?/256);
      if ($rc) { $errors++;print(@out,"rc=$rc\n") };
      return (!$rc);
      }
   unless ($debug & 8);
   }

sub date()
   {
   print ">>>".localtime(time)."\n";
   }

sub lock($)
   {
   my $mode = shift;
   my $rc;
   die "Not a valid lock type: $mode" unless exists $locks{$mode};
   if ( $mode eq 'full' )
      {
      trace "flock full EX,NB";
      flock(LCK_FULL,LOCK_EX|LOCK_NB) or
         die "ERROR: hbu -m full already runnning (flock: $!)";
      }
   elsif ( $mode eq 'arch' )
      {
      trace "flock arch EX,NB";
      flock(LCK_ARCH,LOCK_EX|LOCK_NB) or
         die "ERROR: hbu -m arch already running (flock: $!)";
      # wait for full to finish
      trace "flock full EX";
      flock(LCK_FULL,LOCK_EX) or
         die "ERROR: hbu -m arch can't get full mode lock (flock: $!)";
      trace "flock full UN";
      flock(LCK_FULL,LOCK_UN);
      }
   elsif ( $mode eq 'apponly' )
      {
      trace "flock apponly EX,NB";
      flock(LCK_APPONLY,LOCK_EX|LOCK_NB) or
         die "ERROR: hbu -m arch already running (flock: $!)";
      # wait for full to finish
      trace "flock apponly EX";
      flock(LCK_APPONLY,LOCK_EX) or
         die "ERROR: hbu -m apponly can't get apponly mode lock (flock: $!)";
      trace "flock apponly UN";
      flock(LCK_APPONLY,LOCK_UN);
      }
      return 1;
   }

sub unlock($)
   {
   my $mode = shift;
   die "Not a valid lock type: $mode" unless exists $locks{$mode};
   if ( $mode eq 'full' )
      {
      trace "flock full UN";
      flock(LCK_FULL,LOCK_UN);
      }
   elsif ( $mode eq 'arch' )
      {
      trace "flock arch UN";
      flock(LCK_ARCH,LOCK_UN);
      }
   elsif ( $mode eq 'apponly' )
      {
      trace "flock apponly UN";
      flock(LCK_APPONLY,LOCK_UN);
      }
   return 1;
   }

sub usage()
   {
   print "usage: $0 [-h] -m <full|arch|apponly>\n";
   }

sub trace($)
   {
   my $msg = shift;
   print strftime('%Y/%m/%d %H:%M:%S',localtime(time))," ===$msg===\n" if $debug & 128;
   }
