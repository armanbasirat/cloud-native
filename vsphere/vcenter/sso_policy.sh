#!/bin/bash

VCENTER_ADMIN="administrator@vsphere.local"
POLICY_DAYS=90

# List of service accounts that should never expire
SERVICE_ACCOUNTS=(
  "veeambackup@vsphere.local"
  "veeamone@vsphere.local"
  "veeamone@vsphere.local"
)

read -s -p "Enter password for ${VCENTER_ADMIN}: " VCENTER_PASS
echo ""

set_global_policy() {

  echo "Setting global SSO password expiration policy to ${POLICY_DAYS} days..."

  /usr/lib/vmware-vmdir/bin/dir-cli password policy set \
    --max-life-days ${POLICY_DAYS} \
    --login "${VCENTER_ADMIN}" \
    --password "${VCENTER_PASS}"

  if [ $? -eq 0 ]; then
    echo "Global password policy updated successfully."
  else
    echo "Failed to update global password policy."
    exit 1
  fi
}

disable_expiration_sa() {

  for ACCOUNT in "${SERVICE_ACCOUNTS[@]}"; do

    echo "Disabling password expiration for: ${ACCOUNT}"

    /usr/lib/vmware-vmdir/bin/dir-cli user modify \
      --account "${ACCOUNT}" \
      --set-password-never-expire true \
      --login "${VCENTER_ADMIN}" \
      --password "${VCENTER_PASS}"

    if [ $? -eq 0 ]; then
      echo "Password expiration disabled for ${ACCOUNT}"
    else
      echo "Failed to modify ${ACCOUNT}. Check if it exists."
    fi
  done
}

get_ploicy() {

  echo "Verifying current policy and account settings..."

  /usr/lib/vmware-vmdir/bin/dir-cli password policy get \
    --login "${VCENTER_ADMIN}" \
    --password "${VCENTER_PASS}"

  for ACCOUNT in "${SERVICE_ACCOUNTS[@]}"; do

    echo "---- ${ACCOUNT} ----"

    /usr/lib/vmware-vmdir/bin/dir-cli user get \
      --account "${ACCOUNT}" \
      --login "${VCENTER_ADMIN}" \
      --password "${VCENTER_PASS}" | grep -E "User:|Password Never Expires"

  done
}