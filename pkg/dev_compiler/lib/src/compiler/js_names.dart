// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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
  // TODO(jmesserly): by design, temporary identifier nodes are shared
  // throughout the AST, so any source information we attach in one location
  // be incorrect for another location (and overwrites previous data).
  //
  // If we want to track source information for temporary variables, we'll
  // need to separate the identity of the variable from its Identifier.
  //
  // In practice that makes temporaries more difficult to use: they're no longer
  // JS AST nodes, so `toIdentifier()` is required to put them in the JS AST.
  // And anywhere we currently use type `Identifier` to hold Identifier or
  // TemporaryId, those types would need to change to `Identifier Function()`.
  //
  // However we may need to fix this if we want hover to work well for things
  // like library prefixes and field-initializing formals.
  @override
  dynamic get sourceInformation => null;
  @override
  set sourceInformation(Object obj) {}

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
    _expr = PropertyAccess(qualifier, name);
  }

  /// Helper to create an [Identifier] from something that starts as a property.
  static Identifier identifier(LiteralString propertyName) =>
      Identifier(propertyName.valueWithoutQuotes);

  void setQualified(bool qualified) {
    var name = this.name;
    if (!qualified && name is LiteralString) {
      _expr = identifier(name);
    }
  }

  @override
  int get precedenceLevel => _expr.precedenceLevel;

  @override
  T accept<T>(NodeVisitor<T> visitor) => _expr.accept(visitor);

  @override
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

  TemporaryNamer(Node node) : scope = _RenameVisitor.build(node).rootScope;

  @override
  String getName(Identifier node) {
    var rename = scope.renames[identifierKey(node)];
    if (rename != null) return rename;
    return node.name;
  }

  @override
  void enterScope(Node node) {
    scope = scope.childScopes[node];
  }

  @override
  void leaveScope() {
    scope = scope.parent;
  }
}

/// Represents a complete function scope in JS.
///
/// We don't currently track ES6 block scopes.
class _FunctionScope {
  /// The parent scope.
  final _FunctionScope parent;

  /// All names declared in this scope.
  final declared = HashSet<Object>();

  /// All names [declared] in this scope or its [parent]s, that is used in this
  /// scope and/or children. This is exactly the set of variable names we must
  /// not collide with inside this scope.
  final used = HashSet<String>();

  /// Nested scopes, these are visited after everything else so the names
  /// they might need are in scope.
  final childScopes = <Node, _FunctionScope>{};

  /// New names assigned for temps and identifiers.
  final renames = HashMap<Object, String>();

  _FunctionScope(this.parent);
}

/// Collects all names used in the visited tree.
class _RenameVisitor extends VariableDeclarationVisitor {
  final pendingRenames = <Object, Set<_FunctionScope>>{};

  final _FunctionScope globalScope = _FunctionScope(null);
  final _FunctionScope rootScope = _FunctionScope(null);
  _FunctionScope scope;

  _RenameVisitor.build(Node root) {
    scope = rootScope;
    root.accept(this);
    _finishScopes();
    _finishNames();
  }

  @override
  void declare(Identifier node) {
    var id = identifierKey(node);
    var notAlreadyDeclared = scope.declared.add(id);
    // Normal identifiers can be declared multiple times, because we don't
    // implement block scope yet. However temps should only be declared once.
    assert(notAlreadyDeclared || node is! TemporaryId);
    _markUsed(node, id, scope);
  }

  @override
  void visitIdentifier(Identifier node) {
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

  void _markUsed(Identifier node, Object id, _FunctionScope declScope) {
    // If it needs rename, we can't add it to the used name set yet, instead we
    // will record all scopes it is visible in.
    Set<_FunctionScope> usedIn;
    var rename = declScope != globalScope && needsRename(node);
    if (rename) {
      usedIn = pendingRenames.putIfAbsent(id, () => HashSet());
    }
    for (var s = scope, end = declScope.parent; s != end; s = s.parent) {
      if (usedIn != null) {
        usedIn.add(s);
      } else {
        s.used.add(node.name);
      }
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Visit nested functions after all identifiers are declared.
    scope.childScopes[node] = _FunctionScope(scope);
  }

  @override
  void visitClassExpression(ClassExpression node) {
    scope.childScopes[node] = _FunctionScope(scope);
  }

  void _finishScopes() {
    scope.childScopes.forEach((node, s) {
      scope = s;
      if (node is FunctionExpression) {
        super.visitFunctionExpression(node);
      } else {
        super.visitClassExpression(node as ClassExpression);
      }
      _finishScopes();
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
      name = id as String;
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
      for (var i = 0;
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
bool invalidVariableName(String keyword, {bool strictMode = true}) {
  switch (keyword) {
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    case 'await':

    case 'break':
    case 'case':
    case 'catch':
    case 'class':
    case 'const':
    case 'continue':
    case 'debugger':
    case 'default':
    case 'delete':
    case 'do':
    case 'else':
    case 'enum':
    case 'export':
    case 'extends':
    case 'finally':
    case 'for':
    case 'function':
    case 'if':
    case 'import':
    case 'in':
    case 'instanceof':
    case 'new':
    case 'return':
    case 'super':
    case 'switch':
    case 'this':
    case 'throw':
    case 'try':
    case 'typeof':
    case 'var':
    case 'void':
    case 'while':
    case 'with':
      return true;
    case 'arguments':
    case 'eval':
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    // http://www.ecma-international.org/ecma-262/6.0/#sec-identifiers-static-semantics-early-errors
    case 'implements':
    case 'interface':
    case 'let':
    case 'package':
    case 'private':
    case 'protected':
    case 'public':
    case 'static':
    case 'yield':
      return strictMode;
  }
  return false;
}

/// Returns true for names that cannot be set via `className.fieldName = ...`
/// on a JS class/constructor function.
///
/// These are getters on `Function.prototype` so we cannot set them but we can
/// define them on our object using `Object.defineProperty` or equivalent.
/// They are also valid as static getter/setter/method names if we use the JS
/// class syntax.
bool isFunctionPrototypeGetter(String name) {
  switch (name) {
    case 'arguments':
    case 'caller':
    case 'callee':
    case 'name':
    case 'length':
      return true;
  }
  return false;
}

/// See ES6 spec (and `Object.getOwnPropertyNames(Object.prototype)`):
///
/// http://www.ecma-international.org/ecma-262/6.0/#sec-properties-of-the-object-prototype-object
/// http://www.ecma-international.org/ecma-262/6.0/#sec-additional-properties-of-the-object.prototype-object
final objectProperties = <String>{
  'constructor',
  'toString',
  'toLocaleString',
  'valueOf',
  'hasOwnProperty',
  'isPrototypeOf',
  'propertyIsEnumerable',
  '__defineGetter__',
  '__lookupGetter__',
  '__defineSetter__',
  '__lookupSetter__',
  '__proto__'
};

/// Returns the JS member name for a public Dart instance member, before it
/// is symbolized; generally you should use [_emitMemberName] or
/// [_declareMemberName] instead of this.
String memberNameForDartMember(String name, [bool isExternal = false]) {
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
      // If [isExternal], assume the JS member is intended.
      return isExternal ? name : '_$name';
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

// Invalid characters for identifiers, which would need to be escaped.
final invalidCharInIdentifier = RegExp(r'[^A-Za-z_$0-9]');

/// Escape [name] to make it into a valid identifier.
String toJSIdentifier(String name) {
  if (name.isEmpty) return r'$';

  // Escape any invalid characters
  StringBuffer buffer;
  for (var i = 0; i < name.length; i++) {
    var ch = name[i];
    var needsEscape = ch == r'$' || invalidCharInIdentifier.hasMatch(ch);
    if (needsEscape && buffer == null) {
      buffer = StringBuffer(name.substring(0, i));
    }
    if (buffer != null) {
      buffer.write(needsEscape ? '\$${ch.codeUnits.join("")}' : ch);
    }
  }

  var result = buffer != null ? '$buffer' : name;
  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(RegExp('[0-9]')) || invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}
