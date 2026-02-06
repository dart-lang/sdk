// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';

class MethodInvocationResolver with ScopeHelpers {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The type representing the type 'dynamic'.
  final DynamicTypeImpl _dynamicType = DynamicTypeImpl.instance;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 _inheritance;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl _definingLibrary;

  /// The URI of [_definingLibrary].
  final Uri _definingLibraryUri;

  /// The library fragment of the compilation unit being visited.
  final LibraryFragmentImpl _libraryFragment;

  /// The object providing promoted or declared types of variables.
  final LocalVariableTypeProvider _localVariableTypeProvider;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  final InvocationInferenceHelper _inferenceHelper;

  /// The invocation being resolved.
  InvocationExpressionImpl? _invocation;

  /// The [Name] object of the invocation being resolved by [resolve].
  Name? _currentName;

  MethodInvocationResolver(
    this._resolver, {
    required InvocationInferenceHelper inferenceHelper,
  }) : _typeType = _resolver.typeProvider.typeType,
       _inheritance = _resolver.inheritance,
       _definingLibrary = _resolver.definingLibrary,
       _definingLibraryUri = _resolver.definingLibrary.uri,
       _libraryFragment = _resolver.libraryFragment,
       _localVariableTypeProvider = _resolver.localVariableTypeProvider,
       _extensionResolver = _resolver.extensionResolver,
       _inferenceHelper = inferenceHelper;

  @override
  DiagnosticReporter get diagnosticReporter => _resolver.diagnosticReporter;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  /// Resolves the method invocation, [node].
  void resolve(
    MethodInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    _invocation = node;

    var nameNode = node.methodName;
    String name = nameNode.name;
    _currentName = Name(_definingLibraryUri, name);

    var receiver = node.realTarget;

    if (receiver == null) {
      return _resolveReceiverNull(
        node,
        nameNode,
        name,
        whyNotPromotedArguments,
        contextType: contextType,
      );
    }

    if (receiver is SimpleIdentifierImpl) {
      var receiverElement = receiver.element;
      if (receiverElement is PrefixElementImpl) {
        return _resolveReceiverPrefix(
          node,
          receiverElement,
          nameNode,
          name,
          whyNotPromotedArguments,
          contextType: contextType,
        );
      }
    }

    if (receiver is IdentifierImpl) {
      var receiverElement = receiver.element;
      if (receiverElement is ExtensionElementImpl) {
        return _resolveExtensionMember(
          node,
          receiver,
          receiverElement,
          nameNode,
          name,
          whyNotPromotedArguments,
          contextType: contextType,
        );
      }
    }

    if (receiver is SuperExpressionImpl) {
      return _resolveReceiverSuper(
        node,
        receiver,
        nameNode,
        name,
        whyNotPromotedArguments,
        contextType: contextType,
      );
    }

    if (receiver is ExtensionOverrideImpl) {
      return _resolveExtensionOverride(
        node,
        receiver,
        nameNode,
        name,
        whyNotPromotedArguments,
        contextType: contextType,
      );
    }

    if (receiver is IdentifierImpl) {
      var element = receiver.element;
      if (element is InterfaceElement) {
        return _resolveReceiverTypeLiteral(
          node,
          element,
          nameNode,
          name,
          whyNotPromotedArguments,
          contextType: contextType,
        );
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          return _resolveReceiverTypeLiteral(
            node,
            aliasedType.element,
            nameNode,
            name,
            whyNotPromotedArguments,
            contextType: contextType,
          );
        }
      }
    }

    TypeImpl receiverType = receiver.typeOrThrow;

    if (_typeSystem.isDynamicBounded(receiverType)) {
      _resolveReceiverDynamicBounded(
        node,
        receiverType,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    if (receiverType is NeverTypeImpl) {
      return _resolveReceiverNever(
        node,
        receiver,
        receiverType,
        whyNotPromotedArguments,
        contextType: contextType,
        nameNode: nameNode,
        name: name,
      );
    }

    if (receiverType is VoidType) {
      _setInvalidTypeResolution(
        node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      _reportUseOfVoidType(receiver);
      return;
    }

    if (node.isNullAware) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    if (receiver is TypeLiteralImpl &&
        receiver.type.typeArguments != null &&
        receiver.type.type is FunctionType) {
      // There is no possible resolution for a property access of a function
      // type literal (which can only be a type instantiation of a type alias
      // of a function type).
      _resolver.diagnosticReporter.report(
        diag.undefinedMethodOnFunctionType
            .withArguments(
              methodName: name,
              functionTypeAliasName: receiver.type.qualifiedName,
            )
            .at(nameNode),
      );
      _setInvalidTypeResolution(
        node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    _resolveReceiverType(
      node: node,
      receiver: receiver,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: receiver,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
  }

  /// Resolves the dot shorthand invocation, [node].
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] or a
  /// [DotShorthandConstructorInvocation] in the process, then returns that new
  /// node. Otherwise, returns `null`.
  RewrittenMethodInvocationImpl? resolveDotShorthand(
    DotShorthandInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    _invocation = node;

    TypeImpl dotShorthandContextType = _resolver
        .getDotShorthandContext()
        .unwrapTypeSchemaView();

    // The static namespace denoted by `S` is also the namespace denoted by
    // `FutureOr<S>`.
    dotShorthandContextType = _resolver.typeSystem.futureOrBase(
      dotShorthandContextType,
    );

    if (dotShorthandContextType case InterfaceTypeImpl(
      :var element,
    ) when element.isAccessibleIn(_resolver.definingLibrary)) {
      return _resolveReceiverTypeLiteralForDotShorthand(
        node,
        element,
        node.memberName,
        node.memberName.name,
        whyNotPromotedArguments,
        contextType: contextType,
      );
    }

    _resolver.diagnosticReporter.report(
      diag.dotShorthandUndefinedInvocation
          .withArguments(
            name: node.memberName.name,
            contextType: contextType.getDisplayString(),
          )
          .at(node.memberName),
    );
    _setInvalidTypeResolutionForDotShorthand(
      node,
      setNameTypeToDynamic: false,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
    return null;
  }

  bool _hasMatchingObjectMethod(
    MethodElement target,
    NodeListImpl<ExpressionImpl> arguments,
  ) {
    return arguments.length == target.formalParameters.length &&
        !arguments.any((e) => e is NamedExpression);
  }

  bool _isCoreFunction(DartType type) {
    // TODO(scheglov): Can we optimize this?
    return type is InterfaceType && type.isDartCoreFunction;
  }

  void _reportInstanceAccessToStaticMember(
    SimpleIdentifier nameNode,
    ExecutableElement element,
    bool nullReceiver,
  ) {
    var enclosingElement = element.enclosingElement!;
    if (nullReceiver) {
      if (_resolver.enclosingExtension != null) {
        _resolver.diagnosticReporter.report(
          diag.unqualifiedReferenceToStaticMemberOfExtendedType
              .withArguments(name: enclosingElement.displayString())
              .at(nameNode),
        );
      } else {
        _resolver.diagnosticReporter.report(
          diag.unqualifiedReferenceToNonLocalStaticMember
              .withArguments(name: enclosingElement.displayString())
              .at(nameNode),
        );
      }
    } else if (enclosingElement is ExtensionElement &&
        enclosingElement.name == null) {
      _resolver.diagnosticReporter.report(
        diag.instanceAccessToStaticMemberOfUnnamedExtension
            .withArguments(name: nameNode.name, kind: element.kind.displayName)
            .at(nameNode),
      );
    } else {
      // It is safe to assume that `enclosingElement.name` is non-`null` because
      // it can only be `null` for extensions, and we handle that case above.
      _resolver.diagnosticReporter.report(
        diag.instanceAccessToStaticMember
            .withArguments(
              memberName: nameNode.name,
              memberKind: element.kind.displayName,
              enclosingElementName: enclosingElement.name!,
              enclosingElementKind: enclosingElement is MixinElement
                  ? 'mixin'
                  : enclosingElement.kind.displayName,
            )
            .at(nameNode),
      );
    }
  }

  void _reportInvocationOfNonFunction(SimpleIdentifierImpl methodName) {
    _resolver.diagnosticReporter.report(
      diag.invocationOfNonFunction
          .withArguments(name: methodName.name)
          .at(methodName),
    );
  }

  void _reportPrefixIdentifierNotFollowedByDot(SimpleIdentifier target) {
    _resolver.diagnosticReporter.report(
      diag.prefixIdentifierNotFollowedByDot
          .withArguments(name: target.name)
          .at(target),
    );
  }

  void _reportStaticAccessToInstanceMember(
    ExecutableElement element,
    SimpleIdentifier nameNode,
  ) {
    if (!element.isStatic) {
      _resolver.diagnosticReporter.report(
        diag.staticAccessToInstanceMember
            .withArguments(name: nameNode.name)
            .at(nameNode),
      );
    }
  }

  void _reportUndefinedFunction(
    MethodInvocationImpl node, {
    required String? prefix,
    required String name,
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    _setInvalidTypeResolution(
      node,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );

    if (_libraryFragment.shouldIgnoreUndefined(prefix: prefix, name: name)) {
      return;
    }

    _resolver.diagnosticReporter.report(
      diag.undefinedFunction
          .withArguments(name: node.methodName.name)
          .at(node.methodName),
    );
  }

  void _reportUndefinedMethodOrNew(
    InterfaceElement receiver,
    SimpleIdentifierImpl methodName,
  ) {
    if (methodName.name == 'new') {
      // Attempting to invoke the unnamed constructor via `C.new(`.
      if (_resolver.isConstructorTearoffsEnabled) {
        _resolver.diagnosticReporter.report(
          diag.newWithUndefinedConstructorDefault
              .withArguments(className: receiver.displayName)
              .at(methodName),
        );
      } else {
        // [ParserErrorCode.EXPERIMENT_NOT_ENABLED] is reported by the parser.
        // Do not report extra errors.
      }
    } else {
      _resolver.diagnosticReporter.report(
        diag.undefinedMethod
            .withArguments(
              methodName: methodName.name,
              typeName: receiver.displayName,
            )
            .at(methodName),
      );
    }
  }

  void _reportUseOfVoidType(AstNode errorNode) {
    _resolver.diagnosticReporter.report(diag.useOfVoidResult.at(errorNode));
  }

  void _resolveArguments_finishDotShorthandInference(
    DotShorthandInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    DartType staticStaticType = DotShorthandInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: null,
    ).resolveInvocation();
    node.recordStaticType(staticStaticType, resolver: _resolver);
  }

  void _resolveArguments_finishInference(
    MethodInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    DartType staticStaticType = MethodInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: null,
    ).resolveInvocation();
    node.recordStaticType(staticStaticType, resolver: _resolver);
  }

  /// Given that we are accessing a property of the given [classElement] with the
  /// given [propertyName], return the element that represents the property.
  Element? _resolveElement(
    InterfaceElement classElement,
    SimpleIdentifier propertyName,
  ) {
    // TODO(scheglov): Replace with class hierarchy.
    String name = propertyName.name;
    Element? element;
    if (propertyName.inSetterContext()) {
      element = classElement.getSetter(name);
    }
    element ??= classElement.getGetter(name);
    element ??= classElement.getMethod(name);
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  /// Resolves the method invocation, [node], as an extension member.
  void _resolveExtensionMember(
    MethodInvocationImpl node,
    Identifier receiver,
    ExtensionElementImpl extension,
    SimpleIdentifierImpl nameNode,
    String name,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var getter = extension.getGetter(name);
    if (getter != null) {
      nameNode.element = getter;
      _reportStaticAccessToInstanceMember(getter, nameNode);
      _rewriteAsFunctionExpressionInvocation(
        node,
        node.target,
        node.operator,
        node.methodName,
        node.typeArguments,
        node.argumentList,
        getter.returnType,
        isCascaded: node.isCascaded,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    var method = extension.getMethod(name);
    if (method != null) {
      nameNode.element = method;
      _reportStaticAccessToInstanceMember(method, nameNode);
      _setResolution(
        node,
        method.type,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetExecutableElement(method),
      );
      return;
    }

    _setInvalidTypeResolution(
      node,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
    // This method is only called for named extensions, so we know that
    // `extension.name` is non-`null`.
    _resolver.diagnosticReporter.report(
      diag.undefinedExtensionMethod
          .withArguments(methodName: name, extensionName: extension.name!)
          .at(nameNode),
    );
  }

  /// Resolves the method invocation, [node], as called on an extension
  /// override.
  void _resolveExtensionOverride(
    MethodInvocationImpl node,
    ExtensionOverrideImpl override,
    SimpleIdentifierImpl nameNode,
    String name,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var result = _extensionResolver.getOverrideMember(override, name);
    var member = result.getter2;

    if (member == null) {
      _setInvalidTypeResolution(
        node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      // Extension overrides always refer to named extensions, so we can safely
      // assume `override.staticElement!.name` is non-`null`.
      _resolver.diagnosticReporter.report(
        diag.undefinedExtensionMethod
            .withArguments(
              methodName: name,
              extensionName: override.element.name!,
            )
            .at(nameNode),
      );
      return;
    }

    if (member.isStatic) {
      _resolver.diagnosticReporter.report(
        diag.extensionOverrideAccessToStaticMember.at(nameNode),
      );
    }

    if (node.isCascaded) {
      // Report this error and recover by treating it like a non-cascade.
      _resolver.diagnosticReporter.report(
        diag.extensionOverrideWithCascade.at(override.name),
      );
    }

    nameNode.element = member;

    if (member is InternalPropertyAccessorElement) {
      _rewriteAsFunctionExpressionInvocation(
        node,
        node.target,
        node.operator,
        node.methodName,
        node.typeArguments,
        node.argumentList,
        member.returnType,
        isCascaded: node.isCascaded,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    _setResolution(
      node,
      member.type,
      whyNotPromotedArguments,
      contextType: contextType,
      target: InvocationTargetExecutableElement(member),
    );
  }

  void _resolveReceiverDynamicBounded(
    MethodInvocationImpl node,
    DartType receiverType,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var nameNode = node.methodName;

    var objectElement = _typeSystem.typeProvider.objectElement;
    var targetElement = objectElement.getMethod(nameNode.name);

    InvocationTargetExecutableElement? target;
    if (receiverType is InvalidType) {
      nameNode.element = null;
      nameNode.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
      node.staticInvokeType = InvalidTypeImpl.instance;
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
    } else if (targetElement != null &&
        !targetElement.isStatic &&
        _hasMatchingObjectMethod(targetElement, node.argumentList.arguments)) {
      nameNode.element = targetElement;
      target = InvocationTargetExecutableElement(targetElement);
      nameNode.setPseudoExpressionStaticType(targetElement.type);
      node.staticInvokeType = targetElement.type;
      node.recordStaticType(targetElement.returnType, resolver: _resolver);
    } else {
      nameNode.element = null;
      nameNode.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      node.staticInvokeType = DynamicTypeImpl.instance;
      node.recordStaticType(DynamicTypeImpl.instance, resolver: _resolver);
    }

    _setExplicitTypeArgumentTypes();
    MethodInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
      target: target,
    ).resolveInvocation();
  }

  /// Resolves the method invocation, [node], as an instance invocation on an
  /// expression of type `Never` or `Never?`.
  void _resolveReceiverNever(
    MethodInvocationImpl node,
    ExpressionImpl receiver,
    TypeImpl receiverType,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required SimpleIdentifierImpl nameNode,
    required String name,
  }) {
    _setExplicitTypeArgumentTypes();

    if (receiverType == NeverTypeImpl.instanceNullable) {
      var methodName = node.methodName;
      var objectElement = _resolver.typeProvider.objectElement;
      var objectMember = objectElement.getMethod(methodName.name);
      if (objectMember != null) {
        methodName.element = objectMember;
        _setResolution(
          node,
          objectMember.type,
          whyNotPromotedArguments,
          contextType: contextType,
          target: InvocationTargetExecutableElement(objectMember),
        );
        return;
      } else {
        return _resolveReceiverType(
          node: node,
          receiver: receiver,
          receiverType: receiverType,
          nameNode: nameNode,
          name: name,
          receiverErrorNode: receiver,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
      }
    }

    if (receiverType == NeverTypeImpl.instance) {
      MethodInvocationInferrer(
        resolver: _resolver,
        node: node,
        argumentList: node.argumentList,
        contextType: contextType,
        whyNotPromotedArguments: whyNotPromotedArguments,
        target: null,
      ).resolveInvocation();

      _resolver.diagnosticReporter.report(
        diag.receiverOfTypeNever.at(receiver),
      );

      node.methodName.setPseudoExpressionStaticType(_dynamicType);
      node.staticInvokeType = _dynamicType;
      node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
    }
  }

  /// Resolves the method invocation, [node], as an instance invocation on an
  /// expression of type `Null`.
  void _resolveReceiverNull(
    MethodInvocationImpl node,
    SimpleIdentifierImpl nameNode,
    String name,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var scopeLookupResult = nameNode.scopeLookupResult!;
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      nameToken: nameNode.token,
    );

    var element = scopeLookupResult.getter;
    if (element != null) {
      nameNode.element = element;
      if (element is MultiplyDefinedElement) {
        element = element.conflictingElements[0];
      }
      if (element is InternalPropertyAccessorElement) {
        _rewriteAsFunctionExpressionInvocation(
          node,
          node.target,
          node.operator,
          node.methodName,
          node.typeArguments,
          node.argumentList,
          element.returnType,
          isCascaded: node.isCascaded,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
        return;
      }
      if (element is InternalExecutableElement) {
        _setResolution(
          node,
          element.type,
          whyNotPromotedArguments,
          contextType: contextType,
          target: InvocationTargetExecutableElement(element),
        );
        return;
      }
      if (element is VariableElement) {
        _resolver.checkReadOfNotAssignedLocalVariable(nameNode, element);
        var targetType = _localVariableTypeProvider.getType(
          nameNode,
          isRead: true,
        );
        _rewriteAsFunctionExpressionInvocation(
          node,
          node.target,
          node.operator,
          node.methodName,
          node.typeArguments,
          node.argumentList,
          targetType,
          isCascaded: node.isCascaded,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
        return;
      }
      // TODO(scheglov): This is a questionable distinction.
      if (element is PrefixElement) {
        _setInvalidTypeResolution(
          node,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
        _reportPrefixIdentifierNotFollowedByDot(nameNode);
        return;
      }
      _setInvalidTypeResolution(
        node,
        setNameTypeToDynamic: false,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      _reportInvocationOfNonFunction(node.methodName);
      return;
    }

    var receiverType = _resolver.thisType;
    if (receiverType == null) {
      _reportUndefinedFunction(
        node,
        prefix: null,
        name: node.methodName.name,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    element = scopeLookupResult.setter;
    if (element != null) {
      // If the scope lookup reveals a setter, but no getter, then we may still
      // find the getter by looking up the inheritance chain (via
      // TypePropertyResolver, via `_resolveReceiverType`). However, if the
      // setter that was found is either top-level, or declared in an extension,
      // or is static, then we do not keep searching for the getter; this
      // setter represents the property being accessed (erroneously).
      var noGetterIsPossible =
          element.enclosingElement is LibraryElement ||
          element.enclosingElement is ExtensionElement ||
          (element is ExecutableElement && element.isStatic);
      if (noGetterIsPossible) {
        nameNode.element = element;

        _setInvalidTypeResolution(
          node,
          setNameTypeToDynamic: false,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
        var receiverTypeName = switch (receiverType) {
          InterfaceTypeImpl() => receiverType.element.name!,
          FunctionType() => 'Function',
          _ => '<unknown>',
        };
        _resolver.diagnosticReporter.report(
          diag.undefinedMethod
              .withArguments(methodName: name, typeName: receiverTypeName)
              .at(nameNode),
        );
        return;
      }
    }

    _resolveReceiverType(
      node: node,
      receiver: null,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: nameNode,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
  }

  /// Resolves the method invocation, [node], as a top-level function
  /// invocation, referenced with a prefix.
  void _resolveReceiverPrefix(
    MethodInvocationImpl node,
    PrefixElementImpl prefix,
    SimpleIdentifierImpl nameNode,
    String name,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    // Note: prefix?.bar is reported as an error in ElementResolver.

    if (name == TopLevelFunctionElement.LOAD_LIBRARY_NAME) {
      var imports = prefix.imports;
      if (imports.length == 1) {
        var firstPrefix = imports[0].prefix;
        if (firstPrefix != null && firstPrefix.isDeferred) {
          var importedLibrary = imports[0].importedLibrary;
          var element = importedLibrary?.loadLibraryFunction;
          if (element != null) {
            nameNode.element = element;
            _setResolution(
              node,
              element.type,
              whyNotPromotedArguments,
              contextType: contextType,
              target: InvocationTargetExecutableElement(element),
            );
            return;
          }
        }
      }
    }

    var scopeLookupResult = prefix.scope.lookup(name);
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      nameToken: nameNode.token,
    );

    var element = scopeLookupResult.getter;
    nameNode.element = element;

    if (element is MultiplyDefinedElement) {
      element = element.conflictingElements[0];
    }

    if (element is InternalPropertyAccessorElement) {
      _rewriteAsFunctionExpressionInvocation(
        node,
        node.target,
        node.operator,
        node.methodName,
        node.typeArguments,
        node.argumentList,
        element.returnType,
        isCascaded: node.isCascaded,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    if (element is InternalExecutableElement) {
      _setResolution(
        node,
        element.type,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetExecutableElement(element),
      );
      return;
    }

    _reportUndefinedFunction(
      node,
      prefix: prefix.name,
      name: name,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
  }

  /// Resolves the method invocation, [node], as an instance invocation a
  /// `super` expression.
  void _resolveReceiverSuper(
    MethodInvocationImpl node,
    SuperExpression receiver,
    SimpleIdentifierImpl nameNode,
    String name,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null ||
        SuperContext.of(receiver) != SuperContext.valid) {
      _setInvalidTypeResolution(
        node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    var target = _inheritance.getMember(
      enclosingClass,
      _currentName!,
      forSuper: true,
    );

    // If there is that concrete dispatch target, then we are done.
    if (target != null) {
      nameNode.element = target;
      if (target is InternalPropertyAccessorElement) {
        _rewriteAsFunctionExpressionInvocation(
          node,
          node.target,
          node.operator,
          node.methodName,
          node.typeArguments,
          node.argumentList,
          target.returnType,
          isCascaded: node.isCascaded,
          isSuperAccess: true,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
        return;
      }
      _setResolution(
        node,
        target.type,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetExecutableElement(target),
      );
      return;
    }

    // Otherwise, this is an error.
    // But we would like to give the user at least some resolution.
    // So, we try to find the interface target.
    target = _inheritance.getInherited(enclosingClass, _currentName!);
    if (target != null) {
      nameNode.element = target;
      _setResolution(
        node,
        target.type,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetExecutableElement(target),
      );

      _resolver.diagnosticReporter.report(
        diag.abstractSuperMemberReference
            .withArguments(memberKind: target.kind.displayName, name: name)
            .at(nameNode),
      );
      return;
    }

    // Nothing help, there is no target at all.
    _setInvalidTypeResolution(
      node,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
    _resolver.diagnosticReporter.report(
      diag.undefinedSuperMethod
          .withArguments(
            methodName: name,
            typeName: enclosingClass.firstFragment.displayName,
          )
          .at(nameNode),
    );
  }

  /// Resolves the type of the receiver of the method invocation, [node].
  void _resolveReceiverType({
    required MethodInvocationImpl node,
    required ExpressionImpl? receiver,
    required TypeImpl receiverType,
    required SimpleIdentifierImpl nameNode,
    required String name,
    required Expression receiverErrorNode,
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: name,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: nameNode,
      nameErrorEntity: nameNode,
    );

    var callFunctionType = result.callFunctionType;
    if (callFunctionType != null) {
      assert(name == MethodElement.CALL_METHOD_NAME);
      _setResolution(
        node,
        callFunctionType,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetFunctionTypedExpression(callFunctionType),
      );
      // TODO(scheglov): Replace this with using FunctionType directly.
      // Here was erase resolution that _setResolution() sets.
      nameNode.element = null;
      nameNode.setPseudoExpressionStaticType(_dynamicType);
      return;
    }

    if (receiverType.isDartCoreFunction &&
        name == MethodElement.CALL_METHOD_NAME) {
      _setResolution(
        node,
        DynamicTypeImpl.instance,
        whyNotPromotedArguments,
        contextType: contextType,
        target: null,
      );
      nameNode.element = null;
      nameNode.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      node.staticInvokeType = DynamicTypeImpl.instance;
      node.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      return;
    }

    var recordField = result.recordField;
    if (recordField != null) {
      _rewriteAsFunctionExpressionInvocation(
        node,
        node.target,
        node.operator,
        node.methodName,
        node.typeArguments,
        node.argumentList,
        recordField.type,
        isCascaded: node.isCascaded,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    var target = result.getter2;
    if (target != null) {
      nameNode.element = target;

      if (target.isStatic) {
        _reportInstanceAccessToStaticMember(nameNode, target, receiver == null);
      }

      if (target is PropertyAccessorElement) {
        _rewriteAsFunctionExpressionInvocation(
          node,
          node.target,
          node.operator,
          node.methodName,
          node.typeArguments,
          node.argumentList,
          target.returnType,
          isCascaded: node.isCascaded,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
        return;
      }
      _setResolution(
        node,
        target.type,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetExecutableElement(target),
      );
      return;
    }

    _setInvalidTypeResolution(
      node,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );

    if (!result.needsGetterError) {
      return;
    }

    String receiverClassName = '<unknown>';
    if (receiverType is InterfaceTypeImpl) {
      if (receiverType.element.name case var name?) {
        receiverClassName = name;
      } else {
        return;
      }
    } else if (receiverType is FunctionType) {
      receiverClassName = 'Function';
    }

    if (!nameNode.isSynthetic) {
      _resolver.diagnosticReporter.report(
        diag.undefinedMethod
            .withArguments(methodName: name, typeName: receiverClassName)
            .at(nameNode),
      );
    }
  }

  /// Resolves the method invocation, [node], as an method invocation with a
  /// type literal target.
  void _resolveReceiverTypeLiteral(
    MethodInvocationImpl node,
    InterfaceElement receiver,
    SimpleIdentifierImpl nameNode,
    String name,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    if (node.isCascaded) {
      receiver = _typeType.element;
    }

    var element = _resolveElement(receiver, nameNode);
    if (element != null) {
      if (element is InternalExecutableElement) {
        nameNode.element = element;
        if (element is InternalPropertyAccessorElement) {
          _rewriteAsFunctionExpressionInvocation(
            node,
            node.target,
            node.operator,
            node.methodName,
            node.typeArguments,
            node.argumentList,
            element.returnType,
            isCascaded: node.isCascaded,
            whyNotPromotedArguments: whyNotPromotedArguments,
            contextType: contextType,
          );
          return;
        }
        _setResolution(
          node,
          element.type,
          whyNotPromotedArguments,
          contextType: contextType,
          target: InvocationTargetExecutableElement(element),
        );
      } else {
        _setInvalidTypeResolution(
          node,
          setNameTypeToDynamic: false,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
        _reportInvocationOfNonFunction(nameNode);
      }
      return;
    }

    _setInvalidTypeResolution(
      node,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
    _reportUndefinedMethodOrNew(receiver, nameNode);
  }

  /// Resolves the dot shorthand invocation, [node], as an method invocation
  /// with a type literal target.
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] or a
  /// [DotShorthandConstructorInvocation] in the process, then returns that new
  /// node. Otherwise, returns `null`.
  RewrittenMethodInvocationImpl? _resolveReceiverTypeLiteralForDotShorthand(
    DotShorthandInvocationImpl node,
    InterfaceElement receiver,
    SimpleIdentifierImpl nameNode,
    String name,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var element = _resolveElement(receiver, node.memberName);
    if (element is InternalExecutableElement && element.isStatic) {
      node.memberName.element = element;
      if (element is InternalPropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(
          node,
          null,
          node.period,
          node.memberName,
          node.typeArguments,
          node.argumentList,
          element.returnType,
          isCascaded: false,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
      }
      _setResolutionForDotShorthand(
        node,
        element.type,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetExecutableElement(element),
      );
      return null;
    } else if (receiver.getNamedConstructor(name)
        case ConstructorElementImpl element?
        when element.isAccessibleIn(_resolver.definingLibrary)) {
      // The dot shorthand is a constructor invocation so we rewrite to a
      // [DotShorthandConstructorInvocation].
      var replacement =
          DotShorthandConstructorInvocationImpl(
              constKeyword: null,
              period: node.period,
              constructorName: nameNode,
              typeArguments: node.typeArguments,
              argumentList: node.argumentList,
            )
            ..element = element
            ..isDotShorthand = node.isDotShorthand;
      _resolver.replaceExpression(node, replacement);
      _resolver.flowAnalysis.transferTestData(node, replacement);
      _resolver.instanceCreationExpressionResolver.resolveDotShorthand(
        replacement,
        contextType: contextType,
      );
      return replacement;
    }

    _resolver.diagnosticReporter.report(
      diag.dotShorthandUndefinedInvocation
          .withArguments(name: nameNode.name, contextType: receiver.displayName)
          .at(nameNode),
    );
    _setInvalidTypeResolutionForDotShorthand(
      node,
      setNameTypeToDynamic: element == null,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
    return null;
  }

  /// Rewrites [node] as a [FunctionExpressionInvocation].
  ///
  /// We have identified that [node] is not a real [MethodInvocation],
  /// because it does not invoke a method, but instead invokes the result
  /// of a getter execution, or implicitly invokes the `call` method of
  /// an [InterfaceType]. So, it should be represented as instead as a
  /// [FunctionExpressionInvocation].
  FunctionExpressionInvocationImpl _rewriteAsFunctionExpressionInvocation(
    ExpressionImpl node,
    ExpressionImpl? target,
    Token? operator,
    SimpleIdentifierImpl methodName,
    TypeArgumentListImpl? typeArguments,
    ArgumentListImpl argumentList,
    TypeImpl getterReturnType, {
    required bool isCascaded,
    bool isSuperAccess = false,
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    var targetType = getterReturnType;

    ExpressionImpl functionExpression;
    if (target == null) {
      if (node is DotShorthandInvocationImpl) {
        functionExpression = DotShorthandPropertyAccessImpl(
          period: node.period,
          propertyName: node.memberName,
        );
      } else if (isCascaded) {
        functionExpression = PropertyAccessImpl(
          target: null,
          operator: operator!,
          propertyName: methodName,
        );
      } else {
        functionExpression = methodName;
      }

      var element = methodName.element;
      if (element is ExecutableElement &&
          element.enclosingElement is InstanceElement &&
          !element.isStatic) {
        if (_resolver.flowAnalysis.flow case var flow?) {
          var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
            isCascaded
                ? CascadePropertyTarget.singleton
                : ThisPropertyTarget.singleton,
            methodName.name,
            element,
            SharedTypeView(getterReturnType),
          );
          flow.storeExpressionInfo(functionExpression, expressionInfo);
          targetType = wrappedPromotedType?.unwrapTypeView() ?? targetType;
        }
      }
    } else {
      if (target is SimpleIdentifierImpl && target.element is PrefixElement) {
        functionExpression = PrefixedIdentifierImpl(
          prefix: target,
          period: operator!,
          identifier: methodName,
        );
      } else {
        functionExpression = PropertyAccessImpl(
          target: target,
          operator: operator!,
          propertyName: methodName,
        );
      }
      if (_resolver.flowAnalysis.flow case var flow?) {
        var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
          target is SuperExpressionImpl
              ? SuperPropertyTarget.singleton
              : ExpressionPropertyTarget(target),
          methodName.name,
          methodName.element,
          SharedTypeView(getterReturnType),
        );
        flow.storeExpressionInfo(functionExpression, expressionInfo);
        targetType = wrappedPromotedType?.unwrapTypeView() ?? targetType;
      }
    }
    inferenceLogWriter?.enterFunctionExpressionInvocationTarget(methodName);
    methodName.recordStaticType(targetType, resolver: _resolver);
    inferenceLogWriter?.exitExpression(methodName);

    if (functionExpression != methodName) {
      functionExpression.setPseudoExpressionStaticType(targetType);
    }

    var invocation = FunctionExpressionInvocationImpl(
      function: functionExpression,
      typeArguments: typeArguments,
      argumentList: argumentList,
    );
    _resolver.replaceExpression(node, invocation);
    _resolver.flowAnalysis.transferTestData(node, invocation);
    _resolver.functionExpressionInvocationResolver.resolve(
      invocation,
      whyNotPromotedArguments,
      contextType: contextType,
    );
    return invocation;
  }

  void _setDynamicTypeResolution(
    MethodInvocationImpl node, {
    bool setNameTypeToDynamic = true,
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    if (setNameTypeToDynamic) {
      node.methodName.setPseudoExpressionStaticType(_dynamicType);
    }
    node.staticInvokeType = _dynamicType;
    node.setPseudoExpressionStaticType(_dynamicType);
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishInference(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
    );
  }

  void _setDynamicTypeResolutionForDotShorthand(
    DotShorthandInvocationImpl node, {
    bool setNameTypeToDynamic = true,
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    if (setNameTypeToDynamic) {
      node.memberName.setPseudoExpressionStaticType(_dynamicType);
    }
    node.staticInvokeType = _dynamicType;
    node.setPseudoExpressionStaticType(_dynamicType);
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishDotShorthandInference(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
    );
  }

  /// Set explicitly specified type argument types, or empty if not specified.
  /// Inference is done in type analyzer, so inferred type arguments might be
  /// set later.
  ///
  // TODO(scheglov): when we do inference in this resolver, do we need this?
  void _setExplicitTypeArgumentTypes() {
    var typeArgumentList = _invocation!.typeArguments;
    if (typeArgumentList != null) {
      var arguments = typeArgumentList.arguments;
      _invocation!.typeArgumentTypes = arguments
          .map((n) => n.typeOrThrow)
          .toList();
    } else {
      _invocation!.typeArgumentTypes = [];
    }
  }

  void _setInvalidTypeResolution(
    MethodInvocationImpl node, {
    bool setNameTypeToDynamic = true,
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    if (setNameTypeToDynamic) {
      node.methodName.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
    }
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishInference(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
    );
    node.staticInvokeType = InvalidTypeImpl.instance;
    node.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
  }

  void _setInvalidTypeResolutionForDotShorthand(
    DotShorthandInvocationImpl node, {
    bool setNameTypeToDynamic = true,
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    if (setNameTypeToDynamic) {
      node.memberName.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
    }
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishDotShorthandInference(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
    );
    node.staticInvokeType = InvalidTypeImpl.instance;
    node.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
  }

  void _setResolution(
    MethodInvocationImpl node,
    TypeImpl type,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required InvocationTarget? target,
  }) {
    inferenceLogWriter?.recordLookupResult(
      expression: node,
      type: type,
      target: node.target,
      methodName: node.methodName.name,
    );
    // TODO(scheglov): We need this for StaticTypeAnalyzer to run inference.
    // But it seems weird. Do we need to know the raw type of a function?!
    node.methodName.setPseudoExpressionStaticType(type);

    if (type == _dynamicType || _isCoreFunction(type)) {
      _setDynamicTypeResolution(
        node,
        setNameTypeToDynamic: false,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    if (type is FunctionTypeImpl) {
      _inferenceHelper.resolveMethodInvocation(
        node: node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
        target: target,
      );
      return;
    }

    if (type is VoidType) {
      _setInvalidTypeResolution(
        node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return _reportUseOfVoidType(node.methodName);
    }

    _setInvalidTypeResolution(
      node,
      setNameTypeToDynamic: false,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
    _reportInvocationOfNonFunction(node.methodName);
  }

  void _setResolutionForDotShorthand(
    DotShorthandInvocationImpl node,
    TypeImpl type,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required InvocationTarget target,
  }) {
    inferenceLogWriter?.recordLookupResult(
      expression: node,
      type: type,
      target: null,
      methodName: node.memberName.name,
    );
    // TODO(scheglov): We need this for StaticTypeAnalyzer to run inference.
    // But it seems weird. Do we need to know the raw type of a function?!
    node.memberName.setPseudoExpressionStaticType(type);

    if (type == _dynamicType || _isCoreFunction(type)) {
      _setDynamicTypeResolutionForDotShorthand(
        node,
        setNameTypeToDynamic: false,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    if (type is FunctionTypeImpl) {
      _inferenceHelper.resolveDotShorthandInvocation(
        node: node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
        target: target,
      );
      return;
    }

    if (type is VoidType) {
      _setInvalidTypeResolutionForDotShorthand(
        node,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return _reportUseOfVoidType(node.memberName);
    }

    _setInvalidTypeResolutionForDotShorthand(
      node,
      setNameTypeToDynamic: false,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );
    _reportInvocationOfNonFunction(node.memberName);
  }
}
