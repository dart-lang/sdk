// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 19413.

import 'regress19413_foo.dart' as foo;
import 'regress19413_bar.dart' as foo;

main() {
  foo.f();
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_IMPORT
  // [cfe] 'f' is imported from both 'tests/language/regress/regress19413_bar.dart' and 'tests/language/regress/regress19413_foo.dart'.
}
