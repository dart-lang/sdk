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

  /// Compiles [expression] in library [libraryUri] and file [scriptUri]
  /// at [line]:[column] to JavaScript in [moduleName].
  ///
  /// [libraryUri] and [scriptUri] can be the same, but if for instance
  /// evaluating expressions in a part file the [libraryUri] will be the uri of
  /// the "part of" file whereas [scriptUri] will be the uri of the part.
  ///
  /// [line] and [column] are 1-based. Library level expressions typically use
  /// [line] and [column] 1 as an indicator that there is no relevant location.
  /// For flexibility, a value of 0 is also accepted and recognized
  /// in the same way.
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
  Future<String?> compileExpressionToJs(
      String libraryUri,
      String? scriptUri,
      int line,
      int column,
      Map<String, String> jsScope,
      String expression) async {
    try {
      // 1. find dart scope where debugger is paused

      _log('Compiling expression \n$expression');

      var dartScope = _findScopeAt(Uri.parse(libraryUri),
          scriptUri == null ? null : Uri.parse(scriptUri), line, column);
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
      dartScope.definitions.removeWhere((variable, type) =>
          !jsScope.containsKey(_dartNameToJsName(variable)));

      dartScope.typeParameters
          .removeWhere((parameter) => !jsScope.containsKey(parameter.name));

      // map from values from the stack when available (this allows to evaluate
      // captured variables optimized away in chrome)
      var localJsScope = [
        ...dartScope.typeParameters.map((parameter) => jsScope[parameter.name]),
        ...dartScope.definitions.keys
            .map((variable) => jsScope[_dartNameToJsName(variable)])
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

  String? _dartNameToJsName(String? dartName) {
    if (dartName == null) return dartName;
    if (isExtensionThisName(dartName)) return r'$this';
    return dartName;
  }

  DartScope? _findScopeAt(
      Uri libraryUri, Uri? scriptFileUri, int line, int column) {
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

    // TODO(jensj): Eventually make the scriptUri required and always use this,
    // but for now use the old mechanism when no script is provided.
    if (scriptFileUri != null) {
      final offset = _component.getOffset(library.fileUri, line, column);
      final scope2 =
          DartScopeBuilder2.findScopeFromOffset(library, scriptFileUri, offset);
      return scope2;
    }

    var scope = DartScopeBuilder.findScope(_component, library, line, column);
    if (scope == null) {
      // Fallback mechanism to allow a evaluation of an expression at the
      // library level within the Dart SDK.
      //
      // Currently we lack the full dill and metadata for the Dart SDK module to
      // be able to use the same mechanism of expression evaluation as the rest
      // of a program. Because of that, expression evaluation at arbitrary
      // scopes is not supported in the Dart SDK. However, we can still support
      // compiling expressions that will be evaluated at the library level. We
      // determine if that's the case by recognizing that all such requests use
      // line 1 and column 1.
      if (line <= 1 && column <= 1 && library.importUri.isScheme('dart')) {
        _log('Fallback: use library scope for the Dart SDK');
        scope = DartScope(library, null, null, {}, []);
      } else {
        onDiagnostic(_createInternalError(
            libraryUri, line, column, 'Dart scope not found for location'));
        return null;
      }
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
    var methodName = scope.member?.name.text;
    var member = scope.member;
    if (member != null) {
      if (member.isExtensionMember || member.isExtensionTypeMember) {
        methodName = extractQualifiedNameFromExtensionMethodName(methodName);
      }
    }
    var procedure = await _compiler.compileExpression(
        expression,
        scope.definitions,
        scope.typeParameters,
        debugProcedureName,
        scope.library.importUri,
        methodName: methodName,
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
