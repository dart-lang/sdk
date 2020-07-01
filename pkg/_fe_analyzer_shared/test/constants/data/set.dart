// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: sdk_version_set_literal
const Set set0 = /*cfe.Set<dynamic>()*/ {};

// TODO(johnniwinther): This seems like an odd offset for the constant. It
// should probably be at the start of the type arguments.
// ignore: sdk_version_set_literal
const set1 = <int> /*cfe.Set<int>()*/ {};

// ignore: sdk_version_set_literal
const Set<int> set2 = /*cfe.Set<int>()*/ {};

// ignore: sdk_version_set_literal
const set3 = /*cfe.Set<int>(Int(42))*/ {42};

// ignore: sdk_version_set_literal
const set4 = /*cfe.Set<int>(Int(42),Int(87))*/ {42, 87};

main() {
  print(/*Set<dynamic>()*/ set0);
  print(
      /*cfe|analyzer.Set<int>()*/ /*dart2js.Set<int*>()*/ set1);
  print(
      /*cfe|analyzer.Set<int>()*/ /*dart2js.Set<int*>()*/ set2);
  print(
      /*cfe|analyzer.Set<int>(Int(42))*/ /*dart2js.Set<int*>(Int(42))*/ set3);
  print(
      /*cfe|analyzer.Set<int>(Int(42),Int(87))*/ /*dart2js.Set<int*>(Int(42),Int(87))*/ set4);
}
