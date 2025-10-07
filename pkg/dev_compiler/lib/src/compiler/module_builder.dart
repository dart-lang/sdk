// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:path/path.dart' as p;

import '../js_ast/js_ast.dart';
import '../kernel/compiler.dart';
import '../kernel/compiler_new.dart';
import 'js_names.dart';

/// The module format to emit.
enum ModuleFormat {
  /// ECMAScript 6 module using import and export.
  es6('es6'),

  /// CommonJS module (used in Node.js)
  common('common'),

  /// Asynchronous Module Definition (AMD, used in browsers).
  amd('amd'),

  /// Dart Dev Compiler's own format.
  ddc('ddc'),

  // New version of ddc module system that will support hot reload.
  // TODO(nshahan) Eventually replace the existing `ddc` with this format.
  ddcLibraryBundle('ddc');

  const ModuleFormat(this.flagName);

  /// The name of the module format passed to DDC's `--modules` flag.
  final String flagName;
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
    'legacy': ModuleFormat.ddc,
  };
  var selected = formats[s];
  if (selected == null) {
    throw ArgumentError(
      'Invalid module format `$s`, allowed formats are: '
      '`${formats.keys.join(', ')}`',
    );
  }
  return selected;
}

/// Parse the module format option added by [addModuleFormatOptions].
List<ModuleFormat> parseModuleFormatOption(ArgResults args) {
  return args.multiOption('modules').map(parseModuleFormat).toList();
}

/// Adds an option to the [argParser] for choosing the module format, optionally
/// [allowMultiple] formats to be specified, with each emitted into a separate
/// file.
void addModuleFormatOptions(ArgParser argParser, {bool hide = true}) {
  argParser.addMultiOption(
    'modules',
    help: 'module pattern to emit',
    allowed: [
      'es6',
      'common',
      'amd',
      'ddc',
      'legacy', // renamed to ddc
      'node', // renamed to commonjs
      'all', // to emit all flavors for the SDK
    ],
    allowedHelp: {
      'es6': 'ECMAScript 6 modules',
      'common': 'CommonJS/Node.js modules',
      'amd': 'AMD/RequireJS modules',
    },
    defaultsTo: ['amd'],
  );
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
      return DdcModuleBuilder().build(module);
    case ModuleFormat.common:
      return CommonJSModuleBuilder().build(module);
    case ModuleFormat.amd:
      return AmdModuleBuilder().build(module);
    case ModuleFormat.ddcLibraryBundle:
      return DdcLibraryBundleBuilder().build(module);
    case ModuleFormat.es6:
      return module;
  }
}

/// Transforms an ES6 [function] into a given module [format].
///
/// Because JS ASTs are immutable the resulting function will share as much
/// structure as possible with the original. The transformation is a shallow one
/// that affects the [ImportDeclaration]s from [items].
///
/// Returns a new function that combines all statements from transformed imports
/// from [items] and the body of the [function].
Fun transformFunctionModuleFormat(
  List<ModuleItem> items,
  Fun function,
  ModuleFormat format,
) {
  switch (format) {
    case ModuleFormat.ddc:
      return DdcModuleBuilder().buildFunctionWithImports(items, function);
    case ModuleFormat.amd:
      return AmdModuleBuilder().buildFunctionWithImports(items, function);
    case ModuleFormat.ddcLibraryBundle:
      return DdcLibraryBundleBuilder().buildFunctionWithImports(
        items,
        function,
      );
    default:
      throw UnsupportedError(
        'Incremental build does not support $format module format',
      );
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
  void visitProgram(Program module) {
    visitModuleItems(module.body);
  }

  /// Collect [imports], [exports] and [statements] from the ES6 [items].
  ///
  /// For exports, this will also add their body to [statements] in the
  /// appropriate position.
  void visitModuleItems(List<ModuleItem> items) {
    for (var item in items) {
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

  void clear() {
    imports.clear();
    exports.clear();
    statements.clear();
  }
}

/// Generates DDC modules with our `ddc_module_loader.js` loading mechanism.
class DdcModuleBuilder extends _ModuleBuilder {
  /// Build a module variable definition for [import].
  ///
  /// Used to load modules referenced in the expression during expression
  /// evaluation.
  static Statement buildLoadModule(
    Identifier moduleVar,
    ImportDeclaration import,
  ) => js.statement('const # = dart_library.import(#);', [
    moduleVar,
    import.from,
  ]);

  /// Build library variable definitions for all libraries from [import].
  static List<Statement> buildImports(
    Identifier moduleVar,
    ImportDeclaration import,
    bool deferModules,
  ) {
    var items = <Statement>[];

    for (var importName in import.namedImports!) {
      // import * is not emitted by the compiler, so we don't handle it here.
      assert(!importName.isStar);

      var fromName = importName.name!.name;
      var asName = importName.asName ?? importName.name;
      if (deferModules && import.from.valueWithoutQuotes != dartSdkModule) {
        // Load non-SDK modules on demand (i.e., deferred).
        items.add(
          js.statement(
            'let # = dart_library.defer(#, #, function (mod, lib) {'
            '  # = mod;'
            '  # = lib;'
            '});',
            [asName, moduleVar, js.string(fromName), moduleVar, asName],
          ),
        );
      } else {
        items.add(js.statement('const # = #.#', [asName, moduleVar, fromName]));
      }
    }
    return items;
  }

  /// Build statements for [exports].
  static List<Statement> buildExports(
    Identifier exportsVar,
    List<ExportDeclaration> exports,
  ) {
    var items = <Statement>[];

    if (exports.isNotEmpty) {
      items.add(js.comment('Exports:'));
      // TODO(jmesserly): make these immutable in JS?
      for (var export in exports) {
        // export * (exportedNames is null) is not emitted by the compiler, so
        // we don't handle it here.
        var names = export.exportedNames!;
        for (var name in names) {
          var alias = name.asName ?? name.name!;
          items.add(
            js.statement('#.# = #;', [exportsVar, alias.name, name.name]),
          );
        }
      }
    }
    return items;
  }

  /// Build function body with all necessary imports included.
  ///
  /// Used for the top level synthetic function generated during expression
  /// compilation, in order to include all the context needed for evaluation
  /// inside it.
  ///
  /// Returns a new function that combines all statements from transformed
  /// imports from [items] and the body of the [function].
  Fun buildFunctionWithImports(List<ModuleItem> items, Fun function) {
    clear();
    visitModuleItems(items);

    var moduleImports = _collectModuleImports(imports);
    var importStatements = <Statement>[];

    for (var p in moduleImports) {
      var moduleVar = p.key;
      var import = p.value;
      importStatements.add(buildLoadModule(moduleVar, import));
      importStatements.addAll(buildImports(moduleVar, import, false));
    }

    return Fun(
      function.params,
      Block([...importStatements, ...function.body.statements]),
    );
  }

  Program build(Program module) {
    // Collect imports/exports/statements.
    visitProgram(module);

    var exportsVar = ScopedId('exports');
    var parameters = <Identifier>[exportsVar];
    var importNames = <Expression>[];

    var moduleImports = _collectModuleImports(imports);
    var importStatements = <Statement>[];

    for (var p in moduleImports) {
      var moduleVar = p.key;
      var import = p.value;
      importNames.add(import.from);
      parameters.add(moduleVar);
      importStatements.addAll(buildImports(moduleVar, import, true));
    }

    // Prepend import statements.
    statements.insertAll(0, importStatements);

    // Append export statements.
    statements.addAll(buildExports(exportsVar, exports));

    var moduleName = module.name!;
    var resultModule = NamedFunction(
      loadFunctionIdentifier(moduleName),
      js.fun("function(#) { 'use strict'; #; }", [parameters, statements]),
      true,
    );

    var moduleDef = js.statement('dart_library.library(#, #, #, #, #)', [
      js.string(moduleName, "'"),
      LiteralNull(),
      js.commentExpression(
        'Imports',
        ArrayInitializer(importNames, multiline: true),
      ),
      resultModule,
      ProgramCompiler.metricsLocationID,
    ]);
    return Program(<ModuleItem>[...module.header, moduleDef]);
  }
}

/// Generates CommonJS modules (used by Node.js).
class CommonJSModuleBuilder extends _ModuleBuilder {
  Program build(Program module) {
    var importStatements = [js.statement("'use strict';")];

    // Collect imports/exports/statements.
    visitProgram(module);

    for (var import in imports) {
      // TODO(jmesserly): we could use destructuring here.
      var moduleVar = ScopedId(
        pathToJSIdentifier(import.from.valueWithoutQuotes),
      );
      importStatements.add(
        js.statement('const # = require(#);', [moduleVar, import.from]),
      );

      // TODO(jmesserly): optimize for the common case of a single import.
      for (var importName in import.namedImports!) {
        // import * is not emitted by the compiler, so we don't support it here.
        assert(!importName.isStar);

        var libraryName = importName.name!.name;
        var asName = importName.asName ?? importName.name;
        importStatements.add(
          js.statement('const # = #.#', [asName, moduleVar, libraryName]),
        );
      }
    }
    statements.insertAll(0, importStatements);

    if (exports.isNotEmpty) {
      var exportsVar = Identifier('exports');
      statements.add(js.comment('Exports:'));
      for (var export in exports) {
        // export * (exportedNames is null) is not emitted by the compiler, so
        // we don't handle it here.
        var names = export.exportedNames!;
        for (var name in names) {
          var alias = name.asName ?? name.name!;
          statements.add(
            js.statement('#.# = #;', [exportsVar, alias.name, name.name]),
          );
        }
      }
    }

    return Program(<ModuleItem>[...module.header, ...statements]);
  }
}

/// Generates AMD modules (used in browsers with RequireJS).
class AmdModuleBuilder extends _ModuleBuilder {
  AmdModuleBuilder();

  /// Build a module variable definition for [import].
  ///
  /// Used to load modules referenced in the expression during expression
  /// evaluation.
  static Statement buildLoadModule(
    Identifier moduleVar,
    ImportDeclaration import,
  ) => js.statement('const # = require(#);', [moduleVar, import.from]);

  /// Build library variable definitions for all libraries from [import].
  static List<Statement> buildImports(
    Identifier moduleVar,
    ImportDeclaration import,
  ) {
    var items = <Statement>[];

    for (var importName in import.namedImports!) {
      // import * is not emitted by the compiler, so we don't handle it here.
      assert(!importName.isStar);

      var libraryName = importName.name!.name;
      var asName = importName.asName ?? importName.name;
      items.add(
        js.statement('const # = #.#', [asName, moduleVar, libraryName]),
      );
    }
    return items;
  }

  /// Build statements for [exports].
  static List<Statement> buildExports(List<ExportDeclaration> exports) {
    var items = <Statement>[];

    if (exports.isNotEmpty) {
      var exportedProps = <Property>[];
      for (var export in exports) {
        // export * (exportedNames is null) is not emitted by the compiler, so
        // we don't handle it here.
        var names = export.exportedNames!;
        for (var name in names) {
          var alias = name.asName ?? name.name!;
          exportedProps.add(Property(js.string(alias.name), name.name!));
        }
      }
      items.add(js.comment('Exports:'));
      items.add(Return(ObjectInitializer(exportedProps, multiline: true)));
    }
    return items;
  }

  /// Build function body with all necessary imports included.
  ///
  /// Used for the top level synthetic function generated during expression
  /// compilation, in order to include all the context needed for evaluation
  /// inside it.
  ///
  /// Returns a new function that combines all statements from transformed
  /// imports from [items] and the body of the [function].
  Fun buildFunctionWithImports(List<ModuleItem> items, Fun function) {
    clear();
    visitModuleItems(items);

    var moduleImports = _collectModuleImports(imports);
    var importStatements = <Statement>[];

    for (var p in moduleImports) {
      var moduleVar = p.key;
      var import = p.value;
      importStatements.add(buildLoadModule(moduleVar, import));
      importStatements.addAll(buildImports(moduleVar, import));
    }

    return Fun(
      function.params,
      Block([...importStatements, ...function.body.statements]),
    );
  }

  Program build(Program module) {
    // Collect imports/exports/statements.
    visitProgram(module);

    var moduleImports = _collectModuleImports(imports);
    var importStatements = <Statement>[];
    var fnParams = <Identifier>[];
    var dependencies = <LiteralString>[];

    for (var p in moduleImports) {
      var moduleVar = p.key;
      var import = p.value;
      fnParams.add(moduleVar);
      dependencies.add(import.from);
      importStatements.addAll(buildImports(moduleVar, import));
    }

    // Prepend import statements.
    statements.insertAll(0, importStatements);

    // Append export statements.
    statements.addAll(buildExports(exports));

    var resultModule = NamedFunction(
      loadFunctionIdentifier(module.name!),
      js.fun("function(#) { 'use strict'; #; }", [fnParams, statements]),
      true,
    );
    var block = js.statement('define(#, #);', [
      ArrayInitializer(dependencies),
      resultModule,
    ]);

    return Program([...module.header, block]);
  }
}

/// Generates DDC bundles of libraries with our `ddc_module_loader.js` loading
/// mechanism. This format is compatible with hot reload.
class DdcLibraryBundleBuilder extends _ModuleBuilder {
  /// Build library variable definitions for all libraries from [import].
  static List<Statement> buildImports(
    Identifier? moduleVar,
    ImportDeclaration import,
  ) {
    var items = <Statement>[];

    var fromName = import.from;
    for (var importName in import.namedImports!) {
      // import * is not emitted by the compiler, so we don't handle it here.
      assert(!importName.isStar);

      var asName = importName.asName ?? importName.name;
      if (import.from.valueWithoutQuotes != dartSdkModule) {
        // Load non-SDK modules on demand (i.e., deferred).
        items.add(
          js.statement(
            'let # = dartDevEmbedder.importLibrary(#, function (lib) { '
            '# = lib; });',
            [asName, fromName, asName],
          ),
        );
      } else {
        items.add(
          js.statement('const # = dartDevEmbedder.importLibrary(#)', [
            asName,
            fromName,
          ]),
        );
      }
    }
    return items;
  }

  /// Build function body with all necessary imports included.
  ///
  /// Used for the top level synthetic function generated during expression
  /// compilation, in order to include all the context needed for evaluation
  /// inside it.
  ///
  /// Returns a new function that combines all statements from transformed
  /// imports from [items] and the body of the [function].
  Fun buildFunctionWithImports(List<ModuleItem> items, Fun function) {
    clear();
    visitModuleItems(items);

    var moduleImports = _collectModuleImports(imports);
    var importStatements = <Statement>[];

    for (var p in moduleImports) {
      var moduleVar = p.key;
      var import = p.value;
      importStatements.addAll(buildImports(moduleVar, import));
    }

    return Fun(
      function.params,
      Block([...importStatements, ...function.body.statements]),
    );
  }

  Program build(Program module) {
    if (module is! LibraryBundle) {
      // TODO(nshahan): Delete and update the argument type when this is the
      // only supported module format.
      throw ArgumentError.value(
        module,
        '`DdcLibraryBundleBuilder` requires `LibraryBundle`s as input to '
        '`.build()`.',
      );
    }
    var body = <ModuleItem>[];
    // Collect imports/exports/statements.
    for (var library in module.libraries) {
      // Handle each library separately.
      imports.clear();
      statements.clear();

      visitProgram(library);
      var moduleImports = _collectModuleImports(imports);
      var importStatements = <Statement>[];
      for (var p in moduleImports) {
        var moduleVar = p.key;
        var import = p.value;
        importStatements.addAll(buildImports(moduleVar, import));
      }
      // Prepend import statements.
      statements.insertAll(0, importStatements);
      // Package the library into an initialization function.
      var initFunction = NamedFunction(
        loadFunctionIdentifier(library.name!),
        js.fun("function(#) { 'use strict'; #; return #; }", [
          library.librarySelfVar!,
          statements,
          library.librarySelfVar!,
        ]),
        true,
      );
      var resultModule = js.statement('dartDevEmbedder.defineLibrary(#, #)', [
        js.string(library.name!),
        initFunction,
      ]);
      body.add(resultModule);
    }
    // The library bundle format only needs to keep track of source maps and
    // doesn't need the full `trackLibraries` call that other formats use.
    var setSourceMap = js.statement(
      'dartDevEmbedder.debugger.setSourceMap(#, #)',
      [js.string(module.name!), LibraryCompiler.sourceMapLocationID],
    );
    // Append all library definitions into a single file.
    return Program([...module.header, ...body, setSourceMap]);
  }
}

bool isSdkInternalRuntimeUri(Uri importUri) {
  return importUri.isScheme('dart') && importUri.path == '_runtime';
}

/// Returns a name that can be used to represent a library within the context
/// of a module. This name is not globally unique and therefore should not be
/// used as an import/export name for the library as this can lead to naming
/// collisions. Use [libraryUriToImportName] to ensure global uniqueness.
///
/// The name should be given to a [ScopedId] to ensure there are no local
/// collisions.
String libraryUriToJsIdentifier(Uri importUri) {
  if (importUri.isScheme('dart')) {
    return isSdkInternalRuntimeUri(importUri) ? 'dart' : importUri.path;
  }
  return pathToJSIdentifier(p.withoutExtension(importUri.pathSegments.last));
}

/// Returns a globally unique name that can be used to represent a library.
/// Since this name is unique, it can safely be used for imports and exports
/// to/from JS modules. If global uniqueness is not necessary, use
/// [libraryUriToJsIdentifier] which produces shorter names.
String libraryUriToImportName(Uri importUri) {
  if (importUri.isScheme('dart')) {
    return isSdkInternalRuntimeUri(importUri) ? 'dart' : importUri.path;
  }
  return pathToJSIdentifier(p.withoutExtension(importUri.path));
}

/// Creates function name given [moduleName].
String loadFunctionName(String moduleName) =>
    'load__${pathToJSIdentifier(moduleName.replaceAll('.', '_'))}';

/// Creates function name identifier given [moduleName].
Identifier loadFunctionIdentifier(String moduleName) =>
    Identifier(loadFunctionName(moduleName));

// Replacement string for path separators (i.e., '/', '\', '..').
final encodedSeparator = '__';

/// Group libraries from [imports] by modules.
List<MapEntry<Identifier, ImportDeclaration>> _collectModuleImports(
  List<ImportDeclaration> imports,
) {
  var result = <MapEntry<Identifier, ImportDeclaration>>[];
  for (var import in imports) {
    // TODO(jmesserly): we could use destructuring once Atom supports it.
    var moduleVar = ScopedId(
      pathToJSIdentifier(import.from.valueWithoutQuotes),
    );

    result.add(MapEntry<Identifier, ImportDeclaration>(moduleVar, import));
  }
  return result;
}
