// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Code, Message, PlainAndColorizedString;
import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show CfeDiagnosticMessage, DiagnosticMessageHandler;
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:kernel/ast.dart' show Component, Library, TreeNode;
import 'package:kernel/dart_scope_calculator.dart';

import '../compiler/js_names.dart' as js_ast;
import '../compiler/module_builder.dart';
import '../js_ast/js_ast.dart' as js_ast;
import 'compiler.dart' show Compiler;

CfeDiagnosticMessage _createInternalError(
  Uri uri,
  int line,
  int col,
  String msg,
) {
  return Message(
        Code('Expression Compiler Internal error'),
        problemMessage: msg,
      )
      .withLocation(uri, 0, 0)
      .withFormatting(
        PlainAndColorizedString.plainOnly('Internal error: $msg'),
        line,
        col,
        CfeSeverity.internalProblem,
        [],
      );
}

class ExpressionCompiler {
  static final String debugProcedureName = '\$dartEval';

  final CompilerContext _context;
  final CompilerOptions _options;
  final List<String> errors;
  final IncrementalCompiler _compiler;
  final Compiler _kernel2jsCompiler;
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
  ) : onDiagnostic = _options.onDiagnostic!,
      _context = _compiler.context;

  /// Compiles [expression] in library [libraryUri] and file [scriptUri]
  /// at [line]:[column] to JavaScript in [moduleName].
  ///
  /// [libraryUri] and [scriptUriString] can be the same, but if for instance
  /// evaluating expressions in a part file the [libraryUri] will be the uri of
  /// the "part of" file whereas [scriptUriString] will be the uri of the part.
  /// The [libraryUri] should be an import-uri, i.e. a package uri if it exists.
  /// The [scriptUriString] is allowed to be a package uri in which case it will
  /// be attempted translated to a file uri to match what is recorded in the
  /// kernel file.
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
    String? scriptUriString,
    int line,
    int column,
    Map<String, String> jsScope,
    String expression,
  ) async {
    try {
      // 1. find dart scope where debugger is paused

      _log('Compiling expression \n$expression');

      var scriptUri = scriptUriString == null
          ? null
          : Uri.parse(scriptUriString);
      if (scriptUri != null && scriptUri.isScheme('package')) {
        scriptUri = _compiler.translateUri(scriptUri);
        if (scriptUri.isScheme('package')) {
          // No packages. Try to translate via the component source.
          for (final source in _component.uriToSource.values) {
            if (source.importUri == scriptUri && source.fileUri != null) {
              scriptUri = source.fileUri!;
            }
          }
          // The uri could still be a package-uri, but then failing to do
          // expression compilation seems fair.
        }
      }

      var dartScope = _findScopeAt(
        Uri.parse(libraryUri),
        scriptUri,
        line,
        column,
        jsScope,
      );
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

      // Work around mismatched names and lowered representation for late local
      // variables.
      // Replace the existing entries with a name that matches the named
      // extracted from the lowering.
      // See https://github.com/dart-lang/sdk/issues/55918
      var dartLateLocals = [
        for (var name in dartScope.variables.keys)
          if (isLateLoweredLocalName(name)) name,
      ];
      for (var localName in dartLateLocals) {
        dartScope.variables[extractLocalName(localName)] = dartScope.variables
            .remove(localName)!;
      }

      // Create a mapping from Dart variable names in scope to the corresponding
      // JS values. The Dart variable may have had a suffix of the
      // form '$N' added to it where N is either the empty string or an
      // integer >= 0.
      final dartNameToJsValue = <String, String>{};

      int nameCompare(String a, String b) {
        final lengthCmp = b.length.compareTo(a.length);
        if (lengthCmp != 0) return lengthCmp;
        return b.compareTo(a);
      }

      // Sort Dart names in case a user-defined name includes a '$'. The
      // resulting normalized JS name might seem like a suffixed version of a
      // shorter Dart name. Since longer Dart names can't incorrectly match a
      // shorter JS name (JS names are always at least as long as the Dart
      // name), we process them from longest to shortest.
      final dartNames = [...dartScope.variables.keys]..sort(nameCompare);

      // Sort JS names so that the highest suffix value gets assigned to the
      // corresponding Dart name first. Since names are suffixed in ascending
      // order as inner scopes are visited, the highest suffix value will be
      // the one that matches the visible Dart name in a given scope.
      final jsNames = [...jsScope.keys]..sort(nameCompare);

      const removedSentinel = '';
      const thisJsName = r'$this';

      // Get the available async scopes.
      final asyncScopeRegexp = RegExp(r'^asyncScope(\$[0-9]*)?$');
      final asyncScopes = [
        ...jsNames.where((e) => asyncScopeRegexp.hasMatch(e)),
      ];

      for (final dartName in dartNames) {
        if (isExtensionThisName(dartName)) {
          if (jsScope.containsKey(thisJsName)) {
            dartNameToJsValue[dartName] = jsScope[thisJsName]!;
          }
          continue;
        }
        // Any name containing a '$' symbol will have that symbol expanded to
        // '$36' in JS. We do a similar expansion here to normalize the names.
        final jsNamePrefix = js_ast
            .toJSIdentifier(dartName)
            .replaceAll('\$', '\\\$');
        final regexp = RegExp(r'^' + jsNamePrefix + r'(\$[0-9]*)?$');
        for (var i = 0; i < jsNames.length; i++) {
          final jsName = jsNames[i];
          if (jsName == removedSentinel) continue;
          if (jsName.length < dartName.length) break;
          if (regexp.hasMatch(jsName)) {
            dartNameToJsValue[dartName] = jsScope[jsName]!;
            jsNames[i] = removedSentinel;

            // Remove any additional JS names that match this name as these will
            // correspond to shadowed Dart variables that are not visible in the
            // current scope.
            //
            // Note: In some extreme cases this can match the wrong variable.
            // This would require a combination of 36 nested variables with the
            // same name and a similarly named variable with a $ in its name.
            for (var j = i; j < jsNames.length; j++) {
              final jsName = jsNames[j];
              if (jsName == removedSentinel) continue;
              if (jsName.length < dartName.length) break;
              if (regexp.hasMatch(jsNames[j])) {
                jsNames[j] = removedSentinel;
              }
            }
            break;
          }
        }

        if (asyncScopes.isNotEmpty) {
          // Look up the value in the available async scopes.
          //
          // Creates an expression of the form:
          // "<dartName>" in asyncScope
          //   ? asyncScope["<dartName>"]
          //   : ("<dartName>" in asyncScope1
          //        ? asyncScope1["<dartName>"]
          //        : (...))
          //
          // Each 'asyncScope' variable represents a single Dart scope and the
          // keys in it match the names of the available Dart variables.
          // Each scope object is declared up front but values are not inserted
          // into it until the Dart scope is actually entered. So only "live"
          // scopes will contain keys.
          //
          // This expression will start at the innermost available scope and
          // and work its way out until it finds the first live scope that has
          // a value for the given Dart variable name.
          //
          // If the value is not found in any async scope then it defaults to
          // the nearest matching js value calculated above (which may be
          // captured from an outer scope).
          //
          // If there was no value found then this means that the variable does
          // not exist in any scope. This can occur if the browser detects the
          // JS variable is unused and so the browser doesn't capture it. In
          // this case return a special sentinel value that we can detect and
          // throw on.
          final defaultValue = dartNameToJsValue[dartName] ?? 'sentinel';
          dartNameToJsValue[dartName] = asyncScopes.fold(
            defaultValue,
            (p, e) => '"$dartName" in $e ? $e["$dartName"] : ($p)',
          );
        }
      }

      dartScope.variables.removeWhere(
        (variableName, _) =>
            // Remove undefined js variables (this allows us to get a reference
            // error from chrome on evaluation).
            !dartNameToJsValue.containsKey(variableName) ||
            // Remove wildcard method arguments which are lowered to have Dart
            // names that are invalid for Dart compilations.
            // Wildcard local variables are not appearing here at this time.
            isWildcardLoweredFormalParameter(variableName),
      );

      // Wildcard type parameters already matched by this existing test.
      dartScope.typeParameters.removeWhere(
        (parameter) => !jsScope.containsKey(parameter.name),
      );

      // map from values from the stack when available (this allows to evaluate
      // captured variables optimized away in chrome)
      var localJsScope = [
        ...dartScope.typeParameters.map((parameter) => jsScope[parameter.name]),
        ...dartScope.variables.keys.map(
          (variable) => dartNameToJsValue[variable],
        ),
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
      // We check for '_boundMethod' in case tearoffs are returned.
      var callExpression =
          '((() => {var sentinel = {}; var output = $jsExpression($args); '
          'if (output === sentinel) throw Error("Value not found in scope");'
          'return output?._boundMethod || output;})())';

      _log('Compiled expression \n$expression to $callExpression');
      return callExpression;
    } catch (e, s) {
      onDiagnostic(
        _createInternalError(Uri.parse(libraryUri), line, column, '$e:$s'),
      );
      return null;
    }
  }

  DartScope? _findScopeAt(
    Uri libraryUri,
    Uri? scriptFileUri,
    int line,
    int column,
    Map<String, String> jsScope,
  ) {
    if (line < 0) {
      onDiagnostic(
        _createInternalError(
          libraryUri,
          line,
          column,
          'Invalid source location',
        ),
      );
      return null;
    }

    var library = _getLibrary(libraryUri);
    if (library == null) {
      onDiagnostic(
        _createInternalError(
          libraryUri,
          line,
          column,
          'Dart library not found for location',
        ),
      );
      return null;
    }

    // TODO(jensj): Eventually make the scriptUri required.
    if (scriptFileUri != null) {
      final offset = _component.getOffsetNoThrow(scriptFileUri, line, column);
      if (offset < 0) {
        _log(
          'Got offset negative offset ($offset) for '
          '$scriptFileUri:$line:$column',
        );
        return DartScope(library, null, null, null, null, {}, []);
      }
      final scope = DartScopeBuilder2.findScopeFromOffset(
        library,
        scriptFileUri,
        offset,
      );
      return scope;
    }

    // No scriptUri provided. Find - and try - all of the possible ones.
    final fileUris = [library.fileUri];
    for (final part in library.parts) {
      try {
        final partUriIsh = library.fileUri.resolve(part.partUri);
        if (partUriIsh.isScheme('package')) {
          for (final source in _component.uriToSource.values) {
            if (source.importUri == partUriIsh && source.importUri != null) {
              fileUris.add(source.importUri!);
              break;
            }
          }
        } else {
          fileUris.add(partUriIsh);
        }
      } catch (e) {
        // Bad url.
        _log(
          "Got exception '$e' when resolving ${part.partUri} "
          'against ${library.fileUri}',
        );
      }
    }

    final foundScopes = <DartScope>[];
    for (final fileUri in fileUris) {
      final offset = _component.getOffsetNoThrow(fileUri, line, column);
      if (offset < 0) continue;
      foundScopes.add(
        DartScopeBuilder2.findScopeFromOffset(library, fileUri, offset),
      );
    }
    if (foundScopes.isEmpty) {
      _log(
        'Got only negative offsets for library/parts ${library.fileUri} '
        'at $line:$column.',
      );
      return DartScope(library, null, null, null, null, {}, []);
    }
    if (foundScopes.length == 1) {
      return foundScopes[0];
    }

    // Pick the "best" (most likely) scope based on content compare to js.
    final jsKeys = jsScope.keys.toSet();
    var bestIntersectionCount = -1;
    var bestScope = foundScopes[0];
    for (final scope in foundScopes) {
      final intersection = jsKeys.intersection(scope.variables.keys.toSet());
      if (intersection.length > bestIntersectionCount) {
        bestIntersectionCount = intersection.length;
        bestScope = scope;
      }
    }

    return bestScope;
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
      scope.variablesAsMapToType(),
      scope.typeParameters,
      debugProcedureName,
      scope.library.importUri,
      methodName: methodName,
      className: scope.cls?.name,
      isStatic: scope.isStatic,
      offset: scope.offset ?? TreeNode.noOffset,
      scriptUri: scope.fileUri?.toString(),
    );

    _log('Compiled expression to kernel');

    // TODO: make this code clear and assumptions enforceable
    // https://github.com/dart-lang/sdk/issues/43273
    if (errors.isNotEmpty) {
      return null;
    }

    var imports = <js_ast.ModuleItem>[];
    var jsFun = _kernel2jsCompiler.emitFunctionIncremental(
      imports,
      scope.library,
      scope.cls,
      procedure!.function,
      debugProcedureName,
    );

    _log('Generated JavaScript for expression');

    // print JS ast to string for evaluation
    var context = js_ast.SimpleJavaScriptPrintingContext();
    var opts = js_ast.JavaScriptPrintingOptions(
      allowKeywordsInProperties: true,
    );

    var tree = transformFunctionModuleFormat(imports, jsFun, _moduleFormat);
    tree.accept(
      js_ast.Printer(opts, context, localNamer: js_ast.ScopedNamer(tree)),
    );

    _log('Added imports and renamed variables for expression');

    return context.getText();
  }
}
