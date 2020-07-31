// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:nnbd_migration/instrumentation.dart';

String _computeElementName(Element element) {
  List<String> parts = [];
  while (element != null && element is! CompilationUnitElement) {
    var name = element.name;
    if (name == null || name.isEmpty) {
      parts.add('<unnamed>');
    } else {
      parts.add(name);
    }
    element = element.enclosingElement;
  }
  if (parts.isEmpty) {
    assert(false, 'Could not compute a name for $element');
    return '<unknown>';
  }
  return parts.reversed.join('.');
}

/// Data structure tracking information about which type in the user's source
/// code is referenced by a given nullability node.
abstract class NullabilityNodeTarget {
  /// Creates a [NullabilityNodeTarget] referring to a particular element.
  factory NullabilityNodeTarget.element(
          Element element, LineInfo Function(String) getLineInfo) =
      _NullabilityNodeTarget_Element;

  /// Creates a [NullabilityNodeTarget] with a simple text description.
  factory NullabilityNodeTarget.text(String name) = _NullabilityNodeTarget_Text;

  /// Creates a new [NullabilityNodeTarget] representing the bound of a type
  /// parameter.
  factory NullabilityNodeTarget.typeParameterBound(
      TypeParameterElement element) = _NullabilityNodeTarget_TypeParameterBound;

  NullabilityNodeTarget._();

  /// The source code location associated with this target, if known.  Otherwise
  /// `null`.
  CodeReference get codeReference => null;

  /// Gets a short description of this nullability node target suitable for
  /// displaying to the user, not including a code reference.
  String get description;

  /// Same as [description], but if there is a [codeReference], it is included
  /// after the description in parentheses.
  String get displayName {
    if (codeReference == null) return description;
    return '$description (${codeReference.shortName})';
  }

  NullabilityNodeTarget get supertype => _NullabilityNodeTarget_Supertype(this);

  /// Creates a new [NullabilityNodeTarget] representing a named function
  /// parameter of this target.
  NullabilityNodeTarget namedParameter(String name) =>
      _NullabilityNodeTarget_NamedParameter(this, name);

  /// Creates a new [NullabilityNodeTarget] representing a positional function
  /// parameter of this target.
  NullabilityNodeTarget positionalParameter(int index) =>
      _NullabilityNodeTarget_PositionalParameter(this, index);

  /// Creates a new [NullabilityNodeTarget] representing a function return type
  /// of this target.
  NullabilityNodeTarget returnType() => _NullabilityNodeTarget_ReturnType(this);

  /// Creates a new [NullabilityNodeTarget] representing a type argument of this
  /// target.
  NullabilityNodeTarget typeArgument(int index) =>
      _NullabilityNodeTarget_TypeArgument(this, index);

  /// Creates a new [NullabilityNodeTarget] representing the bound of a formal
  /// function type parameter of this target.
  NullabilityNodeTarget typeFormalBound(String typeFormalName) =>
      _NullabilityNodeTarget_TypeFormalBound(this, typeFormalName);

  /// Creates a [NullabilityNodeTarget] referring to a particular point in the
  /// source code.
  NullabilityNodeTarget withCodeRef(AstNode astNode) =>
      _NullabilityNodeTarget_CodeRef(this, astNode);
}

/// Nullability node target representing a reference to a specific location in
/// source code.
class _NullabilityNodeTarget_CodeRef extends NullabilityNodeTarget {
  final NullabilityNodeTarget inner;

  final CodeReference codeReference;

  _NullabilityNodeTarget_CodeRef(this.inner, AstNode astNode)
      : codeReference = CodeReference.fromAstNode(astNode),
        super._();

  @override
  String get description => inner.description;
}

/// Nullability node target representing the type of an element.
class _NullabilityNodeTarget_Element extends NullabilityNodeTarget {
  final String name;

  final CodeReference codeReference;

  _NullabilityNodeTarget_Element(
      Element element, LineInfo Function(String) getLineInfo)
      : name = _computeElementName(element),
        codeReference = CodeReference.fromElement(element, getLineInfo),
        super._();

  @override
  String get description => name;
}

/// Nullability node target representing the type of a named function parameter.
class _NullabilityNodeTarget_NamedParameter
    extends _NullabilityNodeTarget_Part {
  final String name;

  _NullabilityNodeTarget_NamedParameter(NullabilityNodeTarget inner, this.name)
      : super(inner);

  @override
  String get description => 'parameter $name of ${inner.description}';
}

/// Nullability node target representing a type that forms part of a larger type
/// (e.g. the `int` part of `List<int>`).
abstract class _NullabilityNodeTarget_Part extends NullabilityNodeTarget {
  final NullabilityNodeTarget inner;

  _NullabilityNodeTarget_Part(this.inner) : super._();

  @override
  CodeReference get codeReference => inner.codeReference;
}

/// Nullability node target representing the type of a positional function
/// parameter.
class _NullabilityNodeTarget_PositionalParameter
    extends _NullabilityNodeTarget_Part {
  final int index;

  _NullabilityNodeTarget_PositionalParameter(
      NullabilityNodeTarget inner, this.index)
      : super(inner);

  @override
  String get description => 'parameter $index of ${inner.description}';
}

/// Nullability node target representing a function's return type.
class _NullabilityNodeTarget_ReturnType extends _NullabilityNodeTarget_Part {
  _NullabilityNodeTarget_ReturnType(NullabilityNodeTarget inner) : super(inner);

  @override
  String get description => 'return type of ${inner.description}';
}

/// Nullability node target representing one of a class's supertypes.
class _NullabilityNodeTarget_Supertype extends _NullabilityNodeTarget_Part {
  _NullabilityNodeTarget_Supertype(NullabilityNodeTarget inner) : super(inner);

  @override
  String get description => 'supertype of ${inner.description}';
}

/// Nullability node target for which we only know a string description.
class _NullabilityNodeTarget_Text extends NullabilityNodeTarget {
  final String name;

  _NullabilityNodeTarget_Text(this.name) : super._();

  @override
  String get description => name;
}

/// Nullability node target representing a type argument of an interface type or
/// or typedef.
class _NullabilityNodeTarget_TypeArgument extends _NullabilityNodeTarget_Part {
  final int index;

  _NullabilityNodeTarget_TypeArgument(NullabilityNodeTarget inner, this.index)
      : super(inner);

  @override
  String get description => 'type argument $index of ${inner.description}';
}

/// Nullability node target representing a bound of a function type's formal
/// type parameter.
class _NullabilityNodeTarget_TypeFormalBound
    extends _NullabilityNodeTarget_Part {
  final String typeFormalName;

  _NullabilityNodeTarget_TypeFormalBound(
      NullabilityNodeTarget inner, this.typeFormalName)
      : super(inner);

  @override
  String get description =>
      'bound of type formal $typeFormalName of ${inner.description}';
}

/// Nullability node target representing a type parameter bound.
class _NullabilityNodeTarget_TypeParameterBound extends NullabilityNodeTarget {
  final String name;

  _NullabilityNodeTarget_TypeParameterBound(TypeParameterElement element)
      : name = _computeElementName(element),
        super._();

  @override
  String get description => 'bound of $name';
}
