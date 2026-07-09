// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void optional_toplevel([List<int> x = const []]) {}

void named_toplevel({List<int> x = const []}) {}

main() {
  void optional_local([List<int> x = const []]) {}
  void named_local({List<int> x = const []}) {}
  var optional_closure = ([List<int> x = const []]) {};
  var name_closure = ({List<int> x = const []}) {};
}
