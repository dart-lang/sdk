// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// Represents a dynamically loaded C library.
class DynamicLibrary {
  /// Loads a dynamic library file. This is the equivalent of dlopen.
  ///
  /// Throws an [ArgumentError] if loading the dynamic library fails.
  ///
  /// Note that it loads the functions in the library lazily (RTLD_LAZY).
  external factory DynamicLibrary.open(String name);

  /// Looks up a symbol in the [DynamicLibrary] and returns its address in
  /// memory. Equivalent of dlsym.
  ///
  /// Throws an [ArgumentError] if it fails to lookup the symbol.
  external Pointer<T> lookup<T extends NativeType>(String symbolName);

  /// Helper that combines lookup and cast to a Dart function.
  F lookupFunction<T extends Function, F extends Function>(String symbolName) {
    return lookup<NativeFunction<T>>(symbolName)?.asFunction<F>();
  }

  /// Dynamic libraries are equal if they load the same library.
  external bool operator ==(other);

  /// The hash code for a DynamicLibrary only depends on the loaded library
  external int get hashCode;
}
