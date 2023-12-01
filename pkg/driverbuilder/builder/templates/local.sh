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

{{ if .DownloadSrc }}
echo "* Downloading driver sources"
rm -Rf {{ .DriverBuildDir }}
mkdir {{ .DriverBuildDir }}
rm -Rf /tmp/module-download
mkdir -p /tmp/module-download

curl --silent -SL {{ .ModuleDownloadURL }} | tar -xzf - -C /tmp/module-download
mv /tmp/module-download/*/driver/* {{ .DriverBuildDir }}

cp /tmp/module-Makefile {{ .DriverBuildDir }}/Makefile
bash /tmp/fill-driver-config.sh {{ .DriverBuildDir }}
{{ end }}

{{ if .BuildModule }}
{{ if .UseDKMS }}
echo "* Building kmod with DKMS"
# Build the module using DKMS
echo "#!/usr/bin/env bash" > "/tmp/falco-dkms-make"
echo "make CC={{ .GCCVersion }} \$@" >> "/tmp/falco-dkms-make"
chmod +x "/tmp/falco-dkms-make"
dkms install --directive="MAKE='/tmp/falco-dkms-make'" -m "{{ .ModuleDriverName }}" -v "{{ .DriverVersion }}" -k "{{ .KernelRelease }}"
rm -Rf "/tmp/falco-dkms-make"
{{ else }}
echo "* Building kmod"
# Build the module
cd {{ .DriverBuildDir }}
make CC={{ .GCCVersion }}
mv {{ .ModuleDriverName }}.ko {{ .ModuleFullPath }}
strip -g {{ .ModuleFullPath }}
# Print results
modinfo {{ .ModuleFullPath }}
{{ end }}
{{ end }}

{{ if .BuildProbe }}
echo "* Building eBPF probe"
# Build the eBPF probe
cd {{ .DriverBuildDir }}/bpf
make
ls -l probe.o
{{ end }}

rm -Rf /tmp/module-download