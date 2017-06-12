library HiddenDom2Test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

// Test that the dart:html API does not leak native jsdom methods:
//   appendChild operation.

main() {
  useHtmlConfiguration();

  test('test1', () {
    document.body.children.add(new Element.html(r'''
<div id='div1'>
Hello World!
</div>'''));
    Element e = document.query('#div1');
    Element e2 = new Element.html(r"<div id='xx'>XX</div>");
    expect(e, isNotNull);

    checkNoSuchMethod(() {
      confuse(e).appendChild(e2);
    });
  });
}

class Decoy {
  void appendChild(x) {
    throw 'dead code';
  }
}

confuse(x) => opaqueTrue() ? x : (opaqueTrue() ? new Object() : new Decoy());

/** Returns [:true:], but in a way that confuses the compiler. */
opaqueTrue() => true; // Expand as needed.

checkNoSuchMethod(action()) {
  var ex = null;
  bool threw = false;
  try {
    action();
  } catch (e) {
    threw = true;
    ex = e;
  }
  if (!threw)
    expect(false, isTrue, reason: 'Action should have thrown exception');

  expect(ex, isNoSuchMethodError);
}
