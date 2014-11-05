# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This Makefile is used to run the analyzer on the sources of poi.dart.
# Unfortunately, we have to ignore some hints either due to bugs in the
# analyzer, or due to patterns in dart2js (for example, unused imports of
# helpers.dart).
#
# The purpose of this Makefile is to be used from inside Emacs to fix any valid
# warning or hints reported. The whitelist is maintained as needed by those who
# use this Makefile.

SDK_DIR=../../../xcodebuild/ReleaseIA32/dart-sdk
PACKAGE_ROOT=../../../xcodebuild/ReleaseIA32/packages/

all:
	@echo $(SDK_DIR)/bin/dartanalyzer -p $(PACKAGE_ROOT) repeat_poi.dart
	@$(SDK_DIR)/bin/dartanalyzer -p $(PACKAGE_ROOT) \
	--package-warnings --machine ../poi/repeat_poi.dart 2>&1 \
	| grep -v DEPRECATED_MEMBER_USE \
	| grep -v DEAD_CODE \
	| grep -v -E 'INFO\|HINT\|ARGUMENT_TYPE_NOT_ASSIGNABLE\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/cps_ir/optimizers\.dart\|7\|8\|27\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/dart2jslib\.dart\|26\|8\|22\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/dart_types\.dart\|17\|8\|22\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/elements/elements\.dart\|[0-9]+\|8\|25\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/elements/modelx\.dart\|[0-9]+\|8\|25\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/js_emitter/js_emitter\.dart\|[0-9]+\|8\|25\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/library_loader\.dart\|25\|8\|22\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/patch_parser\.dart\|[0-9]+\|8\|22\|' \
	| grep -v -E 'INFO\|HINT\|UNUSED_IMPORT\|.*/compiler/implementation/resolution/class_members\.dart\|22\|8\|25\|' \
	| sed -e "s,$(PWD)/,," \
	| awk -F'|' '{print $$4 ":" $$5 ":" $$6 ":\n [" n$$3 "]" $$8 }' \
