// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The actual functionality exposed by this package is implemented in
// "dart:_internal" since it is specific to each platform's runtime
// implementation. This package exists as a shell to expose that internal API
// to outside code.
//
// Only this exact special file is allowed to import "dart:_internal" without
// causing a compile error.
// ignore: import_internal_library
import 'dart:_internal' as internal;

/// Given an [Iterable], invokes [extract], passing the [iterable]'s type
/// argument as the type argument to the generic function.
///
/// Example:
///
/// ```dart
/// Object iterable = <int>[];
/// print(extractIterableTypeArgument(iterable, <T>() => new Set<T>());
/// // Prints "Instance of 'Set<int>'".
/// ```
Object? extractIterableTypeArgument(
        Iterable iterable, Object? Function<T>() extract) =>
    internal.extractTypeArguments<Iterable>(iterable, extract);

/// Given a [Map], invokes [extract], passing the [map]'s key and value type
/// arguments as the type arguments to the generic function.
///
/// Example:
///
/// ```dart
/// class Two<A, B> {}
///
/// main() {
///   Object map = <String, int>{};
///   print(extractMapTypeArguments(map, <K, V>() => new Two<K, V>());
///   // Prints "Instance of 'Two<String, int>'".
/// }
/// ```
Object? extractMapTypeArguments(Map map, Object? Function<K, V>() extract) =>
    internal.extractTypeArguments<Map>(map, extract);
