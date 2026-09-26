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

  MethodInvocationResolver(this._resolver)
    : _inheritance = _resolver.inheritance,
      _definingLibrary = _resolver.definingLibrary,
      _definingLibraryUri = _resolver.definingLibrary.uri,
      _libraryFragment = _resolver.libraryFragment,
      _extensionResolver = _resolver.extensionResolver;

  @override
  DiagnosticReporter get diagnosticReporter => _resolver.diagnosticReporter;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolveCascade(
    ParsedValueArgumentsImpl node,
    CascadeExpressionImpl cascade,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var receiver = _resolver.cascadeReceiver(cascade);
    if (receiver is ExpressionImpl &&
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
      case ExpressionImpl() && InstanceReceiverImpl receiver:
      case ExtensionOverride2Impl() && InstanceReceiverImpl receiver:
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
          var (:promotedType, :expressionInfo) = flow.variableRead(
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
          var (:promotedType, :expressionInfo) = flow.propertyGet(
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

  void _reportUseOfVoidType(AstNode errorNode) {
    _resolver.diagnosticReporter.report(diag.useOfVoidResult.at(errorNode));
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
      var (:promotedType, :expressionInfo) = flow.propertyGet(
        receiver is SuperReferenceImpl
            ? SuperPropertyTarget.singleton
            : ExpressionPropertyTarget(
                _resolver.flowAnalysis.getExpressionInfo(
                  receiver is ExpressionImpl ? receiver : null,
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

  /// Looks up the member before inferring arguments, so callable properties
  /// use call inference and methods use their executable signatures.
  void _resolveInstanceInvocation(
    ParsedValueArgumentsImpl node,
    InstanceReceiverImpl receiver,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required bool isNullAware,
    required TypeImpl contextType,
  }) {
    var name =
        node.cascadeInvocationParts?.head.name ??
        node.namedInvocationParts!.selector.name;
    if (receiver is ExtensionOverride2Impl) {
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
    var receiverType = _resolver.instanceReceiverType(receiver);
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
}
