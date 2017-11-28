// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 19413.

import 'regress_19413_foo.dart' as foo;
import 'regress_19413_bar.dart' as foo;

main() {
  foo.f(); /*@compile-error=unspecified*/
}
