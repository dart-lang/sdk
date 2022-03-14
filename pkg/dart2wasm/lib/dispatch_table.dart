// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/param_info.dart';
import 'package:dart2wasm/reference_extensions.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/metadata/table_selector.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Information for a dispatch table selector.
class SelectorInfo {
  final Translator translator;

  final int id;
  final int callCount;
  final bool tornOff;
  final ParameterInfo paramInfo;
  int returnCount;

  final Map<int, Reference> targets = {};
  late final w.FunctionType signature = computeSignature();

  late final List<int> classIds;
  late final int targetCount;
  bool forced = false;
  Reference? singularTarget;
  int? offset;

  String get name => paramInfo.member.name.text;

  bool get alive => callCount > 0 && targetCount > 1 || forced;

  int get sortWeight => classIds.length * 10 + callCount;

  SelectorInfo(this.translator, this.id, this.callCount, this.tornOff,
      this.paramInfo, this.returnCount);

  /// Compute the signature for the functions implementing members targeted by
  /// this selector.
  ///
  /// When the selector has multiple targets, the type of each parameter/return
  /// is the upper bound across all targets, such that all targets have the
  /// same signature, and the actual representation types of the parameters and
  /// returns are subtypes (resp. supertypes) of the types in the signature.
  w.FunctionType computeSignature() {
    var nameIndex = paramInfo.nameIndex;
    List<Set<ClassInfo>> inputSets =
        List.generate(1 + paramInfo.paramCount, (_) => {});
    List<Set<ClassInfo>> outputSets = List.generate(returnCount, (_) => {});
    List<bool> inputNullable = List.filled(1 + paramInfo.paramCount, false);
    List<bool> outputNullable = List.filled(returnCount, false);
    targets.forEach((id, target) {
      ClassInfo receiver = translator.classes[id];
      List<DartType> positional;
      Map<String, DartType> named;
      List<DartType> returns;
      Member member = target.asMember;
      if (member is Field) {
        if (target.isImplicitGetter) {
          positional = const [];
          named = const {};
          returns = [member.getterType];
        } else {
          positional = [member.setterType];
          named = const {};
          returns = const [];
        }
      } else {
        FunctionNode function = member.function!;
        if (target.isTearOffReference) {
          positional = const [];
          named = const {};
          returns = [function.computeFunctionType(Nullability.nonNullable)];
        } else {
          positional = [
            for (VariableDeclaration param in function.positionalParameters)
              param.type
          ];
          named = {
            for (VariableDeclaration param in function.namedParameters)
              param.name!: param.type
          };
          returns = function.returnType is VoidType
              ? const []
              : [function.returnType];
        }
      }
      assert(returns.length <= outputSets.length);
      inputSets[0].add(receiver);
      for (int i = 0; i < positional.length; i++) {
        DartType type = positional[i];
        inputSets[1 + i]
            .add(translator.classInfo[translator.classForType(type)]!);
        inputNullable[1 + i] |= type.isPotentiallyNullable;
      }
      for (String name in named.keys) {
        int i = nameIndex[name]!;
        DartType type = named[name]!;
        inputSets[1 + i]
            .add(translator.classInfo[translator.classForType(type)]!);
        inputNullable[1 + i] |= type.isPotentiallyNullable;
      }
      for (int i = 0; i < returnCount; i++) {
        if (i < returns.length) {
          outputSets[i]
              .add(translator.classInfo[translator.classForType(returns[i])]!);
          outputNullable[i] |= returns[i].isPotentiallyNullable;
        } else {
          outputNullable[i] = true;
        }
      }
    });

    List<w.ValueType> typeParameters = List.filled(paramInfo.typeParamCount,
        translator.classInfo[translator.typeClass]!.nullableType);
    List<w.ValueType> inputs = List.generate(
        inputSets.length,
        (i) => translator.typeForInfo(
            upperBound(inputSets[i]), inputNullable[i]) as w.ValueType);
    inputs[0] = translator.ensureBoxed(inputs[0]);
    if (name == '==') {
      // == can't be called with null
      inputs[1] = inputs[1].withNullability(false);
    }
    List<w.ValueType> outputs = List.generate(
        outputSets.length,
        (i) => translator.typeForInfo(
            upperBound(outputSets[i]), outputNullable[i]) as w.ValueType);
    return translator.functionType(
        [inputs[0], ...typeParameters, ...inputs.sublist(1)], outputs);
  }
}

// Build dispatch table for member calls.
class DispatchTable {
  final Translator translator;
  final List<TableSelectorInfo> selectorMetadata;
  final Map<TreeNode, ProcedureAttributesMetadata> procedureAttributeMetadata;

  final Map<int, SelectorInfo> selectorInfo = {};
  final Map<String, int> dynamicGets = {};
  late final List<Reference?> table;

  DispatchTable(this.translator)
      : selectorMetadata =
            (translator.component.metadata["vm.table-selector.metadata"]
                    as TableSelectorMetadataRepository)
                .mapping[translator.component]!
                .selectors,
        procedureAttributeMetadata =
            (translator.component.metadata["vm.procedure-attributes.metadata"]
                    as ProcedureAttributesMetadataRepository)
                .mapping;

  SelectorInfo selectorForTarget(Reference target) {
    Member member = target.asMember;
    bool isGetter = target.isGetter || target.isTearOffReference;
    ProcedureAttributesMetadata metadata = procedureAttributeMetadata[member]!;
    int selectorId = isGetter
        ? metadata.getterSelectorId
        : metadata.methodOrSetterSelectorId;
    ParameterInfo paramInfo = ParameterInfo.fromMember(target);
    int returnCount = isGetter ||
            member is Procedure && member.function.returnType is! VoidType
        ? 1
        : 0;
    bool calledDynamically = isGetter && metadata.getterCalledDynamically;
    if (calledDynamically) {
      // Merge all same-named getter selectors that are called dynamically.
      selectorId = dynamicGets.putIfAbsent(member.name.text, () => selectorId);
    }
    var selector = selectorInfo.putIfAbsent(
        selectorId,
        () => SelectorInfo(
            translator,
            selectorId,
            selectorMetadata[selectorId].callCount,
            selectorMetadata[selectorId].tornOff,
            paramInfo,
            returnCount)
          ..forced = calledDynamically);
    selector.paramInfo.merge(paramInfo);
    selector.returnCount = max(selector.returnCount, returnCount);
    return selector;
  }

  SelectorInfo selectorForDynamicName(String name) {
    return selectorInfo[dynamicGets[name]!]!;
  }

  void build() {
    // Collect class/selector combinations
    List<List<int>> selectorsInClass = [];
    for (ClassInfo info in translator.classes) {
      List<int> selectorIds = [];
      ClassInfo? superInfo = info.superInfo;
      if (superInfo != null) {
        int superId = superInfo.classId;
        selectorIds = List.of(selectorsInClass[superId]);
        for (int selectorId in selectorIds) {
          SelectorInfo selector = selectorInfo[selectorId]!;
          selector.targets[info.classId] = selector.targets[superId]!;
        }
      }

      SelectorInfo addMember(Reference reference) {
        SelectorInfo selector = selectorForTarget(reference);
        if (reference.asMember.isAbstract) {
          selector.targets[info.classId] ??= reference;
        } else {
          selector.targets[info.classId] = reference;
        }
        selectorIds.add(selector.id);
        return selector;
      }

      for (Member member
          in info.cls?.members ?? translator.coreTypes.objectClass.members) {
        if (member.isInstanceMember) {
          if (member is Field) {
            addMember(member.getterReference);
            if (member.hasSetter) addMember(member.setterReference!);
          } else if (member is Procedure) {
            SelectorInfo method = addMember(member.reference);
            if (method.tornOff) {
              addMember(member.tearOffReference);
            }
          }
        }
      }
      selectorsInClass.add(selectorIds);
    }

    // Build lists of class IDs and count targets
    for (SelectorInfo selector in selectorInfo.values) {
      selector.classIds = selector.targets.keys
          .where((id) => !(translator.classes[id].cls?.isAbstract ?? true))
          .toList()
        ..sort();
      Set<Reference> targets =
          selector.targets.values.where((t) => !t.asMember.isAbstract).toSet();
      selector.targetCount = targets.length;
      if (targets.length == 1) selector.singularTarget = targets.single;
    }

    // Assign selector offsets
    List<SelectorInfo> selectors = selectorInfo.values
        .where((s) => s.alive)
        .toList()
      ..sort((a, b) => b.sortWeight - a.sortWeight);
    int firstAvailable = 0;
    table = [];
    bool first = true;
    for (SelectorInfo selector in selectors) {
      int offset = first ? 0 : firstAvailable - selector.classIds.first;
      first = false;
      bool fits;
      do {
        fits = true;
        for (int classId in selector.classIds) {
          int entry = offset + classId;
          if (entry >= table.length) {
            // Fits
            break;
          }
          if (table[entry] != null) {
            fits = false;
            break;
          }
        }
        if (!fits) offset++;
      } while (!fits);
      selector.offset = offset;
      for (int classId in selector.classIds) {
        int entry = offset + classId;
        while (table.length <= entry) table.add(null);
        assert(table[entry] == null);
        table[entry] = selector.targets[classId];
      }
      while (firstAvailable < table.length && table[firstAvailable] != null) {
        firstAvailable++;
      }
    }
  }

  void output() {
    w.Module m = translator.m;
    w.Table wasmTable = m.addTable(table.length);
    for (int i = 0; i < table.length; i++) {
      Reference? target = table[i];
      if (target != null) {
        w.BaseFunction? fun = translator.functions.getExistingFunction(target);
        if (fun != null) {
          wasmTable.setElement(i, fun);
        }
      }
    }
  }
}
