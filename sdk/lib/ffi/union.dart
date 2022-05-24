// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// The supertype of all FFI union types.
///
/// FFI union types should extend this class and declare fields corresponding
/// to the underlying native union.
///
/// Field declarations in a [Union] subclass declaration are automatically
/// given a setter and getter implementation which accesses the native union's
/// field in memory.
///
/// All field declarations in a [Union] subclass declaration must either have
/// type [int] or [double] and be annotated with a [NativeType] representing the
/// native type, or must be of type [Pointer]. For example:
///
/// ```c
/// typedef union {
///  int a;
///  float b;
///  void* c;
/// } my_union;
/// ```
///
/// ```dart
/// class MyUnion extends Union {
///   @Int32()
///   external int a;
///
///   @Float()
///   external double b;
///
///   external Pointer<Void> c;
/// }
/// ```
///
/// All field declarations in a [Union] subclass declaration must be marked
/// `external`. You cannot create instances of the class, only have it point to
/// existing native memory, so there is no memory in which to store non-native
/// fields. External fields also cannot be initialized by constructors since no
/// Dart object is being created.
///
/// Instances of a subclass of [Union] have reference semantics and are backed
/// by native memory. The may allocated via allocation or loaded from a
/// [Pointer], but cannot be created by a generative constructor.
@Since('2.14')
abstract class Union extends _Compound {
  /// Construct a reference to the [nullptr].
  ///
  /// Use [UnionPointer]'s `.ref` to gain references to native memory backed
  /// unions.
  Union() : super._();

  Union._fromTypedDataBase(Object typedDataBase)
      : super._fromTypedDataBase(typedDataBase);
}
