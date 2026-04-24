// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/loaders/strategy.dart';

class DartRuntimeDebugger {
  final LoadStrategy _loadStrategy;
  final bool _useLibraryBundleExpression;

  DartRuntimeDebugger({
    required this._loadStrategy,
    required this._useLibraryBundleExpression,
  });

  /// Generates a JS expression based on DDC module format.
  String _generateJsExpression(
    String ddcExpression,
    String libraryBundleExpression,
  ) => _useLibraryBundleExpression ? libraryBundleExpression : ddcExpression;

  /// Wraps a JS function call with SDK loader logic.
  String _wrapWithSdkLoader(String args, String functionCall) {
    return '''
      function($args) {
        const sdk = ${_loadStrategy.loadModuleSnippet}('dart_sdk');
        const dart = sdk.dart;
        return dart.$functionCall;
      }
    ''';
  }

  /// Wraps a JS function call with DDC library bundle loader logic.
  String _wrapWithBundleLoader(String args, String functionCall) {
    return '''
      function($args) {
        return dartDevEmbedder.debugger.$functionCall;
      }
    ''';
  }

  /// Wraps an expression in an Immediately Invoked Function Expression (IIFE).
  String _wrapInIIFE(String expression) {
    return '($expression)()';
  }

  /// Builds a JS expression based on the loading strategy.
  String _buildExpression(
    String args,
    String ddcFunction,
    String libraryBundleFunction,
  ) {
    return _generateJsExpression(
      _wrapWithSdkLoader(args, ddcFunction),
      _wrapWithBundleLoader(args, libraryBundleFunction),
    );
  }

  /// Generates a JS expression for retrieving object metadata.
  String getObjectMetadataJsExpression() {
    return _buildExpression(
      'arg',
      'getObjectMetadata(arg)',
      'getObjectMetadata(arg)',
    );
  }

  /// Generates a JS expression for retrieving object field names.
  String getObjectFieldNamesJsExpression() {
    return _buildExpression(
      '',
      'getObjectFieldNames(this)',
      'getObjectFieldNames(this)',
    );
  }

  /// Generates a JS expression for retrieving function metadata.
  String getFunctionMetadataJsExpression() {
    return _buildExpression(
      '',
      'getFunctionMetadata(this)',
      'getFunctionName(this)',
    );
  }

  /// Generates a JS expression for retrieving a subrange of elements.
  String getSubRangeJsExpression() {
    return _buildExpression(
      'offset, count',
      'getSubRange(this, offset, count)',
      'getSubRange(this, offset, count)',
    );
  }

  /// Generates a JS expression for retrieving class metadata.
  String getClassMetadataJsExpression(String libraryUri, String className) {
    final expression = _buildExpression(
      '',
      "getClassMetadata('$libraryUri', '$className')",
      "getClassMetadata('$libraryUri', '$className')",
    );
    // Use the helper method to wrap this in an IIFE
    return _wrapInIIFE(expression);
  }

  /// Generates a JS expression for retrieving Dart Developer Extension Names.
  String getDartDeveloperExtensionNamesJsExpression() {
    return _generateJsExpression(
      '${_loadStrategy.loadModuleSnippet}("dart_sdk").developer._extensions'
          '.keys.toList();',
      'dartDevEmbedder.debugger.extensionNames',
    );
  }

  /// Generates a JS expression for retrieving metadata of classes in a library.
  String getClassesInLibraryJsExpression(String libraryUri) {
    final expression = _buildExpression(
      '',
      "getLibraryMetadata('$libraryUri')",
      "getClassesInLibrary('$libraryUri')",
    );
    // Use the helper method to wrap this in an IIFE
    return _wrapInIIFE(expression);
  }

  /// Generates a JS expression for retrieving map elements.
  String getMapElementsJsExpression() {
    return _buildExpression('', 'getMapElements(this)', 'getMapElements(this)');
  }

  /// Generates a JS expression for getting a property from a JS object.
  String getPropertyJsExpression(String fieldName) {
    return _generateJsExpression(
      '''
      function() {
        return this["$fieldName"];
      }
      ''',
      '''
      function() {
        return this["$fieldName"];
      }
      ''',
    );
  }

  /// Generates a JS expression for retrieving set elements.
  String getSetElementsJsExpression() {
    return _buildExpression('', 'getSetElements(this)', 'getSetElements(this)');
  }

  /// Generates a JS expression for retrieving the fields of a record.
  String getRecordFieldsJsExpression() {
    return _buildExpression(
      '',
      'getRecordFields(this)',
      'getRecordFields(this)',
    );
  }

  /// Generates a JS expression for retrieving the fields of a record type.
  String getRecordTypeFieldsJsExpression() {
    return _buildExpression(
      '',
      'getRecordTypeFields(this)',
      'getRecordTypeFields(this)',
    );
  }

  /// Generates a JS expression for calling an instance method on an object.
  String callInstanceMethodJsExpression(String methodName) {
    String generateInstanceMethodJsExpression(String functionCall) {
      return '''
        function () {
          if (!Object.getPrototypeOf(this)) { return 'Instance of PlainJavaScriptObject'; }
          return $functionCall;
        }
      ''';
    }

    return _generateJsExpression(
      generateInstanceMethodJsExpression(
        '${_loadStrategy.loadModuleSnippet}("dart_sdk").dart'
        '.dsendRepl(this, "$methodName", arguments)',
      ),
      generateInstanceMethodJsExpression(
        'dartDevEmbedder.debugger.callInstanceMethod'
        '(this, "$methodName", arguments)',
      ),
    );
  }

  /// Generates a JS expression to invoke a Dart extension method.
  String invokeExtensionJsExpression(String methodName, String encodedJson) {
    return _generateJsExpression(
      '${_loadStrategy.loadModuleSnippet}("dart_sdk").developer'
          '.invokeExtension("$methodName", JSON.stringify($encodedJson));',
      'dartDevEmbedder.debugger.invokeExtension'
          '("$methodName", JSON.stringify($encodedJson));',
    );
  }

  /// Generates a JS expression for calling a library method.
  String callLibraryMethodJsExpression(String libraryUri, String methodName) {
    final findLibraryExpression =
        '''
     (function() {
       const sdk = ${_loadStrategy.loadModuleSnippet}('dart_sdk');
       const dart = sdk.dart;
       const library = dart.getLibrary('$libraryUri');
       if (!library) throw 'cannot find library for $libraryUri';
       return library;
     })();
     ''';

    // `callLibraryMethod` expects an array of arguments. Chrome DevTools
    // spreads arguments individually when calling functions. This code
    // reconstructs the expected argument array.
    return _generateJsExpression(
      findLibraryExpression,
      _wrapWithBundleLoader(
        '',
        'callLibraryMethod("$libraryUri", "$methodName", '
            'Array.from(arguments))',
      ),
    );
  }
}
