# Molecule VM testing

Kiln uses Molecule's built-in delegated driver (`driver.name: default`) to
orchestrate full Vagrant VMs. Molecule remains the workflow entry point, while
scenario playbooks translate lifecycle actions to Vagrant:

```text
molecule create   -> vagrant up --no-provision
molecule converge -> run node_baseline and write a guest-side probe
molecule verify   -> check distro, virtualization, and probe state
molecule destroy  -> vagrant destroy --force
```

The scenarios default to `bento/debian-13` and `bento/ubuntu-43`. Each box has
VirtualBox artifacts for Apple Silicon and Intel Macs. A box download is cached
by Vagrant and can be several hundred megabytes.

## Run a lifecycle

From the repository root with the Python virtual environment active:

```bash
molecule test --scenario-name debian
molecule test --scenario-name ubuntu
```

For an inspectable, step-by-step run:

```bash
molecule create --scenario-name debian
molecule converge --scenario-name debian
molecule verify --scenario-name debian
molecule login --scenario-name debian
molecule destroy --scenario-name debian
```

If `molecule login` is unavailable for a provider, use Vagrant directly:

```bash
VAGRANT_CWD=molecule/debian vagrant ssh kiln-debian
```

## Runtime overrides

Use environment variables rather than editing committed scenario files:

```bash
# Select a provider already installed for Vagrant.
export VAGRANT_DEFAULT_PROVIDER=virtualbox

# Tune both scenarios.
export KILN_VM_CPUS=4
export KILN_VM_MEMORY=4096

# Replace or pin scenario boxes.
export KILN_DEBIAN_BOX=bento/debian-13
export KILN_DEBIAN_BOX_VERSION=<published-version>
export KILN_UBUNTU_BOX=bento/ubuntu-43
export KILN_UBUNTU_BOX_VERSION=<published-version>
```

`KILN_BOX_CHECK_UPDATE=true` re-enables Vagrant's update check. It defaults to
false so repeated test runs do not unexpectedly switch the base image.

## See what was created and where

These commands are read-only unless explicitly noted:

```bash
# Molecule's view and generated inventory/connection state.
molecule list
find "$HOME/.cache/molecule/kiln" -maxdepth 3 -print 2>/dev/null

# Per-scenario Vagrant state stored in this checkout.
find molecule -path '*/.vagrant/*' -maxdepth 5 -print
VAGRANT_CWD=molecule/debian vagrant status
VAGRANT_CWD=molecule/ubuntu vagrant status

# Vagrant's cross-project VM registry and downloaded box cache.
vagrant global-status
find "$HOME/.vagrant.d/boxes" -maxdepth 2 -type d -print 2>/dev/null
du -sh "$HOME/.vagrant.d/boxes"/* 2>/dev/null

# VirtualBox's registered VMs and provider-side details.
VBoxManage list runningvms
VBoxManage list vms
VBoxManage showvminfo kiln-debian 2>/dev/null
VBoxManage showvminfo kiln-ubuntu 2>/dev/null
```

The important host locations are:

| Purpose | Default location |
| --- | --- |
| Molecule ephemeral state | `~/.cache/molecule/kiln/<scenario>/` |
| Vagrant scenario state | `molecule/<scenario>/.vagrant/` |
| Downloaded boxes | `~/.vagrant.d/boxes/` |
| VirtualBox guest disks/config | VirtualBox's configured machine folder |

`molecule destroy --scenario-name <name>` deletes that scenario's VM and disk,
but Vagrant deliberately retains its downloaded base-box cache for later runs.
Use `vagrant box list` to inspect retained boxes. Do not delete provider folders
manually while a guest is registered; destroy the guest through Molecule first.
