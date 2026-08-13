// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void fn<T, S>(T? t, S? s) {
  var x = [t!, s!];
  List<Object> y = x; // Ok.
}

main() {}
