import 'dart:html';

import 'package:expect/minitest.dart';

// Test that the dart:html API does not leak native jsdom methods:
//   onfocus setter.

main() {
  test('test1', () {
    document.body.children.add(new Element.html(r'''
<div id='div1'>
Hello World!
</div>'''));
    Element e = document.query('#div1');
    expect(e, isNotNull);

    expect(() {
      confuse(e).onfocus = null;
    }, throwsNoSuchMethodError);
  });
}

class Decoy {
  void set onfocus(x) {
    throw 'dead code';
  }
}

confuse(x) => opaqueTrue() ? x : (opaqueTrue() ? new Object() : new Decoy());

/** Returns `true`, but in a way that confuses the compiler. */
opaqueTrue() => true; // Expand as needed.
