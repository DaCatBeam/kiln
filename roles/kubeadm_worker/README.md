# kubeadm_worker

Defines the guarded worker join boundary. Join tokens are secrets and must be
injected at runtime; the initial scaffold fails if someone enables it before a
secure execution path is implemented.
