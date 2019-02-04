// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import '../compiler/js_metalet.dart' as JS;
import '../compiler/js_names.dart' as JS;
import '../compiler/js_utils.dart' as JS;
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;

/// Shared code between Analyzer and Kernel backends.
///
/// This class should only implement functionality that depends purely on JS
/// classes, rather than on Analyzer/Kernel types.
abstract class SharedCompiler<Library, Class> {
  /// When inside a `[]=` operator, this will be a non-null value that should be
  /// returned by any `return;` statement.
  ///
  /// This lets DDC use the setter method's return value directly.
  final List<JS.Identifier> _operatorSetResultStack = [];

  JS.Identifier runtimeModule;
  final namedArgumentTemp = JS.TemporaryId('opts');

  final _privateNames = HashMap<Library, HashMap<String, JS.TemporaryId>>();

  /// The list of output module items, in the order they need to be emitted in.
  final moduleItems = <JS.ModuleItem>[];

  /// When compiling the body of a `operator []=` method, this will be non-null
  /// and will indicate the the value that should be returned from any `return;`
  /// statements.
  JS.Identifier get _operatorSetResult {
    var stack = _operatorSetResultStack;
    return stack.isEmpty ? null : stack.last;
  }

  /// The import URI of current library.
  Uri get currentLibraryUri;

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
  JS.Statement runtimeStatement(String code, [args]) {
    return runtimeCall(code, args).toStatement();
  }

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
  /// `Function.prototype` already defins a getters with the same name.
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

  /// Whether any superclass of [c] defines a static [name].
  bool superclassHasStatic(Class c, String name);
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
