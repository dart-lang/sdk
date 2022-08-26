// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(dynamic y) async {
  var a = await (<X>(List<X> Function() x, X x2) => x2)(() => y, throw 0);
}

main() {}
