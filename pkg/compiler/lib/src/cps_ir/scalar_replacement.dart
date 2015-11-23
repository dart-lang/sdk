// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.cps_ir.scalar_replacement;

import 'optimizers.dart';

import 'dart:collection' show Queue;

import '../common.dart';
import '../compiler.dart' as dart2js show
    Compiler;
import '../constants/values.dart';
import '../elements/elements.dart';
import '../types/types.dart';
import '../world.dart' show World;
import 'cps_ir_nodes.dart';

/**
 * Replaces aggregates with a set of local values.  Performs inlining of
 * single-use closures to generate more replaceable aggregates.
 */
class ScalarReplacer extends Pass {
  String get passName => 'Scalar replacement';

  final InternalErrorFunction _internalError;
  final World _classWorld;

  ScalarReplacer(dart2js.Compiler compiler)
      : _internalError = compiler.reporter.internalError,
        _classWorld = compiler.world;

  @override
  void rewrite(FunctionDefinition root) {
    ScalarReplacementVisitor analyzer =
        new ScalarReplacementVisitor(_internalError, _classWorld);
    analyzer.analyze(root);
    analyzer.process();
  }
}

/**
 * Do scalar replacement of aggregates on instances. Since scalar replacement
 * can create new candidates, iterate until all scalar replacements are done.
 */
class ScalarReplacementVisitor extends TrampolineRecursiveVisitor {

  final InternalErrorFunction internalError;
  final World classWorld;
  ScalarReplacementRemovalVisitor removalVisitor;

  Primitive _current = null;
  Set<Primitive> _allocations = new Set<Primitive>();
  Queue<Primitive> _queue = new Queue<Primitive>();

  ScalarReplacementVisitor(this.internalError, this.classWorld) {
    removalVisitor = new ScalarReplacementRemovalVisitor(this);
  }

  void analyze(FunctionDefinition root) {
    visit(root);
  }

  void process() {
    while (_queue.isNotEmpty) {
      Primitive allocation = _queue.removeFirst();
      _allocations.remove(allocation);
      _current = allocation;
      tryScalarReplacement(allocation);
    }
  }

  void tryScalarReplacement(Primitive allocation) {

    // We can do scalar replacement of an aggregate if all uses of an allocation
    // are reads or writes.
    for (Reference ref = allocation.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is GetField) continue;
      if (use is SetField && use.object == ref) continue;
      return;
    }

    Set<FieldElement> reads = new Set<FieldElement>();
    Set<FieldElement> writes = new Set<FieldElement>();
    for (Reference ref = allocation.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is GetField) {
        reads.add(use.field);
      } else if (use is SetField) {
        writes.add(use.field);
      } else {
        assert(false);
      }
    }

    // Find the initial values of the fields. A CreateBox has no initial
    // values. CreateInstance has initial values in the order of the fields.
    Map<FieldElement, Primitive> fieldInitialValues =
        <FieldElement, Primitive>{};
    if (allocation is CreateInstance) {
      int i = 0;
      allocation.classElement.forEachInstanceField(
        (ClassElement enclosingClass, FieldElement field) {
          Primitive argument = allocation.arguments[i++].definition;
          fieldInitialValues[field] = argument;
        },
        includeSuperAndInjectedMembers: true);
    }

    // Create [MutableVariable]s for each written field. Initialize the
    // MutableVariable with the value from the allocator, or initialize with a
    // `null` constant if there is not initial value.
    Map<FieldElement, MutableVariable> cells =
        <FieldElement, MutableVariable>{};
    InteriorNode insertionPoint = allocation.parent;  // LetPrim
    for (FieldElement field in writes) {
      MutableVariable variable = new MutableVariable(field);
      variable.type = new TypeMask.nonNullEmpty();
      cells[field] = variable;
      Primitive initialValue = fieldInitialValues[field];
      if (initialValue == null) {
        assert(allocation is CreateBox);
        initialValue = new Constant(new NullConstantValue());
        LetPrim let = new LetPrim(initialValue);
        let.primitive.parent = let;
        insertionPoint = let..insertBelow(insertionPoint);
      }
      LetMutable let = new LetMutable(variable, initialValue);
      let.value.parent = let;
      insertionPoint = let..insertBelow(insertionPoint);
    }

    // Replace references with MutableVariable operations or references to the
    // field's value.
    for (Reference ref = allocation.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is GetField) {
        GetField getField = use;
        MutableVariable variable = cells[getField.field];
        if (variable != null) {
          GetMutable getter = new GetMutable(variable);
          getter.type = getField.type;
          getter.variable.parent = getter;
          getField.replaceUsesWith(getter);
          replacePrimitive(getField, getter);
          deletePrimitive(getField);
        } else {
          Primitive value = fieldInitialValues[getField.field];
          getField.replaceUsesWith(value);
          deleteLetPrimOf(getField);
        }
      } else if (use is SetField && use.object == ref) {
        SetField setField = use;
        MutableVariable variable = cells[setField.field];
        Primitive value = setField.value.definition;
        variable.type = variable.type.union(value.type, classWorld);
        SetMutable setter = new SetMutable(variable, value);
        setter.variable.parent = setter;
        setter.value.parent = setter;
        setField.replaceUsesWith(setter);
        replacePrimitive(setField, setter);
        deletePrimitive(setField);
      } else {
        assert(false);
      }
    }

    // Delete [allocation] since that might 'free' another scalar replacement
    // candidate by deleting the last non-field-access.
    deleteLetPrimOf(allocation);
  }

  /// Replaces [old] with [primitive] in [old]'s parent [LetPrim].
  void replacePrimitive(Primitive old, Primitive primitive) {
    LetPrim letPrim = old.parent;
    letPrim.primitive = primitive;
    primitive.parent = letPrim;
  }

  void deleteLetPrimOf(Primitive primitive) {
    assert(primitive.hasNoUses);
    LetPrim letPrim = primitive.parent;
    letPrim.remove();
    deletePrimitive(primitive);
  }

  void deletePrimitive(Primitive primitive) {
    assert(primitive.hasNoUses);
    removalVisitor.visit(primitive);
  }

  void reconsider(Definition node) {
    if (node is CreateInstance || node is CreateBox) {
      if (node == _current) return;
      enqueue(node);
    }
  }

  void enqueue(Primitive node) {
    assert(node is CreateInstance || node is CreateBox);
    if (_allocations.contains(node)) return;
    _allocations.add(node);
    _queue.add(node);
  }

  // -------------------------- Visitor overrides ------------------------------
  void visitCreateInstance(CreateInstance node) {
    enqueue(node);
  }

  void visitCreateBox(CreateBox node) {
    enqueue(node);
  }
}


/// Visit a just-deleted subterm and unlink all [Reference]s in it.  Reconsider
/// allocations for scalar replacement.
class ScalarReplacementRemovalVisitor extends TrampolineRecursiveVisitor {
  ScalarReplacementVisitor process;

  ScalarReplacementRemovalVisitor(this.process);

  processReference(Reference reference) {
    process.reconsider(reference.definition);
    reference.unlink();
  }
}
