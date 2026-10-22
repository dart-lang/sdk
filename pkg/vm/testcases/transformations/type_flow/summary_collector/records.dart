// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const recordConstant = (42, 'Hey', foo: 'foo');

// Field expressions are Statements (%x, %y, %z), so CreateRecordType cannot be
// simplified during summary normalization.
recordLiteral(x, y, z) => (x, y, bar: z);

// All field expressions are specialized Types, so CreateRecordType.simplify()
// folds the statement directly into a ConcreteType with recordFieldTypes.
recordLiteralSpecialized() => (10, 'abc', foo: const <int>[1]);

// String interpolation produces an unspecialized ConeType (_T (String)+), so
// CreateRecordType.simplify() must not fold it before analysis time.
recordLiteralUnspecialized(String x) => ('$x!', 42);

// A field expression of EmptyType causes CreateRecordType.simplify() to fold
// the record creation to EmptyType (_T {}).
recordLiteralEmpty() => (42, throw 'unreachable');

recordFieldAccess1((int, String) rec) => rec.$2;

recordFieldAccess2(({int a, String b}) rec) => rec.b;

main() {}
