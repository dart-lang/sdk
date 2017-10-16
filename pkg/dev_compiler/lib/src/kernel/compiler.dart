// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/src/incremental_class_hierarchy.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:path/path.dart' as path;
import '../compiler/js_metalet.dart' as JS;
import '../compiler/js_names.dart' as JS;
import '../compiler/js_utils.dart' as JS;
import '../compiler/module_builder.dart' show pathToJSIdentifier;
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import 'js_interop.dart';
import 'js_typerep.dart';
import 'kernel_helpers.dart';
import 'native_types.dart';
import 'type_table.dart';

class ProgramCompiler
    implements
        StatementVisitor<JS.Statement>,
        ExpressionVisitor<JS.Expression>,
        DartTypeVisitor<JS.Expression> {
  /// The list of output module items, in the order they need to be emitted in.
  final _moduleItems = <JS.ModuleItem>[];

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  ///
  /// We sometimes special case codegen for a single library, as it simplifies
  /// name scoping requirements.
  final _libraries = new Map<Library, JS.Identifier>.identity();

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = new Map<Library, JS.TemporaryId>();

  JS.Identifier _extensionSymbolsModule;
  final _extensionSymbols = new Map<String, JS.TemporaryId>();

  JS.Identifier _runtimeModule;
  final namedArgumentTemp = new JS.TemporaryId('opts');

  Set<Class> _pendingClasses;

  /// The stack of currently emitting elements, if generating top-level code
  /// for them. This is not used when inside method bodies, because order does
  /// not matter for those.
  Class _classEmittingTopLevel;

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentClass == _classEmittingTopLevel
  ///
  Class _currentClass;

  Library _currentLibrary;

  FunctionNode _currentFunction;

  List<TypeParameter> _typeParamInConst;

  /// Table of named and possibly hoisted types.
  TypeTable _typeTable;

  /// The global extension type table.
  // TODO(jmesserly): rename to `_nativeTypes`
  final NativeTypeSet _extensionTypes;

  final CoreTypes types;

  final TypeEnvironment rules;

  JSTypeRep _typeRep;

  ProgramCompiler(NativeTypeSet nativeTypes)
      : _extensionTypes = nativeTypes,
        types = nativeTypes.types,
        rules = new TypeSchemaEnvironment(
            nativeTypes.types, new IncrementalClassHierarchy(), true);

  JS.Program emitProgram(Program p) {
    if (_moduleItems.isNotEmpty) {
      throw new StateError('Can only call emitModule once.');
    }

    var libraries = p.libraries.where((l) => !l.isExternal);
    var ddcRuntime =
        libraries.firstWhere(isSdkInternalRuntime, orElse: () => null);
    if (ddcRuntime != null) {
      // Don't allow these to be renamed when we're building the SDK.
      // There is JS code in dart:* that depends on their names.
      _runtimeModule = new JS.Identifier('dart');
      _extensionSymbolsModule = new JS.Identifier('dartx');
    } else {
      // Otherwise allow these to be renamed so users can write them.
      _runtimeModule = new JS.TemporaryId('dart');
      _extensionSymbolsModule = new JS.TemporaryId('dartx');
    }
    _typeTable = new TypeTable(_runtimeModule);

    // Initialize our library variables.
    var items = <JS.ModuleItem>[];
    for (var library in libraries) {
      var libraryTemp = library == ddcRuntime
          ? _runtimeModule
          : new JS.TemporaryId(jsLibraryName(library));
      _libraries[library] = libraryTemp;
      items.add(new JS.ExportDeclaration(
          js.call('const # = Object.create(null)', [libraryTemp])));

      // dart:_runtime has a magic module that holds extension method symbols.
      // TODO(jmesserly): find a cleaner design for this.
      if (library == ddcRuntime) {
        items.add(new JS.ExportDeclaration(js
            .call('const # = Object.create(null)', [_extensionSymbolsModule])));
      }
    }

    // Collect all class/type Element -> Node mappings
    // in case we need to forward declare any classes.
    _pendingClasses = new HashSet.identity();
    for (var l in libraries) {
      _pendingClasses.addAll(l.classes);
    }

    // Add implicit dart:core dependency so it is first.
    emitLibraryName(types.coreLibrary);

    // Visit each library and emit its code.
    //
    // NOTE: clases are not necessarily emitted in this order.
    // Order will be changed as needed so the resulting code can execute.
    // This is done by forward declaring items.
    libraries.forEach(_emitLibrary);

    // Visit directives (for exports)
    libraries.forEach(_emitExports);

    // Declare imports
    _finishImports(items);
    // Initialize extension symbols
    _extensionSymbols.forEach((name, id) {
      var value =
          new JS.PropertyAccess(_extensionSymbolsModule, _propertyName(name));
      if (ddcRuntime != null) {
        value = js.call('# = Symbol(#)', [value, js.string("dartx.$name")]);
      }
      items.add(js.statement('const # = #;', [id, value]));
    });

    // Discharge the type table cache variables and
    // hoisted definitions.
    items.addAll(_typeTable.discharge());

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, _moduleItems);

    // Build the module.
    return new JS.Program(items, name: p.root.name);
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

  /// Returns the canonical name to refer to the Dart library.
  JS.Identifier emitLibraryName(Library library) {
    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(
            library, () => new JS.TemporaryId(jsLibraryName(library)));
  }

  String _libraryToModule(Library library) {
    assert(!_libraries.containsKey(library));
    if (library.importUri.scheme == 'dart') {
      // TODO(jmesserly): we need to split out HTML.
      return JS.dartSdkModule;
    }
    // TODO(jmesserly): to implement modular compilation, we need to know
    // how libraries are grouped into modules.
    var moduleName = path.basenameWithoutExtension(library.fileUri);
    return moduleName;
  }

  void _finishImports(List<JS.ModuleItem> items) {
    var modules = new Map<String, List<Library>>();

    for (var import in _imports.keys) {
      modules.putIfAbsent(_libraryToModule(import), () => []).add(import);
    }

    String coreModuleName;
    if (!_libraries.containsKey(types.coreLibrary)) {
      coreModuleName = _libraryToModule(types.coreLibrary);
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
          libraries.map((l) => new JS.NameSpecifier(_imports[l])).toList();
      if (module == coreModuleName) {
        imports.add(new JS.NameSpecifier(_runtimeModule));
        imports.add(new JS.NameSpecifier(_extensionSymbolsModule));
      }

      items.add(new JS.ImportDeclaration(
          namedImports: imports, from: js.string(module, "'")));
    });
  }

  void _emitLibrary(Library library) {
    // NOTE: this method isn't the right place to initialize per-library state.
    // Classes can be visited out of order, so this is only to catch things that
    // haven't been emitted yet.
    //
    // See _emitClass.
    assert(_currentLibrary == null);
    _currentLibrary = library;

    // `dart:_runtime` uses a different order for bootstrapping.
    bool bootstrap = isSdkInternalRuntime(library);
    if (bootstrap) _emitLibraryProcedures(library);

    library.classes.forEach(_emitClass);
    _moduleItems.addAll(library.typedefs.map(_emitTypedef));
    if (bootstrap) {
      _emitInternalSdkFields(library.fields);
    } else {
      _emitLibraryProcedures(library);
      var fields = library.fields;
      if (fields.isNotEmpty) _moduleItems.add(_emitLazyFields(fields));
    }

    _currentLibrary = null;
  }

  void _emitExports(Library library) {
    assert(_currentLibrary == null);
    _currentLibrary = library;

    library.additionalExports.forEach(_emitExport);

    _currentLibrary = null;
  }

  void _emitExport(Reference export) {
    var library = _currentLibrary;

    // We only need to export main as it is the only method part of the
    // publicly exposed JS API for a library.
    // TODO(jacobr): add a library level annotation indicating that all
    // contents of a library need to be exposed to JS.
    // https://github.com/dart-lang/sdk/issues/26368

    var node = export.node;
    if (node is Procedure && node.name.name == 'main') {
      // Don't allow redefining names from this library.
      var name = _emitTopLevelName(export.node);
      _moduleItems.add(js.statement(
          '#.# = #;', [emitLibraryName(library), name.selector, name]));
    }
  }

  /// Called to emit class declarations.
  ///
  /// During the course of emitting one item, we may emit another. For example
  ///
  ///     class D extends B { C m() { ... } }
  ///
  /// Because D depends on B, we'll emit B first if needed. However C is not
  /// used by top-level JavaScript code, so we can ignore that dependency.
  void _emitClass(Class c) {
    if (!_pendingClasses.remove(c)) return;

    var savedClass = _currentClass;
    var savedLibrary = _currentLibrary;
    _currentClass = c;
    _currentLibrary = c.enclosingLibrary;

    _moduleItems.add(_emitClassDeclaration(c));

    _currentClass = savedClass;
    _currentLibrary = savedLibrary;
  }

  /// To emit top-level classes, we sometimes need to reorder them.
  ///
  /// This function takes care of that, and also detects cases where reordering
  /// failed, and we need to resort to lazy loading, by marking the element as
  /// lazy. All elements need to be aware of this possibility and generate code
  /// accordingly.
  ///
  /// If we are not emitting top-level code, this does nothing, because all
  /// declarations are assumed to be available before we start execution.
  /// See [startTopLevel].
  void _declareBeforeUse(Class c) {
    if (c == null) return;
    if (identical(_currentClass, _classEmittingTopLevel)) _emitClass(c);
  }

  JS.Statement _emitClassDeclaration(Class c) {
    // TODO(jmesserly): move this to another class, to encapsulate how
    // we emit classes? Classes and class members introduce a lot of complexity.
    throw new UnimplementedError();
  }

  JS.Statement _emitTypedef(Typedef t) {
    throw new UnimplementedError();
  }

  /// Treat dart:_runtime fields as safe to eagerly evaluate.
  // TODO(jmesserly): it'd be nice to avoid this special case.
  JS.Statement _emitInternalSdkFields(Iterable<Field> fields) {
    throw new UnimplementedError();
  }

  JS.Statement _emitLazyFields(Iterable<Field> fields) {
    throw new UnimplementedError();
  }

  JS.PropertyAccess _emitTopLevelName(NamedNode n, {String suffix: ''}) {
    return _emitJSInterop(n) ?? _emitTopLevelNameNoInterop(n, suffix: suffix);
  }

  JS.PropertyAccess _emitTopLevelNameNoInterop(NamedNode n,
      {String suffix: ''}) {
    var name = getJSExportName(n) ?? getTopLevelName(n);
    return new JS.PropertyAccess(
        emitLibraryName(getLibrary(n)), _propertyName(name + suffix));
  }

  String _getJSNameWithoutGlobal(NamedNode n) {
    if (!isJSReference(n)) return null;
    var libraryJSName = getAnnotationName(getLibrary(n), isPublicJSAnnotation);
    var jsName =
        getAnnotationName(n, isPublicJSAnnotation) ?? getTopLevelName(n);
    return libraryJSName != null ? '$libraryJSName.$jsName' : jsName;
  }

  JS.Expression _emitJSInterop(NamedNode n) {
    var jsName = _getJSNameWithoutGlobal(n);
    if (jsName == null) return null;
    return _emitJSInteropForGlobal(jsName);
  }

  JS.Expression _emitJSInteropForGlobal(String name) {
    var access = callHelper('global');
    for (var part in name.split('.')) {
      access = new JS.PropertyAccess(access, js.escapedString(part, "'"));
    }
    return access;
  }

  void _emitLibraryProcedures(Library library) {
    var procedures =
        library.procedures.where((p) => !p.isExternal && !p.isAbstract);
    _moduleItems.addAll(
        procedures.where((p) => !p.isAccessor).map(_emitLibraryFunction));
    _moduleItems
        .add(_emitLibraryAccessors(procedures.where((p) => p.isAccessor)));
  }

  JS.Statement _emitLibraryAccessors(Iterable<Procedure> accessors) {
    return callHelperStatement('copyProperties(#, { # });', [
      emitLibraryName(_currentLibrary),
      accessors.map(_emitLibraryAccessor).toList()
    ]);
  }

  JS.Method _emitLibraryAccessor(Procedure accessor) {
    throw new UnimplementedError();
  }

  JS.Statement _emitLibraryFunction(Procedure p) {
    var body = <JS.Statement>[];
    var fn = _emitFunction(p.function);

    if (_currentLibrary.importUri.scheme == 'dart' &&
        _isInlineJSFunction(p.function.body)) {
      fn = JS.simplifyPassThroughArrowFunCallBody(fn);
    }

    var nameExpr = _emitTopLevelName(p);
    body.add(js.statement('# = #', [nameExpr, fn]));
    if (!isSdkInternalRuntime(_currentLibrary)) {
      body.add(
          _emitFunctionTagged(nameExpr, p.function.functionType, topLevel: true)
              .toStatement());
    }

    return JS.Statement.from(body);
  }

  JS.Expression _emitFunctionTagged(JS.Expression fn, FunctionType type,
      {topLevel: false}) {
    var lazy = topLevel && !_typeIsLoaded(type);
    var typeRep = visitFunctionType(type);
    if (lazy) {
      return callHelper('lazyFn(#, () => #)', [fn, typeRep]);
    } else {
      return callHelper('fn(#, #)', [fn, typeRep]);
    }
  }

  bool _typeIsLoaded(DartType type) {
    if (type is InterfaceType) {
      return !_pendingClasses.contains(type.classNode) &&
          type.typeArguments.every(_typeIsLoaded);
    }
    if (type is FunctionType) {
      return (_typeIsLoaded(type.returnType) &&
          type.positionalParameters.every(_typeIsLoaded) &&
          type.namedParameters.every((n) => _typeIsLoaded(n.type)));
    }
    if (type is TypedefType) {
      return type.typeArguments.every(_typeIsLoaded);
    }
    return true;
  }

  /// Emits a Dart [type] into code.
  JS.Expression _emitType(DartType type) => type.accept(this);

  @override
  defaultDartType(type) => throw new UnimplementedError();

  @override
  visitInvalidType(type) => defaultDartType(type);

  @override
  visitDynamicType(type) => callHelper('dynamic');

  @override
  visitVoidType(type) => callHelper('void');

  @override
  visitBottomType(type) => callHelper('bottom');

  @override
  visitInterfaceType(type, {bool lowerGeneric: false}) {
    var c = type.classNode;
    _declareBeforeUse(c);

    // Type parameters don't matter as JS interop types cannot be reified.
    // We have to use lazy JS types because until we have proper module
    // loading for JS libraries bundled with Dart libraries, we will sometimes
    // need to load Dart libraries before the corresponding JS libraries are
    // actually loaded.
    // Given a JS type such as:
    //     @JS('google.maps.Location')
    //     class Location { ... }
    // We can't emit a reference to MyType because the JS library that defines
    // it may be loaded after our code. So for now, we use a special lazy type
    // object to represent MyType.
    // Anonymous JS types do not have a corresponding concrete JS type so we
    // have to use a helper to define them.
    if (isJSAnonymousType(c)) {
      return callHelper('anonymousJSType(#)', js.escapedString(c.name));
    }
    var jsName = _getJSNameWithoutGlobal(c);
    if (jsName != null) {
      return callHelper('lazyJSType(() => #, #)',
          [_emitJSInteropForGlobal(jsName), js.escapedString(jsName)]);
    }

    var args = type.typeArguments;
    Iterable jsArgs = null;
    if (args.any((a) => a != const DynamicType())) {
      jsArgs = args.map(_emitType);
    } else if (lowerGeneric) {
      jsArgs = [];
    }
    if (jsArgs != null) {
      var genericName = _emitTopLevelNameNoInterop(c, suffix: '\$');
      var typeRep = js.call('#(#)', [genericName, jsArgs]);
      return _typeTable.nameType(type, typeRep);
    }

    return _emitTopLevelNameNoInterop(c);
  }

  @override
  visitVectorType(type) => defaultDartType(type);

  @override
  visitFunctionType(type, {bool lowerTypedef: false}) {
    var parameterTypes =
        type.positionalParameters.take(type.requiredParameterCount);
    var optionalTypes =
        type.positionalParameters.skip(type.requiredParameterCount);
    var namedTypes = type.namedParameters;
    var rt = _emitType(type.returnType);

    var ra = _emitTypeNames(parameterTypes);

    List<JS.Expression> typeParts;
    if (namedTypes.isNotEmpty) {
      assert(optionalTypes.isEmpty);
      // TODO(vsm): Pass in annotations here as well.
      var na = _emitTypeProperties(namedTypes);
      typeParts = [rt, ra, na];
    } else if (optionalTypes.isNotEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(optionalTypes);
      typeParts = [rt, ra, oa];
    } else {
      typeParts = [rt, ra];
    }

    JS.Expression fullType;
    var typeFormals = type.typeParameters;
    String helperCall;
    if (typeFormals.isNotEmpty) {
      var tf = _emitTypeFormals(typeFormals);

      addTypeFormalsAsParameters(List<JS.Expression> elements) {
        var names = _typeTable.discharge(typeFormals);
        var array = new JS.ArrayInitializer(elements);
        return names.isEmpty
            ? js.call('(#) => #', [tf, array])
            : js.call('(#) => {#; return #;}', [tf, names, array]);
      }

      typeParts = [addTypeFormalsAsParameters(typeParts)];

      helperCall = 'gFnType(#)';
      // If any explicit bounds were passed, emit them.
      if (typeFormals.any((t) => t.bound != null)) {
        var bounds = typeFormals.map((t) => _emitType(t.bound)).toList();
        typeParts.add(addTypeFormalsAsParameters(bounds));
      }
    } else {
      helperCall = 'fnType(#)';
    }
    fullType = callHelper(helperCall, [typeParts]);
    return _typeTable.nameType(type, fullType);
  }

  JS.ObjectInitializer _emitTypeProperties(Iterable<NamedType> types) {
    return new JS.ObjectInitializer(types
        .map((t) => new JS.Property(_propertyName(t.name), _emitType(t.type)))
        .toList());
  }

  JS.ArrayInitializer _emitTypeNames(Iterable<DartType> types) {
    return new JS.ArrayInitializer(types.map(_emitType).toList());
  }

  @override
  visitTypeParameterType(type) {
    _typeParamInConst?.add(type.parameter);
    return new JS.Identifier(type.parameter.name);
  }

  @override
  visitTypedefType(type, {bool lowerGeneric: false}) {
    var args = type.typeArguments;
    Iterable jsArgs = null;
    if (args.any((a) => a != const DynamicType())) {
      jsArgs = args.map(_emitType);
    } else if (lowerGeneric) {
      jsArgs = [];
    }
    if (jsArgs != null) {
      var genericName =
          _emitTopLevelNameNoInterop(type.typedefNode, suffix: '\$');
      var typeRep = js.call('#(#)', [genericName, jsArgs]);
      return _typeTable.nameType(type, typeRep);
    }

    return _emitTopLevelNameNoInterop(type.typedefNode);
  }

  JS.Fun _emitFunction(FunctionNode f, [Procedure method]) {
    // normal function (sync), vs (sync*, async, async*)
    var isSync = f.asyncMarker == AsyncMarker.Sync;
    var formals = _emitParameters(f);
    var typeFormals = _emitTypeFormals(f.typeParameters);
    formals.insertAll(0, typeFormals);

    JS.Block code = isSync
        ? _emitFunctionBody(f)
        : new JS.Block([_emitGeneratorFunction(f).toReturn()]);

    if (method != null && formals.isNotEmpty) {
      var name = method.name.name;
      if (name == '[]=') {
        // []= methods need to return the value. We could also address this at
        // call sites, but it's cleaner to instead transform the operator method.
        code = JS.alwaysReturnLastParameter(code, formals.last);
      } else if (name == '==' &&
          method.enclosingLibrary.importUri.scheme != 'dart') {
        // In Dart `operator ==` methods are not called with a null argument.
        // This is handled before calling them. For performance reasons, we push
        // this check inside the method, to simplify our `equals` helper.
        //
        // TODO(jmesserly): in most cases this check is not necessary, because
        // the Dart code already handles it (typically by an `is` check).
        // Eliminate it when possible.
        code = new JS.Block([
          js.statement('if (# == null) return false;', [formals.first]),
          code
        ]);
      }
    }

    return new JS.Fun(formals, code);
  }

  List<JS.Parameter> _emitParameters(FunctionNode f) {
    var result =
        f.positionalParameters.map((p) => new JS.Identifier(p.name)).toList();
    if (f.namedParameters.isNotEmpty) {
      result.add(namedArgumentTemp);
    }
    return result;
  }

  List<JS.Parameter> _emitTypeFormals(List<TypeParameter> typeFormals) {
    return typeFormals
        .map((t) => new JS.Identifier(t.name))
        .toList(growable: false);
  }

  JS.Expression _emitGeneratorFunction(FunctionNode f) {
    throw new UnimplementedError();
  }

  JS.Block _emitFunctionBody(FunctionNode f) {
    var savedFunction = _currentFunction;
    _currentFunction = f;

    var initArgs = _emitArgumentInitializers(f);
    var block = _visitStatement(f.body);

    if (initArgs != null) block = new JS.Block([initArgs, block]);

    var body = f.body;
    if (body is Block) {
      var params = new Set<String>()
        ..addAll(f.positionalParameters.map((p) => p.name))
        ..addAll(f.namedParameters.map((p) => p.name));
      bool shadowsParam = body.statements
          .any((s) => s is VariableDeclaration && params.contains(s.name));
      ;

      if (shadowsParam) {
        block = new JS.Block([
          new JS.Block([block], isScope: true)
        ]);
      }
    }

    _currentFunction = savedFunction;

    return block;
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  JS.Statement _emitArgumentInitializers(FunctionNode f) {
    if (f.positionalParameters.isEmpty && f.namedParameters.isEmpty)
      return null;

    var body = <JS.Statement>[];

    _emitCovarianceBoundsCheck(f.typeParameters, body);

    initParameter(VariableDeclaration p, JS.Identifier jsParam) {
      if (p.isCovariant || p.isGenericCovariantImpl) {
        var castType = _emitType(p.type);
        body.add(js.statement('#._check(#);', [castType, jsParam]));
      }
      if (_annotatedNullCheck(p)) {
        body.add(_nullParameterCheck(jsParam));
      }
    }

    for (var p in f.positionalParameters.take(f.requiredParameterCount)) {
      var jsParam = new JS.Identifier(p.name);
      initParameter(p, jsParam);
    }
    for (var p in f.positionalParameters.skip(f.requiredParameterCount)) {
      var jsParam = new JS.Identifier(p.name);
      var defaultValue = _defaultParamValue(p);
      if (defaultValue != null) {
        body.add(js.statement(
            'if (# === void 0) # = #;', [jsParam, jsParam, defaultValue]));
      }
      initParameter(p, jsParam);
    }
    for (var p in f.namedParameters) {
      // Parameters will be passed using their real names, not the (possibly
      // renamed) local variable.
      var jsParam = new JS.Identifier(p.name);
      var paramName = js.string(p.name, "'");
      var defaultValue = _defaultParamValue(p);
      if (defaultValue != null) {
        // TODO(ochafik): Fix `'prop' in obj` to please Closure's renaming.
        body.add(js.statement('let # = # && # in # ? #.# : #;', [
          jsParam,
          namedArgumentTemp,
          paramName,
          namedArgumentTemp,
          namedArgumentTemp,
          paramName,
          defaultValue,
        ]));
      } else {
        body.add(js.statement('let # = # && #.#;', [
          jsParam,
          namedArgumentTemp,
          namedArgumentTemp,
          paramName,
        ]));
      }
      initParameter(p, jsParam);
    }
    return body.isEmpty ? null : JS.Statement.from(body);
  }

  // TODO(jmesserly): fix this. Figure out where kernel stores these.
  bool _annotatedNullCheck(VariableDeclaration d) => false;

  JS.Statement _nullParameterCheck(JS.Expression param) {
    var call = callHelper('argumentError((#))', [param]);
    return js.statement('if (# == null) #;', [param, call]);
  }

  JS.Expression _defaultParamValue(VariableDeclaration p) {
    if (p.initializer != null) {
      var value = p.initializer;
      return _isJSUndefined(value) ? null : _visitExpression(value);
    } else {
      return new JS.LiteralNull();
    }
  }

  bool _isJSUndefined(Expression expr) {
    expr = expr is AsExpression ? expr.operand : expr;
    if (expr is StaticGet) {
      var t = expr.target;
      return isSdkInternalRuntime(getLibrary(t)) && t.name.name == 'undefined';
    }
    return false;
  }

  void _emitCovarianceBoundsCheck(
      List<TypeParameter> typeFormals, List<JS.Statement> body) {
    for (var t in typeFormals) {
      if (t.isGenericCovariantImpl) {
        body.add(callHelperStatement('checkTypeBound(#, #, #)', [
          _emitType(new TypeParameterType(t)),
          _emitType(t.bound),
          _propertyName(t.name)
        ]));
      }
    }
  }

  JS.Expression callHelper(String code, [args]) {
    if (args is List) {
      args.insert(0, _runtimeModule);
    } else if (args != null) {
      args = [_runtimeModule, args];
    } else {
      args = _runtimeModule;
    }
    return js.call('#.$code', args);
  }

  JS.Statement callHelperStatement(String code, args) {
    if (args is List) {
      args.insert(0, _runtimeModule);
    } else {
      args = [_runtimeModule, args];
    }
    return js.statement('#.$code', args);
  }

  JS.Statement _visitStatement(Statement s) {
    // TODO(jmesserly): attach source mapping to statements
    return s.accept(this);
  }

  JS.Expression _visitExpression(Expression e) {
    return e.accept(this);
  }

  JS.Expression _visitAndMarkExpression(Expression e) {
    // TODO(jmesserly): attach source mapping to expressions if needed
    return e.accept(this);
  }

  @override
  defaultStatement(node) => throw new UnimplementedError();

  @override
  visitInvalidStatement(node) => throw new UnimplementedError();

  @override
  visitExpressionStatement(node) =>
      _visitExpression(node.expression).toStatement();

  @override
  visitBlock(node) =>
      new JS.Block(node.statements.map(_visitStatement).toList(),
          isScope: true);

  @override
  visitEmptyStatement(node) => throw new UnimplementedError();

  @override
  visitAssertStatement(node) => throw new UnimplementedError();

  @override
  visitLabeledStatement(node) => throw new UnimplementedError();

  @override
  visitBreakStatement(node) => throw new UnimplementedError();

  @override
  visitWhileStatement(node) => throw new UnimplementedError();

  @override
  visitDoStatement(node) => throw new UnimplementedError();

  @override
  visitForStatement(node) => throw new UnimplementedError();

  @override
  visitForInStatement(node) => throw new UnimplementedError();

  @override
  visitSwitchStatement(node) => throw new UnimplementedError();

  @override
  visitContinueSwitchStatement(node) => throw new UnimplementedError();

  @override
  visitIfStatement(node) => throw new UnimplementedError();

  @override
  visitReturnStatement(node) => throw new UnimplementedError();

  @override
  visitTryCatch(node) => throw new UnimplementedError();

  @override
  visitTryFinally(node) => throw new UnimplementedError();

  @override
  visitYieldStatement(node) => throw new UnimplementedError();

  @override
  visitVariableDeclaration(node) => throw new UnimplementedError();

  @override
  visitFunctionDeclaration(node) => throw new UnimplementedError();

  @override
  defaultExpression(node) => throw new UnimplementedError();

  @override
  defaultBasicLiteral(node) => throw new UnimplementedError();

  @override
  visitInvalidExpression(node) => throw new UnimplementedError();

  @override
  visitVariableGet(node) => throw new UnimplementedError();

  @override
  visitVariableSet(node) => throw new UnimplementedError();

  @override
  visitPropertyGet(node) => throw new UnimplementedError();

  @override
  visitPropertySet(node) => throw new UnimplementedError();

  @override
  visitDirectPropertyGet(node) => throw new UnimplementedError();

  @override
  visitDirectPropertySet(node) => throw new UnimplementedError();

  @override
  visitSuperPropertyGet(node) => throw new UnimplementedError();

  @override
  visitSuperPropertySet(node) => throw new UnimplementedError();

  @override
  visitStaticGet(node) => throw new UnimplementedError();

  @override
  visitStaticSet(node) => throw new UnimplementedError();

  @override
  visitMethodInvocation(node) => throw new UnimplementedError();

  @override
  visitDirectMethodInvocation(node) => throw new UnimplementedError();

  @override
  visitSuperMethodInvocation(node) => throw new UnimplementedError();

  @override
  visitStaticInvocation(node) {
    var result = _emitForeignJS(node);
    if (result != null) return result;
    return _emitFunctionCall(node);
  }

  /// Emits a function call, to a top-level function, local function, or
  /// an expression.
  JS.Expression _emitFunctionCall(StaticInvocation node) {
    if (_isCoreIdentical(node.target)) {
      return _emitCoreIdenticalCall(node);
    }
    var fn = _emitTopLevelName(node.target);
    var args = _emitArgumentList(node.arguments);
    return new JS.Call(fn, args);
  }

  List<JS.Expression> _emitArgumentList(Arguments node) {
    var args = <JS.Expression>[];
    for (var typeArg in node.types) {
      args.add(_emitType(typeArg));
    }
    for (var arg in node.positional) {
      if (arg is StaticInvocation &&
          isJSSpreadInvocation(arg.target) &&
          arg.arguments.positional.length == 1) {
        args.add(new JS.RestParameter(
            _visitExpression(arg.arguments.positional[0])));
      } else {
        args.add(_visitExpression(arg));
      }
    }
    var named = <JS.Property>[];
    for (var arg in node.named) {
      named.add(new JS.Property(
          _propertyName(arg.name), _visitExpression(arg.value)));
    }
    if (named.isNotEmpty) {
      args.add(new JS.ObjectInitializer(named));
    }
    return args;
  }

  /// Emits code for the `JS(...)` macro.
  JS.Expression _emitForeignJS(StaticInvocation node) {
    if (isInlineJS(node.target)) {
      throw new UnimplementedError();
    }
    return null;
  }

  bool _isNull(Expression expr) =>
      expr is NullLiteral ||
      expr.getStaticType(rules) == types.nullClass.rawType;

  bool _doubleEqIsIdentity(Expression left, Expression right) {
    // If we statically know LHS or RHS is null we can use ==.
    if (_isNull(left) || _isNull(right)) return true;
    // If the representation of the  two types will not induce conversion in
    // JS then we can use == .
    return !_typeRep.equalityMayConvert(
        left.getStaticType(rules), right.getStaticType(rules));
  }

  bool _tripleEqIsIdentity(Expression left, Expression right) {
    // If either is non-nullable, then we don't need to worry about
    // equating null and undefined, and so we can use triple equals.
    return !isNullable(left) || !isNullable(right);
  }

  /// Returns true if [expr] can be null, optionally using [localIsNullable]
  /// for locals.
  ///
  /// If [localIsNullable] is not supplied, this will use the known list of
  /// [_notNullLocals].
  bool isNullable(Expression expr) {
    // TODO(jmesserly): we do recursive calls in a few places. This could
    // leads to O(depth) cost for calling this function. We could store the
    // resulting value if that becomes an issue, so we maintain the invariant
    // that each node is visited once.
    if (expr is PropertyGet) {
      var target = expr.interfaceTarget;
      // tear-offs are not null, other accessors are
      return target is Procedure && target.isAccessor;
    }
    if (expr is StaticGet) {
      var target = expr.target;
      // tear-offs are not null, other accessors are
      return target is Procedure && target.isAccessor;
    }

    if (expr is TypeLiteral) return false;
    if (expr is BasicLiteral) return expr.value != null;
    if (expr is IsExpression) return false;
    if (expr is FunctionExpression) return false;
    if (expr is ThisExpression) return false;
    if (expr is ConditionalExpression) {
      return isNullable(expr.then) || isNullable(expr.otherwise);
    }
    if (expr is ConstructorInvocation) return false;
    if (expr is LogicalExpression) return false;
    if (expr is Not) return false;
    if (expr is StaticInvocation) {
      return !_isCoreIdentical(expr.target);
    }
    if (expr is DirectMethodInvocation) {
      // TODO(jmesserly): this is to capture that our primitive classes
      // (int, double, num, bool, String) do not return null from their
      // operator methods.
      return !isPrimitiveType(expr.target.enclosingClass.rawType);
    }
    // TODO(jmesserly): handle other cases.
    return true;
  }

  bool isPrimitiveType(DartType t) => _typeRep.isPrimitive(t);

  bool _isCoreIdentical(Procedure node) {
    return node.name.name == 'identical' &&
        node.enclosingLibrary == types.coreLibrary;
  }

  JS.Expression _emitJSDoubleEq(List<JS.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# != #' : '# == #';
    return js.call(op, args);
  }

  JS.Expression _emitJSTripleEq(List<JS.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# !== #' : '# === #';
    return js.call(op, args);
  }

  JS.Expression _emitCoreIdenticalCall(StaticInvocation node,
      {bool negated = false}) {
    var args = node.arguments.positional;
    if (args.length != 2 || node.arguments.named.isNotEmpty) {
      // Shouldn't happen in typechecked code
      return callHelper(
          'throw(Error("compile error: calls to `identical` require 2 args")');
    }
    var left = args[0];
    var right = args[1];
    var jsArgs = [_visitExpression(left), _visitExpression(right)];
    if (_tripleEqIsIdentity(left, right)) {
      return _emitJSTripleEq(jsArgs, negated: negated);
    }
    if (_doubleEqIsIdentity(left, right)) {
      return _emitJSDoubleEq(jsArgs, negated: negated);
    }
    var code = negated ? '!#' : '#';
    return js.call(code, new JS.Call(_emitTopLevelName(node.target), jsArgs));
  }

  @override
  visitConstructorInvocation(node) => throw new UnimplementedError();

  @override
  visitNot(node) => throw new UnimplementedError();

  @override
  visitLogicalExpression(node) => throw new UnimplementedError();

  @override
  visitConditionalExpression(node) => throw new UnimplementedError();

  @override
  visitStringConcatenation(node) => throw new UnimplementedError();

  @override
  visitIsExpression(node) => throw new UnimplementedError();

  @override
  visitAsExpression(node) => throw new UnimplementedError();

  @override
  visitSymbolLiteral(node) => throw new UnimplementedError();

  @override
  visitTypeLiteral(node) => throw new UnimplementedError();

  @override
  visitThisExpression(node) => throw new UnimplementedError();

  @override
  visitRethrow(node) => throw new UnimplementedError();

  @override
  visitThrow(node) => throw new UnimplementedError();

  @override
  visitListLiteral(node) => throw new UnimplementedError();

  @override
  visitMapLiteral(node) => throw new UnimplementedError();

  @override
  visitAwaitExpression(node) => throw new UnimplementedError();

  @override
  visitFunctionExpression(node) => throw new UnimplementedError();

  @override
  visitStringLiteral(node) => js.escapedString(node.value, '"');

  @override
  visitIntLiteral(node) => throw new UnimplementedError();

  @override
  visitDoubleLiteral(node) => throw new UnimplementedError();
  @override
  visitBoolLiteral(node) => throw new UnimplementedError();

  @override
  visitNullLiteral(node) => throw new UnimplementedError();

  @override
  visitLet(node) => throw new UnimplementedError();

  @override
  visitLoadLibrary(node) => throw new UnimplementedError();

  @override
  visitCheckLibraryIsLoaded(node) => throw new UnimplementedError();

  @override
  visitVectorCreation(node) => throw new UnimplementedError();

  @override
  visitVectorGet(node) => throw new UnimplementedError();

  @override
  visitVectorSet(node) => throw new UnimplementedError();

  @override
  visitVectorCopy(node) => throw new UnimplementedError();

  @override
  visitClosureCreation(node) => throw new UnimplementedError();
}

bool isSdkInternalRuntime(Library l) =>
    l.importUri.toString() == 'dart:_runtime';

/// Choose a canonical name from the [library] element.
///
/// This never uses the library's name (the identifier in the `library`
/// declaration) as it doesn't have any meaningful rules enforced.
String jsLibraryName(Library library) {
  var uri = library.importUri;
  if (uri.scheme == 'dart') return uri.path;

  // TODO(vsm): This is not necessarily unique if '__' appears in a file name.
  Iterable<String> segements;
  if (uri.scheme == 'package') {
    // Strip the package name.
    // TODO(vsm): This is not unique if an escaped '/'appears in a filename.
    // E.g., "foo/bar.dart" and "foo__bar.dart" would collide.
    segements = uri.pathSegments.skip(1);
  } else {
    segements = path.split(path.relative(uri.toFilePath()));
  }
  var qualifiedPath = segements.map((p) => p == '..' ? '' : p).join('__');
  return pathToJSIdentifier(qualifiedPath);
}

/// Shorthand for identifier-like property names.
/// For now, we emit them as strings and the printer restores them to
/// identifiers if it can.
// TODO(jmesserly): avoid the round tripping through quoted form.
JS.LiteralString _propertyName(String name) => js.string(name, "'");

bool _isInlineJSFunction(Statement body) {
  var block = body;
  if (block is Block) {
    var statements = block.statements;
    if (statements.length != 1) return false;
    body = statements[0];
  }
  if (body is ReturnStatement) {
    var e = body.expression;
    return e is MethodInvocation && isInlineJS(e.interfaceTarget);
  }
  return false;
}

bool isInlineJS(Member e) =>
    e is Procedure &&
    e.name == 'JS' &&
    e.enclosingLibrary.importUri.toString() == 'dart:_foreign_helper';
