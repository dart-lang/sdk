// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that type checks work properly for Legacy JS Objects across generic
// boundaries.

import 'dart:html';
import "dart:js" as js;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:js/js.dart' as pkgJs;

class TestGenericClass<X> {
  X x;
  TestGenericClass(this.x);

  directCast(p) {
    return p as PackageJSClass<String>;
  }

  typeArgCast(p) {
    return p as X;
  }
}

@pkgJs.JS()
class PackageJSClass<T> {
  external factory PackageJSClass(T x);
}

void main() {
  js.context.callMethod("eval", [
    """
    window.PackageJSClass = function PackageJSClass(x) {
      this.x = x;
    };
  """
  ]);

  var instance =
      TestGenericClass<PackageJSClass<JSString>>(PackageJSClass("Hello".toJS));
  print(instance.directCast(PackageJSClass("Hello".toJS)));
  print(instance.typeArgCast(PackageJSClass("Hello".toJS)));
}
