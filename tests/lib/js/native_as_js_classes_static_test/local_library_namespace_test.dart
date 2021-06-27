// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors with a library with a non-default or non-global namespace.
// Note that none of the following should be errors in this case.

@JS('foo')
library global_library_namespace_test;

import 'package:js/js.dart';

@JS()
class HTMLDocument {}

@JS('HTMLDocument')
class HtmlDocument {}

@JS('self.Window')
class WindowWithSelf {}

@JS('window.Window')
class WindowWithWindow {}

@JS('self.window.self.window.self.Window')
class WindowWithMultipleSelfsAndWindows {}

@JS('foo.Window')
class WindowWithDifferentPrefix {}

@JS()
class DOMWindow {}

@JS('DOMWindow')
class DomWindow {}

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
