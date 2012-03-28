#library('SVG1Test');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

// Test that SVG is present in dart:dom API

main() {
  forLayoutTests();

  test('simpleRect', () {
      var div = document.createElement('div');
      document.body.appendChild(div);
      div.innerHTML = @'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>
''';

    var e = document.getElementById('svg1');
    Expect.isTrue(e != null);

    SVGRectElement r = document.getElementById('rect1');
    Expect.equals(10, r.x.baseVal.value);
    Expect.equals(20, r.y.baseVal.value);
    Expect.equals(40, r.height.baseVal.value);
    Expect.equals(130, r.width.baseVal.value);
    Expect.equals(5, r.rx.baseVal.value);
  });
}
