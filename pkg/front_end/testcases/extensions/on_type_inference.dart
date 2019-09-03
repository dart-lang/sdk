// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension BestCom<T extends num> on Iterable<T> {
  T best() => null;
}
extension BestList<T> on List<T> {
  T best() => null;
}
extension BestSpec on List<num> {
 num best() => null;
}

main() {
  List<int> x;
  var v = x.best();
  List<num> y;
  var w = y.best();
}