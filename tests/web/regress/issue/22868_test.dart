// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/22868 and http://dartbug.com/22895
// Ensure that the closure tracer properly handles await.

main() async {
  var closures = [(x, y) => x + y];
  print(((await closures)[0])(4, 2));
}
