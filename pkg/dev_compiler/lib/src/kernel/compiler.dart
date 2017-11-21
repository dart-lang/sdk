// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show max, min;
import 'package:kernel/kernel.dart' hide ConstantVisitor;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/src/incremental_class_hierarchy.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:path/path.dart' as path;
import '../compiler/js_names.dart' as JS;
import '../compiler/js_utils.dart' as JS;
import '../compiler/module_builder.dart' show pathToJSIdentifier;
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import 'js_interop.dart';
import 'js_typerep.dart';
import 'kernel_helpers.dart';
import 'native_types.dart';
import 'property_model.dart';
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

  /// Maps a library URI import, that is not in [_libraries], to the
  /// corresponding Kernel summary module we imported it with.
  final _importToSummary = new Map<Library, Program>.identity();

  /// Maps a summary to the file URI we used to load it from disk.
  final _summaryToUri = new Map<Program, Uri>.identity();

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = new Map<Library, JS.TemporaryId>();

  /// The variable for the current catch clause
  VariableDeclaration _catchParameter;

  /// In an async* function, this represents the stream controller parameter.
  JS.TemporaryId _asyncStarController;

  // TODO(jmesserly): fuse this with notNull check.
  final _privateNames = new HashMap<Library, HashMap<String, JS.TemporaryId>>();

  JS.Identifier _extensionSymbolsModule;
  final _extensionSymbols = new Map<String, JS.TemporaryId>();

  JS.Identifier _runtimeModule;
  final namedArgumentTemp = new JS.TemporaryId('opts');

  Set<Class> _pendingClasses;

  /// Temporary variables mapped to their corresponding JavaScript variable.
  final _tempVariables = <VariableDeclaration, JS.TemporaryId>{};

  /// Let variables collected for the given function.
  List<JS.TemporaryId> _letVariables;

  /// The class when it's emitting top-level code, used to order classes when
  /// they extend each other.
  ///
  /// This is not used when inside method bodies, or for other type information
  /// such as `implements`.
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

  /// Whether we are currently generating code for the body of a `JS()` call.
  bool _isInForeignJS = false;

  /// Table of named and possibly hoisted types.
  TypeTable _typeTable;

  /// The global extension type table.
  // TODO(jmesserly): rename to `_nativeTypes`
  final NativeTypeSet _extensionTypes;

  final CoreTypes coreTypes;

  final TypeEnvironment types;

  /// Information about virtual and overridden fields/getters/setters in the
  /// class we're currently compiling, or `null` if we aren't compiling a class.
  ClassPropertyModel _classProperties;

  /// Information about virtual fields for all libraries in the current build
  /// unit.
  final virtualFields = new VirtualFieldModel();

  JSTypeRep _typeRep;

  bool _superAllowed = true;

  final _superHelpers = new Map<String, JS.Method>();

  final bool emitMetadata;
  final bool replCompile;

  final Map<String, String> declaredVariables;

  // Compilation of Kernel's [BreakStatement].
  //
  // Kernel represents Dart's `break` and `continue` uniformly as
  // [BreakStatement], by representing a loop continue as a break from the
  // loop's body.  [BreakStatement] always targets an enclosing
  // [LabeledStatement] statement directly without naming it.  (Continue to
  // a labeled switch case is not represented by a [BreakStatement].)
  //
  // We prefer to compile to `continue` where possible and to avoid labeling
  // statements where it is not necessary.  We maintain some state to track
  // which statements can be targets of break or continue without a label, which
  // statements must be labeled to be targets, and the labels that have been
  // assigned.

  /// A list of statements that can be the target of break without a label.
  ///
  /// A [BreakStatement] targeting any [LabeledStatement] in this list can be
  /// compiled to a break without a label.  All the statements in the list have
  /// the same effective target which must compile to something that can be
  /// targeted by break in JS.  This list and [_currentContinueTargets] are
  /// disjoint.
  List<LabeledStatement> _currentBreakTargets = [];

  /// A list of statements that can be the target of a continue without a label.
  ///
  /// A [BreakStatement] targeting any [LabeledStatement] in this list can be
  /// compiled to a continue without a label.  All the statements in this list
  /// have the same effective target which must compile to something that can be
  /// targeted by continue in JS.  This list and [_currentBreakTargets] are
  /// disjoint.
  List<LabeledStatement> _currentContinueTargets = [];

  /// A map from labeled statements to their 'effective targets'.
  ///
  /// The effective target of a labeled loop body is the enclosing loop.  A
  /// [BreakStatement] targeting this statement can be compiled to `continue`
  /// either with or without a label.  The effective target of a labeled
  /// statement that is not a loop body is the outermost non-labeled statement
  /// that it encloses.  A [BreakStatement] targeting this statement can be
  /// compiled to `break` either with or without a label.
  final _effectiveTargets = new HashMap<LabeledStatement, Statement>.identity();

  /// A map from effective targets to their label names.
  ///
  /// If the target needs to be labeled when compiled to JS, because it was
  /// targeted by a break or continue with a label, then this map contains the
  /// label name that was assigned to it.
  final _labelNames = new HashMap<Statement, String>.identity();

  final Class _jsArrayClass;
  final Class privateSymbolClass;
  final Class linkedHashMapImplClass;
  final Class identityHashMapImplClass;
  final Class linkedHashSetImplClass;
  final Class identityHashSetImplClass;
  final Class syncIterableClass;

  /// The dart:async `StreamIterator<T>` type.
  final Class _asyncStreamIteratorClass;

  final ConstantVisitor _constants;

  ProgramCompiler(NativeTypeSet nativeTypes,
      {this.emitMetadata: true,
      this.replCompile: false,
      this.declaredVariables: const {}})
      : _extensionTypes = nativeTypes,
        coreTypes = nativeTypes.coreTypes,
        _constants = new ConstantVisitor(nativeTypes.coreTypes),
        types = new TypeSchemaEnvironment(
            nativeTypes.coreTypes, new IncrementalClassHierarchy(), true),
        _jsArrayClass = nativeTypes.getClass('dart:_interceptors', 'JSArray'),
        _asyncStreamIteratorClass =
            nativeTypes.getClass('dart:async', 'StreamIterator'),
        privateSymbolClass =
            nativeTypes.getClass('dart:_js_helper', 'PrivateSymbol'),
        linkedHashMapImplClass =
            nativeTypes.getClass('dart:_js_helper', 'LinkedMap'),
        identityHashMapImplClass =
            nativeTypes.getClass('dart:_js_helper', 'IdentityMap'),
        linkedHashSetImplClass =
            nativeTypes.getClass('dart:collection', '_HashSet'),
        identityHashSetImplClass =
            nativeTypes.getClass('dart:collection', '_IdentityHashSet'),
        syncIterableClass =
            nativeTypes.getClass('dart:_js_helper', 'SyncIterable') {
    _typeRep = new JSTypeRep(types, coreTypes);
  }

  ClassHierarchy get hierarchy => types.hierarchy;

  JS.Program emitProgram(
      Program p, List<Program> summaries, List<Uri> summaryUris) {
    if (_moduleItems.isNotEmpty) {
      throw new StateError('Can only call emitModule once.');
    }
    for (var i = 0; i < summaries.length; i++) {
      var summary = summaries[i];
      var summaryUri = summaryUris[i];
      for (var l in summary.libraries) {
        assert(!_importToSummary.containsKey(l));
        _importToSummary[l] = summary;
        _summaryToUri[summary] = summaryUri;
      }
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
    emitLibraryName(coreTypes.coreLibrary);

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
    var summary = _importToSummary[library];
    assert(summary != null);
    // TODO(jmesserly): look up the appropriate relative import path if the user
    // specified that on the command line.
    var uri = _summaryToUri[summary];
    var moduleName = path.basenameWithoutExtension(path.fromUri(uri));
    return moduleName;
  }

  void _finishImports(List<JS.ModuleItem> items) {
    var modules = new Map<String, List<Library>>();

    for (var import in _imports.keys) {
      modules.putIfAbsent(_libraryToModule(import), () => []).add(import);
    }

    String coreModuleName;
    if (!_libraries.containsKey(coreTypes.coreLibrary)) {
      coreModuleName = _libraryToModule(coreTypes.coreLibrary);
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
      _moduleItems.add(_emitInternalSdkFields(library.fields));
    } else {
      _emitLibraryProcedures(library);
      var fields = library.fields;
      if (fields.isNotEmpty) _moduleItems.add(_emitLazyFields(library, fields));
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
    types.thisType = c.thisType;
    _currentLibrary = c.enclosingLibrary;

    _moduleItems.add(_emitClassDeclaration(c));

    _currentClass = savedClass;
    types.thisType = savedClass?.thisType;
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
    // If this class is annotated with `@JS`, then there is nothing to emit.
    if (findAnnotation(c, isPublicJSAnnotation) != null) return null;

    // If this is a JavaScript type, emit it now and then exit.
    var jsTypeDef = _emitJSType(c);
    if (jsTypeDef != null) return jsTypeDef;

    JS.Expression className;
    if (c.typeParameters.isNotEmpty) {
      // Generic classes will be defined inside a function that closes over the
      // type parameter. So we can use their local variable name directly.
      className = new JS.Identifier(getLocalClassName(c));
    } else {
      className = _emitTopLevelName(c);
    }

    var savedClassProperties = _classProperties;
    _classProperties =
        new ClassPropertyModel.build(types, _extensionTypes, virtualFields, c);

    var jsCtors = _defineConstructors(c, className);
    var jsMethods = _emitClassMethods(c);

    var body = <JS.Statement>[];
    _emitSuperHelperSymbols(body);
    var deferredSupertypes = <JS.Statement>[];

    // Emit the class, e.g. `core.Object = class Object { ... }`
    _defineClass(c, className, jsMethods, body, deferredSupertypes);
    body.addAll(jsCtors);

    // Emit things that come after the ES6 `class ... { ... }`.
    var jsPeerNames = _getJSPeerNames(c);
    if (jsPeerNames.length == 1 && c.typeParameters.isNotEmpty) {
      // Special handling for JSArray<E>
      body.add(_callHelperStatement('setExtensionBaseClass(#, #.global.#);',
          [className, _runtimeModule, jsPeerNames[0]]));
    }

    var finishGenericTypeTest = _emitClassTypeTests(c, className, body);

    _emitVirtualFieldSymbols(c, body);
    _emitClassSignature(c, className, body);
    _initExtensionSymbols(c);
    _defineExtensionMembers(className, body);
    _emitClassMetadata(c.annotations, className, body);

    var classDef = JS.Statement.from(body);
    var typeFormals = c.typeParameters;
    if (typeFormals.isNotEmpty) {
      classDef = _defineClassTypeArguments(
          c, typeFormals, classDef, className, deferredSupertypes);
    } else {
      body.addAll(deferredSupertypes);
    }

    body = [classDef];
    _emitStaticFields(c, body);
    if (finishGenericTypeTest != null) body.add(finishGenericTypeTest);
    for (var peer in jsPeerNames) {
      _registerExtensionType(c, peer, body);
    }

    _classProperties = savedClassProperties;
    return JS.Statement.from(body);
  }

  /// Wraps a possibly generic class in its type arguments.
  JS.Statement _defineClassTypeArguments(
      NamedNode c, List<TypeParameter> formals, JS.Statement body,
      [JS.Expression className, List<JS.Statement> deferredBaseClass]) {
    assert(formals.isNotEmpty);
    var name = getTopLevelName(c);
    var typeConstructor = js.call('(#) => { #; #; return #; }', [
      _emitTypeFormals(formals),
      _typeTable.discharge(formals),
      body,
      className ?? new JS.Identifier(name)
    ]);

    var genericArgs = [typeConstructor];
    if (deferredBaseClass != null && deferredBaseClass.isNotEmpty) {
      genericArgs.add(js.call('(#) => { #; }', [className, deferredBaseClass]));
    }

    var genericCall = _callHelper('generic(#)', [genericArgs]);

    if (getLibrary(c) == coreTypes.asyncLibrary &&
        (name == "Future" || name == "_Future")) {
      genericCall = _callHelper('flattenFutures(#)', [genericCall]);
    }
    var genericName = _emitTopLevelNameNoInterop(c, suffix: '\$');
    return js.statement('{ # = #; # = #(); }',
        [genericName, genericCall, _emitTopLevelName(c), genericName]);
  }

  JS.Statement _emitClassStatement(Class c, JS.Expression className,
      JS.Expression heritage, List<JS.Method> methods) {
    var name = getLocalClassName(c);
    var classExpr =
        new JS.ClassExpression(new JS.Identifier(name), heritage, methods);
    if (c.typeParameters.isNotEmpty) {
      return classExpr.toStatement();
    } else {
      return js.statement('# = #;', [className, classExpr]);
    }
  }

  void _defineClass(Class c, JS.Expression className, List<JS.Method> methods,
      List<JS.Statement> body, List<JS.Statement> deferredSupertypes) {
    if (c == coreTypes.objectClass) {
      body.add(_emitClassStatement(c, className, null, methods));
      return;
    }

    JS.Expression emitDeferredType(DartType t) {
      if (t is InterfaceType && t.typeArguments.isNotEmpty) {
        if (t == c.thisType) return className;
        return _emitGenericClassType(t, t.typeArguments.map(emitDeferredType));
      }
      return _emitType(t);
    }

    bool shouldDefer(InterfaceType t) {
      var visited = new Set<DartType>();
      bool defer(DartType t) {
        if (t is InterfaceType) {
          var tc = t.classNode;
          if (c == tc) return true;
          if (tc == coreTypes.objectClass || !visited.add(t)) return false;
          if (t.typeArguments.any(defer)) return true;
          var mixin = tc.mixedInType;
          return mixin != null && defer(mixin.asInterfaceType) ||
              defer(tc.supertype.asInterfaceType);
        }
        if (t is TypedefType) {
          return t.typeArguments.any(defer);
        }
        if (t is FunctionType) {
          return defer(t.returnType) ||
              t.positionalParameters.any(defer) ||
              t.namedParameters.any((np) => defer(np.type)) ||
              t.typeParameters.any((tp) => defer(tp.bound));
        }
        return false;
      }

      return defer(t);
    }

    emitClassRef(InterfaceType t) {
      // TODO(jmesserly): investigate this. It seems like `lazyJSType` is
      // invalid for use in an `extends` clause, hence this workaround.
      return _emitJSInterop(t.classNode) ?? visitInterfaceType(t);
    }

    var supertype = c.supertype.asInterfaceType;
    var hasUnnamedSuper = _hasUnnamedConstructor(c.superclass);
    var isCallable = isCallableClass(c);

    void emitMixinConstructors(JS.Expression className, [InterfaceType mixin]) {
      JS.Statement mixinCtor;
      if (mixin != null && _hasUnnamedConstructor(mixin.classNode)) {
        mixinCtor = js.statement('#.#.call(this);', [
          emitClassRef(mixin),
          _usesMixinNew(mixin.classNode)
              ? _callHelper('mixinNew')
              : _constructorName('')
        ]);
      }

      for (var ctor in c.superclass.constructors) {
        var jsParams = _emitFormalParameters(ctor.function);
        var ctorBody = <JS.Statement>[];
        if (mixinCtor != null) ctorBody.add(mixinCtor);
        if (ctor.name != '' || hasUnnamedSuper) {
          ctorBody.add(
              _emitSuperConstructorCall(className, ctor.name.name, jsParams));
        }
        body.add(_addConstructorToClass(
            className,
            ctor.name.name,
            _finishConstructorFunction(
                jsParams, new JS.Block(ctorBody), isCallable)));
      }
    }

    var savedTopLevelClass = _classEmittingTopLevel;
    _classEmittingTopLevel = c;

    // Unroll mixins.
    if (shouldDefer(supertype)) {
      deferredSupertypes.add(_callHelperStatement('setBaseClass(#, #)', [
        isMixinAliasClass(c) ? className : js.call('#.__proto__', className),
        emitDeferredType(supertype),
      ]));
      supertype = supertype.classNode.rawType;
    }
    var baseClass = emitClassRef(supertype);

    // TODO(jmesserly): conceptually we could use isMixinApplication, however,
    // avoiding the extra level of nesting is only required if the class itself
    // is a valid mixin.
    if (isMixinAliasClass(c)) {
      // Given `class C = Object with M [implements I1, I2 ...];`
      // The resulting class C should work as a mixin.
      body.add(_emitClassStatement(c, className, baseClass, []));

      var m = c.mixedInType.asInterfaceType;
      bool deferMixin = shouldDefer(m);
      var mixinBody = deferMixin ? deferredSupertypes : body;
      var mixinClass = deferMixin ? emitDeferredType(m) : emitClassRef(m);

      mixinBody.add(
          _callHelperStatement('mixinMembers(#, #)', [className, mixinClass]));

      _classEmittingTopLevel = savedTopLevelClass;

      if (methods.isNotEmpty) {
        // However we may need to add some methods to this class that call
        // `super` such as covariance checks.
        //
        // We do this with the following pattern:
        //
        //     mixinMembers(C, class C$ extends M { <methods>  });
        mixinBody.add(_callHelperStatement('mixinMembers(#, #)', [
          className,
          new JS.ClassExpression(
              new JS.TemporaryId(getLocalClassName(c)), mixinClass, methods)
        ]));
      }

      emitMixinConstructors(className, m);
      return;
    }

    if (c.isMixinApplication) {
      var m = c.mixedInType.asInterfaceType;

      var mixinId = new JS.TemporaryId(getLocalClassName(c.superclass) +
          '_' +
          getLocalClassName(c.mixedInClass));
      body.add(new JS.ClassExpression(mixinId, baseClass, []).toStatement());
      // Add constructors

      emitMixinConstructors(mixinId, m);
      hasUnnamedSuper =
          hasUnnamedSuper || _hasUnnamedConstructor(c.mixedInClass);

      if (shouldDefer(m)) {
        deferredSupertypes.add(_callHelperStatement(
            'mixinMembers(#.__proto__, #)', [className, emitDeferredType(m)]));
      } else {
        body.add(_callHelperStatement(
            'mixinMembers(#, #)', [mixinId, emitClassRef(m)]));
      }

      baseClass = mixinId;
    }

    _classEmittingTopLevel = savedTopLevelClass;

    body.add(_emitClassStatement(c, className, baseClass, methods));

    if (c.isMixinApplication) emitMixinConstructors(className);
  }

  /// Defines all constructors for this class as ES5 constructors.
  List<JS.Statement> _defineConstructors(Class c, JS.Expression className) {
    var isCallable = isCallableClass(c);

    var body = <JS.Statement>[];
    if (isCallable) {
      // Our class instances will have JS `typeof this == "function"`,
      // so make sure to attach the runtime type information the same way
      // we would do it for function types.
      body.add(js.statement('#.prototype[#] = #;',
          [className, _callHelper('_runtimeType'), className]));
    }

    if (c.isMixinApplication) {
      // We already handled this when we defined the class.
      return body;
    }

    addConstructor(String name, JS.Expression jsCtor) {
      body.add(_addConstructorToClass(className, name, jsCtor));
    }

    if (c.isEnum) {
      assert(!isCallable, 'enums should not be callable');
      addConstructor('', js.call('function(x) { this.index = x; }'));
      return body;
    }

    var fields = c.fields;
    for (var ctor in c.constructors) {
      if (ctor.isExternal) continue;
      addConstructor(ctor.name.name,
          _emitConstructor(ctor, fields, isCallable, className));
    }

    // If classElement has only factory constructors, and it can be mixed in,
    // then we need to emit a special hidden default constructor for use by
    // mixins.
    if (_usesMixinNew(c)) {
      body.add(
          js.statement('(#[#] = function() { # }).prototype = #.prototype;', [
        className,
        _callHelper('mixinNew'),
        [_initializeFields(fields)],
        className
      ]));
    }

    return body;
  }

  JS.Statement _emitClassTypeTests(
      Class c, JS.Expression className, List<JS.Statement> body) {
    JS.Expression getInterfaceSymbol(Class interface) {
      var library = interface.enclosingLibrary;
      if (library == coreTypes.coreLibrary ||
          library == coreTypes.asyncLibrary) {
        switch (interface.name) {
          case 'List':
          case 'Map':
          case 'Iterable':
          case 'Future':
          case 'Stream':
          case 'StreamSubscription':
            return _callHelper('is' + interface.name);
        }
      }
      return null;
    }

    void markSubtypeOf(JS.Expression testSymbol) {
      body.add(js.statement('#.prototype[#] = true', [className, testSymbol]));
    }

    for (var iface in c.implementedTypes) {
      var prop = getInterfaceSymbol(iface.classNode);
      if (prop != null) markSubtypeOf(prop);
    }

    // TODO(jmesserly): share these hand coded type checks with the old back
    // end, perhaps by factoring them into a common file, or move them to be
    // static methdos in the SDK. (Or wait until we delete the old back end.)
    if (c.enclosingLibrary == coreTypes.coreLibrary) {
      if (c == coreTypes.objectClass) {
        // Everything is an Object.
        body.add(js.statement(
            '#.is = function is_Object(o) { return true; }', [className]));
        body.add(js.statement(
            '#.as = function as_Object(o) { return o; }', [className]));
        body.add(js.statement(
            '#._check = function check_Object(o) { return o; }', [className]));
        return null;
      }
      if (c == coreTypes.stringClass) {
        body.add(js.statement(
            '#.is = function is_String(o) { return typeof o == "string"; }',
            className));
        body.add(js.statement(
            '#.as = function as_String(o) {'
            '  if (typeof o == "string" || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, _runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_String(o) {'
            '  if (typeof o == "string" || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, _runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.functionClass) {
        body.add(js.statement(
            '#.is = function is_Function(o) { return typeof o == "function"; }',
            className));
        body.add(js.statement(
            '#.as = function as_Function(o) {'
            '  if (typeof o == "function" || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, _runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_String(o) {'
            '  if (typeof o == "function" || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, _runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.intClass) {
        body.add(js.statement(
            '#.is = function is_int(o) {'
            '  return typeof o == "number" && Math.floor(o) == o;'
            '}',
            className));
        body.add(js.statement(
            '#.as = function as_int(o) {'
            '  if ((typeof o == "number" && Math.floor(o) == o) || o == null)'
            '    return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, _runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_int(o) {'
            '  if ((typeof o == "number" && Math.floor(o) == o) || o == null)'
            '    return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, _runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.nullClass) {
        body.add(js.statement(
            '#.is = function is_Null(o) { return o == null; }', className));
        body.add(js.statement(
            '#.as = function as_Null(o) {'
            '  if (o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, _runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_Null(o) {'
            '  if (o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, _runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.numClass || c == coreTypes.doubleClass) {
        body.add(js.statement(
            '#.is = function is_num(o) { return typeof o == "number"; }',
            className));
        body.add(js.statement(
            '#.as = function as_num(o) {'
            '  if (typeof o == "number" || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, _runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_num(o) {'
            '  if (typeof o == "number" || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, _runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.boolClass) {
        body.add(js.statement(
            '#.is = function is_bool(o) { return o === true || o === false; }',
            className));
        body.add(js.statement(
            '#.as = function as_bool(o) {'
            '  if (o === true || o === false || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, _runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_bool(o) {'
            '  if (o === true || o === false || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, _runtimeModule, className]));
        return null;
      }
    }
    if (c.enclosingLibrary == coreTypes.asyncLibrary) {
      if (c == coreTypes.futureOrClass) {
        var typeParam = new TypeParameterType(c.typeParameters[0]);
        var typeT = visitTypeParameterType(typeParam);
        var futureOfT = visitInterfaceType(
            new InterfaceType(coreTypes.futureClass, [typeParam]));
        body.add(js.statement('''
            #.is = function is_FutureOr(o) {
              return #.is(o) || #.is(o);
            }
            ''', [className, typeT, futureOfT]));
        // TODO(jmesserly): remove the fallback to `dart.as`. It's only for the
        // _ignoreTypeFailure logic.
        body.add(js.statement('''
            #.as = function as_FutureOr(o) {
              if (o == null || #.is(o) || #.is(o)) return o;
              return #.as(o, this, false);
            }
            ''', [className, typeT, futureOfT, _runtimeModule]));
        body.add(js.statement('''
            #._check = function check_FutureOr(o) {
              if (o == null || #.is(o) || #.is(o)) return o;
              return #.as(o, this, true);
            }
            ''', [className, typeT, futureOfT, _runtimeModule]));
        return null;
      }
    }

    body.add(_callHelperStatement('addTypeTests(#);', [className]));

    if (c.typeParameters.isEmpty) return null;

    // For generics, testing against the default instantiation is common,
    // so optimize that.
    var isClassSymbol = getInterfaceSymbol(c);
    if (isClassSymbol == null) {
      // TODO(jmesserly): we could export these symbols, if we want to mark
      // implemented interfaces for user-defined classes.
      var id = new JS.TemporaryId("_is_${getLocalClassName(c)}_default");
      _moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(id.name, "'")]));
      isClassSymbol = id;
    }
    // Marking every generic type instantiation as a subtype of its default
    // instantiation.
    markSubtypeOf(isClassSymbol);

    // Define the type tests on the default instantiation to check for that
    // marker.
    var defaultInst = _emitTopLevelName(c);

    // Return this `addTypeTests` call so we can emit it outside of the generic
    // type parameter scope.
    return _callHelperStatement(
        'addTypeTests(#, #);', [defaultInst, isClassSymbol]);
  }

  void _emitSymbols(Iterable<JS.TemporaryId> vars, List<JS.ModuleItem> body) {
    for (var id in vars) {
      body.add(js.statement('const # = Symbol(#)', [id, js.string(id.name)]));
    }
  }

  void _emitSuperHelperSymbols(List<JS.Statement> body) {
    _emitSymbols(
        _superHelpers.values.map((m) => m.name as JS.TemporaryId), body);
    _superHelpers.clear();
  }

  /// Emits static fields for a class, and initialize them eagerly if possible,
  /// otherwise define them as lazy properties.
  void _emitStaticFields(Class c, List<JS.Statement> body) {
    var lazyStatics = c.fields.where((f) => f.isStatic).toList();
    if (lazyStatics.isNotEmpty) {
      body.add(_emitLazyFields(c, lazyStatics));
    }
  }

  void _emitClassMetadata(List<Expression> metadata, JS.Expression className,
      List<JS.Statement> body) {
    // Metadata
    if (emitMetadata && metadata.isNotEmpty) {
      body.add(js.statement('#[#.metadata] = () => #;', [
        className,
        _runtimeModule,
        new JS.ArrayInitializer(
            new List<JS.Expression>.from(metadata.map(_instantiateAnnotation)))
      ]));
    }
  }

  /// Ensure `dartx.` symbols we will use are present.
  void _initExtensionSymbols(Class c) {
    if (_extensionTypes.hasNativeSubtype(c) || c == coreTypes.objectClass) {
      for (var m in c.procedures) {
        if (!m.isAbstract && !m.isStatic && !m.name.isPrivate) {
          _declareMemberName(m, useExtension: true);
        }
      }
    }
  }

  /// If a concrete class implements one of our extensions, we might need to
  /// add forwarders.
  void _defineExtensionMembers(
      JS.Expression className, List<JS.Statement> body) {
    void emitExtensions(String helperName, Iterable<String> extensions) {
      if (extensions.isEmpty) return;

      var names = extensions
          .map((e) => _propertyName(JS.memberNameForDartMember(e)))
          .toList();
      body.add(js.statement('#.#(#, #);', [
        _runtimeModule,
        helperName,
        className,
        new JS.ArrayInitializer(names, multiline: names.length > 4)
      ]));
    }

    var props = _classProperties;
    emitExtensions('defineExtensionMethods', props.extensionMethods);
    emitExtensions('defineExtensionAccessors', props.extensionAccessors);
  }

  /// Emit the signature on the class recording the runtime type information
  void _emitClassSignature(
      Class c, JS.Expression className, List<JS.Statement> body) {
    if (c.implementedTypes.isNotEmpty) {
      body.add(js.statement('#[#.implements] = () => #;', [
        className,
        _runtimeModule,
        new JS.ArrayInitializer(c.implementedTypes
            .map((i) => _emitType(i.asInterfaceType))
            .toList())
      ]));
    }

    void emitSignature(String name, List<JS.Property> elements) {
      if (elements.isEmpty) return;

      if (!name.startsWith('Static')) {
        var proto = c == coreTypes.objectClass
            ? js.call('Object.create(null)')
            : _callHelper('get${name}s(#.__proto__)', [className]);
        elements.insert(0, new JS.Property(_propertyName('__proto__'), proto));
      }
      body.add(_callHelperStatement('set${name}Signature(#, () => #)', [
        className,
        new JS.ObjectInitializer(elements, multiline: elements.length > 1)
      ]));
    }

    var extMembers = _classProperties.extensionMethods;
    var staticMethods = <JS.Property>[];
    var instanceMethods = <JS.Property>[];
    var staticGetters = <JS.Property>[];
    var instanceGetters = <JS.Property>[];
    var staticSetters = <JS.Property>[];
    var instanceSetters = <JS.Property>[];
    List<JS.Property> getSignatureList(Procedure p) {
      if (p.isStatic) {
        if (p.isGetter) {
          return staticGetters;
        } else if (p.isSetter) {
          return staticSetters;
        } else {
          return staticMethods;
        }
      } else {
        if (p.isGetter) {
          return instanceGetters;
        } else if (p.isSetter) {
          return instanceSetters;
        } else {
          return instanceMethods;
        }
      }
    }

    for (var member in c.procedures) {
      if (member.isAbstract) continue;

      // Static getters/setters cannot be called with dynamic dispatch, nor
      // can they be torn off.
      // TODO(jmesserly): can we attach static method type info at the tearoff
      // point, and avoid saving the information otherwise? Same trick would
      // work for top-level functions.
      if (!emitMetadata && member.isAccessor && member.isStatic) {
        continue;
      }

      var name = member.name.name;
      var reifiedType = _getMemberRuntimeType(member);

      // Don't add redundant signatures for inherited methods whose signature
      // did not change.  If we are not overriding, or if the thing we are
      // overriding has a different reified type from ourselves, we must
      // emit a signature on this class.  Otherwise we will inherit the
      // signature from the superclass.
      var memberOverride = c.superclass != null
          ? hierarchy.getDispatchTarget(c.superclass, member.name,
              setter: member.isSetter)
          : null;

      var needsSignature = memberOverride == null ||
          reifiedType !=
              Substitution
                  .fromSupertype(hierarchy.getClassAsInstanceOf(
                      c, memberOverride.enclosingClass))
                  .substituteType(_getMemberRuntimeType(memberOverride));

      if (needsSignature) {
        var type = _emitAnnotatedFunctionType(reifiedType, member.annotations,
            function: member.function);
        var property = new JS.Property(_declareMemberName(member), type);
        var signatures = getSignatureList(member);
        signatures.add(property);
        if (!member.isStatic && extMembers.contains(name)) {
          signatures.add(new JS.Property(
              _declareMemberName(member, useExtension: true), type));
        }
      }
    }

    emitSignature('Method', instanceMethods);
    emitSignature('StaticMethod', staticMethods);
    emitSignature('Getter', instanceGetters);
    emitSignature('Setter', instanceSetters);
    emitSignature('StaticGetter', staticGetters);
    emitSignature('StaticSetter', staticSetters);

    var instanceFields = <JS.Property>[];
    var staticFields = <JS.Property>[];
    for (var field in c.fields) {
      // Only instance fields need to be saved for dynamic dispatch.
      var isStatic = field.isStatic;
      if (!emitMetadata && isStatic) continue;

      var memberName = _declareMemberName(field);
      var fieldSig = _emitFieldSignature(field.type,
          metadata: field.annotations, isFinal: field.isFinal);
      (isStatic ? staticFields : instanceFields)
          .add(new JS.Property(memberName, fieldSig));
    }
    emitSignature('Field', instanceFields);
    emitSignature('StaticField', staticFields);

    var constructors = <JS.Property>[];
    if (emitMetadata) {
      for (var ctor in c.constructors) {
        var memberName = _constructorName(ctor.name.name);
        var type = _emitAnnotatedFunctionType(
            ctor.function.functionType, ctor.annotations,
            function: ctor.function, nameType: false, definite: true);
        constructors.add(new JS.Property(memberName, type));
      }
    }
    emitSignature('Constructor', constructors);

    // Add static property dart._runtimeType to Object.
    // All other Dart classes will (statically) inherit this property.
    if (c == coreTypes.objectClass) {
      body.add(_callHelperStatement('tagComputed(#, () => #.#);',
          [className, emitLibraryName(coreTypes.coreLibrary), 'Type']));
    }
  }

  JS.Expression _emitFieldSignature(DartType type,
      {List<Expression> metadata, bool isFinal: true}) {
    var args = [_emitType(type)];
    if (emitMetadata && metadata != null && metadata.isNotEmpty) {
      args.add(new JS.ArrayInitializer(
          metadata.map(_instantiateAnnotation).toList()));
    }
    return _callHelper(isFinal ? 'finalFieldType(#)' : 'fieldType(#)', [args]);
  }

  FunctionType _getMemberRuntimeType(Member member) {
    // Check whether we have any covariant parameters.
    // Usually we don't, so we can use the same type.
    isCovariant(VariableDeclaration p) =>
        p.isCovariant || p.isGenericCovariantImpl;

    var f = member.function;
    if (f == null) {
      assert(member is Field);
      return new FunctionType([], member.getterType);
    }

    if (!f.positionalParameters.any(isCovariant) &&
        !f.namedParameters.any(isCovariant)) {
      return f.functionType;
    }

    reifyParameter(VariableDeclaration p) =>
        isCovariant(p) ? coreTypes.objectClass.thisType : p.type;
    reifyNamedParameter(VariableDeclaration p) =>
        new NamedType(p.name, reifyParameter(p));

    // TODO(jmesserly): do covariant type parameter bounds also need to be
    // reified as `Object`?
    return new FunctionType(
        f.positionalParameters.map(reifyParameter).toList(), f.returnType,
        namedParameters: f.namedParameters.map(reifyNamedParameter).toList()
          ..sort(),
        typeParameters: f.functionType.typeParameters,
        requiredParameterCount: f.requiredParameterCount);
  }

  JS.Expression _emitConstructor(Constructor node, List<Field> fields,
      bool isCallable, JS.Expression className) {
    var params = _emitFormalParameters(node.function);

    var savedFunction = _currentFunction;
    var savedLetVariables = _letVariables;
    _currentFunction = node.function;
    _letVariables = [];
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var body = _emitConstructorBody(node, fields, className);

    _letVariables = savedLetVariables;
    _superAllowed = savedSuperAllowed;
    _currentFunction = savedFunction;

    return _finishConstructorFunction(params, body, isCallable);
  }

  JS.Block _emitConstructorBody(
      Constructor node, List<Field> fields, JS.Expression className) {
    var cls = node.enclosingClass;

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    var body = _emitArgumentInitializers(node.function);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    var redirectCall = node.initializers
            .firstWhere((i) => i is RedirectingInitializer, orElse: () => null)
        as RedirectingInitializer;

    if (redirectCall != null) {
      body.add(_emitRedirectingConstructor(redirectCall, className));
      _initTempVars(body);
      return new JS.Block(body);
    }

    // Generate field initializers.
    // These are expanded into each non-redirecting constructor.
    // In the future we may want to create an initializer function if we have
    // multiple constructors, but it needs to be balanced against readability.
    body.add(_initializeFields(fields, node));

    var superCall = node.initializers.firstWhere((i) => i is SuperInitializer,
        orElse: () => null) as SuperInitializer;

    // If no superinitializer is provided, an implicit superinitializer of the
    // form `super()` is added at the end of the initializer list, unless the
    // enclosing class is class Object.
    var jsSuper = _emitSuperConstructorCallIfNeeded(cls, className, superCall);
    if (jsSuper != null) body.add(jsSuper..sourceInformation = superCall);

    body.add(_visitStatement(node.function.body));
    _initTempVars(body);
    return new JS.Block(body)..sourceInformation = node;
  }

  JS.Expression _constructorName(String name) {
    if (name == '') {
      // Default constructors (factory or not) use `new` as their name.
      return _propertyName('new');
    }
    return _emitStaticMemberName(name);
  }

  JS.Statement _emitRedirectingConstructor(
      RedirectingInitializer node, JS.Expression className) {
    var ctor = node.target;
    // We can't dispatch to the constructor with `this.new` as that might hit a
    // derived class constructor with the same name.
    return js.statement('#.#.call(this, #);', [
      className,
      _constructorName(ctor.name.name),
      _emitArgumentList(node.arguments)
    ]);
  }

  JS.Statement _emitSuperConstructorCallIfNeeded(
      Class c, JS.Expression className,
      [SuperInitializer superInit]) {
    if (c == coreTypes.objectClass) return null;

    Constructor ctor;
    List<JS.Expression> args;
    if (superInit == null) {
      ctor = unnamedConstructor(c.superclass);
      args = [];
    } else {
      ctor = superInit.target;
      args = _emitArgumentList(superInit.arguments);
    }
    // We can skip the super call if it's empty. Most commonly this happens for
    // things that extend Object, and don't have any field initializers or their
    // own default constructor.
    if (ctor.name.name == '' && !_hasUnnamedSuperConstructor(c)) {
      return null;
    }
    return _emitSuperConstructorCall(className, ctor.name.name, args);
  }

  JS.Statement _emitSuperConstructorCall(
      JS.Expression className, String name, List<JS.Expression> args) {
    return js.statement('#.__proto__.#.call(this, #);',
        [className, _constructorName(name), args ?? []]);
  }

  bool _hasUnnamedSuperConstructor(Class c) {
    if (c == null) return false;
    return _hasUnnamedConstructor(c.superclass) ||
        _hasUnnamedConstructor(c.mixedInClass);
  }

  bool _hasUnnamedConstructor(Class c) {
    if (c == null || c == coreTypes.objectClass) return false;
    var ctor = unnamedConstructor(c);
    if (ctor != null && !ctor.isSyntheticDefault) return true;
    if (c.fields.any((f) => !f.isStatic)) return true;
    return _hasUnnamedSuperConstructor(c);
  }

  JS.Expression _finishConstructorFunction(
      List<JS.Parameter> params, JS.Block body, isCallable) {
    // We consider a class callable if it inherits from anything with a `call`
    // method. As a result, we can know the callable JS function was created
    // at the first constructor that was hit.
    if (!isCallable) return new JS.Fun(params, body);
    return js.call(r'''function callableClass(#) {
          if (typeof this !== "function") {
            function self(...args) {
              return self.call.apply(self, args);
            }
            self.__proto__ = this.__proto__;
            callableClass.call(self, #);
            return self;
          }
          #
        }''', [params, params, body]);
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  JS.Statement _initializeFields(List<Field> fields, [Constructor ctor]) {
    // Run field initializers if they can have side-effects.

    Set<Field> ctorFields;
    if (ctor != null) {
      ctorFields = ctor.initializers
          .map((c) => c is FieldInitializer ? c.field : null)
          .toSet()
            ..remove(null);
    }

    var body = <JS.Statement>[];
    emitFieldInit(Field f, Expression initializer) {
      var access = _classProperties.virtualFields[f] ?? _declareMemberName(f);
      var jsInit = _visitInitializer(initializer, f.annotations);
      body.add(jsInit
          .toAssignExpression(
              js.call('this.#', [access])..sourceInformation = f)
          .toStatement());
    }

    for (var f in fields) {
      var init = f.initializer;
      if (init == null ||
          ctorFields != null &&
              ctorFields.contains(f) &&
              _constants.isConstant(init)) {
        continue;
      }
      emitFieldInit(f, f.initializer);
    }

    // Run constructor field initializers such as `: foo = bar.baz`
    if (ctor != null) {
      for (var init in ctor.initializers) {
        if (init is FieldInitializer) {
          emitFieldInit(init.field, init.value);
        } else if (init is LocalInitializer) {
          body.add(visitVariableDeclaration(init.variable));
        }
      }
    }

    return JS.Statement.from(body);
  }

  JS.Expression _visitInitializer(
      Expression init, List<Expression> annotations) {
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    if (init == null) return new JS.LiteralNull();
    var value = _annotatedNullCheck(annotations)
        ? notNull(init)
        : _visitAndMarkExpression(init);
    return value..sourceInformation = init;
  }

  JS.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visitExpression(expr);
    if (!isNullable(expr)) return jsExpr;
    return _callHelper('notNull(#)', jsExpr);
  }

  /// If the class has only factory constructors, and it can be mixed in,
  /// then we need to emit a special hidden default constructor for use by
  /// mixins.
  bool _usesMixinNew(Class mixin) {
    return mixin.superclass?.superclass == null &&
        mixin.constructors.every((c) => c.isExternal);
  }

  JS.Statement _addConstructorToClass(
      JS.Expression className, String name, JS.Expression jsCtor) {
    var ctorName = _constructorName(name);
    if (JS.invalidStaticFieldName(name)) {
      jsCtor =
          _callHelper('defineValue(#, #, #)', [className, ctorName, jsCtor]);
    } else {
      jsCtor = js.call('#.# = #', [className, ctorName, jsCtor]);
    }
    return js.statement('#.prototype = #.prototype;', [jsCtor, className]);
  }

  List<JS.Method> _emitClassMethods(Class c) {
    var virtualFields = _classProperties.virtualFields;

    var jsMethods = <JS.Method>[];
    bool hasJsPeer = findAnnotation(c, isJsPeerInterface) != null;
    bool hasIterator = false;

    if (c == coreTypes.objectClass) {
      // Dart does not use ES6 constructors.
      // Add an error to catch any invalid usage.
      jsMethods.add(
          new JS.Method(_propertyName('constructor'), js.call(r'''function() {
                  throw Error("use `new " + #.typeName(#.getReifiedType(this)) +
                      ".new(...)` to create a Dart object");
              }''', [_runtimeModule, _runtimeModule])));
    }

    for (var m in c.fields) {
      if (_extensionTypes.isNativeClass(c)) {
        jsMethods.addAll(_emitNativeFieldAccessors(m));
        continue;
      }
      if (m.isStatic) continue;
      if (virtualFields.containsKey(m)) {
        jsMethods.addAll(_emitVirtualFieldAccessor(m));
      }
    }

    var getters = new Map<String, Procedure>();
    var setters = new Map<String, Procedure>();
    for (var m in c.procedures) {
      if (m.isAbstract) continue;
      if (m.isGetter) {
        getters[m.name.name] = m;
      } else if (m.isSetter) {
        setters[m.name.name] = m;
      }
    }

    for (var m in c.procedures) {
      if (m.isForwardingStub) {
        // TODO(jmesserly): is there any other kind of forwarding stub?
        jsMethods.addAll(_emitCovarianceCheckStub(m));
      } else if (m.isFactory) {
        jsMethods.add(_emitFactoryConstructor(m));
      } else if (m.isAccessor) {
        jsMethods.add(_emitMethodDeclaration(m));
        jsMethods.add(_emitSuperAccessorWrapper(m, getters, setters));
        if (!hasJsPeer && m.isGetter && m.name.name == 'iterator') {
          hasIterator = true;
          jsMethods.add(_emitIterable(c));
        }
      } else {
        jsMethods.add(_emitMethodDeclaration(m));
      }
    }

    jsMethods.addAll(_classProperties.mockMembers.values
        .map((e) => _implementMockMember(e, c)));

    // If the type doesn't have an `iterator`, but claims to implement Iterable,
    // we inject the adaptor method here, as it's less code size to put the
    // helper on a parent class. This pattern is common in the core libraries
    // (e.g. IterableMixin<E> and IterableBase<E>).
    //
    // (We could do this same optimization for any interface with an `iterator`
    // method, but that's more expensive to check for, so it doesn't seem worth
    // it. The above case for an explicit `iterator` method will catch those.)
    if (!hasJsPeer && !hasIterator) {
      jsMethods.add(_emitIterable(c));
    }

    // Add all of the super helper methods
    jsMethods.addAll(_superHelpers.values);

    return jsMethods.where((m) => m != null).toList();
  }

  /// Emits a method, getter, or setter.
  JS.Method _emitMethodDeclaration(Procedure member) {
    if (member.isAbstract) {
      return null;
    }

    JS.Fun fn;
    if (member.isExternal) {
      if (member.isStatic) {
        // TODO(vsm): Do we need to handle this case?
        return null;
      }
      fn = _emitNativeFunctionBody(member);
    } else {
      fn = _emitFunction(member.function, member.name.name);
    }

    return new JS.Method(_declareMemberName(member), fn,
        isGetter: member.isGetter,
        isSetter: member.isSetter,
        isStatic: member.isStatic);
  }

  JS.Fun _emitNativeFunctionBody(Procedure node) {
    String name = getAnnotationName(node, isJSAnnotation) ?? node.name.name;
    if (node.isGetter) {
      return new JS.Fun([], js.statement('{ return this.#; }', [name]));
    } else if (node.isSetter) {
      var params = _emitFormalParameters(node.function);
      return new JS.Fun(
          params, js.statement('{ this.# = #; }', [name, params.last]));
    } else {
      return js.call(
          'function (...args) { return this.#.apply(this, args); }', name);
    }
  }

  List<JS.Method> _emitCovarianceCheckStub(Procedure member) {
    var name = _declareMemberName(member);
    if (member.isSetter) {
      return [
        new JS.Method(
            name,
            js.call('function(x) { return super.#(#._check(x)); }',
                [name, _emitType(member.setterType)]),
            isSetter: true),
        new JS.Method(name, js.call('function() { return super.#; }', [name]),
            isGetter: true)
      ];
    }
    assert(!member.isAccessor);

    var function = member.function;

    var body = <JS.Statement>[];
    var typeParameters = function.typeParameters;
    _emitCovarianceBoundsCheck(typeParameters, body);

    var typeFormals = _emitTypeFormals(typeParameters);
    var jsParams = new List<JS.Parameter>.from(typeFormals);
    var positionalParameters = function.positionalParameters;
    for (var i = 0, n = positionalParameters.length; i < n; i++) {
      var param = positionalParameters[i];
      var jsParam = new JS.Identifier(param.name);
      jsParams.add(jsParam);

      if (i >= function.requiredParameterCount) {
        body.add(js.statement('if (# !== void 0) #._check(#);',
            [jsParam, _emitType(param.type), jsParam]));
      } else {
        body.add(
            js.statement('#._check(#);', [_emitType(param.type), jsParam]));
      }
    }
    var namedParameters = function.namedParameters;
    for (var param in namedParameters) {
      var name = _propertyName(param.name);
      body.add(js.statement('if (# in #) #._check(#.#);', [
        name,
        namedArgumentTemp,
        _emitType(param.type),
        namedArgumentTemp,
        name
      ]));
    }

    if (namedParameters.isNotEmpty) jsParams.add(namedArgumentTemp);

    if (typeFormals.isEmpty) {
      body.add(js.statement('return super.#(#);', [name, jsParams]));
    } else {
      body.add(
          js.statement('return super.#(#)(#);', [name, typeFormals, jsParams]));
    }
    var fn = new JS.Fun(jsParams, new JS.Block(body));
    return [new JS.Method(name, fn)];
  }

  /// Emits a Dart factory constructor to a JS static method.
  JS.Method _emitFactoryConstructor(Procedure node) {
    return new JS.Method(
        _constructorName(node.name.name),
        new JS.Fun(_emitFormalParameters(node.function),
            _emitFunctionBody(node.function)),
        isStatic: true);
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  ///
  /// If [nameType] is true, then the type will be named.  In addition,
  /// if [hoistType] is true, then the named type will be hoisted.
  JS.Expression emitConstructorAccess(InterfaceType type) {
    return _emitJSInterop(type.classNode) ?? visitInterfaceType(type);
  }

  /// Given a class C that implements method M from interface I, but does not
  /// declare M, this will generate an implementation that forwards to
  /// noSuchMethod.
  ///
  /// For example:
  ///
  ///     class Cat {
  ///       bool eatFood(String food) => true;
  ///     }
  ///     class MockCat implements Cat {
  ///        noSuchMethod(Invocation invocation) => 3;
  ///     }
  ///
  /// It will generate an `eatFood` that looks like:
  ///
  ///     eatFood(...args) {
  ///       return core.bool.as(this.noSuchMethod(
  ///           new dart.InvocationImpl.new('eatFood', args)));
  ///     }
  JS.Method _implementMockMember(Procedure method, Class c) {
    var invocationProps = <JS.Property>[];
    addProperty(String name, JS.Expression value) {
      invocationProps.add(new JS.Property(js.string(name), value));
    }

    var args = new JS.TemporaryId('args');
    var function = method.function;
    var typeParams = _emitTypeFormals(function.typeParameters);
    var fnArgs = new List<JS.Parameter>.from(typeParams);
    JS.Expression positionalArgs;

    if (function.namedParameters.isNotEmpty) {
      addProperty('namedArguments', _callHelper('extractNamedArgs(#)', [args]));
    }

    if (!method.isAccessor) {
      addProperty('isMethod', js.boolean(true));

      fnArgs.add(new JS.RestParameter(args));
      positionalArgs = args;
    } else {
      if (method.isGetter) {
        addProperty('isGetter', js.boolean(true));

        positionalArgs = new JS.ArrayInitializer([]);
      } else if (method.isSetter) {
        addProperty('isSetter', js.boolean(true));

        fnArgs.add(args);
        positionalArgs = new JS.ArrayInitializer([args]);
      }
    }

    if (typeParams.isNotEmpty) {
      addProperty('typeArguments', new JS.ArrayInitializer(typeParams));
    }

    var fnBody =
        js.call('this.noSuchMethod(new #.InvocationImpl.new(#, #, #))', [
      _runtimeModule,
      _declareMemberName(method),
      positionalArgs,
      new JS.ObjectInitializer(invocationProps)
    ]);

    var returnType = Substitution
        .fromSupertype(hierarchy.getClassAsInstanceOf(c, method.enclosingClass))
        .substituteType(method.function.functionType);
    if (!types.isTop(returnType)) {
      fnBody = js.call('#._check(#)', [_emitType(returnType), fnBody]);
    }

    var fn = new JS.Fun(fnArgs, js.statement('{ return #; }', [fnBody]),
        typeParams: typeParams);

    return new JS.Method(
        _declareMemberName(method,
            useExtension: _extensionTypes.isNativeClass(c)),
        fn,
        isGetter: method.isGetter,
        isSetter: method.isSetter,
        isStatic: false);
  }

  /// This is called whenever a derived class needs to introduce a new field,
  /// shadowing a field or getter/setter pair on its parent.
  ///
  /// This is important because otherwise, trying to read or write the field
  /// would end up calling the getter or setter, and one of those might not even
  /// exist, resulting in a runtime error. Even if they did exist, that's the
  /// wrong behavior if a new field was declared.
  List<JS.Method> _emitVirtualFieldAccessor(Field field) {
    var virtualField = _classProperties.virtualFields[field];
    var result = <JS.Method>[];
    var name = _declareMemberName(field);

    var mocks = _classProperties.mockMembers;
    if (!mocks.containsKey(field.name.name)) {
      var getter = js.call('function() { return this[#]; }', [virtualField]);
      result.add(new JS.Method(name, getter, isGetter: true));
    }

    if (!mocks.containsKey(field.name.name + '=')) {
      var args = field.isFinal
          ? [new JS.Super(), name]
          : [new JS.This(), virtualField];

      String jsCode;
      if (!field.isFinal && field.isGenericCovariantImpl) {
        args.add(_emitType(field.type));
        jsCode = 'function(value) { #[#] = #._check(value); }';
      } else {
        jsCode = 'function(value) { #[#] = value; }';
      }

      result.add(new JS.Method(name, js.call(jsCode, args), isSetter: true));
    }

    return result;
  }

  /// Provide Dart getters and setters that forward to the underlying native
  /// field.  Note that the Dart names are always symbolized to avoid
  /// conflicts.  They will be installed as extension methods on the underlying
  /// native type.
  List<JS.Method> _emitNativeFieldAccessors(Field field) {
    // TODO(vsm): Can this by meta-programmed?
    // E.g., dart.nativeField(symbol, jsName)
    // Alternatively, perhaps it could be meta-programmed directly in
    // dart.registerExtensions?
    var jsMethods = <JS.Method>[];
    if (field.isStatic) return jsMethods;

    var name = getAnnotationName(field, isJSName) ?? field.name;
    // Generate getter
    var fn = new JS.Fun([], js.statement('{ return this.#; }', [name]));
    var method = new JS.Method(_declareMemberName(field), fn, isGetter: true);
    jsMethods.add(method);

    // Generate setter
    if (!field.isFinal) {
      var value = new JS.TemporaryId('value');
      fn = new JS.Fun([value], js.statement('{ this.# = #; }', [name, value]));
      method = new JS.Method(_declareMemberName(field), fn, isSetter: true);
      jsMethods.add(method);
    }

    return jsMethods;
  }

  /// Emit a getter (or setter) that simply forwards to the superclass getter
  /// (or setter).
  ///
  /// This is needed because in ES6, if you only override a getter
  /// (alternatively, a setter), then there is an implicit override of the
  /// setter (alternatively, the getter) that does nothing.
  JS.Method _emitSuperAccessorWrapper(Procedure method,
      Map<String, Procedure> getters, Map<String, Procedure> setters) {
    var name = method.name.name;
    var memberName = _declareMemberName(method);
    if (method.isGetter) {
      if (!setters.containsKey(name) &&
          _classProperties.inheritedSetters.contains(name)) {
        // Generate a setter that forwards to super.
        var fn = js.call('function(value) { super[#] = value; }', [memberName]);
        return new JS.Method(memberName, fn, isSetter: true);
      }
    } else {
      assert(method.isSetter);
      if (!getters.containsKey(name) &&
          _classProperties.inheritedGetters.contains(name)) {
        // Generate a getter that forwards to super.
        var fn = js.call('function() { return super[#]; }', [memberName]);
        return new JS.Method(memberName, fn, isGetter: true);
      }
    }
    return null;
  }

  /// Support for adapting dart:core Iterable to ES6 versions.
  ///
  /// This lets them use for-of loops transparently:
  /// <https://github.com/lukehoban/es6features#iterators--forof>
  ///
  /// This will return `null` if the adapter was already added on a super type,
  /// otherwise it returns the adapter code.
  // TODO(jmesserly): should we adapt `Iterator` too?
  JS.Method _emitIterable(Class c) {
    var iterable = hierarchy.getClassAsInstanceOf(c, coreTypes.iterableClass);
    if (iterable == null) return null;

    // If a parent had an `iterator` (concrete or abstract) or implements
    // Iterable, we know the adapter is already there, so we can skip it as a
    // simple code size optimization.
    var parent =
        hierarchy.getDispatchTarget(c.superclass, new Name('iterator'));
    if (parent != null) return null;

    var parentIterable =
        hierarchy.getClassAsInstanceOf(c.superclass, coreTypes.iterableClass);
    if (parentIterable != null) return null;

    if (c.enclosingLibrary.importUri.scheme == 'dart' &&
        c.procedures.any((m) => getJSExportName(m) == 'Symbol.iterator')) {
      return null;
    }

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return new JS.Method(
        js.call('Symbol.iterator'),
        js.call('function() { return new #.JsIterator(this.#); }', [
          _runtimeModule,
          _emitMemberName('iterator', type: iterable.asInterfaceType)
        ]) as JS.Fun);
  }

  JS.Expression _instantiateAnnotation(Expression node) =>
      _visitExpression(node);

  /// Gets the JS peer for this Dart type if any, otherwise null.
  ///
  /// For example for dart:_interceptors `JSArray` this will return "Array",
  /// referring to the JavaScript built-in `Array` type.
  List<String> _getJSPeerNames(Class c) {
    var jsPeerNames = getAnnotationName(
        c,
        (a) =>
            isJsPeerInterface(a) ||
            isNativeAnnotation(a) && _extensionTypes.isNativeClass(c));
    if (c == coreTypes.objectClass) return ['Object'];
    if (jsPeerNames == null) return [];

    // Omit the special name "!nonleaf" and any future hacks starting with "!"
    var result =
        jsPeerNames.split(',').where((peer) => !peer.startsWith("!")).toList();
    return result;
  }

  void _registerExtensionType(
      Class c, String jsPeerName, List<JS.Statement> body) {
    var className = _emitTopLevelName(c);
    if (isPrimitiveType(c.rawType)) {
      body.add(_callHelperStatement(
          'definePrimitiveHashCode(#.prototype)', className));
    }
    body.add(_callHelperStatement(
        'registerExtension(#, #);', [js.string(jsPeerName), className]));
  }

  JS.Statement _emitJSType(Class c) {
    var jsTypeName = getAnnotationName(c, isJSAnnotation);
    if (jsTypeName == null || jsTypeName == c.name) return null;

    // We export the JS type as if it was a Dart type. For example this allows
    // `dom.InputElement` to actually be HTMLInputElement.
    // TODO(jmesserly): if we had the JS name on the Element, we could just
    // generate it correctly when we refer to it.
    return js.statement('# = #;', [_emitTopLevelName(c), jsTypeName]);
  }

  JS.Statement _emitTypedef(Typedef t) {
    var body = _callHelper(
        'typedef(#, () => #)', [js.string(t.name, "'"), _emitType(t.type)]);

    if (t.typeParameters.isNotEmpty) {
      return _defineClassTypeArguments(
          t, t.typeParameters, js.statement('const # = #;', [t.name, body]));
    } else {
      return js.statement('# = #;', [_emitTopLevelName(t), body]);
    }
  }

  /// Treat dart:_runtime fields as safe to eagerly evaluate.
  // TODO(jmesserly): it'd be nice to avoid this special case.
  JS.Statement _emitInternalSdkFields(Iterable<Field> fields) {
    var lazyFields = <Field>[];
    for (var field in fields) {
      // Skip our magic undefined constant.
      if (field.name == 'undefined') continue;

      var init = field.initializer;
      if (init == null ||
          init is BasicLiteral ||
          _isJSInvocation(init) ||
          init is ConstructorInvocation &&
              isSdkInternalRuntime(init.target.enclosingLibrary)) {
        _moduleItems.add(js.statement('# = #;', [
          _emitTopLevelName(field),
          _visitInitializer(init, field.annotations)
        ]));
      } else {
        lazyFields.add(field);
      }
    }
    return _emitLazyFields(_currentLibrary, lazyFields);
  }

  bool _isJSInvocation(Expression expr) =>
      expr is StaticInvocation && isInlineJS(expr.target);

  JS.Statement _emitLazyFields(NamedNode target, Iterable<Field> fields) {
    var accessors = <JS.Method>[];
    for (var field in fields) {
      var name = field.name.name;
      var access = _emitStaticMemberName(name);
      accessors.add(new JS.Method(
          access,
          js.call('function() { return #; }',
                  _visitInitializer(field.initializer, field.annotations))
              as JS.Fun,
          isGetter: true));

      // TODO(jmesserly): currently uses a dummy setter to indicate writable.
      if (!field.isFinal && !field.isConst) {
        accessors.add(new JS.Method(access, js.call('function(_) {}') as JS.Fun,
            isSetter: true));
      }
    }

    var objExpr =
        target is Class ? _emitTopLevelName(target) : emitLibraryName(target);

    return _callHelperStatement('defineLazy(#, { # });', [objExpr, accessors]);
  }

  JS.PropertyAccess _emitTopLevelName(NamedNode n, {String suffix: ''}) {
    return _emitJSInterop(n) ?? _emitTopLevelNameNoInterop(n, suffix: suffix);
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  JS.Expression _declareMemberName(Member m, {bool useExtension}) {
    return _emitMemberName(m.name.name,
        isStatic: m is Field ? m.isStatic : (m as Procedure).isStatic,
        useExtension:
            useExtension ?? _extensionTypes.isNativeClass(m.enclosingClass),
        member: m);
  }

  /// This handles member renaming for private names and operators.
  ///
  /// Private names are generated using ES6 symbols:
  ///
  ///     // At the top of the module:
  ///     let _x = Symbol('_x');
  ///     let _y = Symbol('_y');
  ///     ...
  ///
  ///     class Point {
  ///       Point(x, y) {
  ///         this[_x] = x;
  ///         this[_y] = y;
  ///       }
  ///       get x() { return this[_x]; }
  ///       get y() { return this[_y]; }
  ///     }
  ///
  /// For user-defined operators the following names are allowed:
  ///
  ///     <, >, <=, >=, ==, -, +, /, ~/, *, %, |, ^, &, <<, >>, []=, [], ~
  ///
  /// They generate code like:
  ///
  ///     x['+'](y)
  ///
  /// There are three exceptions: [], []= and unary -.
  /// The indexing operators we use `get` and `set` instead:
  ///
  ///     x.get('hi')
  ///     x.set('hi', 123)
  ///
  /// This follows the same pattern as ECMAScript 6 Map:
  /// <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map>
  ///
  /// Unary minus looks like: `x._negate()`.
  ///
  /// Equality is a bit special, it is generated via the Dart `equals` runtime
  /// helper, that checks for null. The user defined method is called '=='.
  ///
  JS.Expression _emitMemberName(String name,
      {DartType type,
      bool isStatic: false,
      bool useExtension,
      NamedNode member}) {
    // Static members skip the rename steps and may require JS interop renames.
    if (isStatic) {
      return _emitStaticMemberName(name, member);
    }

    // We allow some (illegal in Dart) member names to be used in our private
    // SDK code. These renames need to be included at every declaration,
    // including overrides in subclasses.
    if (member != null) {
      var runtimeName = getJSExportName(member);
      if (runtimeName != null) {
        var parts = runtimeName.split('.');
        if (parts.length < 2) return _propertyName(runtimeName);

        JS.Expression result = new JS.Identifier(parts[0]);
        for (int i = 1; i < parts.length; i++) {
          result = new JS.PropertyAccess(result, _propertyName(parts[i]));
        }
        return result;
      }
    }

    if (name.startsWith('_')) {
      return _emitPrivateNameSymbol(_currentLibrary, name);
    }

    useExtension ??= _isSymbolizedMember(type, name);
    name = JS.memberNameForDartMember(name);
    if (useExtension) {
      return _getExtensionSymbolInternal(name);
    }
    return _propertyName(name);
  }

  /// This is an internal method used by [_emitMemberName] and the
  /// optimized `dart:_runtime extensionSymbol` builtin to get the symbol
  /// for `dartx.<name>`.
  ///
  /// Do not call this directly; you want [_emitMemberName], which knows how to
  /// handle the many details involved in naming.
  JS.TemporaryId _getExtensionSymbolInternal(String name) {
    return _extensionSymbols.putIfAbsent(
        name,
        () => new JS.TemporaryId(
            '\$${JS.friendlyNameForDartOperator[name] ?? name}'));
  }

  /// Don't symbolize native members that just forward to the underlying
  /// native member.  We limit this to non-renamed members as the receiver
  /// may be a mock type.
  ///
  /// Note, this is an underlying assumption here that, if another native type
  /// subtypes this one, it also forwards this member to its underlying native
  /// one without renaming.
  bool _isSymbolizedMember(DartType type, String name) {
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).bound;
    }
    if (type == null ||
        type == const DynamicType() ||
        type == coreTypes.objectClass) {
      return isObjectMember(name);
    } else if (type is InterfaceType) {
      var c = type.classNode;
      if (_extensionTypes.isNativeClass(c)) {
        var member = _lookupForwardedMember(c, name);

        // Fields on a native class are implicitly native.
        // Methods/getters/setters are marked external/native.
        if (member is Field || member is Procedure && member.isExternal) {
          var jsName = getAnnotationName(member, isJSName);
          return jsName != null && jsName != name;
        } else {
          // Non-external members must be symbolized.
          return true;
        }
      }
      // If the receiver *may* be a native type (i.e., an interface allowed to
      // be implemented by a native class), conservatively symbolize - we don't
      // know whether it'll be implemented via forwarding.
      // TODO(vsm): Consider CHA here to be less conservative.
      return _extensionTypes.isNativeInterface(c);
    } else if (type is FunctionType) {
      return true;
    }
    return false;
  }

  var _forwardingCache = new HashMap<Class, Map<String, Member>>();

  Member _lookupForwardedMember(Class c, String name) {
    // We only care about public methods.
    if (name.startsWith('_')) return null;

    var map = _forwardingCache.putIfAbsent(c, () => {});

    return map.putIfAbsent(
        name,
        () =>
            hierarchy.getDispatchTarget(c, new Name(name)) ??
            hierarchy.getDispatchTarget(c, new Name(name), setter: true));
  }

  JS.TemporaryId _emitPrivateNameSymbol(Library library, String name) {
    return _privateNames
        .putIfAbsent(library, () => new HashMap())
        .putIfAbsent(name, () {
      var id = new JS.TemporaryId(name);
      _moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(id.name, "'")]));
      return id;
    });
  }

  JS.Expression _emitStaticMemberName(String name, [NamedNode member]) {
    if (member != null) {
      var jsName = _emitJSInteropStaticMemberName(member);
      if (jsName != null) return jsName;
    }

    switch (name) {
      // Reserved for the compiler to do `x as T`.
      case 'as':
      // Reserved for the compiler to do implicit cast `T x = y`.
      case '_check':
      // Reserved for the SDK to compute `Type.toString()`.
      case 'name':
      // Reserved by JS, not a valid static member name.
      case 'prototype':
        name += '_';
        break;
      default:
        // All trailing underscores static names are reserved for the compiler
        // or SDK libraries.
        //
        // If user code uses them, add an extra `_`.
        //
        // This also avoids collision with the renames above, e.g. `static as`
        // and `static as_` will become `as_` and `as__`.
        if (name.endsWith('_')) {
          name += '_';
        }
    }
    return _propertyName(name);
  }

  JS.Expression _emitJSInteropStaticMemberName(NamedNode n) {
    if (!isJSElement(n)) return null;
    var name = getAnnotationName(n, isPublicJSAnnotation);
    if (name != null) {
      if (name.contains('.')) {
        throw new UnsupportedError(
            'static members do not support "." in their names. '
            'See https://github.com/dart-lang/sdk/issues/27926');
      }
    } else {
      name = getTopLevelName(n);
    }
    return js.escapedString(name, "'");
  }

  JS.PropertyAccess _emitTopLevelNameNoInterop(NamedNode n,
      {String suffix: ''}) {
    var name = getJSExportName(n) ?? getTopLevelName(n);
    return new JS.PropertyAccess(
        emitLibraryName(getLibrary(n)), _propertyName(name + suffix));
  }

  String _getJSNameWithoutGlobal(NamedNode n) {
    if (!isJSElement(n)) return null;
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
    var access = _callHelper('global');
    for (var part in name.split('.')) {
      access = new JS.PropertyAccess(access, js.escapedString(part, "'"));
    }
    return access;
  }

  void _emitLibraryProcedures(Library library) {
    var procedures =
        library.procedures.where((p) => !p.isExternal && !p.isAbstract);
    _moduleItems.addAll(procedures
        .where((p) => !p.isAccessor)
        .map(_emitLibraryFunction)
        .toList());
    _moduleItems
        .add(_emitLibraryAccessors(procedures.where((p) => p.isAccessor)));
  }

  JS.Statement _emitLibraryAccessors(Iterable<Procedure> accessors) {
    return _callHelperStatement('copyProperties(#, { # });', [
      emitLibraryName(_currentLibrary),
      accessors.map(_emitLibraryAccessor).toList()
    ]);
  }

  JS.Method _emitLibraryAccessor(Procedure node) {
    var name = node.name.name;
    return new JS.Method(
        _propertyName(name), _emitFunction(node.function, node.name.name),
        isGetter: node.isGetter, isSetter: node.isSetter);
  }

  JS.Statement _emitLibraryFunction(Procedure p) {
    var body = <JS.Statement>[];
    var fn = _emitFunction(p.function, p.name.name)..sourceInformation = p;

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
    return _callHelper(lazy ? 'lazyFn(#, () => #)' : 'fn(#, #)', [fn, typeRep]);
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

  JS.Expression _emitInvalidNode(Node node, [String message = '']) {
    if (message.isNotEmpty) message += ' ';
    return _callHelper('throwUnimplementedError(#)',
        [js.escapedString('node <${node.runtimeType}> $message`$node`')]);
  }

  JS.Expression _nameType(DartType type, JS.Expression typeRep) =>
      _currentFunction != null ? _typeTable.nameType(type, typeRep) : typeRep;

  @override
  defaultDartType(type) => _emitInvalidNode(type);

  @override
  visitInvalidType(type) => defaultDartType(type);

  @override
  visitDynamicType(type) => _callHelper('dynamic');

  @override
  visitVoidType(type) => _callHelper('void');

  @override
  visitBottomType(type) => _callHelper('bottom');

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
      return _callHelper(
          'anonymousJSType(#)', js.escapedString(getLocalClassName(c)));
    }
    var jsName = _getJSNameWithoutGlobal(c);
    if (jsName != null) {
      return _callHelper('lazyJSType(() => #, #)',
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
      return _nameType(type, _emitGenericClassType(type, jsArgs));
    }

    return _emitTopLevelNameNoInterop(type.classNode);
  }

  JS.Expression _emitGenericClassType(
      InterfaceType t, Iterable<JS.Expression> typeArgs) {
    var genericName = _emitTopLevelNameNoInterop(t.classNode, suffix: '\$');
    return js.call('#(#)', [genericName, typeArgs]);
  }

  @override
  visitVectorType(type) => defaultDartType(type);

  @override
  visitFunctionType(type, {bool lowerTypedef: false, FunctionNode function}) {
    var requiredTypes =
        type.positionalParameters.take(type.requiredParameterCount).toList();
    var requiredParams = function?.positionalParameters
        ?.take(type.requiredParameterCount)
        ?.toList();
    var optionalTypes =
        type.positionalParameters.skip(type.requiredParameterCount).toList();
    var optionalParams = function?.positionalParameters
        ?.skip(type.requiredParameterCount)
        ?.toList();

    var namedTypes = type.namedParameters;
    var rt = _emitType(type.returnType);
    var ra = _emitTypeNames(requiredTypes, requiredParams);

    List<JS.Expression> typeParts;
    if (namedTypes.isNotEmpty) {
      assert(optionalTypes.isEmpty);
      // TODO(vsm): Pass in annotations here as well.
      var na = _emitTypeProperties(namedTypes);
      typeParts = [rt, ra, na];
    } else if (optionalTypes.isNotEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(optionalTypes, optionalParams);
      typeParts = [rt, ra, oa];
    } else {
      typeParts = [rt, ra];
    }

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
    return _nameType(type, _callHelper(helperCall, [typeParts]));
  }

  JS.Expression _emitAnnotatedFunctionType(
      FunctionType type, List<Expression> metadata,
      {FunctionNode function, bool nameType: true, bool definite: false}) {
    var result = visitFunctionType(type, function: function);
    return _emitAnnotatedResult(result, metadata);
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  JS.Expression _emitConstructorAccess(InterfaceType type) {
    return _emitJSInterop(type.classNode) ?? _emitType(type);
  }

  JS.Expression _emitConstructorName(InterfaceType type, Member c) {
    return _emitJSInterop(type.classNode) ??
        new JS.PropertyAccess(
            _emitConstructorAccess(type), _constructorName(c.name.name));
  }

  /// Emits an expression that lets you access statics on an [element] from code.
  JS.Expression _emitStaticAccess(Class c) {
    _declareBeforeUse(c);
    return _emitTopLevelName(c);
  }

  // Wrap a result - usually a type - with its metadata.  The runtime is
  // responsible for unpacking this.
  JS.Expression _emitAnnotatedResult(
      JS.Expression result, List<Expression> metadata) {
    if (emitMetadata && metadata != null && metadata.isNotEmpty) {
      result = new JS.ArrayInitializer(
          [result]..addAll(metadata.map(_instantiateAnnotation)));
    }
    return result;
  }

  JS.ObjectInitializer _emitTypeProperties(Iterable<NamedType> types) {
    return new JS.ObjectInitializer(types
        .map((t) => new JS.Property(_propertyName(t.name), _emitType(t.type)))
        .toList());
  }

  JS.ArrayInitializer _emitTypeNames(
      List<DartType> types, List<VariableDeclaration> parameters) {
    var result = <JS.Expression>[];
    for (int i = 0; i < types.length; ++i) {
      var metadata = parameters != null ? parameters[i].annotations : null;
      result.add(_emitAnnotatedResult(_emitType(types[i]), metadata));
    }
    return new JS.ArrayInitializer(result);
  }

  @override
  visitTypeParameterType(type) => _emitTypeParameter(type.parameter);

  JS.Identifier _emitTypeParameter(TypeParameter t) {
    _typeParamInConst?.add(t);
    return new JS.Identifier(getTypeParameterName(t));
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
      return _nameType(type, new JS.Call(genericName, jsArgs));
    }

    return _emitTopLevelNameNoInterop(type.typedefNode);
  }

  JS.Fun _emitFunction(FunctionNode f, String name) {
    // normal function (sync), vs (sync*, async, async*)
    var isSync = f.asyncMarker == AsyncMarker.Sync;
    var formals = _emitFormalParameters(f);
    var typeFormals = _emitTypeFormals(f.typeParameters);
    formals.insertAll(0, typeFormals);

    JS.Block code = isSync
        ? _emitFunctionBody(f)
        : new JS.Block([_emitGeneratorFunction(f, name).toReturn()]);

    if (name != null && formals.isNotEmpty) {
      if (name == '[]=') {
        // []= methods need to return the value. We could also address this at
        // call sites, but it's cleaner to instead transform the operator method.
        code = JS.alwaysReturnLastParameter(code, formals.last);
      } else if (name == '==' && _currentLibrary.importUri.scheme != 'dart') {
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

  // TODO(jmesserly): rename _emitParameters
  List<JS.Parameter> _emitFormalParameters(FunctionNode f) {
    var result =
        f.positionalParameters.map((p) => new JS.Identifier(p.name)).toList();
    if (f.namedParameters.isNotEmpty) {
      result.add(namedArgumentTemp);
    }
    return result;
  }

  void _emitVirtualFieldSymbols(Class c, List<JS.Statement> body) {
    _classProperties.virtualFields.forEach((field, virtualField) {
      body.add(js.statement('const # = Symbol(#);', [
        virtualField,
        js.string('${getLocalClassName(c)}.${field.name.name}')
      ]));
    });
  }

  List<JS.Parameter> _emitTypeFormals(List<TypeParameter> typeFormals) {
    return typeFormals
        .map((t) => new JS.Identifier(getTypeParameterName(t)))
        .toList(growable: false);
  }

  JS.Expression _emitGeneratorFunction(FunctionNode function, String name) {
    // Transforms `sync*` `async` and `async*` function bodies
    // using ES6 generators.

    emitGeneratorFn(Iterable<JS.Expression> getParameters(JS.Block jsBody)) {
      var savedSuperAllowed = _superAllowed;
      var savedController = _asyncStarController;
      _superAllowed = false;

      _asyncStarController = function.asyncMarker == AsyncMarker.AsyncStar
          ? new JS.TemporaryId('stream')
          : null;

      // Visit the body with our async* controller set.
      //
      // TODO(jmesserly): this will emit argument initializers (for default
      // values) inside the generator function body. Is that the best place?
      var jsBody = _emitFunctionBody(function);
      JS.Expression gen =
          new JS.Fun(getParameters(jsBody), jsBody, isGenerator: true);

      // Name the function if possible, to get better stack traces.
      if (name != null) {
        name = JS.friendlyNameForDartOperator[name] ?? name;
        gen = new JS.NamedFunction(new JS.TemporaryId(name), gen);
      }
      if (JS.This.foundIn(gen)) gen = js.call('#.bind(this)', gen);

      _superAllowed = savedSuperAllowed;
      _asyncStarController = savedController;
      return gen;
    }

    if (function.asyncMarker == AsyncMarker.SyncStar) {
      // `sync*` wraps a generator in a Dart Iterable<E>:
      //
      // function name(<args>) {
      //   return new SyncIterator<E>(() => (function* name(<mutated args>) {
      //     <body>
      //   }(<mutated args>));
      // }
      //
      // In the body of a `sync*`, `yield` is generated simply as `yield`.
      //
      // We need to include all <mutated args> as parameters of the generator,
      // so each `.iterator` starts with the same initial values.
      //
      // We also need to ensure the correct `this` is available.
      //
      // In the future, we might be able to simplify this, see:
      // https://github.com/dart-lang/sdk/issues/28320

      var jsParams = _emitFormalParameters(function);
      var gen = emitGeneratorFn((fnBody) => jsParams =
          jsParams.where(JS.findMutatedVariables(fnBody).contains).toList());
      if (jsParams.isNotEmpty) gen = js.call('() => #(#)', [gen, jsParams]);

      var returnType =
          _getExpectedReturnType(function, coreTypes.iterableClass);
      var syncIterable =
          _emitType(new InterfaceType(syncIterableClass, [returnType]));
      return js.call('new #.new(#)', [syncIterable, gen]);
    }

    if (function.asyncMarker == AsyncMarker.AsyncStar) {
      // `async*` uses the `dart.asyncStar` helper, and also has an extra
      // `stream` parameter to the generator, which is used for passing values
      // to the `_AsyncStarStreamController` implementation type.
      //
      // `yield` is specially generated inside `async*` by visitYieldStatement.
      // `await` is generated as `yield`.
      //
      // dart:_runtime/generators.dart has an example of the generated code.
      var gen = emitGeneratorFn((_) => [_asyncStarController]);

      var returnType = _getExpectedReturnType(function, coreTypes.streamClass);
      return _callHelper('asyncStar(#, #)', [_emitType(returnType), gen]);
    }

    assert(function.asyncMarker == AsyncMarker.Async);

    // `async` works similar to `sync*`:
    //
    // function name(<args>) {
    //   return async.async(E, function* name() {
    //     <body>
    //   });
    // }
    //
    // In the body of an `async`, `await` is generated simply as `yield`.
    var gen = emitGeneratorFn((_) => []);
    var returnType = _getExpectedReturnType(function, coreTypes.futureClass);
    return js.call('#.async(#, #)',
        [emitLibraryName(coreTypes.asyncLibrary), _emitType(returnType), gen]);
  }

  // TODO(leafp): Various analyzer pieces computed similar things.
  // Share this logic somewhere?
  DartType _getExpectedReturnType(FunctionNode f, Class expected) {
    var type = f.functionType.returnType;
    if (type is InterfaceType) {
      var match = hierarchy.getTypeAsInstanceOf(type, expected);
      return match.typeArguments[0];
    }
    return const DynamicType();
  }

  JS.Block _emitFunctionBody(FunctionNode f) {
    var savedFunction = _currentFunction;
    _currentFunction = f;
    var savedLetVariables = _letVariables;
    _letVariables = [];

    var block = _emitArgumentInitializers(f);
    var jsBody = _visitStatement(f.body);
    if (jsBody != null) {
      if (jsBody is JS.Block && (block.isEmpty || !jsBody.isScope)) {
        // If the body is a nested block that can be flattened, do so.
        block.addAll(jsBody.statements);
      } else {
        block.add(jsBody);
      }
    }

    _initTempVars(block);
    _currentFunction = savedFunction;
    _letVariables = savedLetVariables;

    if (f.asyncMarker == AsyncMarker.Sync) {
      // It is a JS syntax error to use let or const to bind two variables with
      // the same name in the same scope.  If the let- and const- bound
      // variables in the block shadow any of the parameters, wrap the body in
      // an extra block.  (sync*, async, and async* function bodies are placed
      // in an inner function that is a separate scope from the parameters.)
      var parameterNames = new Set<String>()
        ..addAll(f.positionalParameters.map((p) => p.name))
        ..addAll(f.namedParameters.map((p) => p.name));

      if (block.any((s) => s.shadows(parameterNames))) {
        block = [new JS.Block(block, isScope: true)];
      }
    }

    return new JS.Block(block);
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  List<JS.Statement> _emitArgumentInitializers(FunctionNode f) {
    var body = <JS.Statement>[];

    _emitCovarianceBoundsCheck(f.typeParameters, body);

    initParameter(VariableDeclaration p, JS.Identifier jsParam) {
      if (p.isCovariant || p.isGenericCovariantImpl) {
        var castType = _emitType(p.type);
        body.add(js.statement('#._check(#);', [castType, jsParam]));
      }
      if (_annotatedNullCheck(p.annotations)) {
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
    return body;
  }

  bool _annotatedNullCheck(List<Expression> annotations) =>
      annotations.any(isNullCheckAnnotation);

  JS.Statement _nullParameterCheck(JS.Expression param) {
    var call = _callHelper('argumentError((#))', [param]);
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
        body.add(_callHelperStatement('checkTypeBound(#, #, #)', [
          _emitType(new TypeParameterType(t)),
          _emitType(t.bound),
          _propertyName(t.name)
        ]));
      }
    }
  }

  JS.LiteralString _emitDynamicOperationName(String name) =>
      js.string(replCompile ? '${name}Repl' : name);

  JS.Expression _callHelper(String code, [args]) {
    if (args is List) {
      args.insert(0, _runtimeModule);
    } else if (args != null) {
      args = [_runtimeModule, args];
    } else {
      args = _runtimeModule;
    }
    return js.call('#.$code', args);
  }

  JS.Statement _callHelperStatement(String code, args) {
    if (args is List) {
      args.insert(0, _runtimeModule);
    } else {
      args = [_runtimeModule, args];
    }
    return js.statement('#.$code', args);
  }

  JS.Statement _visitStatement(Statement s) {
    var result = s?.accept(this);
    if (result != null) {
      result.sourceInformation = s;

      // The statement might be the target of a break or continue with a label.
      var name = _labelNames[s];
      if (name != null) result = new JS.LabeledStatement(name, result);
    }
    return result;
  }

  /// Visits [nodes] with [_visitExpression].
  List<JS.Expression> _visitExpressionList(Iterable<Expression> nodes) {
    return nodes?.map(_visitExpression)?.toList();
  }

  /// Generates an expression for a boolean conversion context (if, while, &&,
  /// etc.), where conversions and null checks are implemented via `dart.test`
  /// to give a more helpful message.
  // TODO(sra): When nullablility is available earlier, it would be cleaner to
  // build an input AST where the boolean conversion is a single AST node.
  JS.Expression _visitTest(Expression node) {
    if (node == null) return null;

    JS.Expression finish(JS.Expression result) {
      result?.sourceInformation = node;
      return result;
    }

    if (node is Not) {
      // TODO(leafp): consider a peephole opt for identical
      // and == here.
      return finish(js.call('!#', _visitTest(node.operand)));
    }
    if (node is LogicalExpression) {
      JS.Expression shortCircuit(String code) {
        return finish(
            js.call(code, [_visitTest(node.left), _visitTest(node.right)]));
      }

      var op = node.operator;
      if (op == '&&') return shortCircuit('# && #');
      if (op == '||') return shortCircuit('# || #');
    }

    var result = _visitExpression(node);
    if (node.getStaticType(types) != coreTypes.boolClass.rawType) {
      return finish(_callHelper('dtest(#)', result));
    }
    if (isNullable(node)) result = _callHelper('test(#)', result);
    return finish(result);
  }

  JS.Expression _visitExpression(e) {
    JS.Expression result = e?.accept(this);
    return result;
  }

  JS.Expression _visitAndMarkExpression(Expression e) {
    JS.Expression result = e?.accept(this);
    if (result != null) result.sourceInformation = e;
    return result;
  }

  @override
  defaultStatement(Statement node) => _emitInvalidNode(node).toStatement();

  @override
  visitInvalidStatement(InvalidStatement node) => defaultStatement(node);

  @override
  visitExpressionStatement(ExpressionStatement node) =>
      _visitAndMarkExpression(node.expression).toStatement();

  @override
  visitBlock(Block node) =>
      new JS.Block(node.statements.map(_visitStatement).toList(),
          isScope: true);

  @override
  visitEmptyStatement(EmptyStatement node) => new JS.EmptyStatement();

  @override
  visitAssertStatement(AssertStatement node) {
    // TODO(jmesserly): only emit in checked mode.
    var condition = node.condition;
    var conditionType = condition.getStaticType(types);
    var jsCondition = _visitExpression(condition);

    var boolType = coreTypes.boolClass.rawType;
    if (conditionType is FunctionType &&
        conditionType.requiredParameterCount == 0 &&
        conditionType.returnType == boolType) {
      jsCondition = _callHelper('test(#())', jsCondition);
    } else if (conditionType != boolType) {
      jsCondition = _callHelper('dassert(#)', jsCondition);
    } else if (isNullable(condition)) {
      jsCondition = _callHelper('test(#)', jsCondition);
    }
    return js.statement(' if (!#) #.assertFailed(#);', [
      jsCondition,
      _runtimeModule,
      node.message != null ? [_visitExpression(node.message)] : []
    ]);
  }

  static isBreakable(Statement stmt) {
    // These are conservatively the things that compile to things that can be
    // the target of a break without a label.
    return stmt is ForStatement ||
        stmt is WhileStatement ||
        stmt is DoStatement ||
        stmt is ForInStatement ||
        stmt is SwitchStatement;
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    var saved;
    var target = _effectiveTargets[node];
    // If the effective target is known then this statement is either contained
    // in a labeled statement or a loop.  It has already been processed when
    // the enclosing statement was visited.
    if (target == null) {
      // Find the effective target by bypassing and collecting labeled
      // statements.
      var statements = [node];
      target = node.body;
      while (target is LabeledStatement) {
        statements.add(target);
        target = (target as LabeledStatement).body;
      }
      for (var statement in statements) _effectiveTargets[statement] = target;

      // If the effective target will compile to something that can have a
      // break from it without a label (e.g., a loop but not a block), then any
      // of the labeled statements can have a break from them by breaking from
      // the effective target.  Otherwise breaks will need a label and a break
      // without a label can still target an outer breakable so the list of
      // current break targets does not change.
      if (isBreakable(target)) {
        saved = _currentBreakTargets;
        _currentBreakTargets = statements;
      }
    }

    var result = _visitStatement(node.body);
    if (saved != null) _currentBreakTargets = saved;
    return result;
  }

  @override
  visitBreakStatement(BreakStatement node) {
    // Can it be compiled to a break without a label?
    if (_currentBreakTargets.contains(node.target)) {
      return new JS.Break(null);
    }
    // Can it be compiled to a continue without a label?
    if (_currentContinueTargets.contains(node.target)) {
      return new JS.Continue(null);
    }

    // Ensure the effective target is labeled.  Labels are named globally per
    // Kernel binary.
    //
    // TODO(kmillikin): Preserve Dart label names in Kernel and here.
    var target = _effectiveTargets[node.target];
    var name = _labelNames[target];
    if (name == null) _labelNames[target] = name = 'L${_labelNames.length}';

    // It is a break if the target labeled statement encloses the effective
    // target.
    var current = node.target;
    while (current is LabeledStatement) {
      current = (current as LabeledStatement).body;
    }
    if (identical(current, target)) {
      return new JS.Break(name);
    }
    // Otherwise it is a continue.
    return new JS.Continue(name);
  }

  // Labeled loop bodies can be the target of a continue without a label
  // (targeting the loop).  Find the outermost non-labeled statement starting
  // from body and record all the intermediate labeled statements as continue
  // targets.
  Statement effectiveBodyOf(Statement loop, Statement body) {
    // In a loop whose body is not labeled, this list should be empty because
    // it is not possible to continue to an outer loop without a label.
    _currentContinueTargets = <LabeledStatement>[];
    while (body is LabeledStatement) {
      _currentContinueTargets.add(body);
      _effectiveTargets[body] = loop;
      body = (body as LabeledStatement).body;
    }
    return body;
  }

  @override
  JS.While visitWhileStatement(WhileStatement node) {
    var condition = _visitTest(node.condition);

    var saved = _currentContinueTargets;
    var body = _visitScope(effectiveBodyOf(node, node.body));
    _currentContinueTargets = saved;

    return new JS.While(condition, body);
  }

  @override
  JS.Do visitDoStatement(DoStatement node) {
    var saved = _currentContinueTargets;
    var body = _visitScope(effectiveBodyOf(node, node.body));
    _currentContinueTargets = saved;

    return new JS.Do(body, _visitTest(node.condition));
  }

  @override
  JS.For visitForStatement(ForStatement node) {
    emitForInitializer(VariableDeclaration v) => new JS.VariableInitialization(
        _emitVariableRef(v)..sourceInformation = v,
        _visitInitializer(v.initializer, v.annotations));

    var init = node.variables.map(emitForInitializer).toList();
    var initList =
        init.isEmpty ? null : new JS.VariableDeclarationList('let', init);
    var updates = node.updates;
    JS.Expression update;
    if (updates.isNotEmpty) {
      update = new JS.Expression.binary(
              updates.map(_visitAndMarkExpression).toList(), ',')
          .toVoidExpression();
    }
    var condition = _visitTest(node.condition);

    var saved = _currentContinueTargets;
    var body = _visitScope(effectiveBodyOf(node, node.body));
    _currentContinueTargets = saved;

    return new JS.For(initList, condition, update, body);
  }

  @override
  JS.Statement visitForInStatement(ForInStatement node) {
    if (node.isAsync) {
      return _emitAwaitFor(node);
    }

    var iterable = _visitAndMarkExpression(node.iterable);

    var saved = _currentContinueTargets;
    var body = _visitScope(effectiveBodyOf(node, node.body));
    _currentContinueTargets = saved;

    var v = _emitVariableRef(node.variable);
    var init = js.call('let #', v);
    if (_annotatedNullCheck(node.variable.annotations)) {
      body = new JS.Block([_nullParameterCheck(v), body]);
    }

    return new JS.ForOf(init, iterable, body);
  }

  JS.Statement _emitAwaitFor(ForInStatement node) {
    // Emits `await for (var value in stream) ...`, which desugars as:
    //
    // var iter = new StreamIterator(stream);
    // try {
    //   while (await iter.moveNext()) {
    //     var value = iter.current;
    //     ...
    //   }
    // } finally {
    //   await iter.cancel();
    // }
    //
    // Like the Dart VM, we call cancel() always, as it's safe to call if the
    // stream has already been cancelled.
    //
    // TODO(jmesserly): we may want a helper if these become common. For now the
    // full desugaring seems okay.
    var streamIterator = _asyncStreamIteratorClass.rawType;
    var createStreamIter = new JS.Call(
        _emitConstructorName(
            streamIterator,
            _asyncStreamIteratorClass.procedures
                .firstWhere((p) => p.isFactory && p.name.name == '')),
        [_visitExpression(node.iterable)]);

    var iter = new JS.TemporaryId('iter');
    var init =
        js.call('let # = #.current', [_emitVariableRef(node.variable), iter]);
    return js.statement(
        '{'
        '  let # = #;'
        '  try {'
        '    while (#) { #; #; }'
        '  } finally { #; }'
        '}',
        [
          iter,
          createStreamIter,
          new JS.Yield(js.call('#.moveNext()', iter)),
          init,
          _visitStatement(node.body),
          new JS.Yield(js.call('#.cancel()', iter))
        ]);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    var cases = <JS.SwitchClause>[];
    var emptyBlock = new JS.Block.empty();
    for (var c in node.cases) {
      // TODO(jmesserly): make sure we are statically checking fall through
      var body = _visitStatement(c.body);
      var expressions = c.expressions;
      var last =
          expressions.isNotEmpty && !c.isDefault ? expressions.last : null;
      for (var e in expressions) {
        var jsExpr = _visitAndMarkExpression(e);
        cases.add(new JS.Case(jsExpr, e == last ? body : emptyBlock));
      }
      if (c.isDefault) cases.add(new JS.Default(body));
    }

    return new JS.Switch(_visitAndMarkExpression(node.expression), cases);
  }

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    SwitchCase switchCase;
    for (Statement current = node;;) {
      var parent = current.parent;
      if (parent is Block && parent.statements.last == current) {
        current = parent;
        continue;
      }
      if (parent is SwitchCase) switchCase = parent;
      break;
    }
    if (switchCase != null) {
      var switchCases = (switchCase.parent as SwitchStatement).cases;
      var fromIndex = switchCases.indexOf(switchCase);
      var toIndex = switchCases.indexOf(node.target);
      if (toIndex == fromIndex + 1) {
        return new JS.Comment('continue to next case');
      }
    }
    return _emitInvalidNode(
            node, 'see https://github.com/dart-lang/sdk/issues/29352')
        .toStatement();
  }

  @override
  visitIfStatement(IfStatement node) {
    return new JS.If(_visitTest(node.condition), _visitScope(node.then),
        _visitScope(node.otherwise));
  }

  /// Visits a statement, and ensures the resulting AST handles block scope
  /// correctly. Essentially, we need to promote a variable declaration
  /// statement into a block in some cases, e.g.
  ///
  ///     do var x = 5; while (false); // Dart
  ///     do { let x = 5; } while (false); // JS
  JS.Statement _visitScope(Statement stmt) {
    var result = _visitStatement(stmt);
    if (result is JS.ExpressionStatement &&
        result.expression is JS.VariableDeclarationList) {
      return new JS.Block([result]);
    }
    return result;
  }

  @override
  JS.Statement visitReturnStatement(ReturnStatement node) {
    var e = node.expression;
    if (e == null) return new JS.Return();
    return _visitAndMarkExpression(e).toReturn();
  }

  @override
  visitTryCatch(TryCatch node) {
    return new JS.Try(
        _visitStatement(node.body).toBlock(), _visitCatch(node.catches), null);
  }

  JS.Catch _visitCatch(List<Catch> clauses) {
    if (clauses.isEmpty) return null;

    var savedCatch = _catchParameter;

    if (clauses.length == 1 && clauses.single.exception != null) {
      // Special case for a single catch.
      _catchParameter = clauses.single.exception;
    } else {
      _catchParameter = new VariableDeclaration('#e');
    }

    JS.Statement catchBody =
        js.statement('throw #;', _emitVariableRef(_catchParameter));
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(clause, catchBody);
    }

    var catchVarDecl = _emitVariableRef(_catchParameter);
    _catchParameter = savedCatch;
    return new JS.Catch(catchVarDecl, new JS.Block([catchBody]));
  }

  JS.Statement _catchClauseGuard(Catch node, JS.Statement otherwise) {
    var body = <JS.Statement>[];

    var savedCatch = _catchParameter;
    if (node.exception != null) {
      var name = node.exception;
      if (name != null && name != _catchParameter) {
        body.add(js.statement('let # = #;',
            [_emitVariableRef(name), _emitVariableRef(_catchParameter)]));
        _catchParameter = name;
      }
      if (node.stackTrace != null) {
        var stackVar = _emitVariableRef(node.stackTrace);
        body.add(js.statement('let # = #.stackTrace(#);',
            [stackVar, _runtimeModule, _emitVariableRef(name)]));
      }
    }

    body.add(_visitStatement(node.body));
    _catchParameter = savedCatch;
    var then = JS.Statement.from(body);

    if (types.isTop(node.guard)) return then;

    // TODO(jmesserly): this is inconsistent with [visitIsExpression], which
    // has special case for typeof.
    return new JS.If(
        js.call('#.is(#)',
            [_emitType(node.guard), _emitVariableRef(_catchParameter)]),
        then,
        otherwise);
  }

  @override
  visitTryFinally(TryFinally node) {
    var body = _visitStatement(node.body);
    var catchPart = body is JS.Try ? body.catchPart : null;
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var finallyBlock = _visitStatement(node.finalizer);
    _superAllowed = savedSuperAllowed;
    return new JS.Try(body.toBlock(), catchPart, finallyBlock.toBlock());
  }

  @override
  visitYieldStatement(YieldStatement node) {
    var jsExpr = _visitExpression(node.expression);
    var star = node.isYieldStar;
    if (_asyncStarController != null) {
      // async* yields are generated differently from sync* yields. `yield e`
      // becomes:
      //
      //     if (stream.add(e)) return;
      //     yield;
      //
      // `yield* e` becomes:
      //
      //     if (stream.addStream(e)) return;
      //     yield;
      var helperName = star ? 'addStream' : 'add';
      return js.statement('{ if(#.#(#)) return; #; }',
          [_asyncStarController, helperName, jsExpr, new JS.Yield(null)]);
    }
    // A normal yield in a sync*
    return jsExpr.toYieldStatement(star: star);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // TODO(jmesserly): casts are sometimes required here.
    // Kernel does not represent these explicitly.
    var v = _emitVariableRef(node)..sourceInformation = node;
    return js.statement('let # = #;',
        [v, _visitInitializer(node.initializer, node.annotations)]);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    var func = node.function;
    var fn = _emitFunction(func, node.variable.name);

    var name = new JS.Identifier(node.variable.name)
      ..sourceInformation = node.variable;
    JS.Statement declareFn;
    if (JS.This.foundIn(fn)) {
      declareFn = js.statement('const # = #.bind(this);', [name, fn]);
    } else {
      declareFn = new JS.FunctionDeclaration(name, fn);
    }
    if (_reifyFunctionType(func)) {
      declareFn = new JS.Block([
        declareFn,
        _emitFunctionTagged(name, func.functionType).toStatement()
      ]);
    }
    return declareFn..sourceInformation = node;
  }

  @override
  defaultExpression(Expression node) => _emitInvalidNode(node);

  @override
  defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);

  @override
  visitInvalidExpression(InvalidExpression node) => defaultExpression(node);

  // [ConstantExpression] is produced by the Kernel constant evaluator, which
  // we do not use.
  @override
  visitConstantExpression(ConstantExpression node) => defaultExpression(node);

  @override
  visitVariableGet(VariableGet node) => _emitVariableRef(node.variable);

  JS.Identifier _emitVariableRef(VariableDeclaration v) {
    var name = v.name;
    if (name == null || name.startsWith('#')) {
      name = name == null ? 't${_tempVariables.length}' : name.substring(1);
      return _tempVariables.putIfAbsent(v, () => new JS.TemporaryId(name));
    }
    return new JS.Identifier(name);
  }

  void _initTempVars(List<JS.Statement> block) {
    if (_letVariables.isEmpty) return;
    block.insert(
        0,
        new JS.VariableDeclarationList(
                'let',
                _letVariables
                    .map((v) => new JS.VariableInitialization(v, null))
                    .toList())
            .toStatement());
    _letVariables.clear();
  }

  // TODO(jmesserly): resugar operators for kernel, such as ++x, x++, x+=.
  @override
  visitVariableSet(VariableSet node) => _visitExpression(node.value)
      .toAssignExpression(_emitVariableRef(node.variable));

  @override
  visitPropertyGet(PropertyGet node) {
    return _emitPropertyGet(
        node.receiver, node.interfaceTarget, node.name.name);
  }

  @override
  visitPropertySet(PropertySet node) {
    return _emitPropertySet(
        node.receiver, node.interfaceTarget, node.value, node.name.name)
      ..sourceInformation = node;
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    return _emitPropertyGet(node.receiver, node.target)
      ..sourceInformation = node;
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    return _emitPropertySet(node.receiver, node.target, node.value);
  }

  JS.Expression _emitPropertyGet(Expression receiver, Member member,
      [String memberName]) {
    var jsName = _emitMemberName(memberName ?? member.name.name,
        type: receiver.getStaticType(types), member: member);
    var jsReceiver = _visitExpression(receiver);

    if (member == null) {
      return _callHelper(
          '#(#, #)', [_emitDynamicOperationName('dload'), jsReceiver, jsName]);
    }

    if (_isObjectMemberCall(receiver, memberName)) {
      if (_isObjectMethod(memberName)) {
        return _callHelper('bind(#, #)', [jsReceiver, jsName]);
      } else {
        return _callHelper('#(#)', [memberName, jsReceiver]);
      }
    } else if (member is Procedure &&
        !member.isAccessor &&
        !_isJSNative(member.enclosingClass)) {
      return _callHelper('bind(#, #)', [jsReceiver, jsName]);
    } else {
      return new JS.PropertyAccess(jsReceiver, jsName);
    }
  }

  JS.Expression _emitPropertySet(
      Expression receiver, Member member, Expression value,
      [String memberName]) {
    var jsName = _emitMemberName(memberName ?? member.name.name,
        type: receiver.getStaticType(types), member: member);

    var jsReceiver = _visitExpression(receiver);
    var jsValue = _visitExpression(value);

    if (member == null) {
      return _callHelper('#(#, #, #)',
          [_emitDynamicOperationName('dput'), jsReceiver, jsName, jsValue]);
    }
    return js.call('#.# = #', [jsReceiver, jsName, jsValue]);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    var target = node.interfaceTarget;
    var jsTarget = _emitSuperTarget(target);
    if (target is Procedure &&
        !target.isAccessor &&
        !_isJSNative(target.enclosingClass)) {
      return _callHelper('bind(this, #, #)', [jsTarget.selector, jsTarget]);
    }
    return jsTarget;
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    var target = node.interfaceTarget;
    var jsTarget = _emitSuperTarget(target);
    return _visitExpression(node.value).toAssignExpression(jsTarget);
  }

  @override
  visitStaticGet(StaticGet node) {
    return _emitStaticTarget(node.target)..sourceInformation = node;
  }

  @override
  visitStaticSet(StaticSet node) {
    return _visitExpression(node.value)
        .toAssignExpression(_emitStaticTarget(node.target));
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    return _emitMethodCall(
        node.receiver, node.interfaceTarget, node.arguments, node);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    return _emitMethodCall(node.receiver, node.target, node.arguments, node);
  }

  JS.Expression _emitMethodCall(Expression receiver, Member target,
      Arguments arguments, InvocationExpression node) {
    var name = node.name.name;

    if (isOperatorMethodName(name) && arguments.named.isEmpty) {
      int argLength = arguments.positional.length;
      if (argLength == 0) {
        return _emitUnaryOperator(receiver, target, node);
      } else if (argLength == 1) {
        return _emitBinaryOperator(
            receiver, target, arguments.positional[0], node);
      }
    }

    var jsReceiver = _visitExpression(receiver);
    var args = _emitArgumentList(arguments);
    var receiverType = receiver.getStaticType(types);
    var typeArgs = arguments.types;

    isDynamicOrFunction(DartType t) =>
        t == coreTypes.functionClass.rawType || t == const DynamicType();
    bool isCallingDynamicField = target is Member &&
        target.hasGetter &&
        isDynamicOrFunction(target.getterType);
    if (name == 'call') {
      if (isCallingDynamicField || isDynamicOrFunction(receiverType)) {
        if (typeArgs.isNotEmpty) {
          return _callHelper('dgcall(#, #, #)', [
            jsReceiver,
            new JS.ArrayInitializer(args.take(typeArgs.length).toList()),
            args.skip(typeArgs.length).toList()
          ]);
        } else {
          return _callHelper('dcall(#, #)', [jsReceiver, args]);
        }
      }

      // Call methods on function types or interface types should be handled as
      // regular function invocations.
      return new JS.Call(jsReceiver, args);
    }

    var jsName = _emitMemberName(name, type: receiverType, member: target);
    if (target == null || isCallingDynamicField) {
      if (typeArgs.isNotEmpty) {
        return _callHelper('#(#, #, #, #)', [
          _emitDynamicOperationName('dgsend'),
          jsReceiver,
          new JS.ArrayInitializer(args.take(typeArgs.length).toList()),
          jsName,
          args.skip(typeArgs.length).toList()
        ]);
      } else {
        return _callHelper('#(#, #, #)',
            [_emitDynamicOperationName('dsend'), jsReceiver, jsName, args]);
      }
    }
    if (_isObjectMemberCall(receiver, name)) {
      assert(typeArgs.isEmpty); // Object methods don't take type args.
      return _callHelper('#(#, #)', [name, jsReceiver, args]);
    }
    return js.call('#.#(#)', [jsReceiver, jsName, args]);
  }

  JS.Expression _emitUnaryOperator(
      Expression expr, Member target, InvocationExpression node) {
    var op = node.name.name;
    var dispatchType = expr.getStaticType(types);
    if (_typeRep.unaryOperationIsPrimitive(dispatchType)) {
      if (op == '~') {
        if (_typeRep.isNumber(dispatchType)) {
          return _coerceBitOperationResultToUnsigned(
              node, js.call('~#', notNull(expr)));
        }
        return _emitSend(expr, target, op, []);
      }
      if (op == 'unary-') op = '-';
      return js.call('$op#', notNull(expr));
    }

    return _emitSend(expr, target, op, []);
  }

  /// Bit operations are coerced to values on [0, 2^32). The coercion changes
  /// the interpretation of the 32-bit value from signed to unsigned.  Most
  /// JavaScript operations interpret their operands as signed and generate
  /// signed results.
  JS.Expression _coerceBitOperationResultToUnsigned(
      Expression node, JS.Expression uncoerced) {
    // Don't coerce if the parent will coerce.
    var parent = node.parent;
    if (_nodeIsBitwiseOperation(parent)) return uncoerced;

    // Don't do a no-op coerce if the most significant bit is zero.
    if (_is31BitUnsigned(node)) return uncoerced;

    // If the consumer of the expression is '==' or '!=' with a constant that
    // fits in 31 bits, adding a coercion does not change the result of the
    // comparison, e.g.  `a & ~b == 0`.
    if (parent is InvocationExpression &&
        parent.arguments.positional.length == 1) {
      var op = parent.name.name;
      var left = getInvocationReceiver(parent);
      var right = parent.arguments.positional[0];
      if (left != null && op == '==') {
        const int MAX = 0x7fffffff;
        if (_asIntInRange(right, 0, MAX) != null) return uncoerced;
        if (_asIntInRange(left, 0, MAX) != null) return uncoerced;
      } else if (left != null && op == '>>') {
        if (_isDefinitelyNonNegative(left) &&
            _asIntInRange(right, 0, 31) != null) {
          // Parent will generate `# >>> n`.
          return uncoerced;
        }
      }
    }
    return js.call('# >>> 0', uncoerced);
  }

  bool _nodeIsBitwiseOperation(Node node) {
    if (node is InvocationExpression) {
      switch (node.name.name) {
        case '&':
        case '|':
        case '^':
        case '~':
          return true;
      }
    }
    return false;
  }

  int _asIntInRange(Expression expr, int low, int high) {
    if (expr is IntLiteral) {
      if (expr.value >= low && expr.value <= high) return expr.value;
      return null;
    }
    // TODO(jmesserly): other constant evaluation here once kernel supports it.
    return null;
  }

  bool _isDefinitelyNonNegative(Expression expr) {
    if (expr is IntLiteral) return expr.value >= 0;

    // TODO(sra): Lengths of known list types etc.
    return _nodeIsBitwiseOperation(expr);
  }

  /// Does the parent of [node] mask the result to [width] bits or fewer?
  bool _parentMasksToWidth(Expression node, int width) {
    var parent = node.parent;
    if (parent == null) return false;
    if (_nodeIsBitwiseOperation(parent)) {
      if (parent is InvocationExpression &&
          parent.name.name == '&' &&
          parent.arguments.positional.length == 1) {
        var left = getInvocationReceiver(parent);
        var right = parent.arguments.positional[0];
        final int MAX = (1 << width) - 1;
        if (left != null) {
          if (_asIntInRange(right, 0, MAX) != null) return true;
          if (_asIntInRange(left, 0, MAX) != null) return true;
        }
      }
      return _parentMasksToWidth(parent, width);
    }
    return false;
  }

  /// Determines if the result of evaluating [expr] will be an non-negative
  /// value that fits in 31 bits.
  bool _is31BitUnsigned(Expression expr) {
    const int MAX = 32; // Includes larger and negative values.
    /// Determines how many bits are required to hold result of evaluation
    /// [expr].  [depth] is used to bound exploration of huge expressions.
    int bitWidth(Expression expr, int depth) {
      if (expr is IntLiteral) {
        return expr.value >= 0 ? expr.value.bitLength : MAX;
      }
      if (++depth > 5) return MAX;
      if (expr is InvocationExpression &&
          expr.arguments.positional.length == 1) {
        var left = getInvocationReceiver(expr);
        var right = expr.arguments.positional[0];
        if (left != null) {
          switch (expr.name.name) {
            case '&':
              return min(bitWidth(left, depth), bitWidth(right, depth));

            case '|':
            case '^':
              return max(bitWidth(left, depth), bitWidth(right, depth));

            case '>>':
              int shiftValue = _asIntInRange(right, 0, 31);
              if (shiftValue != null) {
                int leftWidth = bitWidth(left, depth);
                return leftWidth == MAX ? MAX : max(0, leftWidth - shiftValue);
              }
              return MAX;

            case '<<':
              int leftWidth = bitWidth(left, depth);
              int shiftValue = _asIntInRange(right, 0, 31);
              if (shiftValue != null) {
                return min(MAX, leftWidth + shiftValue);
              }
              int rightWidth = bitWidth(right, depth);
              if (rightWidth <= 5) {
                // e.g.  `1 << (x & 7)` has a rightWidth of 3, so shifts by up to
                // (1 << 3) - 1 == 7 bits.
                return min(MAX, leftWidth + ((1 << rightWidth) - 1));
              }
              return MAX;
            default:
              return MAX;
          }
        }
      }
      int value = _asIntInRange(expr, 0, 0x7fffffff);
      if (value != null) return value.bitLength;
      return MAX;
    }

    return bitWidth(expr, 0) < 32;
  }

  JS.Expression _emitBinaryOperator(Expression left, Member target,
      Expression right, InvocationExpression node) {
    var op = node.name.name;
    if (op == '==') return _emitEqualityOperator(left, target, right);

    var leftType = left.getStaticType(types);
    var rightType = right.getStaticType(types);

    if (_typeRep.binaryOperationIsPrimitive(leftType, rightType) ||
        leftType == types.stringType && op == '+') {
      // special cases where we inline the operation
      // these values are assumed to be non-null (determined by the checker)
      // TODO(jmesserly): it would be nice to just inline the method from core,
      // instead of special cases here.
      JS.Expression binary(String code) {
        return js.call(code, [notNull(left), notNull(right)]);
      }

      JS.Expression bitwise(String code) {
        return _coerceBitOperationResultToUnsigned(node, binary(code));
      }

      switch (op) {
        case '~/':
          // `a ~/ b` is equivalent to `(a / b).truncate()`
          return js.call('(# / #).#()', [
            notNull(left),
            notNull(right),
            _emitMemberName('truncate', type: leftType)
          ]);

        case '%':
          // TODO(sra): We can generate `a % b + 0` if both are non-negative
          // (the `+ 0` is to coerce -0.0 to 0).
          return _emitSend(left, target, op, [right]);

        case '&':
          return bitwise('# & #');

        case '|':
          return bitwise('# | #');

        case '^':
          return bitwise('# ^ #');

        case '>>':
          int shiftCount = _asIntInRange(right, 0, 31);
          if (_is31BitUnsigned(left) && shiftCount != null) {
            return binary('# >> #');
          }
          if (_isDefinitelyNonNegative(left) && shiftCount != null) {
            return binary('# >>> #');
          }
          // If the context selects out only bits that can't be affected by the
          // sign position we can use any JavaScript shift, `(x >> 6) & 3`.
          if (shiftCount != null &&
              _parentMasksToWidth(node, 31 - shiftCount)) {
            return binary('# >> #');
          }
          return _emitSend(left, target, op, [right]);

        case '<<':
          if (_is31BitUnsigned(node)) {
            // Result is 31 bit unsigned which implies the shift count was small
            // enough not to pollute the sign bit.
            return binary('# << #');
          }
          if (_asIntInRange(right, 0, 31) != null) {
            return _coerceBitOperationResultToUnsigned(node, binary('# << #'));
          }
          return _emitSend(left, target, op, [right]);

        default:
          // TODO(vsm): When do Dart ops not map to JS?
          return binary('# $op #');
      }
    }

    return _emitSend(left, target, op, [right]);
  }

  JS.Expression _emitEqualityOperator(
      Expression left, Member target, Expression right) {
    var leftType = left.getStaticType(types);

    // Conceptually `x == y` in Dart is defined as:
    //
    // If either x or y is null, then they are equal iff they are both null.
    // Otherwise, equality is the result of calling `x.==(y)`.
    //
    // In practice, `x.==(y)` is equivalent to `identical(x, y)` in many cases:
    // - when either side is known to be `null` (literal or Null type)
    // - left side is an enum
    // - left side is a primitive type
    //
    // We also compile `operator ==` methods to ensure they check the right side
    // for null`. This allows us to skip the check at call sites.
    //
    // TODO(leafp,jmesserly): we could use class hierarchy analysis to check
    // if `operator ==` was overridden, similar to how we devirtualize private
    // fields.
    var isEnum = leftType is InterfaceType && leftType.classNode.isEnum;
    var usesIdentity = _typeRep.isPrimitive(leftType) ||
        isEnum ||
        _isNull(left) ||
        _isNull(right);

    // If we know that the left type uses identity for equality, we can
    // sometimes emit better code, either `===` or `==`.
    if (usesIdentity) {
      return _emitCoreIdenticalCall([left, right]);
    }

    // If the left side is nullable, we need to use a runtime helper to check
    // for null. We could inline the null check, but it did not seem to have
    // a measurable performance effect (possibly the helper is simple enough to
    // be inlined).
    if (isNullable(left)) {
      return _callHelper(
          'equals(#, #)', [_visitExpression(left), _visitExpression(right)]);
    }

    // Otherwise we emit a call to the == method.
    return js.call('#[#](#)', [
      _visitExpression(left),
      _emitMemberName('==', type: leftType),
      _visitExpression(right)
    ]);
  }

  /// Emits a generic send, like an operator method.
  ///
  /// **Please note** this function does not support method invocation syntax
  /// `obj.name(args)` because that could be a getter followed by a call.
  /// See [visitMethodInvocation].
  JS.Expression _emitSend(
      Expression receiver, Member target, String name, List<Expression> args) {
    // TODO(jmesserly): calls that don't pass `element` are probably broken for
    // `super` calls from disallowed super locations.
    var type = receiver.getStaticType(types);
    var memberName = _emitMemberName(name, type: type, member: target);
    if (target == null) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': 'dindex', '[]=': 'dsetindex'}[name];
      if (dynamicHelper != null) {
        return _callHelper('$dynamicHelper(#, #)',
            [_visitExpression(receiver), _visitExpressionList(args)]);
      } else {
        return _callHelper('dsend(#, #, #)', [
          _visitExpression(receiver),
          memberName,
          _visitExpressionList(args)
        ]);
      }
    }

    // Generic dispatch to a statically known method.
    return js.call('#.#(#)',
        [_visitExpression(receiver), memberName, _visitExpressionList(args)]);
  }

  // TODO(jmesserly): optimize super operators for kernel
  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    return new JS.Call(_emitSuperTarget(node.interfaceTarget),
        _emitArgumentList(node.arguments));
  }

  /// Emits the [JS.PropertyAccess] for accessors or method calls to
  /// [jsTarget].[jsName], replacing `super` if it is not allowed in scope.
  JS.PropertyAccess _emitSuperTarget(Member member, {bool setter: false}) {
    var type = member.enclosingClass.rawType;
    var jsName = _emitMemberName(member.name.name, type: type, member: member);
    if (member is Field && !virtualFields.isVirtual(member)) {
      return new JS.PropertyAccess(new JS.This(), jsName);
    }
    if (_superAllowed) return new JS.PropertyAccess(new JS.Super(), jsName);

    // If we can't emit `super` in this context, generate a helper that does it
    // for us, and call the helper.
    var name = member.name.name;
    var jsMethod = _superHelpers.putIfAbsent(name, () {
      var isAccessor = member is Procedure ? member.isAccessor : true;
      if (isAccessor) {
        assert(member is Procedure
            ? setter == member.isSetter
            : (member as Field).isFinal != setter);
        var fn = js.call(
            setter
                ? 'function(x) { super[#] = x; }'
                : 'function() { return super[#]; }',
            [jsName]);

        return new JS.Method(new JS.TemporaryId(name), fn,
            isGetter: !setter, isSetter: setter);
      } else {
        var function = member.function;
        var params = _emitTypeFormals(function.typeParameters);
        for (var param in function.positionalParameters) {
          params.add(new JS.Identifier(param.name));
        }
        if (function.namedParameters.isNotEmpty) {
          params.add(namedArgumentTemp);
        }

        var fn = js.call(
            'function(#) { return super[#](#); }', [params, jsName, params]);
        name = JS.friendlyNameForDartOperator[name] ?? name;
        return new JS.Method(new JS.TemporaryId(name), fn);
      }
    });
    return new JS.PropertyAccess(new JS.This(), jsMethod.name);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    var result = _emitForeignJS(node);
    if (result != null) return result;
    if (node.target.isFactory) {
      return _emitFactoryInvocation(node);
    }
    var target = node.target;
    if (target?.name == 'extensionSymbol' &&
        isSdkInternalRuntime(target.enclosingLibrary)) {
      var args = node.arguments;
      var firstArg = args.positional.length == 1 ? args.positional[0] : null;
      if (firstArg is StringLiteral) {
        return _getExtensionSymbolInternal(firstArg.value);
      }
    }
    if (target == coreTypes.identicalProcedure) {
      return _emitCoreIdenticalCall(node.arguments.positional);
    }

    var fn = _emitStaticTarget(target);
    var args = _emitArgumentList(node.arguments);
    return new JS.Call(fn, args);
  }

  /// Emits the target of a [StaticInvocation], [StaticGet], or [StaticSet].
  JS.Expression _emitStaticTarget(Member target) {
    var c = target.enclosingClass;
    if (c != null) {
      return new JS.PropertyAccess(_emitStaticAccess(c),
          _emitStaticMemberName(target.name.name, target));
    }
    return _emitTopLevelName(target);
  }

  List<JS.Expression> _emitArgumentList(Arguments node, {bool types: true}) {
    var args = <JS.Expression>[];
    if (types) {
      for (var typeArg in node.types) {
        args.add(_emitType(typeArg));
      }
    }
    for (var arg in node.positional) {
      if (arg is StaticInvocation &&
          isJSSpreadInvocation(arg.target) &&
          arg.arguments.positional.length == 1) {
        args.add(new JS.RestParameter(
            _visitExpression(arg.arguments.positional[0])));
      } else {
        args.add(_visitAndMarkExpression(arg));
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
    if (!isInlineJS(node.target)) return null;
    var args = node.arguments.positional;
    // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
    var code = args[1];
    List<Expression> templateArgs;
    String source;
    if (code is StringConcatenation) {
      if (args.length > 2) {
        throw new ArgumentError(
            "Can't mix template args and string interpolation in JS calls.");
      }
      templateArgs = <Expression>[];
      source = code.expressions.map((expression) {
        if (expression is StringLiteral) {
          return expression.value;
        } else {
          templateArgs.add(expression);
          return '#';
        }
      }).join();
    } else {
      templateArgs = args.skip(2).toList();
      source = (code as StringLiteral).value;
    }

    // TODO(vsm): Constructors in dart:html and friends are trying to
    // allocate a type defined on window/self, but this often conflicts a
    // with the generated extension class in scope.  We really should
    // qualify explicitly in dart:html itself.
    var constructorPattern = new RegExp("new [A-Z][A-Za-z]+\\(");
    if (constructorPattern.matchAsPrefix(source) != null) {
      var enclosingClass = node.parent;
      while (enclosingClass != null && enclosingClass is! Class) {
        enclosingClass = enclosingClass.parent;
      }
      if (enclosingClass is Class &&
          _extensionTypes.isNativeClass(enclosingClass)) {
        var constructorName = source.substring(4, source.indexOf('('));
        var className = enclosingClass.name;
        if (className == constructorName) {
          source =
              source.replaceFirst('new $className(', 'new self.$className(');
        }
      }
    }

    JS.Expression visitTemplateArg(Expression arg) {
      if (arg is StaticInvocation) {
        var target = arg.target;
        var positional = arg.arguments.positional;
        if (target.name == 'getGenericClass' &&
            isSdkInternalRuntime(target.enclosingLibrary) &&
            positional.length == 1) {
          var typeArg = positional[0];
          if (typeArg is TypeLiteral) {
            var type = typeArg.type;
            if (type is InterfaceType) {
              return _emitTopLevelNameNoInterop(type.classNode, suffix: '\$');
            }
          }
        }
      }
      return _visitExpression(arg);
    }

    // TODO(rnystrom): The JS() calls are almost never nested, and probably
    // really shouldn't be, but there are at least a couple of calls in the
    // HTML library where an argument to JS() is itself a JS() call. If those
    // go away, this can just assert(!_isInForeignJS).
    // Inside JS(), type names evaluate to the raw runtime type, not the
    // wrapped Type object.
    var wasInForeignJS = _isInForeignJS;
    _isInForeignJS = true;
    var jsArgs = templateArgs.map(visitTemplateArg).toList();
    _isInForeignJS = wasInForeignJS;

    var result = js.parseForeignJS(source).instantiate(jsArgs);

    // `throw` is emitted as a statement by `parseForeignJS`.
    assert(result is JS.Expression ||
        result is JS.Throw && node.parent is ExpressionStatement);
    return result;
  }

  bool _isNull(Expression expr) =>
      expr is NullLiteral ||
      expr.getStaticType(types) == coreTypes.nullClass.rawType;

  bool _doubleEqIsIdentity(Expression left, Expression right) {
    // If we statically know LHS or RHS is null we can use ==.
    if (_isNull(left) || _isNull(right)) return true;
    // If the representation of the  two types will not induce conversion in
    // JS then we can use == .
    return !_typeRep.equalityMayConvert(
        left.getStaticType(types), right.getStaticType(types));
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
      // tear-offs are not null, other accessors are nullable.
      return target is Procedure && target.isAccessor;
    }
    if (expr is StaticGet) {
      var target = expr.target;
      // tear-offs are not null, other accessors are nullable.
      return target is Procedure && target.isAccessor;
    }

    if (expr is TypeLiteral) return false;
    if (expr is BasicLiteral) return expr.value == null;
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
      return expr.target != coreTypes.identicalProcedure;
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

  JS.Expression _emitCoreIdenticalCall(List<Expression> args,
      {bool negated = false}) {
    if (args.length != 2) {
      // Shouldn't happen in typechecked code
      return _callHelper(
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
    return js.call(code,
        new JS.Call(_emitTopLevelName(coreTypes.identicalProcedure), jsArgs));
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    var target = node.target;
    var targetName = target.name;
    var args = node.arguments;

    var enclosingClass = target.enclosingClass;
    if (node.isConst &&
        targetName.name == 'fromEnvironment' &&
        target.enclosingLibrary == coreTypes.coreLibrary &&
        args.positional.length == 1) {
      var varName = (args.positional[0] as StringLiteral).value;
      var value = declaredVariables[varName];
      var defaultArg = args.named.isNotEmpty ? args.named[0].value : null;
      if (enclosingClass == coreTypes.stringClass) {
        value ??= (defaultArg as StringLiteral)?.value;
        return value != null ? js.escapedString(value) : new JS.LiteralNull();
      } else if (enclosingClass == coreTypes.intClass) {
        var intValue = int.parse(value ?? '',
            onError: (_) => (defaultArg as IntLiteral)?.value);
        return intValue != null ? js.number(intValue) : new JS.LiteralNull();
      } else if (enclosingClass == coreTypes.boolClass) {
        if (value == "true") return js.boolean(true);
        if (value == "false") return js.boolean(false);
        return js
            .boolean(defaultArg != null && (defaultArg as BoolLiteral)?.value);
      } else {
        return _emitInvalidNode(
            node, '${enclosingClass}.fromEnvironment constant');
      }
    }
    return _emitConstructorInvocation(
        target, node.constructedType, args, node.isConst);
  }

  JS.Expression _emitFactoryInvocation(StaticInvocation node) {
    var args = node.arguments;
    var target = node.target;
    var c = target.enclosingClass;
    var type =
        c.typeParameters.isEmpty ? c.rawType : new InterfaceType(c, args.types);
    if (args.positional.isEmpty &&
        args.named.isEmpty &&
        c.enclosingLibrary.importUri.scheme == 'dart') {
      // Skip the slow SDK factory constructors when possible.
      switch (c.name) {
        case 'Map':
        case 'HashMap':
        case 'LinkedHashMap':
          if (target.name == '') {
            return js.call('new #.new()', _emitMapImplType(type));
          } else if (target.name == 'identity') {
            return js.call(
                'new #.new()', _emitMapImplType(type, identity: true));
          }
          break;
        case 'Set':
        case 'HashSet':
        case 'LinkedHashSet':
          if (target.name == '') {
            return js.call('new #.new()', _emitSetImplType(type));
          } else if (target.name == 'identity') {
            return js.call(
                'new #.new()', _emitSetImplType(type, identity: true));
          }
          break;
        case 'List':
          if (target.name == '' && type is InterfaceType) {
            return _emitList(type.typeArguments[0], []);
          }
          break;
      }
    }

    JS.Expression emitNew() {
      // Native factory constructors are JS constructors - use new here.
      return new JS.Call(_emitConstructorName(type, target),
          _emitArgumentList(args, types: false));
    }

    return node.isConst ? _emitConst(emitNew) : emitNew();
  }

  JS.Expression _emitConstructorInvocation(
      Constructor ctor, InterfaceType type, Arguments arguments, bool isConst) {
    var enclosingClass = ctor.enclosingClass;
    if (_isObjectLiteral(enclosingClass)) {
      return _emitObjectLiteral(arguments);
    }

    JS.Expression emitNew() {
      return new JS.New(_emitConstructorName(type, ctor),
          _emitArgumentList(arguments, types: false));
    }

    return isConst ? _emitConst(emitNew) : emitNew();
  }

  JS.Expression _emitMapImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= isPrimitiveType(typeArgs[0]);
    var c = identity ? identityHashMapImplClass : linkedHashMapImplClass;
    return _emitType(new InterfaceType(c, typeArgs));
  }

  JS.Expression _emitSetImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= isPrimitiveType(typeArgs[0]);
    var c = identity ? identityHashSetImplClass : linkedHashSetImplClass;
    return _emitType(new InterfaceType(c, typeArgs));
  }

  bool _isObjectLiteral(Class c) {
    return _isJSNative(c) && findAnnotation(c, isJSAnonymousAnnotation) != null;
  }

  bool _isJSNative(NamedNode c) =>
      findAnnotation(c, isPublicJSAnnotation) != null;

  JS.Expression _emitObjectLiteral(Arguments node) {
    var args = _emitArgumentList(node);
    if (args.isEmpty) return js.call('{}');
    assert(args.single is JS.ObjectInitializer);
    return args.single;
  }

  @override
  visitNot(Not node) {
    // Logical negation, `!e`, is a boolean conversion context since it is
    // defined as `e ? false : true`.
    return _visitTest(node);
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    // The operands of logical boolean operators are subject to boolean
    // conversion.
    return _visitTest(node);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      _visitTest(node.condition),
      _visitExpression(node.then),
      _visitExpression(node.otherwise)
    ]);
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    var expressions = node.expressions;
    if (expressions.every((e) => e is StringLiteral)) {
      return new JS.Expression.binary(_visitExpressionList(expressions), '+');
    }

    var strings = <String>[];
    var interpolations = <JS.Expression>[];

    var expectString = true;
    for (var e in expressions) {
      if (e is StringLiteral) {
        // Escape the string as necessary for use in the eventual `` quotes.
        // TODO(jmesserly): this call adds quotes, and then we strip them off.
        var str = js.escapedString(e.value, '`').value;
        str = str.substring(1, str.length - 1);
        if (expectString) {
          strings.add(str);
        } else {
          var last = strings.length - 1;
          strings[last] = strings[last] + str;
        }
        expectString = false;
      } else {
        if (expectString) strings.add('');
        interpolations.add(_visitExpression(e));
        expectString = true;
      }
    }
    if (expectString) strings.add('');
    return new JS.TaggedTemplate(
        _callHelper('str'), new JS.TemplateString(strings, interpolations));
  }

  @override
  visitIsExpression(IsExpression node) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    JS.Expression result;
    var type = node.type;
    var lhs = _visitExpression(node.operand);
    var typeofName = _jsTypeofName(type);
    // Inline primitives other than int (which requires a Math.floor check).
    if (typeofName != null && type != coreTypes.intClass.rawType) {
      result = js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    } else {
      // Always go through a runtime helper, because implicit interfaces.
      var castType = _emitType(type);
      result = js.call('#.is(#)', [castType, lhs]);
    }
    return result;
  }

  String _jsTypeofName(DartType type) {
    var t = _typeRep.typeFor(type);
    if (t is JSNumber) return 'number';
    if (t is JSString) return 'string';
    if (t is JSBoolean) return 'boolean';
    return null;
  }

  @override
  visitAsExpression(AsExpression node) {
    Expression fromExpr = node.operand;
    var from = fromExpr.getStaticType(types);
    var to = node.type;
    var jsFrom = _visitExpression(fromExpr);

    // If the check was put here by static analysis to ensure soundness, we
    // can't skip it. For example, one could implement covariant generic caller
    // side checks like this:
    //
    //      typedef F<T>(T t);
    //      class C<T> {
    //        F<T> f;
    //        add(T t) {
    //          // required check `t as T`
    //        }
    //      }
    //      main() {
    //        C<Object> c = new C<int>()..f = (int x) => x.isEven;
    //        c.f('hi'); // required check `c.f as F<Object>`
    //        c.add('hi);
    //      }
    //
    // NOTE: due to implementation details, we do not currently reify the the
    // `C<T>.add` check in CoercionReifier, so it does not reach this point;
    // rather we check for it explicitly when emitting methods and fields.
    // However we do reify the `c.f` check, so we must not eliminate it.
    var isTypeError = node.isTypeError;
    if (!isTypeError && types.isSubtypeOf(from, to)) return jsFrom;

    // TODO(jmesserly): implicit function type instantiation for kernel?

    // All Dart number types map to a JS double.
    if (_typeRep.isNumber(from) && _typeRep.isNumber(to)) {
      // Make sure to check when converting to int.
      if (from != coreTypes.intClass.rawType &&
          to == coreTypes.intClass.rawType) {
        // TODO(jmesserly): fuse this with notNull check.
        // TODO(jmesserly): this does not correctly distinguish user casts from
        // required-for-soundness casts.
        return _callHelper('asInt(#)', jsFrom);
      }

      // A no-op in JavaScript.
      return jsFrom;
    }

    var code = isTypeError ? '#._check(#)' : '#.as(#)';
    return js.call(code, [_emitType(to), jsFrom]);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    JS.Expression emitSymbol() {
      // TODO(vsm): Handle qualified symbols correctly.
      var last = node.value.split('.').last;
      var name = js.escapedString(node.value, "'");
      if (last.startsWith('_')) {
        var nativeSymbol = _emitPrivateNameSymbol(_currentLibrary, last);
        return js.call('new #.new(#, #)', [
          _emitConstructorAccess(privateSymbolClass.rawType),
          name,
          nativeSymbol
        ]);
      } else {
        return js.call('#.new(#)',
            [_emitConstructorAccess(coreTypes.symbolClass.rawType), name]);
      }
    }

    return _emitConst(emitSymbol);
  }

  JS.Expression _cacheConst(JS.Expression expr()) {
    var savedTypeParams = _typeParamInConst;
    _typeParamInConst = [];

    var jsExpr = expr();

    bool usesTypeParams = _typeParamInConst.isNotEmpty;
    _typeParamInConst = savedTypeParams;

    // TODO(jmesserly): if it uses type params we can still hoist it up as far
    // as it will go, e.g. at the level the generic class is defined where type
    // params are available.
    if (_currentFunction == null || usesTypeParams) return jsExpr;

    var temp = new JS.TemporaryId('const');
    _moduleItems.add(js.statement('let #;', [temp]));
    return js.call('# || (# = #)', [temp, temp, jsExpr]);
  }

  JS.Expression _emitConst(JS.Expression expr()) =>
      _cacheConst(() => _callHelper('const(#)', expr()));

  @override
  visitTypeLiteral(TypeLiteral node) {
    var typeRep = _emitType(node.type);
    // If the type is a type literal expression in Dart code, wrap the raw
    // runtime type in a "Type" instance.
    return _isInForeignJS ? typeRep : _callHelper('wrapType(#)', typeRep);
  }

  @override
  visitThisExpression(ThisExpression node) => new JS.This();

  @override
  visitRethrow(Rethrow node) {
    return _callHelper('rethrow(#)', _emitVariableRef(_catchParameter));
  }

  @override
  visitThrow(Throw node) =>
      _callHelper('throw(#)', _visitExpression(node.expression));

  @override
  visitListLiteral(ListLiteral node) {
    var elementType = node.typeArgument;
    if (!node.isConst) {
      return _emitList(elementType, _visitExpressionList(node.expressions));
    }
    return _cacheConst(() =>
        _emitConstList(elementType, _visitExpressionList(node.expressions)));
  }

  JS.Expression _emitConstList(
      DartType elementType, List<JS.Expression> elements) {
    // dart.constList helper internally depends on _interceptors.JSArray.
    _declareBeforeUse(_jsArrayClass);
    return _callHelper('constList(#, #)',
        [new JS.ArrayInitializer(elements), _emitType(elementType)]);
  }

  JS.Expression _emitList(DartType itemType, List<JS.Expression> items) {
    var list = new JS.ArrayInitializer(items);

    // TODO(jmesserly): analyzer will usually infer `List<Object>` because
    // that is the least upper bound of the element types. So we rarely
    // generate a plain `List<dynamic>` anymore.
    if (itemType == const DynamicType()) return list;

    // Call `new JSArray<E>.of(list)`
    var arrayType = new InterfaceType(_jsArrayClass, [itemType]);
    return js.call('#.of(#)', [_emitType(arrayType), list]);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    emitEntries() {
      var entries = <JS.Expression>[];
      for (var e in node.entries) {
        entries.add(_visitExpression(e.key));
        entries.add(_visitExpression(e.value));
      }
      return new JS.ArrayInitializer(entries);
    }

    if (!node.isConst) {
      var mapType = _emitMapImplType(node.getStaticType(types));
      if (node.entries.isEmpty) {
        return js.call('new #.new()', [mapType]);
      }
      return js.call('new #.from(#)', [mapType, emitEntries()]);
    }
    return _cacheConst(() => _callHelper('constMap(#, #, #)',
        [_emitType(node.keyType), _emitType(node.valueType), emitEntries()]));
  }

  @override
  visitAwaitExpression(AwaitExpression node) =>
      new JS.Yield(_visitExpression(node.operand));

  @override
  visitFunctionExpression(FunctionExpression node) {
    var fn = _emitArrowFunction(node);
    if (!_reifyFunctionType(_currentFunction)) return fn;
    return _emitFunctionTagged(fn, node.getStaticType(types));
  }

  JS.ArrowFun _emitArrowFunction(FunctionExpression node) {
    JS.Fun fn = _emitFunction(node.function, null);
    return _toArrowFunction(fn);
  }

  JS.ArrowFun _toArrowFunction(JS.Fun f) {
    JS.Node body = f.body;

    // Simplify `=> { return e; }` to `=> e`
    if (body is JS.Block) {
      JS.Block block = body;
      if (block.statements.length == 1) {
        JS.Statement s = block.statements[0];
        if (s is JS.Return && s.value != null) body = s.value;
      }
    }

    // Convert `function(...) { ... }` to `(...) => ...`
    // This is for readability, but it also ensures correct `this` binding.
    return new JS.ArrowFun(f.params, body,
        typeParams: f.typeParams, returnType: f.returnType)
      ..sourceInformation = f.sourceInformation;
  }

  @override
  visitStringLiteral(StringLiteral node) => js.escapedString(node.value, '"');

  @override
  visitIntLiteral(IntLiteral node) => js.number(node.value);

  @override
  visitDoubleLiteral(DoubleLiteral node) => js.number(node.value);

  @override
  visitBoolLiteral(BoolLiteral node) => new JS.LiteralBool(node.value);

  @override
  visitNullLiteral(NullLiteral node) => new JS.LiteralNull();

  @override
  visitLet(Let node) {
    var v = node.variable;
    var init = _visitExpression(v.initializer);
    var body = _visitExpression(node.body);
    var temp = _tempVariables.remove(v);
    if (temp != null) {
      init = new JS.Assignment(temp, init);
      _letVariables.add(temp);
    }
    return new JS.Binary(',', init, body);
  }

  @override
  visitLoadLibrary(LoadLibrary node) => _callHelper('loadLibrary()');

  // TODO(jmesserly): DDC loads all libraries eagerly.
  // See
  // https://github.com/dart-lang/sdk/issues/27776
  // https://github.com/dart-lang/sdk/issues/27777
  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) => js.boolean(true);

  @override
  visitVectorCreation(VectorCreation node) => defaultExpression(node);

  @override
  visitVectorGet(VectorGet node) => defaultExpression(node);

  @override
  visitVectorSet(VectorSet node) => defaultExpression(node);

  @override
  visitVectorCopy(VectorCopy node) => defaultExpression(node);

  @override
  visitClosureCreation(ClosureCreation node) => defaultExpression(node);

  bool isCallableClass(Class c) {
    // See if we have a "call" with a statically known function type:
    //
    // - if it's a method, then it does because all methods do,
    // - if it's a getter, check the return type.
    //
    // Other cases like a getter returning dynamic/Object/Function will be
    // handled at runtime by the dynamic call mechanism. So we only
    // concern ourselves with statically known function types.
    //
    // We can ignore `noSuchMethod` because:
    // * `dynamic d; d();` without a declared `call` method is handled by dcall.
    // * for `class C implements Callable { noSuchMethod(i) { ... } }` we find
    //   the `call` method on the `Callable` interface.
    var member = hierarchy.getInterfaceMember(c, new Name("call"));
    return member != null && member.getterType is FunctionType;
  }

  bool _reifyFunctionType(FunctionNode f) {
    if (_currentLibrary.importUri.scheme != 'dart') return true;
    var parent = f.parent;

    // SDK libraries can skip reification if they request it.
    reifyFunctionTypes(Expression a) =>
        isBuiltinAnnotation(a, '_js_helper', 'ReifyFunctionTypes');
    while (parent != null) {
      var a = findAnnotation(parent, reifyFunctionTypes);
      if (a != null && a is ConstructorInvocation) {
        var args = a.arguments.positional;
        if (args.length == 1) {
          var arg = args[0];
          if (arg is BoolLiteral) return arg.value;
        }
      }
      parent = parent.parent;
    }
    return true;
  }

  /// Everything in Dart is an Object and supports the 4 members on Object,
  /// so we have to use a runtime helper to handle values such as `null` and
  /// native types.
  ///
  /// For example `null.toString()` is legal in Dart, so we need to generate
  /// that as `dart.toString(obj)`.
  bool _isObjectMemberCall(Expression target, String memberName) {
    return isObjectMember(memberName) && isNullable(target);
  }
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
  Iterable<String> segments;
  if (uri.scheme == 'package') {
    // Strip the package name.
    // TODO(vsm): This is not unique if an escaped '/'appears in a filename.
    // E.g., "foo/bar.dart" and "foo__bar.dart" would collide.
    segments = uri.pathSegments.skip(1);
  } else {
    // TODO(jmesserly): this is not unique typically.
    segments = [uri.pathSegments.last];
  }

  var qualifiedPath = segments.map((p) => p == '..' ? '' : p).join('__');
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

/// Return true if this is one of the methods/properties on all Dart Objects
/// (toString, hashCode, noSuchMethod, runtimeType).
///
/// Operator == is excluded, as it is handled as part of the equality binary
/// operator.
bool isObjectMember(String name) {
  // We could look these up on Object, but we have hard coded runtime helpers
  // so it's not really providing any benefit.
  switch (name) {
    case 'hashCode':
    case 'toString':
    case 'noSuchMethod':
    case 'runtimeType':
    case '==':
      return true;
  }
  return false;
}

bool _isObjectMethod(String name) =>
    name == 'toString' || name == 'noSuchMethod';
