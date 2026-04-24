// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/debugging/dart_scope.dart';
import 'package:dwds/src/debugging/debugger.dart';
import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/debugging/modules.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/services/javascript_builder.dart';
import 'package:dwds/src/utilities/conversions.dart';
import 'package:dwds/src/utilities/objects.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

class EvaluationErrorKind {
  EvaluationErrorKind._();

  static const compilation = 'CompilationError';
  static const type = 'TypeError';
  static const reference = 'ReferenceError';
  static const internal = 'InternalError';
  static const asyncFrame = 'AsyncFrameError';
  static const invalidInput = 'InvalidInputError';
  static const loadModule = 'LoadModuleError';
}

/// ExpressionEvaluator provides functionality to evaluate dart expressions
/// from text user input in the debugger, using chrome remote debugger to
/// collect context for evaluation (scope, types, modules), and using
/// ExpressionCompilerInterface to compile dart expressions to JavaScript.
class ExpressionEvaluator {
  final String _entrypoint;
  final ChromeAppInspector _inspector;
  final Debugger _debugger;
  final Locations _locations;
  final Modules _modules;
  final ExpressionCompiler _compiler;
  final _logger = Logger('ExpressionEvaluator');
  bool _closed = false;

  /// Strip synthetic library name from compiler error messages.
  static final _syntheticNameFilterRegex = RegExp(
    'org-dartlang-debug:synthetic_debug_expression:.*:.*Error: ',
  );

  /// Find module path from the XHR call network error message received from
  /// chrome.
  ///
  /// Example:
  /// NetworkError: Failed to load `http://<hostname>.com/path/to/module.js?<cache_busting_token>`
  static final _loadModuleErrorRegex = RegExp(
    r".*Failed to load '.*\.com/(.*\.js).*",
  );

  ExpressionEvaluator(
    this._entrypoint,
    this._inspector,
    this._debugger,
    this._locations,
    this._modules,
    this._compiler,
  );

  /// Create and error with [severity] and [message]
  ///
  /// [severity] is one of kinds in [EvaluationErrorKind]
  RemoteObject createError(String severity, String message) {
    return RemoteObject(<String, String>{'type': severity, 'value': message});
  }

  void close() {
    _closed = true;
  }

  /// Evaluate dart expression inside a given library.
  ///
  /// Uses ExpressionCompiler interface to compile the expression to
  /// JavaScript and sends evaluate requests to chrome to calculate
  /// the final result.
  ///
  /// Returns remote object containing the result of evaluation or error.
  ///
  /// [isolateId] current isolate ID.
  /// [libraryUri] dart library to evaluate the expression in.
  /// [expression] dart expression to evaluate.
  Future<RemoteObject> evaluateExpression(
    String isolateId,
    String? libraryUri,
    String expression,
    Map<String, String>? scope,
  ) async {
    if (_closed) {
      return createError(
        EvaluationErrorKind.internal,
        'expression evaluator closed.',
      );
    }

    scope ??= {};

    if (expression.isEmpty) {
      return createError(EvaluationErrorKind.invalidInput, expression);
    }

    if (libraryUri == null) {
      return createError(EvaluationErrorKind.invalidInput, 'no library uri');
    }

    final module = await _modules.moduleForLibrary(libraryUri);
    if (module == null) {
      return createError(
        EvaluationErrorKind.internal,
        'no module for $libraryUri',
      );
    }

    // Wrap the expression in a lambda so we can call it as a function.
    expression = _createDartLambda(expression, scope.keys);
    _logger.finest('Evaluating "$expression" at $module');

    // Compile expression using an expression compiler, such as
    // frontend server or expression compiler worker.
    final compilationResult = await _compiler.compileExpressionToJs(
      isolateId,
      libraryUri.toString(),
      // Evaluating at "the library level" (and passing line 0 column 0) we'll
      // also just pass the library uri as the script uri.
      libraryUri.toString(),
      0,
      0,
      {},
      {},
      module,
      expression,
    );

    final isError = compilationResult.isError;
    final jsResult = compilationResult.result;
    if (isError) {
      return _formatCompilationError(jsResult);
    }

    // Strip try/catch incorrectly added by the expression compiler.
    final jsCode = _maybeStripTryCatch(jsResult);

    // Send JS expression to chrome to evaluate.
    var result = await _callJsFunction(jsCode, scope);
    result = await _formatEvaluationError(result);

    _logger.finest('Evaluated "$expression" to "${result.json}"');
    return result;
  }

  /// Evaluate dart expression inside a given frame (function).
  ///
  /// Gets necessary context (types, scope, module names) data from chrome,
  /// uses ExpressionCompiler interface to compile the expression to
  /// JavaScript, and sends evaluate requests to chrome to calculate the
  /// final result.
  ///
  /// Returns remote object containing the result of evaluation or error.
  ///
  /// [isolateId] current isolate ID.
  /// [frameIndex] JavaScript frame to evaluate the expression in.
  /// [expression] dart expression to evaluate.
  /// [scope] additional scope to use in the expression as a map from
  ///   variable names to remote object IDs.
  ///
  /////////////////////////////////
  /// **Example - without scope**
  ///
  /// To evaluate a dart expression `e`, we perform the following:
  ///
  /// 1. compile dart expression `e` to JavaScript expression `jsExpr`
  ///    using the expression compiler (i.e. frontend server or expression
  ///    compiler worker).
  ///
  /// 2. create JavaScript wrapper expression, `jsWrapperExpr`, defined as
  ///
  ///    ```JavaScript
  ///    try {
  ///      jsExpr;
  ///    } catch (error) {
  ///      error.name + ": " + error.message;
  ///    }
  ///    ```
  ///
  /// 3. evaluate `JsExpr` using `Debugger.evaluateOnCallFrame` chrome API.
  ///
  /// //////////////////////////
  /// **Example - with scope**
  ///
  /// To evaluate a dart expression
  /// ```dart
  ///   this.t + a + x + y
  /// ```
  /// in a dart scope that defines `a` and `this`, and additional scope
  /// `x, y`, we perform the following:
  ///
  /// 1. compile dart function
  ///
  ///    ```dart
  ///    (x, y, a) { return this.t + a + x + y; }
  ///    ```
  ///
  ///    to JavaScript function
  ///
  ///    ```jsFunc```
  ///
  ///    using the expression compiler (i.e. frontend server or expression
  ///    compiler worker).
  ///
  /// 2. create JavaScript wrapper function, `jsWrapperFunc`, defined as
  ///
  ///    ```JavaScript
  ///    function (x, y, a, __t$this) {
  ///      try {
  ///        return function (x, y, a) {
  ///          return jsFunc(x, y, a);
  ///        }.bind(__t$this)(x, y, a);
  ///      } catch (error) {
  ///        return error.name + ": " + error.message;
  ///      }
  ///    }
  ///    ```
  ///
  /// 3. collect scope variable object IDs for total scope
  ///    (original frame scope from WipCallFrame + additional scope passed
  ///    by the user).
  ///
  /// 4. call `jsWrapperFunc` using `Runtime.callFunctionOn` chrome API
  ///    with scope variable object IDs passed as arguments.
  Future<RemoteObject> evaluateExpressionInFrame(
    String isolateId,
    int frameIndex,
    String expression,
    Map<String, String>? scope,
  ) async {
    scope ??= {};

    if (expression.isEmpty) {
      return createError(EvaluationErrorKind.invalidInput, expression);
    }

    // Get JS scope and current JS location.
    final jsFrame = _debugger.jsFrameForIndex(frameIndex);
    if (jsFrame == null) {
      return createError(
        EvaluationErrorKind.asyncFrame,
        'Expression evaluation in async frames '
        'is not supported. No frame with index $frameIndex.',
      );
    }

    final functionName = jsFrame.functionName;
    final jsLine = jsFrame.location.lineNumber;
    final jsScriptId = jsFrame.location.scriptId;
    final jsColumn = jsFrame.location.columnNumber;
    final frameScope = await _collectLocalFrameScope(jsFrame);

    // Find corresponding dart location and scope.
    final url = _debugger.urlForScriptId(jsScriptId);
    if (url == null) {
      return createError(
        EvaluationErrorKind.internal,
        'Cannot find url for JS script: $jsScriptId',
      );
    }
    final locationMap = await _locations.locationForJs(url, jsLine, jsColumn);
    if (locationMap == null) {
      return createError(
        EvaluationErrorKind.internal,
        'Cannot find Dart location for JS location: '
        'url: $url, '
        'function: $functionName, '
        'line: $jsLine, '
        'column: $jsColumn',
      );
    }

    final dartLocation = locationMap.dartLocation;
    final dartSourcePath = dartLocation.uri.serverPath;
    final libraryUri = await _modules.libraryForSource(dartSourcePath);
    final scriptUri = await _modules.libraryOrPartForSource(dartSourcePath);
    if (libraryUri == null) {
      return createError(
        EvaluationErrorKind.internal,
        'no libraryUri for $dartSourcePath',
      );
    }

    final module = await _modules.moduleForLibrary(libraryUri.toString());
    if (module == null) {
      return createError(
        EvaluationErrorKind.internal,
        'no module for $libraryUri ($dartSourcePath)',
      );
    }

    _logger.finest(
      'Evaluating "$expression" at $module, '
      '$libraryUri:${dartLocation.line}:${dartLocation.column} '
      'or rather $scriptUri:${dartLocation.line}:${dartLocation.column} '
      'with scope: $scope',
    );

    if (scope.isNotEmpty) {
      final totalScope = Map<String, String>.from(scope)..addAll(frameScope);
      expression = _createDartLambda(expression, totalScope.keys);
    }

    _logger.finest('Compiling "$expression"');

    // Compile expression using an expression compiler, such as
    // frontend server or expression compiler worker.
    //
    // TODO(annagrin): map JS locals to dart locals in the expression
    // and JS scope before passing them to the dart expression compiler.
    // Issue:  https://github.com/dart-lang/sdk/issues/40273
    final compilationResult = await _compiler.compileExpressionToJs(
      isolateId,
      libraryUri.toString(),
      scriptUri.toString(),
      dartLocation.line,
      dartLocation.column,
      {},
      frameScope.map((key, value) => MapEntry(key, key)),
      module,
      expression,
    );

    final isError = compilationResult.isError;
    final jsResult = compilationResult.result;
    if (isError) {
      return _formatCompilationError(jsResult);
    }

    // Strip try/catch incorrectly added by the expression compiler.
    final jsCode = _maybeStripTryCatch(jsResult);

    // Send JS expression to chrome to evaluate.
    var result = scope.isEmpty
        ? await _evaluateJsExpressionInFrame(frameIndex, jsCode)
        : await _callJsFunctionInFrame(frameIndex, jsCode, scope, frameScope);

    result = await _formatEvaluationError(result);
    _logger.finest('Evaluated "$expression" to "${result.json}"');
    return result;
  }

  /// Call JavaScript [function] with [scope] on frame [frameIndex].
  ///
  /// Wrap the [function] in a lambda that takes scope variables as parameters.
  /// Send JS expression to chrome to evaluate in frame with [frameIndex]
  /// with the provided [scope].
  ///
  /// [frameIndex] is the index of the frame to call the function in.
  /// [function] is the JS function to evaluate.
  /// [scope] is the additional scope as a map from scope variables to
  ///   remote object IDs.
  /// [frameScope] is the original scope as a map from scope variables
  ///   to remote object IDs.
  Future<RemoteObject> _callJsFunctionInFrame(
    int frameIndex,
    String function,
    Map<String, String> scope,
    Map<String, String> frameScope,
  ) async {
    final totalScope = Map<String, String>.from(scope)..addAll(frameScope);
    final thisObject = await _debugger.evaluateJsOnCallFrameIndex(
      frameIndex,
      'this',
    );

    final thisObjectId = thisObject.objectId;
    if (thisObjectId != null) {
      totalScope['this'] = thisObjectId;
    }

    return _callJsFunction(function, totalScope);
  }

  /// Call the [function] with [scope] as arguments.
  ///
  /// Wrap the [function] in a lambda that takes scope variables as parameters.
  /// Send JS expression to chrome to evaluate with the provided [scope].
  ///
  /// [function] is the JS function to evaluate.
  /// [scope] is a map from scope variables to remote object IDs.
  Future<RemoteObject> _callJsFunction(
    String function,
    Map<String, String> scope,
  ) {
    final jsCode = _createEvalFunction(function, scope.keys);

    _logger.finest('Evaluating JS: "$jsCode" with scope: $scope');
    return _inspector.callFunction(jsCode, scope.values);
  }

  /// Evaluate JavaScript [expression] on frame [frameIndex].
  ///
  /// Wrap the [expression] in a try/catch expression to catch errors.
  /// Send JS expression to chrome to evaluate on frame [frameIndex].
  ///
  /// [frameIndex] is the index of the frame to call the function in.
  /// [expression] is the JS function to evaluate.
  Future<RemoteObject> _evaluateJsExpressionInFrame(
    int frameIndex,
    String expression,
  ) {
    final jsCode = _createEvalExpression(expression);

    _logger.finest('Evaluating JS: "$jsCode"');
    return _debugger.evaluateJsOnCallFrameIndex(frameIndex, jsCode);
  }

  static String? _getObjectId(RemoteObject? object) =>
      object?.objectId ?? dartIdFor(object?.value);

  RemoteObject _formatCompilationError(String error) {
    // Frontend currently gives a text message including library name
    // and function name on compilation error. Strip this information
    // since it shows synthetic names that are only used for temporary
    // debug library during expression evaluation.
    //
    // TODO(annagrin): modify frontend to avoid stripping dummy names
    // [issue 40449](https://github.com/dart-lang/sdk/issues/40449)
    if (error.startsWith('[')) {
      error = error.substring(1);
    }
    if (error.endsWith(']')) {
      error = error.substring(0, error.lastIndexOf(']'));
    }
    if (error.contains('InternalError: ')) {
      error = error.replaceAll('InternalError: ', '');
      return createError(EvaluationErrorKind.internal, error);
    }
    error = error.replaceAll(_syntheticNameFilterRegex, '');
    return createError(EvaluationErrorKind.compilation, error);
  }

  Future<RemoteObject> _formatEvaluationError(RemoteObject result) async {
    if (result.type == 'string') {
      var error = '${result.value}';
      if (error.startsWith('ReferenceError: ')) {
        error = error.replaceFirst('ReferenceError: ', '');
        return createError(EvaluationErrorKind.reference, error);
      } else if (error.startsWith('TypeError: ')) {
        error = error.replaceFirst('TypeError: ', '');
        return createError(EvaluationErrorKind.type, error);
      } else if (error.startsWith('NetworkError: ')) {
        var modulePath = _loadModuleErrorRegex.firstMatch(error)?.group(1);
        final module = modulePath != null
            ? await globalToolConfiguration.loadStrategy.moduleForServerPath(
                _entrypoint,
                modulePath,
              )
            : 'unknown';
        modulePath ??= 'unknown';
        error =
            'Module is not loaded : $module (path: $modulePath). '
            'Accessing libraries that have not yet been used in the '
            'application is not supported during expression evaluation.';
        return createError(EvaluationErrorKind.loadModule, error);
      }
    }
    return result;
  }

  /// Return local scope as a map from variable names to remote object IDs.
  ///
  /// [frame] is the current frame index.
  Future<Map<String, String>> _collectLocalFrameScope(
    WipCallFrame frame,
  ) async {
    final scope = <String, String>{};

    void collectVariables(Iterable<chrome.Property> variables) {
      for (final p in variables) {
        final name = p.name;
        final value = p.value;
        // TODO: null values represent variables optimized by v8.
        // Show that to the user.
        if (name != null && value != null && !_isUndefined(value)) {
          final objectId = _getObjectId(p.value);
          if (objectId != null) {
            scope[name] = objectId;
          }
        }
      }
    }

    // skip library and main scope
    final scopeChain = filterScopes(frame).reversed;
    for (final scope in scopeChain) {
      final objectId = scope.object.objectId;
      if (objectId != null) {
        final scopeProperties = await _inspector.getProperties(objectId);
        collectVariables(scopeProperties);
      }
    }

    return scope;
  }

  bool _isUndefined(RemoteObject value) => value.type == 'undefined';

  static String _createDartLambda(String expression, Iterable<String> params) =>
      '(${params.join(', ')}) { return $expression; }';

  /// Strip try/catch incorrectly added by the expression compiler.
  /// TODO: remove adding try/catch block in expression compiler.
  /// https://github.com/dart-lang/webdev/issues/1341, then remove
  /// this stripping code.
  static String _maybeStripTryCatch(String jsCode) {
    // Match the wrapping generated by the expression compiler exactly
    // so the matching does not succeed naturally after the wrapping is
    // removed:
    //
    // Expression compiler's wrapping:
    //
    // '\ntry {'
    // '\n  ($jsExpression('
    // '\n    $args'
    // '\n  ))'
    // '\n} catch (error) {'
    // '\n  error.name + ": " + error.message;'
    // '\n}';
    //
    final lines = jsCode.split('\n');
    if (lines.length > 5) {
      final tryLines = lines.getRange(0, 2).toList();
      final bodyLines = lines.getRange(2, lines.length - 3);
      final catchLines = lines
          .getRange(lines.length - 3, lines.length)
          .toList();
      if (tryLines[0].isEmpty &&
          tryLines[1] == 'try {' &&
          catchLines[0] == '} catch (error) {' &&
          catchLines[1] == '  error.name + ": " + error.message;' &&
          catchLines[2] == '}') {
        return bodyLines.join('\n');
      }
    }
    return jsCode;
  }

  /// Create JS expression to pass to `Debugger.evaluateOnCallFrame`.
  static String _createEvalExpression(String expression) {
    final body = expression.split('\n').where((e) => e.isNotEmpty);

    return JsBuilder.createEvalExpression(body);
  }

  /// Create JS function  to invoke in `Runtime.callFunctionOn`.
  static String _createEvalFunction(String function, Iterable<String> params) {
    final body = function.split('\n').where((e) => e.isNotEmpty);

    return params.contains('this')
        ? JsBuilder.createEvalBoundFunction(body, params)
        : JsBuilder.createEvalStaticFunction(body, params);
  }
}
