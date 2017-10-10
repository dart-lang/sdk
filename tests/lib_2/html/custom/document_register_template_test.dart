import 'dart:html';

import 'package:unittest/unittest.dart';

import '../utils.dart';

main() {
  setUp(() => customElementsReady);

  test('can register custom template with webcomponents-lite polyfill', () {
    document.registerElement('my-element', MyElement, extendsTag: 'template');
    dynamic e = new Element.tag('template', 'my-element');
    document.body.append(e);
    expect(e is TemplateElement, isTrue);
    expect(e.method(), 'value');
  });
}

class MyElement extends TemplateElement {
  MyElement.created() : super.created();
  method() => 'value';
}
