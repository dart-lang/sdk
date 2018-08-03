// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library named_constructor_lib;

class Class<T> {
  final int value;
  Class() : value = 2;
  Class.named() : value = 3;
}
