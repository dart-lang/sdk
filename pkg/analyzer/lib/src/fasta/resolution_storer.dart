// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

class ResolutionData<Type, Declaration, Reference, PrefixInfo> {
  final List<Type> argumentTypes;
  final Reference combiner;
  final Declaration declaration;
  final Type inferredType;
  final Type invokeType;
  final bool isExplicitCall;
  final bool isImplicitCall;
  final bool isWriteReference;
  final Type literalType;
  final PrefixInfo prefixInfo;
  final Reference reference;
  final Type writeContext;

  ResolutionData(
      {this.argumentTypes,
      this.combiner,
      this.declaration,
      this.inferredType,
      this.invokeType,
      this.isExplicitCall = false,
      this.isImplicitCall = false,
      this.isWriteReference = false,
      this.literalType,
      this.prefixInfo,
      this.reference,
      this.writeContext});
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer<Location, Declaration, Reference, PrefixInfo>
    extends TypeInferenceListener<Location, Declaration, Reference,
        PrefixInfo> {
  final Map<Location,
      ResolutionData<DartType, Declaration, Reference, PrefixInfo>> _data;

  final _stack = <Function>[];

  ResolutionStorer(this._data);

  void _store(Location location,
      {List<DartType> argumentTypes,
      Reference combiner,
      Declaration declaration,
      DartType inferredType,
      DartType invokeType,
      bool isExplicitCall = false,
      bool isImplicitCall = false,
      bool isWriteReference = false,
      DartType literalType,
      PrefixInfo prefixInfo,
      Reference reference,
      bool replace = false,
      DartType writeContext}) {
    if (!replace && _data.containsKey(location)) {
      throw new StateError('Data already stored for offset $location');
    }
    _data[location] = new ResolutionData(
        argumentTypes: argumentTypes,
        combiner: combiner,
        declaration: declaration,
        inferredType: inferredType,
        invokeType: invokeType,
        isExplicitCall: isExplicitCall,
        isImplicitCall: isImplicitCall,
        isWriteReference: isWriteReference,
        literalType: literalType,
        prefixInfo: prefixInfo,
        reference: reference,
        writeContext: writeContext);
  }

  void _unstore(Location location) {
    _data.remove(location) == null;
  }

  @override
  void asExpressionExit(Location location, DartType inferredType) {
    _store(location, literalType: inferredType, inferredType: inferredType);
  }

  @override
  void cascadeExpressionExit(Location location, DartType inferredType) {
    // Overridden so that the type of the expression will not be recorded. We
    // don't need to record the type because the type is always the same as the
    // type of the target, and we don't have the appropriate offset so we can't
    // correctly apply the type even if we recorded it.
  }

  @override
  void catchStatementEnter(
      Location location,
      DartType guardType,
      Location exceptionLocation,
      DartType exceptionType,
      Location stackTraceLocation,
      DartType stackTraceType) {
    _store(location, literalType: guardType);

    if (exceptionLocation != null) {
      _store(exceptionLocation, literalType: exceptionType);
    }

    if (stackTraceLocation != null) {
      _store(stackTraceLocation, literalType: stackTraceType);
    }
  }

  @override
  void constructorInvocationEnter(Location location, DartType typeContext) {
    _push((Reference expressionTarget, DartType inferredType) {
      // A class reference may have already been stored at this location by
      // storeClassReference.  We want to replace it with a constructor
      // reference.
      _unstore(location);
      _store(location, inferredType: inferredType, reference: expressionTarget);
    });
  }

  @override
  void constructorInvocationExit(
      Location location, Reference expressionTarget, DartType inferredType) {
    _pop()(expressionTarget, inferredType);
  }

  @override
  void fieldInitializerEnter(Location location, Reference initializerField) {
    _store(location, reference: initializerField);
  }

  void finished() {
    assert(_stack.isEmpty);
  }

  @override
  void forInStatementEnter(
      Location location,
      Location variableLocation,
      Location writeLocation,
      DartType writeType,
      Declaration writeVariable,
      Reference writeTarget) {
    _push((DartType variableType) {
      if (variableLocation != null) {
        _store(variableLocation, inferredType: variableType);
      } else {
        if (writeVariable != null) {
          _store(writeLocation,
              declaration: writeVariable, inferredType: writeType);
        } else {
          _store(writeLocation,
              reference: writeTarget,
              isWriteReference: true,
              writeContext: writeType);
        }
      }
    });
  }

  @override
  void forInStatementExit(
      Location location, bool variablePresent, DartType variableType) {
    _pop()(variableType);
  }

  @override
  void genericExpressionEnter(
      String expressionType, Location location, DartType typeContext) {
    super.genericExpressionEnter(expressionType, location, typeContext);
  }

  @override
  void genericExpressionExit(
      String expressionType, Location location, DartType inferredType) {
    _store(location, inferredType: inferredType);
    super.genericExpressionExit(expressionType, location, inferredType);
  }

  @override
  void functionDeclarationExit(Location location, FunctionType inferredType) {
    _store(location, inferredType: inferredType);
  }

  @override
  void nullLiteralExit(
      Location location, bool isSynthetic, DartType inferredType) {
    if (isSynthetic) return null;
    super.nullLiteralExit(location, isSynthetic, inferredType);
  }

  @override
  void indexAssignExit(Location location, Reference writeMember,
      Reference combiner, DartType inferredType) {
    _store(location,
        reference: writeMember, inferredType: inferredType, combiner: combiner);
  }

  @override
  void isExpressionExit(
      Location location, DartType testedType, DartType inferredType) {
    _store(location, literalType: testedType, inferredType: inferredType);
  }

  void isNotExpressionExit(
      Location location, DartType type, DartType inferredType) {
    _store(location, literalType: type, inferredType: inferredType);
  }

  @override
  void methodInvocationExit(
      Location resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Reference interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);

    _store(resultOffset,
        inferredType: inferredType,
        argumentTypes: argumentsTypes,
        invokeType: invokeType,
        isImplicitCall: isImplicitCall,
        reference: interfaceMember);

    super.genericExpressionExit("methodInvocation", resultOffset, inferredType);
  }

  @override
  void methodInvocationExitCall(
      Location resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);

    _store(resultOffset,
        inferredType: inferredType,
        argumentTypes: argumentsTypes,
        invokeType: invokeType,
        isImplicitCall: isImplicitCall);

    super.genericExpressionExit("methodInvocation", resultOffset, inferredType);
  }

  @override
  void propertyAssignExit(Location location, Reference writeMember,
      DartType writeContext, Reference combiner, DartType inferredType) {
    _store(location,
        isWriteReference: true,
        reference: writeMember,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  @override
  void propertyGetExit(
      Location location, Reference member, DartType inferredType) {
    _store(location, reference: member, inferredType: inferredType);
  }

  @override
  void propertyGetExitCall(Location location, DartType inferredType) {
    _store(location, isExplicitCall: true);
  }

  @override
  void redirectingInitializerEnter(
      Location location, Reference initializerTarget) {
    _store(location, reference: initializerTarget);
  }

  @override
  void staticAssignEnter(Location location, DartType typeContext) {
    _push((Reference writeMember, DartType writeContext, Reference combiner,
        DartType inferredType) {
      _store(location,
          reference: writeMember,
          isWriteReference: true,
          writeContext: writeContext,
          combiner: combiner,
          inferredType: inferredType);
    });
  }

  @override
  void staticAssignExit(Location location, Reference writeMember,
      DartType writeContext, Reference combiner, DartType inferredType) {
    _pop()(writeMember, writeContext, combiner, inferredType);
  }

  @override
  void staticGetEnter(Location location, DartType typeContext) {
    _push(
        (Location location, Reference expressionTarget, DartType inferredType) {
      _store(location, reference: expressionTarget, inferredType: inferredType);
    });
  }

  @override
  void staticGetExit(
      Location location, Reference expressionTarget, DartType inferredType) {
    _pop()(location, expressionTarget, inferredType);
  }

  @override
  void staticInvocationEnter(Location location,
      Location expressionArgumentsLocation, DartType typeContext) {
    _push((Reference expressionTarget,
        List<DartType> expressionArgumentsTypes,
        FunctionType calleeType,
        Substitution substitution,
        DartType inferredType) {
      FunctionType invokeType = substitution == null
          ? calleeType
          : substitution.substituteType(calleeType.withoutTypeParameters);
      _store(expressionArgumentsLocation,
          invokeType: invokeType,
          argumentTypes: expressionArgumentsTypes,
          reference: expressionTarget,
          inferredType: inferredType);
    });
  }

  @override
  void staticInvocationExit(
      Location location,
      Reference expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    _pop()(expressionTarget, expressionArgumentsTypes, calleeType, substitution,
        inferredType);
  }

  @override
  void stringConcatenationExit(Location location, DartType inferredType) {
    // We don't need the type - we already know that it is String.
    // Moreover, the file offset for StringConcatenation is `-1`.
  }

  @override
  void thisExpressionExit(Location location, DartType inferredType) {}

  @override
  void typeLiteralEnter(Location location, DartType typeContext) {
    _push((Reference expressionType, DartType inferredType) {
      _store(location, reference: expressionType, inferredType: inferredType);
    });
  }

  void typeLiteralExit(
      Location location, Reference expressionType, DartType inferredType) {
    _pop()(expressionType, inferredType);
  }

  @override
  void variableAssignExit(Location location, DartType writeContext,
      Declaration writeVariable, Reference combiner, DartType inferredType) {
    _store(location,
        declaration: writeVariable,
        isWriteReference: true,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  @override
  void variableDeclarationExit(
      Location location, DartType statementType, DartType inferredType) {
    _store(location, literalType: statementType, inferredType: inferredType);
  }

  @override
  void variableGetExit(Location location, bool isInCascade,
      Declaration expressionVariable, DartType inferredType) {
    if (isInCascade) {
      return;
    }
    _store(location,
        declaration: expressionVariable, inferredType: inferredType);
  }

  void _push(Function f) {
    _stack.add(f);
  }

  Function _pop() {
    return _stack.removeLast();
  }

  @override
  void storePrefixInfo(Location location, PrefixInfo prefixInfo) {
    _store(location, prefixInfo: prefixInfo);
  }

  @override
  void storeClassReference(
      Location location, Reference reference, DartType rawType) {
    // TODO(paulberry): would it be better to use literalType?
    _store(location, reference: reference, inferredType: rawType);
  }
}

/// A [DartType] wrapper around invocation type arguments.
class TypeArgumentsDartType implements DartType {
  final List<DartType> types;

  TypeArgumentsDartType(this.types);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '<${types.join(', ')}>';
  }
}
