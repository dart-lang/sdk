// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that Dart mocks for `dart:html` classes are recognized as
// `dart:js_interop` JSObjects.
//
// This is expected to work for DDC and dart2js but not dart2wasm.

import 'package:expect/expect.dart';

import 'dart:js_interop' as dartJsInterop;
import 'dart:html' show window, Window, Document, HtmlDocument;

class MockWindow implements Window {
  Document get document => MockDocument();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDocument implements HtmlDocument {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testIs(MockWindow(), true);
  testIs(window, false);

  testAs(MockWindow(), true);
  testAs(window, false);
}

void testIs(Window w, bool isMock) {
  Expect.type<Window>(w);
  Expect.type<dartJsInterop.JSObject>(w);

  final doc = w.document;

  Expect.type<HtmlDocument>(doc);
  Expect.type<dartJsInterop.JSObject>(doc);

  if (isMock) {
    Expect.type<MockWindow>(w);
    Expect.type<MockDocument>(doc);
    Expect.isTrue(w is MockWindow);
    Expect.isTrue(doc is MockDocument);
  } else {
    Expect.isFalse(w is MockWindow);
    Expect.isFalse(doc is MockDocument);
  }
}

void testAs(Window w, bool isMock) {
  asCheck<Window>(w);
  asCheck<dartJsInterop.JSObject>(w);

  final doc = w.document;

  asCheck<HtmlDocument>(doc);
  asCheck<dartJsInterop.JSObject>(doc);

  if (isMock) {
    asCheck<MockWindow>(w);
    asCheck<MockDocument>(doc);
    w as MockWindow;
    doc as MockDocument;
  } else {
    Expect.throws(() => asCheck<MockWindow>(w));
    Expect.throws(() => asCheck<MockDocument>(doc));
    Expect.throws(() => w as MockWindow);
    Expect.throws(() => doc as MockDocument);
  }

  asCheck<String>('hello');
  Expect.throws(() => asCheck<String>(w));
}

@pragma('dart2js:never-inline')
void asCheck<T>(Object? o) => o as T;
