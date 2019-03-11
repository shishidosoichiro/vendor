#!/usr/bin/env sh

# Exit, if return non-zero or use an undefined variable.
set -eu

cd "$(dirname "$0")/.."

install_dir=${1:-~/.vendor}
git clone https://github.com/shishidosoichiro/vendor-home "$install_dir"

cd "$install_dir"
git clone https://github.com/shishidosoichiro/vendor-vendor vendor
