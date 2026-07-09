// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:never-inline')
/*spec|canary.member: test1:function(a) {
  B.JSArray_methods.$indexSet(a, 5, 1);
  B.JSArray_methods.$indexSet(a, 0, 2);
  return a;
}*/
/*prod.member: test1:function(a) {
  a.$flags & 2 && A.throwUnsupportedOperation(a);
  if (5 >= a.length)
    return A.ioore(a, 5);
  a[5] = 1;
  a[0] = 2;
  return a;
}*/
List<int> test1(List<int> a) {
  a[5] = 1;
  a[0] = 2;
  return a;
}

@pragma('dart2js:never-inline')
/*member: test2:function(a) {
  B.JSArray_methods.add$1(a, 100);
  return a;
}*/
List<int> test2(List<int> a) {
  a.add(100);
  return a;
}

@pragma('dart2js:never-inline')
bool isEven(int i) => i.isEven;

@pragma('dart2js:never-inline')
/*member: maybeUnmodifiable:ignore*/
List<int> maybeUnmodifiable() {
  List<int> d = List.filled(10, 0);
  if (DateTime.now().millisecondsSinceEpoch == 42) d = List.unmodifiable(d);
  return d;
}

/*member: main:ignore*/
main() {
  print(test1(maybeUnmodifiable()));
  print(test2(maybeUnmodifiable()));
}
