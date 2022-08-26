// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var list1 = <int>[0];
  var list2 = <int?>[0];
  dynamic list3 = <int>[0];
  var list = <int?>[0, ...list1, ...list2, ...list3, if (true) 2];

  var set1 = <int>{0};
  var set2 = <int?>{0};
  dynamic set3 = <int>{0};
  var set = <int?>{0, ...set1, ...set2, ...set3, if (true) 2};

  var map1 = <int, String>{0: 'foo'};
  var map2 = <int?, String?>{0: 'bar'};
  dynamic map3 = <int, String>{0: 'baz'};
  var map = <int?, String?>{
    0: 'foo',
    ...map1,
    ...map2,
    ...map3,
    if (true) 2: 'baz'
  };
}
