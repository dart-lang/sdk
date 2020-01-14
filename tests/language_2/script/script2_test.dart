// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Part file has library and import directives.

/*@compile-error=unspecified*/
// TODO(rnystrom): Using the above tag instead of making this a static error
// test because the error is reported in the part file and not in this file.
// Static error tests only support errors reported in the main test file itself.
part "script2_part.dart";

main() {
  print("Should not reach here.");
}
