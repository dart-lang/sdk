// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.typedefs;

import '../common.dart';
import '../common/resolution.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart'
    show FunctionSignature, TypedefElement, TypeVariableElement;
import '../elements/modelx.dart' show ErroneousElementX, TypedefElementX;
import '../tree/tree.dart';
import '../util/util.dart' show Link;
import 'class_hierarchy.dart' show TypeDefinitionVisitor;
import 'registry.dart' show ResolutionRegistry;
import 'scope.dart' show MethodScope, TypeDeclarationScope;
import 'signatures.dart' show SignatureResolver;
import 'type_resolver.dart' show FunctionTypeParameterScope;

class TypedefResolverVisitor extends TypeDefinitionVisitor {
  TypedefElementX get element => enclosingElement;

  TypedefResolverVisitor(Resolution resolution, TypedefElement typedefElement,
      ResolutionRegistry registry)
      : super(resolution, typedefElement, registry);

  visitTypedef(Typedef node) {
    element.computeType(resolution);
    scope = new TypeDeclarationScope(scope, element);
    resolveTypeVariableBounds(node.templateParameters);

    FunctionTypeParameterScope functionTypeParameters =
        const FunctionTypeParameterScope().expand(node.typeParameters);

    FunctionSignature signature = SignatureResolver.analyze(
        resolution,
        scope,
        functionTypeParameters,
        null, // Don't create type variable types for the type parameters.
        node.formals,
        node.returnType,
        element,
        registry,
        defaultValuesError: MessageKind.TYPEDEF_FORMAL_WITH_DEFAULT);
    element.functionSignature = signature;

    scope = new MethodScope(scope, element);
    signature.forEachParameter(addToScope);

    element.aliasCache = signature.type;

    void checkCyclicReference() {
      element.checkCyclicReference(resolution);
    }

    addDeferredAction(element, checkCyclicReference);
  }
}

// TODO(johnniwinther): Replace with a traversal on the AST when the type
// annotations in typedef alias are stored in a [TreeElements] mapping.
class TypedefCyclicVisitor extends BaseResolutionDartTypeVisitor {
  final DiagnosticReporter reporter;
  final TypedefElementX element;
  bool hasCyclicReference = false;

  Link<TypedefElement> seenTypedefs = const Link<TypedefElement>();

  int seenTypedefsCount = 0;

  Link<TypeVariableElement> seenTypeVariables =
      const Link<TypeVariableElement>();

  TypedefCyclicVisitor(this.reporter, this.element);

  visitType(ResolutionDartType type, _) {
    // Do nothing.
  }

  visitTypedefType(ResolutionTypedefType type, _) {
    TypedefElementX typedefElement = type.element;
    if (seenTypedefs.contains(typedefElement)) {
      if (!hasCyclicReference && identical(element, typedefElement)) {
        // Only report an error on the checked typedef to avoid generating
        // multiple errors for the same cyclicity.
        hasCyclicReference = true;
        if (seenTypedefsCount == 1) {
          // Direct cyclicity.
          reporter.reportErrorMessage(element, MessageKind.CYCLIC_TYPEDEF,
              {'typedefName': element.name});
        } else if (seenTypedefsCount == 2) {
          // Cyclicity through one other typedef.
          reporter.reportErrorMessage(element, MessageKind.CYCLIC_TYPEDEF_ONE, {
            'typedefName': element.name,
            'otherTypedefName': seenTypedefs.head.name
          });
        } else {
          // Cyclicity through more than one other typedef.
          for (TypedefElement cycle in seenTypedefs) {
            if (!identical(typedefElement, cycle)) {
              reporter.reportErrorMessage(
                  element, MessageKind.CYCLIC_TYPEDEF_ONE, {
                'typedefName': element.name,
                'otherTypedefName': cycle.name
              });
            }
          }
        }
        ErroneousElementX erroneousElement = new ErroneousElementX(
            MessageKind.CYCLIC_TYPEDEF,
            {'typedefName': element.name},
            element.name,
            element);
        element.aliasCache =
            new MalformedType(erroneousElement, typedefElement.aliasCache);
        element.hasBeenCheckedForCycles = true;
      }
    } else {
      seenTypedefs = seenTypedefs.prepend(typedefElement);
      seenTypedefsCount++;
      type.visitChildren(this, null);
      if (!typedefElement.isMalformed) {
        typedefElement.aliasCache.accept(this, null);
      }
      seenTypedefs = seenTypedefs.tail;
      seenTypedefsCount--;
    }
  }

  visitFunctionType(ResolutionFunctionType type, _) {
    type.visitChildren(this, null);
  }

  visitInterfaceType(ResolutionInterfaceType type, _) {
    type.visitChildren(this, null);
  }

  visitTypeVariableType(ResolutionTypeVariableType type, _) {
    TypeVariableElement typeVariableElement = type.element;
    if (seenTypeVariables.contains(typeVariableElement)) {
      // Avoid running in cycles on cyclic type variable bounds.
      // Cyclicity is reported elsewhere.
      return;
    }
    seenTypeVariables = seenTypeVariables.prepend(typeVariableElement);
    typeVariableElement.bound.accept(this, null);
    seenTypeVariables = seenTypeVariables.tail;
  }
}
