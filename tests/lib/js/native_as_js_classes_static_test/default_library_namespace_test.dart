// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors with a library with the default namespace.

@JS()
library default_library_namespace_test;

import 'package:js/js.dart';

// Test same class name as a native class.
@JS()
class HTMLDocument {}
//    ^
// [web] Non-static JS interop class 'HTMLDocument' conflicts with natively supported class 'HtmlDocument' in 'dart:html'.

// Test same annotation name as a native class.
@JS('HTMLDocument')
class HtmlDocument {}
//    ^
// [web] Non-static JS interop class 'HtmlDocument' conflicts with natively supported class 'HtmlDocument' in 'dart:html'.

// Test annotation name with 'self' and 'window' prefixes.
@JS('self.Window')
class WindowWithSelf {}
//    ^
// [web] Non-static JS interop class 'WindowWithSelf' conflicts with natively supported class 'Window' in 'dart:html'.

@JS('window.Window')
class WindowWithWindow {}
//    ^
// [web] Non-static JS interop class 'WindowWithWindow' conflicts with natively supported class 'Window' in 'dart:html'.

@JS('self.window.self.window.self.Window')
class WindowWithMultipleSelfsAndWindows {}
//    ^
// [web] Non-static JS interop class 'WindowWithMultipleSelfsAndWindows' conflicts with natively supported class 'Window' in 'dart:html'.

// Test annotation with native class name but with a prefix that isn't 'self' or
// 'window'.
@JS('foo.Window')
class WindowWithDifferentPrefix {}

// Test same class name as a native class with multiple annotation names.
// dart:html.Window uses both "Window" and "DOMWindow".
@JS()
class DOMWindow {}
//    ^
// [web] Non-static JS interop class 'DOMWindow' conflicts with natively supported class 'Window' in 'dart:html'.

// Test same annotation name as a native class with multiple annotation names
// dart:html.Window uses both "Window" and "DOMWindow".
@JS('DOMWindow')
class DomWindow {}
//    ^
// [web] Non-static JS interop class 'DomWindow' conflicts with natively supported class 'Window' in 'dart:html'.

// Test different annotation name but with same class name as a @Native class.
@JS('Foo')
class Window {}

// Dart classes don't have to worry about conflicts.
class Element {}

// Anonymous classes don't have to worry about conflicts either.
@JS()
@anonymous
class HTMLElement {}

@JS('HTMLElement')
@anonymous
class HtmlElement {}

void main() {}
