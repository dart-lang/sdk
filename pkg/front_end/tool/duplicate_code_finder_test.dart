// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'duplicate_code_finder_experiment.dart';

void main() {
  exactlySameLine();
  sameLineDifferentIndentation();
}

Uri testUri = Uri.parse("test://uri.dart");

void exactlySameLine() {
  // Can find exactly the same lines.
  List<Duplicate> result = findDuplicates({
    testUri: """
if (whatever()) {
  Foo f = new Foo();
  f.partA();
  f.partB();
  f.partC();
} else {
  print("Else case");
  Foo f = new Foo();
  f.partA();
  f.partB();
  f.partC();
}
""",
  });
  if (result.length != 1) throw "Didn't find exactly 1 result; got $result";
  String s = result.single.toString();
  if (!s.contains("Foo f = new Foo ( ) ;") ||
      !s.contains("f . partA ( ) ;") ||
      !s.contains("f . partB ( ) ;") ||
      !s.contains("f . partC ( ) ;")) {
    throw "Didn't contain expected, was $s";
  }
}

void sameLineDifferentIndentation() {
  // Can find exactly the same lines.
  List<Duplicate> result = findDuplicates({
    testUri: """
if (whatever()) {
  Foo f = new Foo();
  f.partA();
  f.partB();
  f.partC();
} else {
  if (something()) {
    print("Else case with something");
  } else {
    Foo f = new Foo();
    f.partA();
    f.partB();
    f.partC();
  }
}
""",
  });
  if (result.length != 1) throw "Didn't find exactly 1 result; got $result";
  String s = result.single.toString();
  if (!s.contains("Foo f = new Foo ( ) ;") ||
      !s.contains("f . partA ( ) ;") ||
      !s.contains("f . partB ( ) ;") ||
      !s.contains("f . partC ( ) ;")) {
    throw "Didn't contain expected, was $s";
  }
}
