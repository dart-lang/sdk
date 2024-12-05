// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin HasSomeField {
  String get someField;
}

enum SomeEnum with HasSomeField {
  value;

  @override
  String get someField => 'field';
}
