#!/usr/bin/env bash

# Check if the script is executing as 'root'.
if [[ ${EUID} -ne 0 ]]; then

  echo -e "\nScript is running as '$(whoami)', not 'root'.\nAttempting to switch to 'root'."

  # Re-execute this script as 'root'.
  exec sudo "$0" "$@"

  # Due to the 'exec' command above, the below lines of code will not execute if the script succeeds running as 'root'.
  echo -e "\nFailed to switch to the 'root' user, exiting."
  exit 1

fi

echo -e '\nMaking the following changes to all kernel entries in the GRUB bootloader:'
echo -e '- Enable logging of kernel messages upto level 3 (error) and below.'
echo -e '- Disable logging of all other types of messages.'
echo -e '- Disable all watchdogs.'
echo -e '- Disable the NMI watchdog explicitly.'
echo -e "- Disable the Intel 'iTCO_wdt' watchdog explicitly."
echo -e "- Disable the AMD 'sp5100_tco' watchdog explicitly."
echo -e "- Set the default suspend state to 'deep' i.e. in-memory."
echo -e "- Disable the 'nouveau' driver from being loaded in the initial ramdisk stage."
echo -e "- Disable the 'nouveau' driver from being loaded later in the boot process."
echo -e '- Enable the Kernel Mode Setting feature for the NVIDIA driver.'
echo -e '- Enable a framebuffer device for the NVIDIA driver.'
grubby --update-kernel=ALL --args='loglevel=3 quiet nowatchdog nmi_watchdog=0 modprobe.blacklist=iTCO_wdt modprobe.blacklist=sp5100_tco mem_sleep_default=deep modprobe.blacklist=nouveau rd.driver.blacklist=nouveau nvidia-drm.modeset=1 nvidia-drm.fbdev=1'

echo -e '\nPrinting the kernel command-line parameters from the default GRUB entry.\n'
grubby --info=DEFAULT

echo -e '\nSuccess!\n'
exit 0