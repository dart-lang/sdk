// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Code, Message, PlainAndColorizedString;
import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler;
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
        TreeNode,
        TypeParameter,
        VariableDeclaration,
        Visitor,
        VisitorNullMixin,
        VisitorVoidMixin;

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

/// Dart scope
///
/// Provides information about symbols available inside a dart scope.
class DartScope {
  final Library library;
  final Class? cls;
  final Member? member;
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
class DartScopeBuilder extends Visitor<void> with VisitorVoidMixin {
  final Component _component;
  final int _line;
  final int _column;

  Library? _library;
  Class? _cls;
  Member? _member;
  int _offset = -1;

  DiagnosticMessageHandler? onDiagnostic;

  final List<FunctionNode> _functions = [];
  final Map<String, DartType> _definitions = {};
  final List<TypeParameter> _typeParameters = [];

  DartScopeBuilder._(this._component, this._line, this._column);

  static DartScope? findScope(Component component, Library library, int line,
      int column, DiagnosticMessageHandler onDiagnostic) {
    var builder = DartScopeBuilder._(component, line, column)
      ..onDiagnostic = onDiagnostic;
    library.accept(builder);
    return builder.build();
  }

  DartScope? build() {
    if (_offset < 0 || _library == null) return null;

    return DartScope(_library!, _cls, _member, _definitions, _typeParameters);
  }

  @override
  void defaultTreeNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitLibrary(Library library) {
    _library = library;
    _offset = 0;
    if (_line > 0) {
      _offset = _component.getOffset(_library!.fileUri, _line, _column);
    }

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
    var name = decl.name;
    // Collect locals and formals appearing before current breakpoint.
    // Note that we include variables with no offset because the offset
    // is not set in many cases in generated code, so omitting them would
    // make expression evaluation fail in too many cases.
    // Issue: https://github.com/dart-lang/sdk/issues/43966
    //
    // A null name signals that the variable was synthetically introduced by the
    // compiler so they are skipped.
    if ((decl.fileOffset < 0 || decl.fileOffset < _offset) && name != null) {
      _definitions[name] = decl.type;
    }
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
class FileEndOffsetCalculator extends Visitor<int?> with VisitorNullMixin<int> {
  static const int noOffset = -1;

  final int _startOffset;
  final TreeNode _root;
  final TreeNode _original;

  int _endOffset = noOffset;

  /// Create calculator for a scoping node with no .fileEndOffset.
  ///
  /// [_root] is the parent of the scoping node.
  /// [_startOffset] is the start offset of the scoping node.
  FileEndOffsetCalculator._(this._root, this._original)
      : _startOffset = _original.fileOffset;

  /// Calculate file end offset for a scoping node.
  ///
  /// This calculator finds the first node in the ancestor chain that
  /// can give such information for a given [node], i.e. satisfies one
  /// of the following conditions:
  ///
  /// - a node with a greater start offset that is a child of the
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
      var calculator = FileEndOffsetCalculator._(n, node);
      var offset = n.accept(calculator);
      if (offset != noOffset) return offset!;
    }
    return noOffset;
  }

  @override
  int defaultTreeNode(TreeNode node) {
    if (node == _original) return _endOffset;
    if (node == _root) {
      node.visitChildren(this);
      if (_endOffset != noOffset) return _endOffset;
      return _endOffsetForNode(node);
    }
    // Skip synthesized variables as they could have offsets
    // from later code (in case they are hoisted, for example).
    if ((node is! VariableDeclaration || !node.isSynthesized) &&
        _endOffset == noOffset &&
        node.fileOffset > _startOffset) {
      _endOffset = node.fileOffset;
    }
    return _endOffset;
  }

  static int _endOffsetForNode(TreeNode node) {
    if (node is Class) return node.fileEndOffset;
    if (node is Constructor) return node.fileEndOffset;
    if (node is Procedure) return node.fileEndOffset;
    if (node is Field) return node.fileEndOffset;
    if (node is FunctionNode) return node.fileEndOffset;
    return noOffset;
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
