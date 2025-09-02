// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math" as math;

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';

class TypeArgumentsVerifier {
  final AnalysisOptions _options;
  final LibraryElement _libraryElement;
  final DiagnosticReporter _diagnosticReporter;

  TypeArgumentsVerifier(
    this._options,
    this._libraryElement,
    this._diagnosticReporter,
  );

  TypeSystemImpl get _typeSystem =>
      _libraryElement.typeSystem as TypeSystemImpl;

  void checkConstructorReference(ConstructorReferenceImpl node) {
    var classElement = node.constructorName.type.element;
    List<TypeParameterElementImpl> typeParameters;
    if (classElement is TypeAliasElementImpl) {
      typeParameters = classElement.typeParameters;
    } else if (classElement is InterfaceElementImpl) {
      typeParameters = classElement.typeParameters;
    } else {
      return;
    }

    if (typeParameters.isEmpty) {
      return;
    }

    for (var typeParameter in typeParameters) {
      if (typeParameter.name == null) {
        return;
      }
    }

    var typeArgumentList = node.constructorName.type.typeArguments;
    if (typeArgumentList == null) {
      return;
    }
    var constructorType = node.staticType;
    if (constructorType is DynamicType) {
      // An erroneous constructor reference.
      return;
    }
    if (constructorType is! FunctionType) {
      return;
    }
    var typeArguments = [
      for (var type in typeArgumentList.arguments) type.type!,
    ];
    if (typeArguments.length != typeParameters.length) {
      // Wrong number of type arguments to be reported elsewhere.
      return;
    }
    var typeArgumentListLength = typeArgumentList.arguments.length;
    var substitution = Substitution.fromPairs2(typeParameters, typeArguments);
    for (var i = 0; i < typeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeArgument = typeArguments[i];

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = substitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        var errorNode = i < typeArgumentListLength
            ? typeArgumentList.arguments[i]
            : node;
        _diagnosticReporter.atNode(
          errorNode,
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          arguments: [typeArgument, typeParameter.name!, bound],
        );
      }
    }
  }

  void checkEnumConstantDeclaration(EnumConstantDeclarationImpl node) {
    var constructorElement = node.constructorElement;
    if (constructorElement == null) {
      return;
    }

    var enumElement = constructorElement.enclosingElement;
    var typeParameters = enumElement.typeParameters;

    for (var typeParameter in typeParameters) {
      if (typeParameter.name == null) {
        return;
      }
    }

    var typeArgumentList = node.arguments?.typeArguments;
    var typeArgumentNodes = typeArgumentList?.arguments;
    if (typeArgumentList != null &&
        typeArgumentNodes != null &&
        typeArgumentNodes.length != typeParameters.length) {
      _diagnosticReporter.atNode(
        typeArgumentList,
        CompileTimeErrorCode.wrongNumberOfTypeArgumentsEnum,
        arguments: [typeParameters.length, typeArgumentNodes.length],
      );
    }

    if (typeParameters.isEmpty) {
      return;
    }

    // Check that type arguments are regular-bounded.
    var typeArguments = constructorElement.returnType.typeArguments;
    var substitution = Substitution.fromPairs2(typeParameters, typeArguments);
    for (var i = 0; i < typeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeArgument = typeArguments[i];

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = substitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        var errorTarget = typeArgumentNodes?[i] ?? node.name;
        _diagnosticReporter.atEntity(
          errorTarget,
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          arguments: [typeArgument, typeParameter.name!, bound],
        );
      }
    }
  }

  void checkFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // For some function expressions, like an implicit 'call' invocation, the
    // function type is on `node`'s `element`. For anonymous function
    // expressions, the function is on `node`'s `function`.
    // TODO(srawlins): It seems that `node.function`, the Expression, should
    // always have the static type of the `call` method.
    var functionType = node.element?.type ?? node.function.staticType;
    _checkInvocationTypeArguments(
      node.typeArguments?.arguments,
      functionType,
      node.staticInvokeType,
    );
  }

  void checkFunctionReference(FunctionReference node) {
    _checkInvocationTypeArguments(
      node.typeArguments?.arguments,
      node.function.staticType,
      node.staticType,
    );
  }

  void checkListLiteral(ListLiteral node) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        for (var argument in typeArguments.arguments) {
          _checkTypeArgumentConst(
            argument,
            CompileTimeErrorCode.invalidTypeArgumentInConstList,
          );
        }
      }
      _checkTypeArgumentCount(
        typeArguments,
        1,
        CompileTimeErrorCode.expectedOneListTypeArguments,
      );
    }
  }

  void checkMapLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        for (var argument in typeArguments.arguments) {
          _checkTypeArgumentConst(
            argument,
            CompileTimeErrorCode.invalidTypeArgumentInConstMap,
          );
        }
      }
      _checkTypeArgumentCount(
        typeArguments,
        2,
        CompileTimeErrorCode.expectedTwoMapTypeArguments,
      );
    }
  }

  void checkMethodInvocation(MethodInvocation node) {
    _checkInvocationTypeArguments(
      node.typeArguments?.arguments,
      node.function.staticType,
      node.staticInvokeType,
    );
  }

  void checkNamedType(NamedTypeImpl node) {
    _checkForTypeArgumentNotMatchingBounds(node);
    var parent = node.parent;
    if (parent is! ConstructorName ||
        parent.parent is! InstanceCreationExpression) {
      _checkForRawTypeName(node);
    }
  }

  void checkSetLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        for (var argument in typeArguments.arguments) {
          _checkTypeArgumentConst(
            argument,
            CompileTimeErrorCode.invalidTypeArgumentInConstSet,
          );
        }
      }
      _checkTypeArgumentCount(
        typeArguments,
        1,
        CompileTimeErrorCode.expectedOneSetTypeArguments,
      );
    }
  }

  /// Checks a type annotation for a raw generic type, and reports the
  /// appropriate error if [AnalysisOptions.strictRawTypes] is set.
  ///
  /// This checks if [node] refers to a generic type and does not have explicit
  /// or inferred type arguments. When that happens, it reports error code
  /// [WarningCode.strictRawType].
  void _checkForRawTypeName(NamedType node) {
    AstNode parentEscapingTypeArguments(NamedType node) {
      var parent = node.parent!;
      while (parent is TypeArgumentList || parent is NamedType) {
        var grandparent = parent.parent;
        if (grandparent == null) {
          return parent;
        }
        parent = grandparent;
      }
      return parent;
    }

    if (!_options.strictRawTypes) return;
    if (node.typeArguments != null) {
      // Type has explicit type arguments.
      return;
    }
    var type = node.typeOrThrow;
    if (_isMissingTypeArguments(node, type, node.element)) {
      AstNode unwrappedParent = parentEscapingTypeArguments(node);
      if (unwrappedParent is AsExpression ||
          unwrappedParent is CastPattern ||
          unwrappedParent is IsExpression ||
          unwrappedParent is ObjectPattern) {
        // Do not report a "Strict raw type" error in this case; too noisy.
        // See https://github.com/dart-lang/language/blob/master/resources/type-system/strict-raw-types.md#conditions-for-a-raw-type-hint
      } else {
        _diagnosticReporter.atNode(
          node,
          WarningCode.strictRawType,
          arguments: [type],
        );
      }
    }
  }

  /// Verify that the type arguments in the given [namedType] are all within
  /// their bounds.
  void _checkForTypeArgumentNotMatchingBounds(NamedTypeImpl namedType) {
    var type = namedType.type;
    if (type == null) {
      return;
    }

    List<TypeParameterElementImpl> typeParameters;
    String? elementName;
    List<TypeImpl> typeArguments;
    var alias = type.alias;
    if (alias != null) {
      elementName = alias.element.name;
      typeParameters = alias.element.typeParameters;
      typeArguments = alias.typeArguments;
    } else if (type is InterfaceTypeImpl) {
      elementName = type.element.name;
      typeParameters = type.element.typeParameters;
      typeArguments = type.typeArguments;
    } else {
      return;
    }

    if (elementName == null) {
      return;
    }

    if (typeParameters.isEmpty) {
      return;
    }

    // Check for regular-bounded.
    List<_TypeArgumentIssue>? issues;
    var substitution = Substitution.fromPairs2(typeParameters, typeArguments);
    for (var i = 0; i < typeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeParameterName = typeParameter.name;
      if (typeParameterName == null) {
        return;
      }

      var typeArgument = typeArguments[i];

      if (typeArgument is FunctionTypeImpl &&
          typeArgument.typeParameters.isNotEmpty) {
        if (!_libraryElement.featureSet.isEnabled(Feature.generic_metadata)) {
          _diagnosticReporter.atNode(
            _typeArgumentErrorNode(namedType, i),
            CompileTimeErrorCode.genericFunctionTypeCannotBeTypeArgument,
          );
          continue;
        }
      }

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = substitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        issues ??= <_TypeArgumentIssue>[];
        issues.add(
          _TypeArgumentIssue(
            i,
            typeParameter,
            typeParameterName,
            bound,
            typeArgument,
          ),
        );
      }
    }

    // If regular-bounded, we are done.
    if (issues == null) {
      return;
    }

    List<DiagnosticMessage>? buildContextMessages({
      List<DartType>? invertedTypeArguments,
    }) {
      var messages = <DiagnosticMessage>[];

      void addMessage(String message) {
        messages.add(
          DiagnosticMessageImpl(
            filePath: _diagnosticReporter.source.fullName,
            length: namedType.length,
            message: message,
            offset: namedType.offset,
            url: null,
          ),
        );
      }

      String typeArgumentsToString(List<DartType> typeArguments) {
        return typeArguments.map((e) => e.getDisplayString()).join(', ');
      }

      if (namedType.typeArguments == null) {
        var typeStr = '$elementName<${typeArgumentsToString(typeArguments)}>';
        addMessage(
          "The raw type was instantiated as '$typeStr', "
          "and is not regular-bounded.",
        );
      }

      if (invertedTypeArguments != null) {
        var invertedTypeStr =
            '$elementName<${typeArgumentsToString(invertedTypeArguments)}>';
        addMessage(
          "The inverted type '$invertedTypeStr' is also not regular-bounded, "
          "so the type is not well-bounded.",
        );
      }

      return messages.isNotEmpty ? messages : null;
    }

    // If not allowed to be super-bounded, report issues.
    if (!_shouldAllowSuperBoundedTypes(namedType)) {
      for (var issue in issues) {
        _diagnosticReporter.atNode(
          _typeArgumentErrorNode(namedType, issue.index),
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          arguments: [
            issue.argument,
            issue.parameterName,
            issue.parameterBound,
          ],
          contextMessages: buildContextMessages(),
        );
      }
      return;
    }

    // Prepare type arguments for checking for super-bounded.
    var invertedType = _typeSystem.replaceTopAndBottom(type);
    List<TypeImpl> invertedTypeArguments;
    var invertedAlias = invertedType.alias;
    if (invertedAlias != null) {
      invertedTypeArguments = invertedAlias.typeArguments;
    } else if (invertedType is InterfaceTypeImpl) {
      invertedTypeArguments = invertedType.typeArguments;
    } else {
      return;
    }

    // Check for super-bounded.
    var invertedSubstitution = Substitution.fromPairs2(
      typeParameters,
      invertedTypeArguments,
    );
    for (var i = 0; i < invertedTypeArguments.length; i++) {
      var typeParameter = typeParameters[i];
      var typeParameterName = typeParameter.name;
      if (typeParameterName == null) {
        return;
      }

      var typeArgument = invertedTypeArguments[i];

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = invertedSubstitution.substituteType(bound);

      if (!_typeSystem.isSubtypeOf(typeArgument, bound)) {
        _diagnosticReporter.atNode(
          _typeArgumentErrorNode(namedType, i),
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          arguments: [typeArgument, typeParameterName, bound],
          contextMessages: buildContextMessages(
            invertedTypeArguments: invertedTypeArguments,
          ),
        );
      }
    }
  }

  /// Verify that each type argument in [typeArgumentList] is within its bounds,
  /// as defined by [genericType].
  void _checkInvocationTypeArguments(
    List<TypeAnnotation>? typeArgumentList,
    DartType? genericType,
    DartType? instantiatedType,
  ) {
    if (typeArgumentList == null) {
      return;
    }

    if (genericType is! FunctionType || instantiatedType is! FunctionType) {
      return;
    }

    var fnTypeParams = genericType.typeParameters;
    var typeArgs = typeArgumentList.map((t) => t.typeOrThrow).toList();

    // If the amount mismatches, clean up the lists to be substitutable. The
    // mismatch in size is reported elsewhere, but we must successfully
    // perform substitution to validate bounds on mismatched lists.
    var providedLength = math.min(typeArgs.length, fnTypeParams.length);
    fnTypeParams = fnTypeParams.sublist(0, providedLength);
    typeArgs = typeArgs.sublist(0, providedLength);

    for (int i = 0; i < providedLength; i++) {
      // Check the `extends` clause for the type parameter, if any.
      //
      // Also substitute to handle cases like this:
      //
      //     <TFrom, TTo extends TFrom>
      //     <TFrom, TTo extends Iterable<TFrom>>
      //     <T extends Cloneable<T>>
      //
      var argType = typeArgs[i];

      if (argType is FunctionTypeImpl && argType.typeParameters.isNotEmpty) {
        if (!_libraryElement.featureSet.isEnabled(Feature.generic_metadata)) {
          _diagnosticReporter.atNode(
            typeArgumentList[i],
            CompileTimeErrorCode.genericFunctionTypeCannotBeTypeArgument,
          );
          continue;
        }
      }

      var fnTypeParam = fnTypeParams[i];
      var fnTypeParamName = fnTypeParam.name;
      if (fnTypeParamName == null) {
        continue;
      }

      var rawBound = fnTypeParam.bound;
      if (rawBound == null) {
        continue;
      }

      var substitution = Substitution.fromPairs2(fnTypeParams, typeArgs);
      var bound = substitution.substituteType(rawBound);
      if (!_typeSystem.isSubtypeOf(argType, bound)) {
        _diagnosticReporter.atNode(
          typeArgumentList[i],
          CompileTimeErrorCode.typeArgumentNotMatchingBounds,
          arguments: [argType, fnTypeParamName, bound],
        );
      }
    }
  }

  /// Checks whether the given [typeAnnotation] contains a type parameter.
  ///
  /// The [errorCode] is either
  /// [CompileTimeErrorCode.invalidTypeArgumentInConstList],
  /// [CompileTimeErrorCode.invalidTypeArgumentInConstMap], or
  /// [CompileTimeErrorCode.invalidTypeArgumentInConstSet].
  void _checkTypeArgumentConst(
    TypeAnnotation typeAnnotation,
    DiagnosticCode errorCode,
  ) {
    switch (typeAnnotation) {
      case NamedType(:var type, :var typeArguments):
        if (type is TypeParameterType) {
          _diagnosticReporter.atNode(
            typeAnnotation,
            errorCode,
            arguments: [typeAnnotation.name.lexeme],
          );
        } else if (typeArguments != null) {
          for (var argument in typeArguments.arguments) {
            _checkTypeArgumentConst(argument, errorCode);
          }
        }
      case GenericFunctionType(:var returnType, :var parameters):
        for (var parameter in parameters.parameters) {
          if (parameter case SimpleFormalParameter(type: var typeAnnotation?)) {
            if (typeAnnotation case TypeAnnotation(:TypeParameterType type)) {
              _diagnosticReporter.atNode(
                typeAnnotation,
                errorCode,
                arguments: [type],
              );
            } else {
              _checkTypeArgumentConst(typeAnnotation, errorCode);
            }
          }
          // `parameter` cannot legally be a DefaultFormalParameter,
          // FieldFormalParameter, FunctionTypedFormalParameter, or
          // SuperFormalParameter.
        }
        if (returnType case TypeAnnotation(:var type)) {
          if (type is TypeParameterType) {
            _diagnosticReporter.atNode(
              returnType,
              errorCode,
              arguments: [type],
            );
          } else {
            _checkTypeArgumentConst(returnType, errorCode);
          }
        }
      case RecordTypeAnnotation(:var fields):
        for (var field in fields) {
          var typeAnnotation = field.type;
          if (typeAnnotation case TypeAnnotation(:TypeParameterType type)) {
            _diagnosticReporter.atNode(
              typeAnnotation,
              errorCode,
              arguments: [type],
            );
          } else {
            _checkTypeArgumentConst(typeAnnotation, errorCode);
          }
        }
    }
  }

  /// Verifies that the given list of [typeArguments] contains exactly the
  /// [expectedCount] of elements, reporting an error with the [code] if not.
  void _checkTypeArgumentCount(
    TypeArgumentList typeArguments,
    int expectedCount,
    DiagnosticCode code,
  ) {
    int actualCount = typeArguments.arguments.length;
    if (actualCount != expectedCount) {
      _diagnosticReporter.atNode(typeArguments, code, arguments: [actualCount]);
    }
  }

  /// Given a [node] without type arguments that refers to [element], issues
  /// an error if [type] is a generic type, and the type arguments were not
  /// supplied from inference or a non-dynamic default instantiation.
  ///
  /// This function is used by other node-specific type checking functions, and
  /// should only be called when [node] has no explicit `typeArguments`.
  ///
  /// This function will return false if either of the following are true:
  ///
  /// - [type] does not have any `dynamic` type arguments.
  /// - the element is marked with `@optionalTypeArgs` from "package:meta".
  bool _isMissingTypeArguments(AstNode node, DartType type, Element? element) {
    if (element == null) {
      return false;
    }

    List<DartType> typeArguments;
    var alias = type.alias;
    if (alias != null) {
      typeArguments = alias.typeArguments;
    } else if (type is InterfaceType) {
      typeArguments = type.typeArguments;
    } else {
      return false;
    }

    // Check if this type has type arguments and at least one is dynamic.
    // If so, we may need to issue a strict-raw-types error.
    if (typeArguments.any((t) => t is DynamicType)) {
      if (element.metadata.hasOptionalTypeArgs) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Determines if the given [namedType] occurs in a context where
  /// super-bounded types are allowed.
  bool _shouldAllowSuperBoundedTypes(NamedType namedType) {
    switch (namedType.parent) {
      case ClassTypeAlias _:
      case ConstructorName _:
      case ExtendsClause _:
      case GenericTypeAlias _:
      case ImplementsClause _:
      case MixinOnClause _:
      case WithClause _:
        return false;
    }

    if (namedType.type?.element is ExtensionTypeElement) {
      return false;
    }

    return true;
  }

  /// Return the type arguments at [index] from [node], or the [node] itself.
  static TypeAnnotation _typeArgumentErrorNode(NamedType node, int index) {
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && index < typeArguments.length) {
      return typeArguments[index];
    }
    return node;
  }
}

class _TypeArgumentIssue {
  /// The index for type argument within the passed type arguments.
  final int index;

  /// The type parameter with the bound that was violated.
  final TypeParameterElement parameter;

  /// The non-null name of the [parameter].
  final String parameterName;

  /// The substituted bound of the [parameter].
  final DartType parameterBound;

  /// The type argument that violated the [parameterBound].
  final DartType argument;

  _TypeArgumentIssue(
    this.index,
    this.parameter,
    this.parameterName,
    this.parameterBound,
    this.argument,
  );

  @override
  String toString() {
    return 'TypeArgumentIssue(index=$index, parameter=$parameter, '
        'parameterBound=$parameterBound, argument=$argument)';
  }
}
