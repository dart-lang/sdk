// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class TypeArgumentsRef extends ObjectRef {
  /// A name for this type argument list.
  String? get name;
}

abstract class TypeArguments extends Object implements TypeArgumentsRef {
  /// A list of types.
  ///
  /// The value will always be one of the kinds:
  /// Type, TypeRef, TypeParameter.
  Iterable<InstanceRef>? get types;
}
