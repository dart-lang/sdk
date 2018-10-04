// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Handling of native code and entry points.
library vm.transformations.type_flow.native_code;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;

import 'calls.dart';
import 'types.dart';
import 'utils.dart';

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

abstract class ParsedPragma {}

enum PragmaEntryPointType { Always, GetterOnly, SetterOnly }

class ParsedEntryPointPragma extends ParsedPragma {
  final PragmaEntryPointType type;
  ParsedEntryPointPragma(this.type);
}

class ParsedResultTypeByTypePragma extends ParsedPragma {
  final DartType type;
  ParsedResultTypeByTypePragma(this.type);
}

class ParsedResultTypeByPathPragma extends ParsedPragma {
  final String path;
  ParsedResultTypeByPathPragma(this.path);
}

const kEntryPointPragmaName = "vm:entry-point";
const kExactResultTypePragmaName = "vm:exact-result-type";

abstract class PragmaAnnotationParser {
  /// May return 'null' if the annotation does not represent a recognized
  /// @pragma.
  ParsedPragma parsePragma(Expression annotation);
}

class ConstantPragmaAnnotationParser extends PragmaAnnotationParser {
  final CoreTypes coreTypes;

  ConstantPragmaAnnotationParser(this.coreTypes);

  ParsedPragma parsePragma(Expression annotation) {
    InstanceConstant pragmaConstant;
    if (annotation is ConstantExpression) {
      Constant constant = annotation.constant;
      if (constant is InstanceConstant) {
        if (constant.classReference.node == coreTypes.pragmaClass) {
          pragmaConstant = constant;
        }
      }
    }
    if (pragmaConstant == null) return null;

    String pragmaName;
    Constant name = pragmaConstant.fieldValues[coreTypes.pragmaName.reference];
    if (name is StringConstant) {
      pragmaName = name.value;
    } else {
      return null;
    }

    Constant options =
        pragmaConstant.fieldValues[coreTypes.pragmaOptions.reference];
    assertx(options != null);

    switch (pragmaName) {
      case kEntryPointPragmaName:
        PragmaEntryPointType type;
        if (options is NullConstant) {
          type = PragmaEntryPointType.Always;
        } else if (options is BoolConstant && options.value == true) {
          type = PragmaEntryPointType.Always;
        } else if (options is StringConstant) {
          if (options.value == "get") {
            type = PragmaEntryPointType.GetterOnly;
          } else if (options.value == "set") {
            type = PragmaEntryPointType.SetterOnly;
          } else {
            throw "Error: string directive to @pragma('$kEntryPointPragmaName', ...) "
                "must be either 'get' or 'set'.";
          }
        }
        return type != null ? new ParsedEntryPointPragma(type) : null;
      case kExactResultTypePragmaName:
        if (options == null) return null;
        if (options is TypeLiteralConstant) {
          return new ParsedResultTypeByTypePragma(options.type);
        } else if (options is StringConstant) {
          return new ParsedResultTypeByPathPragma(options.value);
        }
        throw "ERROR: Unsupported option to '$kExactResultTypePragmaName' "
            "pragma: $options";
      default:
        return null;
    }
  }
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
    var type = _annotationsDefineRoot(klass.annotations);
    if (type != null) {
      if (type != PragmaEntryPointType.Always) {
        throw "Error: pragma entry-point definition on a class must evaluate "
            "to null, true or false. See entry_points_pragma.md.";
      }
      entryPoints.addAllocatedClass(klass);
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

    for (var annotation in member.annotations) {
      ParsedPragma pragma = _matcher.parsePragma(annotation);
      if (pragma == null) continue;
      if (pragma is ParsedResultTypeByTypePragma ||
          pragma is ParsedResultTypeByPathPragma) {
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
          break;
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
        break;
      }
    }

    if (returnType != null) {
      return returnType;
    } else {
      return new Type.fromStatic(member.function.returnType);
    }
  }
}
