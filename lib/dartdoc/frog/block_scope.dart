// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class BlockScope {
  MethodGenerator enclosingMethod;
  BlockScope parent;

  // TODO(jimhug): Using a list or tree-based map may improve perf; the list
  // is normally small.
  CopyOnWriteMap<String, VariableValue> _vars;

  /** Used JS names, if different from the Dart name. */
  Set<String> _jsNames;

  /**
   * Variables in this method that have been captured by lambdas.
   * Don't reuse the names in child blocks.
   */
  Set<String> _closedOver;

  /** If we are in a catch block, this is the exception variable to rethrow. */
  String rethrow;

  /**
   * True if the block is reentrant while the current method is executing.
   * This is only used for the blocks within loops.
   */
  bool reentrant;

  /** Tracks the node that this scope is associated with, for debugging */
  Node node;

  /** True if we should try to infer types for this block. */
  bool inferTypes;

  BlockScope(this.enclosingMethod, this.parent, this.node,
      [bool reentrant = false])
    : this.reentrant = reentrant,
      _vars = new CopyOnWriteMap<String, VariableValue>(),
      _jsNames = new Set<String>() {

    if (isMethodScope) {
      _closedOver = new Set<String>();
    } else {
      // Blocks within a reentrant block are also reentrant.
      this.reentrant = reentrant || parent.reentrant;
    }
    inferTypes = options.inferTypes && (parent == null || parent.inferTypes);
  }

  /** See the [snapshot] method for a description. */
  BlockScope._snapshot(BlockScope original)
    : enclosingMethod = original.enclosingMethod,
      parent = original.parent == null ? null : original.parent.snapshot(),
      _vars = original._vars.clone(),
      node = original.node,
      inferTypes = original.inferTypes,
      rethrow = original.rethrow,
      // TODO(jmesserly): are these this right?
      _jsNames = original._jsNames,
      _closedOver = original._closedOver;

  /** True if this is the top level scope of the method. */
  bool get isMethodScope() {
    return parent == null || parent.enclosingMethod != enclosingMethod;
  }

  /**
   * Gets the method scope associated with this block scope (possibly itself).
   */
  BlockScope get methodScope() {
    var s = this;
    while (!s.isMethodScope) s = s.parent;
    return s;
  }

  VariableValue lookup(String name) {
    for (var s = this; s != null; s = s.parent) {
      VariableValue ret = s._vars[name];
      if (ret != null) return _capture(s, ret);
    }
    return null;
  }

  void inferAssign(String name, Value value) {
    if (inferTypes) assign(name, value);
  }

  void assign(String name, Value value) {
    for (var s = this; s != null; s = s.parent) {
      var existing = s._vars[name];
      if (existing != null) {
        s._vars[name] = existing.replaceValue(value);
        return;
      }
    }
    world.internalError("assigning variable '${name}' that doesn't exist.");
  }

  Value _capture(BlockScope other, Value value) {
    // If this variable is from a different method, it means we closed over
    // it in the child lambda. Time for some bookeeping!
    if (other.enclosingMethod != enclosingMethod) {
      // Make sure the parent method doesn't reuse this variable to mean
      // something else.
      other.methodScope._closedOver.add(value.code);

      // If the scope we found this variable in is reentrant, remember the
      // variable. The lambda we're in will capture it with Function.bind.
      if (enclosingMethod.captures != null && other.reentrant) {
        enclosingMethod.captures.add(value.code);
      }
    }
    return value;
  }

  /**
   * Returns true if we can't use this name because we would be shadowing
   * another name in the JS that we might need to access later.
   */
  bool _isDefinedInParent(String name) {
    if (isMethodScope && _closedOver.contains(name)) return true;

    for (var s = parent; s != null; s = s.parent) {
      if (s._vars.containsKey(name)) return true;
      if (s._jsNames.contains(name)) return true;
      // Don't reuse a name that's been closed over
      if (s.isMethodScope && s._closedOver.contains(name)) return true;
    }

    // Ensure that we don't shadow another name that would've been accessible,
    // like top level names.
    // (This lookup might report errors, which is a bit strange.
    // But probably harmless since we have to pay for the lookup anyway.)
    // TODO(jmesserly): does this work right if JS name of the top-level thing
    // is different from Dart name?
    final type = enclosingMethod.method.declaringType;
    if (type.library.lookup(name, null) != null) return true;

    // Nobody else needs this name. It's safe to reuse.
    return false;
  }


  VariableValue create(String name, Type type, SourceSpan span,
      [bool isFinal = false, bool isParameter = false]) {

    var jsName = world.toJsIdentifier(name);
    if (_vars.containsKey(name)) {
      world.error('duplicate name "$name"', span);
    }

    // Make sure variables don't shadow any names we might need to access.
    if (!isParameter) {
      int index = 0;
      while (_isDefinedInParent(jsName)) {
        jsName = '$name${index++}';
      }
    }

    var ret = new VariableValue(type, jsName, span, isFinal);
    _vars[name] = ret;
    if (name != jsName) _jsNames.add(jsName);
    return ret;
  }

  Value declareParameter(Parameter p) {
    return create(p.name, p.type, p.definition.span, isParameter:true);
  }

  /** Declares a variable in the current scope for this identifier. */
  Value declare(DeclaredIdentifier id) {
    var type = enclosingMethod.method.resolveType(id.type, false, true);
    return create(id.name.name, type, id.span);
  }

  /**
   * Finds the first lexically enclosing catch block, if any, and returns its
   * exception variable.
   */
  String getRethrow() {
    var scope = this;
    while (scope.rethrow == null && scope.parent != null) {
      scope = scope.parent;
    }
    return scope.rethrow;
  }

  /**
   * Creates a snapshot of an existing BlockScope. Both the original and the
   * returned copy are writable. Clones all the way to the root node.
   */
  // TODO(jmesserly): this might need to be optimized.
  BlockScope snapshot() => new BlockScope._snapshot(this);

  /**
   * Unifies variable values with the ones in [other]. Returns `true` if
   * anything changed, `false` otherwise.
   */
  bool unionWith(BlockScope other) {
    bool changed = false;
    if (parent != null) {
      changed = parent.unionWith(other.parent);
    }

    // Optimization: check if the copy-on-write maps are the same
    if (_vars._map !== other._vars._map) {
      other._vars.forEach((String key, VariableValue otherVar) {
        VariableValue myVar = _vars[key];
        Value v = Value.union(myVar.value, otherVar.value);
        if (myVar.value !== v) {
          _vars[key] = myVar.replaceValue(v);
          changed = true;
        }
      });
    }

    return changed;
  }
}
