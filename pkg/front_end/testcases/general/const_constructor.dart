// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  final int field1;

  const Super(this.field1);
}

class Class extends Super {
  final int field2;

  const Class(super.field1, this.field2);
}
