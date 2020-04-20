import 'dart:html';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

main() async {
  await customElementsReady;

  test('can register custom template with webcomponents-lite polyfill', () {
    document.registerElement2(
        'my-element', {'prototype': MyElement, 'extends': 'template'});
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
