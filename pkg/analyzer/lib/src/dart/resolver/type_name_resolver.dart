// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
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
import 'package:analyzer/src/generated/source.dart';
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
  final Source source;
  final AnalysisErrorListener errorListener;

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

  TypeNameResolver(
      this.typeSystem,
      TypeProvider typeProvider,
      this.isNonNullableByDefault,
      this.definingLibrary,
      this.source,
      this.errorListener,
      {this.shouldUseWithClauseInferredTypes = true})
      : dynamicType = typeProvider.dynamicType,
        analysisOptions = definingLibrary.context.analysisOptions;

  NullabilitySuffix get _noneOrStarSuffix {
    return isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  /// Report an error with the given error code and arguments.
  ///
  /// @param errorCode the error code of the error to be reported
  /// @param node the node specifying the location of the error
  /// @param arguments the arguments to the error, used to compose the error
  ///        message
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    errorListener.onError(
        AnalysisError(source, node.offset, node.length, errorCode, arguments));
  }

  /// Resolve the given [TypeName] - set its element and static type. Only the
  /// given [node] is resolved, all its children must be already resolved.
  ///
  /// The client must set [nameScope] before calling [resolveTypeName].
  void resolveTypeName(TypeName node) {
    rewriteResult = null;
    Identifier typeName = node.name;
    _setElement(typeName, null); // Clear old Elements from previous run.
    TypeArgumentList argumentList = node.typeArguments;
    Element element = nameScope.lookup(typeName, definingLibrary);
    if (element == null) {
      //
      // Check to see whether the type name is either 'dynamic' or 'void',
      // neither of which are in the name scope and hence will not be found by
      // normal means.
      //
      VoidTypeImpl voidType = VoidTypeImpl.instance;
      if (typeName.name == voidType.name) {
        // There is no element for 'void'.
//        if (argumentList != null) {
//          // TODO(brianwilkerson) Report this error
//          reporter.reportError(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, node, voidType.getName(), 0, argumentList.getArguments().size());
//        }
        node.type = voidType;
        return;
      }
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
              reportErrorForNode(
                  CompileTimeErrorCode.CONST_WITH_NON_TYPE,
                  prefixedIdentifier.identifier,
                  [prefixedIdentifier.identifier.name]);
            } else {
              // Else, if this expression is a new expression, report a
              // NEW_WITH_NON_TYPE warning.
              reportErrorForNode(
                  StaticWarningCode.NEW_WITH_NON_TYPE,
                  prefixedIdentifier.identifier,
                  [prefixedIdentifier.identifier.name]);
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
    // check element
    bool elementValid = element is! MultiplyDefinedElement;
    if (elementValid &&
        element != null &&
        element is! ClassElement &&
        _isTypeNameInInstanceCreationExpression(node)) {
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      InstanceCreationExpression creation =
          node.parent.parent as InstanceCreationExpression;
      if (creation.isConst) {
        reportErrorForNode(CompileTimeErrorCode.CONST_WITH_NON_TYPE,
            typeNameSimple, [typeName]);
        elementValid = false;
      } else {
        reportErrorForNode(
            StaticWarningCode.NEW_WITH_NON_TYPE, typeNameSimple, [typeName]);
        elementValid = false;
      }
    }
    if (elementValid && element == null) {
      // We couldn't resolve the type name.
      elementValid = false;
      // TODO(jwren) Consider moving the check for
      // CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE from the
      // ErrorVerifier, so that we don't have two errors on a built in
      // identifier being used as a class name.
      // See CompileTimeErrorCodeTest.test_builtInIdentifierAsType().
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      if (_isBuiltInIdentifier(node) && _isTypeAnnotation(node)) {
        reportErrorForNode(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE,
            typeName, [typeName.name]);
      } else if (typeNameSimple.name == "boolean") {
        reportErrorForNode(
            StaticWarningCode.UNDEFINED_CLASS_BOOLEAN, typeNameSimple, []);
      } else if (_isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName,
            [typeName.name]);
      } else if (_isTypeNameInAsExpression(node)) {
        reportErrorForNode(
            StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (_isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME,
            typeName, [typeName.name]);
      } else if (_isRedirectingConstructor(node)) {
        reportErrorForNode(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, typeName,
            [typeName.name]);
      } else if (_isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
            typeName, [typeName.name]);
      } else if (typeName is PrefixedIdentifier &&
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
          reportErrorForNode(
              StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
              argumentList,
              [prefix.name, identifier.name]);
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
            elementValid = true;
            rewriteResult = newConstructorName;
          }
        } else {
          reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_CLASS, typeName, [typeName.name]);
        }
      } else {
        reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CLASS, typeName, [typeName.name]);
      }
    }
    if (!elementValid) {
      if (element is MultiplyDefinedElement) {
        _setElement(typeName, element);
      }
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
    } else if (element is MultiplyDefinedElement) {
      var elements = (element as MultiplyDefinedElement).conflictingElements;
      element = _getElementWhenMultiplyDefined(elements);
    } else {
      // The name does not represent a type.
      if (_isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName,
            [typeName.name]);
      } else if (_isTypeNameInAsExpression(node)) {
        reportErrorForNode(
            StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (_isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_WITH_NON_TYPE, typeName,
            [typeName.name]);
      } else if (_isRedirectingConstructor(node)) {
        reportErrorForNode(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, typeName,
            [typeName.name]);
      } else if (_isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
            typeName, [typeName.name]);
      } else {
        AstNode parent = typeName.parent;
        while (parent is TypeName) {
          parent = parent.parent;
        }
        if (parent is ExtendsClause ||
            parent is ImplementsClause ||
            parent is WithClause ||
            parent is ClassTypeAlias) {
          // Ignored. The error will be reported elsewhere.
        } else if (element is LocalVariableElement ||
            (element is FunctionElement &&
                element.enclosingElement is ExecutableElement)) {
          errorListener.onError(DiagnosticFactory()
              .referencedBeforeDeclaration(source, typeName, element: element));
        } else {
          reportErrorForNode(
              StaticWarningCode.NOT_A_TYPE, typeName, [typeName.name]);
        }
      }
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
      reportErrorForNode(
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

  /// Given the multiple elements to which a single name could potentially be
  /// resolved, return the single [ClassElement] that should be used, or `null`
  /// if there is no clear choice.
  ///
  /// @param elements the elements to which a single name could potentially be
  ///        resolved
  /// @return the single interface type that should be used for the type name
  ClassElement _getElementWhenMultiplyDefined(List<Element> elements) {
    int length = elements.length;
    for (int i = 0; i < length; i++) {
      Element element = elements[i];
      if (element is ClassElement) {
        return element;
      }
    }
    return null;
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

  /// Returns the simple identifier of the given (may be qualified) type name.
  ///
  /// @param typeName the (may be qualified) qualified type name
  /// @return the simple identifier of the given (may be qualified) type name.
  SimpleIdentifier _getTypeSimpleIdentifier(Identifier typeName) {
    if (typeName is SimpleIdentifier) {
      return typeName;
    } else {
      PrefixedIdentifier prefixed = typeName;
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

  /// Return `true` if the given [typeName] is the target in a redirected
  /// constructor.
  bool _isRedirectingConstructor(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      AstNode grandParent = parent.parent;
      if (grandParent is ConstructorDeclaration) {
        if (identical(grandParent.redirectedConstructor, parent)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an as expression.
  bool _isTypeNameInAsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is AsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the exception type in a catch
  /// clause.
  bool _isTypeNameInCatchClause(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an instance creation
  /// expression.
  bool _isTypeNameInInstanceCreationExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName &&
        parent.parent is InstanceCreationExpression) {
      return parent != null && identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an is expression.
  bool _isTypeNameInIsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is IsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] used in a type argument list.
  bool _isTypeNameInTypeArgumentList(TypeName typeName) =>
      typeName.parent is TypeArgumentList;

  /// Given a [typeName] that has a question mark, report an error and return
  /// `true` if it appears in a location where a nullable type is not allowed.
  void _reportInvalidNullableType(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ExtendsClause || parent is ClassTypeAlias) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE, typeName);
    } else if (parent is ImplementsClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE, typeName);
    } else if (parent is OnClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE, typeName);
    } else if (parent is WithClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE, typeName);
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
        reportErrorForNode(
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

  /// Return `true` if the name of the given [typeName] is an built-in
  /// identifier.
  static bool _isBuiltInIdentifier(TypeName typeName) {
    Token token = typeName.name.beginToken;
    return token.type.isKeyword;
  }

  /// @return `true` if given [typeName] is used as a type annotation.
  static bool _isTypeAnnotation(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is VariableDeclarationList) {
      return identical(parent.type, typeName);
    } else if (parent is FieldFormalParameter) {
      return identical(parent.type, typeName);
    } else if (parent is SimpleFormalParameter) {
      return identical(parent.type, typeName);
    }
    return false;
  }
}
