// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// Represents a dynamically loaded C library.
class DynamicLibrary {
  /// Creates a dynamic library holding all global symbols.
  ///
  /// Any symbol in a library currently loaded with global visibility (including
  /// the executable itself) may be resolved in this library.
  ///
  /// This feature is not available on Windows, instead an exception is thrown.
  external factory DynamicLibrary.process();

  /// Creates a dynamic library representing the running executable.
  external factory DynamicLibrary.executable();

  /// Loads a dynamic library file with local visibility.
  ///
  /// Throws an [ArgumentError] if loading the dynamic library fails.
  ///
  /// Calling this function multiple times, even in different isolates, returns
  /// objects which are equal but not identical. The underlying library is only
  /// loaded once into the DartVM by the OS.
  external factory DynamicLibrary.open(String name);

  /// Looks up a symbol in the [DynamicLibrary] and returns its address in
  /// memory. Equivalent of dlsym.
  ///
  /// Throws an [ArgumentError] if it fails to lookup the symbol.
  external Pointer<T> lookup<T extends NativeType>(String symbolName);

  /// Dynamic libraries are equal if they load the same library.
  external bool operator ==(Object other);

  /// The hash code for a DynamicLibrary only depends on the loaded library
  external int get hashCode;

  /// The handle to the dynamic library.
  external Pointer<Void> get handle;
}

/// Methods which cannot be invoked dynamically.
extension DynamicLibraryExtension on DynamicLibrary {
  /// Helper that combines lookup and cast to a Dart function.
  external F lookupFunction<T extends Function, F extends Function>(
      String symbolName);
}
