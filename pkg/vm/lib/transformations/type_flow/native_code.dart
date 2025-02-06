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

  /// Artificial call method corresponding to the given [closure].
  Procedure getClosureCallMethod(Closure closure);

  /// Add class which can be extended by a dynamically loaded class
  /// (unknown at compilation time).
  void addDynamicallyExtendableClass(Class c);
}

class PragmaEntryPointsVisitor extends RecursiveVisitor {
  final EntryPointsListener entryPoints;
  final NativeCodeOracle nativeCodeOracle;
  final PragmaAnnotationParser matcher;

  PragmaEntryPointsVisitor(
      this.entryPoints, this.nativeCodeOracle, this.matcher);

  // Returns list of entry point types specified by
  // pragmas in the given annotations.
  List<PragmaEntryPointType> entryPointTypesFromPragmas(
      List<Expression> annotations) {
    List<PragmaEntryPointType>? types;
    for (var annotation in annotations) {
      ParsedPragma? pragma = matcher.parsePragma(annotation);
      if (pragma == null) continue;
      if (pragma is ParsedEntryPointPragma) {
        if (types == null) {
          types = [pragma.type];
        } else {
          // Duplicate entry point types are rare and harmless.
          types.add(pragma.type);
        }
      }
    }
    return types ?? const [];
  }

  static const _referenceToDocumentation =
      "See https://github.com/dart-lang/sdk/blob/master/runtime/docs/compiler/"
      "aot/entry_point_pragma.md.";

  @override
  visitLibrary(Library library) {
    for (final type in entryPointTypesFromPragmas(library.annotations)) {
      if (type == PragmaEntryPointType.Default) {
        nativeCodeOracle.addLibraryReferencedFromNativeCode(library);
      } else {
        throw "Error: The argument to an entry-point pragma annotation "
            "on a library must evaluate to null, true, or false.\n"
            "$_referenceToDocumentation";
      }
    }
    library.visitChildren(this);
  }

  @override
  visitClass(Class klass) {
    for (final type in entryPointTypesFromPragmas(klass.annotations)) {
      if (type == PragmaEntryPointType.Default) {
        if (!klass.isAbstract) {
          entryPoints.addAllocatedClass(klass);
        }
        nativeCodeOracle.addClassReferencedFromNativeCode(klass);
      } else if (type == PragmaEntryPointType.Extendable) {
        entryPoints.addDynamicallyExtendableClass(klass);
        nativeCodeOracle.addClassReferencedFromNativeCode(klass);
      } else {
        throw "Error: The argument to an entry-point pragma annotation "
            "on a class must evaluate to null, true, or false.\n"
            "$_referenceToDocumentation";
      }
    }
    klass.visitChildren(this);
  }

  @override
  visitProcedure(Procedure proc) {
    final types = entryPointTypesFromPragmas(proc.annotations);
    if (types.isEmpty) return;

    void addSelector(CallKind ck) {
      entryPoints.addRawCall(proc.isInstanceMember
          ? new InterfaceSelector(proc, callKind: ck)
          : new DirectSelector(proc, callKind: ck));
    }

    for (final type in types) {
      switch (type) {
        case PragmaEntryPointType.CallOnly:
          if (proc.isGetter) {
            throw "Error: The argument to an entry-point pragma annotation on "
                "a getter ($proc) must evaluate to null, true, false, or "
                "'get'.\n$_referenceToDocumentation";
          }
          if (proc.isSetter) {
            throw "Error: The argument to an entry-point pragma annotation on "
                "a setter ($proc) must evaluate to null, true, false, or "
                "'set'.\n$_referenceToDocumentation";
          }
          addSelector(CallKind.Method);
          break;
        case PragmaEntryPointType.SetterOnly:
          if (!proc.isSetter) {
            throw "Error: cannot generate a setter for a method or getter "
                "($proc).\n$_referenceToDocumentation";
          }
          addSelector(CallKind.PropertySet);
          break;
        case PragmaEntryPointType.GetterOnly:
          if (proc.isSetter) {
            throw "Error: cannot closurize a setter ($proc).\n"
                "$_referenceToDocumentation";
          }
          if (proc.isFactory) {
            throw "Error: cannot closurize a factory ($proc).\n"
                "$_referenceToDocumentation";
          }
          addSelector(CallKind.PropertyGet);
          break;
        case PragmaEntryPointType.Default:
          if (proc.isGetter) {
            addSelector(CallKind.PropertyGet);
          } else if (proc.isSetter) {
            addSelector(CallKind.PropertySet);
          } else {
            addSelector(CallKind.Method);
            if (!proc.isFactory) {
              addSelector(CallKind.PropertyGet);
            }
          }
          break;
        case PragmaEntryPointType.Extendable:
          throw "Error: only class can be extendable";
        case PragmaEntryPointType.CanBeOverridden:
          nativeCodeOracle.addDynamicallyOverriddenMember(proc);
          break;
      }
    }

    nativeCodeOracle.setMemberReferencedFromNativeCode(proc);
  }

  @override
  visitConstructor(Constructor ctor) {
    for (final type in entryPointTypesFromPragmas(ctor.annotations)) {
      if (type != PragmaEntryPointType.Default &&
          type != PragmaEntryPointType.CallOnly) {
        throw "Error: The argument to an entry-point pragma annotation on a "
            "constructor ($ctor) must evaluate to null, true, false or "
            "'call'.\n$_referenceToDocumentation";
      }
      entryPoints
          .addRawCall(new DirectSelector(ctor, callKind: CallKind.Method));
      entryPoints.addAllocatedClass(ctor.enclosingClass);
      nativeCodeOracle.setMemberReferencedFromNativeCode(ctor);
    }
  }

  @override
  visitField(Field field) {
    final types = entryPointTypesFromPragmas(field.annotations);
    if (types.isEmpty) return;

    void addSelector(CallKind ck) {
      entryPoints.addRawCall(field.isInstanceMember
          ? new InterfaceSelector(field, callKind: ck)
          : new DirectSelector(field, callKind: ck));
    }

    for (final type in types) {
      switch (type) {
        case PragmaEntryPointType.GetterOnly:
          addSelector(CallKind.PropertyGet);
          break;
        case PragmaEntryPointType.SetterOnly:
          if (!field.hasSetter) {
            throw "Error: can't use 'set' in an entry-point pragma annotation "
                "for a field that has no setter ($field).\n"
                "$_referenceToDocumentation";
          }
          addSelector(CallKind.PropertySet);
          break;
        case PragmaEntryPointType.Default:
          addSelector(CallKind.PropertyGet);
          if (field.hasSetter) {
            addSelector(CallKind.PropertySet);
          }
          break;
        case PragmaEntryPointType.CallOnly:
          throw "Error: 'call' is not a valid entry-point pragma annotation "
              "argument for the field $field.\n$_referenceToDocumentation";
        case PragmaEntryPointType.Extendable:
          throw "Error: only class can be extendable";
        case PragmaEntryPointType.CanBeOverridden:
          nativeCodeOracle.addDynamicallyOverriddenMember(field);
          break;
      }
    }

    nativeCodeOracle.setMemberReferencedFromNativeCode(field);
  }
}

/// Provides insights into the behavior of native code.
class NativeCodeOracle {
  final LibraryIndex _libraryIndex;
  final Set<Member> _membersReferencedFromNativeCode = new Set<Member>();
  final Set<Member> _dynamicallyOverriddenMembers = new Set<Member>();
  final Set<Class> _classesReferencedFromNativeCode = new Set<Class>();
  final Set<Library> _librariesReferencedFromNativeCode = new Set<Library>();
  final PragmaAnnotationParser _matcher;

  NativeCodeOracle(this._libraryIndex, this._matcher);

  void addLibraryReferencedFromNativeCode(Library library) {
    _librariesReferencedFromNativeCode.add(library);
  }

  bool isLibraryReferencedFromNativeCode(Library library) =>
      _librariesReferencedFromNativeCode.contains(library);

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

  void addDynamicallyOverriddenMember(Member member) {
    _dynamicallyOverriddenMembers.add(member);
  }

  bool isDynamicallyOverriddenMember(Member member) =>
      _dynamicallyOverriddenMembers.contains(member);

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

    for (var annotation in member.annotations) {
      ParsedPragma? pragma = _matcher.parsePragma(annotation);
      if (pragma == null) continue;
      if (pragma is ParsedResultTypeByTypePragma ||
          pragma is ParsedResultTypeByPathPragma) {
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
                    .map((t) => TypeParameterType.withDefaultNullability(t))
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
      }
    }

    if (returnType != null) {
      return returnType;
    } else {
      return typesBuilder.fromStaticType(member.function!.returnType, true);
    }
  }
}
