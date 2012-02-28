// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testDocumentFragment() {
  group('constructors', () {
    test('.xml parses input as XML', () {
      final fragment = new DocumentFragment.xml('<a>foo</a>');
      Expect.isTrue(fragment.elements.first is XMLElement);
    });
  });
}
