# Kiln agent guide

## Purpose

Kiln prepares and hardens Linux nodes for kubeadm-based Kubernetes clusters.
The project is currently an initial skeleton, and will begin implementing
two targeted distributions. This is not a finished compliance profile. Changes
must keep that distinction clear in code and documentation.

## Current Intention

Kiln is actively pursuing the implementation of compliance hardening specifications
conformant to STIGs created by DISA, based upon NIST controls, for the purpose of hardening
linux distributions for hardened Canonical Kubernetes deployments. As such, the primary STIG
implementation that this project works toward is the Kubernetes STIG vended by DISA.
Meaning, when a linux distro STIG has an implementation guideline that conflicts with the
Kubernetes STIG, the Kubernetes STIG is favored over the linux distro STIG.

Not all linux distros have a DISA STIG created for them. In such cases, the named CIS STIG
benchmark for that linux distro is preferred.

In circumstances where neither a DISA STIG or CIS STIG Benchmark can be attained for a
Kiln-supported linux distro, the generalized CIS Benchmark Level guidelines are implemented,
favoring the highest achievable CIS Benchmark Level (1-3) given the circumstances.

## Rules of the road

- Treat host hardening, cluster bootstrap, and upgrades as high-impact work.
  Never run a playbook against a real inventory unless the user explicitly
  asks for that execution.
- Use an explicit `-i` argument for non-test Ansible commands. Never infer that
  the sample development addresses are reachable or safe targets.
- Keep roles idempotent, focused, and distribution-aware. Prefer Ansible
  modules with fully qualified collection names over `command` or `shell`.
- Put role tunables in `defaults/main.yml`; put environment decisions in
  inventory group variables. Do not bury environment-specific values in tasks.
- Default incomplete or disruptive functionality to disabled. An enabled role
  must either implement and verify its contract or fail with a clear message.
- Never commit credentials, kubeadm join tokens, certificates, kubeconfigs,
  vault passwords, private keys, or production host details.
- Preserve serial and control-plane/worker boundaries in upgrade workflows.
- Update role documentation and verification whenever behavior changes.

## Validation

Run the cheapest relevant checks first:

```bash
yamllint .
ansible-lint
ansible-playbook --syntax-check playbooks/site.yml
```

Then test the affected distribution scenario:

```bash
molecule test --scenario-name debian
molecule test --scenario-name ubuntu
```

Molecule owns its Vagrant guests. If a test is interrupted, explicitly run
`molecule destroy --scenario-name <name>` and confirm `vagrant global-status`
does not show a running Kiln VM.

## Design notes

- `playbooks/site.yml` is the normal composition entry point.
- `playbooks/upgrade_cluster.yml` intentionally remains a separate operation.
- Molecule's built-in delegated driver is named `default`; lifecycle playbooks
  in each scenario call Vagrant and populate Molecule's instance-config API.
- The lifecycle probe in `node_baseline` is disabled outside Molecule and is
  the minimal executable contract used to validate create/converge/verify.
