// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on int {
  syncStarMethod() sync* {}
  asyncMethod() async {}
  asyncStarMethod() async* {}
}

main() {
  0.syncStarMethod();
  0.syncStarMethod;
  0.asyncMethod();
  0.asyncMethod;
  0.asyncStarMethod();
  0.asyncStarMethod;
}
