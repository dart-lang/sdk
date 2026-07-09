// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression for https://github.com/dart-lang/sdk/issues/51307
///
/// The interceptor for JavaScriptObjects was not emitted if the only
/// uses were implicit through a cast and no direct instantiation.

import 'dart:js_interop' hide JS;

import 'package:js/js.dart';

@JS()
@staticInterop
class A {}

extension E on A {
  external int get value;
}

void main() => <String, Object>{'value': 1}.jsify() as A;
