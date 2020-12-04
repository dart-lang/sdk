// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class AnnotationResolver {
  final ResolverVisitor _resolver;

  AnnotationResolver(this._resolver);

  LibraryElement get _definingLibrary => _resolver.definingLibrary;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  void resolve(Annotation node) {
    AstNode parent = node.parent;

    _resolve1(node);

    node.constructorName?.accept(_resolver);
    Element element = node.element;
    if (element is ExecutableElement) {
      InferenceContext.setType(node.arguments, element.type);
    }
    node.arguments?.accept(_resolver);

    ElementAnnotationImpl elementAnnotationImpl = node.elementAnnotation;
    if (elementAnnotationImpl == null) {
      // Analyzer ignores annotations on "part of" directives.
      assert(parent is PartOfDirective);
    } else {
      elementAnnotationImpl.annotationAst = _createCloner().cloneNode(node);
    }
  }

  /// Return a newly created cloner that can be used to clone constant
  /// expressions.
  ///
  /// TODO(scheglov) this is duplicate
  ConstantAstCloner _createCloner() {
    return ConstantAstCloner();
  }

  InterfaceType _instantiateAnnotationClass(ClassElement element) {
    return element.instantiate(
      typeArguments: List.filled(
        element.typeParameters.length,
        DynamicTypeImpl.instance,
      ),
      nullabilitySuffix: _resolver.noneOrStarSuffix,
    );
  }

  void _resolve1(Annotation node) {
    var nodeName = node.name;

    if (nodeName is PrefixedIdentifier) {
      var prefix = nodeName.prefix;
      var identifier = nodeName.identifier;

      prefix.accept(_resolver);
      var prefixElement = prefix.staticElement;

      if (prefixElement is ClassElement && node.arguments != null) {
        var element = prefixElement.getNamedConstructor(identifier.name);
        element = _resolver.toLegacyElement(element);

        identifier.staticElement = element;
        // TODO(scheglov) error?
      } else if (prefixElement is PrefixElement) {
        var resolver = PropertyElementResolver(_resolver);
        var result = resolver.resolvePrefixedIdentifier(
          node: nodeName,
          hasRead: true,
          hasWrite: false,
          forAnnotation: true,
        );

        var element = result.readElement;
        identifier.staticElement = element;

        if (element == null) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_ANNOTATION,
            node,
            [identifier.name],
          );
        }
      } else {
        var resolver = PropertyElementResolver(_resolver);
        var result = resolver.resolvePrefixedIdentifier(
          node: nodeName,
          hasRead: true,
          hasWrite: false,
          forAnnotation: true,
        );

        var element = result.readElement;
        identifier.staticElement = element;
      }
    } else {
      var identifier = nodeName as SimpleIdentifier;

      var resolver = PropertyElementResolver(_resolver);
      var result = resolver.resolveSimpleIdentifier(
        node: identifier,
        hasRead: true,
        hasWrite: false,
      );

      var element = result.readElement;
      identifier.staticElement = element;

      if (element == null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_ANNOTATION,
          node,
          [identifier.name],
        );
      }
    }

    _resolveAnnotationElement(node);
  }

  void _resolveAnnotationConstructorInvocationArguments(
      Annotation annotation, ConstructorElement constructor) {
    ArgumentList argumentList = annotation.arguments;
    // error will be reported in ConstantVerifier
    if (argumentList == null) {
      return;
    }
    // resolve arguments to parameters
    List<ParameterElement> parameters =
        _resolveArgumentsToFunction(argumentList, constructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  /// Continues resolution of the given [annotation].
  void _resolveAnnotationElement(Annotation annotation) {
    SimpleIdentifier nameNode1;
    SimpleIdentifier nameNode2;
    {
      Identifier annName = annotation.name;
      if (annName is PrefixedIdentifier) {
        nameNode1 = annName.prefix;
        nameNode2 = annName.identifier;
      } else {
        nameNode1 = annName as SimpleIdentifier;
        nameNode2 = null;
      }
    }
    SimpleIdentifier nameNode3 = annotation.constructorName;
    ConstructorElement constructor;
    bool undefined = false;
    //
    // CONST or Class(args)
    //
    if (nameNode1 != null && nameNode2 == null && nameNode3 == null) {
      Element element1 = nameNode1.staticElement;
      // TODO(scheglov) Must be const.
      if (element1 is VariableElement) {
        return;
      }
      // CONST
      if (element1 is PropertyAccessorElement) {
        _resolveAnnotationElementGetter(annotation, element1);
        return;
      }
      // Class(args)
      if (element1 is ClassElement) {
        constructor = _instantiateAnnotationClass(element1)
            .lookUpConstructor(null, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
      } else if (element1 == null) {
        undefined = true;
      }
    }
    //
    // prefix.CONST or prefix.Class() or Class.CONST or Class.constructor(args)
    //
    if (nameNode1 != null && nameNode2 != null && nameNode3 == null) {
      Element element1 = nameNode1.staticElement;
      Element element2 = nameNode2.staticElement;
      // Class.CONST - not resolved yet
      if (element1 is ClassElement) {
        element2 = element1.lookUpGetter(nameNode2.name, _definingLibrary);
        element2 = _resolver.toLegacyElement(element2);
      }
      // prefix.CONST or Class.CONST
      if (element2 is PropertyAccessorElement) {
        nameNode2.staticElement = element2;
        annotation.element = element2;
        _resolveAnnotationElementGetter(annotation, element2);
        return;
      }
      // prefix.Class()
      if (element2 is ClassElement) {
        constructor = element2.unnamedConstructor;
        constructor = _resolver.toLegacyElement(constructor);
      }
      // Class.constructor(args)
      if (element1 is ClassElement) {
        constructor = _instantiateAnnotationClass(element1)
            .lookUpConstructor(nameNode2.name, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
        nameNode2.staticElement = constructor;
      }
      if (element1 is PrefixElement && element2 == null) {
        undefined = true;
      }
      if (element1 == null && element2 == null) {
        undefined = true;
      }
    }
    //
    // prefix.Class.CONST or prefix.Class.constructor(args)
    //
    if (nameNode1 != null && nameNode2 != null && nameNode3 != null) {
      Element element2 = nameNode2.staticElement;
      // element2 should be ClassElement
      if (element2 is ClassElement) {
        String name3 = nameNode3.name;
        // prefix.Class.CONST
        PropertyAccessorElement getter =
            element2.lookUpGetter(name3, _definingLibrary);
        if (getter != null) {
          getter = _resolver.toLegacyElement(getter);
          nameNode3.staticElement = getter;
          annotation.element = getter;
          _resolveAnnotationElementGetter(annotation, getter);
          return;
        }
        // prefix.Class.constructor(args)
        constructor = _instantiateAnnotationClass(element2)
            .lookUpConstructor(name3, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
        nameNode3.staticElement = constructor;
      } else if (element2 == null) {
        undefined = true;
      }
    }
    // we need constructor
    if (constructor == null) {
      if (!undefined) {
        // If the class was not found then we've already reported the error.
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      }
      return;
    }
    // record element
    annotation.element = constructor;
    // resolve arguments
    _resolveAnnotationConstructorInvocationArguments(annotation, constructor);
  }

  void _resolveAnnotationElementGetter(
      Annotation annotation, PropertyAccessorElement accessorElement) {
    // accessor should be synthetic
    if (!accessorElement.isSynthetic) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION_GETTER, annotation);
      return;
    }
    // variable should be constant
    VariableElement variableElement = accessorElement.variable;
    if (!variableElement.isConst) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      return;
    }
    // no arguments
    if (annotation.arguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS,
          annotation.name,
          [annotation.name]);
    }
    // OK
    return;
  }

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  ///
  /// TODO(scheglov) this is duplicate
  List<ParameterElement> _resolveArgumentsToFunction(
      ArgumentList argumentList, ExecutableElement executableElement) {
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
  List<ParameterElement> _resolveArgumentsToParameters(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _errorReporter.reportErrorForNode);
  }
}
