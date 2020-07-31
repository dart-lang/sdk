// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const list0 = /*cfe.List<dynamic>()*/ [];

// TODO(johnniwinther): This seems like an odd offset for the constant. It
// should probably be at the start of the type arguments.
const list1 = <int> /*cfe.List<int>()*/ [];

const List<int> list2 = /*cfe.List<int>()*/ [];

const list3 = /*cfe.List<int>(Int(42))*/ [42];

const list4 = /*cfe.List<int>(Int(42),Int(87))*/ [42, 87];

main() {
  print(/*List<dynamic>()*/ list0);
  print(
      /*cfe|analyzer.List<int>()*/ /*dart2js.List<int*>()*/ list1);
  print(
      /*cfe|analyzer.List<int>()*/ /*dart2js.List<int*>()*/ list2);
  print(
      /*cfe|analyzer.List<int>(Int(42))*/ /*dart2js.List<int*>(Int(42))*/ list3);
  print(
      /*cfe|analyzer.List<int>(Int(42),Int(87))*/ /*dart2js.List<int*>(Int(42),Int(87))*/ list4);
}
