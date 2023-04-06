// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An implementation of the JS interop classes which are usable from the
// Dart SDK. These types need to stay in-sync with
// https://github.com/dart-lang/sdk/blob/master/pkg/js/lib/js.dart
library _js_annotations;

export 'dart:js_util' show allowInterop, allowInteropCaptureThis;

class JS {
  final String? name;
  const JS([this.name]);
}

class _Anonymous {
  const _Anonymous();
}

class _StaticInterop {
  const _StaticInterop();
}

const _Anonymous anonymous = _Anonymous();

const _StaticInterop staticInterop = _StaticInterop();

class JSExport {
  final String name;
  const JSExport([this.name = '']);
}
