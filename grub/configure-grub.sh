#!/bin/sh

# Exit on any error.
# Exit if any unset variable is used/referenced.
set -eu

# Get the ID of the current user.
current_user_id="$(id -u)"

# Check if the script is not running as 'root'.
if [ "${current_user_id}" -ne 0 ]; then

  echo "Script is not running as 'root'."
  echo "Attempting to switch to 'root'."

  # Re-execute this script as 'root'.
  exec sudo "$0" "$@"

  # Due to the 'exec' command above, the below lines of code will not execute if the script succeeds running as 'root'.
  echo "Failed to switch to the 'root' user."
  exit 1

# Otherwise, if the script is running as 'root'.
else

  # Initialize a variable to check if the program 'grubby' is installed.
  is_grubby_installed="$(command -v grubby > /dev/null 2>&1; echo $?)"

  # Check if the 'grubby' binary is not available in 'PATH'.
  if [ 0 -ne "${is_grubby_installed}" ]; then

    # Print an error and exit.
    echo "The program 'grubby' is not installed."
    exit 1

  # Otherwise, if the 'grubby' program is installed properly.
  else

    echo 'Making the following changes to all kernel entries in the GRUB bootloader:'
    echo ' - Disable all watchdogs.'
    echo ' - Disable the NMI watchdog explicitly.'
    echo " - Disable the Intel 'iTCO_wdt' watchdog explicitly."
    echo " - Disable the AMD 'sp5100_tco' watchdog explicitly."
    echo " - Disable the 'nouveau' driver from being loaded in the initial ramdisk stage."
    echo " - Disable the 'nouveau' driver from being loaded later in the boot process."
    echo ' - Enable the Kernel Mode Setting feature for the NVIDIA driver.'
    echo ' - Enable a framebuffer device for the NVIDIA driver.'
    echo ' - Disable active-state power management as it can often break.'
    grubby --update-kernel=ALL --args='nowatchdog nmi_watchdog=0 modprobe.blacklist=iTCO_wdt modprobe.blacklist=sp5100_tco modprobe.blacklist=nouveau rd.driver.blacklist=nouveau nvidia-drm.modeset=1 nvidia-drm.fbdev=1 pcie_aspm=off'

    echo 'Printing the kernel command-line parameters from the default GRUB entry.'
    grubby --info=DEFAULT

  fi

  # Unset the variables used.
  unset is_grubby_installed

fi

# Unset the variables used.
unset current_user_id