<!--
Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->
# Running tests

    export DART_AOT_SDK=.../xcodebuild/DerivedSources/DebugX64/patched_sdk
    dart -c --packages=.packages package:testing/src/run_tests.dart test/closures/testing.json
