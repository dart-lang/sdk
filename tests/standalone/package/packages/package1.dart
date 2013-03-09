// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("package1");

#import('package2.dart', prefix: 'p1');
#import('package2.dart', prefix: 'p2');
#import('package:package2.dart', prefix: 'p3');

main() {
  Expect.identical(p1.x, p2.x);
  Expect.identical(p1.x, p3.x);
}
