// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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
        Constructor,
        DartType,
        Field,
        FunctionNode,
        Library,
        Member,
        Node,
        Procedure,
        PropertyGet,
        PropertySet,
        RedirectingFactoryConstructor,
        TreeNode,
        TypeParameter,
        VariableDeclaration,
        Visitor;

DiagnosticMessage _createInternalError(Uri uri, int line, int col, String msg) {
  return Message(Code<String>('Expression Compiler Internal error'),
          message: msg)
      .withLocation(uri, 0, 0)
      .withFormatting(
          'Internal error: $msg', line, col, Severity.internalProblem, []);
}

/// Dart scope
///
/// Provides information about symbols available inside a dart scope.
class DartScope {
  final Library library;
  final Class cls;
  final Member member;
  final bool isStatic;
  final Map<String, DartType> definitions;
  final List<TypeParameter> typeParameters;

  DartScope(this.library, this.cls, this.member, this.definitions,
      this.typeParameters)
      : isStatic = member is Procedure ? member.isStatic : false;

  @override
  String toString() {
    return '''DartScope {
      Library: ${library.importUri},
      Class: ${cls?.name},
      Procedure: $member,
      isStatic: $isStatic,
      Scope: $definitions,
      typeParameters: $typeParameters
    }
    ''';
  }
}

/// DartScopeBuilder finds dart scope information for a location.
///
/// Find all definitions in scope at a given 1-based [line] and [column]:
///
/// - library
/// - class
/// - locals
/// - formals
/// - captured variables (for closures)
class DartScopeBuilder extends Visitor<void> {
  final Component _component;
  final int _line;
  final int _column;

  Library _library;
  Class _cls;
  Member _member;
  int _offset;

  DiagnosticMessageHandler onDiagnostic;

  final List<FunctionNode> _functions = [];
  final Map<String, DartType> _definitions = {};
  final List<TypeParameter> _typeParameters = [];

  DartScopeBuilder._(this._component, this._line, this._column);

  static DartScope findScope(Component component, Library library, int line,
      int column, DiagnosticMessageHandler onDiagnostic) {
    var builder = DartScopeBuilder._(component, line, column)
      ..onDiagnostic = onDiagnostic;
    library.accept(builder);
    return builder.build();
  }

  DartScope build() {
    if (_offset == null || _library == null || _member == null) return null;

    return DartScope(_library, _cls, _member, _definitions, _typeParameters);
  }

  @override
  void defaultTreeNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitLibrary(Library library) {
    _library = library;
    _offset = _component.getOffset(_library.fileUri, _line, _column);

    // Exit early if the evaluation offset is not found.
    // Note: the complete scope is not found in this case,
    // so the expression compiler will report an error.
    if (_offset >= 0) super.visitLibrary(library);
  }

  @override
  void visitClass(Class cls) {
    if (_scopeContainsOffset(cls.fileOffset, cls.fileEndOffset, _offset)) {
      _cls = cls;
      _typeParameters.addAll(cls.typeParameters);

      super.visitClass(cls);
    }
  }

  @override
  void defaultMember(Member m) {
    if (_scopeContainsOffset(m.fileOffset, m.fileEndOffset, _offset)) {
      _member = m;

      super.defaultMember(m);
    }
  }

  @override
  void visitFunctionNode(FunctionNode fun) {
    if (_scopeContainsOffset(fun.fileOffset, fun.fileEndOffset, _offset)) {
      _functions.add(fun);
      _typeParameters.addAll(fun.typeParameters);

      super.visitFunctionNode(fun);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration decl) {
    // collect locals and formals
    _definitions[decl.name] = decl.type;
    super.visitVariableDeclaration(decl);
  }

  @override
  void visitBlock(Block block) {
    var fileEndOffset = FileEndOffsetCalculator.calculateEndOffset(block);
    if (_scopeContainsOffset(block.fileOffset, fileEndOffset, _offset)) {
      super.visitBlock(block);
    }
  }

  bool _scopeContainsOffset(int startOffset, int endOffset, int offset) {
    if (offset < 0 || startOffset < 0 || endOffset < 0) {
      return false;
    }
    return startOffset <= offset && offset <= endOffset;
  }
}

/// File end offset calculator.
///
/// Helps calculate file end offsets for nodes with internal scope
/// that do not have .fileEndOffset field.
///
/// For example - [Block]
class FileEndOffsetCalculator extends Visitor<int> {
  static const int noOffset = -1;

  final int _startOffset;
  final TreeNode _root;

  int _endOffset = noOffset;

  /// Create calculator for a scoping node with no .fileEndOffset.
  ///
  /// [_root] is the parent of the scoping node.
  /// [_startOffset] is the start offset of the scoping node.
  FileEndOffsetCalculator._(this._root, this._startOffset);

  /// Calculate file end offset for a scoping node.
  ///
  /// This calculator finds the first node in the ancestor chain that
  /// can give such information for a given [node], i.e. satisfies one
  /// of the following conditions:
  ///
  /// - a node with with a greater start offset that is a child of the
  ///   closest ancestor. The start offset of this child is used as a
  ///   file end offset of the [node].
  ///
  /// - the closest ancestor with .fileEndOffset information. The file
  ///   end offset of the ancestor is used as the file end offset of
  ///   the [node.]
  ///
  /// If none found, return [noOffset].
  static int calculateEndOffset(TreeNode node) {
    for (var n = node.parent; n != null; n = n.parent) {
      var calculator = FileEndOffsetCalculator._(n, node.fileOffset);
      var offset = n.accept(calculator);
      if (offset != noOffset) return offset;
    }
    return noOffset;
  }

  @override
  int defaultTreeNode(TreeNode node) {
    if (node == _root) {
      node.visitChildren(this);
      if (_endOffset != noOffset) return _endOffset;
      return _endOffsetForNode(node);
    }
    if (_endOffset == noOffset && node.fileOffset > _startOffset) {
      _endOffset = node.fileOffset;
    }
    return _endOffset;
  }

  static int _endOffsetForNode(TreeNode node) {
    if (node is Class) return node.fileEndOffset;
    if (node is Constructor) return node.fileEndOffset;
    if (node is Procedure) return node.fileEndOffset;
    if (node is Field) return node.fileEndOffset;
    if (node is RedirectingFactoryConstructor) return node.fileEndOffset;
    if (node is FunctionNode) return node.fileEndOffset;
    return noOffset;
  }
}

/// Collect private fields and libraries used in expression.
///
/// Used during expression evaluation to find symbols
/// for private fields. The symbols are used in the ddc
/// compilation of the expression, are not always avalable
/// in the JavaScript scope, so we need to redefine them.
///
/// See [_addSymbolDefinitions]
class PrivateFieldsVisitor extends Visitor<void> {
  final Map<String, Library> privateFields = {};

  @override
  void defaultNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitFieldReference(Field node) {
    if (node.name.isPrivate && !node.isStatic) {
      privateFields[node.name.text] = node.enclosingLibrary;
    }
  }

  @override
  void visitField(Field node) {
    if (node.name.isPrivate && !node.isStatic) {
      privateFields[node.name.text] = node.enclosingLibrary;
    }
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    var member = node.interfaceTarget;
    if (node.name.isPrivate && member != null && member.isInstanceMember) {
      privateFields[node.name.text] = node.interfaceTarget?.enclosingLibrary;
    }
  }

  @override
  void visitPropertySet(PropertySet node) {
    var member = node.interfaceTarget;
    if (node.name.isPrivate && member != null && member.isInstanceMember) {
      privateFields[node.name.text] = node.interfaceTarget?.enclosingLibrary;
    }
  }
}

class ExpressionCompiler {
  static final String debugProcedureName = '\$dartEval';

  final CompilerContext _context;
  final CompilerOptions _options;
  final List<String> errors;
  final IncrementalCompiler _compiler;
  final ProgramCompiler _kernel2jsCompiler;
  final Component _component;

  DiagnosticMessageHandler onDiagnostic;

  void _log(String message) {
    if (_options.verbose) {
      _context.options.ticker.logMs(message);
    }
  }

  ExpressionCompiler(
    this._options,
    this.errors,
    this._compiler,
    this._kernel2jsCompiler,
    this._component,
  )   : onDiagnostic = _options.onDiagnostic,
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
  Future<String> compileExpressionToJs(String libraryUri, int line, int column,
      Map<String, String> jsScope, String expression) async {
    try {
      // 1. find dart scope where debugger is paused

      _log('Compiling expression \n$expression');

      var dartScope = await _findScopeAt(Uri.parse(libraryUri), line, column);
      if (dartScope == null) {
        _log('Scope not found at $libraryUri:$line:$column');
        return null;
      }

      // 2. perform necessary variable substitutions

      // TODO(annagrin): we only substitute for the same name or a value
      // currently, need to extend to cases where js variable names are
      // different from dart.
      // See [issue 40273](https://github.com/dart-lang/sdk/issues/40273)

      // remove undefined js variables (this allows us to get a reference error
      // from chrome on evaluation)
      dartScope.definitions
          .removeWhere((variable, type) => !jsScope.containsKey(variable));

      // map from values from the stack when available (this allows to evaluate
      // captured variables optimized away in chrome)
      var localJsScope =
          dartScope.definitions.keys.map((variable) => jsScope[variable]);

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
      var callExpression = '\ntry {'
          '\n  ($jsExpression('
          '\n    $args'
          '\n  ))'
          '\n} catch (error) {'
          '\n  error.name + ": " + error.message;'
          '\n}';

      _log('Compiled expression \n$expression to $callExpression');
      return callExpression;
    } catch (e, s) {
      onDiagnostic(
          _createInternalError(Uri.parse(libraryUri), line, column, '$e:$s'));
      return null;
    }
  }

  Future<DartScope> _findScopeAt(Uri libraryUri, int line, int column) async {
    if (line < 0) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Invalid source location'));
      return null;
    }

    var library = await _getLibrary(libraryUri);
    if (library == null) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Dart library not found for location'));
      return null;
    }

    var scope = DartScopeBuilder.findScope(
        _component, library, line, column, onDiagnostic);
    if (scope == null) {
      onDiagnostic(_createInternalError(
          libraryUri, line, column, 'Dart scope not found for location'));
      return null;
    }

    _log('Detected expression compilation scope');
    return scope;
  }

  Future<Library> _getLibrary(Uri libraryUri) async {
    return await _compiler.context.runInContext((_) async {
      var builder = _compiler.userCode.loader.builders[libraryUri];
      if (builder != null) {
        var library =
            _compiler.userCode.loader.read(libraryUri, -1, accessor: builder);

        return library.library;
      }

      _log('Loaded library for expression');
      return null;
    });
  }

  /// Return a JS function that returns the evaluated results when called.
  ///
  /// [scope] current dart scope information.
  /// [expression] expression to compile in given [scope].
  Future<String> _compileExpression(DartScope scope, String expression) async {
    var procedure = await _compiler.compileExpression(
        expression,
        scope.definitions,
        scope.typeParameters,
        debugProcedureName,
        scope.library.importUri,
        scope.cls?.name,
        scope.isStatic);

    _log('Compiled expression to kernel');

    // TODO: make this code clear and assumptions enforceable
    // https://github.com/dart-lang/sdk/issues/43273
    //
    // We assume here that ExpressionCompiler is always created using
    // onDisgnostic method that adds to the error list that is passed
    // to the same invocation of the ExpressionCompiler constructor.
    // We only use the error list once - below, to detect if the frontend
    // compilation of the expression has failed.
    if (errors.isNotEmpty) {
      return null;
    }

    var jsFun = _kernel2jsCompiler.emitFunctionIncremental(
        scope.library, scope.cls, procedure.function, '$debugProcedureName');

    _log('Generated JavaScript for expression');

    var jsFunModified = _addSymbolDefinitions(procedure, jsFun, scope);

    _log('Added symbol definitions to JavaScript');

    // print JS ast to string for evaluation

    var context = js_ast.SimpleJavaScriptPrintingContext();
    var opts =
        js_ast.JavaScriptPrintingOptions(allowKeywordsInProperties: true);

    jsFunModified.accept(js_ast.Printer(opts, context));
    _log('Performed JavaScript adjustments for expression');

    return context.getText();
  }

  /// Add symbol definitions for all symbols in compiled expression
  ///
  /// Example:
  ///
  ///   compilation of this._field from library 'main'
  ///
  /// Symbol definition:
  ///
  ///   let _f = dart.privateName(main, "_f");
  ///
  /// Expression generated by ddc:
  ///
  ///   this[_f]
  ///
  /// TODO: this is a temporary workaround to make JavaScript produced
  /// by the ProgramCompiler self-contained.
  /// Issue: https://github.com/dart-lang/sdk/issues/41480
  js_ast.Fun _addSymbolDefinitions(
      Procedure procedure, js_ast.Fun jsFun, DartScope scope) {
    // get private fields accessed by the evaluated expression
    var fieldsCollector = PrivateFieldsVisitor();
    procedure.accept(fieldsCollector);
    var privateFields = fieldsCollector.privateFields;

    // collect library names where private symbols are defined
    var libraryForField = privateFields.map((field, library) =>
        MapEntry(field, _kernel2jsCompiler.emitLibraryName(library).name));

    var body = js_ast.Block([
      // re-create private field accessors
      ...libraryForField.keys.map(
          (String field) => _createPrivateField(field, libraryForField[field])),
      // statements generated by the FE
      ...jsFun.body.statements
    ]);
    return js_ast.Fun(jsFun.params, body);
  }

  /// Creates a private symbol definition
  ///
  /// example:
  /// let _f = dart.privateName(main, "_f");
  js_ast.Statement _createPrivateField(String field, String library) {
    return js_ast.js.statement('let # = dart.privateName(#, #)',
        [field, library, js_ast.js.string(field)]);
  }
}
