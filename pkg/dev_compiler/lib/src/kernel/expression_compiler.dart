// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Code, Message, PlainAndColorizedString;
import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler;
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/dart_scope_calculator.dart';

import '../compiler/js_names.dart' as js_ast;
import '../compiler/module_builder.dart';
import '../js_ast/js_ast.dart' as js_ast;
import 'compiler.dart' show ProgramCompiler;

DiagnosticMessage _createInternalError(Uri uri, int line, int col, String msg) {
  return Message(Code<String>('Expression Compiler Internal error'),
          problemMessage: msg)
      .withLocation(uri, 0, 0)
      .withFormatting(PlainAndColorizedString.plainOnly('Internal error: $msg'),
          line, col, Severity.internalProblem, []);
}

class ExpressionCompiler {
  static final String debugProcedureName = '\$dartEval';

  final CompilerContext _context;
  final CompilerOptions _options;
  final List<String> errors;
  final IncrementalCompiler _compiler;
  final ProgramCompiler _kernel2jsCompiler;
  final Component _component;
  final ModuleFormat _moduleFormat;

  DiagnosticMessageHandler onDiagnostic;

  void _log(String message) {
    if (_options.verbose) {
      _context.options.ticker.logMs(message);
    }
  }

  ExpressionCompiler(
    this._options,
    this._moduleFormat,
    this.errors,
    this._compiler,
    this._kernel2jsCompiler,
    this._component,
  )   : onDiagnostic = _options.onDiagnostic!,
        _context = _compiler.context;

  /// Compiles [expression] in [libraryUri] at [line]:[column] to JavaScript
  /// in [moduleName].
  ///
  /// [line] and [column] are 1-based.
  ///
  /// Values listed in [jsFrameValues] are substituted for their names in the
  /// [expression].
  ///
  /// Returns expression compiled to JavaScript or null on error.
  /// Errors are reported using onDiagnostic function.
  ///
  /// [jsFrameValues] is a map from js variable name to its primitive value
  /// or another variable name, for example
  /// { 'x': '1', 'y': 'y', 'o': 'null' }
  Future<String?> compileExpressionToJs(String libraryUri, int line, int column,
      Map<String, String> jsScope, String expression) async {
    try {
      // 1. find dart scope where debugger is paused

      _log('Compiling expression \n$expression');

      var dartScope = _findScopeAt(Uri.parse(libraryUri), line, column);
      if (dartScope == null) {
        _log('Scope not found at $libraryUri:$line:$column');
        return null;
      }
      _log('DartScope: $dartScope');

      // 2. perform necessary variable substitutions

      // TODO(annagrin): we only substitute for the same name or a value
      // currently, need to extend to cases where js variable names are
      // different from dart.
      // See [issue 40273](https://github.com/dart-lang/sdk/issues/40273)

      // remove undefined js variables (this allows us to get a reference error
      // from chrome on evaluation)
      dartScope.definitions
          .removeWhere((variable, type) => !jsScope.containsKey(variable));

      dartScope.typeParameters
          .removeWhere((parameter) => !jsScope.containsKey(parameter.name));

      // map from values from the stack when available (this allows to evaluate
      // captured variables optimized away in chrome)
      var localJsScope = [
        ...dartScope.typeParameters.map((parameter) => jsScope[parameter.name]),
        ...dartScope.definitions.keys.map((variable) => jsScope[variable])
      ];

      _log('Performed scope substitutions for expression');

      // 3. compile dart expression to JS

      var jsExpression = await _compileExpression(dartScope, expression);

      if (jsExpression == null) {
        _log('Failed to compile expression: \n$expression');
        return null;
      }

      // some adjustments to get proper binding to 'this',
      // making closure variables available, and catching errors

      // TODO(annagrin): make compiler produce correct expression:
      // See [issue 40277](https://github.com/dart-lang/sdk/issues/40277)
      // - evaluate to an expression in function and class context
      // - allow setting values
      // See [issue 40273](https://github.com/dart-lang/sdk/issues/40273)
      // - bind to proper 'this'
      // - map to correct js names for dart symbols

      // 4. create call the expression

      if (dartScope.cls != null && !dartScope.isStatic) {
        // bind to correct 'this' instead of 'globalThis'
        jsExpression = '$jsExpression.bind(this)';
      }

      // 5. wrap in a try/catch to catch errors

      var args = localJsScope.join(',\n    ');
      jsExpression = jsExpression.split('\n').join('\n  ');
      var callExpression = '\n  ($jsExpression('
          '\n    $args'
          '\n  ))';

      _log('Compiled expression \n$expression to $callExpression');
      return callExpression;
    } catch (e, s) {
      onDiagnostic(
          _createInternalError(Uri.parse(libraryUri), line, column, '$e:$s'));
      return null;
    }
  }

  DartScope? _findScopeAt(Uri libraryUri, int line, int column) {
    if (line < 0) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Invalid source location'));
      return null;
    }

    var library = _getLibrary(libraryUri);
    if (library == null) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Dart library not found for location'));
      return null;
    }

    var scope = DartScopeBuilder.findScope(_component, library, line, column);
    if (scope == null) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Dart scope not found for location'));
      return null;
    }

    _log('Detected expression compilation scope');
    return scope;
  }

  Library? _getLibrary(Uri libraryUri) {
    return _compiler.lookupLibrary(libraryUri);
  }

  /// Return a JS function that returns the evaluated results when called.
  ///
  /// [scope] current dart scope information.
  /// [expression] expression to compile in given [scope].
  Future<String?> _compileExpression(DartScope scope, String expression) async {
    var procedure = await _compiler.compileExpression(
        expression,
        scope.definitions,
        scope.typeParameters,
        debugProcedureName,
        scope.library.importUri,
        className: scope.cls?.name,
        isStatic: scope.isStatic);

    _log('Compiled expression to kernel');

    // TODO: make this code clear and assumptions enforceable
    // https://github.com/dart-lang/sdk/issues/43273
    if (errors.isNotEmpty) {
      return null;
    }

    var imports = <js_ast.ModuleItem>[];
    var jsFun = _kernel2jsCompiler.emitFunctionIncremental(imports,
        scope.library, scope.cls, procedure!.function, debugProcedureName);

    _log('Generated JavaScript for expression');

    // print JS ast to string for evaluation
    var context = js_ast.SimpleJavaScriptPrintingContext();
    var opts =
        js_ast.JavaScriptPrintingOptions(allowKeywordsInProperties: true);

    var tree = transformFunctionModuleFormat(imports, jsFun, _moduleFormat);
    tree.accept(
        js_ast.Printer(opts, context, localNamer: js_ast.TemporaryNamer(tree)));

    _log('Added imports and renamed variables for expression');

    return context.getText();
  }
}
