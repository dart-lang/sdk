// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test("Creation with parameters", () {
    var font = new FontFace('Ahem', 'url(Ahem.ttf)', {'variant': 'small-caps'});
    expect(font is FontFace, isTrue);
    expect(font.family, 'Ahem');
    expect(font.variant, 'small-caps');
  });
}
