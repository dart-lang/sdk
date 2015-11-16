// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.js_interop;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/constant.dart';

bool _isJsLibType(String expectedName, Element e) =>
    e?.name == expectedName && _isJsLib(e.library);

bool _isJsLib(LibraryElement e) {
  var libName = e?.name;
  return libName == 'js' ||
      libName == 'js.varargs' ||
      libName == 'dart._js_helper';
}

bool isJsRestAnnotation(DartObjectImpl value) =>
    _isJsLibType('_Rest', value.type.element);

bool isJsSpreadInvocation(MethodInvocation i) =>
    _isJsLibType('spread', i.methodName?.bestElement);

// TODO(jmesserly): Move JsPeerInterface to package:js (see issue #135).
bool isJSAnnotation(DartObjectImpl value) => value.type.name == 'JS';

bool isJsPeerInterface(DartObjectImpl value) =>
    value.type.name == 'JsPeerInterface';
