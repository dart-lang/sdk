// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:args/command_runner.dart' show UsageException;
import 'package:path/path.dart' as path;

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

  /// Dart Dev Compiler's legacy format (deprecated).
  legacy,

  /// Like [amd] but can be concatenated into a single file.
  amdConcat,

  /// Like [legacy] but can be concatenated into a single file.
  legacyConcat
}

/// Parses a string into a [ModuleFormat].
ModuleFormat parseModuleFormat(String s) => {
      'es6': ModuleFormat.es6,
      'common': ModuleFormat.common,
      'amd': ModuleFormat.amd,
      // Deprecated:
      'node': ModuleFormat.common,
      'legacy': ModuleFormat.legacy
    }[s];

/// Parse the module format option added by [addModuleFormatOptions].
List<ModuleFormat> parseModuleFormatOption(ArgResults args) {
  var formats =
      (args['modules'] as List<String>).map(parseModuleFormat).toList();

  if (args['single-out-file'] as bool) {
    for (int i = 0; i < formats.length; i++) {
      var format = formats[i];
      switch (formats[i]) {
        case ModuleFormat.amd:
          formats[i] = ModuleFormat.amdConcat;
          break;
        case ModuleFormat.legacy:
          formats[i] = ModuleFormat.legacyConcat;
          break;
        default:
          throw UsageException(
              'Format $format cannot be combined with '
              'single-out-file. Only amd and legacy modes are supported.',
              '');
      }
    }
  }
  return formats;
}

/// Adds an option to the [argParser] for choosing the module format, optionally
/// [allowMultiple] formats to be specified, with each emitted into a separate
/// file.
void addModuleFormatOptions(ArgParser argParser, {bool hide = true}) {
  argParser.addMultiOption('modules', help: 'module pattern to emit', allowed: [
    'es6',
    'common',
    'amd',
    'legacy', // deprecated
    'node', // renamed to commonjs
    'all' // to emit all flavors for the SDK
  ], allowedHelp: {
    'es6': 'ECMAScript 6 modules',
    'common': 'CommonJS/Node.js modules',
    'amd': 'AMD/RequireJS modules'
  }, defaultsTo: [
    'amd'
  ]);

  argParser.addFlag('single-out-file',
      help: 'emit modules that can be concatenated into one file.\n'
          'Only compatible with legacy and amd module formats.',
      defaultsTo: false,
      hide: hide);
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
    case ModuleFormat.legacy:
    case ModuleFormat.legacyConcat:
      // Legacy format always generates output compatible with single file mode.
      return LegacyModuleBuilder().build(module);
    case ModuleFormat.common:
      return CommonJSModuleBuilder().build(module);
    case ModuleFormat.amd:
      return AmdModuleBuilder().build(module);
    case ModuleFormat.amdConcat:
      return AmdModuleBuilder(singleOutFile: true).build(module);
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

  visitImportDeclaration(ImportDeclaration node) {
    imports.add(node);
  }

  visitExportDeclaration(ExportDeclaration node) {
    exports.add(node);
    var exported = node.exported;
    if (exported is! ExportClause) {
      statements.add(exported.toStatement());
    }
  }

  visitStatement(Statement node) {
    statements.add(node);
  }
}

/// Generates modules for with our legacy `dart_library.js` loading mechanism.
// TODO(jmesserly): remove this and replace with something that interoperates.
class LegacyModuleBuilder extends _ModuleBuilder {
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
        assert(!importName.isStar); // import * not supported in legacy modules.
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
        assert(names != null); // export * not supported in legacy modules.
        for (var name in names) {
          statements
              .add(js.statement('#.# = #;', [exportsVar, name.name, name]));
        }
      }
    }

    var functionName =
        'load__' + pathToJSIdentifier(module.name.replaceAll('.', '_'));
    var resultModule = NamedFunction(
        Identifier(functionName),
        js.fun("function(#) { 'use strict'; #; }", [parameters, statements]),
        true);

    var moduleDef = js.statement("dart_library.library(#, #, #, #)", [
      js.string(module.name, "'"),
      LiteralNull(),
      js.commentExpression(
          "Imports", ArrayInitializer(importNames, multiline: true)),
      resultModule
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
          statements
              .add(js.statement('#.# = #;', [exportsVar, name.name, name]));
        }
      }
    }

    return Program(statements);
  }
}

/// Generates AMD modules (used in browsers with RequireJS).
class AmdModuleBuilder extends _ModuleBuilder {
  final bool singleOutFile;

  AmdModuleBuilder({this.singleOutFile = false});

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
          exportedProps.add(Property(js.string(name.name), name));
        }
      }
      statements.add(js.comment('Exports:'));
      statements.add(Return(ObjectInitializer(exportedProps, multiline: true)));
    }

    // TODO(vsm): Consider using an immediately invoked named function pattern
    // (see legacy code above).
    var block = singleOutFile
        ? js.statement("define(#, #, function(#) { 'use strict'; #; });", [
            js.string(module.name, "'"),
            ArrayInitializer(dependencies),
            fnParams,
            statements
          ])
        : js.statement("define(#, function(#) { 'use strict'; #; });",
            [ArrayInitializer(dependencies), fnParams, statements]);

    return Program([block]);
  }
}

/// Escape [name] to make it into a valid identifier.
String pathToJSIdentifier(String name) {
  return toJSIdentifier(path.basenameWithoutExtension(name));
}

/// Escape [name] to make it into a valid identifier.
String toJSIdentifier(String name) {
  if (name.length == 0) return r'$';

  // Escape any invalid characters
  StringBuffer buffer = null;
  for (int i = 0; i < name.length; i++) {
    var ch = name[i];
    var needsEscape = ch == r'$' || _invalidCharInIdentifier.hasMatch(ch);
    if (needsEscape && buffer == null) {
      buffer = StringBuffer(name.substring(0, i));
    }
    if (buffer != null) {
      buffer.write(needsEscape ? '\$${ch.codeUnits.join("")}' : ch);
    }
  }

  var result = buffer != null ? '$buffer' : name;
  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(RegExp('[0-9]')) || invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = RegExp(r'[^A-Za-z_$0-9]');
