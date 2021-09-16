// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var list1 = List<int>.generate(10, (i) => i);
var list2 = List<int>.generate(10, (i) => i, growable: true);
var list3 = List<int>.generate(10, (i) => i, growable: false);
var list4 = List<int>.generate(10, (i) => i, growable: someGrowable);

bool someGrowable = true;

void main() {
  someGrowable = !someGrowable;
  print([list1, list2, list3, list4]);
}
