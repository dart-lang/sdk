// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 13817.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Tag {
  final name;
  const Tag({named}) : this.name = named;
}

@Tag(named: 'valid')
class B {}

@Tag(named: C.STATIC_FIELD)
class C {
  static const STATIC_FIELD = 3;
}

checkMetadata(DeclarationMirror mirror, List expectedMetadata) {
  Expect.listEquals(expectedMetadata.map(reflect).toList(), mirror.metadata);
}

main() {
  checkMetadata(reflectClass(B), [const Tag(named: 'valid')]);
  checkMetadata(reflectClass(C), [const Tag(named: C.STATIC_FIELD)]);
}
