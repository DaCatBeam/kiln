# Kiln
fd
> [!WARNING]
> Kiln is not yet a complete security benchmark implementation. Stablility will be declared
> upon version v1.0.0 once initial target Linux distros (Debian-12, Ubuntu-24.04) have their
> initial OS hardening and Kubernetes requirements met.

Kiln is an Ansible project for hardening Linux hosts that are ready to run a
hardened Kubernetes installation. The repository is currently an initial,
safe-by-default series of planned roles and does not arise to the level of
compliance that most secure deployments require.

Kiln is actively pursuing the implementation of compliance hardening specifications
conformant to STIGs created by DISA, based upon NIST controls, for the purpose of hardening
Linux distributions for hardened Canonical Kubernetes deployments. As such, the primary STIG
implementation that this project works toward is the Kubernetes STIG vended by DISA.
Meaning, when a Linux distro STIG has an implementation guideline that conflicts with the
Kubernetes STIG, the Kubernetes STIG is favored over the Linux distro STIG.

Not all Linux distros have a DISA STIG created for them. In such cases, the named CIS STIG
Benchmark for that Linux distro is preferred.

In circumstances where neither a DISA STIG or CIS STIG Benchmark can be attained for a
Kiln-supported Linux distro, the generalized CIS Benchmark Level guidelines are implemented,
favoring the highest achievable CIS Benchmark Level (1-3) given the circumstances.



## Repository layout

```text
inventories/              Environment inventories and group variables
playbooks/                End-to-end node and Kubernetes workflows
roles/                    Small, independently testable units of automation
molecule/                 Linux Distro VM lifecycle scenarios
ansible.cfg               Project-local Ansible defaults
requirements.yml          Ansible Galaxy collection dependencies
requirements-dev.txt      Python development and test tooling
```

OS Provisioning Entrypoint: `playbooks/site.yml`
Kubernetes Cluster Upgrade Entrypoint: `playbooks/upgrade_cluster.yml`

## Local development on macOS

The VM tests need Python, Vagrant, and a Vagrant provider (VirtualBox)
```bash
brew install pyenv pyenv-virtualenv
brew install --cask vagrant virtualbox

pyenv install -s 3.12.11
pyenv virtualenv 3.12.11 kiln
pyenv activate kiln

python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml
```

Confirm the toolchain:

```bash
ansible --version
molecule --version
vagrant --version
VBoxManage --version
```

Set Vagrants default provider as `virtualbox`.

```bash
export VAGRANT_DEFAULT_PROVIDER=virtualbox
```

## Testing philosophy

Kiln uses layered tests:

1. YAML and Ansible syntax checks catch inexpensive structural failures.
2. Molecule convergence applies a real role and must be idempotent.
3. Verification asserts state from inside a full VM, including the expected
   distribution family and evidence that the target is a virtual guest.
4. Debian and Ubuntu scenarios expose assumptions tied to either the APT or DNF
   ecosystem.
5. Destruction is part of the test: every lifecycle must be repeatable and
   leave no running guest behind.

Run VM tests:

```bash
# Run all test scenarios
make run-all-tests

# Run an individual scenario
molecule test --scenario-name debian

# Run individual scenario lifecycle playbook
molecule create --scenario-name debian
molecule converge --scenario-name debian
molecule verify --scenario-name debian
molecule destroy --scenario-name debian
```
