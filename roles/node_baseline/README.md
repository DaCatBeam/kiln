# node_baseline

Creates `/etc/kiln` and records stable, non-secret facts about the managed host.
Molecule also uses this role's opt-in lifecycle probe as its minimal convergence
contract. `node_baseline_lifecycle_probe_enabled` must remain disabled outside tests.
