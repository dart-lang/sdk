// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

typedef Record = ({String name});

Type getType<T>() => T;

Type makeNullable<T>() => getType<T?>();

void main() {
  final record1 = getType<Record?>();
  final record2 = makeNullable<Record>();
  Expect.equals(record1, record2);
  Expect.equals(record1.hashCode, record2.hashCode);

  // Check that implementation type details of record field types do not leak
  // into record type equality and hash codes.
  final record3 = (List<int>.filled(3, 1, growable: false), "a");
  final record4 = (List<int>.filled(3, 1, growable: true), "b");
  final record5 = (List<int>.unmodifiable([1, 2, 3]), "b");
  Expect.equals(record3.runtimeType, record4.runtimeType);
  Expect.equals(record3.runtimeType.hashCode, record4.runtimeType.hashCode);
  Expect.equals(record4.runtimeType, record5.runtimeType);
  Expect.equals(record4.runtimeType.hashCode, record5.runtimeType.hashCode);
}
