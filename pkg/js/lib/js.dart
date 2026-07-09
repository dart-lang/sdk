// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// > [!CAUTION]
/// > This package is discontinued. Prefer using
/// > [`dart:js_interop`](https://api.dart.dev/dart-js_interop/dart-js_interop-library.html)
/// > for JS interop. See the
/// > [JS interop documentation](https://dart.dev/interop/js-interop) for more
/// > details.
@Deprecated('Use dart:js_interop instead')
library;

// ignore: EXPORT_INTERNAL_LIBRARY
export 'dart:_js_annotations'
    show JS, anonymous, staticInterop, trustTypes, JSExport;
export 'dart:js_util' show allowInterop, allowInteropCaptureThis;
