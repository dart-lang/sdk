// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('GetterSetterInLibTest');
#import('getter_setter_in_lib.dart');

main() {
  Expect.equals(42, foo);
  foo = 43;
  Expect.equals(42, foo);
}
