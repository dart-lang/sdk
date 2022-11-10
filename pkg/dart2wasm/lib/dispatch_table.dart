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
  bool calledDynamically = false;
  Reference? singularTarget;
  int? offset;

  w.Module get m => translator.m;

  String get name => paramInfo.member!.name.text;

  bool get isAlive =>
      (calledDynamically && targetCount > 0) ||
      (callCount > 0 && targetCount > 1);

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
    List<bool> ensureBoxed = List.filled(1 + paramInfo.paramCount, false);
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
      ensureBoxed[0] = true;
      for (int i = 0; i < positional.length; i++) {
        DartType type = positional[i];
        inputSets[1 + i]
            .add(translator.classInfo[translator.classForType(type)]!);
        inputNullable[1 + i] |= type.isPotentiallyNullable;
        ensureBoxed[1 + i] |=
            paramInfo.positional[i] == ParameterInfo.defaultValueSentinel;
      }
      for (String name in named.keys) {
        int i = nameIndex[name]!;
        DartType type = named[name]!;
        inputSets[1 + i]
            .add(translator.classInfo[translator.classForType(type)]!);
        inputNullable[1 + i] |= type.isPotentiallyNullable;
        ensureBoxed[1 + i] |=
            paramInfo.named[name] == ParameterInfo.defaultValueSentinel;
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
        translator.classInfo[translator.typeClass]!.nonNullableType);
    List<w.ValueType> inputs = List.generate(
        inputSets.length,
        (i) => translator.typeForInfo(
            upperBound(inputSets[i]), inputNullable[i],
            ensureBoxed: ensureBoxed[i]) as w.ValueType);
    if (name == '==') {
      // == can't be called with null
      inputs[1] = inputs[1].withNullability(false);
    }
    List<w.ValueType> outputs = List.generate(
        outputSets.length,
        (i) => translator.typeForInfo(
            upperBound(outputSets[i]), outputNullable[i]) as w.ValueType);
    return m.addFunctionType(
        [inputs[0], ...typeParameters, ...inputs.sublist(1)], outputs);
  }

  // Returns a bool indicating whether or not a given selector can be applied to
  // a given [Arguments] object. This only checks the argument counts / names,
  // not their types.
  bool canApply(Expression dynamicExpression) {
    if (dynamicExpression is DynamicGet || dynamicExpression is DynamicSet) {
      // Dynamic get or set can always apply.
      return true;
    } else if (dynamicExpression is DynamicInvocation) {
      Procedure member = paramInfo.member as Procedure;
      Arguments arguments = dynamicExpression.arguments;
      FunctionNode function = member.function;
      if (arguments.types.isNotEmpty &&
          arguments.types.length != function.typeParameters.length) {
        return false;
      }

      if (arguments.positional.length < function.requiredParameterCount ||
          arguments.positional.length > function.positionalParameters.length) {
        return false;
      }

      Set<String> namedParameters = {};
      Set<String> requiredNamedParameters = {};
      for (VariableDeclaration v in function.namedParameters) {
        if (v.isRequired) {
          requiredNamedParameters.add(v.name!);
        } else {
          namedParameters.add(v.name!);
        }
      }

      int requiredFound = 0;
      for (NamedExpression namedArgument in arguments.named) {
        bool found = requiredNamedParameters.contains(namedArgument.name);
        if (found) {
          requiredFound++;
        } else if (!namedParameters.contains(namedArgument.name)) {
          return false;
        }
      }
      return requiredFound == requiredNamedParameters.length;
    }
    throw '"canApply" should only be used for procedures';
  }
}

// Build dispatch table for member calls.
class DispatchTable {
  final Translator translator;
  final List<TableSelectorInfo> selectorMetadata;
  final Map<TreeNode, ProcedureAttributesMetadata> procedureAttributeMetadata;

  final Map<int, SelectorInfo> selectorInfo = {};
  final Map<String, List<SelectorInfo>> dynamicGets = {};
  final Map<String, List<SelectorInfo>> dynamicSets = {};
  final Map<String, List<SelectorInfo>> dynamicMethods = {};
  late final List<Reference?> table;
  late final w.DefinedTable wasmTable;

  w.Module get m => translator.m;

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
    bool isSetter = target.isSetter;
    ProcedureAttributesMetadata metadata = procedureAttributeMetadata[member]!;
    int selectorId = isGetter
        ? metadata.getterSelectorId
        : metadata.methodOrSetterSelectorId;
    ParameterInfo paramInfo = ParameterInfo.fromMember(target);
    final int returnCount = (isGetter && member.getterType is! VoidType) ||
            (member is Procedure && member.function.returnType is! VoidType)
        ? 1
        : 0;

    // _WasmBase and its subclass methods cannot be called dynamically
    final cls = member.enclosingClass;
    final isWasmType = cls != null && translator.isWasmType(cls);

    final calledDynamically = !isWasmType &&
        translator.dynamics.maybeCalledDynamically(member, metadata);

    final selector = selectorInfo.putIfAbsent(
        selectorId,
        () => SelectorInfo(
            translator,
            selectorId,
            selectorMetadata[selectorId].callCount,
            selectorMetadata[selectorId].tornOff,
            paramInfo,
            returnCount));
    selector.paramInfo.merge(paramInfo);
    selector.returnCount = max(selector.returnCount, returnCount);
    selector.calledDynamically |= calledDynamically;
    if (calledDynamically) {
      if (isGetter) {
        (dynamicGets[member.name.text] ??= []).add(selector);
      } else if (isSetter) {
        (dynamicSets[member.name.text] ??= []).add(selector);
      } else {
        (dynamicMethods[member.name.text] ??= []).add(selector);
      }
    }
    return selector;
  }

  /// Returns a possibly null list of [SelectorInfo]s for a given dynamic
  /// call.
  Iterable<SelectorInfo>? selectorsForDynamicNode(Expression node) {
    if (node is DynamicGet) {
      return dynamicGets[node.name.text];
    } else if (node is DynamicSet) {
      return dynamicSets[node.name.text];
    } else if (node is DynamicInvocation) {
      return dynamicMethods[node.name.text];
    } else {
      throw 'Dynamic invocation of $node not supported';
    }
  }

  void build() {
    // Collect class/selector combinations

    // Maps class IDs to selector IDs of the class
    List<List<int>> selectorsInClass = [];

    for (ClassInfo info in translator.classes) {
      List<int> selectorIds = [];
      ClassInfo? superInfo = info.superInfo;

      // _WasmBase does not inherit from Object
      if (superInfo != null && info.cls != translator.wasmTypesBaseClass) {
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
            if (method.tornOff &&
                procedureAttributeMetadata[member]!.hasTearOffUses) {
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
        .where((s) => s.isAlive)
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
        while (table.length <= entry) {
          table.add(null);
        }
        assert(table[entry] == null);
        table[entry] = selector.targets[classId];
      }
      while (firstAvailable < table.length && table[firstAvailable] != null) {
        firstAvailable++;
      }
    }

    wasmTable = m.addTable(w.RefType.func(nullable: true), table.length);
  }

  void output() {
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
