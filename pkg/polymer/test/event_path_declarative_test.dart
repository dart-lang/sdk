// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is ported from event-path-declarative-test.dart in polymer/test/html/.
// While the original test was intended to test event.path support, we changed
// the test structure just to check that the event was handled in the expected
// order.
library polymer.test.event_path_declarative_test;

import 'dart:async';
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

var _observedEvents = [];
var _testFired;

main() => initPolymer();

@reflectable
class XZug extends PolymerElement {

  XZug.created() : super.created();

  ready() {
    shadowRoot.on['test-event'].listen((e) {
      _testFired.complete(null);
    });
  }


  contentTestEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }

  divTestEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }

  testEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }
}

@reflectable
class XFoo extends PolymerElement {
  XFoo.created() : super.created();

  contentTestEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }

  divTestEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }

  testEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }
}

@reflectable
class XBar extends PolymerElement {
  XBar.created() : super.created();

  contentTestEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }

  divTestEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }

  testEventHandler(e, detail, sender) {
    _observedEvents.add(sender);
  }
}

@initMethod init() {
  useHtmlConfiguration();
  // TODO(sigmund): switch back to use @CustomTag. We seem to be running into a
  // problem where using @CustomTag doesn't guarantee that we register the tags
  // in the following order (the query from mirrors is non deterministic).
  // We shouldn't care about registration order though. See dartbug.com/14459
  Polymer.register('x-zug', XZug);
  Polymer.register('x-foo', XFoo);
  Polymer.register('x-bar', XBar);

  _testFired = new Completer();

  setUp(() => Polymer.onReady);
  test('event paths', () {
    var target = document.querySelector('#target');
    target.dispatchEvent(new CustomEvent('test-event', canBubble: true));
    return _testFired.future.then((_) {
      var xBar = querySelector('x-bar');
      var xBarDiv = xBar.shadowRoot.querySelector('#xBarDiv');
      var xBarContent = xBar.shadowRoot.querySelector('#xBarContent');
      var xFoo = xBar.shadowRoot.querySelector('x-foo');
      var xFooDiv = xFoo.shadowRoot.querySelector('#xFooDiv');
      var xFooContent = xFoo.shadowRoot.querySelector('#xFooContent');
      var xZug = xFoo.shadowRoot.querySelector('x-zug');
      var xZugDiv = xZug.shadowRoot.querySelector('#xZugDiv');
      var xZugContent = xZug.shadowRoot.querySelector('#xZugContent');

      var expectedPath = [ xBarContent, xBarDiv, xFooContent,
          xZugContent, xZugDiv, xZug, xFooDiv, xFoo, xBar];
      debugName(e) => '${e.localName}#${e.id}';
      expect(_observedEvents, expectedPath, reason:
        '<br>\nexpected: ${expectedPath.map(debugName).join(',')}'
        '<br>\nactual: ${_observedEvents.map(debugName).join(',')}'
        );
    });
  });
}
