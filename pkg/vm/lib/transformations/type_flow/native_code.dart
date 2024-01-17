// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Handling of native code and entry points.
library;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;

import 'calls.dart';
import 'types.dart';
import '../pragma.dart';

abstract class EntryPointsListener {
  /// Add call by the given selector with arbitrary ('raw') arguments.
  void addRawCall(Selector selector);

  /// Sets the type of the given field.
  void addFieldUsedInConstant(Field field, Type instance, Type value);

  /// Add instantiation of the given class.
  ConcreteType addAllocatedClass(Class c);

  /// Returns Field representing positional field of a record with given shape.
  Field getRecordPositionalField(RecordShape shape, int pos);

  /// Returns Field representing named field of a record with given shape.
  Field getRecordNamedField(RecordShape shape, String name);

  /// Record the fact that given member is called via interface selector
  /// (not dynamically, and not from `this`).
  void recordMemberCalledViaInterfaceSelector(Member target);

  /// Record the fact that given member is called from this.
  void recordMemberCalledViaThis(Member target);

  /// Record the fact that given member is torn off.
  void recordTearOff(Member target) {}
}

class PragmaEntryPointsVisitor extends RecursiveVisitor {
  final EntryPointsListener entryPoints;
  final NativeCodeOracle nativeCodeOracle;
  final PragmaAnnotationParser matcher;

  PragmaEntryPointsVisitor(
      this.entryPoints, this.nativeCodeOracle, this.matcher);

  PragmaEntryPointType? _annotationsDefineRoot(List<Expression> annotations) {
    for (var annotation in annotations) {
      ParsedPragma? pragma = matcher.parsePragma(annotation);
      if (pragma == null) continue;
      if (pragma is ParsedEntryPointPragma) return pragma.type;
    }
    return null;
  }

  @override
  visitClass(Class klass) {
    final type = _annotationsDefineRoot(klass.annotations);
    if (type != null) {
      if (type != PragmaEntryPointType.Default) {
        throw "Error: pragma entry-point definition on a class must evaluate "
            "to null, true or false. See entry_points_pragma.md.";
      }
      if (!klass.isAbstract) {
        entryPoints.addAllocatedClass(klass);
      }
      nativeCodeOracle.addClassReferencedFromNativeCode(klass);
    }
    klass.visitChildren(this);
  }

  @override
  visitProcedure(Procedure proc) {
    var type = _annotationsDefineRoot(proc.annotations);
    if (type == null) return;

    void addSelector(CallKind ck) {
      entryPoints.addRawCall(proc.isInstanceMember
          ? new InterfaceSelector(proc, callKind: ck)
          : new DirectSelector(proc, callKind: ck));
    }

    final defaultCallKind = proc.isGetter
        ? CallKind.PropertyGet
        : (proc.isSetter ? CallKind.PropertySet : CallKind.Method);

    switch (type) {
      case PragmaEntryPointType.CallOnly:
        addSelector(defaultCallKind);
        break;
      case PragmaEntryPointType.SetterOnly:
        if (!proc.isSetter) {
          throw "Error: cannot generate a setter for a method or getter ($proc).";
        }
        addSelector(CallKind.PropertySet);
        break;
      case PragmaEntryPointType.GetterOnly:
        if (proc.isSetter) {
          throw "Error: cannot closurize a setter ($proc).";
        }
        if (proc.isFactory) {
          throw "Error: cannot closurize a factory ($proc).";
        }
        addSelector(CallKind.PropertyGet);
        break;
      case PragmaEntryPointType.Default:
        addSelector(defaultCallKind);
        if (!proc.isSetter && !proc.isGetter && !proc.isFactory) {
          addSelector(CallKind.PropertyGet);
        }
    }

    nativeCodeOracle.setMemberReferencedFromNativeCode(proc);
  }

  @override
  visitConstructor(Constructor ctor) {
    var type = _annotationsDefineRoot(ctor.annotations);
    if (type != null) {
      if (type != PragmaEntryPointType.Default &&
          type != PragmaEntryPointType.CallOnly) {
        throw "Error: pragma entry-point definition on a constructor ($ctor) must"
            "evaluate to null, true, false or 'call'. See entry_points_pragma.md.";
      }
      entryPoints
          .addRawCall(new DirectSelector(ctor, callKind: CallKind.Method));
      entryPoints.addAllocatedClass(ctor.enclosingClass);
      nativeCodeOracle.setMemberReferencedFromNativeCode(ctor);
    }
  }

  @override
  visitField(Field field) {
    var type = _annotationsDefineRoot(field.annotations);
    if (type == null) return;

    void addSelector(CallKind ck) {
      entryPoints.addRawCall(field.isInstanceMember
          ? new InterfaceSelector(field, callKind: ck)
          : new DirectSelector(field, callKind: ck));
    }

    switch (type) {
      case PragmaEntryPointType.GetterOnly:
        addSelector(CallKind.PropertyGet);
        break;
      case PragmaEntryPointType.SetterOnly:
        if (field.isFinal) {
          throw "Error: can't use 'set' in entry-point pragma for final field "
              "$field";
        }
        addSelector(CallKind.PropertySet);
        break;
      case PragmaEntryPointType.Default:
        addSelector(CallKind.PropertyGet);
        if (!field.isFinal) {
          addSelector(CallKind.PropertySet);
        }
        break;
      case PragmaEntryPointType.CallOnly:
        throw "Error: can't generate invocation dispatcher for field $field"
            "through @pragma('vm:entry-point')";
    }

    nativeCodeOracle.setMemberReferencedFromNativeCode(field);
  }
}

/// Provides insights into the behavior of native code.
class NativeCodeOracle {
  final LibraryIndex _libraryIndex;
  final Set<Member> _membersReferencedFromNativeCode = new Set<Member>();
  final Set<Class> _classesReferencedFromNativeCode = new Set<Class>();
  final PragmaAnnotationParser _matcher;

  NativeCodeOracle(this._libraryIndex, this._matcher);

  void addClassReferencedFromNativeCode(Class klass) {
    _classesReferencedFromNativeCode.add(klass);
  }

  bool isClassReferencedFromNativeCode(Class klass) =>
      _classesReferencedFromNativeCode.contains(klass);

  void setMemberReferencedFromNativeCode(Member member) {
    _membersReferencedFromNativeCode.add(member);
  }

  bool isMemberReferencedFromNativeCode(Member member) =>
      _membersReferencedFromNativeCode.contains(member);

  PragmaRecognizedType? recognizedType(Member member) {
    for (var annotation in member.annotations) {
      ParsedPragma? pragma = _matcher.parsePragma(annotation);
      if (pragma is ParsedRecognized) {
        return pragma.type;
      }
    }
    return null;
  }

  bool isRecognized(Member member,
      [List<PragmaRecognizedType>? expectedTypes]) {
    PragmaRecognizedType? type = recognizedType(member);
    return type != null &&
        (expectedTypes == null || expectedTypes.contains(type));
  }

  bool hasDisableUnboxedParameters(Member member) {
    for (var annotation in member.annotations) {
      ParsedPragma? pragma = _matcher.parsePragma(annotation);
      if (pragma is ParsedDisableUnboxedParameters) {
        if (!member.enclosingLibrary.importUri.isScheme("dart")) {
          throw "ERROR: Cannot use @pragma(vm:disable-unboxed-parameters) outside core libraries.";
        }
        return true;
      }
    }
    return false;
  }

  /// Simulate the execution of a native method by adding its entry points
  /// using [entryPointsListener]. Returns result type of the native method.
  TypeExpr handleNativeProcedure(
      Member member,
      EntryPointsListener entryPointsListener,
      TypesBuilder typesBuilder,
      RuntimeTypeTranslator translator) {
    TypeExpr? returnType = null;
    bool? nullable = null;

    for (var annotation in member.annotations) {
      ParsedPragma? pragma = _matcher.parsePragma(annotation);
      if (pragma == null) continue;
      if (pragma is ParsedResultTypeByTypePragma ||
          pragma is ParsedResultTypeByPathPragma ||
          pragma is ParsedNonNullableResultType) {
        // We can only use the 'vm:exact-result-type' pragma on methods in core
        // libraries for safety reasons. See 'result_type_pragma.md', detail 1.2
        // for explanation.
        if (!member.enclosingLibrary.importUri.isScheme("dart")) {
          throw "ERROR: Cannot use $kVmExactResultTypePragmaName "
              "outside core libraries.";
        }
      }
      if (pragma is ParsedResultTypeByTypePragma) {
        var type = pragma.type;
        if (type is InterfaceType) {
          returnType = entryPointsListener.addAllocatedClass(type.classNode);
          if (pragma.resultTypeUsesPassedTypeArguments) {
            returnType = translator.instantiateConcreteType(
                returnType as ConcreteType,
                member.function!.typeParameters
                    .map((t) => TypeParameterType(
                        t, TypeParameterType.computeNullabilityFromBound(t)))
                    .toList());
          }
          continue;
        }
        throw "ERROR: Invalid return type for native method: ${pragma.type}";
      } else if (pragma is ParsedResultTypeByPathPragma) {
        List<String> parts = pragma.path.split("#");
        if (parts.length != 2) {
          throw "ERROR: Could not parse native method return type: ${pragma.path}";
        }

        String libName = parts[0];
        String klassName = parts[1];

        // Error is thrown on the next line if the class is not found.
        Class klass = _libraryIndex.getClass(libName, klassName);
        Type concreteClass = entryPointsListener.addAllocatedClass(klass);
        returnType = concreteClass;
      } else if (pragma is ParsedNonNullableResultType) {
        nullable = false;
      }
    }

    if (returnType != null && nullable != null) {
      throw 'ERROR: Cannot have both, @pragma("$kVmExactResultTypePragmaName") '
          'and @pragma("$kVmNonNullableResultType"), '
          'annotating the same member.';
    }

    if (returnType != null) {
      return returnType;
    } else {
      return typesBuilder.fromStaticType(
          member.function!.returnType, nullable ?? true);
    }
  }
}
