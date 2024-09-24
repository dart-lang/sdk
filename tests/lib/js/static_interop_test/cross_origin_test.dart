// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `JSAny?` can be used in some guaranteed ways to interact with
// cross-origin objects.

import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS('Object.is')
external bool _is(CrossOriginWindow a, CrossOriginWindow b);

@JS()
external Window get window;

@JS('document.body.append')
external void append(HTMLIFrameElement iframe);

@JS('document.createElement')
external JSObject _createElement(String tag);

HTMLIFrameElement createIFrame() => HTMLIFrameElement(_createElement('iframe'));

// Should be aligned with the members used in `cross_origin.dart` from
// `package:web`.
extension type CrossOriginWindow(JSAny? _) {
  external bool get closed;
  external int get length;
  external CrossOriginLocation get location;
  @JS('location')
  external set locationString(String value);
  external CrossOriginWindow get opener;
  external CrossOriginWindow get parent;
  external CrossOriginWindow get top;
  external CrossOriginWindow get frames;
  external CrossOriginWindow get self;
  external CrossOriginWindow get window;
  external void blur();
  external void close();
  external void focus();
  external void postMessage(
    JSAny? message, [
    JSAny optionsOrTargetOrigin,
    JSArray<JSObject> transfer,
  ]);
}

extension type Window(CrossOriginWindow _) implements CrossOriginWindow {
  external CrossOriginWindow open(String url);
}

// Should be aligned with the members used in `cross_origin.dart` from
// `package:web`.
extension type CrossOriginLocation(JSAny? _) {
  external void replace(String url);
  external set href(String value);
}

extension type HTMLIFrameElement(JSObject _) implements JSObject {
  external CrossOriginWindow get contentWindow;
  external set src(String value);
}

void main() {
  const url = 'https://www.google.com';
  const url2 = 'https://www.example.org';

  void testCommon(CrossOriginWindow crossOriginWindow) {
    Expect.equals(crossOriginWindow.length, 0);
    Expect.isFalse(crossOriginWindow.closed);
    crossOriginWindow.location.replace(url2);
    crossOriginWindow.location.href = url;
    crossOriginWindow.locationString = url2;
    crossOriginWindow.postMessage('hello world'.toJS);
    crossOriginWindow.postMessage('hello world'.toJS, url2.toJS);
    crossOriginWindow.postMessage('hello world'.toJS, url2.toJS, JSArray());
    crossOriginWindow.blur();
    crossOriginWindow.focus();
    crossOriginWindow.close();
  }

  final openedWindow = window.open(url);
  Expect.isTrue(_is(openedWindow.opener, window));
  Expect.isTrue(_is(openedWindow.parent, openedWindow));
  Expect.isTrue(_is(openedWindow.top, openedWindow));
  Expect.isTrue(_is(openedWindow.frames, openedWindow));
  Expect.isTrue(_is(openedWindow.self, openedWindow));
  Expect.isTrue(_is(openedWindow.window, openedWindow));
  testCommon(openedWindow);
  Expect.isTrue(openedWindow.closed);

  final iframe = createIFrame();
  iframe.src = url;
  append(iframe);
  final contentWindow = iframe.contentWindow;
  Expect.isTrue(_is(contentWindow.opener, CrossOriginWindow(null)));
  Expect.isTrue(_is(contentWindow.parent, window));
  Expect.isTrue(_is(contentWindow.top, window.top));
  Expect.isTrue(_is(contentWindow.frames, contentWindow));
  Expect.isTrue(_is(contentWindow.self, contentWindow));
  Expect.isTrue(_is(contentWindow.window, contentWindow));
  testCommon(contentWindow);
  Expect.isFalse(contentWindow.closed);
}
