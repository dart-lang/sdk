// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@JS()
library util;

import 'package:js/js.dart';

@JS()
external void eval(String code);

@JS()
external makeDiv(String text);

// Static error to name @JS class the same as a @Native class, so we use a
// namespace `Foo` to avoid conflicting with the native class.
@JS('Foo.HTMLDivElement')
class HTMLDivElement {
  external String bar();
}

@JS('Foo.HTMLDivElement')
@staticInterop
class StaticHTMLDivElement {}

extension StaticHTMLDivElementExtension on StaticHTMLDivElement {
  external String bar();
  external StaticHTMLDivElement cloneNode(bool deep);
}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void setUpJS() {
  eval(r"""
  var Foo = {}

  // A constructor function with the same name as a HTML element.
  Foo.HTMLDivElement = function(a) {
    this.a = a;
  }

  Foo.HTMLDivElement.prototype.bar = function() {
    return this.a;
  }

  Foo.HTMLDivElement.prototype.toString = function() {
    return "HTMLDivElement(" + this.a + ")";
  }

  self.makeDiv = function(text) {
    return new Foo.HTMLDivElement(text);
  }
  """);
}
