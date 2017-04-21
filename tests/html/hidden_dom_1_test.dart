library HiddenDom1Test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

// Test that the dart:html API does not leak native jsdom methods:
//   onfocus setter.

main() {
  useHtmlConfiguration();

  test('test1', () {
    document.body.children.add(new Element.html(r'''
<div id='div1'>
Hello World!
</div>'''));
    Element e = document.query('#div1');
    expect(e, isNotNull);

    checkNoSuchMethod(() {
      confuse(e).onfocus = null;
    });
  });
}

class Decoy {
  void set onfocus(x) {
    throw 'dead code';
  }
}

confuse(x) => opaqueTrue() ? x : (opaqueTrue() ? new Object() : new Decoy());

/** Returns [:true:], but in a way that confuses the compiler. */
opaqueTrue() => true; // Expand as needed.

checkNoSuchMethod(action()) {
  var ex = null;
  try {
    action();
  } catch (e) {
    ex = e;
  }
  if (ex == null)
    expect(false, isTrue, reason: 'Action should have thrown exception');

  expect(ex, isNoSuchMethodError);
}
