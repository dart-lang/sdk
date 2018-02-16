// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.no_dynamic_invocations_annotator;

import 'package:kernel/ast.dart';

import '../metadata/procedure_attributes.dart';

/// Assumes strong mode and closed world. If a procedure can not be riched
/// via dynamic invocation from anywhere then annotates it with appropriate
/// [ProcedureAttributeMetadata] annotation.
Program transformProgram(Program program) {
  new NoDynamicInvocationsAnnotator(program).visitProgram(program);
  return program;
}

enum Action { get, set, invoke }

class Selector {
  final Action action;
  final Name target;

  Selector(this.action, this.target);

  Selector.doInvoke(Name target) : this(Action.invoke, target);
  Selector.doGet(Name target) : this(Action.get, target);
  Selector.doSet(Name target) : this(Action.set, target);

  bool operator ==(other) {
    return other is Selector &&
        other.action == this.action &&
        other.target == this.target;
  }

  int get hashCode => (action.index * 31) ^ target.hashCode;

  @override
  String toString() {
    switch (action) {
      case Action.get:
        return 'get:${target}';
      case Action.set:
        return 'set:${target}';
      case Action.invoke:
        return '${target}';
    }
    return '?';
  }
}

class NoDynamicInvocationsAnnotator {
  final Set<Selector> _dynamicSelectors;
  final ProcedureAttributesMetadataRepository _metadata;

  NoDynamicInvocationsAnnotator(Program program)
      : _dynamicSelectors = DynamicSelectorsCollector.collect(program),
        _metadata = new ProcedureAttributesMetadataRepository() {
    program.addMetadataRepository(_metadata);
  }

  visitProgram(Program program) {
    for (var library in program.libraries) {
      for (var klass in library.classes) {
        visitClass(klass);
      }
    }
  }

  visitClass(Class node) {
    for (var member in node.members) {
      if (member is Procedure) {
        visitProcedure(member);
      } else if (member is Field) {
        visitField(member);
      }
    }
  }

  visitField(Field node) {
    if (node.isStatic || node.name.name == 'call') {
      return;
    }

    if (!_dynamicSelectors.contains(new Selector.doSet(node.name))) {
      _metadata.mapping[node] =
          const ProcedureAttributesMetadata.noDynamicInvocations();
    }
  }

  visitProcedure(Procedure node) {
    if (node.isStatic || node.name.name == 'call') {
      return;
    }

    Selector selector;
    if (node.kind == ProcedureKind.Method) {
      selector = new Selector.doInvoke(node.name);
    } else if (node.kind == ProcedureKind.Setter) {
      selector = new Selector.doSet(node.name);
    } else {
      return;
    }

    if (!_dynamicSelectors.contains(selector)) {
      _metadata.mapping[node] =
          const ProcedureAttributesMetadata.noDynamicInvocations();
    }
  }
}

class DynamicSelectorsCollector extends RecursiveVisitor<Null> {
  final Set<Selector> dynamicSelectors = new Set<Selector>();

  static Set<Selector> collect(Program program) {
    final v = new DynamicSelectorsCollector();
    v.visitProgram(program);
    return v.dynamicSelectors;
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    if (node.dispatchCategory == DispatchCategory.dynamicDispatch) {
      dynamicSelectors.add(new Selector.doInvoke(node.name));
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    super.visitPropertyGet(node);

    if (node.dispatchCategory == DispatchCategory.dynamicDispatch) {
      dynamicSelectors.add(new Selector.doGet(node.name));
    }
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    if (node.dispatchCategory == DispatchCategory.dynamicDispatch) {
      dynamicSelectors.add(new Selector.doSet(node.name));
    }
  }
}
