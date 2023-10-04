#!/usr/bin/env sh

# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

year=$(date +%Y)
baseDir="$1"
copyrightHolder="$2"
test -z $baseDir && baseDir=.
test -z $copyrightHolder && copyrightHolder="SECO Mind Srl"

gitFiles=$(git -C "$baseDir" ls-files --deduplicate --no-empty-directory)
normalFiles=$(echo "$gitFiles" | rg -v '\.license$')
licenseFiles=$(echo "$gitFiles" | rg '\.license$')

# Copyright in normal files
sd '^(\S*\s*Copyright\s+\d+).*(\n\S*\s*SPDX-License-Identifier:\s+.*)$' "\$1-$year $copyrightHolder\$2" $normalFiles
sd "^(\S*\s*Copyright\s+)$year-($year $copyrightHolder)(\n\S*\s*SPDX-License-Identifier:\s+.*)$" '$1$2$3' $normalFiles

# Copyright in license files
sd '(SPDX-FileCopyrightText:\s*\d+).*' "\$1-$year $copyrightHolder" $licenseFiles
sd "(SPDX-FileCopyrightText:\s*)$year-($year $copyrightHolder)" '$1$2' $licenseFiles
