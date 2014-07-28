// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:polymer/auto_binding.dart';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

class TestModel {
  var greeting = 'Hi';
  eventAction(e) {
    e.detail.add('handled');
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('elements upgraded', () {
    AutoBindingElement template = document.getElementById('one');
    template.model = new TestModel();

    var completer = new Completer();
    var events = 0;
    window.addEventListener('template-bound', (e) {
      events++;
      if (e.target.id == 'one') {
        expect(e.target, template);

        var t = template;
        var h = t.$['h'];
        expect(h.text, t.model.greeting, reason: 'binding applied');
        var ce = t.fire('tap', onNode: h, detail: []);
        expect(ce.detail, ['handled'], reason: 'element event handler fired');
      }

      if (events == 3) completer.complete();
    });

    /// test dynamic creation
    new Future(() {
      var d = new DivElement();
      d.setInnerHtml('<template is="auto-binding">Dynamical'
          ' <input value="{{value}}"><div>{{value}}</div></template>',
          treeSanitizer: new _NullSanitizer());
      document.body.append(d);
    });

    return completer.future;
  });
});

class _NullSanitizer implements NodeTreeSanitizer {
  sanitizeTree(Node node) {}
}
