// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// The supertype of all FFI struct types.
///
/// FFI struct types should extend this class and declare fields corresponding
/// to the underlying native structure.
///
/// Field declarations in a [Struct] subclass declaration are automatically
/// given a setter and getter implementation which accesses the native struct's
/// field in memory.
///
/// All field declarations in a [Struct] subclass declaration must either have
/// type [int] or [float] and be annotated with a [NativeType] representing the
/// native type, or must be of type [Pointer]. For example:
///
/// ```
/// typedef struct {
///  int a;
///  float b;
///  void* c;
/// } my_struct;
/// ```
///
/// ```
/// class MyStruct extends Struct {
///   @Int32
///   external int a;
///
///   @Float
///   external double b;
///
///   external Pointer<Void> c;
/// }
/// ```
///
/// All field declarations in a [Struct] subclass declaration must be marked
/// `external`. You cannot create instances of the class, only have it point to
/// existing native memory, so there is no memory in which to store non-native
/// fields. External fields also cannot be initialized by constructors since no
/// Dart object is being created.
///
/// Instances of a subclass of [Struct] have reference semantics and are backed
/// by native memory. The may allocated via allocation or loaded from a
/// [Pointer], but cannot be created by a generative constructor.
abstract class Struct extends NativeType {
  @pragma("vm:entry-point")
  final Object _addressOf;

  /// Construct a reference to the [nullptr].
  ///
  /// Use [StructPointer]'s `.ref` to gain references to native memory backed
  /// structs.
  Struct() : _addressOf = nullptr;

  Struct._fromPointer(this._addressOf);
}

/// Extension on [Struct] specialized for its subtypes.
extension StructAddressOf<T extends Struct> on T {
  /// Returns the address backing the reference.
  Pointer<T> get addressOf => _addressOf as Pointer<T>;
}
