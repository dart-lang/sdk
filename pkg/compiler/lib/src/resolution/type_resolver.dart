// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.types;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../elements/resolution_types.dart';
import '../elements/elements.dart'
    show
        AmbiguousElement,
        ClassElement,
        Element,
        Elements,
        ErroneousElement,
        PrefixElement,
        TypedefElement,
        TypeVariableElement;
import '../elements/modelx.dart' show ErroneousElementX;
import '../resolution/resolution.dart';
import '../tree/tree.dart';
import '../universe/feature.dart' show Feature;
import '../util/util.dart' show Link;
import 'members.dart' show lookupInScope;
import 'registry.dart' show ResolutionRegistry;
import 'resolution_common.dart' show MappingVisitor;
import 'scope.dart' show Scope;

class TypeResolver {
  final Resolution resolution;

  TypeResolver(this.resolution);

  ResolverTask get resolver => resolution.resolver;
  DiagnosticReporter get reporter => resolution.reporter;
  Types get types => resolution.types;

  /// Tries to resolve the type name as an element.
  Element resolveTypeName(
      Identifier prefixName, Identifier typeName, Scope scope,
      {bool deferredIsMalformed: true}) {
    Element element;
    if (prefixName != null) {
      Element prefixElement =
          lookupInScope(reporter, prefixName, scope, prefixName.source);
      if (prefixElement != null && prefixElement.isPrefix) {
        // The receiver is a prefix. Lookup in the imported members.
        PrefixElement prefix = prefixElement;
        element = prefix.lookupLocalMember(typeName.source);
        if (element != null && prefix.isDeferred && deferredIsMalformed) {
          element = new ErroneousElementX(MessageKind.DEFERRED_TYPE_ANNOTATION,
              {'node': typeName}, element.name, element);
        }
      } else {
        // The caller of this method will create the ErroneousElement for
        // the MalformedType.
        element = null;
      }
    } else {
      element = lookupInScope(reporter, typeName, scope, typeName.source);
    }
    return element;
  }

  ResolutionDartType resolveTypeAnnotation(
      MappingVisitor visitor, TypeAnnotation node,
      {bool malformedIsError: false, bool deferredIsMalformed: true}) {
    ResolutionRegistry registry = visitor.registry;

    Identifier typeName;
    ResolutionDartType type;

    ResolutionDartType checkNoTypeArguments(ResolutionDartType type) {
      List<ResolutionDartType> arguments = new List<ResolutionDartType>();
      bool hasTypeArgumentMismatch = resolveTypeArguments(
          visitor, node, const <ResolutionDartType>[], arguments);
      if (hasTypeArgumentMismatch) {
        return new MalformedType(
            new ErroneousElementX(MessageKind.TYPE_ARGUMENT_COUNT_MISMATCH,
                {'type': node}, typeName.source, visitor.enclosingElement),
            type,
            arguments);
      }
      return type;
    }

    Identifier prefixName;
    Send send = node.typeName.asSend();
    if (send != null) {
      // The type name is of the form [: prefix . identifier :].
      prefixName = send.receiver.asIdentifier();
      typeName = send.selector.asIdentifier();
    } else {
      typeName = node.typeName.asIdentifier();
      if (identical(typeName.source, 'void')) {
        type = const ResolutionVoidType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      } else if (identical(typeName.source, 'dynamic')) {
        type = const ResolutionDynamicType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      }
    }

    Element element = resolveTypeName(prefixName, typeName, visitor.scope,
        deferredIsMalformed: deferredIsMalformed);

    ResolutionDartType reportFailureAndCreateType(
        MessageKind messageKind, Map messageArguments,
        {ResolutionDartType userProvidedBadType,
        Element erroneousElement,
        List<DiagnosticMessage> infos: const <DiagnosticMessage>[]}) {
      if (malformedIsError) {
        reporter.reportError(
            reporter.createMessage(node, messageKind, messageArguments), infos);
      } else {
        registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
        reporter.reportWarning(
            reporter.createMessage(node, messageKind, messageArguments), infos);
      }
      if (erroneousElement == null) {
        registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
        erroneousElement = new ErroneousElementX(messageKind, messageArguments,
            typeName.source, visitor.enclosingElement);
      }
      List<ResolutionDartType> arguments = <ResolutionDartType>[];
      resolveTypeArguments(
          visitor, node, const <ResolutionDartType>[], arguments);
      return new MalformedType(
          erroneousElement, userProvidedBadType, arguments);
    }

    // Try to construct the type from the element.
    if (element == null) {
      type = reportFailureAndCreateType(
          MessageKind.CANNOT_RESOLVE_TYPE, {'typeName': node.typeName});
    } else if (element.isAmbiguous) {
      AmbiguousElement ambiguous = element;
      type = reportFailureAndCreateType(
          ambiguous.messageKind, ambiguous.messageArguments,
          infos: ambiguous.computeInfos(
              registry.mapping.analyzedElement, reporter));
      ;
    } else if (element.isMalformed) {
      if (element is ErroneousElement) {
        type = reportFailureAndCreateType(
            element.messageKind, element.messageArguments,
            erroneousElement: element);
      } else {
        type = const ResolutionDynamicType();
      }
    } else if (!element.impliesType) {
      type = reportFailureAndCreateType(
          MessageKind.NOT_A_TYPE, {'node': node.typeName});
    } else if (element.library.isPlatformLibrary &&
        element.name == 'FutureOr') {
      type = const ResolutionDynamicType();
      registry.useType(node, type);
      return type;
    } else {
      bool addTypeVariableBoundsCheck = false;
      if (element.isClass) {
        ClassElement cls = element;
        // TODO(johnniwinther): [ensureClassWillBeResolvedInternal] should imply
        // [computeType].
        resolver.ensureClassWillBeResolvedInternal(cls);
        cls.computeType(resolution);
        List<ResolutionDartType> arguments = <ResolutionDartType>[];
        bool hasTypeArgumentMismatch =
            resolveTypeArguments(visitor, node, cls.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadInterfaceType(
              cls.declaration,
              new ResolutionInterfaceType.forUserProvidedBadType(
                  cls.declaration, arguments));
        } else {
          if (arguments.isEmpty) {
            type = cls.rawType;
          } else {
            type = new ResolutionInterfaceType(
                cls.declaration, arguments.toList(growable: false));
            addTypeVariableBoundsCheck =
                arguments.any((ResolutionDartType type) => !type.isDynamic);
          }
        }
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        // TODO(johnniwinther): [ensureResolved] should imply [computeType].
        typdef.ensureResolved(resolution);
        typdef.computeType(resolution);
        List<ResolutionDartType> arguments = <ResolutionDartType>[];
        bool hasTypeArgumentMismatch = resolveTypeArguments(
            visitor, node, typdef.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadTypedefType(
              typdef,
              new ResolutionTypedefType.forUserProvidedBadType(
                  typdef, arguments));
        } else {
          if (arguments.isEmpty) {
            type = typdef.rawType;
          } else {
            type = new ResolutionTypedefType(
                typdef, arguments.toList(growable: false));
            addTypeVariableBoundsCheck =
                arguments.any((ResolutionDartType type) => !type.isDynamic);
          }
        }
      } else if (element.isTypeVariable) {
        TypeVariableElement typeVariable = element;
        Element outer =
            visitor.enclosingElement.outermostEnclosingMemberOrTopLevel;
        if (!outer.isClass &&
            !outer.isTypedef &&
            !Elements.hasAccessToTypeVariable(
                visitor.enclosingElement, typeVariable)) {
          registry.registerFeature(Feature.THROW_RUNTIME_ERROR);
          type = reportFailureAndCreateType(
              MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
              {'typeVariableName': node},
              userProvidedBadType: typeVariable.type);
        } else {
          type = typeVariable.type;
        }
        type = checkNoTypeArguments(type);
      } else {
        reporter.internalError(
            node, "Unexpected element kind ${element.kind}.");
      }
      if (addTypeVariableBoundsCheck) {
        visitor.addDeferredAction(visitor.enclosingElement,
            () => checkTypeVariableBounds(node, type));
      }
    }
    registry.useType(node, type);
    return type;
  }

  /// Checks the type arguments of [type] against the type variable bounds.
  void checkTypeVariableBounds(TypeAnnotation node, GenericType type) {
    void checkTypeVariableBound(_, ResolutionDartType typeArgument,
        ResolutionTypeVariableType typeVariable, ResolutionDartType bound) {
      if (!types.isSubtype(typeArgument, bound)) {
        reporter.reportWarningMessage(
            node, MessageKind.INVALID_TYPE_VARIABLE_BOUND, {
          'typeVariable': typeVariable,
          'bound': bound,
          'typeArgument': typeArgument,
          'thisType': type.element.thisType
        });
      }
    }

    types.checkTypeVariableBounds(type, checkTypeVariableBound);
  }

  /**
   * Resolves the type arguments of [node] and adds these to [arguments].
   *
   * Returns [: true :] if the number of type arguments did not match the
   * number of type variables.
   */
  bool resolveTypeArguments(
      MappingVisitor visitor,
      TypeAnnotation node,
      List<ResolutionDartType> typeVariables,
      List<ResolutionDartType> arguments) {
    if (node.typeArguments == null) {
      return false;
    }
    int expectedVariables = typeVariables.length;
    int index = 0;
    bool typeArgumentCountMismatch = false;
    for (Link<Node> typeArguments = node.typeArguments.nodes;
        !typeArguments.isEmpty;
        typeArguments = typeArguments.tail, index++) {
      if (index > expectedVariables - 1) {
        reporter.reportWarningMessage(
            typeArguments.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
        typeArgumentCountMismatch = true;
      }
      ResolutionDartType argType =
          resolveTypeAnnotation(visitor, typeArguments.head);
      // TODO(karlklose): rewrite to not modify [arguments].
      arguments.add(argType);
    }
    if (index < expectedVariables) {
      reporter.reportWarningMessage(
          node.typeArguments, MessageKind.MISSING_TYPE_ARGUMENT);
      typeArgumentCountMismatch = true;
    }
    return typeArgumentCountMismatch;
  }
}
