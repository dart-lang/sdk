// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.codegen.js_names;

import 'dart:collection';
import 'package:dev_compiler/src/js/js_ast.dart';

/// Unique instance for temporary variables. Will be renamed consistently
/// across the entire file. Different instances will be named differently
/// even if they have the same name, this makes it safe to use in code
/// generation without needing global knowledge. See [JSNamer].
///
// TODO(jmesserly): move into js_ast? add a boolean to Identifier?
class JSTemporary extends Identifier {
  JSTemporary(String name) : super(name);
}

/// This class has two purposes:
///
/// * rename JS identifiers to avoid keywords.
/// * rename temporary variables to avoid colliding with user-specified names,
///   or other temporaries
///
/// Each instance of [JSTemporary] is treated as a unique variable, with its
/// `name` field simply the suggestion of what name to use. By contrast
/// [Identifiers] are never renamed unless they are an invalid identifier, like
/// `function` or `instanceof`, and their `name` field controls whether they
/// refer to the same variable.
class JSNamer extends LocalNamer {
  final Map<Object, String> renames;

  JSNamer(Node node) : renames = new _RenameVisitor.build(node).renames;

  String getName(Identifier node) {
    var rename = renames[renameKey(node)];
    if (rename != null) return rename;

    assert(!needsRename(node));
    return node.name;
  }

  void enterScope(FunctionExpression node) {}
  void leaveScope() {}
}

class _FunctionScope {
  final _FunctionScope parent;
  final names = new HashSet<String>();
  _FunctionScope(this.parent);
}

/// Collects all names used in the visited tree.
class _RenameVisitor extends BaseVisitor {
  final pendingRenames = new Map<Object, Set<_FunctionScope>>();
  final renames = new HashMap<Object, String>();

  _FunctionScope scope = new _FunctionScope(null);

  _RenameVisitor.build(Node root) {
    root.accept(this);
    _finishNames();
  }

  visitIdentifier(Identifier node) {
    if (needsRename(node)) {
      // We can't assign the name yet, but we can add it to the list of things
      // that need a name.
      var id = renameKey(node);
      pendingRenames.putIfAbsent(id, () => new HashSet()).add(scope);
    } else {
      scope.names.add(node.name);
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    scope = new _FunctionScope(scope);
    super.visitFunctionExpression(node);
    scope = scope.parent;
  }

  void _finishNames() {
    pendingRenames.forEach((id, scopes) {
      var name = _findName(id, _allNamesInScope(scopes));
      renames[id] = name;
      for (var s in scopes) s.names.add(name);
    });
  }

  // Given a set of scopes, populates [allNames] to include all names in those
  // scopes as well as intermediate scopes. Returns the common parent of
  // all scopes. For example:
  //
  // function outer(t) {
  //   function middle(x) {
  //     function inner() { return t; }
  //     foo(x);
  //   }
  // }
  //
  // Here `t` is used in `inner` and `outer` but we need to include `middle`
  // as well, so we know the rename of `t` to `x` is not valid.
  static Set<String> _allNamesInScope(Set<_FunctionScope> scopes) {
    // As we iterate, we'll add more scopes. We don't need to consider these
    // as intermediate scopes can't introduce new intermediates.
    var candidates = [];
    var allScopes = scopes.toSet();
    for (var scope in scopes) {
      for (var p = scope.parent; p != null; p = p.parent) {
        if (allScopes.contains(p)) {
          allScopes.addAll(candidates);
          break;
        }
        candidates.add(p);
      }
      // Discard these, we already added them or we didn't find a parent scope.
      candidates.clear();
    }

    // Now collect all names found.
    return allScopes.expand((s) => s.names).toSet();
  }

  static String _findName(Object id, Set<String> usedNames) {
    String name;
    bool valid;
    if (id is JSTemporary) {
      name = id.name;
      valid = !invalidJSVariableName(name);
    } else {
      name = id;
      valid = false;
    }

    // Try to use the temp's name, otherwise rename.
    String candidate;
    if (valid && !usedNames.contains(name)) {
      candidate = name;
    } else {
      // This assumes that collisions are rare, hence linear search.
      // If collisions become common we need a better search.
      // TODO(jmesserly): what's the most readable scheme here? Maybe 1-letter
      // names in some cases?
      candidate = name == 'function' ? 'func' : '${name}\$';
      for (int i = 0; usedNames.contains(candidate); i++) {
        candidate = '${name}\$$i';
      }
    }
    return candidate;
  }
}

bool needsRename(Identifier node) =>
    node is JSTemporary || node.allowRename && invalidJSVariableName(node.name);

Object /*String|JSTemporary*/ renameKey(Identifier node) =>
    node is JSTemporary ? node : node.name;

/// Returns true for invalid JS variable names, such as keywords.
/// Also handles invalid variable names in strict mode, like "arguments".
bool invalidJSVariableName(String keyword, {bool strictMode: true}) {
  switch (keyword) {
    case "break":
    case "case":
    case "catch":
    case "class":
    case "const":
    case "continue":
    case "debugger":
    case "default":
    case "delete":
    case "do":
    case "else":
    case "export":
    case "extends":
    case "finally":
    case "for":
    case "function":
    case "if":
    case "import":
    case "in":
    case "instanceof":
    case "let":
    case "new":
    case "return":
    case "static":
    case "super":
    case "switch":
    case "this":
    case "throw":
    case "try":
    case "typeof":
    case "var":
    case "void":
    case "while":
    case "with":
    case "yield":
      return true;
    case "arguments":
    case "eval":
      return strictMode;
  }
  return false;
}

/// Returns true for invalid static method names in strict mode.
/// In particular, "caller" "callee" and "arguments" cannot be used.
bool invalidJSStaticMethodName(String name) {
  switch (name) {
    case "arguments":
    case "caller":
    case "callee":
      return true;
  }
  return false;
}
