// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const recordConstant = (42, 'Hey', foo: 'foo');

recordLiteral(x, y, z) => (x, y, bar: z);

recordFieldAccess1((int, String) rec) => rec.$1;

recordFieldAccess2(({int a, String b}) rec) => rec.a;

dynamic list = ['abc', (42, foo42: 'foo42')];

recordDynamicFieldAccess(dynamic x) => x.foo42;

(List<int>, List<String>) getLists() =>
    ([1, 2, 3], List<String>.filled(2, 'a'));

void iterateLists() {
  final (list1, list2) = getLists();
  for (final x in list1) {
    print(x);
  }
  for (final x in list2) {
    print(x);
  }
}

dynamic wrapRecord(dynamic x, bool b1, bool b2, bool b3) {
  final r = (x, 10);
  if (b1) return wrapRecord(r, b2, b3, false);
  return r;
}

void testRecursiveRecords() {
  final d0 = wrapRecord(1, false, false, false);
  print(d0.$1);
  print(d0.$2);

  final d1 = wrapRecord(2, true, false, false);
  print(d1.$1.$1);
  print(d1.$2);

  final d2 = wrapRecord(3, true, true, false);
  print(d2.$1.$1.$1);
  print(d2.$2);

  final d3 = wrapRecord(4, true, true, true);
  print(d3.$1);
  print(d3.$2);
}

Object deepRecordField = (1,);
void pumpRecordField() {
  deepRecordField = (deepRecordField,);
}

(int, int) createRecordWithThrow(bool y) => (42, maybeThrow(y));
int maybeThrow(bool y) => y ? 1 : throw '';

void testEmptyRecordField() {
  final (a, b) = createRecordWithThrow(false);
  print(a);
  print(b);
}

main() {
  print(recordConstant);
  print(recordLiteral(1, 2, 3));
  print(recordFieldAccess1((10, 'hi')));
  print(recordFieldAccess2((a: 20, b: 'bye')));
  print(recordDynamicFieldAccess(list[1]));
  print((const [1], ['a']));
  iterateLists();
  testRecursiveRecords();
  pumpRecordField();
  print(deepRecordField);
  testEmptyRecordField();
}
