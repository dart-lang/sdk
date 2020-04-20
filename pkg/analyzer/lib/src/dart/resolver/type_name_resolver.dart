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
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';

/// Helper for resolving types.
///
/// The client must set [nameScope] before calling [resolveTypeName].
class TypeNameResolver {
  final TypeSystemImpl typeSystem;
  final DartType dynamicType;
  final bool isNonNullableByDefault;
  final LibraryElement definingLibrary;
  final ErrorReporter errorReporter;

  Scope nameScope;

  /// If not `null`, the element of the [ClassDeclaration], or the
  /// [ClassTypeAlias] being resolved.
  ClassElement enclosingClass;

  /// If not `null`, a direct child of an [ExtendsClause], [WithClause],
  /// or [ImplementsClause].
  TypeName classHierarchy_typeName;

  /// If not `null`, a direct child the [WithClause] in the [enclosingClass].
  TypeName withClause_typeName;

  /// If not `null`, the [TypeName] of the redirected constructor being
  /// resolved, in the [enclosingClass].
  TypeName redirectedConstructor_typeName;

  /// If [resolveTypeName] finds out that the given [TypeName] with a
  /// [PrefixedIdentifier] name is actually the name of a class and the name of
  /// the constructor, it rewrites the [ConstructorName] to correctly represent
  /// the type and the constructor name, and set this field to the rewritten
  /// [ConstructorName]. Otherwise this field will be set `null`.
  ConstructorName rewriteResult;

  TypeNameResolver(this.typeSystem, TypeProvider typeProvider,
      this.isNonNullableByDefault, this.definingLibrary, this.errorReporter)
      : dynamicType = typeProvider.dynamicType;

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
      node.type = dynamicType;
      if (nameScope.shouldIgnoreUndefined(typeName)) {
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

    _setElement(typeName, element);
    node.type = _instantiateElement(node, element);
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
      typeArguments[i] = arguments[i].type;
    }

    return typeArguments;
  }

  NullabilitySuffix _getNullability(TypeName node) {
    if (isNonNullableByDefault) {
      if (node.question != null) {
        if (identical(node, classHierarchy_typeName)) {
          _reportInvalidNullableType(node);
          return NullabilitySuffix.none;
        } else {
          return NullabilitySuffix.question;
        }
      } else {
        return NullabilitySuffix.none;
      }
    }
    return NullabilitySuffix.star;
  }

  /// We are resolving the [TypeName] in a redirecting constructor of the
  /// [enclosingClass].
  InterfaceType _inferRedirectedConstructor(ClassElement element) {
    if (element == enclosingClass) {
      return element.thisType;
    } else {
      var typeParameters = element.typeParameters;
      if (typeParameters.isEmpty) {
        return element.thisType;
      } else {
        var typeArguments = typeSystem.inferGenericFunctionOrType(
          typeParameters: typeParameters,
          parameters: const [],
          declaredReturnType: element.thisType,
          argumentTypes: const [],
          contextReturnType: enclosingClass.thisType,
        );
        return element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _noneOrStarSuffix,
        );
      }
    }
  }

  DartType _instantiateElement(TypeName node, Element element) {
    var nullability = _getNullability(node);

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
        var type = element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
        type = typeSystem.toLegacyType(type);
        return type;
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
        _ErrorHelper(errorReporter).checkNullOrNonTypeElement(node, element);
        return dynamicType;
      }
    }

    if (element is ClassElement) {
      if (identical(node, withClause_typeName)) {
        for (var mixin in enclosingClass.mixins) {
          if (mixin.element == element) {
            return mixin;
          }
        }
      }

      if (identical(node, redirectedConstructor_typeName)) {
        return _inferRedirectedConstructor(element);
      }

      return typeSystem.instantiateToBounds2(
        classElement: element,
        nullabilitySuffix: nullability,
      );
    } else if (element is DynamicElementImpl) {
      return DynamicTypeImpl.instance;
    } else if (element is FunctionTypeAliasElement) {
      return typeSystem.instantiateToBounds2(
        functionTypeAliasElement: element,
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
      _ErrorHelper(errorReporter).checkNullOrNonTypeElement(node, element);
      return dynamicType;
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
