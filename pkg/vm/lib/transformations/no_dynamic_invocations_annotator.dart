// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.no_dynamic_invocations_annotator;

import 'package:kernel/ast.dart';

import '../metadata/procedure_attributes.dart';

/// Assumes strong mode and closed world. If a procedure can not be riched
/// via dynamic invocation from anywhere then annotates it with appropriate
/// [ProcedureAttributeMetadata] annotation.
Component transformComponent(Component component) {
  new NoDynamicUsesAnnotator(component).visitComponent(component);
  return component;
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

// TODO(kustermann): Try to extend the idea of tracking uses based on the 'this'
// hierarchy.
class NoDynamicUsesAnnotator {
  final DynamicSelectorsCollector _selectors;
  final ProcedureAttributesMetadataRepository _metadata;

  NoDynamicUsesAnnotator(Component component)
      : _selectors = DynamicSelectorsCollector.collect(component),
        _metadata = new ProcedureAttributesMetadataRepository() {
    component.addMetadataRepository(_metadata);
  }

  visitComponent(Component component) {
    for (var library in component.libraries) {
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
    if (node.isStatic || node.name.text == 'call') {
      return;
    }

    final selector = new Selector.doSet(node.name);
    if (_selectors.dynamicSelectors.contains(selector)) {
      return;
    }

    ProcedureAttributesMetadata metadata;
    if (!_selectors.nonThisSelectors.contains(selector)) {
      metadata = const ProcedureAttributesMetadata(
          methodOrSetterCalledDynamically: false,
          getterCalledDynamically: false,
          hasNonThisUses: true,
          hasTearOffUses: false);
    } else {
      metadata = const ProcedureAttributesMetadata.noDynamicUses();
    }
    _metadata.mapping[node] = metadata;
  }

  visitProcedure(Procedure node) {
    if (node.isStatic || node.name.text == 'call') {
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

    if (_selectors.dynamicSelectors.contains(selector)) {
      return;
    }

    final bool hasNonThisUses = _selectors.nonThisSelectors.contains(selector);
    final bool hasTearOffUses = _selectors.tearOffSelectors.contains(selector);
    ProcedureAttributesMetadata metadata;
    if (!hasNonThisUses && !hasTearOffUses) {
      metadata = const ProcedureAttributesMetadata(
          methodOrSetterCalledDynamically: false,
          getterCalledDynamically: false,
          hasNonThisUses: false,
          hasTearOffUses: false);
    } else if (!hasNonThisUses && hasTearOffUses) {
      metadata = const ProcedureAttributesMetadata(
          methodOrSetterCalledDynamically: false,
          getterCalledDynamically: false,
          hasNonThisUses: false,
          hasTearOffUses: true);
    } else if (hasNonThisUses && !hasTearOffUses) {
      metadata = const ProcedureAttributesMetadata(
          methodOrSetterCalledDynamically: false,
          getterCalledDynamically: false,
          hasNonThisUses: true,
          hasTearOffUses: false);
    } else {
      metadata = const ProcedureAttributesMetadata.noDynamicUses();
    }
    _metadata.mapping[node] = metadata;
  }
}

class DynamicSelectorsCollector extends RecursiveVisitor<Null> {
  final Set<Selector> dynamicSelectors = new Set<Selector>();
  final Set<Selector> nonThisSelectors = new Set<Selector>();
  final Set<Selector> tearOffSelectors = new Set<Selector>();

  static DynamicSelectorsCollector collect(Component component) {
    final v = new DynamicSelectorsCollector();
    v.visitComponent(component);

    // We only populate [nonThisSelectors] and [tearOffSelectors] inside the
    // non-dynamic case (for efficiency reasons) while visiting the [Component].
    //
    // After the recursive visit of [Component] we complete the sets here.
    for (final Selector selector in v.dynamicSelectors) {
      // All dynamic getters can be tearoffs.
      if (selector.action == Action.get) {
        v.tearOffSelectors.add(new Selector.doInvoke(selector.target));
      }

      // All dynamic selectors are non-this selectors.
      v.nonThisSelectors.add(selector);
    }

    return v;
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    Selector selector;
    if (node.interfaceTarget == null) {
      dynamicSelectors.add(new Selector.doInvoke(node.name));
    } else {
      if (node.receiver is! ThisExpression) {
        nonThisSelectors.add(selector ??= new Selector.doInvoke(node.name));
      }
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    super.visitPropertyGet(node);

    Selector selector;
    if (node.interfaceTarget == null) {
      dynamicSelectors.add(selector = new Selector.doGet(node.name));
    } else {
      if (node.receiver is! ThisExpression) {
        nonThisSelectors.add(selector ??= new Selector.doGet(node.name));
      }

      final target = node.interfaceTarget;
      if (target is Procedure && target.kind == ProcedureKind.Method) {
        tearOffSelectors.add(new Selector.doInvoke(node.name));
      }
    }
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    Selector selector;
    if (node.interfaceTarget == null) {
      dynamicSelectors.add(selector = new Selector.doSet(node.name));
    } else {
      if (node.receiver is! ThisExpression) {
        nonThisSelectors.add(selector ??= new Selector.doSet(node.name));
      }
    }
  }
}
