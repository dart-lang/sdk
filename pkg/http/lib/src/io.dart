// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http.io;

@MirrorsUsed(targets: const ['dart.io.HttpClient', 'dart.io.HttpException',
  'dart.io.File'])
import 'dart:mirrors';

/// Whether `dart:io` is supported on this platform.
bool get supported => _library != null;

/// The `dart:io` library mirror, or `null` if it couldn't be loaded.
final _library = _getLibrary();

/// The `dart:io` HttpClient class mirror.
final ClassMirror _httpClient =
    _library.declarations[const Symbol('HttpClient')];

/// The `dart:io` HttpException class mirror.
final ClassMirror _httpException =
    _library.declarations[const Symbol('HttpException')];

/// The `dart:io` File class mirror.
final ClassMirror _file = _library.declarations[const Symbol('File')];

/// Asserts that the [name]d `dart:io` feature is supported on this platform.
///
/// If `dart:io` doesn't work on this platform, this throws an
/// [UnsupportedError].
void assertSupported(String name) {
  if (supported) return;
  throw new UnsupportedError("$name isn't supported on this platform.");
}

/// Creates a new `dart:io` HttpClient instance.
newHttpClient() => _httpClient.newInstance(const Symbol(''), []).reflectee;

/// Creates a new `dart:io` File instance with the given [path].
newFile(String path) => _file.newInstance(const Symbol(''), [path]).reflectee;

/// Returns whether [error] is a `dart:io` HttpException.
bool isHttpException(error) => reflect(error).type.isSubtypeOf(_httpException);

/// Returns whether [client] is a `dart:io` HttpClient.
bool isHttpClient(client) => reflect(client).type.isSubtypeOf(_httpClient);

/// Tries to load `dart:io` and returns `null` if it fails.
LibraryMirror _getLibrary() {
  try {
    return currentMirrorSystem().findLibrary(const Symbol('dart.io'));
  } catch (_) {
    // TODO(nweiz): narrow the catch clause when issue 18532 is fixed.
    return null;
  }
}
