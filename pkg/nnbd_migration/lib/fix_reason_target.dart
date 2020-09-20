// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/utilities_general.dart';

/// Data structure representing a part of a type.  When a fix has multiple
/// reasons (due to a complex type having different nullabilities at different
/// locations), this data structure allows us to tell which part of the type
/// is associated with each reason.
abstract class FixReasonTarget {
  /// Fix reason target representing the full type, rather than a part of it.
  static const FixReasonTarget root = _FixReasonTarget_Root();

  const FixReasonTarget._();

  /// Gets a fix reason target representing the type's return type.
  FixReasonTarget get returnType => _FixReasonTarget_ReturnType(this);

  /// Returns a description of the fix reason target that's suitable for
  /// appending to a description of a nullability trace.
  ///
  /// For example, `root.returnType.suffix` returns ` for return type`.  This
  /// can be attached to a string like `nullability reason` to form
  /// `nullability reason for return type`.
  String get suffix => _describe('for');

  /// Gets a fix reason target representing the type's yielded type.  This
  /// represents the type argument of `Future` or `FutureOr`, or in the case
  /// where `await` is applied to a non-future type, the type itself.
  FixReasonTarget get yieldedType => _FixReasonTarget_YieldedType(this);

  /// Gets a fix reason target representing one of the type's named parameters.
  FixReasonTarget namedParameter(String name) =>
      _FixReasonTarget_NamedParameter(this, name);

  /// Gets a fix reason target representing one of the type's positional
  /// parameters.
  FixReasonTarget positionalParameter(int i) =>
      _FixReasonTarget_PositionalParameter(this, i);

  /// Gets a fix reason target representing one of the type's type arguments.
  FixReasonTarget typeArgument(int i) => _FixReasonTarget_TypeArgument(this, i);

  String _describe(String preposition);
}

/// Fix reason target representing a named parameter of a function type.
class _FixReasonTarget_NamedParameter extends _FixReasonTarget_Part {
  final String name;

  _FixReasonTarget_NamedParameter(FixReasonTarget inner, this.name)
      : super(inner);

  @override
  int get hashCode => JenkinsSmiHash.hash3(2, inner.hashCode, name.hashCode);

  @override
  bool operator ==(Object other) =>
      other is _FixReasonTarget_NamedParameter &&
      inner == other.inner &&
      name == other.name;

  @override
  String _describe(String preposition) =>
      ' $preposition parameter $name${inner._describe('of')}';
}

/// Fix reason target representing a type that forms part of a larger type (e.g.
/// the `int` part of `List<int>`).
abstract class _FixReasonTarget_Part extends FixReasonTarget {
  final FixReasonTarget inner;

  _FixReasonTarget_Part(this.inner) : super._();
}

/// Fix reason target representing a positional parameter of a function type.
class _FixReasonTarget_PositionalParameter extends _FixReasonTarget_Part {
  final int index;

  _FixReasonTarget_PositionalParameter(FixReasonTarget inner, this.index)
      : super(inner);

  @override
  int get hashCode => JenkinsSmiHash.hash3(1, inner.hashCode, index);

  @override
  bool operator ==(Object other) =>
      other is _FixReasonTarget_PositionalParameter &&
      inner == other.inner &&
      index == other.index;

  @override
  String _describe(String preposition) =>
      ' $preposition parameter $index${inner._describe('of')}';
}

/// Fix reason target representing the return type of a function type.
class _FixReasonTarget_ReturnType extends _FixReasonTarget_Part {
  _FixReasonTarget_ReturnType(FixReasonTarget inner) : super(inner);

  @override
  int get hashCode => JenkinsSmiHash.hash2(3, inner.hashCode);

  @override
  bool operator ==(Object other) =>
      other is _FixReasonTarget_ReturnType && inner == other.inner;

  @override
  String _describe(String preposition) =>
      ' $preposition return type${inner._describe('of')}';
}

/// Fix reason target representing the root of the type in question.
class _FixReasonTarget_Root extends FixReasonTarget {
  const _FixReasonTarget_Root() : super._();

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) => other is _FixReasonTarget_Root;

  @override
  String _describe(String preposition) => '';
}

/// Fix reason target representing a type argument of an interface type.
class _FixReasonTarget_TypeArgument extends _FixReasonTarget_Part {
  final int index;

  _FixReasonTarget_TypeArgument(FixReasonTarget inner, this.index)
      : super(inner);

  @override
  int get hashCode => JenkinsSmiHash.hash3(5, inner.hashCode, index);

  @override
  bool operator ==(Object other) =>
      other is _FixReasonTarget_TypeArgument &&
      inner == other.inner &&
      index == other.index;

  @override
  String _describe(String preposition) =>
      ' $preposition type argument $index${inner._describe('of')}';
}

/// Fix reason target representing the type argument of `Future` or `FutureOr`,
/// or in the case where `await` is applied to a non-future type, the type
/// itself.
///
/// This allows the migration tool to describe a type correspondence that exists
/// in a subtype check involving `FutureOr`, for example if the user tries to
/// assign `List<int?>` to `FutureOr<List<int*>>`, then the migration tool
/// determines that it needs to change `*` into `?`.  To make this determination
/// it has to form a correspondence between the type argument of the source type
/// and the type argument of the type argument of the destination type.  To
/// explain to the user which part of the two types is involved in the
/// correspondence, we need an ambiguous way of referring to either "type
/// argument of type argument of" or simply "type argument".  The solution is to
/// describe the fix reason target as "type argument of yielded type".
class _FixReasonTarget_YieldedType extends _FixReasonTarget_Part {
  _FixReasonTarget_YieldedType(FixReasonTarget inner) : super(inner);

  @override
  int get hashCode => JenkinsSmiHash.hash2(4, inner.hashCode);

  @override
  bool operator ==(Object other) =>
      other is _FixReasonTarget_YieldedType && inner == other.inner;

  @override
  String _describe(String preposition) =>
      ' $preposition yielded type${inner._describe('from')}';
}
