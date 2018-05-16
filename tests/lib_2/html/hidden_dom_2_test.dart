import 'dart:html';

import 'package:expect/minitest.dart';

// Test that the dart:html API does not leak native jsdom methods:
//   appendChild operation.

main() {
  test('test1', () {
    document.body.children.add(new Element.html(r'''
<div id='div1'>
Hello World!
</div>'''));
    Element e = document.querySelector('#div1');
    Element e2 = new Element.html(r"<div id='xx'>XX</div>");
    expect(e, isNotNull);

    expect(() {
      confuse(e).appendChild(e2);
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
