// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('content_supported', () {
    expect(ContentElement.supported, true);
  });
}
