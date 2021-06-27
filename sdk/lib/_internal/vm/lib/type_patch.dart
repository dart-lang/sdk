// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// These Dart classes correspond to the VM internal implementation classes.

// Equivalent of AbstractTypeLayout.
abstract class _AbstractType implements Type {
  String toString() native "AbstractType_toString";
}

// Equivalent of TypeLayout.
@pragma("vm:entry-point")
class _Type extends _AbstractType {
  factory _Type._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  int get hashCode native "Type_getHashCode";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  bool operator ==(other) native "Type_equality";
}

// Equivalent of FunctionTypeLayout.
@pragma("vm:entry-point")
class _FunctionType extends _AbstractType {
  factory _FunctionType._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  int get hashCode native "FunctionType_getHashCode";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  bool operator ==(other) native "FunctionType_equality";
}

// Equivalent of TypeRefLayout.
@pragma("vm:entry-point")
class _TypeRef extends _AbstractType {
  factory _TypeRef._uninstantiable() {
    throw "Unreachable";
  }
}

// Equivalent of TypeParameterLayout.
@pragma("vm:entry-point")
class _TypeParameter extends _AbstractType {
  factory _TypeParameter._uninstantiable() {
    throw "Unreachable";
  }
}
