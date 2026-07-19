# kubeadm_control_plane

Defines the guarded control-plane bootstrap boundary. Enabling it currently
fails clearly because generating certificates and a production kubeadm config
without a reviewed design would be unsafe.
