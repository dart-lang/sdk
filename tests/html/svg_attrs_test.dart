// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library SVGTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:svg';

main() {
  useHtmlConfiguration();

  test('svg parsed attributes', () {
    var content = """
<svg version="1.1"
    xmlns:xlink="http://www.w3.org/1999/xlink">
  <image xlink:href="foo.jpg"/>
</svg>""";

    var svg = new SvgElement.svg(content);
    var img = svg.children[0];
    expect(img is ImageElement, isTrue);
    var attrs = img.attributes;
    expect(attrs.length, 0);

    var xlinkAttrs =
        img.getNamespacedAttributes('http://www.w3.org/1999/xlink');
    expect(xlinkAttrs.length, 1);
    expect(xlinkAttrs['href'], 'foo.jpg');

    // validate that the namespaced attr was set by waiting for the image
    // to fail to load.
    return img.onError.first;
  });

  test('svg explicit attributes', () {

    var img = new ImageElement();
    var xlinkAttrs =
        img.getNamespacedAttributes('http://www.w3.org/1999/xlink');
    xlinkAttrs['href'] = 'foo.jpg';

    // validate that the namespaced attr was set by waiting for the image
    // to fail to load.
    return img.onError.first;
  });
}
