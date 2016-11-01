// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

main() {
  asyncTest(() =>
      compileAll(r'''main() { return "${2}${true}${'a'}${3.14}"; }''')
          .then((code) {
        Expect.isTrue(code.contains(r'2truea3.14'));
      }));

  asyncTest(() =>
      compileAll(r'''main() { return "foo ${new Object()}"; }''').then((code) {
        Expect.isFalse(code.contains(r'$add'));
      }));
}
