// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('lib2');
#import('LibrarySameNameUsedLib1.dart', prefix:'lib1');  // for interface X.

class X implements lib1.X {
  X();
  toString() => 'lib2.X';
}
