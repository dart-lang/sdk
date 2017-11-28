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

  var style = new Element.html(
      '''
      <style>
      @font-face {
        font-family: 'Ahem';
        src: url(/root_dart/tests/html/Ahem.ttf);
        font-style: italic;
        font-weight: 300;
        unicode-range: U+0-3FF;
        font-variant: small-caps;
        -webkit-font-feature-settings: "dlig" 1;
        /* font-stretch property is not supported */
      }
      </style>
      ''',
      treeSanitizer: new NullTreeSanitizer());
  document.head.append(style);

  test('document fonts - temporary', () {
    var atLeastOneFont = false;
    var loaded = <Future>[];
    document.fonts.forEach((FontFace fontFace, _, __) {
      atLeastOneFont = true;
      Future f1 = fontFace.loaded;
      Future f2 = fontFace.loaded;
      loaded.add(fontFace.load());
      loaded.add(f1);
      loaded.add(f2);
    });
    expect(atLeastOneFont, isTrue);
    return Future.wait(loaded).then(expectAsync((_) {
      document.fonts.forEach((fontFace, _, __) {
        expect(fontFace.status, 'loaded');
      });
    }));
  });
}
