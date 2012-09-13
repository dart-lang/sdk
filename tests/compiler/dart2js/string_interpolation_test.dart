// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

main() {
  String code =
      compileAll(r'''main() { return "${2}${true}${'a'}${3.14}"; }''');
  Expect.isTrue(code.contains(r'2truea3.14'));

  code = compileAll(r'''main() { return "foo ${new Object()}"; }''');
  Expect.isFalse(code.contains(r'concat'));
}
