// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../static_type_helper.dart';

test(String? key, num? value) {
  var map1 = {key: value};
  var map2 = {?key: value};
  var map3 = {key: ?value};
  var map4 = {?key: ?value};

  map1.expectStaticType<Exactly<Map<String?, num?>>>();
  map2.expectStaticType<Exactly<Map<String, num?>>>();
  map3.expectStaticType<Exactly<Map<String?, num>>>();
  map4.expectStaticType<Exactly<Map<String, num>>>();
}

main() {
  test(null, null);
  test(null, 0);
  test("", null);
  test("", 0);
}
