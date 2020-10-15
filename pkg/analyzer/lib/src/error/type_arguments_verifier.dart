// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math" as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart';

class TypeArgumentsVerifier {
  final AnalysisOptionsImpl _options;
  final LibraryElement _libraryElement;
  final ErrorReporter _errorReporter;

  TypeArgumentsVerifier(
    this._options,
    this._libraryElement,
    this._errorReporter,
  );

  TypeSystemImpl get _typeSystem => _libraryElement.typeSystem;

  void checkFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkTypeArguments(node);
    _checkForImplicitDynamicInvoke(node);
  }

  void checkListLiteral(ListLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        _checkTypeArgumentConst(
          typeArguments.arguments,
          CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST,
        );
      }
      _checkTypeArgumentCount(typeArguments, 1,
          CompileTimeErrorCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS);
    }
    _checkForImplicitDynamicTypedLiteral(node);
  }

  void checkMapLiteral(SetOrMapLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        _checkTypeArgumentConst(
          typeArguments.arguments,
          CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP,
        );
      }
      _checkTypeArgumentCount(typeArguments, 2,
          CompileTimeErrorCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS);
    }
    _checkForImplicitDynamicTypedLiteral(node);
  }

  void checkMethodInvocation(MethodInvocation node) {
    _checkTypeArguments(node);
    _checkForImplicitDynamicInvoke(node);
  }

  void checkSetLiteral(SetOrMapLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (node.isConst) {
        _checkTypeArgumentConst(
          typeArguments.arguments,
          CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET,
        );
      }
      _checkTypeArgumentCount(typeArguments, 1,
          CompileTimeErrorCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS);
    }
    _checkForImplicitDynamicTypedLiteral(node);
  }

  void checkTypeName(TypeName node) {
    _checkForTypeArgumentNotMatchingBounds(node);
    if (node.parent is! ConstructorName ||
        node.parent.parent is! InstanceCreationExpression) {
      _checkForRawTypeName(node);
    }
  }

  void _checkForImplicitDynamicInvoke(InvocationExpression node) {
    if (_options.implicitDynamic ||
        node == null ||
        node.typeArguments != null) {
      return;
    }
    DartType invokeType = node.staticInvokeType;
    DartType declaredType = node.function.staticType;
    if (invokeType is FunctionType &&
        declaredType is FunctionType &&
        declaredType.typeFormals.isNotEmpty) {
      List<DartType> typeArgs = node.typeArgumentTypes;
      if (typeArgs.any((t) => t.isDynamic)) {
        // Issue an error depending on what we're trying to call.
        Expression function = node.function;
        if (function is Identifier) {
          Element element = function.staticElement;
          if (element is MethodElement) {
            _errorReporter.reportErrorForNode(
                LanguageCode.IMPLICIT_DYNAMIC_METHOD,
                node.function,
                [element.displayName, element.typeParameters.join(', ')]);
            return;
          }

          if (element is FunctionElement) {
            _errorReporter.reportErrorForNode(
                LanguageCode.IMPLICIT_DYNAMIC_FUNCTION,
                node.function,
                [element.displayName, element.typeParameters.join(', ')]);
            return;
          }
        }

        // The catch all case if neither of those matched.
        // For example, invoking a function expression.
        _errorReporter.reportErrorForNode(LanguageCode.IMPLICIT_DYNAMIC_INVOKE,
            node.function, [declaredType]);
      }
    }
  }

  void _checkForImplicitDynamicTypedLiteral(TypedLiteral node) {
    if (_options.implicitDynamic || node.typeArguments != null) {
      return;
    }
    DartType type = node.staticType;
    // It's an error if either the key or value was inferred as dynamic.
    if (type is InterfaceType && type.typeArguments.any((t) => t.isDynamic)) {
      // TODO(brianwilkerson) Add StrongModeCode.IMPLICIT_DYNAMIC_SET_LITERAL
      ErrorCode errorCode = node is ListLiteral
          ? LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL
          : LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL;
      _errorReporter.reportErrorForNode(errorCode, node);
    }
  }

  /// Checks a type annotation for a raw generic type, and reports the
  /// appropriate error if [AnalysisOptionsImpl.strictRawTypes] is set.
  ///
  /// This checks if [node] refers to a generic type and does not have explicit
  /// or inferred type arguments. When that happens, it reports error code
  /// [HintCode.STRICT_RAW_TYPE].
  void _checkForRawTypeName(TypeName node) {
    AstNode parentEscapingTypeArguments(TypeName node) {
      AstNode parent = node.parent;
      while (parent is TypeArgumentList || parent is TypeName) {
        if (parent.parent == null) {
          return parent;
        }
        parent = parent.parent;
      }
      return parent;
    }

    if (!_options.strictRawTypes || node == null) return;
    if (node.typeArguments != null) {
      // Type has explicit type arguments.
      return;
    }
    if (_isMissingTypeArguments(
        node, node.type, node.name.staticElement, null)) {
      AstNode unwrappedParent = parentEscapingTypeArguments(node);
      if (unwrappedParent is AsExpression || unwrappedParent is IsExpression) {
        // Do not report a "Strict raw type" error in this case; too noisy.
        // See https://github.com/dart-lang/language/blob/master/resources/type-system/strict-raw-types.md#conditions-for-a-raw-type-hint
      } else {
        _errorReporter
            .reportErrorForNode(HintCode.STRICT_RAW_TYPE, node, [node.type]);
      }
    }
  }

  /// Verify that the type arguments in the given [typeName] are all within
  /// their bounds.
  void _checkForTypeArgumentNotMatchingBounds(TypeName typeName) {
    var element = typeName.name.staticElement;
    var type = typeName.type;

    List<TypeParameterElement> typeParameters;
    List<DartType> typeArguments;
    if (type is InterfaceType) {
      typeParameters = type.element.typeParameters;
      typeArguments = type.typeArguments;
    } else if (element is FunctionTypeAliasElement && type is FunctionType) {
      typeParameters = element.typeParameters;
      typeArguments = type.typeArguments;
    } else {
      return;
    }

    // iterate over each bounded type parameter and corresponding argument
    NodeList<TypeAnnotation> argumentNodes = typeName.typeArguments?.arguments;
    int loopThroughIndex =
        math.min(typeArguments.length, typeParameters.length);
    bool shouldSubstitute = typeArguments.isNotEmpty;
    for (int i = 0; i < loopThroughIndex; i++) {
      DartType argType = typeArguments[i];
      TypeAnnotation argumentNode =
          argumentNodes != null && i < argumentNodes.length
              ? argumentNodes[i]
              : typeName;
      if (argType is FunctionType && argType.typeFormals.isNotEmpty) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          argumentNode,
        );
        continue;
      }
      DartType boundType = typeParameters[i].bound;
      if (argType != null && boundType != null) {
        boundType = _libraryElement.toLegacyTypeIfOptOut(boundType);
        if (shouldSubstitute) {
          boundType = Substitution.fromPairs(typeParameters, typeArguments)
              .substituteType(boundType);
        }

        if (!_typeSystem.isSubtypeOf2(argType, boundType)) {
          if (_shouldAllowSuperBoundedTypes(typeName)) {
            var replacedType = _typeSystem.replaceTopAndBottom(argType);
            if (!identical(replacedType, argType) &&
                _typeSystem.isSubtypeOf2(replacedType, boundType)) {
              // Bound is satisfied under super-bounded rules, so we're ok.
              continue;
            }
          }
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
              argumentNode,
              [argType, boundType]);
        }
      }
    }
  }

  /// Checks to ensure that the given list of type [arguments] does not have a
  /// type parameter as a type argument. The [errorCode] is either
  /// [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST] or
  /// [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP].
  void _checkTypeArgumentConst(
      NodeList<TypeAnnotation> arguments, ErrorCode errorCode) {
    for (TypeAnnotation type in arguments) {
      if (type is TypeName && type.type is TypeParameterType) {
        _errorReporter.reportErrorForNode(errorCode, type, [type.name]);
      }
    }
  }

  /// Verify that the given list of [typeArguments] contains exactly the
  /// [expectedCount] of elements, reporting an error with the [errorCode]
  /// if not.
  void _checkTypeArgumentCount(
    TypeArgumentList typeArguments,
    int expectedCount,
    ErrorCode errorCode,
  ) {
    int actualCount = typeArguments.arguments.length;
    if (actualCount != expectedCount) {
      _errorReporter.reportErrorForNode(
        errorCode,
        typeArguments,
        [actualCount],
      );
    }
  }

  /// Verify that the given [typeArguments] are all within their bounds, as
  /// defined by the given [element].
  void _checkTypeArguments(InvocationExpression node) {
    NodeList<TypeAnnotation> typeArgumentList = node.typeArguments?.arguments;
    if (typeArgumentList == null) {
      return;
    }

    var genericType = node.function.staticType;
    var instantiatedType = node.staticInvokeType;
    if (genericType is FunctionType && instantiatedType is FunctionType) {
      var fnTypeParams = genericType.typeFormals;
      var typeArgs = typeArgumentList.map((t) => t.type).toList();

      // If the amount mismatches, clean up the lists to be substitutable. The
      // mismatch in size is reported elsewhere, but we must successfully
      // perform substitution to validate bounds on mismatched lists.
      final providedLength = math.min(typeArgs.length, fnTypeParams.length);
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
        DartType argType = typeArgs[i];

        if (argType is FunctionType && argType.typeFormals.isNotEmpty) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
            typeArgumentList[i],
          );
          continue;
        }

        var rawBound = fnTypeParams[i].bound;
        if (rawBound == null) {
          continue;
        }

        var substitution = Substitution.fromPairs(fnTypeParams, typeArgs);
        var bound = substitution.substituteType(rawBound);
        if (!_typeSystem.isSubtypeOf2(argType, bound)) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
              typeArgumentList[i],
              [argType, bound]);
        }
      }
    }
  }

  /// Given a [node] without type arguments that refers to [element], issues
  /// an error if [type] is a generic type, and the type arguments were not
  /// supplied from inference or a non-dynamic default instantiation.
  ///
  /// This function is used by other node-specific type checking functions, and
  /// should only be called when [node] has no explicit `typeArguments`.
  ///
  /// [inferenceContextNode] is the node that has the downwards context type,
  /// if any. For example an [InstanceCreationExpression].
  ///
  /// This function will return false if any of the following are true:
  ///
  /// - [inferenceContextNode] has an inference context type that does not
  ///   contain `_`
  /// - [type] does not have any `dynamic` type arguments.
  /// - the element is marked with `@optionalTypeArgs` from "package:meta".
  bool _isMissingTypeArguments(AstNode node, DartType type, Element element,
      Expression inferenceContextNode) {
    // Check if this type has type arguments and at least one is dynamic.
    // If so, we may need to issue a strict-raw-types error.
    if (type is ParameterizedType &&
        type.typeArguments.any((t) => t.isDynamic)) {
      // If we have an inference context node, check if the type was inferred
      // from it. Some cases will not have a context type, such as the type
      // annotation `List` in `List list;`
      if (inferenceContextNode != null) {
        var contextType = InferenceContext.getContext(inferenceContextNode);
        if (contextType != null && UnknownInferredType.isKnown(contextType)) {
          // Type was inferred from downwards context: not an error.
          return false;
        }
      }
      if (element.hasOptionalTypeArgs) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Determines if the given [typeName] occurs in a context where super-bounded
  /// types are allowed.
  bool _shouldAllowSuperBoundedTypes(TypeName typeName) {
    var parent = typeName.parent;
    if (parent is ExtendsClause) return false;
    if (parent is OnClause) return false;
    if (parent is ClassTypeAlias) return false;
    if (parent is WithClause) return false;
    if (parent is ConstructorName) return false;
    if (parent is ImplementsClause) return false;
    return true;
  }
}
