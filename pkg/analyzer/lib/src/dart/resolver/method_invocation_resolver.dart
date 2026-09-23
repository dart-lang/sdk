// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
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

class MethodInvocationResolver with ScopeHelpers {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The type representing the type 'dynamic'.
  final DynamicTypeImpl _dynamicType = DynamicTypeImpl.instance;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 _inheritance;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl _definingLibrary;

  /// The URI of [_definingLibrary].
  final Uri _definingLibraryUri;

  /// The library fragment of the compilation unit being visited.
  final LibraryFragmentImpl _libraryFragment;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  final InvocationInferenceHelper _inferenceHelper;

  /// The invocation being resolved.
  InvocationExpressionImpl? _invocation;

  MethodInvocationResolver(
    this._resolver, {
    required InvocationInferenceHelper inferenceHelper,
  }) : _inheritance = _resolver.inheritance,
       _definingLibrary = _resolver.definingLibrary,
       _definingLibraryUri = _resolver.definingLibrary.uri,
       _libraryFragment = _resolver.libraryFragment,
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

    var receiver = node.realTarget2;

    if (receiver == null) {
      var invocation = UnqualifiedFunctionInvocationImpl(
        name: nameNode.token,
        typeArguments: node.typeArguments,
        argumentList: node.argumentList,
      )..scopeLookupResult = nameNode.scopeLookupResult;
      _resolver.replaceExpression(node, invocation);
      _resolver.flowAnalysis.transferTestData(node, invocation);
      return resolveUnqualified(
        invocation,
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

  void resolveCascade(
    ParsedValueArgumentsImpl node,
    CascadeExpressionImpl cascade,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var receiver = cascade.target2;
    if (receiver is! ExtensionOverrideImpl &&
        cascade.isNullAware &&
        _typeSystem.isNull(_typeSystem.resolveToBound(receiver.typeOrThrow))) {
      _resolveReceiverWithoutTarget(
        _createNamedInvocation(node, receiver),
        whyNotPromotedArguments,
        contextType: contextType,
        type: NeverTypeImpl.instance,
        hasInvocation: false,
      );
      return;
    }
    _resolveInstanceInvocation(
      node,
      receiver,
      whyNotPromotedArguments,
      isNullAware: cascade.isNullAware,
      contextType: contextType,
    );
  }

  /// Resolves a call through an import namespace without constructing an
  /// expression receiver for the prefix.
  void resolveImportPrefixed(
    ImportPrefixedFunctionInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var prefix = node.importPrefix.element as PrefixElementImpl;
    var name = node.name;
    Element? candidate;
    if (name.lexeme == TopLevelFunctionElement.LOAD_LIBRARY_NAME) {
      var imports = prefix.imports;
      if (imports.length == 1 && imports.single.prefix?.isDeferred == true) {
        candidate = imports.single.importedLibrary?.loadLibraryFunction;
      }
    }
    if (candidate == null) {
      var lookup = prefix.scope.lookup(name.lexeme);
      reportDeprecatedExportUseGetter(
        scopeLookupResult: lookup,
        nameToken: name,
      );
      candidate = lookup.getter;
    }
    var element = candidate;
    if (element is MultiplyDefinedElement) {
      element = element.conflictingElements.first;
    }
    if (element is InternalPropertyAccessorElement) {
      var type = element.returnType;
      var receiver =
          ImportPrefixedNameExpressionImpl(
              importPrefix: node.importPrefix,
              name: name,
            )
            ..resolution = candidate is MultiplyDefinedElement
                ? InvalidNamedReadResolutionImpl(recoveryElement: candidate)
                : element is InternalGetterElement
                ? GetterInvocationResolutionImpl(element: element, type: type)
                : InvalidNamedReadResolutionImpl(recoveryElement: element);
      inferenceLogWriter?.enterFunctionExpressionInvocationTarget(receiver);
      receiver.recordStaticType(type, resolver: _resolver);
      if (type.isBottom) {
        _resolver.flowAnalysis.flow?.handleExit(offset: name.end);
      }
      inferenceLogWriter?.exitExpression(receiver);
      var invocation = CallInvocationImpl(
        receiver: receiver,
        typeArguments: node.typeArguments,
        argumentList: node.argumentList,
      );
      _resolver.replaceExpression(node, invocation);
      _resolver.flowAnalysis.transferTestData(node, invocation);
      _resolver.callInvocationResolver.resolve(
        invocation,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }
    if (element is! InternalExecutableElement &&
        !_libraryFragment.shouldIgnoreUndefined(
          prefix: prefix.name,
          name: name.lexeme,
        )) {
      diagnosticReporter.report(
        diag.undefinedFunction.withArguments(name: name.lexeme).at(name),
      );
    }
    _resolveNamedInvocation(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
      candidate: candidate,
      element: element is InternalExecutableElement ? element : null,
    );
  }

  /// Resolves the final named operation after its receiver has been analyzed.
  /// Qualifiers select a static namespace without evaluating a type literal.
  void resolveReceiver(
    ParsedValueArgumentsImpl node,
    NamedReceiverImpl receiver,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    switch (receiver) {
      case StaticQualifierImpl():
        _resolveQualifiedInvocation(
          node,
          receiver,
          whyNotPromotedArguments,
          contextType: contextType,
        );
      case SuperReferenceImpl():
        _resolveSuperInvocation(
          node,
          receiver,
          whyNotPromotedArguments,
          contextType: contextType,
        );
      case ExpressionImpl():
        var selector = node.namedInvocationParts!.selector;
        _resolveInstanceInvocation(
          node,
          receiver,
          whyNotPromotedArguments,
          isNullAware: selector.operator.type == TokenType.QUESTION_PERIOD,
          contextType: contextType,
        );
    }
  }

  /// Resolves a named call whose lexical scope has already been recorded.
  /// Callable values become reads followed by [CallInvocation]; executable
  /// members remain direct invocations, without an intervening tear-off.
  void resolveUnqualified(
    UnqualifiedFunctionInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var name = node.name;
    var lookup = node.scopeLookupResult!;
    reportDeprecatedExportUseGetter(scopeLookupResult: lookup, nameToken: name);
    var candidate = lookup.getter;
    Element? element = candidate;
    FunctionTypeImpl? callFunctionType;
    TypeImpl? recordFieldType;
    var isFunctionInterfaceCall = false;
    if (element is MultiplyDefinedElement) {
      element = element.conflictingElements.first;
    }
    if (element == null) {
      var receiverType = _resolver.thisType;
      if (receiverType == null) {
        if (!_libraryFragment.shouldIgnoreUndefined(
          prefix: null,
          name: name.lexeme,
        )) {
          diagnosticReporter.report(
            diag.undefinedFunction.withArguments(name: name.lexeme).at(name),
          );
        }
      } else {
        var setter = lookup.setter;
        // An instance setter can hide an inherited getter. A top-level,
        // extension, or static setter instead ends lexical lookup.
        var stopsLookup =
            setter != null &&
            (setter.enclosingElement is LibraryElement ||
                setter.enclosingElement is ExtensionElement ||
                setter is ExecutableElement && setter.isStatic);
        var needsError = true;
        if (stopsLookup) {
          candidate = setter;
        } else {
          var result = _resolver.typePropertyResolver.resolve(
            receiver: null,
            receiverType: receiverType,
            name: name.lexeme,
            hasRead: true,
            hasWrite: false,
            propertyErrorEntity: name,
            nameErrorEntity: name,
            parentNode: node,
          );
          candidate = element = result.getter2;
          callFunctionType = result.callFunctionType;
          recordFieldType = result.recordField?.type;
          isFunctionInterfaceCall =
              receiverType.isDartCoreFunction &&
              name.lexeme == MethodElement.CALL_METHOD_NAME;
          needsError = result.needsGetterError;
          if (element is InternalExecutableElement && element.isStatic) {
            _reportInstanceAccessToStaticMember(name, element, true);
          }
        }
        if (element == null &&
            callFunctionType == null &&
            recordFieldType == null &&
            !isFunctionInterfaceCall &&
            needsError &&
            !(receiverType is InterfaceTypeImpl &&
                receiverType.element.name == null) &&
            !name.isSynthetic) {
          diagnosticReporter.report(
            diag.undefinedMethod
                .withArguments(methodName: name.lexeme, type: receiverType)
                .at(name),
          );
        }
      }
    } else if (element is PrefixElement) {
      diagnosticReporter.report(
        diag.prefixIdentifierNotFollowedByDot
            .withArguments(name: name.lexeme)
            .at(name),
      );
    } else if (element is! InternalExecutableElement &&
        element is! InternalVariableElement) {
      diagnosticReporter.report(
        diag.invocationOfNonFunction.withArguments(name: name.lexeme).at(name),
      );
    }

    if (element is InternalVariableElement ||
        element is InternalPropertyAccessorElement ||
        recordFieldType != null) {
      var receiver = UnqualifiedNameExpressionImpl(name: name)
        ..scopeLookupResult = lookup;
      TypeImpl type;
      var flow = _resolver.flowAnalysis.flow;
      if (recordFieldType != null) {
        type = recordFieldType;
        receiver.resolution = RecordFieldReadResolutionImpl(type: type);
      } else if (element is InternalVariableElement) {
        _resolver.checkReadOfNotAssignedLocalVariable2(
          receiver,
          name: name.lexeme,
          element: element,
        );
        type = element.type;
        if (element is PromotableElementImpl && flow != null) {
          var (promotedType, expressionInfo) = flow.variableRead(
            element,
            offset: name.offset,
          );
          type = promotedType?.unwrapTypeView<TypeImpl>() ?? type;
          _resolver.flowAnalysis.storeExpressionInfo(receiver, expressionInfo);
        }
        receiver.resolution = VariableReadResolutionImpl(
          element: element,
          type: type,
        );
      } else {
        element as InternalPropertyAccessorElement;
        type = element.returnType;
        if (!element.isStatic && flow != null) {
          var (promotedType, expressionInfo) = flow.propertyGet(
            ThisPropertyTarget.singleton,
            name.lexeme,
            element,
            SharedTypeView(type),
          );
          type = promotedType?.unwrapTypeView<TypeImpl>() ?? type;
          _resolver.flowAnalysis.storeExpressionInfo(receiver, expressionInfo);
        }
        receiver.resolution = element is InternalGetterElement
            ? GetterInvocationResolutionImpl(element: element, type: type)
            : InvalidNamedReadResolutionImpl(recoveryElement: element);
      }
      if (candidate is MultiplyDefinedElement) {
        receiver.resolution = InvalidNamedReadResolutionImpl(
          recoveryElement: candidate,
        );
      }
      inferenceLogWriter?.enterFunctionExpressionInvocationTarget(receiver);
      receiver.recordStaticType(type, resolver: _resolver);
      if (type.isBottom) {
        flow?.handleExit(offset: name.end);
      }
      inferenceLogWriter?.exitExpression(receiver);
      var invocation = CallInvocationImpl(
        receiver: receiver,
        typeArguments: node.typeArguments,
        argumentList: node.argumentList,
      );
      _resolver.replaceExpression(node, invocation);
      _resolver.flowAnalysis.transferTestData(node, invocation);
      _resolver.callInvocationResolver.resolve(
        invocation,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    _resolveNamedInvocation(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
      candidate: candidate,
      element: element,
      callFunctionType: callFunctionType,
      isFunctionInterfaceCall: isFunctionInterfaceCall,
    );
  }

  NamedFunctionInvocationImpl _createNamedInvocation(
    ParsedValueArgumentsImpl node,
    NamedReceiverImpl receiver,
  ) {
    NamedFunctionInvocationImpl invocation;
    if (node.cascadeInvocationParts case var parts?) {
      invocation = CascadeMethodInvocationImpl(
        name: parts.head.name,
        typeArguments: parts.typeArguments,
        argumentList: node.argumentList,
      );
    } else {
      var (:selector, :typeArguments) = node.namedInvocationParts!;
      invocation = ReceiverMethodInvocationImpl(
        receiver: receiver,
        operator: selector.operator,
        name: selector.name,
        typeArguments: typeArguments,
        argumentList: node.argumentList,
      );
    }
    _resolver.replaceExpression(node, invocation);
    _resolver.flowAnalysis.transferTestData(node, invocation);
    return invocation;
  }

  bool _hasMatchingObjectMethod(
    MethodElement target,
    NodeListImpl<ArgumentImpl> arguments,
  ) {
    return arguments.length == target.formalParameters.length &&
        !arguments.any((e) => e is NamedArgument);
  }

  bool _isCoreFunction(DartType type) {
    // TODO(scheglov): Can we optimize this?
    return type is InterfaceType && type.isDartCoreFunction;
  }

  void _reportInstanceAccessToStaticMember(
    Token nameNode,
    ExecutableElement element,
    bool nullReceiver,
  ) {
    var enclosingElement = element.enclosingElement!;
    if (nullReceiver) {
      if (_resolver.enclosingInstanceElement is ExtensionElementImpl) {
        _resolver.diagnosticReporter.report(
          diag.unqualifiedReferenceToStaticMemberOfExtendedType
              .withArguments(name: enclosingElement.displayName)
              .at(nameNode),
        );
      } else {
        _resolver.diagnosticReporter.report(
          diag.unqualifiedReferenceToNonLocalStaticMember
              .withArguments(name: enclosingElement.displayName)
              .at(nameNode),
        );
      }
    } else if (enclosingElement is ExtensionElement &&
        enclosingElement.name == null) {
      _resolver.diagnosticReporter.report(
        diag.instanceAccessToStaticMemberOfUnnamedExtension
            .withArguments(
              name: nameNode.lexeme,
              kind: element.kind.displayName,
            )
            .at(nameNode),
      );
    } else {
      // It is safe to assume that `enclosingElement.name` is non-`null` because
      // it can only be `null` for extensions, and we handle that case above.
      _resolver.diagnosticReporter.report(
        diag.instanceAccessToStaticMember
            .withArguments(
              memberName: nameNode.lexeme,
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
        diag.undefinedMethodOnTypeLiteral
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

  void _resolveCallableProperty(
    ParsedValueArgumentsImpl node,
    NamedReceiverImpl receiver,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required InternalExecutableElement? element,
    required TypeImpl type,
  }) {
    if (node.cascadeInvocationParts case var parts?) {
      var read = CascadePropertyExtractionImpl(name: parts.head.name);
      var result = _resolver.resolveCascadeProperty(
        read,
        parts.head.name,
        hasRead: true,
        hasWrite: false,
      );
      read.resolution = result?.read;
      inferenceLogWriter?.enterFunctionExpressionInvocationTarget(read);
      read.recordStaticType(
        result?.read?.type ?? NeverTypeImpl.instance,
        resolver: _resolver,
      );
      if (read.typeOrThrow.isBottom) {
        _resolver.flowAnalysis.flow?.handleExit(offset: parts.head.name.end);
      }
      inferenceLogWriter?.exitExpression(read);
      if (result?.readExpressionInfo case var expressionInfo?) {
        _resolver.flowAnalysis.storeExpressionInfo(read, expressionInfo);
      }
      var invocation = CallInvocationImpl(
        receiver: read,
        typeArguments: parts.typeArguments,
        argumentList: node.argumentList,
      );
      _resolver.replaceExpression(node, invocation);
      _resolver.flowAnalysis.transferTestData(node, invocation);
      _resolver.callInvocationResolver.resolve(
        invocation,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }
    var (:selector, :typeArguments) = node.namedInvocationParts!;
    var read = ReceiverPropertyExtractionImpl(
      receiver: receiver,
      operator: selector.operator,
      name: selector.name,
    );
    if ((receiver, _resolver.flowAnalysis.flow) case (
      InstanceReceiverImpl receiver,
      var flow?,
    )) {
      var (promotedType, expressionInfo) = flow.propertyGet(
        receiver is SuperReferenceImpl
            ? SuperPropertyTarget.singleton
            : ExpressionPropertyTarget(
                _resolver.flowAnalysis.getExpressionInfo(
                  receiver as ExpressionImpl,
                ),
              ),
        selector.name.lexeme,
        element,
        SharedTypeView(type),
      );
      type = promotedType?.unwrapTypeView<TypeImpl>() ?? type;
      _resolver.flowAnalysis.storeExpressionInfo(read, expressionInfo);
    }
    read.resolution = switch (element) {
      InternalGetterElement() => GetterInvocationResolutionImpl(
        element: element,
        type: type,
      ),
      null => RecordFieldReadResolutionImpl(type: type),
      _ => InvalidNamedReadResolutionImpl(recoveryElement: element),
    };
    inferenceLogWriter?.enterFunctionExpressionInvocationTarget(read);
    read.recordStaticType(type, resolver: _resolver);
    if (type.isBottom) {
      _resolver.flowAnalysis.flow?.handleExit(offset: selector.name.end);
    }
    inferenceLogWriter?.exitExpression(read);
    var invocation = CallInvocationImpl(
      receiver: read,
      typeArguments: typeArguments,
      argumentList: node.argumentList,
    );
    _resolver.replaceExpression(node, invocation);
    _resolver.flowAnalysis.transferTestData(node, invocation);
    _resolver.callInvocationResolver.resolve(
      invocation,
      whyNotPromotedArguments,
      contextType: contextType,
    );
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
    InternalExecutableElement? element = extension.getGetter(name);
    element ??= extension.getMethod(name);
    if (element != null) {
      nameNode.element = element;
      if (!element.isStatic) {
        _reportStaticAccessToInstanceMember(element, nameNode);
        _setInvalidTypeResolutionForInstanceMember(
          node,
          element,
          whyNotPromotedArguments,
          contextType: contextType,
        );
      } else if (element is InternalPropertyAccessorElement) {
        _rewriteAsCallInvocation(
          node,
          node.target2,
          node.operator,
          node.methodName,
          node.typeArguments,
          node.argumentList,
          element.returnType,
          whyNotPromotedArguments: whyNotPromotedArguments,
          contextType: contextType,
        );
      } else {
        _setResolution(
          node,
          element.type,
          whyNotPromotedArguments,
          contextType: contextType,
          target: InvocationTargetExecutableElement(element),
        );
      }
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

    nameNode.element = member;

    if (member is InternalPropertyAccessorElement) {
      _rewriteAsCallInvocation(
        node,
        node.target2,
        node.operator,
        node.methodName,
        node.typeArguments,
        node.argumentList,
        member.returnType,
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

  /// Looks up the member before inferring arguments, so callable properties
  /// use call inference and methods use their executable signatures.
  void _resolveInstanceInvocation(
    ParsedValueArgumentsImpl node,
    ExpressionImpl receiver,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required bool isNullAware,
    required TypeImpl contextType,
  }) {
    var name =
        node.cascadeInvocationParts?.head.name ??
        node.namedInvocationParts!.selector.name;
    if (receiver is ExtensionOverrideImpl) {
      var member = _extensionResolver
          .getOverrideMember(receiver, name.lexeme)
          .getter2;
      if (member == null) {
        diagnosticReporter.report(
          diag.undefinedExtensionMethod
              .withArguments(
                methodName: name.lexeme,
                extensionName: receiver.element.name!,
              )
              .at(name),
        );
      } else if (member.isStatic) {
        diagnosticReporter.report(
          diag.extensionOverrideAccessToStaticMember.at(name),
        );
      }
      if (member != null && node.cascadeInvocationParts != null) {
        diagnosticReporter.report(
          diag.extensionOverrideWithCascade.at(receiver.name),
        );
      }
      if (member is InternalPropertyAccessorElement) {
        _resolveCallableProperty(
          node,
          receiver,
          whyNotPromotedArguments,
          contextType: contextType,
          element: member,
          type: member.returnType,
        );
      } else {
        _resolveNamedInvocation(
          _createNamedInvocation(node, receiver),
          whyNotPromotedArguments,
          contextType: contextType,
          candidate: member,
          element: member,
        );
      }
      return;
    }
    var receiverType = receiver.typeOrThrow;
    if (_typeSystem.isDynamicBounded(receiverType)) {
      var method = _resolver.typeProvider.objectElement.getMethod(name.lexeme);
      if (receiverType is! InvalidType &&
          method != null &&
          !method.isStatic &&
          _hasMatchingObjectMethod(method, node.argumentList.arguments2)) {
        _resolveNamedInvocation(
          _createNamedInvocation(node, receiver),
          whyNotPromotedArguments,
          contextType: contextType,
          candidate: method,
          element: method,
        );
      } else {
        _resolveReceiverWithoutTarget(
          _createNamedInvocation(node, receiver),
          whyNotPromotedArguments,
          contextType: contextType,
          type: receiverType is InvalidType
              ? InvalidTypeImpl.instance
              : DynamicTypeImpl.instance,
        );
      }
      return;
    }
    if (receiverType is NeverTypeImpl) {
      var method = _resolver.typeProvider.objectElement.getMethod(name.lexeme);
      if (receiverType.nullabilitySuffix == NullabilitySuffix.question &&
          method != null) {
        _resolveNamedInvocation(
          _createNamedInvocation(node, receiver),
          whyNotPromotedArguments,
          contextType: contextType,
          candidate: method,
          element: method,
        );
        return;
      }
      if (receiverType.nullabilitySuffix == NullabilitySuffix.none ||
          isNullAware) {
        if (receiverType.nullabilitySuffix == NullabilitySuffix.none) {
          diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
        }
        _resolveReceiverWithoutTarget(
          _createNamedInvocation(node, receiver),
          whyNotPromotedArguments,
          contextType: contextType,
          type: receiverType,
          hasInvocation: false,
        );
        return;
      }
    }
    if (receiverType is VoidType) {
      _reportUseOfVoidType(receiver);
      _resolveReceiverWithoutTarget(
        _createNamedInvocation(node, receiver),
        whyNotPromotedArguments,
        contextType: contextType,
        type: InvalidTypeImpl.instance,
      );
      return;
    }
    if (isNullAware) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }
    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: name.lexeme,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: name,
      nameErrorEntity: name,
      parentNode: node,
    );
    var element = result.getter2;
    if (element != null && element.isStatic) {
      _reportInstanceAccessToStaticMember(name, element, false);
    }
    if (element is InternalPropertyAccessorElement ||
        result.recordField != null) {
      _resolveCallableProperty(
        node,
        receiver,
        whyNotPromotedArguments,
        contextType: contextType,
        element: element,
        type:
            result.recordField?.type ??
            (element as InternalPropertyAccessorElement).returnType,
      );
      return;
    }
    var isFunctionInterfaceCall =
        receiverType.isDartCoreFunction &&
        name.lexeme == MethodElement.CALL_METHOD_NAME;
    if (element == null &&
        result.callFunctionType == null &&
        !isFunctionInterfaceCall &&
        result.needsGetterError &&
        !(receiverType is InterfaceTypeImpl &&
            receiverType.element.name == null) &&
        !name.isSynthetic) {
      diagnosticReporter.report(
        diag.undefinedMethod
            .withArguments(methodName: name.lexeme, type: receiverType)
            .at(name),
      );
    }
    var invocation = _createNamedInvocation(node, receiver);
    _resolveNamedInvocation(
      invocation,
      whyNotPromotedArguments,
      contextType: contextType,
      candidate: element,
      element: element,
      callFunctionType: result.callFunctionType,
      isFunctionInterfaceCall: isFunctionInterfaceCall,
    );
    if (isFunctionInterfaceCall) {
      invocation.resolution = FunctionInterfaceInvocationResolutionImpl(
        type: invocation.typeOrThrow,
      );
    }
  }

  void _resolveNamedInvocation(
    NamedFunctionInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required Element? candidate,
    required Element? element,
    FunctionTypeImpl? callFunctionType,
    bool isFunctionInterfaceCall = false,
  }) {
    InvocationTarget? target;
    if (element is InternalExecutableElement) {
      target = InvocationTargetExecutableElement(element);
      node.resolution = ExecutableInvocationResolutionImpl(
        element: element,
        invokeType: element.type,
        type: element.returnType,
      );
      if (candidate is MultiplyDefinedElement) {
        node.resolution = InvalidInvocationResolutionImpl(
          candidates: [candidate],
          recovery: FunctionCallInvocationResolutionImpl(
            invokeType: element.type,
            type: element.returnType,
          ),
          type: element.returnType,
        );
      }
    } else if (callFunctionType != null) {
      target = InvocationTargetFunctionTypedExpression(callFunctionType);
    }
    var type =
        NamedFunctionInvocationInferrer(
              resolver: _resolver,
              node: node,
              argumentList: node.argumentList,
              whyNotPromotedArguments: whyNotPromotedArguments,
              contextType: contextType,
              target: target,
            ).resolveInvocation()
            as TypeImpl;
    var invokeType = node.staticInvokeType;
    ValidInvocationResolutionImpl? resolution;
    if (invokeType is FunctionTypeImpl) {
      resolution = candidate is InternalExecutableElement
          ? ExecutableInvocationResolutionImpl(
              element: candidate,
              invokeType: invokeType,
              type: type,
            )
          : FunctionCallInvocationResolutionImpl(
              invokeType: invokeType,
              type: type,
            );
    }
    if (target == null && !isFunctionInterfaceCall) {
      type = InvalidTypeImpl.instance;
      node.staticInvokeType = type;
    }
    node.resolution =
        candidate is MultiplyDefinedElement || type is InvalidTypeImpl
        ? InvalidInvocationResolutionImpl(
            candidates: [?candidate],
            recovery: resolution,
            type: type,
          )
        : resolution ?? DynamicInvocationResolutionImpl(type: type);
    node.recordStaticType(type, resolver: _resolver);
  }

  void _resolveQualifiedInvocation(
    ParsedValueArgumentsImpl node,
    StaticQualifierImpl receiver,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    if (receiver.scopeLookupResult case var lookup?) {
      reportDeprecatedExportUseGetter(
        scopeLookupResult: lookup,
        nameToken: receiver.name,
      );
    }
    var name = node.namedInvocationParts!.selector.name;
    var namespace = receiver.element;
    var interface = switch (namespace) {
      InterfaceElement element => element,
      TypeAliasElement(aliasedType: InterfaceType(:var element)) => element,
      _ => null,
    };
    InternalExecutableElement? element;
    if (interface != null) {
      element =
          (interface.getGetter(name.lexeme) ?? interface.getMethod(name.lexeme))
              as InternalExecutableElement?;
    } else if (namespace is ExtensionElementImpl) {
      element =
          namespace.getGetter(name.lexeme) ?? namespace.getMethod(name.lexeme);
    }
    if (element != null && !element.isAccessibleIn(_definingLibrary)) {
      element = null;
    }
    if (element != null && !element.isStatic) {
      // Preserve argument checking against the recovery declaration without
      // exposing its enclosing type parameters as a valid invocation result.
      diagnosticReporter.report(
        diag.staticAccessToInstanceMember
            .withArguments(name: name.lexeme)
            .at(name),
      );
      var invocation = _createNamedInvocation(node, receiver);
      _resolveNamedInvocation(
        invocation,
        whyNotPromotedArguments,
        contextType: contextType,
        candidate: element,
        element: element,
      );
      var recovery = invocation.resolution;
      invocation.resolution = InvalidInvocationResolutionImpl(
        candidates: [element],
        recovery: recovery is ValidInvocationResolutionImpl ? recovery : null,
        type: InvalidTypeImpl.instance,
      );
      invocation.staticInvokeType = InvalidTypeImpl.instance;
      invocation.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
      return;
    }
    if (element is InternalPropertyAccessorElement) {
      _resolveCallableProperty(
        node,
        receiver,
        whyNotPromotedArguments,
        contextType: contextType,
        element: element,
        type: element.returnType,
      );
      return;
    }
    if (element == null) {
      if (namespace is ExtensionElement) {
        diagnosticReporter.report(
          diag.undefinedExtensionMethod
              .withArguments(
                methodName: name.lexeme,
                extensionName: namespace.name!,
              )
              .at(name),
        );
      } else if (interface != null) {
        diagnosticReporter.report(
          diag.undefinedMethodOnTypeLiteral
              .withArguments(
                methodName: name.lexeme,
                typeName: interface.displayName,
              )
              .at(name),
        );
      } else {
        // Function-type aliases are converted to expression receivers before
        // qualified invocation resolution.
        throw StateError('Unexpected static invocation qualifier: $namespace');
      }
    }
    _resolveNamedInvocation(
      _createNamedInvocation(node, receiver),
      whyNotPromotedArguments,
      contextType: contextType,
      candidate: element,
      element: element,
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
        _hasMatchingObjectMethod(targetElement, node.argumentList.arguments2)) {
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

    void resolveUnreachableInvocation({
      required TypeImpl resultType,
      bool reportReceiverOfTypeNever = false,
    }) {
      MethodInvocationInferrer(
        resolver: _resolver,
        node: node,
        argumentList: node.argumentList,
        contextType: contextType,
        whyNotPromotedArguments: whyNotPromotedArguments,
        target: null,
      ).resolveInvocation();

      if (reportReceiverOfTypeNever) {
        _resolver.diagnosticReporter.report(
          diag.receiverOfTypeNever.at(receiver),
        );
      }

      node.methodName.setPseudoExpressionStaticType(_dynamicType);
      node.staticInvokeType = _dynamicType;
      node.recordStaticType(resultType, resolver: _resolver);
    }

    if (receiverType is NeverTypeImpl &&
        receiverType.nullabilitySuffix == NullabilitySuffix.question) {
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
      } else if (node.isNullAware) {
        resolveUnreachableInvocation(
          resultType: NeverTypeImpl.instanceNullable,
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

    if (receiverType is NeverTypeImpl &&
        receiverType.nullabilitySuffix == NullabilitySuffix.none) {
      resolveUnreachableInvocation(
        resultType: NeverTypeImpl.instance,
        reportReceiverOfTypeNever: true,
      );
    }
  }

  /// Resolves the method invocation, [node], as an instance invocation on an
  /// expression of type `Null`.
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
      _rewriteAsCallInvocation(
        node,
        node.target2,
        node.operator,
        node.methodName,
        node.typeArguments,
        node.argumentList,
        element.returnType,
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
      _rewriteAsCallInvocation(
        node,
        node.target2,
        node.operator,
        node.methodName,
        node.typeArguments,
        node.argumentList,
        recordField.type,
        whyNotPromotedArguments: whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    var target = result.getter2;
    if (target != null) {
      nameNode.element = target;

      if (target.isStatic) {
        _reportInstanceAccessToStaticMember(
          nameNode.token,
          target,
          receiver == null,
        );
      }

      if (target is PropertyAccessorElement) {
        _rewriteAsCallInvocation(
          node,
          node.target2,
          node.operator,
          node.methodName,
          node.typeArguments,
          node.argumentList,
          target.returnType,
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

    if (receiverType is InterfaceTypeImpl &&
        receiverType.element.name == null) {
      return;
    }

    if (!nameNode.isSynthetic) {
      _resolver.diagnosticReporter.report(
        diag.undefinedMethod
            .withArguments(methodName: name, type: receiverType)
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
    var element = _resolveElement(receiver, nameNode);
    if (element != null) {
      if (element is InternalExecutableElement) {
        nameNode.element = element;
        if (!element.isStatic) {
          _setInvalidTypeResolutionForInstanceMember(
            node,
            element,
            whyNotPromotedArguments,
            contextType: contextType,
          );
        } else if (element is InternalPropertyAccessorElement) {
          _rewriteAsCallInvocation(
            node,
            node.target2,
            node.operator,
            node.methodName,
            node.typeArguments,
            node.argumentList,
            element.returnType,
            whyNotPromotedArguments: whyNotPromotedArguments,
            contextType: contextType,
          );
        } else {
          _setResolution(
            node,
            element.type,
            whyNotPromotedArguments,
            contextType: contextType,
            target: InvocationTargetExecutableElement(element),
          );
        }
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

  void _resolveReceiverWithoutTarget(
    NamedFunctionInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required TypeImpl type,
    bool hasInvocation = true,
  }) {
    NamedFunctionInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
      target: null,
    ).resolveInvocation();
    node.staticInvokeType = type is InvalidType
        ? InvalidTypeImpl.instance
        : DynamicTypeImpl.instance;
    node.resolution = !hasInvocation
        ? null
        : type is InvalidType
        ? InvalidInvocationResolutionImpl(
            candidates: [],
            recovery: null,
            type: type,
          )
        : DynamicInvocationResolutionImpl(type: type);
    node.recordStaticType(type, resolver: _resolver);
  }

  void _resolveSuperInvocation(
    ParsedValueArgumentsImpl node,
    SuperReferenceImpl receiver,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var enclosingInterface = _resolver.enclosingInstanceElement;
    if (enclosingInterface is! InterfaceElementImpl ||
        SuperContext.of(receiver) != SuperContext.valid) {
      _resolveReceiverWithoutTarget(
        _createNamedInvocation(node, receiver),
        whyNotPromotedArguments,
        contextType: contextType,
        type: InvalidTypeImpl.instance,
      );
      return;
    }

    var name = node.namedInvocationParts!.selector.name;
    var memberName = Name(_definingLibraryUri, name.lexeme);
    var member = _inheritance.getMember(
      enclosingInterface,
      memberName,
      forSuper: true,
    );
    if (member is InternalPropertyAccessorElement) {
      _resolveCallableProperty(
        node,
        receiver,
        whyNotPromotedArguments,
        contextType: contextType,
        element: member,
        type: member.returnType,
      );
      return;
    }
    if (member == null) {
      // Keep the inherited interface member for argument checking when there
      // is no concrete superclass dispatch target.
      member = _inheritance.getInherited(enclosingInterface, memberName);
      if (member != null) {
        diagnosticReporter.report(
          diag.abstractSuperMemberReference
              .withArguments(
                memberKind: member.kind.displayName,
                name: name.lexeme,
              )
              .at(name),
        );
      } else {
        diagnosticReporter.report(
          diag.undefinedSuperMethod
              .withArguments(
                methodName: name.lexeme,
                typeName: enclosingInterface.firstFragment.displayName,
              )
              .at(name),
        );
      }
    }
    _resolveNamedInvocation(
      _createNamedInvocation(node, receiver),
      whyNotPromotedArguments,
      contextType: contextType,
      candidate: member,
      element: member,
    );
  }

  /// Rewrites [node] as a [CallInvocation].
  ///
  /// We have identified that [node] is not a real [MethodInvocation],
  /// because it does not invoke a method, but instead invokes the result
  /// of a getter execution, or implicitly invokes the `call` method of
  /// an [InterfaceType]. So, it should be represented as instead as a
  /// [CallInvocation].
  CallInvocationImpl _rewriteAsCallInvocation(
    ExpressionImpl node,
    ExpressionImpl? target,
    Token? operator,
    SimpleIdentifierImpl methodName,
    TypeArgumentListImpl? typeArguments,
    ArgumentListImpl argumentList,
    TypeImpl getterReturnType, {
    required List<WhyNotPromotedGetter> whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    var targetType = getterReturnType;

    ExpressionImpl functionExpression;
    if (target == null) {
      functionExpression = methodName;

      var element = methodName.element;
      if (element is ExecutableElement &&
          element.enclosingElement is InstanceElement &&
          !element.isStatic) {
        if (_resolver.flowAnalysis.flow case var flow?) {
          var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
            ThisPropertyTarget.singleton,
            methodName.name,
            element,
            SharedTypeView(getterReturnType),
          );
          _resolver.flowAnalysis.storeExpressionInfo(
            functionExpression,
            expressionInfo,
          );
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
          target2: target,
          operator: operator!,
          propertyName: methodName,
        );
      }
      if (_resolver.flowAnalysis.flow case var flow?) {
        var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
          ExpressionPropertyTarget(
            _resolver.flowAnalysis.getExpressionInfo(target),
          ),
          methodName.name,
          methodName.element,
          SharedTypeView(getterReturnType),
        );
        _resolver.flowAnalysis.storeExpressionInfo(
          functionExpression,
          expressionInfo,
        );
        targetType = wrappedPromotedType?.unwrapTypeView() ?? targetType;
      }
    }
    inferenceLogWriter?.enterFunctionExpressionInvocationTarget(methodName);
    methodName.recordStaticType(targetType, resolver: _resolver);
    if (targetType.isBottom) {
      _resolver.flowAnalysis.flow?.handleExit(offset: methodName.end);
    }
    inferenceLogWriter?.exitExpression(methodName);

    if (functionExpression != methodName) {
      functionExpression.setPseudoExpressionStaticType(targetType);
    }
    var invocation = CallInvocationImpl(
      receiver: functionExpression,
      typeArguments: typeArguments,
      argumentList: argumentList,
    );
    _resolver.replaceExpression(node, invocation);
    _resolver.flowAnalysis.transferTestData(node, invocation);
    _resolver.callInvocationResolver.resolve(
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

  void _setInvalidTypeResolutionForInstanceMember(
    MethodInvocationImpl node,
    InternalExecutableElement element,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    // Resolve the arguments against the recovered member so that independent
    // argument diagnostics are preserved. Do not expose the member's type: it
    // can contain enclosing type parameters that are invalid at this access.
    var recoveryType = element is InternalPropertyAccessorElement
        ? element.returnType
        : element.type;
    _setResolution(
      node,
      recoveryType,
      whyNotPromotedArguments,
      contextType: contextType,
      target: InvocationTargetExecutableElement(element),
    );
    node.methodName.setPseudoExpressionStaticType(InvalidTypeImpl.instance);
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
      target: node.target2,
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
}
