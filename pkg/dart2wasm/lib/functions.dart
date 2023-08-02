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
class FunctionCollector {
  final Translator translator;

  // Wasm function for each Dart function
  final Map<Reference, w.BaseFunction> _functions = {};
  // Names of exported functions
  final Map<Reference, String> _exports = {};
  // Functions for which code has not yet been generated
  final List<Reference> _worklist = [];
  // Class IDs for classes that are allocated somewhere in the program
  final Set<int> _allocatedClasses = {};
  // For each class ID, which functions should be added to the worklist if an
  // allocation of that class is encountered
  final Map<int, List<Reference>> _pendingAllocation = {};

  FunctionCollector(this.translator);

  w.ModuleBuilder get m => translator.m;

  void collectImportsAndExports() {
    for (Library library in translator.libraries) {
      library.procedures.forEach(_importOrExport);
      library.fields.forEach(_importOrExport);
      for (Class cls in library.classes) {
        cls.procedures.forEach(_importOrExport);
      }
    }
  }

  bool isWorkListEmpty() => _worklist.isEmpty;

  Reference popWorkList() => _worklist.removeLast();

  void _importOrExport(Member member) {
    String? importName = translator.getPragma(member, "wasm:import");
    if (importName != null) {
      int dot = importName.indexOf('.');
      if (dot != -1) {
        assert(!member.isInstanceMember);
        String module = importName.substring(0, dot);
        String name = importName.substring(dot + 1);
        if (member is Procedure) {
          // Define the function type in a singular recursion group to enable it
          // to be unified with function types defined in FFI modules or using
          // `WebAssembly.Function`.
          m.types.splitRecursionGroup();
          w.FunctionType ftype = _makeFunctionType(
              translator, member.reference, member.function.returnType, null,
              isImportOrExport: true);
          m.types.splitRecursionGroup();
          _functions[member.reference] =
              m.functions.import(module, name, ftype, "$importName (import)");
        }
      }
    }
    String? exportName =
        translator.getPragma(member, "wasm:export", member.name.text);
    if (exportName != null) {
      if (member is Procedure) {
        // Although we don't need type unification for the types of exported
        // functions, we still place these types in singleton recursion groups,
        // since Binaryen's `--closed-world` optimization mode requires all
        // publicly exposed types to be defined in separate recursion groups
        // from GC types.
        m.types.splitRecursionGroup();
        _makeFunctionType(
            translator, member.reference, member.function.returnType, null,
            isImportOrExport: true);
        m.types.splitRecursionGroup();
      }
      addExport(member.reference, exportName);
    }
  }

  void addExport(Reference target, String exportName) {
    _exports[target] = exportName;
  }

  String? getExport(Reference target) => _exports[target];

  void initialize() {
    // Add exports to the module and add exported functions to the worklist
    for (var export in _exports.entries) {
      Reference target = export.key;
      Member node = target.asMember;
      if (node is Procedure) {
        _worklist.add(target);
        assert(!node.isInstanceMember);
        assert(!node.isGetter);
        w.FunctionType ftype = _makeFunctionType(
            translator, target, node.function.returnType, null,
            isImportOrExport: true);
        w.BaseFunction function = m.functions.define(ftype, "$node");
        _functions[target] = function;
        m.exports.export(export.value, function);
      } else if (node is Field) {
        w.Table? table = translator.getTable(node);
        if (table != null) {
          m.exports.export(export.value, table);
        }
      }
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
      _worklist.add(target);
      return _getFunctionTypeAndName(target, m.functions.define);
    });
  }

  w.FunctionType getFunctionType(Reference target) {
    return _getFunctionTypeAndName(target, (ftype, name) => ftype);
  }

  T _getFunctionTypeAndName<T>(
      Reference target, T Function(w.FunctionType, String) action) {
    if (target.isTypeCheckerReference) {
      Member member = target.asMember;
      if (member is Field || (member is Procedure && member.isSetter)) {
        return action(translator.dynamicSetForwarderFunctionType,
            '${target.asMember} setter type checker');
      } else {
        return action(translator.dynamicInvocationForwarderFunctionType,
            '${target.asMember} invocation type checker');
      }
    }

    if (target.isTearOffReference) {
      return action(
          translator.dispatchTable.selectorForTarget(target).signature,
          "${target.asMember} tear-off");
    }

    final ftype =
        target.asMember.accept1(_FunctionTypeGenerator(translator), target);
    return action(ftype, "${target.asMember}");
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

  /// Returns an iterable of translated procedures.
  Iterable<Procedure> get translatedProcedures =>
      _functions.keys.map((k) => k.node).whereType<Procedure>();
}

class _FunctionTypeGenerator extends MemberVisitor1<w.FunctionType, Reference> {
  final Translator translator;

  _FunctionTypeGenerator(this.translator);

  @override
  w.FunctionType defaultMember(Member node, Reference target) {
    throw "No Wasm function for member: $node";
  }

  @override
  w.FunctionType visitField(Field node, Reference target) {
    if (!node.isInstanceMember) {
      if (target == node.fieldReference) {
        // Static field initializer function
        return _makeFunctionType(translator, target, node.type, null);
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
        : _makeFunctionType(translator, target, node.function.returnType, null);
  }

  @override
  w.FunctionType visitConstructor(Constructor node, Reference target) {
    return _makeFunctionType(translator, target, VoidType(),
        translator.classInfo[node.enclosingClass]!.nonNullableType);
  }
}

w.FunctionType _makeFunctionType(Translator translator, Reference target,
    DartType returnType, w.ValueType? receiverType,
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

  // Translate types differently for imports and exports.
  w.ValueType translateType(DartType type) => isImportOrExport
      ? translator.translateExternalType(type)
      : translator.translateType(type);

  final List<w.ValueType> typeParameters = List.filled(
      typeParamCount,
      translateType(
          InterfaceType(translator.typeClass, Nullability.nonNullable)));

  final List<w.ValueType> inputs = [];
  if (receiverType != null) {
    assert(!isImportOrExport);
    inputs.add(receiverType);
  }
  inputs.addAll(typeParameters);
  inputs.addAll(params.map(translateType));

  final bool emptyOutputList = member is Constructor ||
      member is Procedure && member.isSetter ||
      isImportOrExport && returnType is VoidType ||
      returnType is InterfaceType &&
          returnType.classNode == translator.wasmVoidClass;
  final List<w.ValueType> outputs =
      emptyOutputList ? const [] : [translateType(returnType)];

  return translator.m.types.defineFunction(inputs, outputs);
}
