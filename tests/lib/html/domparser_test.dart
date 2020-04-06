// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isDomParser = predicate((x) => x is DomParser, 'is a DomParser');

  test('constructorTest', () {
    var ctx = new DomParser();
    expect(ctx, isNotNull);
    expect(ctx, isDomParser);
  });
}
