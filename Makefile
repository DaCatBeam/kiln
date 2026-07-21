SHELL := /bin/bash

PHONY: run-all-tests run-debian-tests run-ubuntu-tests run-linter \
	   create-test-fixtures create-gpg-test-fixtures

run-linter:
	yamllint .;
	ansible-lint;
	ansible-playbook --syntax-check playbooks/*.yml;

run-debian-tests: create-test-fixtures
	molecule test --scenario-name debian;

run-ubuntu-tests:
	molecule test --scenario-name ubuntu;

run-all-tests: run-linter run-debian-tests run-ubuntu-tests

create-gpg-test-fixtures:
	scripts/gen-gpg-fixtures.sh;

create-test-fixtures: create-gpg-test-fixtures
