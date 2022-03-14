// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/dispatch_table.dart';
import 'package:dart2wasm/reference_extensions.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// This class is responsible for collecting import and export annotations.
/// It also creates Wasm functions for Dart members and manages the worklist
/// used to achieve tree shaking.
class FunctionCollector extends MemberVisitor1<w.FunctionType, Reference> {
  final Translator translator;

  // Wasm function for each Dart function
  final Map<Reference, w.BaseFunction> _functions = {};
  // Names of exported functions
  final Map<Reference, String> exports = {};
  // Functions for which code has not yet been generated
  final List<Reference> worklist = [];
  // Class IDs for classes that are allocated somewhere in the program
  final Set<int> _allocatedClasses = {};
  // For each class ID, which functions should be added to the worklist if an
  // allocation of that class is encountered
  final Map<int, List<Reference>> _pendingAllocation = {};

  FunctionCollector(this.translator);

  w.Module get m => translator.m;

  void collectImportsAndExports() {
    for (Library library in translator.libraries) {
      for (Procedure procedure in library.procedures) {
        _importOrExport(procedure);
      }
      for (Class cls in library.classes) {
        for (Procedure procedure in cls.procedures) {
          _importOrExport(procedure);
        }
      }
    }
  }

  void _importOrExport(Procedure procedure) {
    String? importName = translator.getPragma(procedure, "wasm:import");
    if (importName != null) {
      int dot = importName.indexOf('.');
      if (dot != -1) {
        assert(!procedure.isInstanceMember);
        String module = importName.substring(0, dot);
        String name = importName.substring(dot + 1);
        w.FunctionType ftype = _makeFunctionType(
            procedure.reference, procedure.function.returnType, null,
            isImportOrExport: true);
        _functions[procedure.reference] =
            m.importFunction(module, name, ftype, "$importName (import)");
      }
    }
    String? exportName =
        translator.getPragma(procedure, "wasm:export", procedure.name.text);
    if (exportName != null) {
      addExport(procedure.reference, exportName);
    }
  }

  void addExport(Reference target, String exportName) {
    exports[target] = exportName;
  }

  void initialize() {
    // Add all exports to the worklist
    for (Reference target in exports.keys) {
      worklist.add(target);
      Procedure node = target.asProcedure;
      assert(!node.isInstanceMember);
      assert(!node.isGetter);
      w.FunctionType ftype = _makeFunctionType(
          target, node.function.returnType, null,
          isImportOrExport: true);
      _functions[target] = m.addFunction(ftype, "$node");
    }

    // Value classes are always implicitly allocated.
    allocateClass(translator.classInfo[translator.boxedBoolClass]!.classId);
    allocateClass(translator.classInfo[translator.boxedIntClass]!.classId);
    allocateClass(translator.classInfo[translator.boxedDoubleClass]!.classId);
  }

  w.BaseFunction? getExistingFunction(Reference target) {
    return _functions[target];
  }

  w.BaseFunction getFunction(Reference target) {
    return _functions.putIfAbsent(target, () {
      worklist.add(target);
      w.FunctionType ftype = target.isTearOffReference
          ? translator.dispatchTable.selectorForTarget(target).signature
          : target.asMember.accept1(this, target);
      return m.addFunction(ftype, "${target.asMember}");
    });
  }

  void activateSelector(SelectorInfo selector) {
    selector.targets.forEach((classId, target) {
      if (!target.asMember.isAbstract) {
        if (_allocatedClasses.contains(classId)) {
          // Class declaring or inheriting member is allocated somewhere.
          getFunction(target);
        } else {
          // Remember the member in case an allocation is encountered later.
          _pendingAllocation.putIfAbsent(classId, () => []).add(target);
        }
      }
    });
  }

  void allocateClass(int classId) {
    if (_allocatedClasses.add(classId)) {
      // Schedule all members that were pending allocation of this class.
      for (Reference target in _pendingAllocation[classId] ?? const []) {
        getFunction(target);
      }
    }
  }

  @override
  w.FunctionType defaultMember(Member node, Reference target) {
    throw "No Wasm function for member: $node";
  }

  @override
  w.FunctionType visitField(Field node, Reference target) {
    if (!node.isInstanceMember) {
      if (target == node.fieldReference) {
        // Static field initializer function
        return _makeFunctionType(target, node.type, null);
      }
      String kind = target == node.setterReference ? "setter" : "getter";
      throw "No implicit $kind function for static field: $node";
    }
    return translator.dispatchTable.selectorForTarget(target).signature;
  }

  @override
  w.FunctionType visitProcedure(Procedure node, Reference target) {
    assert(!node.isAbstract);
    return node.isInstanceMember
        ? translator.dispatchTable.selectorForTarget(node.reference).signature
        : _makeFunctionType(target, node.function.returnType, null);
  }

  @override
  w.FunctionType visitConstructor(Constructor node, Reference target) {
    return _makeFunctionType(target, VoidType(),
        translator.classInfo[node.enclosingClass]!.nonNullableType);
  }

  w.FunctionType _makeFunctionType(
      Reference target, DartType returnType, w.ValueType? receiverType,
      {bool isImportOrExport = false}) {
    Member member = target.asMember;
    int typeParamCount = 0;
    Iterable<DartType> params;
    if (member is Field) {
      params = [if (target.isImplicitSetter) member.setterType];
    } else {
      FunctionNode function = member.function!;
      typeParamCount = (member is Constructor
              ? member.enclosingClass.typeParameters
              : function.typeParameters)
          .length;
      List<String> names = [for (var p in function.namedParameters) p.name!]
        ..sort();
      Map<String, DartType> nameTypes = {
        for (var p in function.namedParameters) p.name!: p.type
      };
      params = [
        for (var p in function.positionalParameters) p.type,
        for (String name in names) nameTypes[name]!
      ];
      function.positionalParameters.map((p) => p.type);
    }

    List<w.ValueType> typeParameters = List.filled(typeParamCount,
        translator.classInfo[translator.typeClass]!.nullableType);

    // The JS embedder will not accept Wasm struct types as parameter or return
    // types for functions called from JS. We need to use eqref instead.
    w.ValueType adjustExternalType(w.ValueType type) {
      if (isImportOrExport && type.isSubtypeOf(w.RefType.eq())) {
        return w.RefType.eq();
      }
      return type;
    }

    List<w.ValueType> inputs = [];
    if (receiverType != null) {
      inputs.add(adjustExternalType(receiverType));
    }
    inputs.addAll(typeParameters.map(adjustExternalType));
    inputs.addAll(
        params.map((t) => adjustExternalType(translator.translateType(t))));

    List<w.ValueType> outputs = returnType is VoidType ||
            returnType is NeverType ||
            returnType is NullType
        ? const []
        : [adjustExternalType(translator.translateType(returnType))];

    return translator.functionType(inputs, outputs);
  }
}
