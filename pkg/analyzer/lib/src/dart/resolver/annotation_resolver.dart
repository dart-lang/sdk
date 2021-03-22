// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class AnnotationResolver {
  final ResolverVisitor _resolver;

  AnnotationResolver(this._resolver);

  LibraryElement get _definingLibrary => _resolver.definingLibrary;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _genericMetadataIsEnabled =>
      _definingLibrary.featureSet.isEnabled(Feature.generic_metadata);

  void resolve(AnnotationImpl node,
      List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo) {
    AstNode parent = node.parent;

    node.typeArguments?.accept(_resolver);
    _resolve(node, whyNotPromotedInfo);

    var elementAnnotationImpl =
        node.elementAnnotation as ElementAnnotationImpl?;
    if (elementAnnotationImpl == null) {
      // Analyzer ignores annotations on "part of" directives.
      assert(parent is PartDirective || parent is PartOfDirective);
    } else {
      elementAnnotationImpl.annotationAst = _createCloner().cloneNode(node);
    }
  }

  void _classGetter(
    AnnotationImpl node,
    ClassElement classElement,
    SimpleIdentifierImpl? getterName,
    List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo,
  ) {
    ExecutableElement? getter;
    if (getterName != null) {
      getter = classElement.getGetter(getterName.name);
      getter = _resolver.toLegacyElement(getter);
      // Recovery, try to find a constructor.
      getter ??= classElement.getNamedConstructor(getterName.name);
    } else {
      getter = classElement.unnamedConstructor;
    }

    getterName?.staticElement = getter;
    node.element = getter;

    if (getterName != null && getter is PropertyAccessorElement) {
      _propertyAccessorElement(node, getterName, getter, whyNotPromotedInfo);
      _resolveAnnotationElementGetter(node, getter);
    } else if (getter is! ConstructorElement) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ANNOTATION,
        node,
      );
    }

    _visitArguments(node, whyNotPromotedInfo);
  }

  void _constructorInvocation(
    AnnotationImpl node,
    ClassElement classElement,
    SimpleIdentifierImpl? constructorName,
    ArgumentList argumentList,
    List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo,
  ) {
    ConstructorElement? constructorElement;
    if (constructorName != null) {
      constructorElement = classElement.getNamedConstructor(
        constructorName.name,
      );
    } else {
      constructorElement = classElement.unnamedConstructor;
    }

    constructorElement = _resolver.toLegacyElement(constructorElement);
    constructorName?.staticElement = constructorElement;
    node.element = constructorElement;

    if (constructorElement == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ANNOTATION,
        node,
      );
      _resolver.visitArgumentList(argumentList,
          whyNotPromotedInfo: whyNotPromotedInfo);
      return;
    }

    var typeParameters = classElement.typeParameters;

    // If no type parameters, the elements are correct.
    if (typeParameters.isEmpty) {
      _resolveConstructorInvocationArguments(node);
      InferenceContext.setType(argumentList, constructorElement.type);
      _resolver.visitArgumentList(argumentList,
          whyNotPromotedInfo: whyNotPromotedInfo);
      return;
    }

    void resolveWithFixedTypeArguments(
      List<DartType> typeArguments,
      ConstructorElement constructorElement,
    ) {
      var type = classElement.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: _resolver.noneOrStarSuffix,
      );
      constructorElement = ConstructorMember.from(constructorElement, type);
      constructorName?.staticElement = constructorElement;
      node.element = constructorElement;
      _resolveConstructorInvocationArguments(node);

      InferenceContext.setType(argumentList, constructorElement.type);
      _resolver.visitArgumentList(argumentList,
          whyNotPromotedInfo: whyNotPromotedInfo);
    }

    if (!_genericMetadataIsEnabled) {
      var typeArguments = List.filled(
        typeParameters.length,
        DynamicTypeImpl.instance,
      );
      resolveWithFixedTypeArguments(typeArguments, constructorElement);
      return;
    }

    var typeArgumentList = node.typeArguments;
    if (typeArgumentList != null) {
      List<DartType> typeArguments;
      if (typeArgumentList.arguments.length == typeParameters.length) {
        typeArguments = typeArgumentList.arguments
            .map((element) => element.typeOrThrow)
            .toList();
      } else {
        typeArguments = List.filled(
          typeParameters.length,
          DynamicTypeImpl.instance,
        );
      }
      resolveWithFixedTypeArguments(typeArguments, constructorElement);
      return;
    }

    _resolver.visitArgumentList(argumentList,
        whyNotPromotedInfo: whyNotPromotedInfo);

    var constructorRawType = _resolver.typeAnalyzer
        .constructorToGenericFunctionType(constructorElement);

    var inferred = _resolver.inferenceHelper.inferGenericInvoke(
        node, constructorRawType, typeArgumentList, argumentList, node,
        isConst: true)!;

    constructorElement = ConstructorMember.from(
      constructorElement,
      inferred.returnType as InterfaceType,
    );
    constructorName?.staticElement = constructorElement;
    node.element = constructorElement;
    _resolveConstructorInvocationArguments(node);
  }

  /// Return a newly created cloner that can be used to clone constant
  /// expressions.
  ///
  /// TODO(scheglov) this is duplicate
  ConstantAstCloner _createCloner() {
    return ConstantAstCloner();
  }

  void _extensionGetter(
    AnnotationImpl node,
    ExtensionElement extensionElement,
    SimpleIdentifierImpl? getterName,
    List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo,
  ) {
    ExecutableElement? getter;
    if (getterName != null) {
      getter = extensionElement.getGetter(getterName.name);
      getter = _resolver.toLegacyElement(getter);
    }

    getterName?.staticElement = getter;
    node.element = getter;

    if (getterName != null && getter is PropertyAccessorElement) {
      _propertyAccessorElement(node, getterName, getter, whyNotPromotedInfo);
      _resolveAnnotationElementGetter(node, getter);
    } else {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ANNOTATION,
        node,
      );
    }

    _visitArguments(node, whyNotPromotedInfo);
  }

  void _propertyAccessorElement(
    AnnotationImpl node,
    SimpleIdentifierImpl name,
    PropertyAccessorElement element,
    List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo,
  ) {
    element = _resolver.toLegacyElement(element);
    name.staticElement = element;
    node.element = element;

    _resolveAnnotationElementGetter(node, element);
    _visitArguments(node, whyNotPromotedInfo);
  }

  void _resolve(AnnotationImpl node,
      List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo) {
    SimpleIdentifierImpl name1;
    SimpleIdentifierImpl? name2;
    SimpleIdentifierImpl? name3;
    var nameNode = node.name;
    if (nameNode is PrefixedIdentifierImpl) {
      name1 = nameNode.prefix;
      name2 = nameNode.identifier;
      name3 = node.constructorName;
    } else {
      name1 = nameNode as SimpleIdentifierImpl;
      name2 = node.constructorName;
    }
    var argumentList = node.arguments;

    var element1 = _resolver.nameScope.lookup(name1.name).getter;
    name1.staticElement = element1;

    if (element1 == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_ANNOTATION,
        node,
        [name1.name],
      );
      _visitArguments(node, whyNotPromotedInfo);
      return;
    }

    // Class(args) or Class.CONST
    if (element1 is ClassElement) {
      if (argumentList != null) {
        _constructorInvocation(
            node, element1, name2, argumentList, whyNotPromotedInfo);
      } else {
        _classGetter(node, element1, name2, whyNotPromotedInfo);
      }
      return;
    }

    // Extension.CONST
    if (element1 is ExtensionElement) {
      _extensionGetter(node, element1, name2, whyNotPromotedInfo);
      return;
    }

    // prefix.*
    if (element1 is PrefixElement) {
      if (name2 != null) {
        var element2 = element1.scope.lookup(name2.name).getter;
        name2.staticElement = element2;
        // prefix.Class(args) or prefix.Class.CONST
        if (element2 is ClassElement) {
          if (argumentList != null) {
            _constructorInvocation(
                node, element2, name3, argumentList, whyNotPromotedInfo);
          } else {
            _classGetter(node, element2, name3, whyNotPromotedInfo);
          }
          return;
        }
        // prefix.Extension.CONST
        if (element2 is ExtensionElement) {
          _extensionGetter(node, element2, name3, whyNotPromotedInfo);
          return;
        }
        // prefix.CONST
        if (element2 is PropertyAccessorElement) {
          _propertyAccessorElement(node, name2, element2, whyNotPromotedInfo);
          return;
        }
        // undefined
        if (element2 == null) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_ANNOTATION,
            node,
            [name2.name],
          );
          _visitArguments(node, whyNotPromotedInfo);
          return;
        }
      }
    }

    // CONST
    if (element1 is PropertyAccessorElement) {
      _propertyAccessorElement(node, name1, element1, whyNotPromotedInfo);
      return;
    }

    // TODO(scheglov) Must be const.
    if (element1 is VariableElement) {
      return;
    }

    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.INVALID_ANNOTATION,
      node,
    );

    _visitArguments(node, whyNotPromotedInfo);
  }

  void _resolveAnnotationElementGetter(
      Annotation annotation, PropertyAccessorElement accessorElement) {
    // The accessor should be synthetic, the variable should be constant, and
    // there should be no arguments.
    VariableElement variableElement = accessorElement.variable;
    if (!accessorElement.isSynthetic ||
        !variableElement.isConst ||
        annotation.arguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
    }
  }

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  ///
  /// TODO(scheglov) this is duplicate
  List<ParameterElement?>? _resolveArgumentsToFunction(
      ArgumentList argumentList, ExecutableElement? executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return _resolveArgumentsToParameters(argumentList, parameters);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments. An error will be reported if any of
  /// the arguments cannot be matched to a parameter. Return the parameters that
  /// correspond to the arguments.
  ///
  /// TODO(scheglov) this is duplicate
  List<ParameterElement?> _resolveArgumentsToParameters(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _errorReporter.reportErrorForNode);
  }

  void _resolveConstructorInvocationArguments(AnnotationImpl node) {
    var argumentList = node.arguments;
    // error will be reported in ConstantVerifier
    if (argumentList == null) {
      return;
    }
    // resolve arguments to parameters
    var constructor = node.element;
    if (constructor is ConstructorElement) {
      var parameters = _resolveArgumentsToFunction(argumentList, constructor);
      if (parameters != null) {
        argumentList.correspondingStaticParameters = parameters;
      }
    }
  }

  void _visitArguments(AnnotationImpl node,
      List<Map<DartType, NonPromotionReason> Function()> whyNotPromotedInfo) {
    var arguments = node.arguments;
    if (arguments != null) {
      _resolver.visitArgumentList(arguments,
          whyNotPromotedInfo: whyNotPromotedInfo);
    }
  }
}
