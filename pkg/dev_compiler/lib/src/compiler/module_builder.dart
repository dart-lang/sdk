// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:dev_compiler/src/compiler/shared_compiler.dart';
import 'package:path/path.dart' as p;

import '../js_ast/js_ast.dart';
import 'js_names.dart';

/// The module format to emit.
enum ModuleFormat {
  /// ECMAScript 6 module using import and export.
  es6,

  /// CommonJS module (used in Node.js)
  common,

  /// Asynchronous Module Definition (AMD, used in browsers).
  amd,

  /// Dart Dev Compiler's own format.
  ddc,
}

/// Parses a string into a [ModuleFormat].
///
/// Throws an [ArgumentError] if the module format is not recognized.
ModuleFormat parseModuleFormat(String s) {
  var formats = const {
    'es6': ModuleFormat.es6,
    'common': ModuleFormat.common,
    'amd': ModuleFormat.amd,
    'ddc': ModuleFormat.ddc,
    // Deprecated:
    'node': ModuleFormat.common,
    'legacy': ModuleFormat.ddc
  };
  var selected = formats[s];
  if (selected == null) {
    throw ArgumentError('Invalid module format `$s`, allowed formats are: '
        '`${formats.keys.join(', ')}`');
  }
  return selected;
}

/// Parse the module format option added by [addModuleFormatOptions].
List<ModuleFormat> parseModuleFormatOption(ArgResults args) {
  return (args['modules'] as List<String>).map(parseModuleFormat).toList();
}

/// Adds an option to the [argParser] for choosing the module format, optionally
/// [allowMultiple] formats to be specified, with each emitted into a separate
/// file.
void addModuleFormatOptions(ArgParser argParser, {bool hide = true}) {
  argParser.addMultiOption('modules', help: 'module pattern to emit', allowed: [
    'es6',
    'common',
    'amd',
    'ddc',
    'legacy', // renamed to ddc
    'node', // renamed to commonjs
    'all' // to emit all flavors for the SDK
  ], allowedHelp: {
    'es6': 'ECMAScript 6 modules',
    'common': 'CommonJS/Node.js modules',
    'amd': 'AMD/RequireJS modules'
  }, defaultsTo: [
    'amd'
  ]);
}

/// Transforms an ES6 [module] into a given module [format].
///
/// If the format is [ModuleFormat.es6] this will return [module] unchanged.
///
/// Because JS ASTs are immutable the resulting module will share as much
/// structure as possible with the original. The transformation is a shallow one
/// that affects the top-level module items, especially [ImportDeclaration]s and
/// [ExportDeclaration]s.
Program transformModuleFormat(ModuleFormat format, Program module) {
  switch (format) {
    case ModuleFormat.ddc:
      // Legacy format always generates output compatible with single file mode.
      return DdcModuleBuilder().build(module);
    case ModuleFormat.common:
      return CommonJSModuleBuilder().build(module);
    case ModuleFormat.amd:
      return AmdModuleBuilder().build(module);
    case ModuleFormat.es6:
    default:
      return module;
  }
}

/// Base class for compiling ES6 modules into various ES5 module patterns.
///
/// This is a helper class for utilities and state that is shared by several
/// module transformers.
// TODO(jmesserly): "module transformer" might be a better name than builder.
abstract class _ModuleBuilder {
  final imports = <ImportDeclaration>[];
  final exports = <ExportDeclaration>[];
  final statements = <Statement>[];

  /// Collect [imports], [exports] and [statements] from the ES6 [module].
  ///
  /// For exports, this will also add their body to [statements] in the
  /// appropriate position.
  void visitProgram(Program module) {
    for (var item in module.body) {
      if (item is ImportDeclaration) {
        visitImportDeclaration(item);
      } else if (item is ExportDeclaration) {
        visitExportDeclaration(item);
      } else if (item is Statement) {
        visitStatement(item);
      }
    }
  }

  void visitImportDeclaration(ImportDeclaration node) {
    imports.add(node);
  }

  void visitExportDeclaration(ExportDeclaration node) {
    exports.add(node);
    var exported = node.exported;
    if (exported is! ExportClause) {
      statements.add(exported.toStatement());
    }
  }

  void visitStatement(Statement node) {
    statements.add(node);
  }
}

/// Generates modules for with our DDC `dart_library.js` loading mechanism.
// TODO(jmesserly): remove this and replace with something that interoperates.
class DdcModuleBuilder extends _ModuleBuilder {
  Program build(Program module) {
    // Collect imports/exports/statements.
    visitProgram(module);

    // Build import parameters.
    var exportsVar = TemporaryId('exports');
    var parameters = <TemporaryId>[exportsVar];
    var importNames = <Expression>[];
    var importStatements = <Statement>[];
    for (var import in imports) {
      importNames.add(import.from);
      // TODO(jmesserly): we could use destructuring here.
      var moduleVar =
          TemporaryId(pathToJSIdentifier(import.from.valueWithoutQuotes));
      parameters.add(moduleVar);
      for (var importName in import.namedImports) {
        assert(!importName
            .isStar); // import * not supported in ddc format modules.
        var asName = importName.asName ?? importName.name;
        var fromName = importName.name.name;
        // Load non-SDK modules on demand (i.e., deferred).
        if (import.from.valueWithoutQuotes != dartSdkModule) {
          importStatements.add(js.statement(
              'let # = dart_library.defer(#, #, function (mod, lib) {'
              '  # = mod;'
              '  # = lib;'
              '});',
              [asName, moduleVar, js.string(fromName), moduleVar, asName]));
        } else {
          importStatements.add(js.statement(
              'const # = #.#', [asName, moduleVar, importName.name.name]));
        }
      }
    }
    statements.insertAll(0, importStatements);

    if (exports.isNotEmpty) {
      statements.add(js.comment('Exports:'));
      // TODO(jmesserly): make these immutable in JS?
      for (var export in exports) {
        var names = export.exportedNames;
        assert(names != null); // export * not supported in ddc modules.
        for (var name in names) {
          var alias = name.asName ?? name.name;
          statements.add(
              js.statement('#.# = #;', [exportsVar, alias.name, name.name]));
        }
      }
    }

    var resultModule = NamedFunction(
        loadFunctionIdentifier(module.name),
        js.fun("function(#) { 'use strict'; #; }", [parameters, statements]),
        true);

    var moduleDef = js.statement('dart_library.library(#, #, #, #, #)', [
      js.string(module.name, "'"),
      LiteralNull(),
      js.commentExpression(
          'Imports', ArrayInitializer(importNames, multiline: true)),
      resultModule,
      SharedCompiler.metricsLocationID
    ]);
    return Program(<ModuleItem>[moduleDef]);
  }
}

/// Generates CommonJS modules (used by Node.js).
class CommonJSModuleBuilder extends _ModuleBuilder {
  Program build(Program module) {
    var importStatements = [
      js.statement("'use strict';"),
    ];

    // Collect imports/exports/statements.
    visitProgram(module);

    for (var import in imports) {
      // TODO(jmesserly): we could use destructuring here.
      var moduleVar =
          TemporaryId(pathToJSIdentifier(import.from.valueWithoutQuotes));
      importStatements
          .add(js.statement('const # = require(#);', [moduleVar, import.from]));

      // TODO(jmesserly): optimize for the common case of a single import.
      for (var importName in import.namedImports) {
        // import * is not emitted by the compiler, so we don't support it here.
        assert(!importName.isStar);
        var asName = importName.asName ?? importName.name;
        importStatements.add(js.statement(
            'const # = #.#', [asName, moduleVar, importName.name.name]));
      }
    }
    statements.insertAll(0, importStatements);

    if (exports.isNotEmpty) {
      var exportsVar = Identifier('exports');
      statements.add(js.comment('Exports:'));
      for (var export in exports) {
        var names = export.exportedNames;
        // export * is not emitted by the compiler, so we don't handle it here.
        assert(names != null);
        for (var name in names) {
          var alias = name.asName ?? name.name;
          statements.add(
              js.statement('#.# = #;', [exportsVar, alias.name, name.name]));
        }
      }
    }

    return Program(statements);
  }
}

/// Generates AMD modules (used in browsers with RequireJS).
class AmdModuleBuilder extends _ModuleBuilder {
  AmdModuleBuilder();

  Program build(Program module) {
    var importStatements = <Statement>[];

    // Collect imports/exports/statements.
    visitProgram(module);

    var dependencies = <LiteralString>[];
    var fnParams = <Parameter>[];
    for (var import in imports) {
      // TODO(jmesserly): we could use destructuring once Atom supports it.
      var moduleVar =
          TemporaryId(pathToJSIdentifier(import.from.valueWithoutQuotes));
      fnParams.add(moduleVar);
      dependencies.add(import.from);

      // TODO(jmesserly): optimize for the common case of a single import.
      for (var importName in import.namedImports) {
        // import * is not emitted by the compiler, so we don't handle it here.
        assert(!importName.isStar);
        var asName = importName.asName ?? importName.name;
        importStatements.add(js.statement(
            'const # = #.#', [asName, moduleVar, importName.name.name]));
      }
    }
    statements.insertAll(0, importStatements);

    if (exports.isNotEmpty) {
      var exportedProps = <Property>[];
      for (var export in exports) {
        var names = export.exportedNames;
        // export * is not emitted by the compiler, so we don't handle it here.
        assert(names != null);
        for (var name in names) {
          var alias = name.asName ?? name.name;
          exportedProps.add(Property(js.string(alias.name), name.name));
        }
      }
      statements.add(js.comment('Exports:'));
      statements.add(Return(ObjectInitializer(exportedProps, multiline: true)));
    }
    var resultModule = NamedFunction(
        loadFunctionIdentifier(module.name),
        js.fun("function(#) { 'use strict'; #; }", [fnParams, statements]),
        true);
    var block = js.statement(
        'define(#, #);', [ArrayInitializer(dependencies), resultModule]);

    return Program([block]);
  }
}

bool isSdkInternalRuntimeUri(Uri importUri) {
  return importUri.scheme == 'dart' && importUri.path == '_runtime';
}

String libraryUriToJsIdentifier(Uri importUri) {
  if (importUri.scheme == 'dart') {
    return isSdkInternalRuntimeUri(importUri) ? 'dart' : importUri.path;
  }
  return pathToJSIdentifier(p.withoutExtension(importUri.pathSegments.last));
}

/// Converts an entire arbitrary path string into a string compatible with
/// JS identifier naming rules while conserving path information.
///
/// NOT guaranteed to result in a unique string. E.g.,
///   1) '__' appears in a file name.
///   2) An escaped '/' or '\' appears in a filename (a/b and a$47b).
String pathToJSIdentifier(String path) {
  path = p.normalize(path);
  if (path.startsWith('/') || path.startsWith('\\')) {
    path = path.substring(1, path.length);
  }
  return toJSIdentifier(path
      .replaceAll('\\', '__')
      .replaceAll('/', '__')
      .replaceAll('..', '__')
      .replaceAll('-', '_'));
}

/// Creates function name given [moduleName].
String loadFunctionName(String moduleName) =>
    'load__' + pathToJSIdentifier(moduleName.replaceAll('.', '_'));

/// Creates function name identifier given [moduleName].
Identifier loadFunctionIdentifier(String moduleName) =>
    Identifier(loadFunctionName(moduleName));

// Replacement string for path separators (i.e., '/', '\', '..').
final encodedSeparator = '__';
