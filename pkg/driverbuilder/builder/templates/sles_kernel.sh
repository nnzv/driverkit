#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Simple script that desperately tries to load the kernel instrumentation by
# looking for it in a bunch of ways. Convenient when running Falco inside
# a container or in other weird environments.
#
set -xeuo pipefail

# Fetch the kernel
rm -Rf /tmp/kernel-download
mkdir /tmp/kernel-download
cd /tmp/kernel-download
zypper --non-interactive install --download-only kernel-default-devel={{ .KernelPackage }} kernel-devel={{ .KernelPackage }}
mv -v $(find /var/cache/zypp/packages -name kernel*.rpm) /tmp/kernel-download
for rpm in /tmp/kernel-download/*.rpm
do
    rpm2cpio $rpm | cpio --extract --make-directories
done
sourcedir="$(find . -type d -name "linux-*-obj" | head -n 1 | xargs readlink -f)/*/default"

# exit value
export KERNELDIR=$sourcedir
