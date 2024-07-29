// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(int? x) {
  var y1 = [?x];
  var y2 = [1, ?x];
  var y3 = [1.0, ?x];
}

test2(dynamic x) {
  List<String> y1 = [?x];
  List<String> y2 = ["", ?x];
  var y3 = ["", ?x];
}
