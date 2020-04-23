// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

/// A class that should be ignored but it used embed the type signatures
/// actually being tested.
class Embed<T> {}

Type extractType<T>() => T;
Type nonNullableFutureOrOf<T>() => extractType<FutureOr<T>>();

final nullableFutureOfNull = extractType<Future<Null>?>();
final embeddedNullableFutureOfNull = extractType<Embed<Future<Null>?>>();
