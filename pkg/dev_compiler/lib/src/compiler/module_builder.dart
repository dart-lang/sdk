// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../js_ast/js_ast.dart';
import 'js_names.dart';

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
    statements.add(node.exported.toStatement());
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
    var exportsVar = new TemporaryId('exports');
    var parameters = <TemporaryId>[exportsVar];
    var importNames = <Expression>[];
    var importStatements = <Statement>[];
    for (var import in imports) {
      importNames.add(import.from);
      // TODO(jmesserly): we could use destructuring once Atom supports it.
      var moduleVar =
          new TemporaryId(pathToJSIdentifier(import.from.valueWithoutQuotes));
      parameters.add(moduleVar);
      for (var importName in import.namedImports) {
        assert(!importName.isStar); // import * not supported in legacy modules.
        var asName = importName.asName ?? importName.name;
        importStatements.add(js.statement(
            'const # = #.#', [asName, moduleVar, importName.name.name]));
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

    var resultModule =
        js.call("function(#) { 'use strict'; #; }", [parameters, statements]);

    var moduleDef = js.statement("dart_library.library(#, #, #, #)", [
      js.string(module.name, "'"),
      new LiteralNull(),
      js.commentExpression(
          "Imports", new ArrayInitializer(importNames, multiline: true)),
      resultModule
    ]);
    return new Program(<ModuleItem>[moduleDef]);
  }
}

/// Generates node modules.
class NodeModuleBuilder extends _ModuleBuilder {
  Program build(Program module) {
    var importStatements = [];

    // Collect imports/exports/statements.
    visitProgram(module);

    for (var import in imports) {
      // TODO(jmesserly): we could use destructuring once Atom supports it.
      var moduleVar =
          new TemporaryId(pathToJSIdentifier(import.from.valueWithoutQuotes));
      importStatements
          .add(js.statement('const # = require(#);', [moduleVar, import.from]));

      // TODO(jmesserly): optimize for the common case of a single import.
      for (var importName in import.namedImports) {
        assert(!importName.isStar); // import * not supported yet.
        var asName = importName.asName ?? importName.name;
        importStatements.add(js.statement(
            'const # = #.#', [asName, moduleVar, importName.name.name]));
      }
    }
    statements.insertAll(0, importStatements);

    if (exports.isNotEmpty) {
      var exportsVar = new Identifier('exports');
      statements.add(js.comment('Exports:'));
      for (var export in exports) {
        var names = export.exportedNames;
        assert(names != null); // export * not supported in legacy modules.
        for (var name in names) {
          statements
              .add(js.statement('#.# = #;', [exportsVar, name.name, name]));
        }
      }
    }

    // TODO(vsm): See https://github.com/dart-lang/dev_compiler/issues/512
    // This extra level of indirection should be unnecessary.
    var block =
        js.statement("(function() { 'use strict'; #; })()", [statements]);

    return new Program([block]);
  }
}

/// Escape [name] to make it into a valid identifier.
String pathToJSIdentifier(String name) {
  name = path.basenameWithoutExtension(name);
  if (name.length == 0) return r'$';

  // Escape any invalid characters
  StringBuffer buffer = null;
  for (int i = 0; i < name.length; i++) {
    var ch = name[i];
    var needsEscape = ch == r'$' || _invalidCharInIdentifier.hasMatch(ch);
    if (needsEscape && buffer == null) {
      buffer = new StringBuffer(name.substring(0, i));
    }
    if (buffer != null) {
      buffer.write(needsEscape ? '\$${ch.codeUnits.join("")}' : ch);
    }
  }

  var result = buffer != null ? '$buffer' : name;
  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(new RegExp('[0-9]')) || invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = new RegExp(r'[^A-Za-z_$0-9]');
