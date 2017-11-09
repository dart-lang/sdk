// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import '../js_ast/js_ast.dart';

/// The ES6 name for the Dart SDK.  All dart:* libraries are in this module.
const String dartSdkModule = 'dart_sdk';

/// Unique instance for temporary variables. Will be renamed consistently
/// across the entire file. Different instances will be named differently
/// even if they have the same name, this makes it safe to use in code
/// generation without needing global knowledge. See [TemporaryNamer].
// TODO(jmesserly): move into js_ast? add a boolean to Identifier?
class TemporaryId extends Identifier {
  TemporaryId(String name) : super(name);
}

/// Creates a qualified identifier, without determining for sure if it needs to
/// be qualified until [setQualified] is called.
///
/// This expression is transparent to visiting after [setQualified].
class MaybeQualifiedId extends Expression {
  Expression _expr;

  final Identifier qualifier;
  final Expression name;

  MaybeQualifiedId(this.qualifier, this.name) {
    _expr = new PropertyAccess(qualifier, name);
  }

  /// Helper to create an [Identifier] from something that starts as a property.
  static identifier(LiteralString propertyName) =>
      new Identifier(propertyName.valueWithoutQuotes);

  void setQualified(bool qualified) {
    if (!qualified && name is LiteralString) {
      _expr = identifier(name);
    }
  }

  int get precedenceLevel => _expr.precedenceLevel;

  accept(NodeVisitor visitor) => _expr.accept(visitor);

  void visitChildren(NodeVisitor visitor) => _expr.visitChildren(visitor);
}

/// This class has two purposes:
///
/// * rename JS identifiers to avoid keywords.
/// * rename temporary variables to avoid colliding with user-specified names,
///   or other temporaries
///
/// Each instance of [TemporaryId] is treated as a unique variable, with its
/// `name` field simply the suggestion of what name to use. By contrast
/// [Identifiers] are never renamed unless they are an invalid identifier, like
/// `function` or `instanceof`, and their `name` field controls whether they
/// refer to the same variable.
class TemporaryNamer extends LocalNamer {
  _FunctionScope scope;

  TemporaryNamer(Node node) : scope = new _RenameVisitor.build(node).rootScope;

  String getName(Identifier node) {
    var rename = scope.renames[identifierKey(node)];
    if (rename != null) return rename;
    return node.name;
  }

  void enterScope(FunctionExpression node) {
    scope = scope.functions[node];
  }

  void leaveScope() {
    scope = scope.parent;
  }
}

/// Represents a complete function scope in JS.
///
/// We don't currently track ES6 block scopes, because we don't represent them
/// in js_ast yet.
class _FunctionScope {
  /// The parent scope.
  final _FunctionScope parent;

  /// All names declared in this scope.
  final declared = new HashSet<Object>();

  /// All names [declared] in this scope or its [parent]s, that is used in this
  /// scope and/or children. This is exactly the set of variable names we must
  /// not collide with inside this scope.
  final used = new HashSet<String>();

  /// Nested functions, these are visited after everything else so the names
  /// they might need are in scope.
  final functions = new Map<FunctionExpression, _FunctionScope>();

  /// New names assigned for temps and identifiers.
  final renames = new HashMap<Object, String>();

  _FunctionScope(this.parent);
}

/// Collects all names used in the visited tree.
class _RenameVisitor extends VariableDeclarationVisitor {
  final pendingRenames = new Map<Object, Set<_FunctionScope>>();

  final _FunctionScope globalScope = new _FunctionScope(null);
  final _FunctionScope rootScope = new _FunctionScope(null);
  _FunctionScope scope;

  _RenameVisitor.build(Node root) {
    scope = rootScope;
    root.accept(this);
    _finishFunctions();
    _finishNames();
  }

  declare(Identifier node) {
    var id = identifierKey(node);
    var notAlreadyDeclared = scope.declared.add(id);
    // Normal identifiers can be declared multiple times, because we don't
    // implement block scope yet. However temps should only be declared once.
    assert(notAlreadyDeclared || node is! TemporaryId);
    _markUsed(node, id, scope);
  }

  visitIdentifier(Identifier node) {
    var id = identifierKey(node);

    // Find where the node was declared.
    var declScope = scope;
    while (declScope != null && !declScope.declared.contains(id)) {
      declScope = declScope.parent;
    }
    if (declScope == null) {
      // Assume it comes from the global scope.
      declScope = globalScope;
      declScope.declared.add(id);
    }
    _markUsed(node, id, declScope);
  }

  _markUsed(Identifier node, Object id, _FunctionScope declScope) {
    // If it needs rename, we can't add it to the used name set yet, instead we
    // will record all scopes it is visible in.
    Set<_FunctionScope> usedIn = null;
    var rename = declScope != globalScope && needsRename(node);
    if (rename) {
      usedIn = pendingRenames.putIfAbsent(id, () => new HashSet());
    }
    for (var s = scope, end = declScope.parent; s != end; s = s.parent) {
      if (usedIn != null) {
        usedIn.add(s);
      } else {
        s.used.add(node.name);
      }
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    // Visit nested functions after all identifiers are declared.
    scope.functions[node] = new _FunctionScope(scope);
  }

  void _finishFunctions() {
    scope.functions.forEach((FunctionExpression f, _FunctionScope s) {
      scope = s;
      super.visitFunctionExpression(f);
      _finishFunctions();
      scope = scope.parent;
    });
  }

  void _finishNames() {
    pendingRenames.forEach((id, scopes) {
      var name = _findName(id, scopes);
      for (var s in scopes) {
        s.used.add(name);
        s.renames[id] = name;
      }
    });
  }

  static String _findName(Object id, Set<_FunctionScope> scopes) {
    String name;
    bool valid;
    if (id is TemporaryId) {
      name = id.name;
      valid = !invalidVariableName(name);
    } else {
      name = id;
      valid = false;
    }

    // Try to use the temp's name, otherwise rename.
    String candidate;
    if (valid && !scopes.any((scope) => scope.used.contains(name))) {
      candidate = name;
    } else {
      // This assumes that collisions are rare, hence linear search.
      // If collisions become common we need a better search.
      // TODO(jmesserly): what's the most readable scheme here? Maybe 1-letter
      // names in some cases?
      candidate = name == 'function' ? 'func' : '${name}\$';
      for (int i = 0;
          scopes.any((scope) => scope.used.contains(candidate));
          i++) {
        candidate = '${name}\$$i';
      }
    }
    return candidate;
  }
}

bool needsRename(Identifier node) =>
    node is TemporaryId || node.allowRename && invalidVariableName(node.name);

Object /*String|TemporaryId*/ identifierKey(Identifier node) =>
    node is TemporaryId ? node : node.name;

/// Returns true for invalid JS variable names, such as keywords.
/// Also handles invalid variable names in strict mode, like "arguments".
bool invalidVariableName(String keyword, {bool strictMode: true}) {
  switch (keyword) {
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    case "await":

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
    case "enum":
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
      return true;
    case "arguments":
    case "eval":
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    // http://www.ecma-international.org/ecma-262/6.0/#sec-identifiers-static-semantics-early-errors
    case "implements":
    case "interface":
    case "let":
    case "package":
    case "private":
    case "protected":
    case "public":
    case "static":
    case "yield":
      return strictMode;
  }
  return false;
}

/// Returns true for invalid static field names in strict mode.
///
/// In particular, "caller" "callee" "arguments" and "name" cannot be used.
/// These names however are valid as static getter/setter/method names using
/// ES class syntax.
bool invalidStaticFieldName(String name) {
  switch (name) {
    case "arguments":
    case "caller":
    case "callee":
    case "name":
      return true;
  }
  return false;
}

/// See ES6 spec (and `Object.getOwnPropertyNames(Object.prototype)`):
///
/// http://www.ecma-international.org/ecma-262/6.0/#sec-properties-of-the-object-prototype-object
/// http://www.ecma-international.org/ecma-262/6.0/#sec-additional-properties-of-the-object.prototype-object
final objectProperties = <String>[
  "constructor",
  "toString",
  "toLocaleString",
  "valueOf",
  "hasOwnProperty",
  "isPrototypeOf",
  "propertyIsEnumerable",
  "__defineGetter__",
  "__lookupGetter__",
  "__defineSetter__",
  "__lookupSetter__",
  "__proto__"
].toSet();

/// Returns the JS member name for a public Dart instance member, before it
/// is symbolized; generally you should use [_emitMemberName] or
/// [_declareMemberName] instead of this.
String memberNameForDartMember(String name) {
  // When generating synthetic names, we use _ as the prefix, since Dart names
  // won't have this, nor will static names reach here.
  switch (name) {
    case '[]':
      return '_get';
    case '[]=':
      return '_set';
    case 'unary-':
      return '_negate';
    case '==':
      return '_equals';
    case 'constructor':
    case 'prototype':
      return '_$name';
  }
  return name;
}

final friendlyNameForDartOperator = {
  '<': 'lessThan',
  '>': 'greaterThan',
  '<=': 'lessOrEquals',
  '>=': 'greaterOrEquals',
  '-': 'minus',
  '+': 'plus',
  '/': 'divide',
  '~/': 'floorDivide',
  '*': 'times',
  '%': 'modulo',
  '|': 'bitOr',
  '^': 'bitXor',
  '&': 'bitAnd',
  '<<': 'leftShift',
  '>>': 'rightShift',
  '~': 'bitNot',
  // These ones are always renamed, hence the choice of `_` to avoid conflict
  // with Dart names. See _emitMemberName.
  '==': '_equals',
  '[]': '_get',
  '[]=': '_set',
  'unary-': '_negate',
};
