// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';

/// Helper for resolving types.
///
/// The client must set [nameScope] before calling [resolveTypeName].
class TypeNameResolver {
  final TypeSystemImpl typeSystem;
  final DartType dynamicType;
  final bool isNonNullableByDefault;
  final AnalysisOptionsImpl analysisOptions;
  final LibraryElement definingLibrary;
  final ErrorReporter errorReporter;

  /// Indicates whether bare typenames in "with" clauses should have their type
  /// inferred type arguments loaded from the element model.
  ///
  /// This is needed for mixin type inference, but is incompatible with the old
  /// task model.
  final bool shouldUseWithClauseInferredTypes;

  Scope nameScope;

  /// If [resolveTypeName] finds out that the given [TypeName] with a
  /// [PrefixedIdentifier] name is actually the name of a class and the name of
  /// the constructor, it rewrites the [ConstructorName] to correctly represent
  /// the type and the constructor name, and set this field to the rewritten
  /// [ConstructorName]. Otherwise this field will be set `null`.
  ConstructorName rewriteResult;

  TypeNameResolver(this.typeSystem, TypeProvider typeProvider,
      this.isNonNullableByDefault, this.definingLibrary, this.errorReporter,
      {this.shouldUseWithClauseInferredTypes = true})
      : dynamicType = typeProvider.dynamicType,
        analysisOptions = definingLibrary.context.analysisOptions;

  NullabilitySuffix get _noneOrStarSuffix {
    return isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  /// Resolve the given [TypeName] - set its element and static type. Only the
  /// given [node] is resolved, all its children must be already resolved.
  ///
  /// The client must set [nameScope] before calling [resolveTypeName].
  void resolveTypeName(TypeName node) {
    rewriteResult = null;

    Identifier typeName = node.name;

    if (typeName is SimpleIdentifier && typeName.name == 'void') {
      node.type = VoidTypeImpl.instance;
      return;
    }

    _setElement(typeName, null); // Clear old Elements from previous run.

    TypeArgumentList argumentList = node.typeArguments;
    Element element = nameScope.lookup(typeName, definingLibrary);
    if (element == null) {
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        node.type = dynamicType;
        return;
      }
      //
      // If not, the look to see whether we might have created the wrong AST
      // structure for a constructor name. If so, fix the AST structure and then
      // proceed.
      //
      AstNode parent = node.parent;
      if (typeName is PrefixedIdentifier &&
          parent is ConstructorName &&
          argumentList == null) {
        ConstructorName name = parent;
        if (name.name == null) {
          PrefixedIdentifier prefixedIdentifier =
              typeName as PrefixedIdentifier;
          SimpleIdentifier prefix = prefixedIdentifier.prefix;
          element = nameScope.lookup(prefix, definingLibrary);
          if (element is PrefixElement) {
            if (nameScope.shouldIgnoreUndefined(typeName)) {
              node.type = dynamicType;
              return;
            }
            AstNode grandParent = parent.parent;
            if (grandParent is InstanceCreationExpression &&
                grandParent.isConst) {
              // If, if this is a const expression, then generate a
              // CompileTimeErrorCode.CONST_WITH_NON_TYPE error.
              errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONST_WITH_NON_TYPE,
                prefixedIdentifier.identifier,
                [prefixedIdentifier.identifier.name],
              );
            } else {
              // Else, if this expression is a new expression, report a
              // NEW_WITH_NON_TYPE warning.
              errorReporter.reportErrorForNode(
                StaticWarningCode.NEW_WITH_NON_TYPE,
                prefixedIdentifier.identifier,
                [prefixedIdentifier.identifier.name],
              );
            }
            _setElement(prefix, element);
            return;
          } else if (element != null) {
            //
            // Rewrite the constructor name. The parser, when it sees a
            // constructor named "a.b", cannot tell whether "a" is a prefix and
            // "b" is a class name, or whether "a" is a class name and "b" is a
            // constructor name. It arbitrarily chooses the former, but in this
            // case was wrong.
            //
            name.name = prefixedIdentifier.identifier;
            name.period = prefixedIdentifier.period;
            node.name = prefix;
            typeName = prefix;
            rewriteResult = parent;
          }
        }
      }
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        node.type = dynamicType;
        return;
      }
    }

    if (element is MultiplyDefinedElement) {
      _setElement(typeName, element);
      node.type = dynamicType;
      return;
    }

    var errorHelper = _ErrorHelper(errorReporter);
    if (errorHelper.checkNewWithNonType(node, element)) {
      _setElement(typeName, element);
      node.type = dynamicType;
      return;
    }

    if (element == null) {
      if (errorHelper.checkNullOrNonTypeElement(node, element)) {
        _setElement(typeName, element);
        node.type = dynamicType;
        return;
      }

      if (typeName is PrefixedIdentifier &&
          node.parent is ConstructorName &&
          argumentList != null) {
        SimpleIdentifier prefix = (typeName as PrefixedIdentifier).prefix;
        SimpleIdentifier identifier =
            (typeName as PrefixedIdentifier).identifier;
        Element prefixElement = nameScope.lookup(prefix, definingLibrary);
        ClassElement classElement;
        ConstructorElement constructorElement;
        if (prefixElement is ClassElement) {
          classElement = prefixElement;
          constructorElement =
              prefixElement.getNamedConstructor(identifier.name);
        }
        if (constructorElement != null) {
          errorReporter.reportErrorForNode(
            StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
            argumentList,
            [prefix.name, identifier.name],
          );
          prefix.staticElement = prefixElement;
          identifier.staticElement = constructorElement;
          AstNode grandParent = node.parent.parent;
          if (grandParent is InstanceCreationExpressionImpl) {
            var instanceType = classElement.instantiate(
              typeArguments: List.filled(
                classElement.typeParameters.length,
                dynamicType,
              ),
              nullabilitySuffix: _noneOrStarSuffix,
            );
            grandParent.staticElement = constructorElement;
            grandParent.staticType = instanceType;
            //
            // Re-write the AST to reflect the resolution.
            //
            TypeName newTypeName = astFactory.typeName(prefix, null);
            newTypeName.type = instanceType;
            ConstructorName newConstructorName = astFactory.constructorName(
                newTypeName,
                (typeName as PrefixedIdentifier).period,
                identifier);
            newConstructorName.staticElement = constructorElement;
            NodeReplacer.replace(node.parent, newConstructorName);
            grandParent.typeArguments = node.typeArguments;
            // Re-assign local variables that have effectively changed.
            node = newTypeName;
            typeName = prefix;
            element = prefixElement;
            argumentList = null;
            rewriteResult = newConstructorName;
          }
        } else {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CLASS,
            typeName,
            [typeName.name],
          );
        }
      } else {
        errorHelper.reportUnresolvedElement(node);
      }
    }

    if (element == null) {
      node.type = dynamicType;
      return;
    }

    if (element is ClassElement) {
      _resolveClassElement(node, typeName, argumentList, element);
      return;
    }

    DartType type;
    if (element == DynamicElementImpl.instance) {
      _setElement(typeName, element);
      type = DynamicTypeImpl.instance;
    } else if (element is NeverElementImpl) {
      _setElement(typeName, element);
      type = element.instantiate(
        nullabilitySuffix: _getNullability(node.question != null),
      );
    } else if (element is FunctionTypeAliasElement) {
      _setElement(typeName, element);
    } else if (element is TypeParameterElement) {
      _setElement(typeName, element);
      type = element.instantiate(
        nullabilitySuffix: _getNullability(node.question != null),
      );
    } else {
      errorHelper.checkNullOrNonTypeElement(node, element);
      node.type = dynamicType;
      return;
    }

    type = _instantiateElement(node, element);

    node.type = type;
  }

  /// Return type arguments, exactly [parameterCount].
  List<DartType> _buildTypeArguments(TypeName node, int parameterCount) {
    var arguments = node.typeArguments.arguments;
    var argumentCount = arguments.length;

    if (argumentCount != parameterCount) {
      errorReporter.reportErrorForNode(
        StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
        node,
        [node.name.name, parameterCount, argumentCount],
      );
      return List.filled(parameterCount, DynamicTypeImpl.instance);
    }

    if (parameterCount == 0) {
      return const <DartType>[];
    }

    var typeArguments = List<DartType>(parameterCount);
    for (var i = 0; i < parameterCount; i++) {
      typeArguments[i] = _getType(arguments[i]);
    }

    return typeArguments;
  }

  DartType _getInferredMixinType(
      ClassElement classElement, ClassElement mixinElement) {
    for (var candidateMixin in classElement.mixins) {
      if (candidateMixin.element == mixinElement) return candidateMixin;
    }
    return null; // Not found
  }

  NullabilitySuffix _getNullability(bool hasQuestion) {
    if (isNonNullableByDefault) {
      if (hasQuestion) {
        return NullabilitySuffix.question;
      } else {
        return NullabilitySuffix.none;
      }
    }
    return NullabilitySuffix.star;
  }

  /// Return the type represented by the given type [annotation].
  DartType _getType(TypeAnnotation annotation) {
    DartType type = annotation.type;
    if (type == null) {
      return dynamicType;
    }
    return type;
  }

  /// If the [node] is the type name in a redirected factory constructor,
  /// infer type arguments using the enclosing class declaration. Return `null`
  /// otherwise.
  List<DartType> _inferTypeArgumentsForRedirectedConstructor(
      TypeName node, ClassElement typeElement) {
    AstNode constructorName = node.parent;
    AstNode enclosingConstructor = constructorName?.parent;
    if (constructorName is ConstructorName &&
        enclosingConstructor is ConstructorDeclaration &&
        enclosingConstructor.redirectedConstructor == constructorName) {
      ClassOrMixinDeclaration enclosingClassNode = enclosingConstructor.parent;
      var enclosingClassElement = enclosingClassNode.declaredElement;
      if (enclosingClassElement == typeElement) {
        return typeElement.thisType.typeArguments;
      } else {
        return typeSystem.inferGenericFunctionOrType(
          typeParameters: typeElement.typeParameters,
          parameters: const [],
          declaredReturnType: typeElement.thisType,
          argumentTypes: const [],
          contextReturnType: enclosingClassElement.thisType,
        );
      }
    }
    return null;
  }

  DartType _instantiateElement(TypeName node, Element element) {
    var nullability = _getNullability(node.question != null);

    var argumentList = node.typeArguments;
    if (argumentList != null) {
      if (element is ClassElement) {
        var typeArguments = _buildTypeArguments(
          node,
          element.typeParameters.length,
        );
        return element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
      } else if (element is DynamicElementImpl) {
        _buildTypeArguments(node, 0);
        return DynamicTypeImpl.instance;
      } else if (element is FunctionTypeAliasElement) {
        var typeArguments = _buildTypeArguments(
          node,
          element.typeParameters.length,
        );
        return element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
      } else if (element is NeverElementImpl) {
        _buildTypeArguments(node, 0);
        return element.instantiate(
          nullabilitySuffix: nullability,
        );
      } else if (element is TypeParameterElement) {
        _buildTypeArguments(node, 0);
        return element.instantiate(
          nullabilitySuffix: nullability,
        );
      } else {
        throw UnimplementedError('(${element.runtimeType}) $element');
      }
    }

    if (element is ClassElement) {
      return element.instantiateToBounds(
        nullabilitySuffix: nullability,
      );
    } else if (element is DynamicElementImpl) {
      return DynamicTypeImpl.instance;
    } else if (element is FunctionTypeAliasElement) {
      return element.instantiateToBounds(
        nullabilitySuffix: nullability,
      );
    } else if (element is NeverElementImpl) {
      return element.instantiate(
        nullabilitySuffix: nullability,
      );
    } else if (element is TypeParameterElement) {
      return element.instantiate(
        nullabilitySuffix: nullability,
      );
    } else {
      throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }

  /// Given a [typeName] that has a question mark, report an error and return
  /// `true` if it appears in a location where a nullable type is not allowed.
  void _reportInvalidNullableType(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ExtendsClause || parent is ClassTypeAlias) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE,
        typeName,
      );
    } else if (parent is ImplementsClause) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE,
        typeName,
      );
    } else if (parent is OnClause) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE,
        typeName,
      );
    } else if (parent is WithClause) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE,
        typeName,
      );
    }
  }

  void _resolveClassElement(TypeName node, Identifier typeName,
      TypeArgumentList argumentList, ClassElement element) {
    _setElement(typeName, element);

    var typeParameters = element.typeParameters;
    var parameterCount = typeParameters.length;

    List<DartType> typeArguments;
    if (argumentList != null) {
      var argumentNodes = argumentList.arguments;
      var argumentCount = argumentNodes.length;

      typeArguments = List<DartType>(parameterCount);
      if (argumentCount == parameterCount) {
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = _getType(argumentNodes[i]);
        }
      } else {
        errorReporter.reportErrorForNode(
          StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
          node,
          [typeName.name, parameterCount, argumentCount],
        );
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = dynamicType;
        }
      }
    } else if (parameterCount == 0) {
      typeArguments = const <DartType>[];
    } else {
      typeArguments =
          _inferTypeArgumentsForRedirectedConstructor(node, element);
      if (typeArguments == null) {
        typeArguments = typeSystem.instantiateTypeFormalsToBounds2(element);
      }
    }

    var parent = node.parent;

    NullabilitySuffix nullabilitySuffix;
    if (parent is ClassTypeAlias ||
        parent is ExtendsClause ||
        parent is ImplementsClause ||
        parent is OnClause ||
        parent is WithClause) {
      if (node.question != null) {
        _reportInvalidNullableType(node);
      }
      if (isNonNullableByDefault) {
        nullabilitySuffix = NullabilitySuffix.none;
      } else {
        nullabilitySuffix = NullabilitySuffix.star;
      }
    } else {
      nullabilitySuffix = _getNullability(node.question != null);
    }

    var type = InterfaceTypeImpl.explicit(element, typeArguments,
        nullabilitySuffix: nullabilitySuffix);

    if (shouldUseWithClauseInferredTypes) {
      if (parent is WithClause && parameterCount != 0) {
        // Get the (possibly inferred) mixin type from the element model.
        var grandParent = parent.parent;
        if (grandParent is ClassDeclaration) {
          type = _getInferredMixinType(grandParent.declaredElement, element);
        } else if (grandParent is ClassTypeAlias) {
          type = _getInferredMixinType(grandParent.declaredElement, element);
        } else {
          assert(false, 'Unexpected context for "with" clause');
        }
      }
    }

    node.type = type;
  }

  /// Records the new Element for a TypeName's Identifier.
  ///
  /// A null may be passed in to indicate that the element can't be resolved.
  /// (During a re-run of a task, it's important to clear any previous value
  /// of the element.)
  void _setElement(Identifier typeName, Element element) {
    if (typeName is SimpleIdentifier) {
      typeName.staticElement = element;
    } else if (typeName is PrefixedIdentifier) {
      typeName.identifier.staticElement = element;
      SimpleIdentifier prefix = typeName.prefix;
      prefix.staticElement = nameScope.lookup(prefix, definingLibrary);
    }
  }
}

/// Helper for reporting errors during type name resolution.
class _ErrorHelper {
  final ErrorReporter errorReporter;

  _ErrorHelper(this.errorReporter);

  bool checkNewWithNonType(TypeName node, Element element) {
    if (element != null && element is! ClassElement) {
      var constructorName = node.parent;
      if (constructorName is ConstructorName) {
        var instanceCreation = constructorName.parent;
        if (instanceCreation is InstanceCreationExpression) {
          var identifier = node.name;
          var simpleIdentifier = _getSimpleIdentifier(identifier);
          if (instanceCreation.isConst) {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_WITH_NON_TYPE,
              simpleIdentifier,
              [identifier],
            );
          } else {
            errorReporter.reportErrorForNode(
              StaticWarningCode.NEW_WITH_NON_TYPE,
              simpleIdentifier,
              [identifier],
            );
          }
          return true;
        }
      }
    }

    return false;
  }

  bool checkNullOrNonTypeElement(TypeName node, Element element) {
    var typeName = node.name;
    SimpleIdentifier typeNameSimple = _getSimpleIdentifier(typeName);
    if (typeNameSimple.name == "boolean") {
      errorReporter.reportErrorForNode(
        StaticWarningCode.UNDEFINED_CLASS_BOOLEAN,
        typeNameSimple,
      );
      return true;
    } else if (_isTypeInCatchClause(node)) {
      errorReporter.reportErrorForNode(
        StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE,
        typeName,
        [typeName.name],
      );
      return true;
    } else if (_isTypeInAsExpression(node)) {
      errorReporter.reportErrorForNode(
        StaticWarningCode.CAST_TO_NON_TYPE,
        typeName,
        [typeName.name],
      );
      return true;
    } else if (_isTypeInIsExpression(node)) {
      if (element != null) {
        errorReporter.reportErrorForNode(
          StaticWarningCode.TYPE_TEST_WITH_NON_TYPE,
          typeName,
          [typeName.name],
        );
      } else {
        errorReporter.reportErrorForNode(
          StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME,
          typeName,
          [typeName.name],
        );
      }
      return true;
    } else if (_isRedirectingConstructor(node)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.REDIRECT_TO_NON_CLASS,
        typeName,
        [typeName.name],
      );
      return true;
    } else if (_isTypeInTypeArgumentList(node)) {
      errorReporter.reportErrorForNode(
        StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
        typeName,
        [typeName.name],
      );
      return true;
    } else if (element != null) {
      var parent = node.parent;
      if (parent is ExtendsClause ||
          parent is ImplementsClause ||
          parent is WithClause ||
          parent is ClassTypeAlias) {
        // Ignored. The error will be reported elsewhere.
      } else if (element is LocalVariableElement ||
          (element is FunctionElement &&
              element.enclosingElement is ExecutableElement)) {
        errorReporter.reportError(
          DiagnosticFactory().referencedBeforeDeclaration(
            errorReporter.source,
            typeName,
            element: element,
          ),
        );
      } else {
        errorReporter.reportErrorForNode(
          StaticWarningCode.NOT_A_TYPE,
          typeName,
          [typeName.name],
        );
      }
      return true;
    }
    return false;
  }

  void reportUnresolvedElement(TypeName node) {
    var identifier = node.name;
    if (identifier is SimpleIdentifier && identifier.name == 'await') {
      errorReporter.reportErrorForNode(
        StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT,
        node,
      );
    } else {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_CLASS,
        identifier,
        [identifier.name],
      );
    }
  }

  /// Returns the simple identifier of the given (maybe prefixed) identifier.
  static SimpleIdentifier _getSimpleIdentifier(Identifier identifier) {
    if (identifier is SimpleIdentifier) {
      return identifier;
    } else {
      PrefixedIdentifier prefixed = identifier;
      SimpleIdentifier prefix = prefixed.prefix;
      // The prefixed identifier can be:
      // 1. new importPrefix.TypeName()
      // 2. new TypeName.constructorName()
      // 3. new unresolved.Unresolved()
      if (prefix.staticElement is PrefixElement) {
        return prefixed.identifier;
      } else {
        return prefix;
      }
    }
  }

  /// Check if the [node] is the type in a redirected constructor name.
  static bool _isRedirectingConstructor(TypeName node) {
    var parent = node.parent;
    if (parent is ConstructorName) {
      var grandParent = parent.parent;
      if (grandParent is ConstructorDeclaration) {
        return identical(grandParent.redirectedConstructor, parent);
      }
    }
    return false;
  }

  /// Checks if the [node] is the type in an `as` expression.
  static bool _isTypeInAsExpression(TypeName node) {
    var parent = node.parent;
    if (parent is AsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is the exception type in a `catch` clause.
  static bool _isTypeInCatchClause(TypeName node) {
    var parent = node.parent;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, node);
    }
    return false;
  }

  /// Checks if the [node] is the type in an `is` expression.
  static bool _isTypeInIsExpression(TypeName node) {
    var parent = node.parent;
    if (parent is IsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is an element in a type argument list.
  static bool _isTypeInTypeArgumentList(TypeName node) {
    return node.parent is TypeArgumentList;
  }
}
