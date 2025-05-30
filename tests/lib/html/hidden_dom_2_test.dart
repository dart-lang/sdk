// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package

// Test that the dart:html API does not leak native jsdom methods:
//   appendChild operation.

main() {
  test('test1', () {
    document.body!.children.add(
      new Element.html(r'''
<div id='div1'>
Hello World!
</div>'''),
    );
    Element? e = document.querySelector('#div1');
    Element e2 = new Element.html(r"<div id='xx'>XX</div>");
    expect(e, isNotNull);

    expect(() {
      confuse(e!).appendChild(e2);
    }, throwsNoSuchMethodError);
  });
}

class Decoy {
  void appendChild(x) {
    throw 'dead code';
  }
}

confuse(x) => opaqueTrue() ? x : (opaqueTrue() ? new Object() : new Decoy());

/** Returns `true`, but in a way that confuses the compiler. */
opaqueTrue() => true; // Expand as needed.
