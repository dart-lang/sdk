// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class T {
  const T(this.symbol);
  final Symbol symbol;
}

class U {
  @T(#x)
  int? field;
}

main() {
  final field = reflectClass(U).declarations[#field] as VariableMirror;
  final metadata = field.metadata;
  Expect.identical((metadata.first.reflectee as T).symbol, const Symbol('x'));
}
