// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors with a library with a global namespace.

@JS('window')
library global_library_namespace_test;

import 'package:js/js.dart';

@JS()
class HTMLDocument {}
//    ^
// [web] Non-static JS interop class 'HTMLDocument' conflicts with natively supported class 'HtmlDocument' in 'dart:html'.

@JS('HTMLDocument')
class HtmlDocument {}
//    ^
// [web] Non-static JS interop class 'HtmlDocument' conflicts with natively supported class 'HtmlDocument' in 'dart:html'.

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

@JS('foo.Window')
class WindowWithDifferentPrefix {}

@JS()
class DOMWindow {}
//    ^
// [web] Non-static JS interop class 'DOMWindow' conflicts with natively supported class 'Window' in 'dart:html'.

@JS('DOMWindow')
class DomWindow {}
//    ^
// [web] Non-static JS interop class 'DomWindow' conflicts with natively supported class 'Window' in 'dart:html'.

@JS('Foo')
class Window {}

class Element {}

@JS()
@anonymous
class HTMLElement {}

@JS('HTMLElement')
@anonymous
class HtmlElement {}

void main() {}
