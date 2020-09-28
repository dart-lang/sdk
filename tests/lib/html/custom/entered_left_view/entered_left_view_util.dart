// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entered_left_view_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;

import 'package:async_helper/async_minitest.dart';

import '../utils.dart';

var invocations = [];

class Foo extends HtmlElement {
  Foo.created() : super.created() {
    invocations.add('created');
  }

  void attached() {
    invocations.add('attached');
  }

  void enteredView() {
    // Deprecated name. Should never be called since we override "attached".
    invocations.add('enteredView');
  }

  void detached() {
    invocations.add('detached');
  }

  void leftView() {
    // Deprecated name. Should never be called since we override "detached".
    invocations.add('leftView');
  }

  void attributeChanged(String name, String oldValue, String newValue) {
    invocations.add('attribute changed');
  }
}

// Test that the deprecated callbacks still work.
class FooOldCallbacks extends HtmlElement {
  FooOldCallbacks.created() : super.created() {
    invocations.add('created');
  }

  void enteredView() {
    invocations.add('enteredView');
  }

  void leftView() {
    invocations.add('leftView');
  }

  void attributeChanged(String name, String oldValue, String newValue) {
    invocations.add('attribute changed');
  }
}

var docA = document;
var docB = document.implementation!.createHtmlDocument('');
var nullSanitizer = new NullTreeSanitizer();

setupFunc() {
  // Adapted from Blink's
  // fast/dom/custom/attached-detached-document.html test.
  return customElementsReady.then((_) {
    document.registerElement2('x-a', {'prototype': Foo});
    document.registerElement2('x-a-old', {'prototype': FooOldCallbacks});
  });
}
