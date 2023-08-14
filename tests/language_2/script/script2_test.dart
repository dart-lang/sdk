// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Part file has library and import directives.

// TODO(rnystrom): Using a multitest instead of making this a static error test
// because the error is reported in the part file and not in this file. Once
// issue #44990 is fixed, this can be a static error test.
part "script2_part.dart"; //# 01: compile-time error

main() {}
