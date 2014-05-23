// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';
import 'package:template_binding/template_binding.dart';

Future<List<MutationRecord>> onMutation(Node node) {
  var completer = new Completer();
  new MutationObserver((mutations, observer) {
    observer.disconnect();
    completer.complete(mutations);
  })..observe(node, childList: true, subtree: true);
  return completer.future;
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  var ready = Polymer.onReady.then((_) {
    var a = querySelector("#a");
    templateBind(a).model = "foo";
    return onMutation(a.parent);
  });

  setUp(() => ready);

  test('template found with multiple noscript declarations', () {
    expect(querySelector('x-a').shadowRoot.nodes.first.text, 'a');
    expect(querySelector('x-c').shadowRoot.nodes.first.text, 'c');
    expect(querySelector('x-b').shadowRoot.nodes.first.text, 'b');
    expect(querySelector('x-d').shadowRoot.nodes.first.text, 'd');
  });
});
