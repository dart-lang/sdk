// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:expect/minitest.dart';

class Mock {
  noSuchMethod(Invocation i) => document;
}

@proxy
class MockBodyElement extends Mock implements BodyElement {
  Node append(Node e) => e;
}

class _EventListeners {
  Stream<Event> get onBlur => new Stream.fromIterable([]);
}

@proxy
class MockHtmlDocument extends Mock
    with _EventListeners
    implements HtmlDocument {
  BodyElement get body => new MockBodyElement();
}

@proxy
class MockWindow extends Mock with _EventListeners implements Window {
  Stream<Event> get onBeforeUnload => new Stream.fromIterable([]);

  String name = "MOCK_NAME";
}

@proxy
class MockLocation extends Mock implements Location {
  String href = "MOCK_HREF";
}

main() {
  test('is', () {
    var win = new MockWindow();
    expect(win is Window, isTrue);
  });

  test('getter', () {
    var win = new MockWindow();
    expect(win.document, equals(document));
  });

  test('override', () {
    Window win = new MockWindow();
    expect(win.onBeforeUnload != null, isTrue);
    expect(win.name, equals("MOCK_NAME"));
  });

  test('override', () {
    var loc1 = new MockLocation();
    Location loc2 = loc1;
    dynamic loc3 = loc1;
    expect(loc1.href, equals("MOCK_HREF"));
    loc1.href = "RESET";
    expect(loc2.href, equals("RESET"));
    loc2.href = "RESET2";
    expect(loc3.href, equals("RESET2"));
  });

  test('method', () {
    HtmlDocument doc = new MockHtmlDocument();
    expect(doc.body.append(null), equals(null));
  });

  test('mixin', () {
    Window win = new MockWindow();
    expect(win.onBlur is Stream, isTrue, reason: 'onBlur should be a stream');
    HtmlDocument doc = new MockHtmlDocument();
    expect(doc.onBlur is Stream, isTrue, reason: 'onBlur should be a stream');
  });
}
