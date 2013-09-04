// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'compiler_helper.dart';

const String TEST = '''
foo(a) {
  foo([]);
  print(a[0]);
}
''';

main() {
  String generated = compile(
      TEST,
      entry: 'foo',
      interceptorsSource: DEFAULT_INTERCEPTORSLIB
      // ADD a bogus indexable class that does not have [].
          + 'class BogusIndexable implements JSIndexable {}');

  // Ensure that we still generate an optimized version, even if there
  // is an indexable class that does not implement [].
  Expect.isTrue(!generated.contains('index'));
}
