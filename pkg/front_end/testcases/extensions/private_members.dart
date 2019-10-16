// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'private_members_lib.dart';

main() {
  test();

  expect(123, "".publicMethod2());
  expect(123, PublicExtension("").publicMethod2());

  expect(321, PublicExtension.publicStaticMethod2());
}

errors() {
  expect(42, "".publicMethod1());
  expect(87, ""._privateMethod1());
  expect(237, ""._privateMethod2());
  expect(473, "".publicMethod3());
  expect(586, ""._privateMethod3());

  expect(42, _PrivateExtension("").publicMethod1());
  expect(87, _PrivateExtension("")._privateMethod1());
  expect(237, PublicExtension("")._privateMethod2());

  expect(24, _PrivateExtension.publicStaticMethod1());
  expect(78, _PrivateExtension._privateStaticMethod1());
  expect(732, PublicExtension._privateStaticMethod2());
}
