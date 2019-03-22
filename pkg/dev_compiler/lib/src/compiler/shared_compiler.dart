// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:meta/meta.dart';

import '../compiler/js_metalet.dart' as JS;
import '../compiler/js_names.dart' as JS;
import '../compiler/js_utils.dart' as JS;
import '../js_ast/js_ast.dart' as JS;
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
  final List<JS.Identifier> _operatorSetResultStack = [];

  /// Private member names in this module, organized by their library.
  final _privateNames = HashMap<Library, HashMap<String, JS.TemporaryId>>();

  /// Extension member symbols for adding Dart members to JS types.
  ///
  /// These are added to the [extensionSymbolsModule]; see that field for more
  /// information.
  final _extensionSymbols = <String, JS.TemporaryId>{};

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  final _libraries = <Library, JS.Identifier>{};

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = <Library, JS.TemporaryId>{};

  /// The identifier used to reference DDC's core "dart:_runtime" library from
  /// generated JS code, typically called "dart" e.g. `dart.dcall`.
  @protected
  JS.Identifier runtimeModule;

  /// The identifier used to reference DDC's "extension method" symbols, used to
  /// safely add Dart-specific member names to JavaScript classes, such as
  /// primitive types (e.g. String) or DOM types in "dart:html".
  @protected
  JS.Identifier extensionSymbolsModule;

  /// Whether we're currently building the SDK, which may require special
  /// bootstrapping logic.
  ///
  /// This is initialized by [startModule], which must be called before
  /// accessing this field.
  @protected
  bool isBuildingSdk;

  /// The temporary variable that stores named arguments (these are passed via a
  /// JS object literal, to match JS conventions).
  @protected
  final namedArgumentTemp = JS.TemporaryId('opts');

  /// The list of output module items, in the order they need to be emitted in.
  @protected
  final moduleItems = <JS.ModuleItem>[];

  /// Like [moduleItems] but for items that should be emitted after classes.
  ///
  /// This is used for deferred supertypes of mutually recursive non-generic
  /// classes.
  @protected
  final afterClassDefItems = <JS.ModuleItem>[];

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
  ///
  /// This never uses the library's name (the identifier in the `library`
  /// declaration) as it doesn't have any meaningful rules enforced.
  @protected
  String jsLibraryName(Library library);

  /// Debugger friendly name for a Dart [library].
  @protected
  String jsLibraryDebuggerName(Library library);

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
  JS.Expression emitConstructorAccess(InterfaceType type);

  /// When compiling the body of a `operator []=` method, this will be non-null
  /// and will indicate the the value that should be returned from any `return;`
  /// statements.
  JS.Identifier get _operatorSetResult {
    var stack = _operatorSetResultStack;
    return stack.isEmpty ? null : stack.last;
  }

  /// Called when starting to emit methods/functions, in particular so we can
  /// implement special handling of the user-defined `[]=` and `==` methods.
  ///
  /// See also [exitFunction] and [emitReturnStatement].
  @protected
  void enterFunction(String name, List<JS.Parameter> formals,
      bool Function() isLastParamMutated) {
    if (name == '[]=') {
      _operatorSetResultStack.add(isLastParamMutated()
          ? JS.TemporaryId((formals.last as JS.Identifier).name)
          : formals.last);
    } else {
      _operatorSetResultStack.add(null);
    }
  }

  /// Called when finished emitting methods/functions, and must correspond to a
  /// previous [enterFunction] call.
  @protected
  JS.Block exitFunction(
      String name, List<JS.Parameter> formals, JS.Block code) {
    if (name == "==" &&
        formals.isNotEmpty &&
        currentLibraryUri.scheme != 'dart') {
      // In Dart `operator ==` methods are not called with a null argument.
      // This is handled before calling them. For performance reasons, we push
      // this check inside the method, to simplify our `equals` helper.
      //
      // TODO(jmesserly): in most cases this check is not necessary, because
      // the Dart code already handles it (typically by an `is` check).
      // Eliminate it when possible.
      code = js
          .block('{ if (# == null) return false; #; }', [formals.first, code]);
    }
    var setOperatorResult = _operatorSetResultStack.removeLast();
    if (setOperatorResult != null) {
      // []= methods need to return the value. We could also address this at
      // call sites, but it's less code size to handle inside the operator.
      var valueParam = formals.last;
      var statements = code.statements;
      if (statements.isEmpty || !statements.last.alwaysReturns) {
        statements.add(JS.Return(setOperatorResult));
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
  JS.Statement emitReturnStatement(JS.Expression value) {
    if (_operatorSetResult != null) {
      var result = JS.Return(_operatorSetResult);
      return value != null ? JS.Block([value.toStatement(), result]) : result;
    }
    return value != null ? value.toReturn() : JS.Return();
  }

  /// Prepends the `dart.` and then uses [js.call] to parse the specified JS
  /// [code] template, passing [args].
  ///
  /// For example:
  ///
  ///     runtimeCall('asInt(#)', expr)
  ///
  /// Generates a JS AST representing:
  ///
  ///     dart.asInt(<expr>)
  ///
  @protected
  JS.Expression runtimeCall(String code, [args]) {
    if (args != null) {
      var newArgs = <Object>[runtimeModule];
      if (args is Iterable) {
        newArgs.addAll(args);
      } else {
        newArgs.add(args);
      }
      args = newArgs;
    } else {
      args = runtimeModule;
    }
    return js.call('#.$code', args);
  }

  /// Calls [runtimeCall] and uses `toStatement()` to convert the resulting
  /// expression into a statement.
  @protected
  JS.Statement runtimeStatement(String code, [args]) {
    return runtimeCall(code, args).toStatement();
  }

  /// Emits a private name JS Symbol for [name] scoped to the Dart [library].
  ///
  /// If the same name is used in multiple libraries in the same module,
  /// distinct symbols will be used, so the names cannot be referenced outside
  /// of their library.
  @protected
  JS.TemporaryId emitPrivateNameSymbol(Library library, String name) {
    // TODO(jmesserly): fix this to support referring to private symbols from
    // libraries that aren't in the current module.
    //
    // This is needed for several uses cases:
    // - const instances of classes (which directly initialize fields via an
    //   object literal).
    // - noSuchMethod stubs created when an interface is implemented that had
    //   private members from another library.
    // - stateful hot reload, where we need the ability to patch private
    //   class members.
    //
    // See https://github.com/dart-lang/sdk/issues/36252
    return _privateNames.putIfAbsent(library, () => HashMap()).putIfAbsent(name,
        () {
      var idName = name;
      if (idName.endsWith('=')) {
        idName = idName.replaceAll('=', '_');
      }
      var id = JS.TemporaryId(idName);
      moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(name, "'")]));
      return id;
    });
  }

  /// Emits an expression to set the property [nameExpr] on the class [className],
  /// with [value].
  ///
  /// This will use `className.name = value` if possible, otherwise it will use
  /// `dart.defineValue(className, name, value)`. This is required when
  /// `FunctionNode.prototype` already defins a getters with the same name.
  @protected
  JS.Expression defineValueOnClass(Class c, JS.Expression className,
      JS.Expression nameExpr, JS.Expression value) {
    var args = [className, nameExpr, value];
    if (nameExpr is JS.LiteralString) {
      var name = nameExpr.valueWithoutQuotes;
      if (JS.isFunctionPrototypeGetter(name) || superclassHasStatic(c, name)) {
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
  JS.Expression cacheConst(JS.Expression jsExpr) {
    if (currentFunction == null) return jsExpr;

    var temp = JS.TemporaryId('const');
    moduleItems.add(js.statement('let #;', [temp]));
    return js.call('# || (# = #)', [temp, temp, jsExpr]);
  }

  /// Emits a Dart Symbol with the given member [symbolName].
  ///
  /// If the symbol refers to a private name, its library will be set to the
  /// [currentLibrary], so the Symbol is scoped properly.
  @protected
  JS.Expression emitDartSymbol(String symbolName) {
    // TODO(vsm): Handle qualified symbols correctly.
    var last = symbolName.split('.').last;
    var name = js.escapedString(symbolName, "'");
    JS.Expression result;
    if (last.startsWith('_')) {
      var nativeSymbol = emitPrivateNameSymbol(currentLibrary, last);
      result = js.call('new #.new(#, #)',
          [emitConstructorAccess(privateSymbolType), name, nativeSymbol]);
    } else {
      result = js.call(
          'new #.new(#)', [emitConstructorAccess(internalSymbolType), name]);
    }
    return canonicalizeConstObject(result);
  }

  /// Calls the `dart.const` function in "dart:_runtime" to canonicalize a
  /// constant instance of a user-defined class stored in [expr].
  @protected
  JS.Expression canonicalizeConstObject(JS.Expression expr) =>
      cacheConst(runtimeCall('const(#)', expr));

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
  /// This also initializes several fields: [isBuildingSdk], [runtimeModule],
  /// [extensionSymbolsModule], as well as the [_libraries] map needed by
  /// [emitLibraryName].
  @protected
  List<JS.ModuleItem> startModule(Iterable<Library> libraries) {
    isBuildingSdk = libraries.any(isSdkInternalRuntime);
    if (isBuildingSdk) {
      // Don't allow these to be renamed when we're building the SDK.
      // There is JS code in dart:* that depends on their names.
      runtimeModule = JS.Identifier('dart');
      extensionSymbolsModule = JS.Identifier('dartx');
    } else {
      // Otherwise allow these to be renamed so users can write them.
      runtimeModule = JS.TemporaryId('dart');
      extensionSymbolsModule = JS.TemporaryId('dartx');
    }

    // Initialize our library variables.
    var items = <JS.ModuleItem>[];
    var exports = <JS.NameSpecifier>[];

    if (isBuildingSdk) {
      // Bootstrap the ability to create Dart library objects.
      var libraryProto = JS.TemporaryId('_library');
      items.add(js.statement('const # = Object.create(null)', libraryProto));
      items.add(js.statement(
          'const # = Object.create(#)', [runtimeModule, libraryProto]));
      items.add(js.statement('#.library = #', [runtimeModule, libraryProto]));
      exports.add(JS.NameSpecifier(runtimeModule));
    }

    for (var library in libraries) {
      if (isBuildingSdk && isSdkInternalRuntime(library)) {
        _libraries[library] = runtimeModule;
        continue;
      }
      var id = JS.TemporaryId(jsLibraryName(library));
      _libraries[library] = id;

      items.add(js.statement(
          'const # = Object.create(#.library)', [id, runtimeModule]));
      exports.add(JS.NameSpecifier(id));
    }

    // dart:_runtime has a magic module that holds extension method symbols.
    // TODO(jmesserly): find a cleaner design for this.
    if (isBuildingSdk) {
      var id = extensionSymbolsModule;
      items.add(js.statement(
          'const # = Object.create(#.library)', [id, runtimeModule]));
      exports.add(JS.NameSpecifier(id));
    }

    items.add(JS.ExportDeclaration(JS.ExportClause(exports)));
    return items;
  }

  /// Returns the canonical name to refer to the Dart library.
  @protected
  JS.Identifier emitLibraryName(Library library) {
    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(
            library, () => JS.TemporaryId(jsLibraryName(library)));
  }

  /// Emits imports and extension methods into [items].
  @protected
  void emitImportsAndExtensionSymbols(List<JS.ModuleItem> items) {
    var modules = Map<String, List<Library>>();

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
      var imports =
          libraries.map((l) => JS.NameSpecifier(_imports[l])).toList();
      if (module == coreModuleName) {
        imports.add(JS.NameSpecifier(runtimeModule));
        imports.add(JS.NameSpecifier(extensionSymbolsModule));
      }

      items.add(JS.ImportDeclaration(
          namedImports: imports, from: js.string(module, "'")));
    });

    // Initialize extension symbols
    _extensionSymbols.forEach((name, id) {
      JS.Expression value =
          JS.PropertyAccess(extensionSymbolsModule, propertyName(name));
      if (isBuildingSdk) {
        value = js.call('# = Symbol(#)', [value, js.string("dartx.$name")]);
      }
      items.add(js.statement('const # = #;', [id, value]));
    });
  }

  void _emitDebuggerExtensionInfo(String name) {
    var properties = <JS.Property>[];
    _libraries.forEach((library, value) {
      // TODO(jacobr): we could specify a short library name instead of the
      // full library uri if we wanted to save space.
      properties.add(
          JS.Property(js.escapedString(jsLibraryDebuggerName(library)), value));
    });
    var module = JS.ObjectInitializer(properties, multiline: true);

    // Track the module name for each library in the module.
    // This data is only required for debugging.
    moduleItems.add(js.statement(
        '#.trackLibraries(#, #, $sourceMapLocationID);',
        [runtimeModule, js.string(name), module]));
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
  JS.Program finishModule(List<JS.ModuleItem> items, String moduleName) {
    // TODO(jmesserly): there's probably further consolidation we can do
    // between DDC's two backends, by moving more code into this method, as the
    // code between `startModule` and `finishModule` is very similar in both.
    _emitDebuggerExtensionInfo(moduleName);

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, moduleItems);
    moduleItems.clear();

    // Build the module.
    return JS.Program(items, name: moduleName);
  }

  /// Flattens blocks in [items] to a single list.
  ///
  /// This will not flatten blocks that are marked as being scopes.
  void _copyAndFlattenBlocks(
      List<JS.ModuleItem> result, Iterable<JS.ModuleItem> items) {
    for (var item in items) {
      if (item is JS.Block && !item.isScope) {
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
  JS.TemporaryId getExtensionSymbolInternal(String name) {
    return _extensionSymbols.putIfAbsent(
        name,
        () => JS.TemporaryId(
            '\$${JS.friendlyNameForDartOperator[name] ?? name}'));
  }

  /// Shorthand for identifier-like property names.
  /// For now, we emit them as strings and the printer restores them to
  /// identifiers if it can.
  // TODO(jmesserly): avoid the round tripping through quoted form.
  @protected
  JS.LiteralString propertyName(String name) => js.string(name, "'");

  /// Unique identifier indicating the location to inline the source map.
  ///
  /// We cannot generate the source map before the script it is for is
  /// generated so we have generate the script including this identifier in the
  /// JS AST, and then replace it once the source map is generated.
  static const String sourceMapLocationID =
      'SourceMap3G5a8h6JVhHfdGuDxZr1EF9GQC8y0e6u';
}

/// Whether a variable with [name] is referenced in the [node].
bool variableIsReferenced(String name, JS.Node node) {
  var finder = _IdentifierFinder.instance;
  finder.nameToFind = name;
  finder.found = false;
  node.accept(finder);
  return finder.found;
}

class _IdentifierFinder extends JS.BaseVisitor<void> {
  String nameToFind;
  bool found = false;

  static final instance = _IdentifierFinder();

  visitIdentifier(node) {
    if (node.name == nameToFind) found = true;
  }

  visitNode(node) {
    if (!found) super.visitNode(node);
  }
}

class YieldFinder extends JS.BaseVisitor {
  bool hasYield = false;
  bool hasThis = false;
  bool _nestedFunction = false;

  @override
  visitThis(JS.This node) {
    hasThis = true;
  }

  @override
  visitFunctionExpression(JS.FunctionExpression node) {
    var savedNested = _nestedFunction;
    _nestedFunction = true;
    super.visitFunctionExpression(node);
    _nestedFunction = savedNested;
  }

  @override
  visitYield(JS.Yield node) {
    if (!_nestedFunction) hasYield = true;
    super.visitYield(node);
  }

  @override
  visitNode(JS.Node node) {
    if (hasYield && hasThis) return; // found both, nothing more to do.
    super.visitNode(node);
  }
}
