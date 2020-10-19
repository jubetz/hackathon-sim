#!/usr/bin/env bash

set -x

###########################
# linter.sh
# -----
# looks through the current directory
# for all files ending in .yml
# and then passes them through yamllint
# which checks for valid yaml syntax
#
# YamlLint can be found at
# https://pypi.python.org/pypi/yamllint
#
# Installed via pip with
# $ pip install yamllint
#
#
###########################

if [ -d "./cldemo2" ]
then
  echo "cldemo2 submodule detected - in a topology repo"
  yamllint ./ -c ./cldemo2/ci-common/.yamllint
else
  echo "no cldemo2 folder/submodule detected - in the cldemo2 base repo"
  yamllint ./ -c ./ci-common/.yamllint
fi
