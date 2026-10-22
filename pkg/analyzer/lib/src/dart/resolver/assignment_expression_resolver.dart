// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';

/// Helper for resolving V2 assignment expressions and their targets.
class AssignmentExpressionResolver {
  final TypeAnalyzer _typeAnalyzer;
  final PropertyElementResolver _propertyElementResolver;
  final TypePropertyResolver _typePropertyResolver;

  new({required TypeAnalyzer typeAnalyzer})
    : _typeAnalyzer = typeAnalyzer,
      _propertyElementResolver = typeAnalyzer.propertyElementResolver,
      _typePropertyResolver = typeAnalyzer.typePropertyResolver;

  DiagnosticReporter get _diagnosticReporter =>
      _typeAnalyzer.diagnosticReporter;

  TypeSystemImpl get _typeSystem => _typeAnalyzer.typeSystem;

  void analyzePropertyTargetReceiver(
    AstNode node,
    ReceiverPropertyAssignmentTargetImpl target,
  ) {
    var receiver = target.receiver;
    switch (receiver) {
      case StaticQualifierImpl():
        return;
      case SuperReferenceImpl():
        _typeAnalyzer.visitSuperReference(receiver);
        if (target.operator.type == TokenType.QUESTION_PERIOD) {
          _typeAnalyzer.startNullAwareAssignmentTarget(
            receiver,
            offset: target.operator.offset,
          );
        }
        return;
      case ExtensionOverride2Impl():
        _typeAnalyzer.visitExtensionOverride2(receiver);
        receiver.legacyStaticType =
            receiver.extendedType ?? InvalidTypeImpl.instance;
        if (target.operator.type == TokenType.QUESTION_PERIOD) {
          _typeAnalyzer.startNullAwareAssignmentTarget(
            receiver,
            offset: target.operator.offset,
          );
        }
        return;
      case ExpressionImpl():
        _typeAnalyzer.analyzeExpression(
          receiver,
          SharedTypeSchemaView(UnknownInferredType.instance),
          continueNullShorting: true,
        );
        receiver = _typeAnalyzer.popRewrite()!;
        target.receiver = receiver;
        var receiverDoesNotComplete = identical(
          _typeSystem.resolveToBound(receiver.typeOrThrow),
          NeverTypeImpl.instance,
        );
        if (target.operator.type == TokenType.QUESTION_PERIOD &&
            !receiverDoesNotComplete) {
          _typeAnalyzer.startNullAwareAssignmentTarget(
            receiver,
            offset: target.operator.offset,
          );
          _typeAnalyzer.nullSafetyDeadCodeVerifier.recordDeadIntervalAt(
            node,
            target.name,
          );
          _typeAnalyzer.nullSafetyDeadCodeVerifier.verifyNullAwareAccess(
            node,
            receiver,
            target.operator,
          );
        }
    }
  }

  void resolveCompound(
    CompoundAssignmentImpl node, {
    required TypeImpl contextType,
  }) {
    TypeImpl readType;
    TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    switch (resolveReadWriteTarget(node, node.target)) {
      case ResolvedReadWriteTarget result:
        readType = result.readType;
        writeAcceptedType = result.writeAcceptedType;
        variableElement = result.variableElement;
      case UnresolvedReadWriteTarget():
        _analyzeValue(node, UnknownInferredType.instance);
        node.operatorResultType = NeverTypeImpl.instance;
        node.recordStaticType(
          NeverTypeImpl.instance,
          typeAnalyzer: _typeAnalyzer,
        );
        return;
      case InvalidReadWriteTarget(:var expression?):
        _resolveInvalidCompound(node, expression);
        return;
      case InvalidReadWriteTarget():
        _analyzeValue(node, InvalidTypeImpl.instance);
        node.operatorResultType = InvalidTypeImpl.instance;
        node.recordStaticType(
          InvalidTypeImpl.instance,
          typeAnalyzer: _typeAnalyzer,
        );
        return;
    }

    _resolveCompoundOperator(node, receiver: null, readType: readType);

    // Analyze `target op= value` as an operator invocation whose receiver has
    // the target's read type and whose surrounding context is the target's
    // write type. Flow analysis may provide a promoted write type for a
    // variable; other targets use the type accepted by their write resolution.
    var writeContextType = writeAcceptedType;
    if (variableElement case var element?) {
      writeContextType = _typeAnalyzer.localVariableTypeProvider.getWriteType(
        element,
      );
    }
    var rhsContext = _computeCompoundRhsContext(
      operatorTargetType: readType,
      writeContextType: writeContextType,
      element: node.element,
    );
    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(rhsContext),
    );
    node.value = _typeAnalyzer.popRewrite()!;
    var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(node.value),
    );

    var operatorResultType = _computeCompoundOperatorResultType(
      node,
      readType: readType,
    );
    node.operatorResultType = operatorResultType;
    node.recordStaticType(operatorResultType, typeAnalyzer: _typeAnalyzer);

    _checkForInvalidAssignment(
      node.target,
      writeAcceptedType,
      node.value,
      operatorResultType,
      whyNotPromoted: null,
    );
    _typeAnalyzer.checkForArgumentTypeNotAssignableForArgument(
      node.value,
      whyNotPromoted: whyNotPromoted,
    );
    _typeAnalyzer.checkWriteOfAssignedFinalLocalVariable(node.target);

    var flow = _typeAnalyzer.flowAnalysis.flow;
    if (flow == null) return;
    if (variableElement case PromotableElementImpl element) {
      _typeAnalyzer.flowAnalysis.storeExpressionInfo(
        node,
        flow.write(
          node,
          element,
          SharedTypeView(operatorResultType),
          null,
          offset: node.end,
        ),
      );
    }
  }

  void resolveDirect(
    DirectAssignmentImpl node, {
    required TypeImpl contextType,
  }) {
    var target = node.target;
    late TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    switch (target) {
      case CascadeIndexAssignmentTargetImpl():
        var result = _typeAnalyzer.resolveCascadeIndex(
          target,
          hasRead: false,
          hasWrite: true,
        );
        var resolution = result?.write;
        target.write = resolution;
        _typeAnalyzer.analyzeExpression(
          target.index,
          SharedTypeSchemaView(
            resolution?.indexContextType ?? UnknownInferredType.instance,
          ),
        );
        target.index = _typeAnalyzer.popRewrite()!;
        var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
          _typeAnalyzer.flowAnalysis.getExpressionInfo(target.index),
        );
        var writeElement = resolution?.elementOrRecovery;
        _typeAnalyzer.checkIndexExpressionIndex(
          target.index,
          readElement: null,
          writeElement: writeElement,
          whyNotPromoted: whyNotPromoted,
        );
        if (resolution == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case CascadePropertyAssignmentTargetImpl():
        var result = _typeAnalyzer.resolveCascadeProperty(
          node,
          target.name,
          hasRead: false,
          hasWrite: true,
        );
        var resolution = result?.write;
        target.write = resolution;
        if (resolution == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case ReceiverIndexAssignmentTargetImpl():
        target.receiver = _typeAnalyzer.analyzeInstanceReceiver(
          target.receiver,
          continueNullShorting: true,
        );
        var receiverDoesNotComplete =
            target.receiver is! ExtensionOverride2Impl &&
            identical(
              _typeSystem.resolveToBound(
                _typeAnalyzer.instanceReceiverType(target.receiver),
              ),
              NeverTypeImpl.instance,
            );
        if (target.question case var question? when !receiverDoesNotComplete) {
          _typeAnalyzer.startNullAwareAssignmentTarget(
            target.receiver,
            offset: question.offset,
          );
          _typeAnalyzer.nullSafetyDeadCodeVerifier.visitNode(target.index);
        }
        var resolution = _propertyElementResolver
            .resolveIndexDirectAssignmentTarget(target);
        target.write = resolution;

        _typeAnalyzer.analyzeExpression(
          target.index,
          SharedTypeSchemaView(
            resolution?.indexContextType ?? UnknownInferredType.instance,
          ),
        );
        target.index = _typeAnalyzer.popRewrite()!;
        var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
          _typeAnalyzer.flowAnalysis.getExpressionInfo(target.index),
        );
        var writeElement = resolution?.elementOrRecovery;
        _typeAnalyzer.checkIndexExpressionIndex(
          target.index,
          readElement: null,
          writeElement: writeElement,
          whyNotPromoted: whyNotPromoted,
        );

        if (resolution == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case ReceiverPropertyAssignmentTargetImpl():
        analyzePropertyTargetReceiver(node, target);
        var resolution = _propertyElementResolver
            .resolveReceiverPropertyDirectAssignmentTarget(target);
        target.write = resolution;
        if (resolution == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case ImportPrefixedAssignmentTargetImpl():
        _propertyElementResolver.resolveImportPrefixedAssignmentTarget(target);
        writeAcceptedType = target.write!.acceptedType;
      case UnqualifiedNameAssignmentTargetImpl():
        var resolution = _propertyElementResolver
            .resolveUnqualifiedNameAssignmentTarget(target);
        target.write = resolution;
        writeAcceptedType = resolution.acceptedType;
        if (resolution case VariableWriteResolutionImpl(:var element)) {
          variableElement = element;
        }
      case ParsedAssignmentTargetImpl():
        throw StateError('Parsed assignment target was not lowered');
      case InvalidExtensionOverrideAssignmentTargetImpl():
        _resolveInvalidExtensionOverride(node, target);
        return;
      case InvalidSuperAssignmentTargetImpl():
        _resolveInvalidSuper(node, target);
        return;
      case InvalidExpressionAssignmentTargetImpl():
        _resolveInvalidDirect(node, target);
        return;
    }

    var rhsContext = writeAcceptedType;
    if (variableElement case var element?) {
      rhsContext = _typeAnalyzer.localVariableTypeProvider.getWriteType(
        element,
      );
    }

    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(rhsContext),
    );
    node.value = _typeAnalyzer.popRewrite()!;
    var valueType = node.value.typeOrThrow;
    var flow = _typeAnalyzer.flowAnalysis.flow;
    var whyNotPromoted = flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(node.value),
    );

    node.recordStaticType(valueType, typeAnalyzer: _typeAnalyzer);
    _checkForInvalidAssignment(
      target,
      writeAcceptedType,
      node.value,
      valueType,
      whyNotPromoted: whyNotPromoted,
    );
    _typeAnalyzer.checkWriteOfAssignedFinalLocalVariable(target);

    if (flow == null) return;
    if (variableElement case PromotableElementImpl element) {
      _typeAnalyzer.flowAnalysis.storeExpressionInfo(
        node,
        flow.write(
          node,
          element,
          SharedTypeView(node.typeOrThrow),
          _typeAnalyzer.flowAnalysis.getExpressionInfo(node.value),
          offset: node.end,
        ),
      );
    }
  }

  void resolveIfNull(
    IfNullAssignmentImpl node, {
    required TypeImpl contextType,
  }) {
    TypeImpl readType;
    TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    ExpressionInfo? readExpressionInfo;
    switch (resolveReadWriteTarget(node, node.target)) {
      case ResolvedReadWriteTarget result:
        readType = result.readType;
        writeAcceptedType = result.writeAcceptedType;
        variableElement = result.variableElement;
        readExpressionInfo = result.readExpressionInfo;
      case UnresolvedReadWriteTarget():
        _analyzeValue(node, UnknownInferredType.instance);
        node.recordStaticType(
          NeverTypeImpl.instance,
          typeAnalyzer: _typeAnalyzer,
        );
        return;
      case InvalidReadWriteTarget(:var expression?):
        _resolveInvalidIfNull(node, expression, contextType: contextType);
        return;
      case InvalidReadWriteTarget(:var target):
        _analyzeValue(node, InvalidTypeImpl.instance);
        node.recordStaticType(
          target is InvalidExtensionOverrideAssignmentTargetImpl
              ? DynamicTypeImpl.instance
              : InvalidTypeImpl.instance,
          typeAnalyzer: _typeAnalyzer,
        );
        return;
    }

    if (readType is VoidType) {
      _diagnosticReporter.report(diag.useOfVoidResult.at(node.operator));
    }

    var rhsContext = writeAcceptedType;
    if (variableElement case var element?) {
      rhsContext = _typeAnalyzer.localVariableTypeProvider.getWriteType(
        element,
      );
    }

    var flow = _typeAnalyzer.flowAnalysis.flow;
    flow?.ifNullExpression_rightBegin(
      readExpressionInfo,
      SharedTypeView(readType),
      offset: node.operator.offset,
    );

    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(rhsContext),
    );
    node.value = _typeAnalyzer.popRewrite()!;
    var valueType = node.value.typeOrThrow;
    var whyNotPromoted = flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(node.value),
    );

    var nodeType = _computeIfNullType(
      readType: readType,
      valueType: valueType,
      contextType: contextType,
    );
    node.recordStaticType(nodeType, typeAnalyzer: _typeAnalyzer);
    _checkForInvalidAssignment(
      node.target,
      writeAcceptedType,
      node.value,
      valueType,
      whyNotPromoted: whyNotPromoted,
    );
    _typeAnalyzer.checkWriteOfAssignedFinalLocalVariable(node.target);

    if (flow == null) return;
    if (variableElement case PromotableElementImpl element) {
      _typeAnalyzer.flowAnalysis.storeExpressionInfo(
        node,
        flow.write(
          node,
          element,
          SharedTypeView(node.typeOrThrow),
          null,
          offset: node.end,
        ),
      );
    }
    flow.ifNullExpression_end(offset: node.end);
  }

  /// Resolves [target] of the read-write operation [node]: a compound
  /// assignment, `??=`, `++`, or `--`.
  ///
  /// This does all the work that depends only on the target, so that each
  /// operation adds only its operator-specific work.
  ReadWriteTargetResult resolveReadWriteTarget(
    ExpressionImpl node,
    AssignmentTargetImpl target,
  ) {
    switch (target) {
      case CascadeIndexAssignmentTargetImpl():
        var result = _resolveCascadeIndexReadWriteTarget(target);
        if (result == null) return const UnresolvedReadWriteTarget();
        return ResolvedReadWriteTarget(
          readType: result.read.type,
          writeAcceptedType: result.write.acceptedType,
        );
      case CascadePropertyAssignmentTargetImpl():
        var result = _resolveCascadePropertyReadWriteTarget(node, target);
        if (result == null) return const UnresolvedReadWriteTarget();
        return ResolvedReadWriteTarget(
          readType: operatorReadType(result.read, result.write),
          writeAcceptedType: result.write.acceptedType,
          readExpressionInfo: result.readExpressionInfo,
        );
      case ReceiverIndexAssignmentTargetImpl():
        var result = _resolveIndexReadWriteTarget(target);
        if (result == null) return const UnresolvedReadWriteTarget();
        return ResolvedReadWriteTarget(
          readType: result.read.type,
          writeAcceptedType: result.write.acceptedType,
        );
      case ReceiverPropertyAssignmentTargetImpl():
        analyzePropertyTargetReceiver(node, target);
        var result = _propertyElementResolver
            .resolveReceiverPropertyReadWriteAssignmentTarget(target);
        if (result == null) return const UnresolvedReadWriteTarget();
        target.read = result.read;
        target.write = result.write;
        return ResolvedReadWriteTarget(
          readType: operatorReadType(result.read, result.write),
          writeAcceptedType: result.write.acceptedType,
          readExpressionInfo: result.readExpressionInfo,
        );
      case ImportPrefixedAssignmentTargetImpl():
        _propertyElementResolver.resolveImportPrefixedAssignmentTarget(target);
        var read = target.read!;
        var write = target.write!;
        return ResolvedReadWriteTarget(
          readType: operatorReadType(read, write),
          writeAcceptedType: write.acceptedType,
        );
      case UnqualifiedNameAssignmentTargetImpl():
        var result = _propertyElementResolver
            .resolveUnqualifiedNameReadWriteAssignmentTarget(target);
        target.read = result.read;
        target.write = result.write;
        return ResolvedReadWriteTarget(
          readType: operatorReadType(result.read, result.write),
          writeAcceptedType: result.write.acceptedType,
          variableElement: switch (result.write) {
            VariableWriteResolutionImpl(:var element) => element,
            _ => null,
          },
          readExpressionInfo: result.readExpressionInfo,
        );
      case ParsedAssignmentTargetImpl():
        throw StateError('Parsed assignment target was not lowered');
      case InvalidExtensionOverrideAssignmentTargetImpl():
        _typeAnalyzer.visitExtensionOverride2(target.extensionOverride);
        target.read = const InvalidReadResolutionImpl();
        target.write = const InvalidWriteResolutionImpl();
        return InvalidReadWriteTarget(target: target, expression: null);
      case InvalidSuperAssignmentTargetImpl():
        _typeAnalyzer.visitSuperReference(target.superReference);
        target.read = const InvalidReadResolutionImpl();
        target.write = const InvalidWriteResolutionImpl();
        return InvalidReadWriteTarget(target: target, expression: null);
      case InvalidExpressionAssignmentTargetImpl():
        _typeAnalyzer.analyzeExpression(
          target.expression,
          SharedTypeSchemaView(UnknownInferredType.instance),
        );
        target.expression = _typeAnalyzer.popRewrite()!;
        target.read = const InvalidReadResolutionImpl();
        target.write = const InvalidWriteResolutionImpl();
        return InvalidReadWriteTarget(
          target: target,
          expression: target.expression,
        );
    }
  }

  /// Analyzes the value of [node] with [contextType], and replaces it with
  /// its rewrite.
  void _analyzeValue(AssignmentExpression2Impl node, TypeImpl contextType) {
    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(contextType),
    );
    node.value = _typeAnalyzer.popRewrite()!;
  }

  void _checkForInvalidAssignment(
    AssignmentTargetImpl target,
    TypeImpl writeType,
    Expression right,
    TypeImpl rightType, {
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    if (writeType is! VoidType && _checkForUseOfVoidResult(right)) {
      return;
    }

    var strictCasts = _typeAnalyzer.analysisOptions.strictCasts;
    if (_typeSystem.isAssignableTo(
      rightType,
      writeType,
      strictCasts: strictCasts,
    )) {
      return;
    }

    if (writeType is RecordTypeImpl &&
        writeType.positionalFields.length == 1 &&
        rightType is! RecordType &&
        right is ParenthesizedExpressionImpl) {
      var field = writeType.positionalFields.first;
      if (_typeSystem.isAssignableTo(
        field.type,
        rightType,
        strictCasts: strictCasts,
      )) {
        _diagnosticReporter.report(
          diag.recordLiteralOnePositionalNoTrailingCommaByType.at(right),
        );
        return;
      }
    }

    _diagnosticReporter.report(
      // An index assignment invokes `operator []=`, so a non-assignable value
      // is reported as an argument error.
      (target is IndexAssignmentTargetImpl
              ? const NonAssignabilityReporterForArgument().createDiagnostic(
                  expectedStaticType: writeType,
                  actualStaticType: rightType,
                )
              : diag.invalidAssignment.withArguments(
                  actualStaticType: rightType,
                  expectedStaticType: writeType,
                ))
          .withContextMessages(
            _typeAnalyzer.computeWhyNotPromotedMessages(
              right,
              whyNotPromoted?.call(),
            ),
          )
          .at(right),
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [diag.useOfVoidResult].
  // TODO(scheglov): this is duplicate
  bool _checkForUseOfVoidResult(Expression expression) {
    if (expression.staticType is! VoidTypeImpl) {
      return false;
    }

    if (expression is NamedFunctionInvocation) {
      _diagnosticReporter.report(diag.useOfVoidResult.at(expression.name));
    } else {
      _diagnosticReporter.report(diag.useOfVoidResult.at(expression));
    }

    return true;
  }

  TypeImpl _computeCompoundOperatorResultType(
    CompoundAssignmentImpl node, {
    required TypeImpl readType,
  }) {
    if (identical(readType, NeverTypeImpl.instance)) {
      return NeverTypeImpl.instance;
    }
    if (readType is DynamicType) {
      return DynamicTypeImpl.instance;
    }
    var element = node.element;
    if (element == null) {
      return InvalidTypeImpl.instance;
    }
    return _typeSystem.refineBinaryExpressionType(
      readType,
      node.operator.type,
      node.value.typeOrThrow,
      element.returnType,
      element,
    );
  }

  TypeImpl _computeCompoundRhsContext({
    required TypeImpl operatorTargetType,
    required TypeImpl writeContextType,
    required InternalMethodElement? element,
  }) {
    if (element != null && element.formalParameters.isNotEmpty) {
      return _typeSystem.refineNumericInvocationContext(
        operatorTargetType,
        element,
        writeContextType,
        element.formalParameters.first.type,
      );
    }
    return UnknownInferredType.instance;
  }

  TypeImpl _computeIfNullType({
    required TypeImpl readType,
    required TypeImpl valueType,
    required TypeImpl contextType,
  }) {
    // An if-null assignment `E` of the form `lvalue ??= e` with context type
    // `K` is analyzed as follows:
    //
    // - Let `T1` be the read type of the lvalue.
    var t1 = readType;
    // - Let `T2` be the type of `e` inferred with context type `T1`.
    var t2 = valueType;
    // - Let `T` be `UP(NonNull(T1), T2)`.
    var nonNullT1 = _typeSystem.promoteToNonNull(t1);
    var t = _typeSystem.leastUpperBound(nonNullT1, t2);
    // - Let `S` be the greatest closure of `K`.
    var s = _typeAnalyzer.operations
        .greatestClosureOfSchema(SharedTypeSchemaView(contextType))
        .unwrapTypeView<TypeImpl>();
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!_typeAnalyzer.definingLibrary.featureSet.isEnabled(
      Feature.inference_update_3,
    )) {
      return t;
    }
    // - If `T <: S`, then the type of `E` is `T`.
    if (_typeSystem.isSubtypeOf(t, s)) {
      return t;
    }
    // - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of `E`
    //   is `S`.
    if (_typeSystem.isSubtypeOf(nonNullT1, s) &&
        _typeSystem.isSubtypeOf(t2, s)) {
      return s;
    }
    // - Otherwise, the type of `E` is `T`.
    return t;
  }

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  _resolveCascadeIndexReadWriteTarget(CascadeIndexAssignmentTargetImpl target) {
    var result = _typeAnalyzer.resolveCascadeIndex(
      target,
      hasRead: true,
      hasWrite: true,
    );
    target.read = result?.read;
    target.write = result?.write;

    _typeAnalyzer.analyzeExpression(
      target.index,
      SharedTypeSchemaView(
        result?.read?.indexContextType ?? UnknownInferredType.instance,
      ),
    );
    target.index = _typeAnalyzer.popRewrite()!;
    var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(target.index),
    );
    var readElement = result?.read?.elementOrRecovery;
    var writeElement = result?.write?.elementOrRecovery;
    _typeAnalyzer.checkIndexExpressionIndex(
      target.index,
      readElement: readElement,
      writeElement: writeElement,
      whyNotPromoted: whyNotPromoted,
    );
    var read = result?.read;
    var write = result?.write;
    if (read == null || write == null) return null;
    return (read: read, write: write);
  }

  ({
    NamedReadResolutionImpl read,
    NamedWriteResolutionImpl write,
    ExpressionInfo? readExpressionInfo,
  })?
  _resolveCascadePropertyReadWriteTarget(
    ExpressionImpl node,
    CascadePropertyAssignmentTargetImpl target,
  ) {
    var result = _typeAnalyzer.resolveCascadeProperty(
      node,
      target.name,
      hasRead: true,
      hasWrite: true,
    );
    target.read = result?.read;
    target.write = result?.write;
    var read = result?.read;
    var write = result?.write;
    if (read == null || write == null) return null;
    return (
      read: read,
      write: write,
      readExpressionInfo: result?.readExpressionInfo,
    );
  }

  void _resolveCompoundOperator(
    CompoundAssignmentImpl node, {
    required ExpressionImpl? receiver,
    required TypeImpl readType,
  }) {
    if (identical(readType, NeverTypeImpl.instance)) {
      return;
    }
    if (readType is VoidType) {
      _diagnosticReporter.report(diag.useOfVoidResult.at(node.operator));
      return;
    }

    var methodName =
        node.operator.type.binaryOperatorOfCompoundAssignment!.lexeme;
    var result = _typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: readType,
      name: methodName,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node.operator,
      nameErrorEntity: node.operator,
      parentNode: node,
    );
    node.element = result.getter2 as InternalMethodElement?;
    if (result.getterOutcome == LookupOutcome.notFound) {
      _diagnosticReporter.report(
        diag.undefinedOperator
            .withArguments(operator: methodName, type: readType)
            .at(node.operator),
      );
    }
  }

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  _resolveIndexReadWriteTarget(ReceiverIndexAssignmentTargetImpl target) {
    target.receiver = _typeAnalyzer.analyzeInstanceReceiver(
      target.receiver,
      continueNullShorting: true,
    );

    var receiverDoesNotComplete =
        target.receiver is! ExtensionOverride2Impl &&
        identical(
          _typeSystem.resolveToBound(
            _typeAnalyzer.instanceReceiverType(target.receiver),
          ),
          NeverTypeImpl.instance,
        );
    if (target.question case var question? when !receiverDoesNotComplete) {
      _typeAnalyzer.startNullAwareAssignmentTarget(
        target.receiver,
        offset: question.offset,
      );
      _typeAnalyzer.nullSafetyDeadCodeVerifier.visitNode(target.index);
    }

    var result = _propertyElementResolver.resolveIndexReadWriteAssignmentTarget(
      target,
    );
    target.read = result?.read;
    target.write = result?.write;

    _typeAnalyzer.analyzeExpression(
      target.index,
      SharedTypeSchemaView(
        result?.read.indexContextType ?? UnknownInferredType.instance,
      ),
    );
    target.index = _typeAnalyzer.popRewrite()!;
    var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(target.index),
    );
    var readElement = result?.read.elementOrRecovery;
    var writeElement = result?.write.elementOrRecovery;
    _typeAnalyzer.checkIndexExpressionIndex(
      target.index,
      readElement: readElement,
      writeElement: writeElement,
      whyNotPromoted: whyNotPromoted,
    );
    return result;
  }

  void _resolveInvalidCompound(
    CompoundAssignmentImpl node,
    ExpressionImpl expression,
  ) {
    var readType = expression.typeOrThrow;
    _resolveCompoundOperator(node, receiver: expression, readType: readType);
    var rhsContext = _computeCompoundRhsContext(
      operatorTargetType: readType,
      writeContextType: readType,
      element: node.element,
    );
    _analyzeValue(node, rhsContext);
    var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(node.value),
    );

    var operatorResultType = _computeCompoundOperatorResultType(
      node,
      readType: readType,
    );
    node.operatorResultType = operatorResultType;
    node.recordStaticType(operatorResultType, typeAnalyzer: _typeAnalyzer);
    _typeAnalyzer.checkForArgumentTypeNotAssignableForArgument(
      node.value,
      whyNotPromoted: whyNotPromoted,
    );
  }

  void _resolveInvalidDirect(
    DirectAssignmentImpl node,
    InvalidExpressionAssignmentTargetImpl target, {
    bool expressionIsResolved = false,
  }) {
    if (!expressionIsResolved) {
      _typeAnalyzer.analyzeExpression(
        target.expression,
        SharedTypeSchemaView(UnknownInferredType.instance),
      );
      target.expression = _typeAnalyzer.popRewrite()!;
    }
    target.write = const InvalidWriteResolutionImpl();

    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(InvalidTypeImpl.instance),
    );
    node.value = _typeAnalyzer.popRewrite()!;
    node.recordStaticType(node.value.typeOrThrow, typeAnalyzer: _typeAnalyzer);
  }

  void _resolveInvalidExtensionOverride(
    DirectAssignmentImpl node,
    InvalidExtensionOverrideAssignmentTargetImpl target,
  ) {
    _typeAnalyzer.visitExtensionOverride2(target.extensionOverride);
    target.write = const InvalidWriteResolutionImpl();
    _analyzeValue(node, InvalidTypeImpl.instance);
    node.recordStaticType(node.value.typeOrThrow, typeAnalyzer: _typeAnalyzer);
  }

  void _resolveInvalidIfNull(
    IfNullAssignmentImpl node,
    ExpressionImpl expression, {
    required TypeImpl contextType,
  }) {
    var readType = expression.typeOrThrow;
    _analyzeValue(node, InvalidTypeImpl.instance);
    node.recordStaticType(
      _computeIfNullType(
        readType: readType,
        valueType: node.value.typeOrThrow,
        contextType: contextType,
      ),
      typeAnalyzer: _typeAnalyzer,
    );
  }

  void _resolveInvalidSuper(
    DirectAssignmentImpl node,
    InvalidSuperAssignmentTargetImpl target,
  ) {
    _typeAnalyzer.visitSuperReference(target.superReference);
    target.write = const InvalidWriteResolutionImpl();
    _analyzeValue(node, InvalidTypeImpl.instance);
    node.recordStaticType(node.value.typeOrThrow, typeAnalyzer: _typeAnalyzer);
  }

  /// The type that a read-write operation on a target reads, given the
  /// target's [read] and [write] resolutions.
  ///
  /// When the target names a method, the read is a tear-off, and the write
  /// fails, which is reported. The tear-off type is replaced with
  /// [InvalidTypeImpl], so that the operator, or the flow analysis and the
  /// dead code check of `??=`, don't report follow-up diagnostics about the
  /// method's function type.
  static TypeImpl operatorReadType(
    ReadResolutionImpl read,
    WriteResolutionImpl? write,
  ) {
    if (read is ExecutableTearOffResolution &&
        write is InvalidNamedWriteResolution) {
      return InvalidTypeImpl.instance;
    }
    return read.type;
  }
}

/// An assignment target of a read-write operation that is analyzed as an
/// expression, or as `super` or an extension override, because it can't be
/// read and written.
final class InvalidReadWriteTarget extends ReadWriteTargetResult {
  final AssignmentTargetImpl target;

  /// The analyzed expression, if [target] is an
  /// [InvalidExpressionAssignmentTargetImpl].
  final ExpressionImpl? expression;

  new({required this.target, required this.expression});
}

/// The result of [AssignmentExpressionResolver.resolveReadWriteTarget].
sealed class ReadWriteTargetResult {
  const new();
}

/// A resolved assignment target of a read-write operation.
final class ResolvedReadWriteTarget extends ReadWriteTargetResult {
  /// The type of the value that the operation reads.
  final TypeImpl readType;

  /// The type that the value written back must be assignable to.
  final TypeImpl writeAcceptedType;

  /// The variable that is written, if the target is a local variable or a
  /// parameter.
  final InternalVariableElement? variableElement;

  /// The flow analysis information about the read.
  final ExpressionInfo? readExpressionInfo;

  new({
    required this.readType,
    required this.writeAcceptedType,
    this.variableElement,
    this.readExpressionInfo,
  });
}

/// An assignment target of a read-write operation whose resolution failed;
/// the failure is already reported.
final class UnresolvedReadWriteTarget extends ReadWriteTargetResult {
  const new();
}
