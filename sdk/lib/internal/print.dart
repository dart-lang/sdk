// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:_internal";

/// This function is set by the first `Zone` with a print handler.
///
/// Once the function is set the core `print` function calls this closure instead
/// of [printToConsole].
///
/// This decouples the `dart:core` library from the `dart:async` library.
external void Function(String)? get printToZone;
external set printToZone(void Function(String)? value);

/// Default behavior of `print` when no zones override it.
external void printToConsole(String line);
