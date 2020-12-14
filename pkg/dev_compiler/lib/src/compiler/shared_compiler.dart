// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:collection';
import 'package:meta/meta.dart';

import '../compiler/js_names.dart' as js_ast;
import '../compiler/module_containers.dart' show ModuleItemContainer;
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;

/// Shared code between Analyzer and Kernel backends.
///
/// This class should only implement functionality that depends purely on JS
/// classes, rather than on Analyzer/Kernel types.
abstract class SharedCompiler<Library, Class, InterfaceType, FunctionNode> {
  /// When inside a `[]=` operator, this will be a non-null value that should be
  /// returned by any `return;` statement.
  ///
  /// This lets DDC use the setter method's return value directly.
  final List<js_ast.Identifier> _operatorSetResultStack = [];

  /// Private member names in this module, organized by their library.
  final _privateNames = HashMap<Library, HashMap<String, js_ast.TemporaryId>>();

  /// Holds all top-level JS symbols (used for caching or indexing fields).
  final _symbolContainer = ModuleItemContainer<js_ast.Identifier>.asObject('S',
      keyToString: (js_ast.Identifier i) => '${i.name}');

  /// Extension member symbols for adding Dart members to JS types.
  ///
  /// These are added to the [extensionSymbolsModule]; see that field for more
  /// information.
  final _extensionSymbols = <String, js_ast.TemporaryId>{};

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  final _libraries = <Library, js_ast.Identifier>{};

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = <Library, js_ast.TemporaryId>{};

  /// The identifier used to reference DDC's core "dart:_runtime" library from
  /// generated JS code, typically called "dart" e.g. `dart.dcall`.
  js_ast.Identifier runtimeModule;

  /// The identifier used to reference DDC's "extension method" symbols, used to
  /// safely add Dart-specific member names to JavaScript classes, such as
  /// primitive types (e.g. String) or DOM types in "dart:html".
  @protected
  js_ast.Identifier extensionSymbolsModule;

  /// Whether we're currently building the SDK, which may require special
  /// bootstrapping logic.
  ///
  /// This is initialized by [emitModule], which must be called before
  /// accessing this field.
  @protected
  bool isBuildingSdk;

  /// Whether or not to move top level symbols into top-level containers.
  ///
  /// This is set in both [emitModule] and [emitLibrary].
  /// Depends on [isBuildingSdk].
  @protected
  bool containerizeSymbols;

  /// The temporary variable that stores named arguments (these are passed via a
  /// JS object literal, to match JS conventions).
  @protected
  final namedArgumentTemp = js_ast.TemporaryId('opts');

  /// The list of output module items, in the order they need to be emitted in.
  @protected
  final moduleItems = <js_ast.ModuleItem>[];

  /// Like [moduleItems] but for items that should be emitted after classes.
  ///
  /// This is used for deferred supertypes of mutually recursive non-generic
  /// classes.
  @protected
  final afterClassDefItems = <js_ast.ModuleItem>[];

  /// The type used for private Dart [Symbol]s.
  @protected
  InterfaceType get privateSymbolType;

  /// The type used for public Dart [Symbol]s.
  @protected
  InterfaceType get internalSymbolType;

  /// The current library being compiled.
  @protected
  Library get currentLibrary;

  /// The library for dart:core in the SDK.
  @protected
  Library get coreLibrary;

  /// The import URI of current library.
  @protected
  Uri get currentLibraryUri;

  /// The current function being compiled, if any.
  @protected
  FunctionNode get currentFunction;

  /// Choose a canonical name from the [library] element.
  @protected
  String jsLibraryName(Library library);

  /// Choose a module-unique name from the [library] element.
  ///
  /// Returns null if no alias exists or there are multiple output paths
  /// (e.g., when compiling the Dart SDK).
  ///
  /// This never uses the library's name (the identifier in the `library`
  /// declaration) as it doesn't have any meaningful rules enforced.
  @protected
  String jsLibraryAlias(Library library);

  /// Debugger friendly name for a Dart [library].
  @protected
  String jsLibraryDebuggerName(Library library);

  /// Debugger friendly names for all parts in a Dart [library].
  @protected
  Iterable<String> jsPartDebuggerNames(Library library);

  /// Gets the module import URI that contains [library].
  @protected
  String libraryToModule(Library library);

  /// Returns true if the library [l] is "dart:_runtime".
  @protected
  bool isSdkInternalRuntime(Library l);

  /// Whether any superclass of [c] defines a static [name].
  @protected
  bool superclassHasStatic(Class c, String name);

  /// Emits the expression necessary to access a constructor of [type];
  @protected
  js_ast.Expression emitConstructorAccess(InterfaceType type);

  /// When compiling the body of a `operator []=` method, this will be non-null
  /// and will indicate the the value that should be returned from any `return;`
  /// statements.
  js_ast.Identifier get _operatorSetResult {
    var stack = _operatorSetResultStack;
    return stack.isEmpty ? null : stack.last;
  }

  /// Called when starting to emit methods/functions, in particular so we can
  /// implement special handling of the user-defined `[]=` and `==` methods.
  ///
  /// See also [exitFunction] and [emitReturnStatement].
  @protected
  void enterFunction(String name, List<js_ast.Parameter> formals,
      bool Function() isLastParamMutated) {
    if (name == '[]=') {
      _operatorSetResultStack.add(isLastParamMutated()
          ? js_ast.TemporaryId((formals.last as js_ast.Identifier).name)
          : formals.last as js_ast.Identifier);
    } else {
      _operatorSetResultStack.add(null);
    }
  }

  /// Called when finished emitting methods/functions, and must correspond to a
  /// previous [enterFunction] call.
  @protected
  js_ast.Block exitFunction(
      String name, List<js_ast.Parameter> formals, js_ast.Block code) {
    var setOperatorResult = _operatorSetResultStack.removeLast();
    if (setOperatorResult != null) {
      // []= methods need to return the value. We could also address this at
      // call sites, but it's less code size to handle inside the operator.
      var valueParam = formals.last;
      var statements = code.statements;
      if (statements.isEmpty || !statements.last.alwaysReturns) {
        statements.add(js_ast.Return(setOperatorResult));
      }
      if (!identical(setOperatorResult, valueParam)) {
        // If the value parameter was mutated, then we use a temporary
        // variable to track the initial value
        formals.last = setOperatorResult;
        code = js
            .block('{ let # = #; #; }', [valueParam, setOperatorResult, code]);
      }
    }
    return code;
  }

  /// Emits a return statement `return <value>;`, handling special rules for
  /// the `operator []=` method.
  @protected
  js_ast.Statement emitReturnStatement(js_ast.Expression value) {
    if (_operatorSetResult != null) {
      var result = js_ast.Return(_operatorSetResult);
      return value != null
          ? js_ast.Block([value.toStatement(), result])
          : result;
    }
    return value != null ? value.toReturn() : js_ast.Return();
  }

  /// Prepends the `dart.` and then uses [js.call] to parse the specified JS
  /// [code] template, passing [args].
  ///
  /// For example:
  ///
  ///     runtimeCall('asInt(#)', [<expr>])
  ///
  /// Generates a JS AST representing:
  ///
  ///     dart.asInt(<expr>)
  ///
  @protected
  js_ast.Expression runtimeCall(String code, [List<Object> args]) =>
      js.call('#.$code', <Object>[runtimeModule, ...?args]);

  /// Calls [runtimeCall] and uses `toStatement()` to convert the resulting
  /// expression into a statement.
  @protected
  js_ast.Statement runtimeStatement(String code, [List<Object> args]) =>
      runtimeCall(code, args).toStatement();

  /// Emits a private name JS Symbol for [name] scoped to the Dart [library].
  ///
  /// If the same name is used in multiple libraries in the same module,
  /// distinct symbols will be used, so each library will have distinct private
  /// member names, that won't collide at runtime, as required by the Dart
  /// language spec.
  ///
  /// If an [id] is provided, try to use that.
  ///
  /// TODO(vsm): Clean up id generation logic.  This method is used to both
  /// define new symbols and to reference existing ones.  If it's called
  /// multiple times with same [library] and [name], we'll allocate redundant
  /// top-level variables (see callers to this method).
  @protected
  js_ast.TemporaryId emitPrivateNameSymbol(Library library, String name,
      [js_ast.TemporaryId id]) {
    /// Initializes the JS `Symbol` for the private member [name] in [library].
    ///
    /// If the library is in the current JS module ([_libraries] contains it),
    /// the private name will be created and exported. The exported symbol is
    /// used for a few things:
    ///
    /// - private fields of constant objects
    /// - stateful hot reload (not yet implemented)
    /// - correct library scope in REPL (not yet implemented)
    ///
    /// If the library is imported, then the existing private name will be
    /// retrieved from it. In both cases, we use the same `dart.privateName`
    /// runtime call.
    js_ast.TemporaryId initPrivateNameSymbol() {
      var idName = name.endsWith('=') ? name.replaceAll('=', '_') : name;
      idName = idName.replaceAll(js_ast.invalidCharInIdentifier, '_');
      id ??= js_ast.TemporaryId(idName);
      addSymbol(
          id,
          js.call('#.privateName(#, #)',
              [runtimeModule, emitLibraryName(library), js.string(name)]));
      if (!containerizeSymbols) {
        // TODO(vsm): Change back to `const`.
        // See https://github.com/dart-lang/sdk/issues/40380.
        moduleItems.add(js.statement('var # = #.privateName(#, #)',
            [id, runtimeModule, emitLibraryName(library), js.string(name)]));
      }
      return id;
    }

    var privateNames = _privateNames.putIfAbsent(library, () => HashMap());
    return privateNames.putIfAbsent(name, initPrivateNameSymbol);
  }

  /// Emits a private name JS Symbol for [memberName] unique to a Dart
  /// class [className].
  ///
  /// This is now required for fields of constant objects that may be
  /// overridden within the same library.
  @protected
  js_ast.TemporaryId emitClassPrivateNameSymbol(
      Library library, String className, String memberName,
      [js_ast.TemporaryId id]) {
    return emitPrivateNameSymbol(library, '$className.$memberName', id);
  }

  /// Emits an expression to set the property [nameExpr] on the class [className],
  /// with [value].
  ///
  /// This will use `className.name = value` if possible, otherwise it will use
  /// `dart.defineValue(className, name, value)`. This is required when
  /// `FunctionNode.prototype` already defins a getters with the same name.
  @protected
  js_ast.Expression defineValueOnClass(Class c, js_ast.Expression className,
      js_ast.Expression nameExpr, js_ast.Expression value) {
    var args = [className, nameExpr, value];
    if (nameExpr is js_ast.LiteralString) {
      var name = nameExpr.valueWithoutQuotes;
      if (js_ast.isFunctionPrototypeGetter(name) ||
          superclassHasStatic(c, name)) {
        return runtimeCall('defineValue(#, #, #)', args);
      }
    }
    return js.call('#.# = #', args);
  }

  /// Caches a constant (list/set/map or class instance) in a variable, so it's
  /// only canonicalized once at this location in the code, which improves
  /// performance.
  ///
  /// This method ensures the constant is not initialized until use.
  ///
  /// The expression [jsExpr] should contain the already-canonicalized constant.
  /// If the constant is not canonicalized yet, it should be wrapped in the
  /// appropriate call, such as:
  ///
  /// - dart.constList (for Lists),
  /// - dart.constMap (for Maps),
  /// - dart.constSet (for Sets),
  /// - dart.const (for other instances of classes)
  ///
  /// [canonicalizeConstObject] can be used for class instances; it will wrap
  /// the expression in `dart.const` and then call this method.
  ///
  /// If the same consant is used elsewhere (in this module, or another module),
  /// that will require a second canonicalization. In general it is uncommon
  /// to define the same large constant (such as lists, maps) in different
  /// locations, because that requires copy+paste, so in practice this
  /// optimization is rather effective (we should consider caching once
  /// per-module, though, as that would be relatively easy for the compiler to
  /// implement once we have a single Kernel backend).
  @protected
  js_ast.Expression cacheConst(js_ast.Expression jsExpr) {
    if (currentFunction == null) return jsExpr;

    var temp = js_ast.TemporaryId('const');
    moduleItems.add(js.statement('let #;', [temp]));
    return js.call('# || (# = #)', [temp, temp, jsExpr]);
  }

  /// Emits a Dart Symbol with the given member [symbolName].
  ///
  /// If the symbol refers to a private name, its library will be set to the
  /// [currentLibrary], so the Symbol is scoped properly.
  @protected
  js_ast.Expression emitDartSymbol(String symbolName) {
    // TODO(vsm): Handle qualified symbols correctly.
    var last = symbolName.split('.').last;
    var name = js.escapedString(symbolName, "'");
    js_ast.Expression result;
    if (last.startsWith('_')) {
      var nativeSymbolAccessor =
          getSymbol(emitPrivateNameSymbol(currentLibrary, last));
      result = js.call('new #.new(#, #)', [
        emitConstructorAccess(privateSymbolType),
        name,
        nativeSymbolAccessor
      ]);
    } else {
      result = js.call(
          'new #.new(#)', [emitConstructorAccess(internalSymbolType), name]);
    }
    return canonicalizeConstObject(result);
  }

  /// Calls the `dart.const` function in "dart:_runtime" to canonicalize a
  /// constant instance of a user-defined class stored in [expr].
  @protected
  js_ast.Expression canonicalizeConstObject(js_ast.Expression expr) =>
      cacheConst(runtimeCall('const(#)', [expr]));

  /// Emits preamble for the module containing [libraries], and returns the
  /// list of module items for further items to be added.
  ///
  /// The preamble consists of initializing the identifiers for each library,
  /// that will be used to store their members. It also generates the
  /// appropriate ES6 `export` declaration to export them from this module.
  ///
  /// After the code for all of the library members is emitted,
  /// [emitImportsAndExtensionSymbols] should be used to emit imports/extension
  /// symbols into the list returned by this method. Finally, [finishModule]
  /// can be called to complete the module and return the resulting JS AST.
  ///
  /// This also initializes several fields: [runtimeModule],
  /// [extensionSymbolsModule], and the [_libraries] map needed by
  /// [emitLibraryName].
  @protected
  List<js_ast.ModuleItem> startModule(Iterable<Library> libraries) {
    if (isBuildingSdk) {
      // Don't allow these to be renamed when we're building the SDK.
      // There is JS code in dart:* that depends on their names.
      runtimeModule = js_ast.Identifier('dart');
      extensionSymbolsModule = js_ast.Identifier('dartx');
    } else {
      // Otherwise allow these to be renamed so users can write them.
      runtimeModule = js_ast.TemporaryId('dart');
      extensionSymbolsModule = js_ast.TemporaryId('dartx');
    }

    // Initialize our library variables.
    var items = <js_ast.ModuleItem>[];
    var exports = <js_ast.NameSpecifier>[];

    if (isBuildingSdk) {
      // Bootstrap the ability to create Dart library objects.
      var libraryProto = js_ast.TemporaryId('_library');
      items.add(js.statement('const # = Object.create(null)', libraryProto));
      items.add(js.statement(
          'const # = Object.create(#)', [runtimeModule, libraryProto]));
      items.add(js.statement('#.library = #', [runtimeModule, libraryProto]));
      exports.add(js_ast.NameSpecifier(runtimeModule));
    }

    for (var library in libraries) {
      if (isBuildingSdk && isSdkInternalRuntime(library)) {
        _libraries[library] = runtimeModule;
        continue;
      }
      var libraryId = js_ast.TemporaryId(jsLibraryName(library));
      _libraries[library] = libraryId;
      var alias = jsLibraryAlias(library);
      var aliasId = alias == null ? null : js_ast.TemporaryId(alias);

      // TODO(vsm): Change back to `const`.
      // See https://github.com/dart-lang/sdk/issues/40380.
      items.add(js.statement(
          'var # = Object.create(#.library)', [libraryId, runtimeModule]));
      exports.add(js_ast.NameSpecifier(libraryId, asName: aliasId));
    }

    // dart:_runtime has a magic module that holds extension method symbols.
    // TODO(jmesserly): find a cleaner design for this.
    if (isBuildingSdk) {
      var id = extensionSymbolsModule;
      // TODO(vsm): Change back to `const`.
      // See https://github.com/dart-lang/sdk/issues/40380.
      items.add(js
          .statement('var # = Object.create(#.library)', [id, runtimeModule]));
      exports.add(js_ast.NameSpecifier(id));
    }

    items.add(js_ast.ExportDeclaration(js_ast.ExportClause(exports)));

    if (isBuildingSdk) {
      // Initialize the private name function.
      // To bootstrap the SDK, this needs to be emitted before other code.
      var symbol = js_ast.TemporaryId('_privateNames');
      items.add(js.statement('const # = Symbol("_privateNames")', symbol));
      items.add(js.statement(r'''
        #.privateName = function(library, name) {
          let names = library[#];
          if (names == null) names = library[#] = new Map();
          let symbol = names.get(name);
          if (symbol == null) names.set(name, symbol = Symbol(name));
          return symbol;
        }
      ''', [runtimeModule, symbol, symbol]));
    }

    return items;
  }

  /// Returns the canonical name to refer to the Dart library.
  js_ast.Identifier emitLibraryName(Library library) {
    // Avoid adding the dart:_runtime to _imports when our runtime unit tests
    // import it explicitly. It will always be implicitly imported.
    if (isSdkInternalRuntime(library)) return runtimeModule;

    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(
            library, () => js_ast.TemporaryId(jsLibraryName(library)));
  }

  /// Emits imports and extension methods into [items].
  @protected
  void emitImportsAndExtensionSymbols(List<js_ast.ModuleItem> items) {
    var modules = <String, List<Library>>{};

    for (var import in _imports.keys) {
      modules.putIfAbsent(libraryToModule(import), () => []).add(import);
    }

    String coreModuleName;
    if (!_libraries.containsKey(coreLibrary)) {
      coreModuleName = libraryToModule(coreLibrary);
    }
    modules.forEach((module, libraries) {
      // Generate import directives.
      //
      // Our import variables are temps and can get renamed. Since our renaming
      // is integrated into js_ast, it is aware of this possibility and will
      // generate an "as" if needed. For example:
      //
      //     import {foo} from 'foo';         // if no rename needed
      //     import {foo as foo$} from 'foo'; // if rename was needed
      //
      var imports = libraries.map((library) {
        var alias = jsLibraryAlias(library);
        if (alias != null) {
          var aliasId = js_ast.TemporaryId(alias);
          return js_ast.NameSpecifier(aliasId, asName: _imports[library]);
        }
        return js_ast.NameSpecifier(_imports[library]);
      }).toList();
      if (module == coreModuleName) {
        imports.add(js_ast.NameSpecifier(runtimeModule));
        imports.add(js_ast.NameSpecifier(extensionSymbolsModule));
      }

      items.add(js_ast.ImportDeclaration(
          namedImports: imports, from: js.string(module, "'")));
    });

    // Initialize extension symbols
    _extensionSymbols.forEach((name, id) {
      js_ast.Expression value =
          js_ast.PropertyAccess(extensionSymbolsModule, propertyName(name));
      if (isBuildingSdk) {
        value = js.call('# = Symbol(#)', [value, js.string('dartx.$name')]);
      }
      if (!_symbolContainer.canEmit(id)) {
        // Extension symbols marked with noEmit are managed manually.
        // TODO(vsm): Change back to `const`.
        // See https://github.com/dart-lang/sdk/issues/40380.
        items.add(js.statement('var # = #;', [id, value]));
      }
      _symbolContainer[id] = value;
    });
  }

  void _emitDebuggerExtensionInfo(String name) {
    var properties = <js_ast.Property>[];
    var parts = <js_ast.Property>[];
    _libraries.forEach((library, value) {
      // TODO(jacobr): we could specify a short library name instead of the
      // full library uri if we wanted to save space.
      var libraryName = js.escapedString(jsLibraryDebuggerName(library));
      properties.add(js_ast.Property(libraryName, value));
      var partNames = jsPartDebuggerNames(library);
      if (partNames.isNotEmpty) {
        parts.add(js_ast.Property(libraryName, js.stringArray(partNames)));
      }
    });
    var module = js_ast.ObjectInitializer(properties, multiline: true);
    var partMap = js_ast.ObjectInitializer(parts, multiline: true);

    // Track the module name for each library in the module.
    // This data is only required for debugging.
    moduleItems.add(js.statement(
        '#.trackLibraries(#, #, #, $sourceMapLocationID);',
        [runtimeModule, js.string(name), module, partMap]));
  }

  /// Returns an accessor for [id] via the symbol container.
  /// E.g., transforms $sym to S$5.$sym.
  ///
  /// A symbol lookup on an id marked no emit omits the symbol accessor.
  js_ast.Expression getSymbol(js_ast.Identifier id) {
    return _symbolContainer.canEmit(id) ? _symbolContainer.access(id) : id;
  }

  /// Returns the raw JS value associated with [id].
  js_ast.Expression getSymbolValue(js_ast.Identifier id) {
    return _symbolContainer[id];
  }

  /// Inserts a symbol into the symbol table.
  js_ast.Expression addSymbol(js_ast.Identifier id, js_ast.Expression symbol) {
    _symbolContainer[id] = symbol;
    if (!containerizeSymbols) {
      _symbolContainer.setNoEmit(id);
    }
    return _symbolContainer[id];
  }

  /// Finishes the module created by [startModule], by combining the preable
  /// [items] with the [moduleItems] that have been emitted.
  ///
  /// The [moduleName] should specify the module's name, and the items should
  /// be the list resulting from startModule, with additional items added,
  /// but not including the contents of moduleItems (which will be handled by
  /// this method itself).
  ///
  /// Note, this function mutates the items list and returns it as the `body`
  /// field of the result.
  @protected
  js_ast.Program finishModule(
      List<js_ast.ModuleItem> items, String moduleName) {
    // TODO(jmesserly): there's probably further consolidation we can do
    // between DDC's two backends, by moving more code into this method, as the
    // code between `startModule` and `finishModule` is very similar in both.
    _emitDebuggerExtensionInfo(moduleName);

    // Emit all top-level JS symbol containers.
    items.addAll(_symbolContainer.emit());

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, moduleItems);
    moduleItems.clear();

    // Build the module.
    return js_ast.Program(items, name: moduleName);
  }

  /// Flattens blocks in [items] to a single list.
  ///
  /// This will not flatten blocks that are marked as being scopes.
  void _copyAndFlattenBlocks(
      List<js_ast.ModuleItem> result, Iterable<js_ast.ModuleItem> items) {
    for (var item in items) {
      if (item is js_ast.Block && !item.isScope) {
        _copyAndFlattenBlocks(result, item.statements);
      } else if (item != null) {
        result.add(item);
      }
    }
  }

  /// This is an internal method used by [_emitMemberName] and the
  /// optimized `dart:_runtime extensionSymbol` builtin to get the symbol
  /// for `dartx.<name>`.
  ///
  /// Do not call this directly; you want [_emitMemberName], which knows how to
  /// handle the many details involved in naming.
  @protected
  js_ast.TemporaryId getExtensionSymbolInternal(String name) {
    if (!_extensionSymbols.containsKey(name)) {
      var id = js_ast.TemporaryId(
          '\$${js_ast.friendlyNameForDartOperator[name] ?? name}');
      _extensionSymbols[name] = id;
      addSymbol(id, id);
    }
    return _extensionSymbols[name];
  }

  /// Shorthand for identifier-like property names.
  /// For now, we emit them as strings and the printer restores them to
  /// identifiers if it can.
  // TODO(jmesserly): avoid the round tripping through quoted form.
  @protected
  js_ast.LiteralString propertyName(String name) => js.string(name, "'");

  /// Unique identifiers indicating the locations to inline the corresponding
  /// information.
  ///
  /// We cannot generate the source map before the script it is for is
  /// generated so we have generate the script including this identifier in the
  /// JS AST, and then replace it once the source map is generated.  Similarly,
  /// metrics include the size of the source map.
  static const String sourceMapLocationID =
      'SourceMap3G5a8h6JVhHfdGuDxZr1EF9GQC8y0e6u';
  static const String metricsLocationID =
      'MetricsJ7xFWBfSv6ZjrW9yLb21GNzisZr3anSf5h';
}

/// Whether a variable with [name] is referenced in the [node].
bool variableIsReferenced(String name, js_ast.Node node) {
  var finder = _IdentifierFinder.instance;
  finder.nameToFind = name;
  finder.found = false;
  node.accept(finder);
  return finder.found;
}

class _IdentifierFinder extends js_ast.BaseVisitor<void> {
  String nameToFind;
  bool found = false;

  static final instance = _IdentifierFinder();

  @override
  void visitIdentifier(node) {
    if (node.name == nameToFind) found = true;
  }

  @override
  void visitNode(node) {
    if (!found) super.visitNode(node);
  }
}

class YieldFinder extends js_ast.BaseVisitor<void> {
  bool hasYield = false;
  bool hasThis = false;
  bool _nestedFunction = false;

  @override
  void visitThis(js_ast.This node) {
    hasThis = true;
  }

  @override
  void visitFunctionExpression(js_ast.FunctionExpression node) {
    var savedNested = _nestedFunction;
    _nestedFunction = true;
    super.visitFunctionExpression(node);
    _nestedFunction = savedNested;
  }

  @override
  void visitYield(js_ast.Yield node) {
    if (!_nestedFunction) hasYield = true;
    super.visitYield(node);
  }

  @override
  void visitNode(js_ast.Node node) {
    if (hasYield && hasThis) return; // found both, nothing more to do.
    super.visitNode(node);
  }
}

/// Given the function [fn], returns a function declaration statement, binding
/// `this` and `super` if necessary (using an arrow function).
js_ast.Statement toBoundFunctionStatement(
    js_ast.Fun fn, js_ast.Identifier name) {
  if (usesThisOrSuper(fn)) {
    return js.statement('const # = (#) => {#}', [name, fn.params, fn.body]);
  } else {
    return js_ast.FunctionDeclaration(name, fn);
  }
}

/// Returns whether [node] uses `this` or `super`.
bool usesThisOrSuper(js_ast.Expression node) {
  var finder = _ThisOrSuperFinder.instance;
  finder.found = false;
  node.accept(finder);
  return finder.found;
}

class _ThisOrSuperFinder extends js_ast.BaseVisitor<void> {
  bool found = false;

  static final instance = _ThisOrSuperFinder();

  @override
  void visitThis(js_ast.This node) {
    found = true;
  }

  @override
  void visitSuper(js_ast.Super node) {
    found = true;
  }

  @override
  void visitNode(js_ast.Node node) {
    if (!found) super.visitNode(node);
  }
}
