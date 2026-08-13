// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@pragma('external-effect')
external void externalEffect(Object? o);

void noExternalEffect(Object? o) {}

List<Object> used = [];

Null use(int o) {
  used.add(o);
  return null;
}

const Object constObj = Object();

Null useConstObject() {
  used.add(constObj);
  return null;
}

void main() {
  externalEffect(use(3));
  externalEffect(useConstObject());
  Expect.isTrue(used.isEmpty);
  noExternalEffect(use(4));
  noExternalEffect(useConstObject());
  Expect.equals(used.length, 2);
  Expect.equals(used[0], 4);
  Expect.equals(used[1], constObj);
}
