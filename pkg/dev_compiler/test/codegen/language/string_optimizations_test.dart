// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js's type inferrer, that used to not
// correclty infer optional named parameters.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

@DontInline()
foo({path}) {
  () => 42;
  return path.toString();
}

@DontInline()
bar({path}) {
  () => 42;
  return path;
}

main() {
  var a = [foo(path: '42'), foo(), 42, bar(path: '54')];
  Expect.isTrue(a[1] is String);
  Expect.throws(() => bar().concat('54'), (e) => e is NoSuchMethodError);
}
