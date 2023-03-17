// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:typed_data';

// NativeType is not private, because it is used in type arguments.
// NativeType is abstract because it not used with const constructors in
// annotations directly, so it should never be instantiated at runtime.
@patch
@pragma("vm:entry-point")
abstract final class NativeType {}

@patch
@pragma("vm:entry-point")
final class _NativeInteger extends NativeType {}

@patch
@pragma("vm:entry-point")
final class _NativeDouble extends NativeType {}

@patch
@pragma("vm:entry-point")
final class Int8 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Int16 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Int32 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Int64 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Uint8 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Uint16 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Uint32 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Uint64 extends _NativeInteger {}

@patch
@pragma("vm:entry-point")
final class Float extends _NativeDouble {}

@patch
@pragma("vm:entry-point")
final class Double extends _NativeDouble {}

@patch
@pragma("vm:entry-point")
abstract final class Bool extends NativeType {}

@patch
@pragma("vm:entry-point")
abstract final class Void extends NativeType {}

@patch
@pragma("vm:entry-point")
abstract final class Handle extends NativeType {}

@patch
@pragma("vm:entry-point")
abstract final class NativeFunction<T extends Function> extends NativeType {}

@patch
@pragma("vm:entry-point")
abstract final class VarArgs<T extends Record> extends NativeType {}
