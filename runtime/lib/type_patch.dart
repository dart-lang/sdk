// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// These Dart classes correspond to the VM internal implementation classes.

// Equivalent of RawAbstractType.
abstract class _AbstractType implements Type {
  String toString() native "AbstractType_toString";
}

// Equivalent of RawType.
class _Type extends _AbstractType {}

// Equivalent of RawTypeRef.
class _TypeRef extends _AbstractType {}

// Equivalent of RawTypeParameter.
class _TypeParameter extends _AbstractType {}

// Equivalent of RawBoundedType.
class _BoundedType extends _AbstractType {}

// Equivalent of RawMixinAppType.
class _MixinAppType extends _AbstractType {}
