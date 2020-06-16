// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// All imports must be in all FFI patch files to not depend on the order
// the patches are applied.
import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';

// NativeType is not private, because it is used in type arguments.
// NativeType is abstract because it not used with const constructors in
// annotations directly, so it should never be instantiated at runtime.
@patch
@pragma("vm:entry-point")
abstract class NativeType {}

@patch
@pragma("vm:entry-point")
class _NativeInteger extends NativeType {}

@patch
@pragma("vm:entry-point")
class _NativeDouble extends NativeType {}

@patch
@pragma("vm:entry-point")
class Int8 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Int16 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Int32 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Int64 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Uint8 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Uint16 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Uint32 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Uint64 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class IntPtr extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
class Float extends _NativeDouble {}

@patch
@pragma("vm:entry-point")
class Double extends _NativeDouble {}

@patch
@pragma("vm:entry-point")
abstract class Void extends NativeType {}

@patch
@pragma("vm:entry-point")
abstract class Handle extends NativeType {}

@patch
@pragma("vm:entry-point")
abstract class NativeFunction<T extends Function> extends NativeType {}
