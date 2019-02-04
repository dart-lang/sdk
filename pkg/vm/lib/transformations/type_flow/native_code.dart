// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Handling of native code and entry points.
library vm.transformations.type_flow.native_code;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;

import 'calls.dart';
import 'types.dart';
import 'utils.dart';
import '../pragma.dart';

abstract class EntryPointsListener {
  /// Add call by the given selector with arbitrary ('raw') arguments.
  void addRawCall(Selector selector);

  /// Sets the type of the given field.
  void addDirectFieldAccess(Field field, Type value);

  /// Add instantiation of the given class.
  ConcreteType addAllocatedClass(Class c);

  /// Record the fact that given member is called via interface selector
  /// (not dynamically, and not from `this`).
  void recordMemberCalledViaInterfaceSelector(Member target);

  /// Record the fact that given member is called from this.
  void recordMemberCalledViaThis(Member target);
}

class PragmaEntryPointsVisitor extends RecursiveVisitor {
  final EntryPointsListener entryPoints;
  final NativeCodeOracle nativeCodeOracle;
  final PragmaAnnotationParser matcher;
  Class currentClass = null;

  PragmaEntryPointsVisitor(
      this.entryPoints, this.nativeCodeOracle, this.matcher) {
    assertx(matcher != null);
  }

  PragmaEntryPointType _annotationsDefineRoot(List<Expression> annotations) {
    for (var annotation in annotations) {
      ParsedPragma pragma = matcher.parsePragma(annotation);
      if (pragma == null) continue;
      if (pragma is ParsedEntryPointPragma) return pragma.type;
    }
    return null;
  }

  @override
  visitClass(Class klass) {
    if (!klass.isAbstract) {
      var type = _annotationsDefineRoot(klass.annotations);
      if (type != null) {
        if (type != PragmaEntryPointType.Always) {
          throw "Error: pragma entry-point definition on a class must evaluate "
              "to null, true or false. See entry_points_pragma.md.";
        }
        entryPoints.addAllocatedClass(klass);
      }
    }
    currentClass = klass;
    klass.visitChildren(this);
  }

  @override
  visitProcedure(Procedure proc) {
    var type = _annotationsDefineRoot(proc.annotations);
    if (type != null) {
      if (type != PragmaEntryPointType.Always) {
        throw "Error: pragma entry-point definition on a procedure (including"
            "getters and setters) must evaluate to null, true or false. "
            "See entry_points_pragma.md.";
      }
      var callKind = proc.isGetter
          ? CallKind.PropertyGet
          : (proc.isSetter ? CallKind.PropertySet : CallKind.Method);
      entryPoints.addRawCall(proc.isInstanceMember
          ? new InterfaceSelector(proc, callKind: callKind)
          : new DirectSelector(proc, callKind: callKind));
      nativeCodeOracle.setMemberReferencedFromNativeCode(proc);
    }
  }

  @override
  visitConstructor(Constructor ctor) {
    var type = _annotationsDefineRoot(ctor.annotations);
    if (type != null) {
      if (type != PragmaEntryPointType.Always) {
        throw "Error: pragma entry-point definition on a constructor must "
            "evaluate to null, true or false. See entry_points_pragma.md.";
      }
      entryPoints
          .addRawCall(new DirectSelector(ctor, callKind: CallKind.Method));
      entryPoints.addAllocatedClass(currentClass);
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
      case PragmaEntryPointType.Always:
        addSelector(CallKind.PropertyGet);
        if (!field.isFinal) {
          addSelector(CallKind.PropertySet);
        }
        break;
    }

    nativeCodeOracle.setMemberReferencedFromNativeCode(field);
  }
}

/// Provides insights into the behavior of native code.
class NativeCodeOracle {
  final LibraryIndex _libraryIndex;
  final Set<Member> _membersReferencedFromNativeCode = new Set<Member>();
  final PragmaAnnotationParser _matcher;

  NativeCodeOracle(this._libraryIndex, this._matcher) {
    assertx(_matcher != null);
  }

  void setMemberReferencedFromNativeCode(Member member) {
    _membersReferencedFromNativeCode.add(member);
  }

  bool isMemberReferencedFromNativeCode(Member member) =>
      _membersReferencedFromNativeCode.contains(member);

  /// Simulate the execution of a native method by adding its entry points
  /// using [entryPointsListener]. Returns result type of the native method.
  Type handleNativeProcedure(
      Member member, EntryPointsListener entryPointsListener) {
    Type returnType = null;
    bool nullable = null;

    for (var annotation in member.annotations) {
      ParsedPragma pragma = _matcher.parsePragma(annotation);
      if (pragma == null) continue;
      if (pragma is ParsedResultTypeByTypePragma ||
          pragma is ParsedResultTypeByPathPragma ||
          pragma is ParsedNonNullableResultType) {
        // We can only use the 'vm:exact-result-type' pragma on methods in core
        // libraries for safety reasons. See 'result_type_pragma.md', detail 1.2
        // for explanation.
        if (member.enclosingLibrary.importUri.scheme != "dart") {
          throw "ERROR: Cannot use $kExactResultTypePragmaName "
              "outside core libraries.";
        }
      }
      if (pragma is ParsedResultTypeByTypePragma) {
        var type = pragma.type;
        if (type is InterfaceType) {
          returnType = entryPointsListener.addAllocatedClass(type.classNode);
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
      throw 'ERROR: Cannot have both, @pragma("$kExactResultTypePragmaName") '
          'and @pragma("$kNonNullableResultType"), annotating the same member.';
    }

    if (returnType != null) {
      return returnType;
    } else {
      final coneType = new Type.cone(member.function.returnType);
      return nullable == false ? coneType : new Type.nullable(coneType);
    }
  }
}
