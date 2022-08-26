// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// [NativeType]'s subtypes represent a native type in C.
///
/// [NativeType]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
abstract class NativeType {
  const NativeType();
}

/// [Opaque]'s subtypes represent opaque types in C.
///
/// [Opaque]'s subtypes are not constructible in the Dart code and serve purely
/// as markers in type signatures.
@Since('2.12')
abstract class Opaque extends NativeType {}

/// [_NativeInteger]'s subtypes represent a native integer in C.
///
/// [_NativeInteger]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
class _NativeInteger extends NativeType {
  const _NativeInteger();
}

/// [_NativeDouble]'s subtypes represent a native float or double in C.
///
/// [_NativeDouble]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
class _NativeDouble extends NativeType {
  const _NativeDouble();
}

/// Represents a native signed 8 bit integer in C.
///
/// [Int8] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
class Int8 extends _NativeInteger {
  const Int8();
}

/// Represents a native signed 16 bit integer in C.
///
/// [Int16] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
class Int16 extends _NativeInteger {
  const Int16();
}

/// Represents a native signed 32 bit integer in C.
///
/// [Int32] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
class Int32 extends _NativeInteger {
  const Int32();
}

/// Represents a native signed 64 bit integer in C.
///
/// [Int64] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
class Int64 extends _NativeInteger {
  const Int64();
}

/// Represents a native unsigned 8 bit integer in C.
///
/// [Uint8] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
class Uint8 extends _NativeInteger {
  const Uint8();
}

/// Represents a native unsigned 16 bit integer in C.
///
/// [Uint16] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
class Uint16 extends _NativeInteger {
  const Uint16();
}

/// Represents a native unsigned 32 bit integer in C.
///
/// [Uint32] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
class Uint32 extends _NativeInteger {
  const Uint32();
}

/// Represents a native unsigned 64 bit integer in C.
///
/// [Uint64] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
class Uint64 extends _NativeInteger {
  const Uint64();
}

/// Represents a native 32 bit float in C.
///
/// [Float] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
class Float extends _NativeDouble {
  const Float();
}

/// Represents a native 64 bit double in C.
///
/// [Double] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
class Double extends _NativeDouble {
  const Double();
}

/// Represents a native bool in C.
///
/// [Bool] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
@Since('2.15')
class Bool extends NativeType {
  const Bool();
}

/// Represents a void type in C.
///
/// [Void] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
@unsized
abstract class Void extends NativeType {}

/// Represents `Dart_Handle` in C.
///
/// [Handle] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
@Since('2.9')
abstract class Handle extends NativeType {}

/// Represents a function type in C.
///
/// [NativeFunction] is not constructible in the Dart code and serves purely as
/// marker in type signatures.
@unsized
abstract class NativeFunction<T extends Function> extends NativeType {}
