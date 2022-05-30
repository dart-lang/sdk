// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

test1(dynamic stringList) {
  var intSet = <int>{...?stringList};
}

test2(dynamic stringList) {
  var intList = <int>[...?stringList];
}

test3(dynamic stringMap) {
  var intMap = <int, int>{...?stringMap};
}

main() {
  dynamic stringList = ['string'];
  Expect.throwsTypeError(() {
    test1(stringList);
  });
  Expect.throwsTypeError(() {
    test2(stringList);
  });

  dynamic stringMap = {'a': 'b'};
  Expect.throwsTypeError(() {
    test3(stringMap);
  });
}
