// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fontface_loaded_test;

import 'package:async_helper/async_minitest.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:html';

class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}

main() {
  var style = new Element.html('''
      <style>
      @font-face {
        font-family: 'Ahem';
        src: url(/root_dart/tests/lib/html/Ahem.ttf);
        font-style: italic;
        font-weight: 300;
        unicode-range: U+0-3FF;
        font-variant: small-caps;
        -webkit-font-feature-settings: "dlig" 1;
        /* font-stretch property is not supported */
      }
      </style>
      ''', treeSanitizer: new NullTreeSanitizer());
  document.head!.append(style);

  test('document fonts - temporary', () async {
    var atLeastOneFont = false;
    var loaded = <Future<FontFace>>[];
    document.fonts!.forEach((FontFace fontFace, _, __) async {
      atLeastOneFont = true;
      var f1 = fontFace.loaded;
      var f2 = fontFace.loaded;
      loaded.add(fontFace.load());
      loaded.add(f1);
      loaded.add(f2);
    });
    expect(atLeastOneFont, isTrue);
    return Future.wait(loaded).then(expectAsync((_) async {
      document.fonts!.forEach((fontFace, _, __) {
        expect(fontFace.status, 'loaded');
      });
      expect(loaded.length, 3);
      for (var loadedEntry in loaded) {
        var fontFace = await loadedEntry;
        expect(fontFace.status, 'loaded');
        var fontFamily = fontFace.family!;
        if (fontFamily.startsWith('"')) {
          // FF wraps family in quotes - remove the quotes.
          fontFamily = fontFamily.substring(1, fontFamily.length - 1);
        }
        expect(fontFamily, 'Ahem');
      }
    }));
  });
}
