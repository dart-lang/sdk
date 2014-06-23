# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

SDK_DIR=../../../xcodebuild/ReleaseIA32/dart-sdk
PACKAGE_ROOT=../../../sdk/lib/_internal/

all:
	$(SDK_DIR)/bin/dartanalyzer -p $(PACKAGE_ROOT) \
	--package-warnings --machine leap.dart 2>&1 \
	| grep -v DEPRECATED_MEMBER_USE \
	| sed -e "s,$(PWD)/,," \
	| awk -F'|' '{print $$4 ":" $$5 ":" $$6 ": [" $$3 "] " $$8 }'
