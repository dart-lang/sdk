// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'dispatch_table.dart' show Row, buildRowDisplacementTable;
import 'functions.dart'
    show
        CallShape,
        GetterCallShape,
        MethodCallShape,
        SetterCallShape,
        makeDynamicForwarderSignature;
import 'reference_extensions.dart';
import 'translator.dart';

class DynamicDispatchTable {
  final Translator translator;

  late final w.Table _definedTargetsTable;
  late final WasmTableImporter _importedTargetsTable = WasmTableImporter(
    translator,
    'dynamicDispatchTargets',
  );

  late final w.Table _definedClassIdsTable;
  late final WasmTableImporter _importedClassIdsTable = WasmTableImporter(
    translator,
    'dynamicDispatchClassIds',
  );

  late List<TableEntry?> _table;

  late final Map<CallShape, DynamicSelector> dynamicSelectors;

  DynamicDispatchTable(this.translator);

  w.Table getTargetsTable(w.ModuleBuilder module) =>
      _importedTargetsTable.get(_definedTargetsTable, module);

  w.Table getClassIdsTable(w.ModuleBuilder module) =>
      _importedClassIdsTable.get(_definedClassIdsTable, module);

  void build(Set<CallShape> dynamicCallShapes) {
    dynamicSelectors = {};
    for (final callerShape in dynamicCallShapes) {
      dynamicSelectors[callerShape] = DynamicSelector(
        callerShape,
        makeDynamicForwarderSignature(translator, callerShape),
      );
    }

    final List<({DynamicSelector selector, Row<TableEntry> row})> selectorRows =
        [];

    for (final selector in dynamicSelectors.values) {
      final targets = <int, Reference>{};
      final rowValues = <({int index, TableEntry value})>[];
      for (
        int classId = 0;
        classId <= translator.classIdNumbering.maxConcreteClassId;
        classId++
      ) {
        final target = _lookupTarget(selector, classId);
        if (target != null) {
          final match =
              !selector.isMethod ||
              (selector.shape as MethodCallShape).matchesTarget(
                (target.asMember as Procedure).function,
              );
          if (match) {
            targets[classId] = target;
          } else {
            // We may have the following situation:
            //
            //   class Foo {
            //     void foo(int i) {}
            //   }
            //
            //   dynamic x
            //   x.foo(bar: 1)
            //
            // Here the dynamic call site has a dynamic method selector with
            // call shape `MethodCallShape(bar)`. The target class `Foo` does
            // have the `foo` method but it doesn't match the caller shape.
            //
            // => Make the dynamic dispatch table have a slot, so we can
            //    detect that `foo` is present in `Foo`
            // => Do not actually generate a dynamic forwarder function for
            //    the call shape, since the shape doesn't match.
            // => This will make the dynamic call invoke `x.noSuchMethod(...)`
          }
          rowValues.add((
            index: classId,
            value: (target: target, classId: classId, shape: selector.shape),
          ));
        }
      }
      selector.targets = targets;
      if (rowValues.isNotEmpty) {
        selectorRows.add((selector: selector, row: Row(rowValues)));
      } else {
        selector.offset = null;
      }
    }

    // Fitting larger rows first makes the table more compact.
    selectorRows.sort((a, b) => b.row.values.length - a.row.values.length);

    // A dynamic call may not succeed (in which case it results in NSM), so we
    // require unique selctor offsets. This allows us to verify existence by
    // only checking the receiver class id in [_definedClassIdsTable] (otherwise
    // we'd need to verify receiver class id & selector id).
    _table = buildRowDisplacementTable([
      for (final sr in selectorRows) sr.row,
    ], uniqueOffsets: true);

    // Assign the selector offsets.
    for (final sr in selectorRows) {
      sr.selector.offset = sr.row.offset;
    }

    final module = translator.isDynamicSubmodule
        ? translator.dynamicSubmodule
        : translator.mainModule;
    _definedTargetsTable = module.tables.define(
      w.RefType.func(nullable: true),
      _table.length,
    );
    _definedClassIdsTable = module.tables.define(
      w.RefType.i31(nullable: true),
      _table.length,
    );
  }

  Reference? _lookupTarget(DynamicSelector selector, int classId) {
    final cls = translator.classes[classId].cls;
    if (cls == null) return null;

    // We do not dyanmically dispatch on wasm objects, they are not Dart objects
    if (translator.isWasmType(cls)) return null;

    final member = translator.hierarchy.getDispatchTarget(
      cls,
      selector.name,
      setter: selector.isSetter,
    );

    if (member == null || member.isAbstract) return null;

    final metadata = translator.procedureAttributeMetadata[member];
    if (metadata == null) return null;

    // If we have
    //
    //   class A { dynamic get foo => ... }
    //
    //   dynamic x;
    //   x.foo(...);
    //
    // TFA will claim that `A.foo` has no dynamic getter calls - but it has due
    // to `x.foo()` being evaluated as `var tmp = x.foo; foo()`.
    final bool calledDynamically = selector.isGetter
        ? metadata.getterCalledDynamically ||
              metadata.methodOrSetterCalledDynamically
        : metadata.methodOrSetterCalledDynamically;

    if (!calledDynamically && selector.name.text != "call") return null;

    if (selector.isMethod) {
      if (member is Procedure && !member.isGetter && !member.isSetter) {
        return member.reference;
      }
    } else if (selector.isGetter) {
      if (member is Field) return member.getterReference;
      if (member is Procedure) {
        if (member.isGetter) return member.reference;
        if (member.kind == ProcedureKind.Method && metadata.hasTearOffUses) {
          return member.tearOffReference;
        }
      }
    } else if (selector.isSetter) {
      if (member is Field && member.hasSetter) return member.setterReference;
      if (member is Procedure && member.isSetter) return member.reference;
    }
    return null;
  }

  void output() {
    for (int i = 0; i < _table.length; i++) {
      final entry = _table[i];
      if (entry == null) continue;

      if (!translator.functions.hasDynamicSelectorCall(entry.shape)) {
        // The dynamic call was never compiled (e.g. due to being unreachable).
        continue;
      }

      final targetModuleBuilder = translator.isDynamicSubmodule
          ? translator.dynamicSubmodule
          : translator.moduleForReference(entry.target);

      // The dynamic selector is invoked and the class has a target, we have to
      // write the class id - to make it match at runtime.
      final classIdsTable = getClassIdsTable(targetModuleBuilder);
      targetModuleBuilder.elements
          .activeExpressionSegmentBuilderFor(classIdsTable)
          .setExpressionAt(
            i,
            buildIntegerExpression(targetModuleBuilder, entry.classId),
          );

      // Only write out a dynamic forwarder function iff the target supports the
      // shape. See longer comment in [build] about this.
      final fun = translator.functions.getExistingDynamicForwarder(
        entry.target,
        entry.shape,
      );
      if (fun != null) {
        final targetsTable = getTargetsTable(targetModuleBuilder);
        targetModuleBuilder.elements
            .activeFunctionSegmentBuilderFor(targetsTable)
            .setFunctionAt(i, fun);
      }
    }
  }
}

class DynamicSelector {
  final CallShape shape;
  final w.FunctionType signature;
  late final Map<int, Reference> targets;

  late final int? offset;

  DynamicSelector(this.shape, this.signature);

  Name get name => shape.name;
  bool get isSetter => shape is SetterCallShape;
  bool get isGetter => shape is GetterCallShape;
  bool get isMethod => shape is MethodCallShape;

  @override
  bool operator ==(Object other) =>
      other is DynamicSelector && shape == other.shape;

  @override
  int get hashCode => shape.hashCode;

  @override
  String toString() => "DynamicSelector $shape $signature";
}

class DynamicCallSiteCollector extends RecursiveVisitor {
  final Set<CallShape> _callerShapes = {};

  DynamicCallSiteCollector._();

  static Set<CallShape> collect(Component component) {
    final collector = DynamicCallSiteCollector._();
    component.accept(collector);
    return collector._callerShapes;
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    if (node.kind == FunctionAccessKind.Function) {
      // This is a call on `Function f`. Since `Function` cannot be implemented
      // we know it's a closure and closures are always called via field getter.
      _callerShapes.add(GetterCallShape(node.name));
    }
    super.visitFunctionInvocation(node);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    final methodShape = MethodCallShape(
      node.name,
      node.arguments.types.length,
      node.arguments.positional.length,
      node.arguments.named.map((n) => n.name).toList()..sort(),
    );
    _callerShapes.add(methodShape);
    // A `dynamic x; x.foo(...)` may end up be executed via
    // `var tmp = x.foo; var tmp2 = tmp.call; ...; tmpX.call(...)`.
    _callerShapes.add(GetterCallShape(node.name));
    _callerShapes.add(GetterCallShape(Name('call')));
    _callerShapes.add(methodShape.copyWithName(Name('call')));
    super.visitDynamicInvocation(node);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    _callerShapes.add(GetterCallShape(node.name));
    super.visitDynamicGet(node);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    _callerShapes.add(SetterCallShape(node.name));
    super.visitDynamicSet(node);
  }
}

typedef TableEntry = ({Reference target, int classId, CallShape shape});

w.InstructionsBuilder buildIntegerExpression(
  w.ModuleBuilder module,
  int value,
) {
  final b = w.InstructionsBuilder(module, [], [
    w.RefType.i31(nullable: false),
  ], constantExpression: true);
  b.i32_const(value);
  b.i31_new();
  b.end();
  return b;
}
