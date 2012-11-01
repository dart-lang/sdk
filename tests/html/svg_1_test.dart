library SVG1Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

// Test that SVG is present in dart:html API

main() {
  useHtmlConfiguration();

  var isSVGElement = predicate((x) => x is SVGElement, 'is a SVGElement');

  test('simpleRect', () {
      var div = new Element.tag('div');
      document.body.nodes.add(div);
      div.innerHTML = r'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>

''';

    var e = document.query('#svg1');
    expect(e, isNotNull);

    SVGRectElement r = document.query('#rect1');
    expect(r.x.baseVal.value, 10);
    expect(r.y.baseVal.value, 20);
    expect(r.height.baseVal.value, 40);
    expect(r.width.baseVal.value, 130);
    expect(r.rx.baseVal.value, 5);
  });

  test('trailing newline', () {
    // Ensures that we handle SVG with trailing newlines.
    var logo = new SVGElement.svg("""
      <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
        <path/>
      </svg>
      """);

  expect(logo, isSVGElement);

  });
}
