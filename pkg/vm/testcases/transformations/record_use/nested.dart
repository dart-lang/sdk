// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  const list = [
    const MyClass(42),
    {
      const MyClass('test'),
      const MyOtherClass(),
    },
  ];
  print(list);
}

@RecordUse()
class MyClass {
  final Object i;

  const MyClass(this.i);
}

@RecordUse()
class MyOtherClass {
  const MyOtherClass();
}
