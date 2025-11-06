// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A resolver for [ConstructorReference] nodes.
class ConstructorReferenceResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  ConstructorReferenceResolver(this._resolver);

  void resolve(ConstructorReferenceImpl node, {required DartType contextType}) {
    if (!_resolver.isConstructorTearoffsEnabled &&
        node.constructorName.type.typeArguments == null) {
      // Only report this if [node] has no explicit type arguments; otherwise
      // the parser has already reported an error.
      _resolver.diagnosticReporter.atNode(
        node,
        WarningCode.sdkVersionConstructorTearoffs,
      );
    }
    node.constructorName.accept(_resolver);
    var element = node.constructorName.element;
    if (element != null && !element.isFactory) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElementImpl && enclosingElement.isAbstract) {
        _resolver.diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.tearoffOfGenerativeConstructorOfAbstractClass,
        );
      }
    }
    var name = node.constructorName.name;
    if (element == null &&
        name != null &&
        _resolver.isConstructorTearoffsEnabled) {
      // The illegal construction, which looks like a type-instantiated
      // constructor tearoff, may be an attempt to reference a member on
      // [enclosingElement]. Try to provide a helpful error, and fall back to
      // "unknown constructor."
      //
      // Only report errors when the constructor tearoff feature is enabled,
      // to avoid reporting redundant errors.
      var enclosingElement = node.constructorName.type.element;
      if (enclosingElement is TypeAliasElement) {
        var aliasedType = enclosingElement.aliasedType;
        enclosingElement = aliasedType is InterfaceType
            ? aliasedType.element
            : null;
      }
      // TODO(srawlins): Handle `enclosingElement` being a function typedef:
      // typedef F<T> = void Function(); var a = F<int>.extensionOnType;`.
      // This is illegal.
      if (enclosingElement is InterfaceElement) {
        var method =
            enclosingElement.getMethod(name.name) ??
            enclosingElement.getGetter(name.name) ??
            enclosingElement.getSetter(name.name);
        if (method != null) {
          var error = method.isStatic
              ? CompileTimeErrorCode.classInstantiationAccessToStaticMember
              : CompileTimeErrorCode.classInstantiationAccessToInstanceMember;
          _resolver.diagnosticReporter.atNode(
            node,
            error,
            arguments: [name.name],
          );
        } else if (!name.isSynthetic) {
          _resolver.diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode.classInstantiationAccessToUnknownMember,
            arguments: [enclosingElement.name!, name.name],
          );
        }
      }
    }
    _inferArgumentTypes(node, contextType: contextType);
  }

  void _inferArgumentTypes(
    ConstructorReferenceImpl node, {
    required DartType contextType,
  }) {
    var constructorName = node.constructorName;
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      typeElement: constructorName.type.element,
      constructorName: constructorName.name,
      definingLibrary: _resolver.definingLibrary,
    );

    // If the constructor is generic, we'll have a ConstructorMember that
    // substitutes in type arguments (possibly `dynamic`) from earlier in
    // resolution.
    //
    // Otherwise we'll have a ConstructorElement, and we can skip inference
    // because there's nothing to infer in a non-generic type.
    if (elementToInfer != null &&
        elementToInfer.typeParameters.isNotEmpty &&
        constructorName.type.typeArguments == null) {
      // TODO(leafp): Currently, we may re-infer types here, since we
      // sometimes resolve multiple times.  We should really check that we
      // have not already inferred something.  However, the obvious ways to
      // check this don't work, since we may have been instantiated
      // to bounds in an earlier phase, and we *do* want to do inference
      // in that case.

      // Get back to the uninstantiated generic constructor.
      // TODO(jmesserly): should we store this earlier in resolution?
      // Or look it up, instead of jumping backwards through the Member?
      var rawElement = elementToInfer.element.baseElement;
      var constructorType = elementToInfer.asType;

      var inferred =
          _resolver.inferenceHelper.inferTearOff(
                node,
                constructorName.name!,
                constructorType,
                contextType: contextType,
              )
              as FunctionType?;

      if (inferred != null) {
        var inferredReturnType = inferred.returnType as InterfaceType;

        // Update the static element as well. This is used in some cases, such
        // as computing constant values. It is stored in two places.
        var constructorElement = SubstitutedConstructorElementImpl.from2(
          rawElement,
          inferredReturnType,
        );

        constructorName.element = constructorElement.baseElement;
        constructorName.name?.element = constructorElement.baseElement;
        node.recordStaticType(inferred, resolver: _resolver);
        // The NamedType child of `constructorName` doesn't have a static type.
        constructorName.type.type = null;
      }
    } else {
      var constructorElement = constructorName.element;
      node.recordStaticType(
        constructorElement == null
            ? InvalidTypeImpl.instance
            : constructorElement.type,
        resolver: _resolver,
      );
      // The NamedType child of `constructorName` doesn't have a static type.
      constructorName.type.type = null;
    }
  }
}
