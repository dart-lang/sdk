// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler;

import 'package:_fe_analyzer_shared/src/messages/codes.dart' show Message, Code;

import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/js_ast/js_ast.dart' as js_ast;
import 'package:dev_compiler/src/kernel/compiler.dart';

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_unstable/ddc.dart';

import 'package:kernel/ast.dart'
    show
        Block,
        Class,
        Component,
        DartType,
        Field,
        FunctionNode,
        Library,
        Node,
        Procedure,
        PropertyGet,
        PropertySet,
        TypeParameter,
        VariableDeclaration,
        Visitor;

// TODO(annagrin): remove private fields
// See [issue 40272](https://github.com/dart-lang/sdk/issues/40272)

/// Provides information about symbols available inside a dart scope.
class DartScope {
  final Library library;
  final Class cls;
  final Procedure procedure;
  final Map<String, DartType> definitions;
  final List<TypeParameter> typeParameters;
  final Set<String> privateFields;

  DartScope(this.library, this.cls, this.procedure, this.definitions,
      this.typeParameters, this.privateFields);

  @override
  String toString() {
    return '''DartScope {
      Library = ${library.importUri},
      Class ${cls?.name},
      Procedure $procedure,
      isStatic ${procedure.isStatic},
      Scope: $definitions,
      typeParameters: $typeParameters,
      privateFields: $privateFields''';
  }
}

/// DartScopeBuilder finds dart scope information in
/// [component] on a given [line]:
/// library, class, locals, formals, and any other
/// avaiable symbols at that location.
/// TODO(annagrin): Refine scope detection
/// See [issue 40278](https://github.com/dart-lang/sdk/issues/40278)
class DartScopeBuilder extends Visitor<void> {
  final Component _component;
  Library _library;
  Class _cls;
  Procedure _procedure;
  final List<FunctionNode> _functions = [];
  final int _line;
  final Set<String> _privateFields = {};
  final Map<String, DartType> _definitions = {};
  final List<TypeParameter> _typeParameters = [];

  DartScopeBuilder(this._component, this._line);

  DartScope build() {
    if (_library == null || _procedure == null) return null;

    return DartScope(_library, _cls, _procedure, _definitions, _typeParameters,
        _privateFields);
  }

  @override
  void defaultNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitLibrary(Library library) {
    _library = library;

    super.visitLibrary(library);
  }

  @override
  void visitClass(Class cls) {
    if (_scopeContainsLine(cls.fileOffset, cls.fileEndOffset, _line)) {
      _cls = cls;
      _typeParameters.addAll(cls.typeParameters);

      super.visitClass(cls);
    }
  }

  @override
  void visitField(Field node) {
    if (node.name.isPrivate) {
      _privateFields.add(node.name.name);
    }
  }

  @override
  void visitFieldReference(Field node) {
    if (node.name.isPrivate) {
      _privateFields.add(node.name.name);
    }
  }

  @override
  void visitProcedure(Procedure p) {
    if (_scopeContainsLine(p.fileOffset, p.fileEndOffset, _line)) {
      _procedure = p;

      super.visitProcedure(p);
    }
  }

  @override
  void visitFunctionNode(FunctionNode fun) {
    if (_scopeContainsLine(fun.fileOffset, fun.fileEndOffset, _line)) {
      _collectDefinitions(fun);
      _typeParameters.addAll(fun.typeParameters);

      super.visitFunctionNode(fun);
    }
  }

  void _collectDefinitions(FunctionNode fun) {
    _functions.add(fun);

    // add formals
    for (var formal in fun.namedParameters) {
      _definitions[formal.name] = formal.type;
    }

    for (var formal in fun.positionalParameters) {
      _definitions[formal.name] = formal.type;
    }

    // add locals
    var body = fun.body;
    if (body is VariableDeclaration) {
      // local
      _definitions[body.name] = body.type;
    }
    if (body is Block) {
      for (var stmt in body.statements) {
        if (stmt is VariableDeclaration) {
          // local
          _definitions[stmt.name] = stmt.type;
        }
      }
    }
  }

  // TODO(annagrin): use offset instead of line to find containing scope
  // See [issue 40281](https://github.com/dart-lang/sdk/issues/40281)
  bool _scopeContainsLine(int startOffset, int endOffset, int line) {
    if (line < 0) return false;
    if (startOffset < 0) return false;

    var startLine = _getLine(startOffset);
    var endLine = _getLine(endOffset);

    return line >= startLine && line <= endLine;
  }

  int _getLine(int offset) {
    return _component.getLocation(_library.fileUri, offset).line;
  }
}

class PrivateFieldsVisitor extends Visitor<void> {
  final Set<String> _privateFields = {};

  Set<String> getPrivateFields() {
    return _privateFields;
  }

  @override
  void defaultNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitField(Field node) {
    if (node.name.isPrivate) {
      _privateFields.add(node.name.name);
    }
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    if (node.name.isPrivate) {
      _privateFields.add(node.name.name);
    }
  }

  @override
  void visitPropertySet(PropertySet node) {
    if (node.name.isPrivate) {
      _privateFields.add(node.name.name);
    }
  }
}

class ExpressionCompiler {
  static final String debugProcedureName = '\$dartEval';

  final bool verbose;
  final IncrementalCompiler _compiler;
  final ProgramCompiler _kernel2jsCompiler;
  final Component _component;
  DiagnosticMessageHandler onDiagnostic;

  void _log(String message) {
    if (verbose) {
      print(message);
    }
  }

  ExpressionCompiler(this._compiler, this._kernel2jsCompiler, this._component,
      {this.verbose, this.onDiagnostic});

  /// Compiles [expression] in [libraryUri] at [line]:[column] to JavaScript
  /// in [moduleName].
  ///
  /// Values listed in [jsFrameValues] are substituted for their names in the
  /// [expression].
  ///
  /// Ensures that all [jsModules] are loaded and accessible inside the
  /// expression.
  ///
  /// Returns expression compiled to JavaScript or null on error.
  /// Errors are reported using onDiagnostic function
  /// [moduleName] is of the form '/packages/hello_world_main.dart'
  /// [jsFrameValues] is a map from js variable name to its primitive value
  /// or another variable name, for example
  /// { 'x': '1', 'y': 'y', 'o': 'null' }
  /// [jsModules] is a map from variable name to the module name, where
  /// variable name is the name originally used in JavaScript to contain the
  /// module object, for example:
  /// { 'dart':'dart_sdk', 'main': '/packages/hello_world_main.dart' }
  Future<String> compileExpressionToJs(
      String libraryUri,
      int line,
      int column,
      Map<String, String> jsModules,
      Map<String, String> jsScope,
      String moduleName,
      String expression) async {
    // 1. find dart scope where debugger is paused

    _log('ExpressionCompiler: compiling:  $expression in $moduleName');

    var moduleVariable = moduleName.split('/').last;

    var dartScope = await _findScopeAt(Uri.parse(libraryUri), line, column);
    if (dartScope == null) {
      _log('ExpressionCompiler: scope not found at $libraryUri:$line:$column');
      return null;
    }

    // 2. perform necessary variable substitutions

    // TODO(annagrin): we only substitute for the same name or a value currently,
    // need to extend to cases where js variable names are different from dart
    // See [issue 40273](https://github.com/dart-lang/sdk/issues/40273)

    // remove undefined js variables (this allows us to get a reference error
    // from chrome on evaluation)
    dartScope.definitions
        .removeWhere((variable, type) => !jsScope.containsKey(variable));

    // map from values from the stack when available (this allows to evaluate
    // captured variables optimized away in chrome)
    var localJsScope =
        dartScope.definitions.keys.map((variable) => jsScope[variable]);

    _log('ExpressionCompiler: dart scope: $dartScope');
    _log('ExpressionCompiler: substituted local JsScope: $localJsScope');

    // 3. compile dart expression to JS

    var jsExpression = await _compileExpression(
        dartScope, jsModules, moduleVariable, expression);

    if (jsExpression == null) {
      _log('ExpressionCompiler: failed to compile $expression, $jsExpression');
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

    if (dartScope.cls != null && !dartScope.procedure.isStatic) {
      // bind to correct 'this' instead of 'globalThis'
      jsExpression = '$jsExpression.bind(this)';
    }

    // 5. wrap in a try/catch to catch errors

    var args = localJsScope.join(', ');
    var callExpression = '''
try {
($jsExpression(
$args
))
} catch (error) {
error.name + ": " + error.message;
}''';

    _log('ExpressionCompiler: compiled $expression to $callExpression');
    return callExpression;
  }

  Future<DartScope> _findScopeAt(Uri libraryUri, int line, int column) async {
    if (line < 0) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'invalid source location: $line, $column'));
      return null;
    }

    var library = await _getLibrary(libraryUri);
    if (library == null) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Dart library not found for location'));
      return null;
    }

    var builder = DartScopeBuilder(_component, line);
    library.accept(builder);
    var scope = builder.build();
    if (scope == null) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Dart scope not found for location'));
      return null;
    }

    return scope;
  }

  Future<Library> _getLibrary(Uri libraryUri) async {
    return await _compiler.context.runInContext((_) async {
      var builder = _compiler.userCode.loader.builders[libraryUri];
      var library =
          _compiler.userCode.loader.read(libraryUri, -1, accessor: builder);

      return library.library;
    });
  }

  /// Creates a stament to require a module to bring it back to scope
  /// example:
  /// let dart = require('dart_sdk').dart;
  js_ast.Statement _createRequireModuleStatement(
      String moduleName, String moduleVariable) {
    var variableName = moduleVariable.replaceFirst('.dart', '');
    var rhs = js_ast.PropertyAccess.field(
        js_ast.Call(js_ast.Identifier('require'),
            [js_ast.LiteralExpression('\'$moduleName\'')]),
        '$variableName');

    return rhs.toVariableDeclaration(js_ast.Identifier('$variableName'));
  }

  js_ast.Statement _createPrivateField(String field, String library) {
    var libraryName = library.replaceFirst('.dart', '');
    var rhs = js_ast.Call(
        js_ast.PropertyAccess.field(js_ast.Identifier('dart'), 'privateName'), [
      js_ast.LiteralExpression(libraryName),
      js_ast.LiteralExpression('"$field"')
    ]);

    // example:
    // let _f = dart.privateName(main, "_f");
    return rhs.toVariableDeclaration(js_ast.Identifier('$field'));
  }

  DiagnosticMessage _createInternalError(
      Uri uri, int line, int col, String msg) {
    return Message(Code<String>('Internal error', null), message: msg)
        .withLocation(uri, 0, 0)
        .withFormatting('', line, col, Severity.internalProblem, []);
  }

  /// Return a JS function that returns the evaluated results when called.
  ///
  /// [scope] current dart scope information
  /// [modules] map from module variable names to module names in JavaScript
  /// code. For example,
  /// { 'dart':'dart_sdk', 'main': '/packages/hello_world_main.dart' }
  /// [currentModule] current js module name.
  /// For example, in library package:hello_world/main.dart:
  /// '/packages/hello_world/main.dart'
  /// [expression] expression to compile in given [scope].
  Future<String> _compileExpression(
      DartScope scope,
      Map<String, String> modules,
      String currentModule,
      String expression) async {
    // 1. Compile expression to kernel AST

    var procedure = await _compiler.compileExpression(
        expression,
        scope.definitions,
        scope.typeParameters,
        debugProcedureName,
        scope.library.importUri,
        scope.cls?.name,
        scope.procedure.isStatic);

    if (_compiler.context.errors.length > 0) {
      return null;
    }

    _log('ExpressionCompiler: Kernel: ${procedure.leakingDebugToString()}');

    // 2. compile kernel AST to JS ast

    _kernel2jsCompiler.setIncrementalCompilationScope(scope.library, scope.cls);
    _kernel2jsCompiler.runtimeModule = js_ast.Identifier('dart');

    var jsFun = _kernel2jsCompiler.emitFunction(
        procedure.function, '$debugProcedureName');

    // 3. apply (hopefully temporary) workarounds for what ideally
    // need to be done in FE

    // Unused symbols are not captured inside functions, for example,
    // core.print is not available inside a top-level function foo()
    // if foo does not use anything from core.

    // get private fields accessed by the evaluated expression
    var fieldsCollector = PrivateFieldsVisitor();
    procedure.accept(fieldsCollector);
    var privateFields = fieldsCollector.getPrivateFields();
    privateFields
        .removeWhere((String name) => scope.privateFields.contains(name));

    var body = js_ast.Block([
      // require dart, core, self and other modules
      ...modules.keys.map((String variable) {
        return _createRequireModuleStatement(modules[variable], variable);
      }),
      // re-create private field accessors
      ...scope.privateFields
          .map((String v) => _createPrivateField(v, currentModule)),
      ...privateFields.map((String v) => _createPrivateField(v, currentModule)),
      // statements generated by the FE
      ...jsFun.body.statements
    ]);

    var jsFunModified = js_ast.Fun(jsFun.params, body);
    _log('ExpressionCompiler: JS AST: ${jsFunModified.toString()}');

    // 4. print JS ast to string for evaluation

    var context = js_ast.SimpleJavaScriptPrintingContext();
    var opts =
        js_ast.JavaScriptPrintingOptions(allowKeywordsInProperties: true);

    jsFunModified.accept(js_ast.Printer(opts, context));

    return context.getText();
  }
}
