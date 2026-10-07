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
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Helper for resolving V2 assignment expressions and their targets.
class AssignmentExpressionResolver {
  final TypeAnalyzer _typeAnalyzer;
  final TypePropertyResolver _typePropertyResolver;
  final AssignmentExpressionShared _assignmentShared;

  AssignmentExpressionResolver({required TypeAnalyzer typeAnalyzer})
    : _typeAnalyzer = typeAnalyzer,
      _typePropertyResolver = typeAnalyzer.typePropertyResolver,
      _assignmentShared = AssignmentExpressionShared(
        typeAnalyzer: typeAnalyzer,
      );

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

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  resolveCascadeIndexReadWriteTarget(CascadeIndexAssignmentTargetImpl target) {
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
  resolveCascadePropertyReadWriteTarget(
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

  void resolveCompound(
    CompoundAssignmentImpl node, {
    required TypeImpl contextType,
  }) {
    var target = node.target;
    late TypeImpl readType;
    late TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    switch (target) {
      case CascadeIndexAssignmentTargetImpl():
        var targetResult = resolveCascadeIndexReadWriteTarget(target);
        if (targetResult == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case CascadePropertyAssignmentTargetImpl():
        var targetResult = resolveCascadePropertyReadWriteTarget(node, target);
        if (targetResult == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case ReceiverIndexAssignmentTargetImpl():
        var targetResult = resolveIndexReadWriteTarget(target);
        if (targetResult == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case ReceiverPropertyAssignmentTargetImpl():
        analyzePropertyTargetReceiver(node, target);
        var targetResult = _typeAnalyzer
            .resolveReceiverPropertyReadWriteAssignmentTarget(target);
        if (targetResult == null) {
          _typeAnalyzer.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _typeAnalyzer.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(
            NeverTypeImpl.instance,
            typeAnalyzer: _typeAnalyzer,
          );
          return;
        }
        target.read = targetResult.read;
        target.write = targetResult.write;
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        if (target.receiver is UnqualifiedNameExpressionImpl &&
            target.operator.type == TokenType.PERIOD &&
            targetResult.read is ExecutableTearOffResolution) {
          // V1 does not report an additional operator error when a prefixed
          // identifier names a method that cannot be assigned.
          readType = InvalidTypeImpl.instance;
        }
      case ImportPrefixedAssignmentTargetImpl():
        _typeAnalyzer.resolveImportPrefixedAssignmentTarget(target);
        readType = target.read!.type;
        writeAcceptedType = target.write!.acceptedType;
      case UnqualifiedNameAssignmentTargetImpl():
        var targetResult = _typeAnalyzer
            .resolveUnqualifiedNameReadWriteAssignmentTarget(target);
        target.read = targetResult.read;
        target.write = targetResult.write;
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        if (targetResult.write case VariableWriteResolutionImpl(:var element)) {
          variableElement = element;
        }
        _assignmentShared.checkFinalTargetAlreadyAssigned(target);
      case ParsedAssignmentTargetImpl():
        throw StateError('Parsed assignment target was not lowered');
      case InvalidExtensionOverrideAssignmentTargetImpl():
        _resolveInvalidExtensionOverride(node, target);
        return;
      case InvalidSuperAssignmentTargetImpl():
        _resolveInvalidSuper(node, target);
        return;
      case InvalidExpressionAssignmentTargetImpl():
        _resolveInvalidCompound(node, target);
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
      writeAcceptedType,
      node.value,
      operatorResultType,
      whyNotPromoted: null,
    );
    _typeAnalyzer.checkForArgumentTypeNotAssignableForArgument(
      node.value,
      whyNotPromoted: whyNotPromoted,
    );

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
        var resolution = _typeAnalyzer.resolveIndexDirectAssignmentTarget(
          target,
        );
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
        var resolution = _typeAnalyzer
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
        _typeAnalyzer.resolveImportPrefixedAssignmentTarget(target);
        writeAcceptedType = target.write!.acceptedType;
      case UnqualifiedNameAssignmentTargetImpl():
        var resolution = _typeAnalyzer.resolveUnqualifiedNameAssignmentTarget(
          target,
        );
        target.write = resolution;
        writeAcceptedType = resolution.acceptedType;
        if (resolution case VariableWriteResolutionImpl(:var element)) {
          variableElement = element;
        }
        _assignmentShared.checkFinalTargetAlreadyAssigned(target);
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
      writeAcceptedType,
      node.value,
      valueType,
      whyNotPromoted: whyNotPromoted,
    );

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
    var target = node.target;
    late TypeImpl readType;
    late TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    ExpressionInfo? readExpressionInfo;
    switch (target) {
      case CascadeIndexAssignmentTargetImpl():
        var targetResult = resolveCascadeIndexReadWriteTarget(target);
        if (targetResult == null) {
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
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case CascadePropertyAssignmentTargetImpl():
        var targetResult = resolveCascadePropertyReadWriteTarget(node, target);
        if (targetResult == null) {
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
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        readExpressionInfo = targetResult.readExpressionInfo;
      case ReceiverIndexAssignmentTargetImpl():
        var targetResult = resolveIndexReadWriteTarget(target);
        if (targetResult == null) {
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
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case ReceiverPropertyAssignmentTargetImpl():
        analyzePropertyTargetReceiver(node, target);
        var targetResult = _typeAnalyzer
            .resolveReceiverPropertyReadWriteAssignmentTarget(target);
        if (targetResult == null) {
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
        target.read = targetResult.read;
        target.write = targetResult.write;
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        readExpressionInfo = targetResult.readExpressionInfo;
      case ImportPrefixedAssignmentTargetImpl():
        _typeAnalyzer.resolveImportPrefixedAssignmentTarget(target);
        readType = target.read!.type;
        writeAcceptedType = target.write!.acceptedType;
      case UnqualifiedNameAssignmentTargetImpl():
        var targetResult = _typeAnalyzer
            .resolveUnqualifiedNameReadWriteAssignmentTarget(target);
        target.read = targetResult.read;
        target.write = targetResult.write;
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        if (targetResult.write case VariableWriteResolutionImpl(:var element)) {
          variableElement = element;
        }
        readExpressionInfo = targetResult.readExpressionInfo;
        _assignmentShared.checkFinalTargetAlreadyAssigned(target);
      case ParsedAssignmentTargetImpl():
        throw StateError('Parsed assignment target was not lowered');
      case InvalidExtensionOverrideAssignmentTargetImpl():
        _resolveInvalidExtensionOverride(node, target);
        return;
      case InvalidSuperAssignmentTargetImpl():
        _resolveInvalidSuper(node, target);
        return;
      case InvalidExpressionAssignmentTargetImpl():
        _resolveInvalidIfNull(node, target, contextType: contextType);
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
      writeAcceptedType,
      node.value,
      valueType,
      whyNotPromoted: whyNotPromoted,
    );

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

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  resolveIndexReadWriteTarget(ReceiverIndexAssignmentTargetImpl target) {
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

    var result = _typeAnalyzer.resolveIndexReadWriteAssignmentTarget(target);
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

  void _checkForInvalidAssignment(
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
      diag.invalidAssignment
          .withArguments(
            actualStaticType: rightType,
            expectedStaticType: writeType,
          )
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
      hasWrite: true,
      propertyErrorEntity: node.operator,
      nameErrorEntity: node.operator,
      parentNode: node,
    );
    node.element = result.getter2 as InternalMethodElement?;
    if (result.needsGetterError) {
      _diagnosticReporter.report(
        diag.undefinedOperator
            .withArguments(operator: methodName, type: readType)
            .at(node.operator),
      );
    }
  }

  void _resolveInvalidCompound(
    CompoundAssignmentImpl node,
    InvalidExpressionAssignmentTargetImpl target,
  ) {
    _typeAnalyzer.analyzeExpression(
      target.expression,
      SharedTypeSchemaView(UnknownInferredType.instance),
    );
    target.expression = _typeAnalyzer.popRewrite()!;
    target.read = const InvalidReadResolutionImpl();
    target.write = const InvalidWriteResolutionImpl();

    var readType = target.expression.typeOrThrow;
    _resolveCompoundOperator(
      node,
      receiver: target.expression,
      readType: readType,
    );
    var rhsContext = _computeCompoundRhsContext(
      operatorTargetType: readType,
      writeContextType: readType,
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
    AssignmentExpression2Impl node,
    InvalidExtensionOverrideAssignmentTargetImpl target,
  ) {
    _typeAnalyzer.visitExtensionOverride2(target.extensionOverride);
    if (target.hasRead) target.read = const InvalidReadResolutionImpl();
    target.write = const InvalidWriteResolutionImpl();
    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(InvalidTypeImpl.instance),
    );
    node.value = _typeAnalyzer.popRewrite()!;
    if (node is CompoundAssignmentImpl) {
      node.operatorResultType = InvalidTypeImpl.instance;
    }
    node.recordStaticType(switch (node) {
      DirectAssignmentImpl() => node.value.typeOrThrow,
      IfNullAssignmentImpl() => DynamicTypeImpl.instance,
      _ => InvalidTypeImpl.instance,
    }, typeAnalyzer: _typeAnalyzer);
  }

  void _resolveInvalidIfNull(
    IfNullAssignmentImpl node,
    InvalidExpressionAssignmentTargetImpl target, {
    required TypeImpl contextType,
    bool expressionIsResolved = false,
  }) {
    if (!expressionIsResolved) {
      _typeAnalyzer.analyzeExpression(
        target.expression,
        SharedTypeSchemaView(UnknownInferredType.instance),
      );
      target.expression = _typeAnalyzer.popRewrite()!;
    }
    target.read = const InvalidReadResolutionImpl();
    target.write = const InvalidWriteResolutionImpl();

    var readType = target.expression.typeOrThrow;
    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(InvalidTypeImpl.instance),
    );
    node.value = _typeAnalyzer.popRewrite()!;
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
    AssignmentExpression2Impl node,
    InvalidSuperAssignmentTargetImpl target,
  ) {
    _typeAnalyzer.visitSuperReference(target.superReference);
    if (target.hasRead) target.read = const InvalidReadResolutionImpl();
    target.write = const InvalidWriteResolutionImpl();
    _typeAnalyzer.analyzeExpression(
      node.value,
      SharedTypeSchemaView(InvalidTypeImpl.instance),
    );
    node.value = _typeAnalyzer.popRewrite()!;
    if (node is CompoundAssignmentImpl) {
      node.operatorResultType = InvalidTypeImpl.instance;
    }
    node.recordStaticType(
      node is DirectAssignmentImpl
          ? node.value.typeOrThrow
          : InvalidTypeImpl.instance,
      typeAnalyzer: _typeAnalyzer,
    );
  }
}

class AssignmentExpressionShared {
  final TypeAnalyzer _typeAnalyzer;

  AssignmentExpressionShared({required TypeAnalyzer typeAnalyzer})
    : _typeAnalyzer = typeAnalyzer;

  DiagnosticReporter get _errorReporter => _typeAnalyzer.diagnosticReporter;

  /// Reports a write to [target] if it is a final local variable that might
  /// already be assigned.
  void checkFinalTargetAlreadyAssigned(
    UnqualifiedNameAssignmentTargetImpl target, {
    bool isWrittenRepeatedly = false,
  }) {
    if (_typeAnalyzer.flowAnalysis.flow == null) return;
    var element = target.scopeLookupResult?.getter;
    if (element is PromotableElementImpl) {
      _checkFinalAlreadyAssigned(
        target,
        element,
        isWrittenRepeatedly: isWrittenRepeatedly,
      );
    }
  }

  void _checkFinalAlreadyAssigned(
    AstNode node,
    PromotableElementImpl element, {
    required bool isWrittenRepeatedly,
  }) {
    var flowAnalysis = _typeAnalyzer.flowAnalysis;
    var assigned = flowAnalysis.isDefinitelyAssigned(node, element);
    var unassigned = flowAnalysis.isDefinitelyUnassigned(node, element);

    if (element.isFinal) {
      if (element.isLate) {
        if (isWrittenRepeatedly || assigned) {
          _errorReporter.report(diag.lateFinalLocalAlreadyAssigned.at(node));
        }
      } else if (isWrittenRepeatedly || !unassigned) {
        _errorReporter.report(
          diag.assignmentToFinalLocal
              .withArguments(variableName: element.name!)
              .at(node),
        );
      }
    }
  }
}
