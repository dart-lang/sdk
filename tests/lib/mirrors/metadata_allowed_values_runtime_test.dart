// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'metadata_allowed_values_import.dart'; // Unprefixed.
import 'metadata_allowed_values_import.dart' as prefix;

@B.CONSTANT
class B {
  static const CONSTANT = 3;
}

@C(3)
class C {
  final field;
  const C(this.field);
}

@D.named(4)
class D {
  final field;
  const D.named(this.field);
}

@Imported()
class N {}

@Imported.named()
class O {}

@Imported.CONSTANT
class P {}

@prefix.Imported()
class R {}

@prefix.Imported.named()
class S {}

@prefix.Imported.CONSTANT
class T {}

checkMetadata(DeclarationMirror mirror, List expectedMetadata) {
  Expect.listEquals(expectedMetadata.map(reflect).toList(), mirror.metadata);
}

main() {
  checkMetadata(reflectClass(B), [B.CONSTANT]);
  checkMetadata(reflectClass(C), [const C(3)]);
  checkMetadata(reflectClass(D), [const D.named(4)]);
  checkMetadata(reflectClass(N), [const Imported()]);
  checkMetadata(reflectClass(O), [const Imported.named()]);
  checkMetadata(reflectClass(P), [Imported.CONSTANT]);
  checkMetadata(reflectClass(R), [const prefix.Imported()]);
  checkMetadata(reflectClass(S), [const prefix.Imported.named()]);
  checkMetadata(reflectClass(T), [prefix.Imported.CONSTANT]);
}
