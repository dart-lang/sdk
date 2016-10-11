// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  var l = [new MyTest(1), new MyTest(5), new MyTest(3)];
  l.sort();
  if (l.toString() != "[d{1}, d{3}, d{5}]") throw 'Wrong result!';
}

class MyTest implements Comparable<MyTest> {
  final int a;
  MyTest(this.a);
  int compareTo(MyTest b) => this.a - b.a;
  String toString() => "d{$a}";
}
