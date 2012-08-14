#library('HiddenDom1Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

// Test that the dart:html API does not leak native jsdom methods:
//   onfocus setter.

main() {
  useHtmlConfiguration();

  test('test1', () {
    document.body.elements.add(new Element.html(@'''
<div id='div1'>
Hello World!
</div>'''));
    Element e = document.query('#div1');
    Expect.isTrue(e != null);

    checkNoSuchMethod(() { confuse(e).onfocus = null; });
  });

}

class Decoy {
  void set onfocus(x) { throw 'dead code'; }
}

confuse(x) => opaqueTrue() ? x : (opaqueTrue() ? new Object() : new Decoy());

/** Returns [:true:], but in a way that confuses the compiler. */
opaqueTrue() => true;  // Expand as needed.

checkNoSuchMethod(action()) {
  var ex = null;
  try {
    action();
  } catch (var e) {
    ex = e;
  }
  if (ex === null)
    Expect.fail('Action should have thrown exception');

  Expect.isTrue(ex is NoSuchMethodException, 'ex is NoSuchMethodException');
}
