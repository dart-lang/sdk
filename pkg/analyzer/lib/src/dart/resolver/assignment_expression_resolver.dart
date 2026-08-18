// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [AssignmentExpression]s.
class AssignmentExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final AssignmentExpressionShared _assignmentShared;

  AssignmentExpressionResolver({required ResolverVisitor resolver})
    : _resolver = resolver,
      _typePropertyResolver = resolver.typePropertyResolver,
      _assignmentShared = AssignmentExpressionShared(resolver: resolver);

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void analyzePropertyTargetReceiver(
    AstNode node,
    ReceiverPropertyAssignmentTargetImpl target,
  ) {
    if (target.receiver case ExtensionOverrideImpl receiver) {
      _resolver.visitExtensionOverride(receiver);
      receiver.setPseudoExpressionStaticType(
        receiver.extendedType ?? InvalidTypeImpl.instance,
      );
    } else {
      _resolver.analyzeExpression(
        target.receiver,
        SharedTypeSchemaView(UnknownInferredType.instance),
        continueNullShorting: true,
      );
      target.receiver = _resolver.popRewrite()!;
    }

    var receiverDoesNotComplete = identical(
      _typeSystem.resolveToBound(target.receiver.typeOrThrow),
      NeverTypeImpl.instance,
    );
    if (target.operator.type == TokenType.QUESTION_PERIOD &&
        !receiverDoesNotComplete) {
      _resolver.startNullAwareAssignmentTarget(target.receiver);
      _resolver.nullSafetyDeadCodeVerifier.visitNullAwareAccess(
        node,
        target.propertyName,
      );
      _resolver.nullSafetyDeadCodeVerifier.verifyNullAwareAccess(
        node,
        target.receiver,
        target.operator,
      );
    }
  }

  void resolve(AssignmentExpressionImpl node, {required TypeImpl contextType}) {
    var operator = node.operator.type;
    var hasRead = operator != TokenType.EQ;
    var isIfNull = operator == TokenType.QUESTION_QUESTION_EQ;

    var leftResolution = _resolver.resolveForWrite(
      node: node.leftHandSide2,
      hasRead: hasRead,
    );

    var left = node.leftHandSide2;
    var right = node.rightHandSide2;

    var readElement = leftResolution.readElement2;
    var writeElement = leftResolution.writeElement2;
    var writeElement2 = leftResolution.writeElement2;

    if (hasRead) {
      _resolver.setReadElement(
        left,
        readElement,
        atDynamicTarget: leftResolution.atDynamicTarget,
      );
      {
        var recordField = leftResolution.recordField;
        if (recordField != null) {
          node.readType = recordField.type;
        }
      }
      _resolveOperator(node);
    }
    _resolver.setWriteElement(
      left,
      writeElement,
      atDynamicTarget: leftResolution.atDynamicTarget,
    );

    // TODO(scheglov): Use VariableElement and do in resolveForWrite() ?
    _assignmentShared.checkFinalAlreadyAssigned(left);

    TypeImpl rhsContext;
    {
      var leftType = node.writeType;
      if (writeElement is VariableElement) {
        leftType = _resolver.localVariableTypeProvider.getType(
          left as SimpleIdentifierImpl,
          isRead: false,
        );
      }
      rhsContext = _computeRhsContext(node, leftType!, operator, right);
    }

    var flow = _resolver.flowAnalysis.flow;
    if (flow != null && isIfNull) {
      flow.ifNullExpression_rightBegin(
        _resolver.flowAnalysis.getExpressionInfo(left),
        SharedTypeView(node.readType!),
      );
    }

    _resolver.analyzeExpression(right, SharedTypeSchemaView(rhsContext));
    right = _resolver.popRewrite()!;
    var whyNotPromoted = flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(right),
    );

    _resolveTypes(
      node,
      whyNotPromoted: whyNotPromoted,
      contextType: contextType,
    );

    if (flow != null) {
      if (writeElement2 is PromotableElementImpl) {
        _resolver.flowAnalysis.storeExpressionInfo(
          node,
          flow.write(
            node,
            writeElement2,
            SharedTypeView(node.typeOrThrow),
            hasRead ? null : _resolver.flowAnalysis.getExpressionInfo(right),
          ),
        );
      }
      if (isIfNull) {
        flow.ifNullExpression_end();
      }
    }
  }

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  resolveCascadeIndexReadWriteTarget(CascadeIndexAssignmentTargetImpl target) {
    var result = _resolver.resolveCascadeIndex(
      target,
      hasRead: true,
      hasWrite: true,
    );
    target.read = result?.read;
    target.write = result?.write;

    _resolver.analyzeExpression(
      target.index,
      SharedTypeSchemaView(
        result?.read?.indexContextType ?? UnknownInferredType.instance,
      ),
    );
    target.index = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(target.index),
    );
    var readElement = switch (result?.read) {
      MethodIndexReadResolutionImpl(:var element) => element,
      InvalidIndexReadResolutionImpl(
        recovery: MethodIndexReadResolutionImpl(:var element),
      ) =>
        element,
      _ => null,
    };
    var writeElement = switch (result?.write) {
      MethodIndexWriteResolutionImpl(:var element) => element,
      InvalidIndexWriteResolutionImpl(
        recovery: MethodIndexWriteResolutionImpl(:var element),
      ) =>
        element,
      _ => null,
    };
    _resolver.checkIndexExpressionIndex(
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
    var result = _resolver.resolveCascadeProperty(
      node,
      target.propertyName,
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
    if (target is InvalidExpressionAssignmentTargetImpl) {
      _resolveInvalidCompound(node, target);
      return;
    }
    late TypeImpl readType;
    late TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    switch (target) {
      case CascadeIndexAssignmentTargetImpl():
        var targetResult = resolveCascadeIndexReadWriteTarget(target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case CascadePropertyAssignmentTargetImpl():
        var targetResult = resolveCascadePropertyReadWriteTarget(node, target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case IndexAssignmentTargetImpl():
        var targetResult = resolveIndexReadWriteTarget(target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case ReceiverPropertyAssignmentTargetImpl():
        analyzePropertyTargetReceiver(node, target);
        var targetResult = _resolver
            .resolveReceiverPropertyReadWriteAssignmentTarget(target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.operatorResultType = NeverTypeImpl.instance;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        target.read = targetResult.read;
        target.write = targetResult.write;
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case UnqualifiedNameAssignmentTargetImpl():
        var targetResult = _resolver
            .resolveUnqualifiedNameReadWriteAssignmentTarget(target);
        target.read = targetResult.read;
        target.write = targetResult.write;
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        if (targetResult.write case VariableWriteResolutionImpl(:var element)) {
          variableElement = element;
        }
        _assignmentShared.checkFinalTargetAlreadyAssigned(target);
      case InvalidExpressionAssignmentTargetImpl():
        throw StateError('Handled above');
    }

    _resolveCompoundOperator(node, receiver: null, readType: readType);

    // Analyze `target op= value` as an operator invocation whose receiver has
    // the target's read type and whose surrounding context is the target's
    // write type. Flow analysis may provide a promoted write type for a
    // variable; other targets use the type accepted by their write resolution.
    var writeContextType = writeAcceptedType;
    if (variableElement case var element?) {
      writeContextType = _resolver.localVariableTypeProvider.getWriteType(
        element,
      );
    }
    var rhsContext = _computeCompoundRhsContext(
      operatorTargetType: readType,
      writeContextType: writeContextType,
      element: node.element,
    );
    _resolver.analyzeExpression(node.value, SharedTypeSchemaView(rhsContext));
    node.value = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(node.value),
    );

    var operatorResultType = _computeCompoundOperatorResultType(
      node,
      readType: readType,
    );
    node.operatorResultType = operatorResultType;
    node.recordStaticType(operatorResultType, resolver: _resolver);

    _checkForInvalidAssignment(
      writeAcceptedType,
      node.value,
      operatorResultType,
      whyNotPromoted: null,
    );
    _resolver.checkForArgumentTypeNotAssignableForArgument(
      node.value,
      whyNotPromoted: whyNotPromoted,
    );

    var flow = _resolver.flowAnalysis.flow;
    if (flow == null) return;
    if (variableElement case PromotableElementImpl element) {
      _resolver.flowAnalysis.storeExpressionInfo(
        node,
        flow.write(node, element, SharedTypeView(operatorResultType), null),
      );
    }
  }

  void resolveDirect(
    DirectAssignmentImpl node, {
    required TypeImpl contextType,
  }) {
    var target = node.target;
    if (target is InvalidExpressionAssignmentTargetImpl) {
      _resolveInvalidDirect(node, target);
      return;
    }

    late TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    switch (target) {
      case CascadeIndexAssignmentTargetImpl():
        var result = _resolver.resolveCascadeIndex(
          target,
          hasRead: false,
          hasWrite: true,
        );
        var resolution = result?.write;
        target.write = resolution;
        _resolver.analyzeExpression(
          target.index,
          SharedTypeSchemaView(
            resolution?.indexContextType ?? UnknownInferredType.instance,
          ),
        );
        target.index = _resolver.popRewrite()!;
        var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
          _resolver.flowAnalysis.getExpressionInfo(target.index),
        );
        var writeElement = switch (resolution) {
          MethodIndexWriteResolutionImpl(:var element) => element,
          InvalidIndexWriteResolutionImpl(
            recovery: MethodIndexWriteResolutionImpl(:var element),
          ) =>
            element,
          _ => null,
        };
        _resolver.checkIndexExpressionIndex(
          target.index,
          readElement: null,
          writeElement: writeElement,
          whyNotPromoted: whyNotPromoted,
        );
        if (resolution == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case CascadePropertyAssignmentTargetImpl():
        var result = _resolver.resolveCascadeProperty(
          node,
          target.propertyName,
          hasRead: false,
          hasWrite: true,
        );
        var resolution = result?.write;
        target.write = resolution;
        if (resolution == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case IndexAssignmentTargetImpl():
        _resolver.analyzeExpression(
          target.receiver,
          SharedTypeSchemaView(UnknownInferredType.instance),
          continueNullShorting: true,
        );
        target.receiver = _resolver.popRewrite()!;
        var receiverDoesNotComplete =
            target.receiver is! ExtensionOverrideImpl &&
            identical(
              _typeSystem.resolveToBound(target.receiver.typeOrThrow),
              NeverTypeImpl.instance,
            );
        if (target.question != null && !receiverDoesNotComplete) {
          _resolver.startNullAwareAssignmentTarget(target.receiver);
          _resolver.nullSafetyDeadCodeVerifier.visitNode(target.index);
        }
        var resolution = _resolver.resolveIndexDirectAssignmentTarget(target);
        target.write = resolution;

        _resolver.analyzeExpression(
          target.index,
          SharedTypeSchemaView(
            resolution?.indexContextType ?? UnknownInferredType.instance,
          ),
        );
        target.index = _resolver.popRewrite()!;
        var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
          _resolver.flowAnalysis.getExpressionInfo(target.index),
        );
        var writeElement = switch (resolution) {
          MethodIndexWriteResolutionImpl(:var element) => element,
          InvalidIndexWriteResolutionImpl(
            recovery: MethodIndexWriteResolutionImpl(:var element),
          ) =>
            element,
          _ => null,
        };
        _resolver.checkIndexExpressionIndex(
          target.index,
          readElement: null,
          writeElement: writeElement,
          whyNotPromoted: whyNotPromoted,
        );

        if (resolution == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case ReceiverPropertyAssignmentTargetImpl():
        analyzePropertyTargetReceiver(node, target);
        var resolution = _resolver
            .resolveReceiverPropertyDirectAssignmentTarget(target);
        target.write = resolution;
        if (resolution == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        writeAcceptedType = resolution.acceptedType;
      case UnqualifiedNameAssignmentTargetImpl():
        var resolution = _resolver.resolveUnqualifiedNameAssignmentTarget(
          target,
        );
        target.write = resolution;
        writeAcceptedType = resolution.acceptedType;
        if (resolution case VariableWriteResolutionImpl(:var element)) {
          variableElement = element;
        }
        _assignmentShared.checkFinalTargetAlreadyAssigned(target);
      case InvalidExpressionAssignmentTargetImpl():
        throw StateError('Handled above');
    }

    var rhsContext = writeAcceptedType;
    if (variableElement case var element?) {
      rhsContext = _resolver.localVariableTypeProvider.getWriteType(element);
    }

    _resolver.analyzeExpression(node.value, SharedTypeSchemaView(rhsContext));
    node.value = _resolver.popRewrite()!;
    var valueType = node.value.typeOrThrow;
    var flow = _resolver.flowAnalysis.flow;
    var whyNotPromoted = flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(node.value),
    );

    node.recordStaticType(valueType, resolver: _resolver);
    _checkForInvalidAssignment(
      writeAcceptedType,
      node.value,
      valueType,
      whyNotPromoted: whyNotPromoted,
    );

    if (flow == null) return;
    if (variableElement case PromotableElementImpl element) {
      _resolver.flowAnalysis.storeExpressionInfo(
        node,
        flow.write(
          node,
          element,
          SharedTypeView(node.typeOrThrow),
          _resolver.flowAnalysis.getExpressionInfo(node.value),
        ),
      );
    }
  }

  void resolveIfNull(
    IfNullAssignmentImpl node, {
    required TypeImpl contextType,
  }) {
    var target = node.target;
    if (target is InvalidExpressionAssignmentTargetImpl) {
      _resolveInvalidIfNull(node, target, contextType: contextType);
      return;
    }
    late TypeImpl readType;
    late TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    ExpressionInfo? readExpressionInfo;
    switch (target) {
      case CascadeIndexAssignmentTargetImpl():
        var targetResult = resolveCascadeIndexReadWriteTarget(target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case CascadePropertyAssignmentTargetImpl():
        var targetResult = resolveCascadePropertyReadWriteTarget(node, target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        readExpressionInfo = targetResult.readExpressionInfo;
      case IndexAssignmentTargetImpl():
        var targetResult = resolveIndexReadWriteTarget(target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
      case ReceiverPropertyAssignmentTargetImpl():
        analyzePropertyTargetReceiver(node, target);
        var targetResult = _resolver
            .resolveReceiverPropertyReadWriteAssignmentTarget(target);
        if (targetResult == null) {
          _resolver.analyzeExpression(
            node.value,
            SharedTypeSchemaView(UnknownInferredType.instance),
          );
          node.value = _resolver.popRewrite()!;
          node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
          return;
        }
        target.read = targetResult.read;
        target.write = targetResult.write;
        readType = targetResult.read.type;
        writeAcceptedType = targetResult.write.acceptedType;
        readExpressionInfo = targetResult.readExpressionInfo;
      case UnqualifiedNameAssignmentTargetImpl():
        var targetResult = _resolver
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
      case InvalidExpressionAssignmentTargetImpl():
        throw StateError('Handled above');
    }

    if (readType is VoidType) {
      _diagnosticReporter.report(diag.useOfVoidResult.at(node.operator));
    }

    var rhsContext = writeAcceptedType;
    if (variableElement case var element?) {
      rhsContext = _resolver.localVariableTypeProvider.getWriteType(element);
    }

    var flow = _resolver.flowAnalysis.flow;
    flow?.ifNullExpression_rightBegin(
      readExpressionInfo,
      SharedTypeView(readType),
    );

    _resolver.analyzeExpression(node.value, SharedTypeSchemaView(rhsContext));
    node.value = _resolver.popRewrite()!;
    var valueType = node.value.typeOrThrow;
    var whyNotPromoted = flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(node.value),
    );

    var nodeType = _computeIfNullType(
      readType: readType,
      valueType: valueType,
      contextType: contextType,
    );
    node.recordStaticType(nodeType, resolver: _resolver);
    _checkForInvalidAssignment(
      writeAcceptedType,
      node.value,
      valueType,
      whyNotPromoted: whyNotPromoted,
    );

    if (flow == null) return;
    if (variableElement case PromotableElementImpl element) {
      _resolver.flowAnalysis.storeExpressionInfo(
        node,
        flow.write(node, element, SharedTypeView(node.typeOrThrow), null),
      );
    }
    flow.ifNullExpression_end();
  }

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  resolveIndexReadWriteTarget(IndexAssignmentTargetImpl target) {
    _resolver.analyzeExpression(
      target.receiver,
      SharedTypeSchemaView(UnknownInferredType.instance),
      continueNullShorting: true,
    );
    target.receiver = _resolver.popRewrite()!;

    var receiverDoesNotComplete =
        target.receiver is! ExtensionOverrideImpl &&
        identical(
          _typeSystem.resolveToBound(target.receiver.typeOrThrow),
          NeverTypeImpl.instance,
        );
    if (target.question != null && !receiverDoesNotComplete) {
      _resolver.startNullAwareAssignmentTarget(target.receiver);
      _resolver.nullSafetyDeadCodeVerifier.visitNode(target.index);
    }

    var result = _resolver.resolveIndexReadWriteAssignmentTarget(target);
    target.read = result?.read;
    target.write = result?.write;

    _resolver.analyzeExpression(
      target.index,
      SharedTypeSchemaView(
        result?.read.indexContextType ?? UnknownInferredType.instance,
      ),
    );
    target.index = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(target.index),
    );
    var readElement = switch (result?.read) {
      MethodIndexReadResolutionImpl(:var element) => element,
      InvalidIndexReadResolutionImpl(
        recovery: MethodIndexReadResolutionImpl(:var element),
      ) =>
        element,
      _ => null,
    };
    var writeElement = switch (result?.write) {
      MethodIndexWriteResolutionImpl(:var element) => element,
      InvalidIndexWriteResolutionImpl(
        recovery: MethodIndexWriteResolutionImpl(:var element),
      ) =>
        element,
      _ => null,
    };
    _resolver.checkIndexExpressionIndex(
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

    var strictCasts = _resolver.analysisOptions.strictCasts;
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
            _resolver.computeWhyNotPromotedMessages(
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

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _diagnosticReporter.report(diag.useOfVoidResult.at(methodName));
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
    var s = _resolver.operations
        .greatestClosureOfSchema(SharedTypeSchemaView(contextType))
        .unwrapTypeView<TypeImpl>();
    // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
    if (!_resolver.definingLibrary.featureSet.isEnabled(
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

  TypeImpl _computeRhsContext(
    AssignmentExpressionImpl node,
    TypeImpl leftType,
    TokenType operator,
    Expression right,
  ) {
    switch (operator) {
      case TokenType.EQ:
      case TokenType.QUESTION_QUESTION_EQ:
        return leftType;
      case TokenType.AMPERSAND_AMPERSAND_EQ:
      case TokenType.BAR_BAR_EQ:
        return _typeProvider.boolType;
      default:
        var method = node.element;
        if (method != null) {
          var parameters = method.formalParameters;
          if (parameters.isNotEmpty) {
            return _typeSystem.refineNumericInvocationContext(
              leftType,
              method,
              leftType,
              parameters[0].type,
            );
          }
        }
        return UnknownInferredType.instance;
    }
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
    _resolver.analyzeExpression(
      target.expression,
      SharedTypeSchemaView(UnknownInferredType.instance),
    );
    target.expression = _resolver.popRewrite()!;

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
    _resolver.analyzeExpression(node.value, SharedTypeSchemaView(rhsContext));
    node.value = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
      _resolver.flowAnalysis.getExpressionInfo(node.value),
    );

    var operatorResultType = _computeCompoundOperatorResultType(
      node,
      readType: readType,
    );
    node.operatorResultType = operatorResultType;
    node.recordStaticType(operatorResultType, resolver: _resolver);
    _resolver.checkForArgumentTypeNotAssignableForArgument(
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
      _resolver.analyzeExpression(
        target.expression,
        SharedTypeSchemaView(UnknownInferredType.instance),
      );
      target.expression = _resolver.popRewrite()!;
    }

    _resolver.analyzeExpression(
      node.value,
      SharedTypeSchemaView(InvalidTypeImpl.instance),
    );
    node.value = _resolver.popRewrite()!;
    node.recordStaticType(node.value.typeOrThrow, resolver: _resolver);
  }

  void _resolveInvalidIfNull(
    IfNullAssignmentImpl node,
    InvalidExpressionAssignmentTargetImpl target, {
    required TypeImpl contextType,
    bool expressionIsResolved = false,
  }) {
    if (!expressionIsResolved) {
      _resolver.analyzeExpression(
        target.expression,
        SharedTypeSchemaView(UnknownInferredType.instance),
      );
      target.expression = _resolver.popRewrite()!;
    }

    var readType = target.expression.typeOrThrow;
    _resolver.analyzeExpression(
      node.value,
      SharedTypeSchemaView(InvalidTypeImpl.instance),
    );
    node.value = _resolver.popRewrite()!;
    node.recordStaticType(
      _computeIfNullType(
        readType: readType,
        valueType: node.value.typeOrThrow,
        contextType: contextType,
      ),
      resolver: _resolver,
    );
  }

  void _resolveOperator(AssignmentExpressionImpl node) {
    var left = node.leftHandSide2;
    var operator = node.operator;
    var operatorType = operator.type;

    var leftType = node.readType!;
    if (identical(leftType, NeverTypeImpl.instance)) {
      return;
    }

    // Values of the type void cannot be used.
    // Example: `y += 0`, is not allowed.
    if (operatorType != TokenType.EQ) {
      if (leftType is VoidType) {
        _diagnosticReporter.report(diag.useOfVoidResult.at(operator));
        return;
      }
    }

    if (operatorType == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operatorType == TokenType.BAR_BAR_EQ ||
        operatorType == TokenType.EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      return;
    }

    var binaryOperatorType = operatorType.binaryOperatorOfCompoundAssignment;
    if (binaryOperatorType == null) {
      return;
    }
    var methodName = binaryOperatorType.lexeme;

    var result = _typePropertyResolver.resolve(
      receiver: left,
      receiverType: leftType,
      name: methodName,
      hasRead: operatorType != TokenType.EQ,
      hasWrite: true,
      propertyErrorEntity: operator,
      nameErrorEntity: operator,
    );
    node.element = result.getter2 as InternalMethodElement?;
    if (result.needsGetterError) {
      _diagnosticReporter.report(
        diag.undefinedOperator
            .withArguments(operator: methodName, type: leftType)
            .at(operator),
      );
    }
  }

  void _resolveTypes(
    AssignmentExpressionImpl node, {
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
    required TypeImpl contextType,
  }) {
    TypeImpl assignedType;

    var rightHandSide = node.rightHandSide2;
    var operator = node.operator.type;
    if (operator == TokenType.EQ) {
      assignedType = rightHandSide.typeOrThrow;
    } else if (operator == TokenType.QUESTION_QUESTION_EQ) {
      assignedType = rightHandSide.typeOrThrow;
    } else if (operator == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operator == TokenType.BAR_BAR_EQ) {
      assignedType = _typeProvider.boolType;
    } else {
      var leftType = node.readType!;
      var operatorElement = node.element;
      if (leftType is DynamicType) {
        assignedType = DynamicTypeImpl.instance;
      } else if (operatorElement != null) {
        var rightType = rightHandSide.typeOrThrow;
        assignedType = _typeSystem.refineBinaryExpressionType(
          leftType,
          operator,
          rightType,
          operatorElement.returnType,
          operatorElement,
        );
      } else {
        assignedType = InvalidTypeImpl.instance;
      }
    }

    DartType nodeType;
    if (operator == TokenType.QUESTION_QUESTION_EQ) {
      // - An if-null assignment `E` of the form `lvalue ??= e` with context type
      //   `K` is analyzed as follows:
      //
      //   - Let `T1` be the read type the lvalue.
      var t1 = node.readType!;
      //   - Let `T2` be the type of `e` inferred with context type `T1`.
      var t2 = assignedType;
      nodeType = _computeIfNullType(
        readType: t1,
        valueType: t2,
        contextType: contextType,
      );
    } else {
      nodeType = assignedType;
    }
    node.recordStaticType(nodeType, resolver: _resolver);

    // TODO(scheglov): Remove from ErrorVerifier?
    _checkForInvalidAssignment(
      node.writeType!,
      node.rightHandSide2,
      assignedType,
      whyNotPromoted: operator == TokenType.EQ ? whyNotPromoted : null,
    );
    if (operator != TokenType.EQ &&
        operator != TokenType.QUESTION_QUESTION_EQ) {
      _resolver.checkForArgumentTypeNotAssignableForArgument(
        node.rightHandSide2,
        whyNotPromoted: whyNotPromoted,
      );
    }
  }
}

class AssignmentExpressionShared {
  final ResolverVisitor _resolver;

  AssignmentExpressionShared({required ResolverVisitor resolver})
    : _resolver = resolver;

  DiagnosticReporter get _errorReporter => _resolver.diagnosticReporter;

  void checkFinalAlreadyAssigned(
    Expression left, {
    bool isForEachIdentifier = false,
  }) {
    var flowAnalysis = _resolver.flowAnalysis;

    var flow = flowAnalysis.flow;
    if (flow == null) return;

    if (left is SimpleIdentifier) {
      var element = left.element;
      if (element is PromotableElementImpl) {
        _checkFinalAlreadyAssigned(
          left,
          element,
          isForEachIdentifier: isForEachIdentifier,
        );
      }
    }
  }

  void checkFinalForEachIdentifier(ForEachPartsWithIdentifierImpl node) {
    if (_resolver.flowAnalysis.flow == null) return;
    if (node.write case VariableWriteResolutionImpl(
      element: PromotableElementImpl element,
    )) {
      _checkFinalAlreadyAssigned(
        node,
        element,
        isForEachIdentifier: true,
        errorToken: node.identifier2,
      );
    }
  }

  void checkFinalTargetAlreadyAssigned(
    UnqualifiedNameAssignmentTargetImpl target,
  ) {
    if (_resolver.flowAnalysis.flow == null) return;
    var element = target.scopeLookupResult?.getter;
    if (element is PromotableElementImpl) {
      _checkFinalAlreadyAssigned(target, element, isForEachIdentifier: false);
    }
  }

  void _checkFinalAlreadyAssigned(
    AstNode node,
    PromotableElementImpl element, {
    required bool isForEachIdentifier,
    Token? errorToken,
  }) {
    var flowAnalysis = _resolver.flowAnalysis;
    var assigned = flowAnalysis.isDefinitelyAssigned(node, element);
    var unassigned = flowAnalysis.isDefinitelyUnassigned(node, element);

    if (element.isFinal) {
      if (element.isLate) {
        if (isForEachIdentifier || assigned) {
          _errorReporter.report(
            diag.lateFinalLocalAlreadyAssigned.at(errorToken ?? node),
          );
        }
      } else if (isForEachIdentifier || !unassigned) {
        _errorReporter.report(
          diag.assignmentToFinalLocal
              .withArguments(variableName: element.name!)
              .at(errorToken ?? node),
        );
      }
    }
  }
}
