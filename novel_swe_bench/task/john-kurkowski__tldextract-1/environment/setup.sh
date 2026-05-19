#!/usr/bin/env bash
# Install dependencies for john-kurkowski__tldextract-1.
# Mirrors `install_spec.install_commands` in instance.json so that callers
# bypassing Docker (e.g. a local venv) get the same environment.
set -euo pipefail

# tldextract uses setuptools-scm; without git tags we pin the version explicitly.
export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_TLDEXTRACT=5.3.1

python -m pip install --upgrade pip
python -m pip install 'pytest>=7,<9' sybil pytest-mock responses syrupy
python -m pip install -e .
