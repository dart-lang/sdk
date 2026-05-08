// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(paulberry): Would `targets.dart` be a better name for this file? It
// currently contains some classes called `TypeInstantiationTarget...` and some
// called `InvocationTarget...`.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

/// An entity in the program being analyzed that might have ordinary arguments
/// (and possibly type arguments) applied to it.
sealed class InvocationTarget extends TypeInstantiationTarget {
  /// The function type of the thing being invoked, prior to type argument
  /// instantiation.
  FunctionTypeImpl get rawType;
}

/// Invocation target representing a constructor.
class InvocationTargetConstructorElement
    extends InvocationTargetExecutableElement {
  @override
  final FunctionTypeImpl rawType;

  InvocationTargetConstructorElement(super.element, this.rawType);

  @override
  LocatableDiagnostic wrongNumberOfTypeArgumentsError({
    required int typeParameterCount,
    required int typeArgumentCount,
  }) {
    // The element being invoked is a constructor, so report that the enclosing
    // class has the wrong number of type parameters, because that's where the
    // type parameters are declared.
    var enclosingElement = element.enclosingElement!;
    return diag.wrongNumberOfTypeArgumentsElement.withArguments(
      kind: enclosingElement.kind.displayName,
      element: enclosingElement.displayName,
      typeParameterCount: typeParameterCount,
      typeArgumentCount: typeArgumentCount,
    );
  }
}

/// Invocation target representing an executable element (for example, a method
/// or a top level function).
class InvocationTargetExecutableElement extends TypeInstantiationTargetElement
    implements InvocationTarget {
  @override
  final ExecutableElement element;

  InvocationTargetExecutableElement(this.element) {
    assert(
      this is InvocationTargetConstructorElement ||
          element is! ConstructorElement,
      'constructors should use TypeInstantiationTargetConstructorElement',
    );
  }

  @override
  FunctionTypeImpl get rawType =>
      // TODO(paulberry): get rid of this cast.
      element.type as FunctionTypeImpl;

  @override
  LocatableDiagnostic wrongNumberOfTypeArgumentsError({
    required int typeParameterCount,
    required int typeArgumentCount,
  }) {
    return diag.wrongNumberOfTypeArgumentsElement.withArguments(
      kind: element.kind.displayName,
      element: element.displayName,
      typeParameterCount: typeParameterCount,
      typeArgumentCount: typeArgumentCount,
    );
  }

  /// If [element] is not `null`, returns a
  /// [InvocationTargetExecutableElement] that corresponds to it.
  /// Otherwise returns `null`.
  static InvocationTargetExecutableElement? orNull(
    ExecutableElement? element,
  ) => element == null ? null : InvocationTargetExecutableElement(element);
}

/// Invocation target representing an extension override.
class InvocationTargetExtensionOverride extends InvocationTarget {
  final ExtensionElementImpl element;
  final FunctionTypeImpl type;

  InvocationTargetExtensionOverride({
    required this.element,
    required this.type,
  });

  @override
  FunctionTypeImpl get rawType => type;

  @override
  LocatableDiagnostic wrongNumberOfTypeArgumentsError({
    required int typeParameterCount,
    required int typeArgumentCount,
  }) {
    // In theory, this code should never be reached, because if the number of
    // type arguments is wrong, `ExtensionMemberResolver._inferTypeArguments`
    // will report the error and replace them with a list of `dynamic` of the
    // appropriate length.
    assert(false);

    // However, to avoid a crash in production code in case that theory is
    // wrong, go ahead and return the appropriate error.
    return diag.wrongNumberOfTypeArgumentsExtension.withArguments(
      extensionName: element.name!,
      typeParameterCount: typeParameterCount,
      typeArgumentCount: typeArgumentCount,
    );
  }
}

/// Invocation target representing a function typed expression.
class InvocationTargetFunctionTypedExpression extends InvocationTarget {
  final FunctionTypeImpl type;

  InvocationTargetFunctionTypedExpression(this.type);

  @override
  FunctionTypeImpl get rawType => type;

  @override
  LocatableDiagnostic wrongNumberOfTypeArgumentsError({
    required int typeParameterCount,
    required int typeArgumentCount,
  }) {
    assert(type.typeParameters.length == typeParameterCount);
    return diag.wrongNumberOfTypeArgumentsFunction.withArguments(
      type: type,
      typeParameterCount: typeParameterCount,
      typeArgumentCount: typeArgumentCount,
    );
  }

  /// If [type] is a function type, returns a
  /// [InvocationTargetFunctionTypedExpression] that corresponds to it.
  /// Otherwise returns `null`.
  static InvocationTargetFunctionTypedExpression? orNull(DartType? type) =>
      type is FunctionTypeImpl
      ? InvocationTargetFunctionTypedExpression(type)
      : null;
}

/// An entity in the program being analyzed that might have type arguments
/// applied to it.
sealed class TypeInstantiationTarget {
  const TypeInstantiationTarget();

  /// Creates the appropriate diagnostic message when the wrong number of type
  /// arguments is applied.
  LocatableDiagnostic wrongNumberOfTypeArgumentsError({
    required int typeParameterCount,
    required int typeArgumentCount,
  });
}

/// Type instantiation target representing the type `dynamic`.
class TypeInstantiationTargetDynamicTypeElement
    extends TypeInstantiationTargetTypeDefiningElement {
  const TypeInstantiationTargetDynamicTypeElement();

  @override
  DynamicElementImpl get element => DynamicElementImpl.instance;
}

/// Type instantiation target backed by an element.
sealed class TypeInstantiationTargetElement extends TypeInstantiationTarget {
  const TypeInstantiationTargetElement();

  Element get element;
}

/// Type instantiation target representing an ordinary interface type.
class TypeInstantiationTargetInterfaceElement
    extends TypeInstantiationTargetTypeDefiningElement {
  @override
  final InterfaceElement element;

  TypeInstantiationTargetInterfaceElement(this.element);
}

/// Type instantiation target representing the type `Never`.
class TypeInstantiationTargetNeverTypeElement
    extends TypeInstantiationTargetTypeDefiningElement {
  const TypeInstantiationTargetNeverTypeElement();

  @override
  NeverElementImpl get element => NeverElementImpl.instance;
}

/// Type instantiation target representing a type defined by a type alias.
class TypeInstantiationTargetTypeAliasElement
    extends TypeInstantiationTargetTypeDefiningElement {
  @override
  final TypeAliasElement element;

  TypeInstantiationTargetTypeAliasElement(this.element);
}

/// Type instantiation target representing a type in the program being analyzed.
sealed class TypeInstantiationTargetTypeDefiningElement
    extends TypeInstantiationTargetElement {
  const TypeInstantiationTargetTypeDefiningElement();

  @override
  LocatableDiagnostic wrongNumberOfTypeArgumentsError({
    required int typeParameterCount,
    required int typeArgumentCount,
  }) {
    return diag.wrongNumberOfTypeArguments.withArguments(
      type: element.displayName,
      typeParameterCount: typeParameterCount,
      typeArgumentCount: typeArgumentCount,
    );
  }
}

/// Type instantiation target representing a type parameter.
class TypeInstantiationTargetTypeParameterElement
    extends TypeInstantiationTargetTypeDefiningElement {
  @override
  final TypeParameterElement element;

  TypeInstantiationTargetTypeParameterElement(this.element);
}
