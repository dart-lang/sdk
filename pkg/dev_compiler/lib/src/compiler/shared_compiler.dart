// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:meta/meta.dart';

import '../compiler/js_metalet.dart' as JS;
import '../compiler/js_names.dart' as JS;
import '../compiler/js_utils.dart' as JS;
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;

/// Shared code between Analyzer and Kernel backends.
///
/// This class should only implement functionality that depends purely on JS
/// classes, rather than on Analyzer/Kernel types.
abstract class SharedCompiler<Library, Class, InterfaceType, FunctionNode> {
  /// When inside a `[]=` operator, this will be a non-null value that should be
  /// returned by any `return;` statement.
  ///
  /// This lets DDC use the setter method's return value directly.
  final List<JS.Identifier> _operatorSetResultStack = [];

  /// The identifier used to reference DDC's core "dart:_runtime" library from
  /// generated JS code, typically called "dart" e.g. `dart.dcall`.
  @protected
  JS.Identifier runtimeModule;

  /// The temporary variable that stores named arguments (these are passed via a
  /// JS object literal, to match JS conventions).
  @protected
  final namedArgumentTemp = JS.TemporaryId('opts');

  final _privateNames = HashMap<Library, HashMap<String, JS.TemporaryId>>();

  /// The list of output module items, in the order they need to be emitted in.
  @protected
  final moduleItems = <JS.ModuleItem>[];

  /// Like [moduleItems] but for items that should be emitted after classes.
  ///
  /// This is used for deferred supertypes of mutually recursive non-generic
  /// classes.
  final afterClassDefItems = <JS.ModuleItem>[];

  /// The type used for private Dart [Symbol]s.
  @protected
  InterfaceType get privateSymbolType;

  /// The type used for public Dart [Symbol]s.
  @protected
  InterfaceType get internalSymbolType;

  @protected
  Library get currentLibrary;

  /// The import URI of current library.
  @protected
  Uri get currentLibraryUri;

  /// The current function being compiled, if any.
  @protected
  FunctionNode get currentFunction;

  /// Whether any superclass of [c] defines a static [name].
  @protected
  bool superclassHasStatic(Class c, String name);

  /// Emits the expression necessary to access a constructor of [type];
  @protected
  JS.Expression emitConstructorAccess(InterfaceType type);

  /// When compiling the body of a `operator []=` method, this will be non-null
  /// and will indicate the the value that should be returned from any `return;`
  /// statements.
  JS.Identifier get _operatorSetResult {
    var stack = _operatorSetResultStack;
    return stack.isEmpty ? null : stack.last;
  }

  /// Called when starting to emit methods/functions, in particular so we can
  /// implement special handling of the user-defined `[]=` and `==` methods.
  ///
  /// See also [exitFunction] and [emitReturnStatement].
  @protected
  void enterFunction(String name, List<JS.Parameter> formals,
      bool Function() isLastParamMutated) {
    if (name == '[]=') {
      _operatorSetResultStack.add(isLastParamMutated()
          ? JS.TemporaryId((formals.last as JS.Identifier).name)
          : formals.last);
    } else {
      _operatorSetResultStack.add(null);
    }
  }

  /// Called when finished emitting methods/functions, and must correspond to a
  /// previous [enterFunction] call.
  @protected
  JS.Block exitFunction(
      String name, List<JS.Parameter> formals, JS.Block code) {
    if (name == "==" &&
        formals.isNotEmpty &&
        currentLibraryUri.scheme != 'dart') {
      // In Dart `operator ==` methods are not called with a null argument.
      // This is handled before calling them. For performance reasons, we push
      // this check inside the method, to simplify our `equals` helper.
      //
      // TODO(jmesserly): in most cases this check is not necessary, because
      // the Dart code already handles it (typically by an `is` check).
      // Eliminate it when possible.
      code = js
          .block('{ if (# == null) return false; #; }', [formals.first, code]);
    }
    var setOperatorResult = _operatorSetResultStack.removeLast();
    if (setOperatorResult != null) {
      // []= methods need to return the value. We could also address this at
      // call sites, but it's less code size to handle inside the operator.
      var valueParam = formals.last;
      var statements = code.statements;
      if (statements.isEmpty || !statements.last.alwaysReturns) {
        statements.add(JS.Return(setOperatorResult));
      }
      if (!identical(setOperatorResult, valueParam)) {
        // If the value parameter was mutated, then we use a temporary
        // variable to track the initial value
        formals.last = setOperatorResult;
        code = js
            .block('{ let # = #; #; }', [valueParam, setOperatorResult, code]);
      }
    }
    return code;
  }

  /// Emits a return statement `return <value>;`, handling special rules for
  /// the `operator []=` method.
  @protected
  JS.Statement emitReturnStatement(JS.Expression value) {
    if (_operatorSetResult != null) {
      var result = JS.Return(_operatorSetResult);
      return value != null ? JS.Block([value.toStatement(), result]) : result;
    }
    return value != null ? value.toReturn() : JS.Return();
  }

  /// Prepends the `dart.` and then uses [js.call] to parse the specified JS
  /// [code] template, passing [args].
  ///
  /// For example:
  ///
  ///     runtimeCall('asInt(#)', expr)
  ///
  /// Generates a JS AST representing:
  ///
  ///     dart.asInt(<expr>)
  ///
  @protected
  JS.Expression runtimeCall(String code, [args]) {
    if (args != null) {
      var newArgs = <Object>[runtimeModule];
      if (args is Iterable) {
        newArgs.addAll(args);
      } else {
        newArgs.add(args);
      }
      args = newArgs;
    } else {
      args = runtimeModule;
    }
    return js.call('#.$code', args);
  }

  /// Calls [runtimeCall] and uses `toStatement()` to convert the resulting
  /// expression into a statement.
  @protected
  JS.Statement runtimeStatement(String code, [args]) {
    return runtimeCall(code, args).toStatement();
  }

  /// Emits a private name JS Symbol for [name] scoped to the Dart [library].
  ///
  /// If the same name is used in multiple libraries in the same module,
  /// distinct symbols will be used, so the names cannot be referenced outside
  /// of their library.
  @protected
  JS.TemporaryId emitPrivateNameSymbol(Library library, String name) {
    return _privateNames.putIfAbsent(library, () => HashMap()).putIfAbsent(name,
        () {
      var idName = name;
      if (idName.endsWith('=')) {
        idName = idName.replaceAll('=', '_');
      }
      var id = JS.TemporaryId(idName);
      moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(name, "'")]));
      return id;
    });
  }

  /// Emits an expression to set the property [nameExpr] on the class [className],
  /// with [value].
  ///
  /// This will use `className.name = value` if possible, otherwise it will use
  /// `dart.defineValue(className, name, value)`. This is required when
  /// `FunctionNode.prototype` already defins a getters with the same name.
  @protected
  JS.Expression defineValueOnClass(Class c, JS.Expression className,
      JS.Expression nameExpr, JS.Expression value) {
    var args = [className, nameExpr, value];
    if (nameExpr is JS.LiteralString) {
      var name = nameExpr.valueWithoutQuotes;
      if (JS.isFunctionPrototypeGetter(name) || superclassHasStatic(c, name)) {
        return runtimeCall('defineValue(#, #, #)', args);
      }
    }
    return js.call('#.# = #', args);
  }

  /// Caches a constant (list/set/map or class instance) in a variable, so it's
  /// only canonicalized once at this location in the code, which improves
  /// performance.
  ///
  /// This method ensures the constant is not initialized until use.
  ///
  /// The expression [jsExpr] should contain the already-canonicalized constant.
  /// If the constant is not canonicalized yet, it should be wrapped in the
  /// appropriate call, such as:
  ///
  /// - dart.constList (for Lists),
  /// - dart.constMap (for Maps),
  /// - dart.constSet (for Sets),
  /// - dart.const (for other instances of classes)
  ///
  /// [canonicalizeConstObject] can be used for class instances; it will wrap
  /// the expression in `dart.const` and then call this method.
  ///
  /// If the same consant is used elsewhere (in this module, or another module),
  /// that will require a second canonicalization. In general it is uncommon
  /// to define the same large constant (such as lists, maps) in different
  /// locations, because that requires copy+paste, so in practice this
  /// optimization is rather effective (we should consider caching once
  /// per-module, though, as that would be relatively easy for the compiler to
  /// implement once we have a single Kernel backend).
  @protected
  JS.Expression cacheConst(JS.Expression jsExpr) {
    if (currentFunction == null) return jsExpr;

    var temp = JS.TemporaryId('const');
    moduleItems.add(js.statement('let #;', [temp]));
    return js.call('# || (# = #)', [temp, temp, jsExpr]);
  }

  /// Emits a Dart Symbol with the given member [symbolName].
  ///
  /// If the symbol refers to a private name, its library will be set to the
  /// [currentLibrary], so the Symbol is scoped properly.
  @protected
  JS.Expression emitDartSymbol(String symbolName) {
    // TODO(vsm): Handle qualified symbols correctly.
    var last = symbolName.split('.').last;
    var name = js.escapedString(symbolName, "'");
    JS.Expression result;
    if (last.startsWith('_')) {
      var nativeSymbol = emitPrivateNameSymbol(currentLibrary, last);
      result = js.call('new #.new(#, #)',
          [emitConstructorAccess(privateSymbolType), name, nativeSymbol]);
    } else {
      result = js.call(
          'new #.new(#)', [emitConstructorAccess(internalSymbolType), name]);
    }
    return canonicalizeConstObject(result);
  }

  /// Calls the `dart.const` function in "dart:_runtime" to canonicalize a
  /// constant instance of a user-defined class stored in [expr].
  @protected
  JS.Expression canonicalizeConstObject(JS.Expression expr) =>
      cacheConst(runtimeCall('const(#)', expr));
}

/// Whether a variable with [name] is referenced in the [node].
bool variableIsReferenced(String name, JS.Node node) {
  var finder = _IdentifierFinder.instance;
  finder.nameToFind = name;
  finder.found = false;
  node.accept(finder);
  return finder.found;
}

class _IdentifierFinder extends JS.BaseVisitor<void> {
  String nameToFind;
  bool found = false;

  static final instance = _IdentifierFinder();

  visitIdentifier(node) {
    if (node.name == nameToFind) found = true;
  }

  visitNode(node) {
    if (!found) super.visitNode(node);
  }
}

class YieldFinder extends JS.BaseVisitor {
  bool hasYield = false;
  bool hasThis = false;
  bool _nestedFunction = false;

  @override
  visitThis(JS.This node) {
    hasThis = true;
  }

  @override
  visitFunctionExpression(JS.FunctionExpression node) {
    var savedNested = _nestedFunction;
    _nestedFunction = true;
    super.visitFunctionExpression(node);
    _nestedFunction = savedNested;
  }

  @override
  visitYield(JS.Yield node) {
    if (!_nestedFunction) hasYield = true;
    super.visitYield(node);
  }

  @override
  visitNode(JS.Node node) {
    if (hasYield && hasThis) return; // found both, nothing more to do.
    super.visitNode(node);
  }
}
