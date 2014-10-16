library fontface_loaded_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:html';

class NullTreeSanitizer implements NodeTreeSanitizer {
    void sanitizeTree(Node node) {}
}

main() {
  useHtmlConfiguration();

  var style = new Element.html('''
      <style>
      @font-face {
        font-family: 'Ahem';
        src: url(../../resources/Ahem.ttf);
        font-style: italic;
        font-weight: 300;
        unicode-range: U+0-3FF;
        font-variant: small-caps;
        -webkit-font-feature-settings: "dlig" 1;
        /* font-stretch property is not supported */
      }
      </style>
      ''', treeSanitizer: new NullTreeSanitizer());
  document.head.append(style);


  test('document fonts - temporary', () {
    var atLeastOneFont = false;
    document.fonts.forEach((FontFace fontFace, _, __) {
      atLeastOneFont = true;
      Future f1 = fontFace.loaded;
      Future f2 = fontFace.loaded;
      expect(f1, equals(f2)); // Repeated calls should answer the same Future.

      expect(fontFace.load(), throws);
    });
    expect(atLeastOneFont, isTrue);
  });
}
