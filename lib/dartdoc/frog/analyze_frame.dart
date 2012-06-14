// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CallFrame implements CallingContext {
  CallFrame enclosingFrame;

  MethodAnalyzer analyzer;

  MemberSet findMembers(String name) => library._findMembers(name);
  CounterLog get counters() => world.counters;
  Library get library() => method.library;
  MethodMember method;

  bool get needsCode() => false;
  bool get showWarnings() => true;

  // TODO(jimhug): Shouldn't need these 5 methods below.
  String _makeThisCode() => null;

  Value getTemp(Value value) => null;
  VariableValue forceTemp(Value value) => null;
  Value assignTemp(Value tmp, Value v) => null;
  void freeTemp(VariableValue value) => null;

  bool get isStatic() =>
    enclosingFrame != null ? enclosingFrame.isStatic : method.isStatic;

  Value thisValue;
  Arguments args;

  List<VariableSlot> _slots;
  VariableSlot _returnSlot;

  AnalyzeScope _scope;


  CallFrame(this.analyzer, this.method, this.thisValue, this.args,
      this.enclosingFrame) {
    _slots = [];
    _scope = new AnalyzeScope(null, this, analyzer.body);

    _returnSlot = new VariableSlot(_scope, 'return', method.returnType,
      analyzer.body, false);

  }

  void pushBlock(Node node) {
    _scope = new AnalyzeScope(_scope, this, node);
  }

  void popBlock(Node node) {
    if (_scope.node != node) {
      world.internalError('incorrect pop', node.span, _scope.node.span);
    }
    _scope = _scope.parent;
  }

  Value getReturnValue() {
    return _returnSlot.get(null);
  }

  void returns(Value value) {
    _returnSlot.set(value);
  }

  VariableSlot lookup(String name) {
    var slot = _scope._lookup(name);
    if (slot == null && enclosingFrame != null) {
      return enclosingFrame.lookup(name);
    }
    return slot;
  }

  VariableSlot create(String name, Type staticType, Node node, bool isFinal,
      Value value) {
    // TODO(jimhug): Save mapping from node -> Slot.

    final slot = new VariableSlot(_scope, name, staticType, node, isFinal,
      value);
    final existingSlot = _scope._lookup(name);
    if (existingSlot !== null) {
      if (existingSlot.scope == this) {
        world.error('duplicate name "$name"', node.span);
      } else {
        // TODO(jimhug): Confirm that we can enable this useful warning.
        //world.warning('"$name" shadows variable from enclosing scope',
        //  node.span);
      }
    }
    _slots.add(slot);
    _scope._slots.add(slot);
  }

  VariableSlot declareParameter(Parameter p, Value value) {
    return create(p.name, p.type, p.definition, false, value);
  }

  _makeValue(Type type, Node node) {
    return new PureStaticValue(type, node == null ? null : node.span);
  }


  Value makeSuperValue(Node node) {
    return _makeValue(thisValue.type.parent, node);
  }

  Value makeThisValue(Node node) {
    return _makeValue(thisValue.type, node);
  }


  void dump() {
    print('**********${method.declaringType.name}.${method.name}***********');
    for (var slot in _slots) {
      print(slot);
    }
    print(_returnSlot);
  }
}

class VariableSlot {
  AnalyzeScope scope;
  final String name;
  Type staticType;
  Node node;
  bool isFinal;
  Value value;

  VariableSlot(this.scope, this.name, this.staticType, this.node,
    this.isFinal, [this.value]) {
    if (value !== null) {
      value = value.convertTo(scope.frame, staticType);
    }
  }

  Value get(Node position) {
    return scope.frame._makeValue(staticType, position);
  }

  void set(Value newValue) {
    if (newValue !== null) {
      newValue = newValue.convertTo(scope.frame, staticType);
    }

    value = Value.union(value, newValue);
  }

  String toString() {
    var valueString = value !== null ? ' = ${value.type.name}' : '';
    return '${this.staticType.name} ${this.name}${valueString}';
  }
}

class AnalyzeScope {
  CallFrame frame;
  AnalyzeScope parent;

  /** Tracks the node that this scope is associated with, for debugging */
  Node node;

  List<VariableSlot> _slots;

  AnalyzeScope(this.parent, this.frame, this.node): _slots = [];

  VariableSlot _lookup(String name) {
    for (var s = this; s != null; s = s.parent) {
      for (int i = 0; i < s._slots.length; i++) {
        final ret = s._slots[i];
        if (ret.name == name) return ret;
      }
    }
    return null;
  }
}
