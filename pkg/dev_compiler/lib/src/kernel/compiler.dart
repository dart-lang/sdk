// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:collection';
import 'dart:convert';
import 'dart:math' show max, min;

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' hide MapEntry;
import 'package:kernel/library_index.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/src/dart_type_equivalence.dart';
import 'package:source_span/source_span.dart' show SourceLocation;
import 'package:path/path.dart' as p;

import '../compiler/js_names.dart' as js_ast;
import '../compiler/js_utils.dart' as js_ast;
import '../compiler/module_builder.dart'
    show isSdkInternalRuntimeUri, libraryUriToJsIdentifier, pathToJSIdentifier;
import '../compiler/module_containers.dart' show ModuleItemContainer;
import '../compiler/shared_command.dart' show SharedCompilerOptions;
import '../compiler/shared_compiler.dart';
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;
import '../js_ast/source_map_printer.dart' show NodeEnd, NodeSpan, HoverComment;
import 'constants.dart';
import 'js_interop.dart';
import 'js_typerep.dart';
import 'kernel_helpers.dart';
import 'native_types.dart';
import 'nullable_inference.dart';
import 'property_model.dart';
import 'type_table.dart';

class ProgramCompiler extends ComputeOnceConstantVisitor<js_ast.Expression>
    with SharedCompiler<Library, Class, InterfaceType, FunctionNode>
    implements
        StatementVisitor<js_ast.Statement>,
        ExpressionVisitor<js_ast.Expression>,
        DartTypeVisitor<js_ast.Expression> {
  final SharedCompilerOptions _options;

  /// Maps a library URI import, that is not in [_libraries], to the
  /// corresponding Kernel summary module we imported it with.
  ///
  /// An entry must exist for every reachable component.
  final Map<Library, Component> _importToSummary;

  /// Maps a Kernel summary to the JS import name for the module.
  ///
  /// An entry must exist for every reachable component.
  final Map<Component, String> _summaryToModule;

  /// The variable for the current catch clause
  VariableDeclaration _rethrowParameter;

  /// In an async* function, this represents the stream controller parameter.
  js_ast.TemporaryId _asyncStarController;

  Set<Class> _pendingClasses;

  /// Temporary variables mapped to their corresponding JavaScript variable.
  final _tempVariables = <VariableDeclaration, js_ast.TemporaryId>{};

  /// Let variables collected for the given function.
  List<js_ast.TemporaryId> _letVariables;

  final _constTable = js_ast.TemporaryId('CT');

  /// Constant getters used to populate the constant table.
  final _constLazyAccessors = <js_ast.Method>[];

  /// Container for holding the results of lazily-evaluated constants.
  final _constTableCache = ModuleItemContainer<String>.asArray('C');

  /// Tracks the index in [moduleItems] where the const table must be inserted.
  /// Required for SDK builds due to internal circular dependencies.
  /// E.g., dart.constList depends on JSArray.
  int _constTableInsertionIndex = 0;

  /// The class that is emitting its base class or mixin references, otherwise
  /// null.
  ///
  /// This is not used when inside the class method bodies, or for other type
  /// information such as `implements`.
  Class _classEmittingExtends;

  /// The class that is emitting its signature information, otherwise null.
  Class _classEmittingSignatures;

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentClass == _classEmittingTopLevel
  ///
  Class _currentClass;

  /// The current source file URI for emitting in the source map.
  Uri _currentUri;

  Component _component;

  Library _currentLibrary;

  FunctionNode _currentFunction;

  /// Whether the current function needs to insert parameter checks.
  ///
  /// Used to avoid adding checks for formal parameters inside a synthetic
  /// function that is generated during expression compilation in the
  /// incremental compiler, since those checks would already be done in
  /// the original code.
  bool _checkParameters = true;

  /// Whether we are currently generating code for the body of a `JS()` call.
  bool _isInForeignJS = false;

  /// Table of named and possibly hoisted types.
  TypeTable _typeTable;

  /// The global extension type table.
  // TODO(jmesserly): rename to `_nativeTypes`
  final NativeTypeSet _extensionTypes;

  final CoreTypes _coreTypes;

  final TypeEnvironment _types;

  final StatefulStaticTypeContext _staticTypeContext;

  final ClassHierarchy _hierarchy;

  /// Information about virtual and overridden fields/getters/setters in the
  /// class we're currently compiling, or `null` if we aren't compiling a class.
  ClassPropertyModel _classProperties;

  /// Information about virtual fields for all libraries in the current build
  /// unit.
  final _virtualFields = VirtualFieldModel();

  final JSTypeRep _typeRep;

  bool _superAllowed = true;

  final _superHelpers = <String, js_ast.Method>{};

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
  final _effectiveTargets = HashMap<LabeledStatement, Statement>.identity();

  /// A map from effective targets to their label names.
  ///
  /// If the target needs to be labeled when compiled to JS, because it was
  /// targeted by a break or continue with a label, then this map contains the
  /// label name that was assigned to it.
  final _labelNames = HashMap<Statement, String>.identity();

  /// Indicates that the current context exists within a switch statement that
  /// uses at least one continue statement with a target label.
  ///
  /// JS forbids labels at case statement boundaries, so these switch
  /// statements must be generated less directly.
  /// Updated from the method 'visitSwitchStatement'.
  bool _inLabeledContinueSwitch = false;

  /// A map from switch statements to their state information.
  /// State information includes the names of the switch statement's implicit
  /// label name and implicit state variable name.
  ///
  /// Entries are only created for switch statements that contain labeled
  /// continue statements and are used to simulate "jumping" to case statements.
  /// State variables hold the next constant case expression, while labels act
  /// as targets for continue and break.
  final _switchLabelStates = HashMap<Statement, _SwitchLabelState>();

  /// Maps Kernel constants to their JS aliases.
  final constAliasCache = HashMap<Constant, js_ast.Expression>();

  /// Maps uri strings in asserts and elsewhere to hoisted identifiers.
  final _uriContainer = ModuleItemContainer<String>.asArray('I');

  final Class _jsArrayClass;
  final Class _privateSymbolClass;
  final Class _linkedHashMapImplClass;
  final Class _identityHashMapImplClass;
  final Class _linkedHashSetClass;
  final Class _linkedHashSetImplClass;
  final Class _identityHashSetImplClass;
  final Class _syncIterableClass;
  final Class _asyncStarImplClass;

  /// The dart:async `StreamIterator<T>` type.
  final Class _asyncStreamIteratorClass;

  final Procedure _assertInteropMethod;

  final DevCompilerConstants _constants;

  final NullableInference _nullableInference;

  factory ProgramCompiler(
      Component component,
      ClassHierarchy hierarchy,
      SharedCompilerOptions options,
      Map<Library, Component> importToSummary,
      Map<Component, String> summaryToModule,
      {CoreTypes coreTypes}) {
    coreTypes ??= CoreTypes(component);
    var types = TypeEnvironment(coreTypes, hierarchy);
    var constants = DevCompilerConstants();
    var nativeTypes = NativeTypeSet(coreTypes, constants);
    var jsTypeRep = JSTypeRep(types, hierarchy);
    var staticTypeContext = StatefulStaticTypeContext.stacked(types);
    return ProgramCompiler._(
      coreTypes,
      coreTypes.index,
      nativeTypes,
      constants,
      types,
      hierarchy,
      jsTypeRep,
      NullableInference(jsTypeRep, staticTypeContext, options: options),
      staticTypeContext,
      options,
      importToSummary,
      summaryToModule,
    );
  }

  ProgramCompiler._(
      this._coreTypes,
      LibraryIndex sdk,
      this._extensionTypes,
      this._constants,
      this._types,
      this._hierarchy,
      this._typeRep,
      this._nullableInference,
      this._staticTypeContext,
      this._options,
      this._importToSummary,
      this._summaryToModule)
      : _jsArrayClass = sdk.getClass('dart:_interceptors', 'JSArray'),
        _asyncStreamIteratorClass =
            sdk.getClass('dart:async', 'StreamIterator'),
        _privateSymbolClass = sdk.getClass('dart:_js_helper', 'PrivateSymbol'),
        _linkedHashMapImplClass = sdk.getClass('dart:_js_helper', 'LinkedMap'),
        _identityHashMapImplClass =
            sdk.getClass('dart:_js_helper', 'IdentityMap'),
        _linkedHashSetClass = sdk.getClass('dart:collection', 'LinkedHashSet'),
        _linkedHashSetImplClass = sdk.getClass('dart:collection', '_HashSet'),
        _identityHashSetImplClass =
            sdk.getClass('dart:collection', '_IdentityHashSet'),
        _syncIterableClass = sdk.getClass('dart:_js_helper', 'SyncIterable'),
        _asyncStarImplClass = sdk.getClass('dart:async', '_AsyncStarImpl'),
        _assertInteropMethod = sdk.getTopLevelMember(
            'dart:_runtime', 'assertInterop') as Procedure;

  @override
  Uri get currentLibraryUri => _currentLibrary.importUri;

  @override
  Library get currentLibrary => _currentLibrary;

  @override
  Library get coreLibrary => _coreTypes.coreLibrary;

  @override
  FunctionNode get currentFunction => _currentFunction;

  @override
  InterfaceType get privateSymbolType =>
      _coreTypes.legacyRawType(_privateSymbolClass);

  @override
  InterfaceType get internalSymbolType =>
      _coreTypes.legacyRawType(_coreTypes.internalSymbolClass);

  js_ast.Program emitModule(Component component) {
    if (moduleItems.isNotEmpty) {
      throw StateError('Can only call emitModule once.');
    }
    _component = component;

    var libraries = component.libraries;

    // Initialize library variables.
    isBuildingSdk = libraries.any(isSdkInternalRuntime);

    // For runtime performance reasons, we only containerize SDK symbols in web
    // libraries. Otherwise, we use a 600-member cutoff before a module is
    // containerized. This is somewhat arbitrary but works promisingly for the
    // SDK and Flutter Web.
    if (!isBuildingSdk) {
      // The number of DDC top-level symbols scales with the number of
      // non-static class members across an entire module.
      var uniqueNames = HashSet<String>();
      libraries.forEach((Library l) {
        l.classes.forEach((Class c) {
          c.members.forEach((m) {
            var isStatic =
                m is Field ? m.isStatic : (m is Procedure ? m.isStatic : false);
            if (isStatic) return;
            var name = js_ast.toJSIdentifier(
                m.name.text.replaceAll(js_ast.invalidCharInIdentifier, '_'));
            uniqueNames.add(name);
          });
        });
      });
      containerizeSymbols = uniqueNames.length > 600;
    }

    var items = startModule(libraries);
    _nullableInference.allowNotNullDeclarations = isBuildingSdk;
    _typeTable = TypeTable(runtimeModule);

    // Collect all class/type Element -> Node mappings
    // in case we need to forward declare any classes.
    _pendingClasses = HashSet.identity();
    for (var l in libraries) {
      _pendingClasses.addAll(l.classes);
    }

    // Insert a circular reference so neither the constant table or its cache
    // are optimized away by V8. Required for expression evaluation.
    var constTableDeclaration =
        js.statement('const # = Object.create({# : () => (#, #)});', [
      _constTable,
      js_ast.LiteralString('_'),
      _constTableCache.containerId,
      _constTable
    ]);
    moduleItems.add(constTableDeclaration);

    // Record a safe index after the declaration of type generators and
    // top-level symbols but before the declaration of any functions.
    // Various preliminary data structures must be inserted here prior before
    // referenced by the rest of the module.
    var safeDeclarationIndex = moduleItems.length;
    _constTableInsertionIndex = safeDeclarationIndex;

    // Add implicit dart:core dependency so it is first.
    emitLibraryName(_coreTypes.coreLibrary);

    // Visit each library and emit its code.
    //
    // NOTE: classes are not necessarily emitted in this order.
    // Order will be changed as needed so the resulting code can execute.
    // This is done by forward declaring items.
    libraries.forEach(_emitLibrary);

    // Emit hoisted assert strings
    moduleItems.insertAll(safeDeclarationIndex, _uriContainer.emit());

    moduleItems.insertAll(safeDeclarationIndex, _constTableCache.emit());

    if (_constLazyAccessors.isNotEmpty) {
      var constTableBody = runtimeStatement(
          'defineLazy(#, { # }, false)', [_constTable, _constLazyAccessors]);
      moduleItems.insert(_constTableInsertionIndex, constTableBody);
      _constLazyAccessors.clear();
    }

    moduleItems.addAll(afterClassDefItems);
    afterClassDefItems.clear();

    // Visit directives (for exports)
    libraries.forEach(_emitExports);

    // Declare imports and extension symbols
    emitImportsAndExtensionSymbols(items);

    // Insert a check that runs when loading this module to verify that the null
    // safety mode it was compiled in matches the mode used when compiling the
    // dart sdk module.
    //
    // This serves as a sanity check at runtime that we don't have an
    // infrastructure issue that loaded js files compiled with different modes
    // into the same application.
    js_ast.LiteralBool soundNullSafety;
    switch (component.mode) {
      case NonNullableByDefaultCompiledMode.Strong:
        soundNullSafety = js_ast.LiteralBool(true);
        break;
      case NonNullableByDefaultCompiledMode.Weak:
        soundNullSafety = js_ast.LiteralBool(false);
        break;
      default:
        throw StateError('Unsupported Null Safety mode ${component.mode}, '
            'in ${component?.location?.file}.');
    }
    if (!isBuildingSdk) {
      items.add(
          runtimeStatement('_checkModuleNullSafetyMode(#)', [soundNullSafety]));
    }

    // Emit the hoisted type table cache variables
    items.addAll(_typeTable.dischargeBoundTypes());

    return finishModule(items, _options.moduleName);
  }

  @override
  String jsLibraryName(Library library) {
    return libraryUriToJsIdentifier(library.importUri);
  }

  @override
  String jsLibraryAlias(Library library) {
    var uri = library.importUri.normalizePath();
    if (uri.scheme == 'dart') return null;

    Iterable<String> segments;
    if (uri.scheme == 'package') {
      // Strip the package name.
      segments = uri.pathSegments.skip(1);
    } else {
      segments = uri.pathSegments;
    }

    var qualifiedPath =
        pathToJSIdentifier(p.withoutExtension(segments.join('/')));
    return qualifiedPath == jsLibraryName(library) ? null : qualifiedPath;
  }

  @override
  String jsLibraryDebuggerName(Library library) => '${library.importUri}';

  @override
  Iterable<String> jsPartDebuggerNames(Library library) =>
      library.parts.map((part) => part.partUri);

  @override
  bool isSdkInternalRuntime(Library l) {
    return isSdkInternalRuntimeUri(l.importUri);
  }

  @override
  String libraryToModule(Library library) {
    if (library.importUri.scheme == 'dart') {
      // TODO(jmesserly): we need to split out HTML.
      return js_ast.dartSdkModule;
    }
    var summary = _importToSummary[library];
    var moduleName = _summaryToModule[summary];
    if (moduleName == null) {
      throw StateError('Could not find module name for library "$library" '
          'from component "$summary".');
    }
    return moduleName;
  }

  void _emitLibrary(Library library) {
    // NOTE: this method isn't the right place to initialize per-library state.
    // Classes can be visited out of order, so this is only to catch things that
    // haven't been emitted yet.
    //
    // See _emitClass.
    assert(_currentLibrary == null);
    _currentLibrary = library;
    _staticTypeContext.enterLibrary(_currentLibrary);

    if (isBuildingSdk) {
      containerizeSymbols = _isWebLibrary(library.importUri);
    }

    if (isSdkInternalRuntime(library)) {
      // `dart:_runtime` uses a different order for bootstrapping.
      //
      // Functions are first because we use them to associate type info
      // (such as `dart.fn`), then classes/typedefs, then fields
      // (which instantiate classes).
      //
      // For other libraries, we start with classes/types, because functions
      // often use classes/types from the library in their signature.
      //
      // TODO(jmesserly): we can merge these once we change signatures to be
      // lazily associated at the tear-off point for top-level functions.
      _emitLibraryProcedures(library);
      _emitTopLevelFields(library.fields);
      library.classes.forEach(_emitClass);
    } else {
      library.classes.forEach(_emitClass);
      _emitLibraryProcedures(library);
      _emitTopLevelFields(library.fields);
    }

    _staticTypeContext.leaveLibrary(_currentLibrary);
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

    var node = export.node;
    if (node is Procedure && node.name.text == 'main') {
      // Don't allow redefining names from this library.
      var name = _emitTopLevelName(export.node);
      moduleItems.add(js.statement(
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
    var savedUri = _currentUri;
    _currentClass = c;
    _currentLibrary = c.enclosingLibrary;
    _currentUri = c.fileUri;

    moduleItems.add(_emitClassDeclaration(c));

    // The const table depends on dart.defineLazy, so emit it after the SDK.
    if (isSdkInternalRuntime(_currentLibrary)) {
      _constTableInsertionIndex = moduleItems.length;
    }

    _currentClass = savedClass;
    _currentLibrary = savedLibrary;
    _currentUri = savedUri;
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
    if (c != null && _emittingClassExtends) {
      _emitClass(c);
    }
  }

  static js_ast.Identifier _emitIdentifier(String name) =>
      js_ast.Identifier(js_ast.toJSIdentifier(name));

  static js_ast.TemporaryId _emitTemporaryId(String name) =>
      js_ast.TemporaryId(js_ast.toJSIdentifier(name));

  js_ast.Statement _emitClassDeclaration(Class c) {
    // Mixins are unrolled in _defineClass.
    if (c.isAnonymousMixin) return null;

    // If this class is annotated with `@JS`, then there is nothing to emit.
    if (findAnnotation(c, isPublicJSAnnotation) != null) return null;

    // Generic classes will be defined inside a function that closes over the
    // type parameter. So we can use their local variable name directly.
    //
    // TODO(jmesserly): the special case for JSArray is to support its special
    // type-tagging factory constructors. Those will go away once we fix:
    // https://github.com/dart-lang/sdk/issues/31003
    var className = c.typeParameters.isNotEmpty
        ? (c == _jsArrayClass
            ? _emitIdentifier(c.name)
            : _emitTemporaryId(getLocalClassName(c)))
        : _emitTopLevelName(c);

    var savedClassProperties = _classProperties;
    _classProperties =
        ClassPropertyModel.build(_types, _extensionTypes, _virtualFields, c);

    var body = <js_ast.Statement>[];

    // ClassPropertyModel.build introduces symbols for virtual field accessors.
    _classProperties.virtualFields.forEach((field, virtualField) {
      // TODO(vsm): Clean up this logic.
      //
      // Typically, [emitClassPrivateNameSymbol] creates a new symbol.  If it
      // is called multiple times, that symbol is cached.  If the former,
      // assign directly to [virtualField].  If the latter, copy the old
      // variable to [virtualField].
      var symbol = emitClassPrivateNameSymbol(c.enclosingLibrary,
          getLocalClassName(c), field.name.text, virtualField);
      if (symbol != virtualField) {
        addSymbol(virtualField, getSymbolValue(symbol));
        if (!containerizeSymbols) {
          body.add(js.statement('const # = #;', [virtualField, symbol]));
        }
      }
    });

    var jsCtors = _defineConstructors(c, className);
    var jsMethods = _emitClassMethods(c);

    _emitSuperHelperSymbols(body);
    // Deferred supertypes must be evaluated lazily while emitting classes to
    // prevent evaluating a JS expression for a deferred type from influencing
    // class declaration order (such as when calling 'emitDeferredType').
    var deferredSupertypes = <js_ast.Statement Function()>[];

    // Emit the class, e.g. `core.Object = class Object { ... }`
    _defineClass(c, className, jsMethods, body, deferredSupertypes);
    body.addAll(jsCtors);

    // Emit things that come after the ES6 `class ... { ... }`.
    var jsPeerNames = _extensionTypes.getNativePeers(c);
    if (jsPeerNames.length == 1 && c.typeParameters.isNotEmpty) {
      // Special handling for JSArray<E>
      body.add(runtimeStatement('setExtensionBaseClass(#, #.global.#)',
          [className, runtimeModule, jsPeerNames[0]]));
    }

    var finishGenericTypeTest = _emitClassTypeTests(c, className, body);

    // Attach caches on all canonicalized types.
    body.add(runtimeStatement('addTypeCaches(#)', [className]));

    _emitClassSignature(c, className, body);
    _initExtensionSymbols(c);
    if (!c.isMixinDeclaration) {
      _defineExtensionMembers(className, body);
    }

    var classDef = js_ast.Statement.from(body);
    var typeFormals = c.typeParameters;
    var evaluatedDeferredSupertypes =
        deferredSupertypes.map<js_ast.Statement>((f) => f()).toList();
    if (typeFormals.isNotEmpty) {
      classDef = _defineClassTypeArguments(
          c, typeFormals, classDef, className, evaluatedDeferredSupertypes);
    } else {
      afterClassDefItems.addAll(evaluatedDeferredSupertypes);
    }

    body = [classDef];
    _emitStaticFields(c, body);
    if (finishGenericTypeTest != null) body.add(finishGenericTypeTest);
    for (var peer in jsPeerNames) {
      _registerExtensionType(c, peer, body);
    }

    _classProperties = savedClassProperties;
    return js_ast.Statement.from(body);
  }

  /// Wraps a possibly generic class in its type arguments.
  js_ast.Statement _defineClassTypeArguments(
      NamedNode c, List<TypeParameter> formals, js_ast.Statement body,
      [js_ast.Expression className, List<js_ast.Statement> deferredBaseClass]) {
    assert(formals.isNotEmpty);
    var name = getTopLevelName(c);
    var jsFormals = _emitTypeFormals(formals);

    // Checks for explicitly set variance to avoid emitting legacy covariance
    // Variance annotations are not necessary when variance experiment flag is
    // not enabled or when no type parameters have explicitly defined
    // variances.
    var hasOnlyLegacyCovariance = formals.every((t) => t.isLegacyCovariant);
    if (!hasOnlyLegacyCovariance) {
      var varianceList = formals.map(_emitVariance);
      var varianceStatement = runtimeStatement(
          'setGenericArgVariances(#, [#])', [className, varianceList]);
      body = js_ast.Statement.from([body, varianceStatement]);
    }

    var typeConstructor = js.call('(#) => { #; #; return #; }', [
      jsFormals,
      _typeTable.dischargeFreeTypes(formals),
      body,
      className ?? _emitIdentifier(name)
    ]);

    var genericArgs = [
      typeConstructor,
      if (deferredBaseClass != null && deferredBaseClass.isNotEmpty)
        js.call('(#) => { #; }', [jsFormals, deferredBaseClass]),
    ];

    // FutureOr types have a runtime normalization step that will call
    // generic() as needed.
    var genericCall = c == _coreTypes.deprecatedFutureOrClass
        ? runtimeCall('normalizeFutureOr(#)', [genericArgs])
        : runtimeCall('generic(#)', [genericArgs]);

    var genericName = _emitTopLevelNameNoInterop(c, suffix: '\$');
    return js.statement('{ # = #; # = #(); }',
        [genericName, genericCall, _emitTopLevelName(c), genericName]);
  }

  js_ast.Expression _emitVariance(TypeParameter typeParameter) {
    switch (typeParameter.variance) {
      case Variance.contravariant:
        return runtimeCall('Variance.contravariant');
      case Variance.invariant:
        return runtimeCall('Variance.invariant');
      case Variance.unrelated:
        return runtimeCall('Variance.unrelated');
      case Variance.covariant:
      default:
        return runtimeCall('Variance.covariant');
    }
  }

  js_ast.Statement _emitClassStatement(Class c, js_ast.Expression className,
      js_ast.Expression heritage, List<js_ast.Method> methods) {
    if (c.typeParameters.isNotEmpty) {
      return js_ast.ClassExpression(
              className as js_ast.Identifier, heritage, methods)
          .toStatement();
    }
    var classExpr = js_ast.ClassExpression(
        _emitTemporaryId(getLocalClassName(c)), heritage, methods);
    return js.statement('# = #;', [className, classExpr]);
  }

  /// Like [_emitClassStatement] but emits a Dart 2.1 mixin represented by
  /// [c].
  ///
  /// Mixins work similar to normal classes, but their instance methods close
  /// over the actual superclass. Given a Dart class like:
  ///
  ///     mixin M on C {
  ///       foo() => super.foo() + 42;
  ///     }
  ///
  /// We generate a JS class like this:
  ///
  ///     lib.M = class M extends core.Object {}
  ///     lib.M[dart.mixinOn] = (C) => class M extends C {
  ///       foo() {
  ///         return super.foo() + 42;
  ///       }
  ///     };
  ///
  /// The special `dart.mixinOn` symbolized property is used by the runtime
  /// helper `dart.applyMixin`. The helper calls the function with the actual
  /// base class, and then copies the resulting members to the destination
  /// class.
  ///
  /// In the long run we may be able to improve this so we do not have the
  /// unnecessary class, but for now, this lets us get the right semantics with
  /// minimal compiler and runtime changes.
  void _emitMixinStatement(
      Class c,
      js_ast.Expression className,
      js_ast.Expression heritage,
      List<js_ast.Method> methods,
      List<js_ast.Statement> body) {
    var staticMethods = methods.where((m) => m.isStatic).toList();
    var instanceMethods = methods.where((m) => !m.isStatic).toList();

    body.add(_emitClassStatement(c, className, heritage, staticMethods));
    var superclassId = _emitTemporaryId(getLocalClassName(c.superclass));
    var classId = className is js_ast.Identifier
        ? className
        : _emitTemporaryId(getLocalClassName(c));

    var mixinMemberClass =
        js_ast.ClassExpression(classId, superclassId, instanceMethods);

    js_ast.Node arrowFnBody = mixinMemberClass;
    var extensionInit = <js_ast.Statement>[];
    _defineExtensionMembers(classId, extensionInit);
    if (extensionInit.isNotEmpty) {
      extensionInit.insert(0, mixinMemberClass.toStatement());
      extensionInit.add(classId.toReturn());
      arrowFnBody = js_ast.Block(extensionInit);
    }

    body.add(js.statement('#[#.mixinOn] = #', [
      className,
      runtimeModule,
      js_ast.ArrowFun([superclassId], arrowFnBody)
    ]));
  }

  void _defineClass(
      Class c,
      js_ast.Expression className,
      List<js_ast.Method> methods,
      List<js_ast.Statement> body,
      List<js_ast.Statement Function()> deferredSupertypes) {
    if (c == _coreTypes.objectClass) {
      body.add(_emitClassStatement(c, className, null, methods));
      return;
    }

    js_ast.Expression emitDeferredType(DartType t) {
      assert(isKnownDartTypeImplementor(t));
      if (t is InterfaceType) {
        _declareBeforeUse(t.classNode);
        if (t.typeArguments.isNotEmpty) {
          return _emitGenericClassType(
              t, t.typeArguments.map(emitDeferredType));
        }
        return _emitInterfaceType(t, emitNullability: false);
      } else if (t is FutureOrType) {
        _declareBeforeUse(_coreTypes.deprecatedFutureOrClass);
        return _emitFutureOrTypeWithArgument(emitDeferredType(t.typeArgument));
      } else if (t is TypeParameterType) {
        return _emitTypeParameterType(t, emitNullability: false);
      }
      return _emitType(t);
    }

    bool shouldDefer(InterfaceType t) {
      var visited = <DartType>{};
      bool defer(DartType t) {
        assert(isKnownDartTypeImplementor(t));
        if (t is InterfaceType) {
          var tc = t.classNode;
          if (c == tc) return true;
          if (tc == _coreTypes.objectClass || !visited.add(t)) return false;
          if (t.typeArguments.any(defer)) return true;
          var mixin = tc.mixedInType;
          return mixin != null && defer(mixin.asInterfaceType) ||
              defer(tc.supertype.asInterfaceType);
        }
        if (t is FutureOrType) {
          if (c == _coreTypes.deprecatedFutureOrClass) return true;
          if (!visited.add(t)) return false;
          if (defer(t.typeArgument)) return true;
          return defer(
              _coreTypes.deprecatedFutureOrClass.supertype.asInterfaceType);
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

    js_ast.Expression emitClassRef(InterfaceType t) {
      // TODO(jmesserly): investigate this. It seems like `lazyJSType` is
      // invalid for use in an `extends` clause, hence this workaround.
      return _emitJSInterop(t.classNode) ??
          _emitInterfaceType(t, emitNullability: false);
    }

    js_ast.Expression getBaseClass(int count) {
      var base = emitDeferredType(
          c.getThisType(_coreTypes, c.enclosingLibrary.nonNullable));
      while (--count >= 0) {
        base = js.call('#.__proto__', [base]);
      }
      return base;
    }

    /// Returns the "actual" superclass of [c].
    ///
    /// Walks up the superclass chain looking for the first actual class
    /// skipping any synthetic classes inserted by the CFE.
    Class superClassAsWritten(Class c) {
      var superclass = c.superclass;
      while (superclass.isAnonymousMixin) {
        superclass = superclass.superclass;
      }
      return superclass;
    }

    // Find the real (user declared) superclass and the list of mixins.
    // We'll use this to unroll the intermediate classes.
    //
    // TODO(jmesserly): consider using Kernel's mixin unrolling.
    var superclass = superClassAsWritten(c);
    var supertype = identical(c.superclass, superclass)
        ? c.supertype.asInterfaceType
        : _hierarchy.getClassAsInstanceOf(c, superclass).asInterfaceType;
    // All mixins (real and anonymous) classes applied to c.
    var mixinApplications = [
      if (c.mixedInClass != null) c.mixedInClass,
      for (var sc = c.superclass;
          sc.isAnonymousMixin && sc.mixedInClass != null;
          sc = sc.superclass)
        sc,
    ].reversed.toList();

    var hasUnnamedSuper = _hasUnnamedInheritedConstructor(superclass);

    void emitMixinConstructors(
        js_ast.Expression className, InterfaceType mixin) {
      js_ast.Statement mixinCtor;
      if (_hasUnnamedConstructor(mixin.classNode)) {
        mixinCtor = js.statement('#.#.call(this);', [
          emitClassRef(mixin),
          _usesMixinNew(mixin.classNode)
              ? runtimeCall('mixinNew')
              : _constructorName('')
        ]);
      }

      for (var ctor in superclass.constructors) {
        var savedUri = _currentUri;
        _currentUri = ctor.enclosingClass.fileUri;
        var jsParams = _emitParameters(ctor.function, isForwarding: true);
        _currentUri = savedUri;
        var name = ctor.name.text;
        var ctorBody = [
          if (mixinCtor != null) mixinCtor,
          if (name != '' || hasUnnamedSuper)
            _emitSuperConstructorCall(className, name, jsParams),
        ];
        body.add(_addConstructorToClass(
            c, className, name, js_ast.Fun(jsParams, js_ast.Block(ctorBody))));
      }
    }

    var savedTopLevelClass = _classEmittingExtends;
    _classEmittingExtends = c;

    // Unroll mixins.
    if (shouldDefer(supertype)) {
      var originalSupertype = supertype;
      deferredSupertypes.add(() => runtimeStatement('setBaseClass(#, #)', [
            getBaseClass(isMixinAliasClass(c) ? 0 : mixinApplications.length),
            emitDeferredType(originalSupertype),
          ]));
      // Refers to 'supertype' without type parameters. We remove these from
      // the 'extends' clause for generics for cyclic dependencies and append
      // them later with 'setBaseClass'.
      supertype =
          _coreTypes.rawType(supertype.classNode, _currentLibrary.nonNullable);
    }
    var baseClass = emitClassRef(supertype);

    if (isMixinAliasClass(c)) {
      // Given `class C = Object with M [implements I1, I2 ...];`
      // The resulting class C should work as a mixin.
      //
      // TODO(jmesserly): is there any way to merge this with the other mixin
      // code paths, or will these always need special handling?
      body.add(_emitClassStatement(c, className, baseClass, []));

      var m = c.mixedInType.asInterfaceType;
      var deferMixin = shouldDefer(m);
      var mixinClass = deferMixin ? emitDeferredType(m) : emitClassRef(m);
      var classExpr = deferMixin ? getBaseClass(0) : className;

      var mixinApplication =
          runtimeStatement('applyMixin(#, #)', [classExpr, mixinClass]);
      if (deferMixin) {
        deferredSupertypes.add(() => mixinApplication);
      } else {
        body.add(mixinApplication);
      }

      if (methods.isNotEmpty) {
        // However we may need to add some methods to this class that call
        // `super` such as covariance checks.
        //
        // We do this with the following pattern:
        //
        //     applyMixin(C, class C$ extends M { <methods>  });
        var mixinApplicationWithMethods = runtimeStatement('applyMixin(#, #)', [
          classExpr,
          js_ast.ClassExpression(
              _emitTemporaryId(getLocalClassName(c)), mixinClass, methods)
        ]);
        if (deferMixin) {
          deferredSupertypes.add(() => mixinApplicationWithMethods);
        } else {
          body.add(mixinApplicationWithMethods);
        }
      }

      emitMixinConstructors(className, m);

      _classEmittingExtends = savedTopLevelClass;
      return;
    }

    // TODO(jmesserly): we need to unroll kernel mixins because the synthetic
    // classes lack required synthetic members, such as constructors.
    //
    // Also, we need to generate one extra level of nesting for alias classes.
    for (var i = 0; i < mixinApplications.length; i++) {
      var m = mixinApplications[i];
      var mixinClass = m.isAnonymousMixin ? m.mixedInClass : m;
      var mixinType =
          _hierarchy.getClassAsInstanceOf(c, mixinClass).asInterfaceType;
      var mixinName =
          getLocalClassName(superclass) + '_' + getLocalClassName(mixinClass);
      var mixinId = _emitTemporaryId(mixinName + '\$');
      // Collect all forwarding stubs from anonymous mixins classes. These will
      // contain covariant parameter checks that need to be applied.
      var forwardingMethodStubs = [
        for (var procedure in m.procedures)
          if (procedure.isForwardingStub && !procedure.isAbstract)
            _emitMethodDeclaration(procedure)
      ];

      // Bind the mixin class to a name to workaround a V8 bug with es6 classes
      // and anonymous function names.
      // TODO(leafp:) Eliminate this once the bug is fixed:
      // https://bugs.chromium.org/p/v8/issues/detail?id=7069
      body.add(js.statement('const # = #', [
        mixinId,
        js_ast.ClassExpression(
            _emitTemporaryId(mixinName), baseClass, forwardingMethodStubs)
      ]));

      emitMixinConstructors(mixinId, mixinType);
      hasUnnamedSuper = hasUnnamedSuper || _hasUnnamedConstructor(mixinClass);

      if (shouldDefer(mixinType)) {
        deferredSupertypes.add(() => runtimeStatement('applyMixin(#, #)', [
              getBaseClass(mixinApplications.length - i),
              emitDeferredType(mixinType)
            ]));
      } else {
        body.add(runtimeStatement(
            'applyMixin(#, #)', [mixinId, emitClassRef(mixinType)]));
      }

      baseClass = mixinId;
    }

    if (c.isMixinDeclaration) {
      _emitMixinStatement(c, className, baseClass, methods, body);
    } else {
      body.add(_emitClassStatement(c, className, baseClass, methods));
    }

    _classEmittingExtends = savedTopLevelClass;
  }

  /// Defines all constructors for this class as ES5 constructors.
  List<js_ast.Statement> _defineConstructors(
      Class c, js_ast.Expression className) {
    var body = <js_ast.Statement>[];
    if (c.isAnonymousMixin || isMixinAliasClass(c)) {
      // We already handled this when we defined the class.
      return body;
    }

    void addConstructor(String name, js_ast.Expression jsCtor) {
      body.add(_addConstructorToClass(c, className, name, jsCtor));
    }

    var fields = c.fields;
    for (var ctor in c.constructors) {
      if (ctor.isExternal) continue;
      addConstructor(ctor.name.text, _emitConstructor(ctor, fields, className));
    }

    // If classElement has only factory constructors, and it can be mixed in,
    // then we need to emit a special hidden default constructor for use by
    // mixins.
    if (_usesMixinNew(c)) {
      body.add(
          js.statement('(#[#] = function() { # }).prototype = #.prototype;', [
        className,
        runtimeCall('mixinNew'),
        [_initializeFields(fields)],
        className
      ]));
    }

    return body;
  }

  js_ast.Statement _emitClassTypeTests(
      Class c, js_ast.Expression className, List<js_ast.Statement> body) {
    js_ast.Expression getInterfaceSymbol(Class interface) {
      var library = interface.enclosingLibrary;
      if (library == _coreTypes.coreLibrary ||
          library == _coreTypes.asyncLibrary) {
        switch (interface.name) {
          case 'List':
          case 'Map':
          case 'Iterable':
          case 'Future':
          case 'Stream':
          case 'StreamSubscription':
            return runtimeCall('is' + interface.name);
        }
      }
      return null;
    }

    void markSubtypeOf(js_ast.Expression testSymbol) {
      body.add(js.statement('#.prototype[#] = true', [className, testSymbol]));
    }

    for (var iface in c.implementedTypes) {
      var prop = getInterfaceSymbol(iface.classNode);
      if (prop != null) markSubtypeOf(prop);
    }

    if (c.enclosingLibrary == _coreTypes.coreLibrary &&
        (c == _coreTypes.objectClass ||
            c == _coreTypes.stringClass ||
            c == _coreTypes.functionClass ||
            c == _coreTypes.intClass ||
            c == _coreTypes.deprecatedNullClass ||
            c == _coreTypes.numClass ||
            c == _coreTypes.doubleClass ||
            c == _coreTypes.boolClass)) {
      // Custom type tests for these types are in the patch files.
      return null;
    }

    if (c == _coreTypes.deprecatedFutureOrClass) {
      // Custom type tests for FutureOr types are attached when the type is
      // constructed in the runtime normalizeFutureOr method.
      return null;
    }

    body.add(runtimeStatement('addTypeTests(#)', [className]));

    if (c.typeParameters.isEmpty) return null;

    // For generics, testing against the default instantiation is common,
    // so optimize that.
    var isClassSymbol = getInterfaceSymbol(c);
    if (isClassSymbol == null) {
      // TODO(jmesserly): we could export these symbols, if we want to mark
      // implemented interfaces for user-defined classes.
      var id = _emitTemporaryId('_is_${getLocalClassName(c)}_default');
      moduleItems.add(
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
    return runtimeStatement('addTypeTests(#, #)', [defaultInst, isClassSymbol]);
  }

  void _emitDartSymbols(
      Iterable<js_ast.TemporaryId> vars, List<js_ast.ModuleItem> body) {
    for (var id in vars) {
      body.add(js.statement('const # = Symbol(#)', [id, js.string(id.name)]));
    }
  }

  void _emitSuperHelperSymbols(List<js_ast.Statement> body) {
    _emitDartSymbols(
        _superHelpers.values.map((m) => m.name as js_ast.TemporaryId), body);
    _superHelpers.clear();
  }

  /// Emits static fields for a class, and initialize them eagerly if possible,
  /// otherwise define them as lazy properties.
  void _emitStaticFields(Class c, List<js_ast.Statement> body) {
    var fields = c.fields
        .where((f) => f.isStatic && getRedirectingFactories(f) == null)
        .toList();
    if (c.isEnum) {
      // We know enum fields can be safely emitted as const fields, as long
      // as the `values` field is emitted last.
      var classRef = _emitTopLevelName(c);
      var valueField = fields.firstWhere((f) => f.name.text == 'values');
      fields.remove(valueField);
      fields.add(valueField);
      for (var f in fields) {
        assert(f.isConst);
        body.add(defineValueOnClass(
                c,
                classRef,
                _emitStaticMemberName(f.name.text),
                _visitInitializer(f.initializer, f.annotations))
            .toStatement());
      }
    } else if (fields.isNotEmpty) {
      body.add(_emitLazyFields(_emitTopLevelName(c), fields,
          (n) => _emitStaticMemberName(n.name.text)));
    }
  }

  /// Ensure `dartx.` symbols we will use are present.
  void _initExtensionSymbols(Class c) {
    if (_extensionTypes.hasNativeSubtype(c) || c == _coreTypes.objectClass) {
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
      js_ast.Expression className, List<js_ast.Statement> body) {
    void emitExtensions(String helperName, Iterable<String> extensions) {
      if (extensions.isEmpty) return;
      var names = extensions
          .map((e) => propertyName(js_ast.memberNameForDartMember(e)))
          .toList();
      body.add(js.statement('#.#(#, #);', [
        runtimeModule,
        helperName,
        className,
        js_ast.ArrayInitializer(names, multiline: names.length > 4)
      ]));
    }

    var props = _classProperties;
    emitExtensions('defineExtensionMethods', props.extensionMethods);
    emitExtensions('defineExtensionAccessors', props.extensionAccessors);
  }

  /// Emit the signature on the class recording the runtime type information
  void _emitClassSignature(
      Class c, js_ast.Expression className, List<js_ast.Statement> body) {
    var savedClass = _classEmittingSignatures;
    _classEmittingSignatures = c;

    var interfaces = c.implementedTypes.toList()
      ..addAll(c.superclassConstraints());
    if (interfaces.isNotEmpty) {
      body.add(js.statement('#[#.implements] = () => [#];', [
        className,
        runtimeModule,
        interfaces.map((i) =>
            _emitInterfaceType(i.asInterfaceType, emitNullability: false))
      ]));
    }

    void emitSignature(String name, List<js_ast.Property> elements) {
      if (elements.isEmpty) return;

      if (!name.startsWith('Static')) {
        var proto = c == _coreTypes.objectClass
            ? js.call('Object.create(null)')
            : runtimeCall('get${name}s(#.__proto__)', [className]);
        elements.insert(0, js_ast.Property(propertyName('__proto__'), proto));
      }
      body.add(runtimeStatement('set${name}Signature(#, () => #)', [
        className,
        js_ast.ObjectInitializer(elements, multiline: elements.length > 1)
      ]));
    }

    var extMethods = _classProperties.extensionMethods;
    var extAccessors = _classProperties.extensionAccessors;
    var staticMethods = <js_ast.Property>[];
    var instanceMethods = <js_ast.Property>[];
    var staticGetters = <js_ast.Property>[];
    var instanceGetters = <js_ast.Property>[];
    var staticSetters = <js_ast.Property>[];
    var instanceSetters = <js_ast.Property>[];
    List<js_ast.Property> getSignatureList(Procedure p) {
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

    var classProcedures = c.procedures.where((p) => !p.isAbstract).toList();
    for (var member in classProcedures) {
      // Static getters/setters/methods cannot be called with dynamic dispatch,
      // nor can they be torn off.
      if (member.isStatic) continue;

      var name = member.name.text;
      var reifiedType = _memberRuntimeType(member, c) as FunctionType;

      // Don't add redundant signatures for inherited methods whose signature
      // did not change.  If we are not overriding, or if the thing we are
      // overriding has a different reified type from ourselves, we must
      // emit a signature on this class.  Otherwise we will inherit the
      // signature from the superclass.
      var memberOverride = c.superclass != null
          ? _hierarchy.getDispatchTarget(c.superclass, member.name,
              setter: member.isSetter)
          : null;

      var needsSignature = memberOverride == null ||
          reifiedType != _memberRuntimeType(memberOverride, c);

      if (needsSignature) {
        js_ast.Expression type;
        if (member.isAccessor) {
          type = _emitType(member.isGetter
              ? reifiedType.returnType
              : reifiedType.positionalParameters[0]);
        } else {
          type = visitFunctionType(reifiedType, member: member);
        }
        var property = js_ast.Property(_declareMemberName(member), type);
        var signatures = getSignatureList(member);
        signatures.add(property);
        if (!member.isStatic &&
            (extMethods.contains(name) || extAccessors.contains(name))) {
          signatures.add(js_ast.Property(
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
    body.add(runtimeStatement('setLibraryUri(#, #)',
        [className, _cacheUri(jsLibraryDebuggerName(c.enclosingLibrary))]));

    var instanceFields = <js_ast.Property>[];
    var staticFields = <js_ast.Property>[];

    var classFields = c.fields.toList();
    for (var field in classFields) {
      // Only instance fields need to be saved for dynamic dispatch.
      var isStatic = field.isStatic;
      if (isStatic) continue;

      var memberName = _declareMemberName(field);
      var fieldSig = _emitFieldSignature(field, c);
      (isStatic ? staticFields : instanceFields)
          .add(js_ast.Property(memberName, fieldSig));
    }
    emitSignature('Field', instanceFields);
    emitSignature('StaticField', staticFields);

    // Add static property dart._runtimeType to Object.
    // All other Dart classes will (statically) inherit this property.
    if (c == _coreTypes.objectClass) {
      body.add(runtimeStatement('lazyFn(#, () => #.#)',
          [className, emitLibraryName(_coreTypes.coreLibrary), 'Type']));
    }

    _classEmittingSignatures = savedClass;
  }

  js_ast.Expression _emitFieldSignature(Field field, Class fromClass) {
    var type = _typeFromClass(field.type, field.enclosingClass, fromClass);
    var args = [_emitType(type)];
    return runtimeCall(
        field.isFinal ? 'finalFieldType(#)' : 'fieldType(#)', [args]);
  }

  DartType _memberRuntimeType(Member member, Class fromClass) {
    var f = member.function;
    if (f == null) {
      return (member as Field).type;
    }
    FunctionType result;
    if (!f.positionalParameters.any(isCovariantParameter) &&
        !f.namedParameters.any(isCovariantParameter)) {
      // Avoid tagging a member as Function? or Function*
      result = f.computeThisFunctionType(Nullability.nonNullable);
    } else {
      DartType reifyParameter(VariableDeclaration p) => isCovariantParameter(p)
          ? _coreTypes.objectRawType(member.enclosingLibrary.nullable)
          : p.type;
      NamedType reifyNamedParameter(VariableDeclaration p) =>
          NamedType(p.name, reifyParameter(p));

      // TODO(jmesserly): do covariant type parameter bounds also need to be
      // reified as `Object`?
      result = FunctionType(f.positionalParameters.map(reifyParameter).toList(),
          f.returnType, Nullability.nonNullable,
          namedParameters: f.namedParameters.map(reifyNamedParameter).toList()
            ..sort(),
          typeParameters: f
              .computeThisFunctionType(member.enclosingLibrary.nonNullable)
              .typeParameters,
          requiredParameterCount: f.requiredParameterCount);
    }
    return _typeFromClass(result, member.enclosingClass, fromClass)
        as FunctionType;
  }

  DartType _typeFromClass(DartType type, Class superclass, Class subclass) {
    if (identical(superclass, subclass)) return type;
    return Substitution.fromSupertype(
            _hierarchy.getClassAsInstanceOf(subclass, superclass))
        .substituteType(type);
  }

  js_ast.Expression _emitConstructor(
      Constructor node, List<Field> fields, js_ast.Expression className) {
    var savedUri = _currentUri;
    _currentUri = node.fileUri ?? savedUri;
    _staticTypeContext.enterMember(node);
    var params = _emitParameters(node.function);
    var body = _withCurrentFunction(
        node.function,
        () => _superDisallowed(
            () => _emitConstructorBody(node, fields, className)));

    var end = _nodeEnd(node.fileEndOffset);
    _currentUri = savedUri;
    _staticTypeContext.leaveMember(node);
    end ??= _nodeEnd(node.enclosingClass.fileEndOffset);

    return js_ast.Fun(params, js_ast.Block(body))..sourceInformation = end;
  }

  List<js_ast.Statement> _emitConstructorBody(
      Constructor node, List<Field> fields, js_ast.Expression className) {
    var cls = node.enclosingClass;

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    var fn = node.function;
    var body = _emitArgumentInitializers(fn, node.name.text);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    var redirectCall = node.initializers
            .firstWhere((i) => i is RedirectingInitializer, orElse: () => null)
        as RedirectingInitializer;

    if (redirectCall != null) {
      body.add(_emitRedirectingConstructor(redirectCall, className));
      return body;
    }

    // Generate field initializers.
    // These are expanded into each non-redirecting constructor.
    // In the future we may want to create an initializer function if we have
    // multiple constructors, but it needs to be balanced against readability.
    body.add(_initializeFields(fields, node));

    // If no superinitializer is provided, an implicit superinitializer of the
    // form `super()` is added at the end of the initializer list, unless the
    // enclosing class is class Object.
    var superCall = node.initializers.firstWhere((i) => i is SuperInitializer,
        orElse: () => null) as SuperInitializer;
    var jsSuper = _emitSuperConstructorCallIfNeeded(cls, className, superCall);
    if (jsSuper != null) {
      body.add(jsSuper..sourceInformation = _nodeStart(superCall));
    }

    body.add(_emitFunctionScopedBody(fn));
    return body;
  }

  js_ast.Expression _constructorName(String name) {
    if (name == '') {
      // Default constructors (factory or not) use `new` as their name.
      return propertyName('new');
    }
    return _emitStaticMemberName(name);
  }

  js_ast.Statement _emitRedirectingConstructor(
      RedirectingInitializer node, js_ast.Expression className) {
    var ctor = node.target;
    // We can't dispatch to the constructor with `this.new` as that might hit a
    // derived class constructor with the same name.
    return js.statement('#.#.call(this, #);', [
      className,
      _constructorName(ctor.name.text),
      _emitArgumentList(node.arguments, types: false)
    ]);
  }

  js_ast.Statement _emitSuperConstructorCallIfNeeded(
      Class c, js_ast.Expression className,
      [SuperInitializer superInit]) {
    if (c == _coreTypes.objectClass) return null;

    Constructor ctor;
    List<js_ast.Expression> args;
    if (superInit == null) {
      ctor = unnamedConstructor(c.superclass);
      args = [];
    } else {
      ctor = superInit.target;
      args = _emitArgumentList(superInit.arguments, types: false);
    }
    // We can skip the super call if it's empty. Most commonly this happens for
    // things that extend Object, and don't have any field initializers or their
    // own default constructor.
    if (ctor.name.text == '' && !_hasUnnamedSuperConstructor(c)) {
      return null;
    }
    return _emitSuperConstructorCall(className, ctor.name.text, args);
  }

  js_ast.Statement _emitSuperConstructorCall(
      js_ast.Expression className, String name, List<js_ast.Expression> args) {
    return js.statement('#.__proto__.#.call(this, #);',
        [className, _constructorName(name), args ?? []]);
  }

  bool _hasUnnamedInheritedConstructor(Class c) {
    if (c == null) return false;
    return _hasUnnamedConstructor(c) || _hasUnnamedSuperConstructor(c);
  }

  bool _hasUnnamedSuperConstructor(Class c) {
    return _hasUnnamedConstructor(c.mixedInClass) ||
        _hasUnnamedInheritedConstructor(c.superclass);
  }

  bool _hasUnnamedConstructor(Class c) {
    if (c == null || c == _coreTypes.objectClass) return false;
    var ctor = unnamedConstructor(c);
    if (ctor != null && !ctor.isSynthetic) return true;
    return c.fields.any((f) => !f.isStatic);
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  js_ast.Statement _initializeFields(List<Field> fields, [Constructor ctor]) {
    // Run field initializers if they can have side-effects.
    Set<Field> ctorFields;
    if (ctor != null) {
      ctorFields = ctor.initializers
          .map((c) => c is FieldInitializer ? c.field : null)
          .toSet()
            ..remove(null);
    }

    var body = <js_ast.Statement>[];
    void emitFieldInit(Field f, Expression initializer, TreeNode hoverInfo) {
      var virtualField = _classProperties.virtualFields[f];

      // Avoid calling getSymbol on _declareMemberName since _declareMemberName
      // calls _emitMemberName downstream, which already invokes getSymbol.
      var access = virtualField == null
          ? _declareMemberName(f)
          : getSymbol(virtualField);
      var jsInit = _visitInitializer(initializer, f.annotations);
      body.add(jsInit
          .toAssignExpression(js.call('this.#', [access])
            ..sourceInformation = _nodeStart(hoverInfo))
          .toStatement());
    }

    for (var f in fields) {
      if (f.isStatic) continue;
      var init = f.initializer;
      if (ctorFields != null &&
          ctorFields.contains(f) &&
          (init == null || _constants.isConstant(init))) {
        continue;
      }
      _staticTypeContext.enterMember(f);
      emitFieldInit(f, init, f);
      _staticTypeContext.leaveMember(f);
    }

    // Run constructor field initializers such as `: foo = bar.baz`
    if (ctor != null) {
      for (var init in ctor.initializers) {
        if (init is FieldInitializer) {
          emitFieldInit(init.field, init.value, init);
        } else if (init is LocalInitializer) {
          body.add(visitVariableDeclaration(init.variable));
        } else if (init is AssertInitializer) {
          body.add(visitAssertStatement(init.statement));
        }
      }
    }

    return js_ast.Statement.from(body);
  }

  js_ast.Expression _visitInitializer(
      Expression init, List<Expression> annotations) {
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    if (init == null) return js_ast.LiteralNull();
    return _annotatedNullCheck(annotations)
        ? notNull(init)
        : _visitExpression(init);
  }

  js_ast.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visitExpression(expr);
    if (!isNullable(expr)) return jsExpr;
    return runtimeCall('notNull(#)', [jsExpr]);
  }

  /// If the class has only factory constructors, and it can be mixed in,
  /// then we need to emit a special hidden default constructor for use by
  /// mixins.
  bool _usesMixinNew(Class mixin) {
    // TODO(jmesserly): mixin declarations don't get implicit constructor nodes,
    // even if they have fields, so we need to ensure they're getting generated.
    return mixin.isMixinDeclaration && _hasUnnamedConstructor(mixin) ||
        mixin.superclass?.superclass == null &&
            mixin.constructors.every((c) => c.isExternal);
  }

  js_ast.Statement _addConstructorToClass(Class c, js_ast.Expression className,
      String name, js_ast.Expression jsCtor) {
    jsCtor = defineValueOnClass(c, className, _constructorName(name), jsCtor);
    return js.statement('#.prototype = #.prototype;', [jsCtor, className]);
  }

  @override
  bool superclassHasStatic(Class c, String memberName) {
    // Note: because we're only considering statics, we can ignore mixins.
    // We're only trying to find conflicts due to JS inheriting statics.
    var name = Name(memberName, c.enclosingLibrary);
    while (true) {
      c = c.superclass;
      if (c == null) return false;
      for (var m in c.members) {
        if (m.name == name &&
            (m is Procedure && m.isStatic || m is Field && m.isStatic)) {
          return true;
        }
      }
    }
  }

  List<js_ast.Method> _emitClassMethods(Class c) {
    var virtualFields = _classProperties.virtualFields;

    var jsMethods = <js_ast.Method>[];
    var hasJsPeer = _extensionTypes.isNativeClass(c);
    var hasIterator = false;

    if (c == _coreTypes.objectClass) {
      // Dart does not use ES6 constructors.
      // Add an error to catch any invalid usage.
      jsMethods.add(
          js_ast.Method(propertyName('constructor'), js.fun(r'''function() {
                  throw Error("use `new " + #.typeName(#.getReifiedType(this)) +
                      ".new(...)` to create a Dart object");
              }''', [runtimeModule, runtimeModule])));
    } else if (c == _jsArrayClass) {
      // Provide access to the Array constructor property, so it works like
      // other native types (rather than calling the Dart Object "constructor"
      // above, which throws).
      //
      // This will become obsolete when
      // https://github.com/dart-lang/sdk/issues/31003 is addressed.
      jsMethods.add(js_ast.Method(
          propertyName('constructor'), js.fun(r'function() { return []; }')));
    }

    Set<Member> redirectingFactories;
    for (var m in c.fields) {
      if (m.isStatic) {
        redirectingFactories ??= getRedirectingFactories(m)?.toSet();
      } else if (_extensionTypes.isNativeClass(c)) {
        jsMethods.addAll(_emitNativeFieldAccessors(m));
      } else if (virtualFields.containsKey(m)) {
        jsMethods.addAll(_emitVirtualFieldAccessor(m));
      }
    }

    var getters = <String, Procedure>{};
    var setters = <String, Procedure>{};
    for (var m in c.procedures) {
      if (m.isAbstract) continue;
      if (m.isGetter) {
        getters[m.name.text] = m;
      } else if (m.isSetter) {
        setters[m.name.text] = m;
      }
    }

    var savedUri = _currentUri;
    for (var m in c.procedures) {
      _staticTypeContext.enterMember(m);
      // For the Dart SDK, we use the member URI because it may be different
      // from the class (because of patch files). User code does not need this.
      //
      // TODO(jmesserly): CFE has a bug(?) where nSM forwarders sometimes have a
      // bogus file URI, that is mismatched compared to the offsets. This causes
      // a crash when we look up the location. So for those forwarders, we just
      // suppress source spans.
      _currentUri = m.isNoSuchMethodForwarder ? null : (m.fileUri ?? savedUri);
      if (_isForwardingStub(m)) {
        // TODO(jmesserly): is there any other kind of forwarding stub?
        jsMethods.addAll(_emitCovarianceCheckStub(m));
      } else if (m.isFactory) {
        if (redirectingFactories?.contains(m) ?? false) {
          // Skip redirecting factories (they've already been resolved).
        } else {
          jsMethods.add(_emitFactoryConstructor(m));
        }
      } else if (m.isAccessor) {
        jsMethods.add(_emitMethodDeclaration(m));
        jsMethods.add(_emitSuperAccessorWrapper(m, getters, setters));
        if (!hasJsPeer && m.isGetter && m.name.text == 'iterator') {
          hasIterator = true;
          jsMethods.add(_emitIterable(c));
        }
      } else {
        jsMethods.add(_emitMethodDeclaration(m));
      }
      _staticTypeContext.leaveMember(m);
    }
    _currentUri = savedUri;

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

  bool _isForwardingStub(Procedure member) {
    if (member.isForwardingStub || member.isForwardingSemiStub) {
      if (_currentLibrary.importUri.scheme != 'dart') return true;
      // TODO(jmesserly): external methods in the SDK seem to get incorrectly
      // tagged as forwarding stubs even if they are patched. Perhaps there is
      // an ordering issue in CFE. So for now we pattern match to see if it
      // looks like an actual forwarding stub.
      //
      // We may be able to work around this in a cleaner way by simply emitting
      // the code, and letting the normal covariance check logic handle things.
      // But currently we use _emitCovarianceCheckStub to work around some
      // issues in the stubs.
      var body = member.function.body;
      if (body is ReturnStatement) {
        var expr = body.expression;
        return expr is SuperMethodInvocation || expr is SuperPropertySet;
      }
    }
    return false;
  }

  /// Emits a method, getter, or setter.
  js_ast.Method _emitMethodDeclaration(Procedure member) {
    if (member.isAbstract) {
      return null;
    }

    js_ast.Fun fn;
    if (member.isExternal && !member.isNoSuchMethodForwarder) {
      if (member.isStatic) {
        // TODO(vsm): Do we need to handle this case?
        return null;
      }
      fn = _emitNativeFunctionBody(member);
    } else {
      fn = _emitFunction(member.function, member.name.text);
    }

    return js_ast.Method(_declareMemberName(member), fn,
        isGetter: member.isGetter,
        isSetter: member.isSetter,
        isStatic: member.isStatic)
      ..sourceInformation = _nodeEnd(member.fileEndOffset);
  }

  js_ast.Fun _emitNativeFunctionBody(Procedure node) {
    var name = _annotationName(node, isJSAnnotation) ?? node.name.text;
    if (node.isGetter) {
      var returnValue = js('this.#', [name]);
      if (_isNullCheckableNative(node)) {
        // Add a potential null-check on native getter if type is non-nullable.
        returnValue = runtimeCall('checkNativeNonNull(#)', [returnValue]);
      }
      return js_ast.Fun([], js.block('{ return #; }', [returnValue]));
    } else if (node.isSetter) {
      var params = _emitParameters(node.function);
      return js_ast.Fun(
          params, js.block('{ this.# = #; }', [name, params.last]));
    } else {
      var returnValue = js('this.#.apply(this, args)', [name]);
      if (_isNullCheckableNative(node)) {
        // Add a potential null-check on return value if type is non-nullable.
        returnValue = runtimeCall('checkNativeNonNull(#)', [returnValue]);
      }
      return js.fun('function (...args) { return #; }', [returnValue]);
    }
  }

  List<js_ast.Method> _emitCovarianceCheckStub(Procedure member) {
    // TODO(jmesserly): kernel stubs have a few problems:
    // - they're generated even when there is no concrete super member
    // - the stub parameter types don't match the types we need to check to
    //   ensure soundness of the super member, so we must lookup the super
    //   member and determine checks ourselves.
    // - it generates getter stubs, but these are not used
    if (member.isGetter) return const [];

    var enclosingClass = member.enclosingClass;
    var superMember = member.forwardingStubSuperTarget ??
        member.forwardingStubInterfaceTarget;

    if (superMember == null) return const [];

    DartType substituteType(DartType t) {
      return _typeFromClass(t, superMember.enclosingClass, enclosingClass);
    }

    var name = _declareMemberName(member);
    if (member.isSetter) {
      if (superMember is Field && isCovariantField(superMember) ||
          superMember is Procedure &&
              isCovariantParameter(
                  superMember.function.positionalParameters[0])) {
        return const [];
      }
      var setterType = substituteType(superMember.setterType);
      if (_types.isTop(setterType)) return const [];
      return [
        js_ast.Method(
            name,
            js.fun('function(x) { return super.# = #; }',
                [name, _emitCast(_emitIdentifier('x'), setterType)]),
            isSetter: true),
        js_ast.Method(name, js.fun('function() { return super.#; }', [name]),
            isGetter: true)
      ];
    }
    assert(!member.isAccessor);

    var superMethodType = substituteType(superMember.function
            .computeThisFunctionType(superMember.enclosingLibrary.nonNullable))
        as FunctionType;
    var function = member.function;

    var body = <js_ast.Statement>[];
    var typeParameters = superMethodType.typeParameters;
    _emitCovarianceBoundsCheck(typeParameters, body);

    var typeFormals = _emitTypeFormals(typeParameters);
    var jsParams = List<js_ast.Parameter>.from(typeFormals);
    var positionalParameters = function.positionalParameters;
    for (var i = 0, n = positionalParameters.length; i < n; i++) {
      var param = positionalParameters[i];
      var jsParam = _emitIdentifier(param.name);
      jsParams.add(jsParam);

      if (isCovariantParameter(param) &&
          !isCovariantParameter(superMember.function.positionalParameters[i])) {
        var check = _emitCast(jsParam, superMethodType.positionalParameters[i]);
        if (i >= function.requiredParameterCount) {
          body.add(js.statement('if (# !== void 0) #;', [jsParam, check]));
        } else {
          body.add(check.toStatement());
        }
      }
    }
    var namedParameters = function.namedParameters;
    for (var param in namedParameters) {
      if (isCovariantParameter(param) &&
          !isCovariantParameter(superMember.function.namedParameters
              .firstWhere((n) => n.name == param.name))) {
        var name = propertyName(param.name);
        var paramType = superMethodType.namedParameters
            .firstWhere((n) => n.name == param.name);
        body.add(js.statement('if (# in #) #;', [
          name,
          namedArgumentTemp,
          _emitCast(
              js_ast.PropertyAccess(namedArgumentTemp, name), paramType.type)
        ]));
      }
    }

    if (body.isEmpty) return const []; // No checks were needed.

    if (namedParameters.isNotEmpty) jsParams.add(namedArgumentTemp);
    body.add(js.statement('return super.#(#);', [name, jsParams]));
    return [js_ast.Method(name, js_ast.Fun(jsParams, js_ast.Block(body)))];
  }

  /// Emits a Dart factory constructor to a JS static method.
  js_ast.Method _emitFactoryConstructor(Procedure node) {
    if (node.isExternal || isUnsupportedFactoryConstructor(node)) return null;

    var function = node.function;

    /// Note: factory constructors can't use `sync*`/`async*`/`async` bodies
    /// because it would return the wrong type, so we can assume `sync` here.
    ///
    /// We can also skip the logic in [_emitFunction] related to operator
    /// methods like ==, as well as generic method parameters.
    ///
    /// If a future Dart version allows factory constructors to take their
    /// own type parameters, this will need to be changed to call
    /// [_emitFunction] instead.
    var name = node.name.text;
    var jsBody = _emitSyncFunctionBody(function, name);

    return js_ast.Method(
        _constructorName(name), js_ast.Fun(_emitParameters(function), jsBody),
        isStatic: true)
      ..sourceInformation = _nodeEnd(node.fileEndOffset);
  }

  @override
  js_ast.Expression emitConstructorAccess(InterfaceType type) {
    return _emitJSInterop(type.classNode) ??
        _emitInterfaceType(type, emitNullability: false);
  }

  /// This is called whenever a derived class needs to introduce a new field,
  /// shadowing a field or getter/setter pair on its parent.
  ///
  /// This is important because otherwise, trying to read or write the field
  /// would end up calling the getter or setter, and one of those might not even
  /// exist, resulting in a runtime error. Even if they did exist, that's the
  /// wrong behavior if a new field was declared.
  List<js_ast.Method> _emitVirtualFieldAccessor(Field field) {
    var virtualField = _classProperties.virtualFields[field];
    var virtualFieldSymbol = getSymbol(virtualField);
    var name = _declareMemberName(field);

    var getter = js.fun('function() { return this[#]; }', [virtualFieldSymbol]);
    var jsGetter = js_ast.Method(name, getter, isGetter: true)
      ..sourceInformation = _nodeStart(field);

    var args = field.isFinal
        ? [js_ast.Super(), name]
        : [js_ast.This(), virtualFieldSymbol];

    js_ast.Expression value = _emitIdentifier('value');
    if (!field.isFinal && isCovariantField(field)) {
      value = _emitCast(value, field.type);
    }
    args.add(value);

    var jsSetter = js_ast.Method(
        name, js.fun('function(value) { #[#] = #; }', args),
        isSetter: true)
      ..sourceInformation = _nodeStart(field);

    return [jsGetter, jsSetter];
  }

  /// Provide Dart getters and setters that forward to the underlying native
  /// field.  Note that the Dart names are always symbolized to avoid
  /// conflicts.  They will be installed as extension methods on the underlying
  /// native type.
  List<js_ast.Method> _emitNativeFieldAccessors(Field field) {
    // TODO(vsm): Can this by meta-programmed?
    // E.g., dart.nativeField(symbol, jsName)
    // Alternatively, perhaps it could be meta-programmed directly in
    // dart.registerExtensions?
    var jsMethods = <js_ast.Method>[];
    assert(!field.isStatic);

    var name = _annotationName(field, isJSName) ?? field.name.text;
    // Generate getter
    var fn = js_ast.Fun([], js.block('{ return this.#; }', [name]));
    var method = js_ast.Method(_declareMemberName(field), fn, isGetter: true);
    jsMethods.add(method);

    // Generate setter
    if (!field.isFinal) {
      var value = _emitTemporaryId('value');
      fn = js_ast.Fun([value], js.block('{ this.# = #; }', [name, value]));
      method = js_ast.Method(_declareMemberName(field), fn, isSetter: true);
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
  js_ast.Method _emitSuperAccessorWrapper(Procedure member,
      Map<String, Procedure> getters, Map<String, Procedure> setters) {
    if (member.isAbstract) return null;

    var name = member.name.text;
    var memberName = _declareMemberName(member);
    if (member.isGetter) {
      if (!setters.containsKey(name) &&
          _classProperties.inheritedSetters.contains(name)) {
        // Generate a setter that forwards to super.
        var fn = js.fun('function(value) { super[#] = value; }', [memberName]);
        return js_ast.Method(memberName, fn, isSetter: true);
      }
    } else {
      assert(member.isSetter);
      if (!getters.containsKey(name) &&
          _classProperties.inheritedGetters.contains(name)) {
        // Generate a getter that forwards to super.
        var fn = js.fun('function() { return super[#]; }', [memberName]);
        return js_ast.Method(memberName, fn, isGetter: true);
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
  js_ast.Method _emitIterable(Class c) {
    var iterable = _hierarchy.getClassAsInstanceOf(c, _coreTypes.iterableClass);
    if (iterable == null) return null;

    // If a parent had an `iterator` (concrete or abstract) or implements
    // Iterable, we know the adapter is already there, so we can skip it as a
    // simple code size optimization.
    var parent = _hierarchy.getDispatchTarget(c.superclass, Name('iterator'));
    if (parent != null) return null;

    var parentIterable =
        _hierarchy.getClassAsInstanceOf(c.superclass, _coreTypes.iterableClass);
    if (parentIterable != null) return null;

    if (c.enclosingLibrary.importUri.scheme == 'dart' &&
        c.procedures.any((m) => _jsExportName(m) == 'Symbol.iterator')) {
      return null;
    }

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return js_ast.Method(
        js.call('Symbol.iterator'),
        js.call('function() { return new #.JsIterator(this.#); }', [
          runtimeModule,
          _emitMemberName('iterator', memberClass: _coreTypes.iterableClass)
        ]) as js_ast.Fun);
  }

  void _registerExtensionType(
      Class c, String jsPeerName, List<js_ast.Statement> body) {
    var className = _emitTopLevelName(c);
    if (_typeRep.isPrimitive(_coreTypes.legacyRawType(c))) {
      body.add(runtimeStatement(
          'definePrimitiveHashCode(#.prototype)', [className]));
    }
    body.add(runtimeStatement(
        'registerExtension(#, #)', [js.string(jsPeerName), className]));
  }

  void _emitTopLevelFields(List<Field> fields) {
    if (isSdkInternalRuntime(_currentLibrary)) {
      /// Treat dart:_runtime fields as safe to eagerly evaluate.
      // TODO(jmesserly): it'd be nice to avoid this special case.
      var lazyFields = <Field>[];
      var savedUri = _currentUri;

      // Helper functions to test if a constructor invocation is internal and
      // should be eagerly evaluated.
      var isInternalConstructor = (ConstructorInvocation node) {
        var type = node.getStaticType(_staticTypeContext) as InterfaceType;
        var library = type.classNode.enclosingLibrary;
        return isSdkInternalRuntime(library);
      };
      for (var field in fields) {
        _staticTypeContext.enterMember(field);
        var init = field.initializer;
        if (init == null ||
            init is BasicLiteral ||
            init is ConstructorInvocation && isInternalConstructor(init) ||
            init is StaticInvocation && isInlineJS(init.target)) {
          if (init is ConstructorInvocation) {
            // This is an eagerly executed constructor invocation.  We need to
            // ensure the class is emitted before this statement.
            var type = init.getStaticType(_staticTypeContext) as InterfaceType;
            _emitClass(type.classNode);
          }
          _currentUri = field.fileUri;
          moduleItems.add(js.statement('# = #;', [
            _emitTopLevelName(field),
            _visitInitializer(init, field.annotations)
          ]));
        } else {
          lazyFields.add(field);
        }
        _staticTypeContext.leaveMember(field);
      }

      _currentUri = savedUri;
      fields = lazyFields;
    }

    if (fields.isEmpty) return;
    moduleItems.add(_emitLazyFields(
        emitLibraryName(_currentLibrary), fields, _emitTopLevelMemberName));
  }

  js_ast.Statement _emitLazyFields(
      js_ast.Expression objExpr,
      Iterable<Field> fields,
      js_ast.Expression Function(Field f) emitFieldName) {
    var accessors = <js_ast.Method>[];
    var savedUri = _currentUri;

    for (var field in fields) {
      _currentUri = field.fileUri;
      _staticTypeContext.enterMember(field);
      var access = emitFieldName(field);
      accessors.add(js_ast.Method(access, _emitStaticFieldInitializer(field),
          isGetter: true)
        ..sourceInformation = _hoverComment(
            js_ast.PropertyAccess(objExpr, access),
            field.fileOffset,
            field.name.text.length));

      // TODO(jmesserly): currently uses a dummy setter to indicate writable.
      if (!field.isFinal && !field.isConst) {
        accessors.add(js_ast.Method(
            access, js.call('function(_) {}') as js_ast.Fun,
            isSetter: true));
      }
      _staticTypeContext.leaveMember(field);
    }
    _currentUri = savedUri;

    return runtimeStatement('defineLazy(#, { # }, #)', [
      objExpr,
      accessors,
      js.boolean(!_currentLibrary.isNonNullableByDefault)
    ]);
  }

  js_ast.Fun _emitStaticFieldInitializer(Field field) {
    return js_ast.Fun([], js_ast.Block(_withLetScope(() {
      return [
        js_ast.Return(_visitInitializer(field.initializer, field.annotations))
      ];
    })));
  }

  List<js_ast.Statement> _withLetScope(
      List<js_ast.Statement> Function() visitBody) {
    var savedLetVariables = _letVariables;
    _letVariables = [];

    var body = visitBody();
    var letVars = _initLetVariables();
    if (letVars != null) body.insert(0, letVars);

    _letVariables = savedLetVariables;
    return body;
  }

  js_ast.PropertyAccess _emitTopLevelName(NamedNode n, {String suffix = ''}) {
    return _emitJSInterop(n) ?? _emitTopLevelNameNoInterop(n, suffix: suffix);
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  js_ast.Expression _declareMemberName(Member m, {bool useExtension}) {
    return _emitMemberName(m.name.text,
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
  js_ast.Expression _emitMemberName(String name,
      {bool isStatic = false,
      bool useExtension,
      Member member,
      Class memberClass}) {
    // Static members skip the rename steps and may require JS interop renames.
    if (isStatic) {
      return _emitStaticMemberName(name, member);
    }

    // We allow some (illegal in Dart) member names to be used in our private
    // SDK code. These renames need to be included at every declaration,
    // including overrides in subclasses.
    if (member != null) {
      var runtimeName = _jsExportName(member);
      if (runtimeName != null) {
        var parts = runtimeName.split('.');
        if (parts.length < 2) return propertyName(runtimeName);

        js_ast.Expression result = _emitIdentifier(parts[0]);
        for (var i = 1; i < parts.length; i++) {
          result = js_ast.PropertyAccess(result, propertyName(parts[i]));
        }
        return result;
      }
    }

    memberClass ??= member?.enclosingClass;
    if (name.startsWith('_')) {
      // Use the library that this private member's name is scoped to.
      var memberLibrary = member?.name?.library ??
          memberClass?.enclosingLibrary ??
          _currentLibrary;
      return getSymbol(emitPrivateNameSymbol(memberLibrary, name));
    }

    useExtension ??= _isSymbolizedMember(memberClass, name);
    name = js_ast.memberNameForDartMember(name, _isExternal(member));
    if (useExtension) {
      return getSymbol(getExtensionSymbolInternal(name));
    }
    return propertyName(name);
  }

  /// Don't symbolize native members that just forward to the underlying
  /// native member.  We limit this to non-renamed members as the receiver
  /// may be a mock type.
  ///
  /// Note, this is an underlying assumption here that, if another native type
  /// subtypes this one, it also forwards this member to its underlying native
  /// one without renaming.
  bool _isSymbolizedMember(Class c, String name) {
    if (c == null) {
      return _isObjectMember(name);
    }
    c = _typeRep.getImplementationClass(_coreTypes.legacyRawType(c)) ?? c;
    if (_extensionTypes.isNativeClass(c)) {
      var member = _lookupForwardedMember(c, name);

      // Fields on a native class are implicitly native.
      // Methods/getters/setters are marked external/native.
      if (member is Field || _isExternal(member)) {
        // If the native member needs to be null-checked and we're running in
        // sound null-safety, we require symbolizing it in order to access the
        // null-check at the member definition.
        if (_isNullCheckableNative(member)) return true;
        var jsName = _annotationName(member, isJSName);
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
  }

  final _forwardingCache = HashMap<Class, Map<String, Member>>();

  Member _lookupForwardedMember(Class c, String name) {
    // We only care about public methods.
    if (name.startsWith('_')) return null;

    var map = _forwardingCache.putIfAbsent(c, () => {});

    return map.putIfAbsent(
        name,
        () =>
            _hierarchy.getDispatchTarget(c, Name(name)) ??
            _hierarchy.getDispatchTarget(c, Name(name), setter: true));
  }

  js_ast.Expression _emitStaticMemberName(String name, [NamedNode member]) {
    if (member != null) {
      var jsName = _emitJSInteropStaticMemberName(member);
      if (jsName != null) return jsName;

      // Allow the Dart SDK to assign names to statics with the @JSExportName
      // annotation.
      var exportName = _jsExportName(member);
      if (exportName != null) return propertyName(exportName);
    }
    switch (name) {
      // Reserved for the compiler to do `x as T`.
      case 'as':
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
    return propertyName(name);
  }

  /// If [f] is a function passed to JS, make it throw at runtime when called if
  /// it isn't wrapped with `allowInterop`.
  ///
  /// Arguments which are _directly_ wrapped at the site they are passed are
  /// unmodified.
  Expression _assertInterop(Expression f) {
    var type = f.getStaticType(_staticTypeContext);
    if (type is FunctionType ||
        (type is InterfaceType && type.classNode == _coreTypes.functionClass)) {
      if (!isAllowInterop(f)) {
        return StaticInvocation(
            _assertInteropMethod, Arguments([f], types: [type]));
      }
    }
    return f;
  }

  js_ast.Expression _emitJSInteropStaticMemberName(NamedNode n) {
    if (!usesJSInterop(n)) return null;
    var name = _annotationName(n, isPublicJSAnnotation);
    if (name != null) {
      if (name.contains('.')) {
        throw UnsupportedError(
            'static members do not support "." in their names. '
            'See https://github.com/dart-lang/sdk/issues/27926');
      }
    } else {
      name = getTopLevelName(n);
    }
    return js.escapedString(name, "'");
  }

  js_ast.PropertyAccess _emitTopLevelNameNoInterop(NamedNode n,
      {String suffix = ''}) {
    return js_ast.PropertyAccess(emitLibraryName(getLibrary(n)),
        _emitTopLevelMemberName(n, suffix: suffix));
  }

  js_ast.PropertyAccess _emitFutureOrNameNoInterop({String suffix = ''}) {
    return js_ast.PropertyAccess(emitLibraryName(_coreTypes.asyncLibrary),
        propertyName('FutureOr' + suffix));
  }

  /// Emits the member name portion of a top-level member.
  ///
  /// NOTE: usually you should use [_emitTopLevelName] instead of this. This
  /// function does not handle JS interop.
  js_ast.Expression _emitTopLevelMemberName(NamedNode n, {String suffix = ''}) {
    var name = _jsExportName(n) ?? getTopLevelName(n);
    return propertyName(name + suffix);
  }

  bool _isExternal(Member m) {
    // Corresponds to the names in memberNameForDartMember in
    // compiler/js_names.dart.
    const renamedJsMembers = ['prototype', 'constructor'];
    if (m is Procedure) {
      if (m.isExternal) return true;
      if (m.isNoSuchMethodForwarder) {
        if (renamedJsMembers.contains(m.name.text)) {
          return _hasExternalProcedure(m.enclosingClass, m.name.text);
        }
      }
    }
    return false;
  }

  /// Returns true if anything up the class hierarchy externally defines a
  /// procedure with name = [name].
  ///
  /// Used to determine when we should alias Dart-JS reserved members
  /// (e.g., 'prototype' and 'constructor').
  bool _hasExternalProcedure(Class c, String name) {
    var classes = Queue<Class>()..add(c);

    while (classes.isNotEmpty) {
      var c = classes.removeFirst();
      var classesToCheck = [
        if (c.supertype != null) c.supertype.classNode,
        for (var t in c.implementedTypes)
          if (t.classNode != null) t.classNode,
      ];
      classes.addAll(classesToCheck);
      for (var procedure in c.procedures) {
        if (procedure.name.text == name && !procedure.isNoSuchMethodForwarder) {
          return procedure.isExternal;
        }
      }
    }

    return false;
  }

  String _jsNameWithoutGlobal(NamedNode n) {
    if (!usesJSInterop(n)) return null;
    var libraryJSName = _annotationName(getLibrary(n), isPublicJSAnnotation);
    var jsName = _annotationName(n, isPublicJSAnnotation) ?? getTopLevelName(n);
    return libraryJSName != null ? '$libraryJSName.$jsName' : jsName;
  }

  js_ast.PropertyAccess _emitJSInterop(NamedNode n) {
    var jsName = _jsNameWithoutGlobal(n);
    if (jsName == null) return null;
    return _emitJSInteropForGlobal(jsName);
  }

  js_ast.PropertyAccess _emitJSInteropForGlobal(String name) {
    var parts = name.split('.');
    if (parts.isEmpty) parts = [''];
    js_ast.PropertyAccess access;
    for (var part in parts) {
      access = js_ast.PropertyAccess(
          access ?? runtimeCall('global'), js.escapedString(part, "'"));
    }
    return access;
  }

  void _emitLibraryProcedures(Library library) {
    var procedures = library.procedures
        .where((p) => !p.isExternal && !p.isAbstract)
        .toList();
    moduleItems.addAll(procedures
        .where((p) => !p.isAccessor)
        .map(_emitLibraryFunction)
        .toList());
    _emitLibraryAccessors(procedures.where((p) => p.isAccessor).toList());
  }

  void _emitLibraryAccessors(Iterable<Procedure> accessors) {
    if (accessors.isEmpty) return;
    moduleItems.add(runtimeStatement('copyProperties(#, { # })', [
      emitLibraryName(_currentLibrary),
      accessors.map(_emitLibraryAccessor).toList()
    ]));
  }

  js_ast.Method _emitLibraryAccessor(Procedure node) {
    var savedUri = _currentUri;
    _staticTypeContext.enterMember(node);
    _currentUri = node.fileUri;

    var name = node.name.text;
    var result = js_ast.Method(
        propertyName(name), _emitFunction(node.function, node.name.text),
        isGetter: node.isGetter, isSetter: node.isSetter)
      ..sourceInformation = _nodeEnd(node.fileEndOffset);

    _currentUri = savedUri;
    _staticTypeContext.leaveMember(node);
    return result;
  }

  js_ast.Statement _emitLibraryFunction(Procedure p) {
    var savedUri = _currentUri;
    _staticTypeContext.enterMember(p);
    _currentUri = p.fileUri;

    var body = <js_ast.Statement>[];
    var fn = _emitFunction(p.function, p.name.text)
      ..sourceInformation = _nodeEnd(p.fileEndOffset);

    if (_currentLibrary.importUri.scheme == 'dart' &&
        _isInlineJSFunction(p.function.body)) {
      fn = js_ast.simplifyPassThroughArrowFunCallBody(fn);
    }

    var nameExpr = _emitTopLevelName(p);
    body.add(js.statement('# = #',
        [nameExpr, js_ast.NamedFunction(_emitTemporaryId(p.name.text), fn)]));

    _currentUri = savedUri;
    _staticTypeContext.leaveMember(p);
    return js_ast.Statement.from(body);
  }

  js_ast.Expression _emitFunctionTagged(js_ast.Expression fn, FunctionType type,
      {bool topLevel = false}) {
    var lazy = topLevel && !_canEmitTypeAtTopLevel(type);
    var typeRep = visitFunctionType(
        // Avoid tagging a closure as Function? or Function*
        type.withDeclaredNullability(Nullability.nonNullable),
        lazy: lazy);
    return runtimeCall(lazy ? 'lazyFn(#, #)' : 'fn(#, #)', [fn, typeRep]);
  }

  /// Whether the expression for [type] can be evaluated at this point in the JS
  /// module.
  ///
  /// Types cannot be evaluated if they depend on something that hasn't been
  /// defined yet. For example:
  ///
  ///     C foo() => null;
  ///     class C {}
  ///
  /// If we're emitting the type information for `foo`, we cannot refer to `C`
  /// yet, so we must evaluate foo's type lazily.
  bool _canEmitTypeAtTopLevel(DartType type) {
    assert(isKnownDartTypeImplementor(type));
    if (type is InterfaceType) {
      return !_pendingClasses.contains(type.classNode) &&
          type.typeArguments.every(_canEmitTypeAtTopLevel);
    }
    if (type is FutureOrType) {
      return !_pendingClasses.contains(_coreTypes.deprecatedFutureOrClass) &&
          _canEmitTypeAtTopLevel(type.typeArgument);
    }
    if (type is FunctionType) {
      // Generic functions are always safe to emit, because they're lazy until
      // type arguments are applied.
      if (type.typeParameters.isNotEmpty) return true;

      return (_canEmitTypeAtTopLevel(type.returnType) &&
          type.positionalParameters.every(_canEmitTypeAtTopLevel) &&
          type.namedParameters.every((n) => _canEmitTypeAtTopLevel(n.type)));
    }
    if (type is TypedefType) {
      return type.typeArguments.every(_canEmitTypeAtTopLevel);
    }
    return true;
  }

  /// Emits a Dart [type] into code.
  js_ast.Expression _emitType(DartType type) => type.accept(this);

  js_ast.Expression _emitInvalidNode(Node node, [String message = '']) {
    if (message.isNotEmpty) message += ' ';
    return runtimeCall('throwUnimplementedError(#)',
        [js.escapedString('node <${node.runtimeType}> $message`$node`')]);
  }

  @override
  js_ast.Expression defaultDartType(DartType type) => _emitInvalidNode(type);

  @override
  js_ast.Expression visitInvalidType(InvalidType type) => defaultDartType(type);

  @override
  js_ast.Expression visitDynamicType(DynamicType type) =>
      runtimeCall('dynamic');

  @override
  js_ast.Expression visitVoidType(VoidType type) => runtimeCall('void');

  @override
  js_ast.Expression visitBottomType(BottomType type) =>
      _emitType(const NullType());

  @override
  js_ast.Expression visitNullType(NullType type) =>
      _emitInterfaceType(_coreTypes.deprecatedNullType);

  @override
  js_ast.Expression visitNeverType(NeverType type) =>
      type.nullability == Nullability.nullable
          ? visitNullType(const NullType())
          : _emitNullabilityWrapper(runtimeCall('Never'), type.nullability);

  /// Normalizes `FutureOr` types and emits the normalized version.
  js_ast.Expression _normalizeFutureOr(FutureOrType futureOr) {
    var typeArgument = futureOr.typeArgument;
    if (typeArgument is DynamicType) {
      // FutureOr<dynamic> --> dynamic
      return visitDynamicType(typeArgument);
    }
    if (typeArgument is VoidType) {
      // FutureOr<void> --> void
      return visitVoidType(typeArgument);
    }

    if (typeArgument is InterfaceType &&
        typeArgument.classNode == _coreTypes.objectClass) {
      // Normalize FutureOr of Object, Object?, Object*.
      var nullable = futureOr.nullability == Nullability.nullable ||
          typeArgument.nullability == Nullability.nullable;
      var legacy = futureOr.nullability == Nullability.legacy ||
          typeArgument.nullability == Nullability.legacy;
      var nullability = nullable
          ? Nullability.nullable
          : legacy
              ? Nullability.legacy
              : Nullability.nonNullable;
      return _emitInterfaceType(
          typeArgument.withDeclaredNullability(nullability));
    } else if (typeArgument is NeverType) {
      // FutureOr<Never> --> Future<Never>
      return _emitInterfaceType(InterfaceType(
          _coreTypes.futureClass, futureOr.nullability, [typeArgument]));
    } else if (typeArgument is NullType) {
      // FutureOr<Null> --> Future<Null>?
      return _emitInterfaceType(InterfaceType(
          _coreTypes.futureClass, Nullability.nullable, [typeArgument]));
    } else if (futureOr.declaredNullability == Nullability.nullable &&
        typeArgument.nullability == Nullability.nullable) {
      // FutureOr<T?>? --> FutureOr<T?>
      return _emitFutureOrType(
          futureOr.withDeclaredNullability(Nullability.nonNullable));
    }
    return _emitFutureOrType(futureOr);
  }

  @override
  js_ast.Expression visitInterfaceType(InterfaceType type) =>
      _emitInterfaceType(type);

  @override
  js_ast.Expression visitFutureOrType(FutureOrType type) =>
      _normalizeFutureOr(type);

  /// Emits the representation of [type].
  ///
  /// Will avoid emitting the type wrappers for null safety when
  /// [emitNullability] is `false` to avoid cases where marking [type] with
  /// nullability information makes no sense in the context.
  js_ast.Expression _emitInterfaceType(InterfaceType type,
      {bool emitNullability = true}) {
    var c = type.classNode;
    _declareBeforeUse(c);
    js_ast.Expression typeRep;

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
      typeRep = runtimeCall(
          'anonymousJSType(#)', [js.escapedString(getLocalClassName(c))]);
    } else {
      var jsName = _jsNameWithoutGlobal(c);
      if (jsName != null) {
        typeRep = runtimeCall('lazyJSType(() => #, #)',
            [_emitJSInteropForGlobal(jsName), js.escapedString(jsName)]);
      }
    }

    if (typeRep != null) {
      // JS types are not currently cached in the type table like other types
      // are below.
      return emitNullability
          ? _emitNullabilityWrapper(typeRep, type.nullability)
          : typeRep;
    }

    var args = type.typeArguments;
    Iterable<js_ast.Expression> jsArgs;
    if (args.any((a) => a != const DynamicType())) {
      jsArgs = args.map(_emitType);
    }
    if (jsArgs != null) {
      // We force nullability to non-nullable to prevent caching nullable
      // and non-nullable generic types separately (e.g., C<T> and C<T>?).
      // Forward-defined types will only have nullability wrappers around
      // their type arguments (not the generic type itself).
      typeRep = _emitGenericClassType(
          type.withDeclaredNullability(Nullability.nonNullable), jsArgs);
      if (_cacheTypes) {
        typeRep = _typeTable.nameType(
            type.withDeclaredNullability(Nullability.nonNullable), typeRep);
      }
    }

    typeRep ??= _emitTopLevelNameNoInterop(type.classNode);

    // Avoid emitting the null safety wrapper types when:
    // * This specific InterfaceType is known to be from a context where
    //   the nullability is meaningless:
    //   * `class A extends B {...}` where B is the InterfaceType.
    //   * Emitting non-null constructor calls.
    // * The InterfaceType is the Null type.
    // * The types were written in JS context or as part of the dart:_runtime
    //   library.
    if (!emitNullability ||
        type == _coreTypes.deprecatedNullType ||
        // TODO(38701) Remove these once the SDK has unforked and is running
        // "opted-in"
        !coreLibrary.isNonNullableByDefault &&
            (_isInForeignJS || isSdkInternalRuntime(currentLibrary))) {
      return typeRep;
    }

    if (type.nullability == Nullability.undetermined) {
      throw UnsupportedError('Undetermined Nullability');
    }

    // Emit non-nullable version directly.
    typeRep = _emitNullabilityWrapper(typeRep, type.nullability);
    if (!_cacheTypes || type.nullability == Nullability.nonNullable) {
      return typeRep;
    }

    // Hoist the nullable or legacy versions of the type to the top level and
    // use it everywhere it appears.
    return _typeTable.nameType(type, typeRep);
  }

  /// Emits the representation of a FutureOr [type].
  js_ast.Expression _emitFutureOrType(FutureOrType type) {
    _declareBeforeUse(_coreTypes.deprecatedFutureOrClass);

    var arg = type.typeArgument;
    js_ast.Expression typeRep;
    if (arg != const DynamicType()) {
      // We force nullability to non-nullable to prevent caching nullable
      // and non-nullable generic types separately (e.g., C<T> and C<T>?).
      // Forward-defined types will only have nullability wrappers around
      // their type arguments (not the generic type itself).
      typeRep = _emitFutureOrTypeWithArgument(_emitType(arg));
      if (_cacheTypes) {
        typeRep = _typeTable.nameType(
            type.withDeclaredNullability(Nullability.nonNullable), typeRep);
      }
    }

    typeRep ??= _emitFutureOrNameNoInterop();

    if (type.declaredNullability == Nullability.undetermined) {
      throw UnsupportedError('Undetermined Nullability');
    }

    // Emit non-nullable version directly.
    typeRep = _emitNullabilityWrapper(typeRep, type.declaredNullability);
    if (!_cacheTypes || type.nullability == Nullability.nonNullable) {
      return typeRep;
    }

    // Hoist the nullable or legacy versions of the type to the top level and
    // use it everywhere it appears.
    return _typeTable.nameType(type, typeRep);
  }

  /// Wraps [typeRep] in the appropriate wrapper for the given [nullability].
  ///
  /// Non-nullable and undetermined nullability will not cause any wrappers to
  /// be emitted.
  js_ast.Expression _emitNullabilityWrapper(
      js_ast.Expression typeRep, Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return runtimeCall('legacy(#)', [typeRep]);
      case Nullability.nullable:
        return runtimeCall('nullable(#)', [typeRep]);
      default:
        // Do not wrap types that are known to be non-nullable or those that do
        // not yet have the nullability determined.
        return typeRep;
    }
  }

  bool get _emittingClassSignatures =>
      _currentClass != null &&
      identical(_currentClass, _classEmittingSignatures);

  bool get _emittingClassExtends =>
      _currentClass != null && identical(_currentClass, _classEmittingExtends);

  bool get _cacheTypes =>
      !_emittingClassExtends && !_emittingClassSignatures ||
      _currentFunction != null;

  js_ast.Expression _emitGenericClassType(
      InterfaceType t, Iterable<js_ast.Expression> typeArgs) {
    var genericName = _emitTopLevelNameNoInterop(t.classNode, suffix: '\$');
    return js.call('#(#)', [genericName, typeArgs]);
  }

  js_ast.Expression _emitFutureOrTypeWithArgument(js_ast.Expression typeArg) {
    var genericName = _emitFutureOrNameNoInterop(suffix: '\$');
    return js.call('#(#)', [
      genericName,
      [typeArg]
    ]);
  }

  @override
  js_ast.Expression visitFunctionType(type,
      {Member member, bool lazy = false}) {
    var requiredTypes =
        type.positionalParameters.take(type.requiredParameterCount).toList();
    var function = member?.function;
    var requiredParams = function?.positionalParameters
        ?.take(type.requiredParameterCount)
        ?.toList();
    var optionalTypes =
        type.positionalParameters.skip(type.requiredParameterCount).toList();
    var optionalParams = function?.positionalParameters
        ?.skip(type.requiredParameterCount)
        ?.toList();

    var namedTypes = <NamedType>[];
    var requiredNamedTypes = <NamedType>[];
    type.namedParameters.forEach((param) => param.isRequired
        ? requiredNamedTypes.add(param)
        : namedTypes.add(param));
    var allNamedTypes = type.namedParameters;

    var returnType = _emitType(type.returnType);
    var requiredArgs = _emitTypeNames(requiredTypes, requiredParams, member);

    List<js_ast.Expression> typeParts;
    if (allNamedTypes.isNotEmpty) {
      assert(optionalTypes.isEmpty);
      var namedArgs = _emitTypeProperties(namedTypes);
      var requiredNamedArgs = _emitTypeProperties(requiredNamedTypes);
      typeParts = [returnType, requiredArgs, namedArgs, requiredNamedArgs];
    } else if (optionalTypes.isNotEmpty) {
      assert(allNamedTypes.isEmpty);
      var optionalArgs = _emitTypeNames(optionalTypes, optionalParams, member);
      typeParts = [returnType, requiredArgs, optionalArgs];
    } else {
      typeParts = [returnType, requiredArgs];
    }

    var typeFormals = type.typeParameters;
    String helperCall;
    if (typeFormals.isNotEmpty) {
      var tf = _emitTypeFormals(typeFormals);

      js_ast.Expression addTypeFormalsAsParameters(
          List<js_ast.Expression> elements) {
        var names = _typeTable.dischargeFreeTypes(typeFormals);
        return names.isEmpty
            ? js.call('(#) => [#]', [tf, elements])
            : js.call('(#) => {#; return [#];}', [tf, names, elements]);
      }

      typeParts = [addTypeFormalsAsParameters(typeParts)];

      helperCall = 'gFnType(#)';

      /// Returns `true` when the type parameter [t] has a `Object*` bound
      /// either implicit `<T>` or explicit `<T extends Object>` written in a
      /// legacy library.
      ///
      /// Note: Kernel represents these differently in the default values.
      /// `<T extends Object* = dynamic>` vs `<T extends Object* = Object*>` but
      /// at runtime we treat both as having a default value of dynamic as it is
      /// correct for the cases that appear more frequently.
      bool typeParameterHasLegacyTopBound(TypeParameter t) =>
          t.bound == _types.coreTypes.objectLegacyRawType;

      // Avoid emitting these bounds when possible and interpret the empty
      // bounds at runtime to mean all bounds are `Object*`.
      // TODO(nshahan) Revisit this representation when more libraries have
      // migrated to null safety.
      if (!typeFormals.every(typeParameterHasLegacyTopBound)) {
        /// Emits the bound of the type parameter [t] for use in runtime
        /// checking.
        ///
        /// Default values e.g. dynamic get replaced at runtime.
        js_ast.Expression emitTypeParameterBound(TypeParameter t) =>
            _emitType(t.bound);

        var bounds = typeFormals.map(emitTypeParameterBound).toList();
        typeParts.add(addTypeFormalsAsParameters(bounds));
      }
    } else {
      helperCall = 'fnType(#)';
    }
    var typeRep = runtimeCall(helperCall, [typeParts]);
    // First add the type to the type table in its non-nullable form. It can be
    // reused by the nullable and legacy versions.
    typeRep = _cacheTypes
        ? _typeTable.nameFunctionType(
            type.withDeclaredNullability(Nullability.nonNullable), typeRep,
            lazy: lazy)
        : typeRep;

    if (type.nullability == Nullability.nonNullable) return typeRep;

    // Hoist the nullable or legacy versions of the type to the top level and
    // use it everywhere it appears.
    typeRep = _emitNullabilityWrapper(typeRep, type.nullability);
    return _cacheTypes
        ? _typeTable.nameFunctionType(type, typeRep, lazy: lazy)
        : typeRep;
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  js_ast.Expression _emitConstructorAccess(InterfaceType type) {
    return _emitJSInterop(type.classNode) ??
        _emitInterfaceType(type, emitNullability: false);
  }

  js_ast.Expression _emitConstructorName(InterfaceType type, Member c) {
    return _emitJSInterop(type.classNode) ??
        js_ast.PropertyAccess(
            _emitConstructorAccess(type), _constructorName(c.name.text));
  }

  /// Emits an expression that lets you access statics on an [c] from code.
  js_ast.Expression _emitStaticClassName(Class c) {
    _declareBeforeUse(c);
    return _emitTopLevelName(c);
  }

  /// Emits named parameters in the form '{name: type}'.
  js_ast.ObjectInitializer _emitTypeProperties(Iterable<NamedType> types) {
    return js_ast.ObjectInitializer(types
        .map((t) => js_ast.Property(propertyName(t.name), _emitType(t.type)))
        .toList());
  }

  /// Emits a list of types and their metadata annotations to code.
  ///
  /// Annotatable contexts include typedefs and method/function declarations.
  js_ast.ArrayInitializer _emitTypeNames(List<DartType> types,
          List<VariableDeclaration> parameters, Member member) =>
      js_ast.ArrayInitializer([for (var type in types) _emitType(type)]);

  @override
  js_ast.Expression visitTypeParameterType(TypeParameterType type) =>
      _emitTypeParameterType(type);

  js_ast.Expression _emitTypeParameterType(TypeParameterType type,
      {bool emitNullability = true}) {
    var typeParam = _emitTypeParameter(type.parameter);

    // Avoid wrapping the type parameter in a nullability or hoisting a type
    // that has no nullability wrappers.
    if (!emitNullability || type.isPotentiallyNonNullable) return typeParam;

    var typeWithNullability =
        _emitNullabilityWrapper(typeParam, type.nullability);

    if (!_cacheTypes) return typeWithNullability;

    // Hoist the wrapped version to the top level and use it everywhere this
    // type appears.
    return _typeTable.nameType(type, typeWithNullability);
  }

  js_ast.Identifier _emitTypeParameter(TypeParameter t) =>
      _emitIdentifier(getTypeParameterName(t));

  @override
  js_ast.Expression visitTypedefType(TypedefType type) =>
      visitFunctionType(type.unalias as FunctionType);

  /// Emits function after initial compilation.
  ///
  /// Emits function from kernel [functionNode] with name [name] in the context
  /// of [library] and [cls], after the initial compilation of the module is
  /// finished. For example, this happens in expression compilation during
  /// expression evaluation initiated by the user from the IDE and coordinated
  /// by the debugger.
  js_ast.Fun emitFunctionIncremental(
      Library library, Class cls, FunctionNode functionNode, String name) {
    // setup context
    _currentLibrary = library;
    _staticTypeContext.enterLibrary(_currentLibrary);
    _currentClass = cls;

    // Do not add formal parameter checks for the top-level synthetic function
    // generated for expression evaluation, as those parameters are a set of
    // variables from the current scope, and should alredy be checked in the
    // original code.
    _checkParameters = false;

    // Emit function with additional information, such as types that are used
    // in the expression. Note that typeTable can be null if this function is
    // called from the expression compilation service, since we currently do
    // not optimize for size of generated javascript in that scenario.
    // TODO: figure whether or when optimizing for build time vs JavaScript
    // size on expression evaluation is better.
    // Issue: https://github.com/dart-lang/sdk/issues/43288
    var fun = _emitFunction(functionNode, name);

    var types = _typeTable?.dischargeBoundTypes(incremental: true);
    var constants = _dischargeConstTable();

    var body = js_ast.Block([...?types, ...?constants, ...fun.body.statements]);
    return js_ast.Fun(fun.params, body);
  }

  /// Emit all collected const symbols
  ///
  /// This is similar to how constants are emitted during
  /// initial compilation in emitModule
  ///
  /// TODO: unify the code with emitModule.
  List<js_ast.Statement> _dischargeConstTable() {
    var items = <js_ast.Statement>[];

    if (_constLazyAccessors.isNotEmpty) {
      var constTableBody = runtimeStatement(
          'defineLazy(#, { # }, false)', [_constTable, _constLazyAccessors]);
      items.add(constTableBody);
      _constLazyAccessors.clear();
    }

    _copyAndFlattenBlocks(items, moduleItems);
    moduleItems.clear();
    return items;
  }

  /// Flattens blocks in [items] to a single list.
  ///
  /// This will not flatten blocks that are marked as being scopes.
  void _copyAndFlattenBlocks(
      List<js_ast.Statement> result, Iterable<js_ast.ModuleItem> items) {
    for (var item in items) {
      if (item is js_ast.Block && !item.isScope) {
        _copyAndFlattenBlocks(result, item.statements);
      } else {
        result.add(item as js_ast.Statement);
      }
    }
  }

  js_ast.Fun _emitFunction(FunctionNode f, String name) {
    // normal function (sync), vs (sync*, async, async*)
    var isSync = f.asyncMarker == AsyncMarker.Sync;
    var formals = _emitParameters(f);
    var typeFormals = _emitTypeFormals(f.typeParameters);

    var parent = f.parent;
    if (_reifyGenericFunction(parent is Member ? parent : null)) {
      formals.insertAll(0, typeFormals);
    }

    // TODO(jmesserly): need a way of determining if parameters are
    // potentially mutated in Kernel. For now we assume all parameters are.
    super.enterFunction(name, formals, () => true);

    var block = isSync
        ? _emitSyncFunctionBody(f, name)
        : _emitGeneratorFunctionBody(f, name);

    block = super.exitFunction(name, formals, block);
    return js_ast.Fun(formals, block);
  }

  js_ast.Parameter _emitParameter(VariableDeclaration node,
      {bool withoutInitializer = false}) {
    var initializer = node.initializer;
    var id = _emitVariableDef(node);
    if (initializer == null || withoutInitializer) return id;
    return js_ast.DestructuredVariable(
        name: id, defaultValue: _visitExpression(initializer));
  }

  List<js_ast.Parameter> _emitParameters(FunctionNode f,
      {bool isForwarding = false}) {
    // Destructure optional positional parameters in place.
    // Given:
    //  - (arg1, arg2, [opt1, opt2 = def2])
    // Emit:
    //  - (arg1, arg2, opt1 = null, opt2 = def2)
    // Note, if [isForwarding] is set, omit initializers as this actually a
    // forwarded call not a parameter list. E.g., the second in:
    //  - foo(arg1, opt1 = def1) => super(arg1, opt1).
    var positional = f.positionalParameters;
    var result = List<js_ast.Parameter>.of(positional
        .map((p) => _emitParameter(p, withoutInitializer: isForwarding)));
    if (positional.isNotEmpty &&
        f.requiredParameterCount == positional.length &&
        positional.last.annotations.any(isJsRestAnnotation)) {
      result.last = js_ast.RestParameter(result.last as js_ast.Identifier);
    }
    if (f.namedParameters.isNotEmpty) result.add(namedArgumentTemp);
    return result;
  }

  List<js_ast.Identifier> _emitTypeFormals(List<TypeParameter> typeFormals) {
    return typeFormals
        .map((t) => _emitIdentifier(getTypeParameterName(t)))
        .toList();
  }

  /// Transforms `sync*` `async` and `async*` function bodies
  /// using ES6 generators.
  ///
  /// This is an internal part of [_emitGeneratorFunctionBody] and should not be
  /// called directly.
  js_ast.Expression _emitGeneratorFunctionExpression(
      FunctionNode function, String name) {
    js_ast.Expression emitGeneratorFn(
        List<js_ast.Parameter> Function(js_ast.Block jsBody) getParameters) {
      var savedController = _asyncStarController;
      _asyncStarController = function.asyncMarker == AsyncMarker.AsyncStar
          ? _emitTemporaryId('stream')
          : null;

      js_ast.Expression gen;
      _superDisallowed(() {
        // Visit the body with our async* controller set.
        //
        // Note: we intentionally don't emit argument initializers here, because
        // they were already emitted outside of the generator expression.
        var jsBody = js_ast.Block(_withCurrentFunction(
            function, () => [_emitFunctionScopedBody(function)]));
        var genFn =
            js_ast.Fun(getParameters(jsBody), jsBody, isGenerator: true);

        // Name the function if possible, to get better stack traces.
        gen = genFn;
        if (name != null) {
          gen = js_ast.NamedFunction(
              _emitTemporaryId(
                  js_ast.friendlyNameForDartOperator[name] ?? name),
              genFn);
        }

        gen.sourceInformation = _nodeEnd(function.fileEndOffset);
        if (usesThisOrSuper(gen)) gen = js.call('#.bind(this)', gen);
      });

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
      var jsParams = _emitParameters(function, isForwarding: true);
      var mutatedParams = jsParams;
      var gen = emitGeneratorFn((fnBody) {
        var mutatedVars = js_ast.findMutatedVariables(fnBody);
        mutatedParams = jsParams
            .where((id) => mutatedVars.contains(id.parameterName))
            .toList();
        return mutatedParams;
      });
      if (mutatedParams.isNotEmpty) {
        gen = js.call('() => #(#)', [gen, mutatedParams]);
      }

      var returnType = _expectedReturnType(function, _coreTypes.iterableClass);
      var syncIterable = _emitInterfaceType(
          InterfaceType(_syncIterableClass, Nullability.legacy, [returnType]),
          emitNullability: false);
      return js.call('new #.new(#)', [syncIterable, gen]);
    }

    if (function.asyncMarker == AsyncMarker.AsyncStar) {
      // `async*` uses the `_AsyncStarImpl<T>` helper class. The generator
      // callback takes an instance of this class.
      //
      // `yield` is specially generated inside `async*` by visitYieldStatement.
      // `await` is generated as `yield`.
      //
      // _AsyncStarImpl has an example of the generated code.
      var gen = emitGeneratorFn((_) => [_asyncStarController]);

      var returnType = _expectedReturnType(function, _coreTypes.streamClass);
      var asyncStarImpl = _emitInterfaceType(
          InterfaceType(_asyncStarImplClass, Nullability.legacy, [returnType]),
          emitNullability: false);
      return js.call('new #.new(#).stream', [asyncStarImpl, gen]);
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
    // Return type of an async body is `Future<flatten(T)>`, where T is the
    // declared return type.
    var returnType = _types.flatten(function
        .computeThisFunctionType(_currentLibrary.nonNullable)
        .returnType);
    return js.call('#.async(#, #)',
        [emitLibraryName(_coreTypes.asyncLibrary), _emitType(returnType), gen]);
  }

  /// Gets the expected return type of a `sync*` or `async*` body.
  DartType _expectedReturnType(FunctionNode f, Class expected) {
    var type =
        f.computeThisFunctionType(_currentLibrary.nonNullable).returnType;
    if (type is InterfaceType) {
      var matchArguments =
          _hierarchy.getTypeArgumentsAsInstanceOf(type, expected);
      if (matchArguments != null) return matchArguments[0];
    }
    return const DynamicType();
  }

  /// Emits a `sync` function body (the default in Dart)
  ///
  /// To emit an `async`, `sync*`, or `async*` function body, use
  /// [_emitGeneratorFunctionBody] instead.
  js_ast.Block _emitSyncFunctionBody(FunctionNode f, String name) {
    assert(f.asyncMarker == AsyncMarker.Sync);

    var block = _withCurrentFunction(f, () {
      /// For (normal) `sync` bodies, execute the function body immediately
      /// after the argument initializers.
      var block = _emitArgumentInitializers(f, name);
      block.add(_emitFunctionScopedBody(f));
      return block;
    });

    return js_ast.Block(block);
  }

  /// Emits an `async`, `sync*`, or `async*` function body.
  ///
  /// The body will perform these steps:
  ///
  /// - Run the argument initializers. These must be run synchronously
  ///   (e.g. covariance checks), and this helps performance.
  /// - Return the generator function, wrapped with the appropriate type
  ///   (`Future`, `Itearble`, and `Stream` respectively).
  ///
  /// To emit a `sync` function body (the default in Dart), use
  /// [_emitSyncFunctionBody] instead.
  js_ast.Block _emitGeneratorFunctionBody(FunctionNode f, String name) {
    assert(f.asyncMarker != AsyncMarker.Sync);

    var statements =
        _withCurrentFunction(f, () => _emitArgumentInitializers(f, name));
    statements.add(_emitGeneratorFunctionExpression(f, name).toReturn()
      ..sourceInformation = _nodeStart(f));
    return js_ast.Block(statements);
  }

  List<js_ast.Statement> _withCurrentFunction(
      FunctionNode fn, List<js_ast.Statement> Function() action) {
    var savedFunction = _currentFunction;
    _currentFunction = fn;
    _nullableInference.enterFunction(fn);

    var result = _withLetScope(action);

    _nullableInference.exitFunction(fn);
    _currentFunction = savedFunction;
    return result;
  }

  T _superDisallowed<T>(T Function() action) {
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var result = action();
    _superAllowed = savedSuperAllowed;
    return result;
  }

  /// Returns true if the underlying type does not accept a null value.
  bool _mustBeNonNullable(DartType type) =>
      type.nullability == Nullability.nonNullable;

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  List<js_ast.Statement> _emitArgumentInitializers(
      FunctionNode f, String name) {
    var body = <js_ast.Statement>[];

    _emitCovarianceBoundsCheck(f.typeParameters, body);

    void initParameter(VariableDeclaration p, js_ast.Identifier jsParam) {
      // When the parameter is covariant, insert the null check before the
      // covariant cast to avoid a TypeError when testing equality with null.
      if (name == '==') {
        // In Dart `operator ==` methods are not called with a null argument.
        // This is handled before calling them. For performance reasons, we push
        // this check inside the method, to simplify our `equals` helper.
        //
        // TODO(jmesserly): in most cases this check is not necessary, because
        // the Dart code already handles it (typically by an `is` check).
        // Eliminate it when possible.
        body.add(js.statement('if (# == null) return false;', [jsParam]));
      }
      if (isCovariantParameter(p)) {
        var castExpr = _emitCast(jsParam, p.type);
        if (!identical(castExpr, jsParam)) body.add(castExpr.toStatement());
      }

      if (name == '==') return;

      if (_annotatedNullCheck(p.annotations)) {
        body.add(_nullParameterCheck(jsParam));
      } else if (!_options.soundNullSafety &&
          _mustBeNonNullable(p.type) &&
          !_annotatedNotNull(p.annotations)) {
        // TODO(vsm): Remove if / when CFE does this:
        // https://github.com/dart-lang/sdk/issues/40597
        // The check on `p.type` is per:
        // https://github.com/dart-lang/language/blob/master/accepted/future-releases/nnbd/feature-specification.md#automatic-debug-assertion-insertion
        var condition = js.call('# == null', [jsParam]);
        // Offsets are not available for compiler-generated variables
        // Get the best available location even if the offset is missing.
        // https://github.com/dart-lang/sdk/issues/34942
        var location = p.location;
        var check = js.statement(' if (#) #.nullFailed(#, #, #, #);', [
          condition,
          runtimeModule,
          _cacheUri(location?.file?.toString()),
          js.number(location?.line ?? -1),
          js.number(location?.column ?? -1),
          js.escapedString('${p.name}'),
        ]);
        body.add(check);
      }
    }

    for (var p in f.positionalParameters) {
      var jsParam = _emitVariableDef(p);
      if (_checkParameters) {
        initParameter(p, jsParam);
      }
    }
    for (var p in f.namedParameters) {
      // Parameters will be passed using their real names, not the (possibly
      // renamed) local variable.
      var jsParam = _emitVariableDef(p);
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
      if (_checkParameters) {
        initParameter(p, jsParam);
      }
    }

    // '_checkParametes = false' is only needed once, while processing formal
    // parameters of the synthetic function from expression evalaluation - it
    // will be called from emitFunctionIncremental, which is a top-level API
    // for expression compilation.
    // Here we either are done with processing those formals, or compiling
    // something else (in which case _checkParameters is already true).
    _checkParameters = true;
    return body;
  }

  bool _annotatedNullCheck(List<Expression> annotations) =>
      annotations.any(_nullableInference.isNullCheckAnnotation);

  bool _annotatedNotNull(List<Expression> annotations) =>
      annotations.any(_nullableInference.isNotNullAnnotation);

  bool _reifyGenericFunction(Member m) =>
      m == null ||
      m.enclosingLibrary.importUri.scheme != 'dart' ||
      !m.annotations
          .any((a) => isBuiltinAnnotation(a, '_js_helper', 'NoReifyGeneric'));

  js_ast.Statement _nullParameterCheck(js_ast.Expression param) {
    var call = runtimeCall('argumentError((#))', [param]);
    return js.statement('if (# == null) #;', [param, call]);
  }

  js_ast.Expression _defaultParamValue(VariableDeclaration p) {
    if (p.annotations.any(isUndefinedAnnotation)) {
      return null;
    } else if (p.initializer != null) {
      return _visitExpression(p.initializer);
    } else {
      return js_ast.LiteralNull();
    }
  }

  void _emitCovarianceBoundsCheck(
      List<TypeParameter> typeFormals, List<js_ast.Statement> body) {
    for (var t in typeFormals) {
      if (t.isGenericCovariantImpl && !_types.isTop(t.bound)) {
        body.add(runtimeStatement('checkTypeBound(#, #, #)', [
          _emitTypeParameterType(TypeParameterType(t, Nullability.undetermined),
              emitNullability: false),
          _emitType(t.bound),
          propertyName(t.name)
        ]));
      }
    }
  }

  js_ast.Statement _visitStatement(Statement s) {
    if (s == null) return null;
    var result = s.accept(this);
    // TODO(jmesserly): is the `is! Block` still necessary?
    if (s is! Block) result.sourceInformation = _nodeStart(s);

    // The statement might be the target of a break or continue with a label.
    var name = _labelNames[s];
    if (name != null) result = js_ast.LabeledStatement(name, result);
    return result;
  }

  js_ast.Statement _emitFunctionScopedBody(FunctionNode f) {
    var jsBody = _visitStatement(f.body);
    if (f.positionalParameters.isNotEmpty || f.namedParameters.isNotEmpty) {
      // Handle shadowing of parameters by local varaibles, which is allowed in
      // Dart but not in JS.
      //
      // We need this for all function types, including generator-based ones
      // (sync*/async/async*). Our code generator assumes it can emit names for
      // named argument initialization, and sync* functions also emit locally
      // modified parameters into the function's scope.
      var parameterNames = {
        for (var p in f.positionalParameters) p.name,
        for (var p in f.namedParameters) p.name,
      };

      return jsBody.toScopedBlock(parameterNames);
    }
    return jsBody;
  }

  /// Visits [nodes] with [_visitExpression].
  List<js_ast.Expression> _visitExpressionList(Iterable<Expression> nodes) {
    return nodes?.map(_visitExpression)?.toList();
  }

  /// Generates an expression for a boolean conversion context (if, while, &&,
  /// etc.), where conversions and null checks are implemented via `dart.test`
  /// to give a more helpful message.
  // TODO(sra): When nullablility is available earlier, it would be cleaner to
  // build an input AST where the boolean conversion is a single AST node.
  js_ast.Expression _visitTest(Expression node) {
    if (node == null) return null;

    if (node is Not) {
      return visitNot(node);
    }
    if (node is LogicalExpression) {
      js_ast.Expression shortCircuit(String code) {
        return js.call(code, [_visitTest(node.left), _visitTest(node.right)]);
      }

      var op = node.operatorEnum;
      if (op == LogicalExpressionOperator.AND) return shortCircuit('# && #');
      if (op == LogicalExpressionOperator.OR) return shortCircuit('# || #');
    }

    if (node is AsExpression && node.isTypeError) {
      assert(node.getStaticType(_staticTypeContext) ==
          _types.coreTypes.boolRawType(currentLibrary.nonNullable));
      return runtimeCall('dtest(#)', [_visitExpression(node.operand)]);
    }

    var result = _visitExpression(node);
    if (isNullable(node)) result = runtimeCall('test(#)', [result]);
    return result;
  }

  js_ast.Expression _visitExpression(Expression e) {
    if (e == null) return null;
    if (e is ConstantExpression) {
      return visitConstant(e.constant);
    }
    var result = e.accept(this);
    result.sourceInformation ??= _nodeStart(e);
    return result;
  }

  /// Gets the start position of [node] for use in source mapping.
  ///
  /// This is the most common kind of marking, and is used for most expressions
  /// and statements.
  SourceLocation _nodeStart(TreeNode node) =>
      _toSourceLocation(node.fileOffset);

  /// Gets the end position of [node] for use in source mapping.
  ///
  /// This is mainly used for things that compile to JS functions. JS wants a
  /// marking on the end of all functions for stepping purposes.
  ///
  /// This can be used to complete a hover span, when we know the start position
  /// has already been emitted. For example, `foo.bar` we only need to mark the
  /// end of `.bar` to ensure `foo.bar` has a hover tooltip.
  NodeEnd _nodeEnd(int endOffset) {
    var loc = _toSourceLocation(endOffset);
    return loc != null ? NodeEnd(loc) : null;
  }

  /// Combines [_nodeStart] with the variable name length to produce a hoverable
  /// span for the varaible.
  //
  // TODO(jmesserly): we need a lot more nodes to support hover.
  NodeSpan _variableSpan(int offset, int nameLength) {
    var start = _toSourceLocation(offset);
    var end = _toSourceLocation(offset + nameLength);
    return start != null && end != null ? NodeSpan(start, end) : null;
  }

  SourceLocation _toSourceLocation(int offset) {
    if (offset == -1) return null;
    var fileUri = _currentUri;
    if (fileUri == null) return null;
    try {
      var loc = _component.getLocation(fileUri, offset);
      if (loc == null || loc.line < 0) return null;
      return SourceLocation(offset,
          sourceUrl: fileUri, line: loc.line - 1, column: loc.column - 1);
    } on StateError catch (_) {
      // TODO(jmesserly): figure out why this is throwing. Perhaps the file URI
      // and offset are mismatched and don't correspond to the same source?
      return null;
    } on RangeError catch (_) {
      return null;
    }
  }

  /// Adds a hover comment for Dart node using JS expression [expr], where
  /// that expression would not otherwise not be generated into source code.
  ///
  /// For example, top-level and static fields are defined as lazy properties,
  /// on the library/class, so their access expressions do not appear in the
  /// source code.
  HoverComment _hoverComment(
      js_ast.Expression expr, int offset, int nameLength) {
    var start = _toSourceLocation(offset);
    var end = _toSourceLocation(offset + nameLength);
    return start != null && end != null ? HoverComment(expr, start, end) : null;
  }

  @override
  js_ast.Statement defaultStatement(Statement node) =>
      _emitInvalidNode(node).toStatement();

  @override
  js_ast.Statement visitExpressionStatement(ExpressionStatement node) {
    var expr = node.expression;
    if (expr is StaticInvocation) {
      if (isInlineJS(expr.target)) {
        return _emitInlineJSCode(expr).toStatement();
      }
      if (_isDebuggerCall(expr.target)) {
        return _emitDebuggerCall(expr).toStatement();
      }
    }
    return _visitExpression(expr).toStatement();
  }

  @override
  js_ast.Statement visitBlock(Block node) {
    // If this is the block body of a function, don't mark it as a separate
    // scope, because the function is the scope. This avoids generating an
    // unncessary nested block.
    //
    // NOTE: we do sometimes need to handle this because Dart and JS rules are
    // slightly different (in Dart, there is a nested scope), but that's handled
    // by _emitSyncFunctionBody.
    var isScope = !identical(node.parent, _currentFunction);
    return js_ast.Block(node.statements.map(_visitStatement).toList(),
        isScope: isScope);
  }

  @override
  js_ast.Statement visitEmptyStatement(EmptyStatement node) =>
      js_ast.EmptyStatement();

  @override
  js_ast.Statement visitAssertBlock(AssertBlock node) {
    // AssertBlocks are introduced by the VM-specific async elimination
    // transformation.  We do not expect them to arise here.
    throw UnsupportedError('compilation of an assert block');
  }

  // Replace a string `uri` literal with a cached top-level variable containing
  // the value to reduce overall code size.
  js_ast.Expression _cacheUri(String uri) {
    if (!_uriContainer.contains(uri)) {
      _uriContainer[uri] = js_ast.LiteralString('"$uri"');
    }
    return _uriContainer.access(uri);
  }

  @override
  js_ast.Statement visitAssertStatement(AssertStatement node) {
    if (!_options.enableAsserts) return js_ast.EmptyStatement();
    var condition = node.condition;
    var conditionType = condition.getStaticType(_staticTypeContext);
    var jsCondition = _visitExpression(condition);

    if (conditionType != _coreTypes.boolLegacyRawType &&
        conditionType != _coreTypes.boolNullableRawType &&
        conditionType != _coreTypes.boolNonNullableRawType) {
      jsCondition = runtimeCall('dtest(#)', [jsCondition]);
    } else if (isNullable(condition)) {
      jsCondition = runtimeCall('test(#)', [jsCondition]);
    }

    var encodedSource =
        node.enclosingComponent.uriToSource[node.location.file].source;
    var source = utf8.decode(encodedSource, allowMalformed: true);
    var conditionSource =
        source.substring(node.conditionStartOffset, node.conditionEndOffset);
    var location = _toSourceLocation(node.conditionStartOffset);
    return js.statement(' if (!#) #.assertFailed(#, #, #, #, #);', [
      jsCondition,
      runtimeModule,
      if (node.message == null)
        js_ast.LiteralNull()
      else
        _visitExpression(node.message),
      _cacheUri(location.sourceUrl.toString()),
      // Lines and columns are typically printed with 1 based indexing.
      js.number(location.line + 1),
      js.number(location.column + 1),
      js.escapedString(conditionSource),
    ]);
  }

  static bool isBreakable(Statement stmt) {
    // These are conservatively the things that compile to things that can be
    // the target of a break without a label.
    return stmt is ForStatement ||
        stmt is WhileStatement ||
        stmt is DoStatement ||
        stmt is ForInStatement ||
        stmt is SwitchStatement;
  }

  @override
  js_ast.Statement visitLabeledStatement(LabeledStatement node) {
    List<LabeledStatement> saved;
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
        var labeled = target as LabeledStatement;
        statements.add(labeled);
        target = labeled.body;
      }
      for (var statement in statements) {
        _effectiveTargets[statement] = target;
      }

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
  js_ast.Statement visitBreakStatement(BreakStatement node) {
    // Switch statements with continue labels must explicitly break to their
    // implicit label due to their being wrapped in a loop.
    if (_inLabeledContinueSwitch &&
        _switchLabelStates.containsKey(node.target.body)) {
      return js_ast.Break(_switchLabelStates[node.target.body].label);
    }
    // Can it be compiled to a break without a label?
    if (_currentBreakTargets.contains(node.target)) {
      return js_ast.Break(null);
    }
    // Can it be compiled to a continue without a label?
    if (_currentContinueTargets.contains(node.target)) {
      return js_ast.Continue(null);
    }

    // Ensure the effective target is labeled.  Labels are named globally per
    // Kernel binary.
    //
    // TODO(markzipan): Retrieve the real label name with source offsets
    var target = _effectiveTargets[node.target];
    var name = _labelNames[target];
    if (name == null) _labelNames[target] = name = 'L${_labelNames.length}';

    // It is a break if the target labeled statement encloses the effective
    // target.
    Statement current = node.target;
    while (current is LabeledStatement) {
      current = (current as LabeledStatement).body;
    }
    if (identical(current, target)) {
      return js_ast.Break(name);
    }
    // Otherwise it is a continue.
    return js_ast.Continue(name);
  }

  // Labeled loop bodies can be the target of a continue without a label
  // (targeting the loop).  Find the outermost non-labeled statement starting
  // from body and record all the intermediate labeled statements as continue
  // targets.
  Statement _effectiveBodyOf(Statement loop, Statement body) {
    // In a loop whose body is not labeled, this list should be empty because
    // it is not possible to continue to an outer loop without a label.
    _currentContinueTargets = <LabeledStatement>[];
    while (body is LabeledStatement) {
      var labeled = body as LabeledStatement;
      _currentContinueTargets.add(labeled);
      _effectiveTargets[labeled] = loop;
      body = labeled.body;
    }
    return body;
  }

  T _translateLoop<T extends js_ast.Statement>(
      Statement node, T Function() action) {
    List<LabeledStatement> savedBreakTargets;
    if (_currentBreakTargets.isNotEmpty &&
        _effectiveTargets[_currentBreakTargets.first] != node) {
      // If breaking without a label targets some other (outer) loop, then
      // this loop prevents breaking to that loop without a label.  This loop
      // was not labeled for a break in Kernel, otherwise it would be the
      // effective target of the current break targets, so it is not itself the
      // target of a break.
      savedBreakTargets = _currentBreakTargets;
      _currentBreakTargets = <LabeledStatement>[];
    }
    var savedContinueTargets = _currentContinueTargets;
    var result = action();
    if (savedBreakTargets != null) _currentBreakTargets = savedBreakTargets;
    _currentContinueTargets = savedContinueTargets;
    return result;
  }

  @override
  js_ast.While visitWhileStatement(WhileStatement node) {
    return _translateLoop(node, () {
      var condition = _visitTest(node.condition);
      var body = _visitScope(_effectiveBodyOf(node, node.body));
      return js_ast.While(condition, body);
    });
  }

  @override
  js_ast.Do visitDoStatement(DoStatement node) {
    return _translateLoop(node, () {
      var body = _visitScope(_effectiveBodyOf(node, node.body));
      var condition = _visitTest(node.condition);
      return js_ast.Do(body, condition);
    });
  }

  @override
  js_ast.For visitForStatement(ForStatement node) {
    return _translateLoop(node, () {
      js_ast.VariableInitialization emitForInitializer(VariableDeclaration v) =>
          js_ast.VariableInitialization(_emitVariableDef(v),
              _visitInitializer(v.initializer, v.annotations));

      var init = node.variables.map(emitForInitializer).toList();
      var initList =
          init.isEmpty ? null : js_ast.VariableDeclarationList('let', init);
      var updates = node.updates;
      js_ast.Expression update;
      if (updates.isNotEmpty) {
        update = js_ast.Expression.binary(
                updates.map(_visitExpression).toList(), ',')
            .toVoidExpression();
      }
      var condition = _visitTest(node.condition);
      var body = _visitScope(_effectiveBodyOf(node, node.body));

      return js_ast.For(initList, condition, update, body);
    });
  }

  @override
  js_ast.Statement visitForInStatement(ForInStatement node) {
    return _translateLoop(node, () {
      if (node.isAsync) {
        return _emitAwaitFor(node);
      }

      var iterable = _visitExpression(node.iterable);
      var body = _visitScope(_effectiveBodyOf(node, node.body));

      var init = js.call('let #', _emitVariableDef(node.variable));
      if (_annotatedNullCheck(node.variable.annotations)) {
        body = js_ast.Block(
            [_nullParameterCheck(_emitVariableRef(node.variable)), body]);
      }

      if (variableIsReferenced(node.variable.name, iterable)) {
        var temp = _emitTemporaryId('iter');
        return js_ast.Block([
          iterable.toVariableDeclaration(temp),
          js_ast.ForOf(init, temp, body)
        ]);
      }
      return js_ast.ForOf(init, iterable, body);
    });
  }

  js_ast.Statement _emitAwaitFor(ForInStatement node) {
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
    var streamIterator = _coreTypes.rawType(
        _asyncStreamIteratorClass, currentLibrary.nonNullable);
    var createStreamIter = js_ast.Call(
        _emitConstructorName(
            streamIterator,
            _asyncStreamIteratorClass.procedures
                .firstWhere((p) => p.isFactory && p.name.text == '')),
        [_visitExpression(node.iterable)]);

    var iter = _emitTemporaryId('iter');
    return js.statement(
        '{'
        '  let # = #;'
        '  try {'
        '    while (#) { let # = #.current; #; }'
        '  } finally { #; }'
        '}',
        [
          iter,
          createStreamIter,
          js_ast.Yield(js.call('#.moveNext()', iter))
            ..sourceInformation = _nodeStart(node.variable),
          _emitVariableDef(node.variable),
          iter,
          _visitStatement(node.body),
          js_ast.Yield(js.call('#.cancel()', iter))
            ..sourceInformation = _nodeStart(node.variable)
        ]);
  }

  @override
  js_ast.Statement visitSwitchStatement(SwitchStatement node) {
    // Switches with labeled continues are generated as an infinite loop with
    // an explicit variable for holding the switch's next case state and an
    // explicit label. Any implicit breaks are made explicit (e.g., when break
    // is omitted for the final case statement).
    var previous = _inLabeledContinueSwitch;
    _inLabeledContinueSwitch = hasLabeledContinue(node);

    var cases = <js_ast.SwitchCase>[];

    if (_inLabeledContinueSwitch) {
      var labelState = _emitTemporaryId('labelState');
      // TODO(markzipan): Retrieve the real label name with source offsets
      var labelName = 'SL${_switchLabelStates.length}';
      _switchLabelStates[node] = _SwitchLabelState(labelName, labelState);

      for (var c in node.cases) {
        var subcases =
            _visitSwitchCase(c, lastSwitchCase: c == node.cases.last);
        if (subcases.isNotEmpty) cases.addAll(subcases);
      }

      var switchExpr = _visitExpression(node.expression);
      var switchStmt = js_ast.Switch(labelState, cases);
      var loopBody = js_ast.Block([switchStmt, js_ast.Break(null)]);
      var loopStmt = js_ast.While(js.boolean(true), loopBody);
      // Note: Cannot use _labelNames, as the label must be on the loop.
      // not the block surrounding the switch statement.
      var labeledStmt = js_ast.LabeledStatement(labelName, loopStmt);
      var block = js_ast.Block([
        js.statement('let # = #', [labelState, switchExpr]),
        labeledStmt
      ]);
      _inLabeledContinueSwitch = previous;
      return block;
    }

    for (var c in node.cases) {
      var subcases = _visitSwitchCase(c);
      if (subcases.isNotEmpty) cases.addAll(subcases);
    }

    var stmt = js_ast.Switch(_visitExpression(node.expression), cases);
    _inLabeledContinueSwitch = previous;
    return stmt;
  }

  /// Helper for visiting a SwitchCase statement.
  ///
  /// lastSwitchCase is only used when the current switch statement contains
  /// labeled continues. Dart permits the final case to implicitly break, but
  /// switch statements with labeled continues must explicitly break/continue
  /// to escape the surrounding infinite loop.
  List<js_ast.SwitchCase> _visitSwitchCase(SwitchCase node,
      {bool lastSwitchCase = false}) {
    var cases = <js_ast.SwitchCase>[];
    var emptyBlock = js_ast.Block.empty();
    // TODO(jmesserly): make sure we are statically checking fall through
    var body = _visitStatement(node.body).toBlock();
    var expressions = node.expressions;
    var lastExpr =
        expressions.isNotEmpty && !node.isDefault ? expressions.last : null;
    for (var e in expressions) {
      var jsExpr = _visitExpression(e);
      cases.add(js_ast.SwitchCase(jsExpr, e == lastExpr ? body : emptyBlock));
    }
    if (node.isDefault) {
      cases.add(js_ast.SwitchCase.defaultCase(body));
    }
    // Switch statements with continue labels must explicitly break from their
    // last case to escape the additional loop around the switch.
    if (lastSwitchCase && _inLabeledContinueSwitch && cases.isNotEmpty) {
      // TODO(markzipan): avoid generating unreachable breaks
      assert(_switchLabelStates.containsKey(node.parent));
      var breakStmt = js_ast.Break(_switchLabelStates[node.parent].label);
      var switchBody = js_ast.Block(cases.last.body.statements..add(breakStmt));
      var updatedSwitch = js_ast.SwitchCase(cases.last.expression, switchBody);
      cases.removeLast();
      cases.add(updatedSwitch);
    }
    return cases;
  }

  @override
  js_ast.Statement visitContinueSwitchStatement(ContinueSwitchStatement node) {
    var switchStmt = node.target.parent;
    if (_inLabeledContinueSwitch &&
        _switchLabelStates.containsKey(switchStmt)) {
      var switchState = _switchLabelStates[switchStmt];
      // Use the first constant expression that can match the collated switch
      // case. Use an unused symbol otherwise to force the default case.
      var jsExpr = node.target.expressions.isEmpty
          ? js.call("Symbol('_default')", [])
          : _visitExpression(node.target.expressions[0]);
      var setStateStmt = js.statement('# = #', [switchState.variable, jsExpr]);
      var continueStmt = js_ast.Continue(switchState.label);
      return js_ast.Block([setStateStmt, continueStmt]);
    }
    return _emitInvalidNode(
            node, 'see https://github.com/dart-lang/sdk/issues/29352')
        .toStatement();
  }

  @override
  js_ast.Statement visitIfStatement(IfStatement node) {
    return js_ast.If(_visitTest(node.condition), _visitScope(node.then),
        _visitScope(node.otherwise));
  }

  /// Visits a statement, and ensures the resulting AST handles block scope
  /// correctly. Essentially, we need to promote a variable declaration
  /// statement into a block in some cases, e.g.
  ///
  ///     do var x = 5; while (false); // Dart
  ///     do { let x = 5; } while (false); // JS
  js_ast.Statement _visitScope(Statement stmt) {
    var result = _visitStatement(stmt);
    if (result is js_ast.ExpressionStatement &&
        result.expression is js_ast.VariableDeclarationList) {
      return js_ast.Block([result]);
    }
    return result;
  }

  @override
  js_ast.Statement visitReturnStatement(ReturnStatement node) {
    return super.emitReturnStatement(_visitExpression(node.expression));
  }

  @override
  js_ast.Statement visitTryCatch(TryCatch node) {
    return js_ast.Try(
        _visitStatement(node.body).toBlock(), _visitCatch(node.catches), null);
  }

  js_ast.Catch _visitCatch(List<Catch> clauses) {
    if (clauses.isEmpty) return null;

    var caughtError = VariableDeclaration('#e');
    var savedRethrow = _rethrowParameter;
    _rethrowParameter = caughtError;

    // If we have more than one catch clause, always create a temporary so we
    // don't shadow any names.
    var exceptionParameter =
        (clauses.length == 1 ? clauses[0].exception : null) ??
            VariableDeclaration('#ex');

    var stackTraceParameter =
        (clauses.length == 1 ? clauses[0].stackTrace : null) ??
            (clauses.any((c) => c.stackTrace != null)
                ? VariableDeclaration('#st')
                : null);

    js_ast.Statement catchBody = js_ast.Throw(_emitVariableRef(caughtError));
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(
          clause, catchBody, exceptionParameter, stackTraceParameter);
    }
    var catchStatements = [
      js.statement('let # = #.getThrown(#)', [
        _emitVariableDef(exceptionParameter),
        runtimeModule,
        _emitVariableRef(caughtError)
      ]),
      if (stackTraceParameter != null)
        js.statement('let # = #.stackTrace(#)', [
          _emitVariableDef(stackTraceParameter),
          runtimeModule,
          _emitVariableRef(caughtError)
        ]),
      catchBody,
    ];
    _rethrowParameter = savedRethrow;
    return js_ast.Catch(
        _emitVariableDef(caughtError), js_ast.Block(catchStatements));
  }

  js_ast.Statement _catchClauseGuard(
      Catch node,
      js_ast.Statement otherwise,
      VariableDeclaration exceptionParameter,
      VariableDeclaration stackTraceParameter) {
    var body = <js_ast.Statement>[];
    var vars = HashSet<String>();

    void declareVariable(
        VariableDeclaration variable, VariableDeclaration value) {
      if (variable == null) return;
      vars.add(variable.name);
      if (variable.name != value.name) {
        body.add(js.statement('let # = #',
            [_emitVariableDef(variable), _emitVariableRef(value)]));
      }
    }

    declareVariable(node.exception, exceptionParameter);
    declareVariable(node.stackTrace, stackTraceParameter);

    body.add(_visitStatement(node.body).toScopedBlock(vars));
    var then = js_ast.Block(body);

    // Discard following clauses, if any, as they are unreachable.
    if (_types.isTop(node.guard)) return then;

    var condition =
        _emitIsExpression(VariableGet(exceptionParameter), node.guard);
    return js_ast.If(condition, then, otherwise)
      ..sourceInformation = _nodeStart(node);
  }

  @override
  js_ast.Statement visitTryFinally(TryFinally node) {
    var body = _visitStatement(node.body);
    var finallyBlock =
        _superDisallowed(() => _visitStatement(node.finalizer).toBlock());

    if (body is js_ast.Try && body.finallyPart == null) {
      // Kernel represents Dart try/catch/finally as try/catch nested inside of
      // try/finally.  Flatten that pattern in the output into JS try/catch/
      // finally.
      return js_ast.Try(body.body, body.catchPart, finallyBlock);
    }
    return js_ast.Try(body.toBlock(), null, finallyBlock);
  }

  @override
  js_ast.Statement visitYieldStatement(YieldStatement node) {
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
      return js.statement('{ if(#.#(#)) return; #; }', [
        _asyncStarController,
        helperName,
        jsExpr,
        js_ast.Yield(null)..sourceInformation = _nodeStart(node)
      ]);
    }
    // A normal yield in a sync*
    return jsExpr.toYieldStatement(star: star);
  }

  @override
  js_ast.Statement visitVariableDeclaration(VariableDeclaration node) {
    // TODO(jmesserly): casts are sometimes required here.
    // Kernel does not represent these explicitly.
    var v = _emitVariableDef(node);
    return js.statement('let # = #;',
        [v, _visitInitializer(node.initializer, node.annotations)]);
  }

  @override
  js_ast.Statement visitFunctionDeclaration(FunctionDeclaration node) {
    var func = node.function;
    var fn = _emitFunction(func, node.variable.name);

    var name = _emitVariableDef(node.variable);
    js_ast.Statement declareFn;
    declareFn = toBoundFunctionStatement(fn, name);
    if (_reifyFunctionType(func)) {
      declareFn = js_ast.Block([
        declareFn,
        _emitFunctionTagged(_emitVariableRef(node.variable),
                func.computeThisFunctionType(_currentLibrary.nonNullable))
            .toStatement()
      ]);
    }
    return declareFn;
  }

  @override
  js_ast.Expression defaultExpression(Expression node) =>
      _emitInvalidNode(node);

  @override
  js_ast.Expression defaultBasicLiteral(BasicLiteral node) =>
      defaultExpression(node);

  @override
  js_ast.Expression visitInvalidExpression(InvalidExpression node) =>
      defaultExpression(node);

  @override
  js_ast.Expression visitConstantExpression(ConstantExpression node) =>
      visitConstant(node.constant);

  @override
  js_ast.Expression canonicalizeConstObject(js_ast.Expression expr) {
    if (isSdkInternalRuntime(_currentLibrary)) {
      return super.canonicalizeConstObject(expr);
    }
    return runtimeCall('const(#)', [expr]);
  }

  @override
  js_ast.Expression visitVariableGet(VariableGet node) {
    var v = node.variable;
    var id = _emitVariableRef(v);
    if (id.name == v.name) {
      id.sourceInformation = _variableSpan(node.fileOffset, v.name.length);
    }
    return id;
  }

  js_ast.Identifier _emitVariableRef(VariableDeclaration v) {
    var name = v.name;
    if (name == null || name.startsWith('#')) {
      name = name == null ? 't${_tempVariables.length}' : name.substring(1);
      return _tempVariables.putIfAbsent(v, () => _emitTemporaryId(name));
    }
    return _emitIdentifier(name);
  }

  /// Emits the declaration of a variable.
  ///
  /// This is similar to [_emitVariableRef] but it also attaches source
  /// location information, so hover will work as expected.
  js_ast.Identifier _emitVariableDef(VariableDeclaration v) {
    return _emitVariableRef(v)..sourceInformation = _nodeStart(v);
  }

  js_ast.Statement _initLetVariables() {
    if (_letVariables.isEmpty) return null;
    var result = js_ast.VariableDeclarationList(
            'let',
            _letVariables
                .map((v) => js_ast.VariableInitialization(v, null))
                .toList())
        .toStatement();
    _letVariables.clear();
    return result;
  }

  // TODO(jmesserly): resugar operators for kernel, such as ++x, x++, x+=.
  @override
  js_ast.Expression visitVariableSet(VariableSet node) =>
      _visitExpression(node.value)
          .toAssignExpression(_emitVariableRef(node.variable));

  @override
  js_ast.Expression visitDynamicGet(DynamicGet node) {
    return _emitPropertyGet(node.receiver, null, node.name.name);
  }

  @override
  js_ast.Expression visitInstanceGet(InstanceGet node) {
    return _emitPropertyGet(
        node.receiver, node.interfaceTarget, node.name.name);
  }

  @override
  js_ast.Expression visitInstanceTearOff(InstanceTearOff node) {
    return _emitPropertyGet(
        node.receiver, node.interfaceTarget, node.name.name);
  }

  @override
  js_ast.Expression visitPropertyGet(PropertyGet node) {
    return _emitPropertyGet(
        node.receiver, node.interfaceTarget, node.name.text);
  }

  @override
  js_ast.Expression visitDynamicSet(DynamicSet node) {
    return _emitPropertySet(node.receiver, null, node.value, node.name.text);
  }

  @override
  js_ast.Expression visitInstanceSet(InstanceSet node) {
    return _emitPropertySet(
        node.receiver, node.interfaceTarget, node.value, node.name.text);
  }

  @override
  js_ast.Expression visitPropertySet(PropertySet node) {
    return _emitPropertySet(
        node.receiver, node.interfaceTarget, node.value, node.name.text);
  }

  js_ast.Expression _emitPropertyGet(Expression receiver, Member member,
      [String memberName]) {
    memberName ??= member.name.text;
    // TODO(jmesserly): should tearoff of `.call` on a function type be
    // encoded as a different node, or possibly eliminated?
    // (Regardless, we'll still need to handle the callable JS interop classes.)
    if (memberName == 'call' &&
        _isDirectCallable(receiver.getStaticType(_staticTypeContext))) {
      // Tearoff of `call` on a function type is a no-op;
      return _visitExpression(receiver);
    }
    var jsName = _emitMemberName(memberName, member: member);
    var jsReceiver = _visitExpression(receiver);

    // TODO(jmesserly): we need to mark an end span for property accessors so
    // they can be hovered. Unfortunately this is not possible as Kernel does
    // not store this data.
    if (_isObjectMember(memberName)) {
      if (isNullable(receiver)) {
        // If the receiver is nullable, use a helper so calls like
        // `null.hashCode` and `null.runtimeType` will work.
        // Also method tearoffs like `null.toString`.
        if (_isObjectMethodTearoff(memberName)) {
          return runtimeCall('bind(#, #)', [jsReceiver, jsName]);
        }
        return runtimeCall('#(#)', [memberName, jsReceiver]);
      }
      // Otherwise generate this as a normal typed property get.
    } else if (member == null) {
      return runtimeCall('dload$_replSuffix(#, #)', [jsReceiver, jsName]);
    }

    if (_reifyTearoff(member)) {
      return runtimeCall('bind(#, #)', [jsReceiver, jsName]);
    } else if (member is Procedure &&
        !member.isAccessor &&
        isJsMember(member)) {
      return runtimeCall(
          'tearoffInterop(#)', [js_ast.PropertyAccess(jsReceiver, jsName)]);
    } else {
      return js_ast.PropertyAccess(jsReceiver, jsName);
    }
  }

  /// Return whether [member] returns a native object whose type needs to be
  /// null-checked in sound null-safety.
  ///
  /// This is true for non-nullable native return types.
  bool _isNullCheckableNative(Member member) =>
      _options.soundNullSafety &&
      member != null &&
      member.isExternal &&
      _extensionTypes.isNativeClass(member.enclosingClass) &&
      member is Procedure &&
      member.function != null &&
      member.function.returnType.isPotentiallyNonNullable &&
      _isWebLibrary(member.enclosingLibrary?.importUri);

  // TODO(jmesserly): can we encapsulate REPL name lookups and remove this?
  // _emitMemberName would be a nice place to handle it, but we don't have
  // access to the target expression there (needed for `dart.replNameLookup`).
  String get _replSuffix => _options.replCompile ? 'Repl' : '';

  js_ast.Expression _emitPropertySet(
      Expression receiver, Member member, Expression value,
      [String memberName]) {
    var jsName =
        _emitMemberName(memberName ?? member.name.text, member: member);

    if (member != null && isJsMember(member)) {
      value = _assertInterop(value);
    }

    var jsReceiver = _visitExpression(receiver);
    var jsValue = _visitExpression(value);

    if (member == null) {
      return runtimeCall(
          'dput$_replSuffix(#, #, #)', [jsReceiver, jsName, jsValue]);
    }
    return js.call('#.# = #', [jsReceiver, jsName, jsValue]);
  }

  @override
  js_ast.Expression visitSuperPropertyGet(SuperPropertyGet node) {
    var target = node.interfaceTarget;
    var jsTarget = _emitSuperTarget(target);
    if (_reifyTearoff(target)) {
      return runtimeCall('bind(this, #, #)', [jsTarget.selector, jsTarget]);
    }
    return jsTarget;
  }

  @override
  js_ast.Expression visitSuperPropertySet(SuperPropertySet node) {
    var target = node.interfaceTarget;
    var jsTarget = _emitSuperTarget(target, setter: true);
    return _visitExpression(node.value).toAssignExpression(jsTarget);
  }

  @override
  js_ast.Expression visitStaticGet(StaticGet node) =>
      _emitStaticGet(node.target);

  @override
  js_ast.Expression visitStaticTearOff(StaticTearOff node) =>
      _emitStaticGet(node.target);

  js_ast.Expression _emitStaticGet(Member target) {
    var result = _emitStaticTarget(target);
    if (_reifyTearoff(target)) {
      // TODO(jmesserly): we could tag static/top-level function types once
      // in the module initialization, rather than at the point where they
      // escape.
      return _emitFunctionTagged(
          result,
          target.function
              .computeThisFunctionType(target.enclosingLibrary.nonNullable));
    }
    return result;
  }

  @override
  js_ast.Expression visitStaticSet(StaticSet node) {
    var target = node.target;
    var value = isJsMember(target) ? _assertInterop(node.value) : node.value;
    return _visitExpression(value)
        .toAssignExpression(_emitStaticTarget(target));
  }

  @override
  js_ast.Expression visitDynamicInvocation(DynamicInvocation node) {
    return _emitMethodCall(node.receiver, null, node.arguments, node);
  }

  @override
  js_ast.Expression visitFunctionInvocation(FunctionInvocation node) {
    return _emitMethodCall(node.receiver, null, node.arguments, node);
  }

  @override
  js_ast.Expression visitInstanceInvocation(InstanceInvocation node) {
    return _emitMethodCall(
        node.receiver, node.interfaceTarget, node.arguments, node);
  }

  @override
  js_ast.Expression visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    return _emitMethodCall(
        VariableGet(node.variable)..fileOffset = node.fileOffset,
        null,
        node.arguments,
        node);
  }

  @override
  js_ast.Expression visitEqualsCall(EqualsCall node) {
    return _emitEqualityOperator(node.left, node.interfaceTarget, node.right,
        negated: node.isNot);
  }

  @override
  js_ast.Expression visitEqualsNull(EqualsNull node) {
    return _emitCoreIdenticalCall([node.expression, NullLiteral()],
        negated: node.isNot);
  }

  @override
  js_ast.Expression visitMethodInvocation(MethodInvocation node) {
    return _emitMethodCall(
        node.receiver, node.interfaceTarget, node.arguments, node);
  }

  js_ast.Expression _emitMethodCall(Expression receiver, Member target,
      Arguments arguments, InvocationExpression node) {
    var name = node.name.text;

    /// Returns `true` when [node] represents an invocation of `List.add()` that
    /// can be optimized.
    ///
    /// The optimized add operation can skip checks for a growable or modifiable
    /// list and the element type is known to be invariant so it can skip the
    /// type check.
    bool isNativeListInvariantAdd(InvocationExpression node) {
      if (node is MethodInvocation &&
          node.isInvariant &&
          node.name.name == 'add') {
        // The call to add is marked as invariant, so the type check on the
        // parameter to add is not needed.
        var receiver = node.receiver;
        if (receiver is VariableGet &&
            receiver.variable.isFinal &&
            !receiver.variable.isLate) {
          // The receiver is a final variable, so it only contains the
          // initializer value. Also, avoid late variables in case the CFE
          // lowering of late variables is changed in the future.
          if (receiver.variable.initializer is ListLiteral) {
            // The initializer is a list literal, so we know the list can be
            // grown, modified, and is represented by a JavaScript Array.
            return true;
          }
        }
      }
      return false;
    }

    if (isOperatorMethodName(name) && arguments.named.isEmpty) {
      var argLength = arguments.positional.length;
      if (argLength == 0) {
        return _emitUnaryOperator(receiver, target, node);
      } else if (argLength == 1) {
        return _emitBinaryOperator(
            receiver, target, arguments.positional[0], node);
      }
    }

    var jsReceiver = _visitExpression(receiver);
    var args = _emitArgumentList(arguments, target: target);

    if (isNativeListInvariantAdd(node)) {
      return js.call('#.push(#)', [jsReceiver, args]);
    }

    var isCallingDynamicField = target is Member &&
        target.hasGetter &&
        _isDynamicOrFunction(target.getterType);
    if (name == 'call') {
      var receiverType = receiver.getStaticType(_staticTypeContext);
      if (isCallingDynamicField || _isDynamicOrFunction(receiverType)) {
        return _emitDynamicInvoke(jsReceiver, null, args, arguments);
      } else if (_isDirectCallable(receiverType)) {
        // Call methods on function types should be handled as function calls.
        return js_ast.Call(jsReceiver, args);
      }
    }

    var jsName = _emitMemberName(name, member: target);

    // Handle Object methods that are supported by `null`.
    if (_isObjectMethodCall(name, arguments)) {
      if (isNullable(receiver)) {
        // If the receiver is nullable, use a helper so calls like
        // `null.toString()` will work.
        return runtimeCall('#(#, #)', [name, jsReceiver, args]);
      }
      // Otherwise generate this as a normal typed method call.
    } else if (target == null || isCallingDynamicField) {
      return _emitDynamicInvoke(jsReceiver, jsName, args, arguments);
    }
    // TODO(jmesserly): remove when Kernel desugars this for us.
    // Handle `o.m(a)` where `o.m` is a getter returning a class with `call`.
    if (target is Field || target is Procedure && target.isAccessor) {
      var fromType = target.getterType;
      if (fromType is InterfaceType) {
        var callName = _implicitCallTarget(fromType);
        if (callName != null) {
          return js.call('#.#.#(#)', [jsReceiver, jsName, callName, args]);
        }
      }
    }
    return js.call('#.#(#)', [jsReceiver, jsName, args]);
  }

  js_ast.Expression _emitDynamicInvoke(
      js_ast.Expression fn,
      js_ast.Expression methodName,
      Iterable<js_ast.Expression> args,
      Arguments arguments) {
    var jsArgs = <Object>[fn];
    String jsCode;

    var typeArgs = arguments.types;
    if (typeArgs.isNotEmpty) {
      jsArgs.add(args.take(typeArgs.length));
      args = args.skip(typeArgs.length);
      if (methodName != null) {
        jsCode = 'dgsend$_replSuffix(#, [#], #';
        jsArgs.add(methodName);
      } else {
        jsCode = 'dgcall(#, [#]';
      }
    } else if (methodName != null) {
      jsCode = 'dsend$_replSuffix(#, #';
      jsArgs.add(methodName);
    } else {
      jsCode = 'dcall(#';
    }

    var hasNamed = arguments.named.isNotEmpty;
    if (hasNamed) {
      jsCode += ', [#], #)';
      jsArgs.add(args.take(args.length - 1));
      jsArgs.add(args.last);
    } else {
      jsArgs.add(args);
      jsCode += ', [#])';
    }

    return runtimeCall(jsCode, jsArgs);
  }

  bool _isDirectCallable(DartType t) =>
      t is FunctionType || (t is InterfaceType && usesJSInterop(t.classNode));

  js_ast.Expression _implicitCallTarget(InterfaceType from) {
    var c = from.classNode;
    var member = _hierarchy.getInterfaceMember(c, Name('call'));
    if (member is Procedure && !member.isAccessor && !usesJSInterop(c)) {
      return _emitMemberName('call', member: member);
    }
    return null;
  }

  bool _isDynamicOrFunction(DartType t) =>
      DartTypeEquivalence(_coreTypes, ignoreTopLevelNullability: true)
          .areEqual(t, _coreTypes.functionNonNullableRawType) ||
      t == const DynamicType();

  js_ast.Expression _emitUnaryOperator(
      Expression expr, Member target, InvocationExpression node) {
    var op = node.name.text;
    if (target != null) {
      var dispatchType = _coreTypes.legacyRawType(target.enclosingClass);
      if (_typeRep.unaryOperationIsPrimitive(dispatchType)) {
        if (op == '~') {
          if (_typeRep.isNumber(dispatchType)) {
            return _coerceBitOperationResultToUnsigned(
                node, js.call('~#', notNull(expr)));
          }
          return _emitOperatorCall(expr, target, op, []);
        }
        if (op == 'unary-') op = '-';
        return js.call('$op#', notNull(expr));
      }
    }
    return _emitOperatorCall(expr, target, op, []);
  }

  /// Bit operations are coerced to values on [0, 2^32). The coercion changes
  /// the interpretation of the 32-bit value from signed to unsigned.  Most
  /// JavaScript operations interpret their operands as signed and generate
  /// signed results.
  js_ast.Expression _coerceBitOperationResultToUnsigned(
      Expression node, js_ast.Expression uncoerced) {
    // Don't coerce if the parent will coerce.
    var parent = node.parent;
    if (parent is InvocationExpression && _nodeIsBitwiseOperation(parent)) {
      return uncoerced;
    }

    // Don't do a no-op coerce if the most significant bit is zero.
    if (_is31BitUnsigned(node)) return uncoerced;

    // If the consumer of the expression is '==' or '!=' with a constant that
    // fits in 31 bits, adding a coercion does not change the result of the
    // comparison, e.g.  `a & ~b == 0`.
    Expression left;
    Expression right;
    String op;
    if (parent is InvocationExpression &&
        parent.arguments.positional.length == 1) {
      op = parent.name.text;
      left = getInvocationReceiver(parent);
      right = parent.arguments.positional[0];
    } else if (parent is EqualsCall) {
      left = parent.left;
      right = parent.right;
      op = '==';
    } else if (parent is EqualsNull) {
      left = parent.expression;
      right = NullLiteral();
      op = '==';
    }
    if (left != null) {
      if (op == '==') {
        const MAX = 0x7fffffff;
        if (_asIntInRange(right, 0, MAX) != null) return uncoerced;
        if (_asIntInRange(left, 0, MAX) != null) return uncoerced;
      } else if (op == '>>') {
        if (_isDefinitelyNonNegative(left) &&
            _asIntInRange(right, 0, 31) != null) {
          // Parent will generate `# >>> n`.
          return uncoerced;
        }
      }
    }
    return js.call('# >>> 0', uncoerced);
  }

  bool _nodeIsBitwiseOperation(InvocationExpression node) {
    switch (node.name.text) {
      case '&':
      case '|':
      case '^':
      case '~':
        return true;
    }
    return false;
  }

  int _asIntInRange(Expression expr, int low, int high) {
    if (expr is IntLiteral) {
      if (expr.value >= low && expr.value <= high) return expr.value;
      return null;
    }
    if (_constants.isConstant(expr)) {
      var c = _constants.evaluate(expr);
      if (c is IntConstant && c.value >= low && c.value <= high) return c.value;
    }
    return null;
  }

  bool _isDefinitelyNonNegative(Expression expr) {
    if (expr is IntLiteral) return expr.value >= 0;

    // TODO(sra): Lengths of known list types etc.
    return expr is InvocationExpression && _nodeIsBitwiseOperation(expr);
  }

  /// Does the parent of [node] mask the result to [width] bits or fewer?
  bool _parentMasksToWidth(Expression node, int width) {
    var parent = node.parent;
    if (parent == null) return false;
    if (parent is InvocationExpression && _nodeIsBitwiseOperation(parent)) {
      if (parent.name.text == '&' && parent.arguments.positional.length == 1) {
        var left = getInvocationReceiver(parent);
        var right = parent.arguments.positional[0];
        final MAX = (1 << width) - 1;
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
    const MAX = 32; // Includes larger and negative values.
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
          switch (expr.name.text) {
            case '&':
              return min(bitWidth(left, depth), bitWidth(right, depth));

            case '|':
            case '^':
              return max(bitWidth(left, depth), bitWidth(right, depth));

            case '>>':
              var shiftValue = _asIntInRange(right, 0, 31);
              if (shiftValue != null) {
                var leftWidth = bitWidth(left, depth);
                return leftWidth == MAX ? MAX : max(0, leftWidth - shiftValue);
              }
              return MAX;

            case '<<':
              var leftWidth = bitWidth(left, depth);
              var shiftValue = _asIntInRange(right, 0, 31);
              if (shiftValue != null) {
                return min(MAX, leftWidth + shiftValue);
              }
              var rightWidth = bitWidth(right, depth);
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
      var value = _asIntInRange(expr, 0, 0x7fffffff);
      if (value != null) return value.bitLength;
      return MAX;
    }

    return bitWidth(expr, 0) < 32;
  }

  js_ast.Expression _emitBinaryOperator(Expression left, Member target,
      Expression right, InvocationExpression node) {
    var op = node.name.text;
    if (op == '==') return _emitEqualityOperator(left, target, right);

    // TODO(jmesserly): using the target type here to work around:
    // https://github.com/dart-lang/sdk/issues/33293
    if (target != null) {
      var targetClass = target.enclosingClass;
      var leftType = _coreTypes.legacyRawType(targetClass);
      var rightType = right.getStaticType(_staticTypeContext);

      if (_typeRep.binaryOperationIsPrimitive(leftType, rightType) ||
          leftType == _types.coreTypes.stringLegacyRawType && op == '+') {
        // Inline operations on primitive types where possible.
        // TODO(jmesserly): inline these from dart:core instead of hardcoding
        // the implementation details here.

        /// Emits an inlined binary operation using the JS [code], adding null
        /// checks if needed to ensure we throw the appropriate error.
        js_ast.Expression binary(String code) {
          return js.call(code, [notNull(left), notNull(right)]);
        }

        js_ast.Expression bitwise(String code) {
          return _coerceBitOperationResultToUnsigned(node, binary(code));
        }

        /// Similar to [binary] but applies a boolean conversion to the right
        /// operand, to match the boolean bitwise operators in dart:core.
        ///
        /// Short circuiting operators should not be used in [code], because the
        /// null checks for both operands must happen unconditionally.
        js_ast.Expression bitwiseBool(String code) {
          return js.call(code, [notNull(left), _visitTest(right)]);
        }

        switch (op) {
          case '~/':
            // `a ~/ b` is equivalent to `(a / b).truncate()`
            return js.call('(# / #).#()', [
              notNull(left),
              notNull(right),
              _emitMemberName('truncate', memberClass: targetClass)
            ]);

          case '%':
            // TODO(sra): We can generate `a % b + 0` if both are non-negative
            // (the `+ 0` is to coerce -0.0 to 0).
            return _emitOperatorCall(left, target, op, [right]);

          case '&':
            return _typeRep.isBoolean(leftType)
                ? bitwiseBool('!!(# & #)')
                : bitwise('# & #');

          case '|':
            return _typeRep.isBoolean(leftType)
                ? bitwiseBool('!!(# | #)')
                : bitwise('# | #');

          case '^':
            return _typeRep.isBoolean(leftType)
                ? bitwiseBool('# !== #')
                : bitwise('# ^ #');

          case '>>':
            var shiftCount = _asIntInRange(right, 0, 31);
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
            return _emitOperatorCall(left, target, op, [right]);

          case '<<':
            if (_is31BitUnsigned(node)) {
              // Result is 31 bit unsigned which implies the shift count was small
              // enough not to pollute the sign bit.
              return binary('# << #');
            }
            if (_asIntInRange(right, 0, 31) != null) {
              return _coerceBitOperationResultToUnsigned(
                  node, binary('# << #'));
            }
            return _emitOperatorCall(left, target, op, [right]);

          default:
            // TODO(vsm): When do Dart ops not map to JS?
            return binary('# $op #');
        }
      }
    }

    return _emitOperatorCall(left, target, op, [right]);
  }

  js_ast.Expression _emitEqualityOperator(
      Expression left, Member target, Expression right,
      {bool negated = false}) {
    var targetClass = target?.enclosingClass;
    var leftType = targetClass != null
        ? _coreTypes.legacyRawType(targetClass)
        : left.getStaticType(_staticTypeContext);

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
    //
    // If we know that the left type uses identity for equality, we can
    // sometimes emit better code, either `===` or `==`.
    var isEnum = leftType is InterfaceType && leftType.classNode.isEnum;
    var usesIdentity = _typeRep.isPrimitive(leftType) ||
        isEnum ||
        _isNull(left) ||
        _isNull(right);

    if (usesIdentity) {
      return _emitCoreIdenticalCall([left, right], negated: negated);
    }

    // If the left side is nullable, we need to use a runtime helper to check
    // for null. We could inline the null check, but it did not seem to have
    // a measurable performance effect (possibly the helper is simple enough to
    // be inlined).
    if (isNullable(left)) {
      return js.call(negated ? '!#.equals(#, #)' : '#.equals(#, #)',
          [runtimeModule, _visitExpression(left), _visitExpression(right)]);
    }

    // Otherwise we emit a call to the == method.
    return js.call(negated ? '!#[#](#)' : '#[#](#)', [
      _visitExpression(left),
      _emitMemberName('==', memberClass: targetClass),
      _visitExpression(right)
    ]);
  }

  /// Emits a generic send, like an operator method.
  ///
  /// **Please note** this function does not support method invocation syntax
  /// `obj.name(args)` because that could be a getter followed by a call.
  /// See [visitMethodInvocation].
  js_ast.Expression _emitOperatorCall(
      Expression receiver, Member target, String name, List<Expression> args) {
    // TODO(jmesserly): calls that don't pass `element` are probably broken for
    // `super` calls from disallowed super locations.
    var memberName = _emitMemberName(name, member: target);
    if (target == null) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': 'dindex', '[]=': 'dsetindex'}[name];
      if (dynamicHelper != null) {
        return runtimeCall('$dynamicHelper(#, #)',
            [_visitExpression(receiver), _visitExpressionList(args)]);
      } else {
        return runtimeCall('dsend(#, #, [#])', [
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
  js_ast.Expression visitSuperMethodInvocation(SuperMethodInvocation node) {
    var target = node.interfaceTarget;
    return js_ast.Call(_emitSuperTarget(target),
        _emitArgumentList(node.arguments, target: target));
  }

  /// Emits the [js_ast.PropertyAccess] for accessors or method calls to
  /// [jsTarget].[jsName], replacing `super` if it is not allowed in scope.
  js_ast.PropertyAccess _emitSuperTarget(Member member, {bool setter = false}) {
    var jsName = _emitMemberName(member.name.text, member: member);
    if (member is Field && !_virtualFields.isVirtual(member)) {
      return js_ast.PropertyAccess(js_ast.This(), jsName);
    }
    if (_superAllowed) return js_ast.PropertyAccess(js_ast.Super(), jsName);

    // If we can't emit `super` in this context, generate a helper that does it
    // for us, and call the helper.
    var name = member.name.text;
    var jsMethod = _superHelpers.putIfAbsent(name, () {
      var isAccessor = member is Procedure ? member.isAccessor : true;
      if (isAccessor) {
        assert(member is Procedure
            ? member.isSetter == setter
            : !setter || !(member as Field).isFinal);
        var fn = js.fun(
            setter
                ? 'function(x) { super[#] = x; }'
                : 'function() { return super[#]; }',
            [jsName]);

        return js_ast.Method(_emitTemporaryId(name), fn,
            isGetter: !setter, isSetter: setter);
      } else {
        var function = member.function;
        var params = [
          ..._emitTypeFormals(function.typeParameters),
          for (var param in function.positionalParameters)
            _emitIdentifier(param.name),
          if (function.namedParameters.isNotEmpty) namedArgumentTemp,
        ];

        var fn = js.fun(
            'function(#) { return super[#](#); }', [params, jsName, params]);
        name = js_ast.friendlyNameForDartOperator[name] ?? name;
        return js_ast.Method(_emitTemporaryId(name), fn);
      }
    });
    return js_ast.PropertyAccess(js_ast.This(), jsMethod.name);
  }

  @override
  js_ast.Expression visitStaticInvocation(StaticInvocation node) {
    var target = node.target;
    if (isInlineJS(target)) return _emitInlineJSCode(node) as js_ast.Expression;
    if (target.isFactory) return _emitFactoryInvocation(node);

    // Optimize some internal SDK calls.
    if (isSdkInternalRuntime(target.enclosingLibrary)) {
      var name = target.name.text;
      if (node.arguments.positional.isEmpty) {
        if (name == 'typeRep') {
          return _emitType(node.arguments.types.single);
        }
        if (name == 'legacyTypeRep') {
          return _emitType(node.arguments.types.single
              .withDeclaredNullability(Nullability.legacy));
        }
      } else if (node.arguments.positional.length == 1) {
        var firstArg = node.arguments.positional[0];
        if (name == 'getGenericClass' && firstArg is TypeLiteral) {
          var type = firstArg.type;
          if (type is InterfaceType) {
            return _emitTopLevelNameNoInterop(type.classNode, suffix: '\$');
          }
          if (type is FutureOrType) {
            return _emitFutureOrNameNoInterop(suffix: '\$');
          }
        }
        if (name == 'unwrapType' && firstArg is TypeLiteral) {
          return _emitType(firstArg.type);
        }
        if (name == 'extensionSymbol' && firstArg is StringLiteral) {
          return getSymbol(getExtensionSymbolInternal(firstArg.value));
        }

        if (name == 'compileTimeFlag' && firstArg is StringLiteral) {
          var flagName = firstArg.value;
          if (flagName == 'soundNullSafety') {
            return js.boolean(_options.soundNullSafety);
          }
          throw UnsupportedError('Invalid flag in call to $name: $flagName');
        }
      } else if (node.arguments.positional.length == 2) {
        var firstArg = node.arguments.positional[0];
        var secondArg = node.arguments.positional[1];
        if (name == '_jsInstanceOf' && secondArg is TypeLiteral) {
          return js.call('# instanceof #', [
            _visitExpression(firstArg),
            _emitType(
                secondArg.type.withDeclaredNullability(Nullability.nonNullable))
          ]);
        }

        if (name == '_equalType' && secondArg is TypeLiteral) {
          return js.call('# === #', [
            _visitExpression(firstArg),
            _emitType(
                secondArg.type.withDeclaredNullability(Nullability.nonNullable))
          ]);
        }
      }
    }
    if (target == _coreTypes.identicalProcedure) {
      return _emitCoreIdenticalCall(node.arguments.positional);
    }
    if (_isDebuggerCall(target)) {
      return _emitDebuggerCall(node) as js_ast.Expression;
    }

    var fn = _emitStaticTarget(target);
    var args = _emitArgumentList(node.arguments, target: target);
    return js_ast.Call(fn, args);
  }

  bool _isDebuggerCall(Procedure target) {
    return target.name.text == 'debugger' &&
        target.enclosingLibrary.importUri.toString() == 'dart:developer';
  }

  js_ast.Node _emitDebuggerCall(StaticInvocation node) {
    var args = node.arguments.named;
    var isStatement = node.parent is ExpressionStatement;
    if (args.isEmpty) {
      // Inline `debugger()` with no arguments, as a statement if possible,
      // otherwise as an immediately invoked function.
      return isStatement
          ? js.statement('debugger;')
          : js.call('(() => { debugger; return true})()');
    }

    // The signature of `debugger()` is:
    //
    //     bool debugger({bool when: true, String message})
    //
    // This code path handles the named arguments `when` and/or `message`.
    // Both must be evaluated in the supplied order, and then `when` is used
    // to decide whether to break or not.
    //
    // We also need to return the value of `when`.
    var jsArgs = args.map(_emitNamedExpression).toList();
    var when = args.length == 1
        // For a single `when` argument, use it.
        //
        // For a single `message` argument, use `{message: ...}`, which
        // coerces to true (the default value of `when`).
        ? (args[0].name == 'when'
            ? jsArgs[0].value
            : js_ast.ObjectInitializer(jsArgs))
        // If we have both `message` and `when` arguments, evaluate them in
        // order, then extract the `when` argument.
        : js.call('#.when', js_ast.ObjectInitializer(jsArgs));
    return isStatement
        ? js.statement('if (#) debugger;', when)
        : js.call('# && (() => { debugger; return true })()', when);
  }

  /// Emits the target of a [StaticInvocation], [StaticGet], or [StaticSet].
  js_ast.Expression _emitStaticTarget(Member target) {
    var c = target.enclosingClass;
    if (c != null) {
      // A static native element should just forward directly to the JS type's
      // member, for example `Css.supports(...)` in dart:html should be replaced
      // by a direct call to the DOM API: `global.CSS.supports`.
      if (_isExternal(target) && (target as Procedure).isStatic) {
        var nativeName = _extensionTypes.getNativePeers(c);
        if (nativeName.isNotEmpty) {
          var memberName = _annotationName(target, isJSName) ??
              _emitStaticMemberName(target.name.text, target);
          return runtimeCall('global.#.#', [nativeName[0], memberName]);
        }
      }
      return js_ast.PropertyAccess(_emitStaticClassName(c),
          _emitStaticMemberName(target.name.text, target));
    }
    return _emitTopLevelName(target);
  }

  List<js_ast.Expression> _emitArgumentList(Arguments node,
      {bool types = true, Member target}) {
    types = types && _reifyGenericFunction(target);
    final isJsInterop = target != null && isJsMember(target);
    return [
      if (types)
        for (var typeArg in node.types) _emitType(typeArg),
      for (var arg in node.positional)
        if (arg is StaticInvocation &&
            isJSSpreadInvocation(arg.target) &&
            arg.arguments.positional.length == 1)
          js_ast.Spread(_visitExpression(arg.arguments.positional[0]))
        else if (isJsInterop)
          _visitExpression(_assertInterop(arg))
        else
          _visitExpression(arg),
      if (node.named.isNotEmpty)
        js_ast.ObjectInitializer([
          for (var arg in node.named) _emitNamedExpression(arg, isJsInterop)
        ]),
    ];
  }

  js_ast.Property _emitNamedExpression(NamedExpression arg,
      [bool isJsInterop = false]) {
    var value = isJsInterop ? _assertInterop(arg.value) : arg.value;
    return js_ast.Property(propertyName(arg.name), _visitExpression(value));
  }

  /// Emits code for the `JS(...)` macro.
  js_ast.Node _emitInlineJSCode(StaticInvocation node) {
    var args = node.arguments.positional;
    // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
    var code = args[1];
    List<Expression> templateArgs;
    String source;
    if (code is StringConcatenation) {
      if (code.expressions.every((e) => e is StringLiteral)) {
        templateArgs = args.skip(2).toList();
        source = code.expressions.map((e) => (e as StringLiteral).value).join();
      } else {
        if (args.length > 2) {
          throw ArgumentError(
              "Can't mix template args and string interpolation in JS calls: "
              '`$node`');
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
      }
    } else {
      templateArgs = args.skip(2).toList();
      source = (code as StringLiteral).value;
    }

    // TODO(jmesserly): arguments to JS() that contain type literals evaluate to
    // the raw runtime type instead of the wrapped Type object.
    // We can clean this up by switching to `unwrapType(<type literal>)`, which
    // the compiler will then optimize.
    var wasInForeignJS = _isInForeignJS;
    _isInForeignJS = true;
    var jsArgs = templateArgs.map(_visitExpression).toList();
    _isInForeignJS = wasInForeignJS;

    var result = js.parseForeignJS(source).instantiate(jsArgs);

    // Add a check to make sure any JS() values from a native type are typed
    // properly in sound null-safety.
    if (_isWebLibrary(_currentLibrary.importUri) && _options.soundNullSafety) {
      var type = node.getStaticType(_staticTypeContext);
      if (type.isPotentiallyNonNullable) {
        result = runtimeCall('checkNativeNonNull(#)', [result]);
      }
    }

    assert(result is js_ast.Expression ||
        result is js_ast.Statement && node.parent is ExpressionStatement);
    return result.withSourceInformation(_nodeStart(node));
  }

  bool _isWebLibrary(Uri importUri) =>
      importUri != null &&
      importUri.scheme == 'dart' &&
      (importUri.path == 'html' ||
          importUri.path == 'svg' ||
          importUri.path == 'indexed_db' ||
          importUri.path == 'web_audio' ||
          importUri.path == 'web_gl' ||
          importUri.path == 'web_sql' ||
          importUri.path == 'html_common');

  bool _isNull(Expression expr) =>
      expr is NullLiteral || expr.getStaticType(_staticTypeContext) is NullType;

  bool _doubleEqIsIdentity(Expression left, Expression right) {
    // If we statically know LHS or RHS is null we can use ==.
    if (_isNull(left) || _isNull(right)) return true;
    // If the representation of the  two types will not induce conversion in
    // JS then we can use == .
    return !_typeRep.equalityMayConvert(left.getStaticType(_staticTypeContext),
        right.getStaticType(_staticTypeContext));
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
  bool isNullable(Expression expr) => _nullableInference.isNullable(expr);

  js_ast.Expression _emitJSDoubleEq(List<js_ast.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# != #' : '# == #';
    return js.call(op, args);
  }

  js_ast.Expression _emitJSTripleEq(List<js_ast.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# !== #' : '# === #';
    return js.call(op, args);
  }

  js_ast.Expression _emitCoreIdenticalCall(List<Expression> args,
      {bool negated = false}) {
    if (args.length != 2) {
      // Shouldn't happen in typechecked code
      return runtimeCall(
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
        js_ast.Call(_emitTopLevelName(_coreTypes.identicalProcedure), jsArgs));
  }

  @override
  js_ast.Expression visitConstructorInvocation(ConstructorInvocation node) {
    var ctor = node.target;
    var ctorClass = ctor.enclosingClass;
    var args = node.arguments;
    if (isJSAnonymousType(ctorClass)) return _emitObjectLiteral(args, ctor);
    var result = js_ast.New(_emitConstructorName(node.constructedType, ctor),
        _emitArgumentList(args, types: false, target: ctor));

    return node.isConst ? canonicalizeConstObject(result) : result;
  }

  js_ast.Expression _emitFactoryInvocation(StaticInvocation node) {
    var args = node.arguments;
    var ctor = node.target;
    var ctorClass = ctor.enclosingClass;
    if (ctor.isExternal && hasJSInteropAnnotation(ctorClass)) {
      return _emitJSInteropNew(ctor, args);
    }

    var type = ctorClass.typeParameters.isEmpty
        ? _coreTypes.nonNullableRawType(ctorClass)
        : InterfaceType(ctorClass, Nullability.legacy, args.types);

    if (isFromEnvironmentInvocation(_coreTypes, node)) {
      var value = _constants.evaluate(node);
      if (value is PrimitiveConstant) {
        return visitConstant(value);
      }
    }

    if (args.positional.isEmpty &&
        args.named.isEmpty &&
        ctorClass.enclosingLibrary.importUri.scheme == 'dart') {
      // Skip the slow SDK factory constructors when possible.
      switch (ctorClass.name) {
        case 'Map':
        case 'HashMap':
        case 'LinkedHashMap':
          if (ctor.name.text == '') {
            return js.call('new #.new()', _emitMapImplType(type));
          } else if (ctor.name.text == 'identity') {
            return js.call(
                'new #.new()', _emitMapImplType(type, identity: true));
          }
          break;
        case 'Set':
        case 'HashSet':
        case 'LinkedHashSet':
          if (ctor.name.text == '') {
            return js.call('new #.new()', _emitSetImplType(type));
          } else if (ctor.name.text == 'identity') {
            return js.call(
                'new #.new()', _emitSetImplType(type, identity: true));
          }
          break;
        case 'List':
          if (ctor.name.text == '' && type is InterfaceType) {
            return _emitList(type.typeArguments[0], []);
          }
          break;
      }
    }

    var result = js_ast.Call(_emitConstructorName(type, ctor),
        _emitArgumentList(args, types: false));

    return node.isConst ? canonicalizeConstObject(result) : result;
  }

  js_ast.Expression _emitJSInteropNew(Member ctor, Arguments args) {
    var ctorClass = ctor.enclosingClass;
    if (isJSAnonymousType(ctorClass)) return _emitObjectLiteral(args, ctor);
    return js_ast.New(
        _emitConstructorName(_coreTypes.legacyRawType(ctorClass), ctor),
        _emitArgumentList(args, types: false, target: ctor));
  }

  js_ast.Expression _emitMapImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) {
      return _emitInterfaceType(type, emitNullability: false);
    }
    identity ??= _typeRep.isPrimitive(typeArgs[0]);
    var c = identity ? _identityHashMapImplClass : _linkedHashMapImplClass;
    return _emitInterfaceType(InterfaceType(c, Nullability.legacy, typeArgs),
        emitNullability: false);
  }

  js_ast.Expression _emitSetImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) {
      return _emitInterfaceType(type, emitNullability: false);
    }
    identity ??= _typeRep.isPrimitive(typeArgs[0]);
    var c = identity ? _identityHashSetImplClass : _linkedHashSetImplClass;
    return _emitInterfaceType(InterfaceType(c, Nullability.legacy, typeArgs),
        emitNullability: false);
  }

  js_ast.Expression _emitObjectLiteral(Arguments node, Member ctor) {
    var args = _emitArgumentList(node, types: false, target: ctor);
    if (args.isEmpty) return js.call('{}');
    assert(args.single is js_ast.ObjectInitializer);
    return args.single;
  }

  @override
  js_ast.Expression visitNot(Not node) {
    var operand = node.operand;
    if (operand is MethodInvocation && operand.name.text == '==') {
      return _emitEqualityOperator(operand.receiver, operand.interfaceTarget,
          operand.arguments.positional[0],
          negated: true);
    } else if (operand is StaticInvocation &&
        operand.target == _coreTypes.identicalProcedure) {
      return _emitCoreIdenticalCall(operand.arguments.positional,
          negated: true);
    }

    // Logical negation, `!e`, is a boolean conversion context since it is
    // defined as `e ? false : true`.
    return js.call('!#', _visitTest(operand));
  }

  @override
  js_ast.Expression visitNullCheck(NullCheck node) {
    var expr = node.operand;
    var jsExpr = _visitExpression(expr);
    // If the expression is non-nullable already, this is a no-op.
    return isNullable(expr) ? runtimeCall('nullCheck(#)', [jsExpr]) : jsExpr;
  }

  @override
  js_ast.Expression visitLogicalExpression(LogicalExpression node) {
    // The operands of logical boolean operators are subject to boolean
    // conversion.
    return _visitTest(node);
  }

  @override
  js_ast.Expression visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      _visitTest(node.condition),
      _visitExpression(node.then),
      _visitExpression(node.otherwise)
    ])
      ..sourceInformation = _nodeStart(node.condition);
  }

  @override
  js_ast.Expression visitStringConcatenation(StringConcatenation node) {
    var parts = <js_ast.Expression>[];
    for (var e in node.expressions) {
      var jsExpr = _visitExpression(e);
      if (jsExpr is js_ast.LiteralString && jsExpr.valueWithoutQuotes.isEmpty) {
        continue;
      }
      var type = e.getStaticType(_staticTypeContext);
      parts.add(DartTypeEquivalence(_coreTypes, ignoreTopLevelNullability: true)
                  .areEqual(type, _coreTypes.stringNonNullableRawType) &&
              !isNullable(e)
          ? jsExpr
          : runtimeCall('str(#)', [jsExpr]));
    }
    if (parts.isEmpty) return js.string('');
    return js_ast.Expression.binary(parts, '+');
  }

  @override
  js_ast.Expression visitListConcatenation(ListConcatenation node) {
    // Only occurs inside unevaluated constants.
    throw UnsupportedError('List concatenation');
  }

  @override
  js_ast.Expression visitSetConcatenation(SetConcatenation node) {
    // Only occurs inside unevaluated constants.
    throw UnsupportedError('Set concatenation');
  }

  @override
  js_ast.Expression visitMapConcatenation(MapConcatenation node) {
    // Only occurs inside unevaluated constants.
    throw UnsupportedError('Map concatenation');
  }

  @override
  js_ast.Expression visitInstanceCreation(InstanceCreation node) {
    // Only occurs inside unevaluated constants.
    throw UnsupportedError('Instance creation');
  }

  @override
  js_ast.Expression visitFileUriExpression(FileUriExpression node) {
    // Only occurs inside unevaluated constants.
    throw UnsupportedError('File URI expression');
  }

  @override
  js_ast.Expression visitIsExpression(IsExpression node) {
    return _emitIsExpression(node.operand, node.type);
  }

  js_ast.Expression _emitIsExpression(Expression operand, DartType type) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    var lhs = _visitExpression(operand);
    var typeofName = _typeRep.typeFor(type).primitiveTypeOf;
    // Inline non-nullable primitive types other than int (which requires a
    // Math.floor check).
    if (typeofName != null &&
        type.nullability == Nullability.nonNullable &&
        type != _types.coreTypes.intNonNullableRawType) {
      return js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    } else {
      return js.call('#.is(#)', [_emitType(type), lhs]);
    }
  }

  @override
  js_ast.Expression visitAsExpression(AsExpression node) {
    var fromExpr = node.operand;
    var jsFrom = _visitExpression(fromExpr);
    var to = node.type;
    var from = fromExpr.getStaticType(_staticTypeContext);

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
    var isTypeError = node.isTypeError;
    if (!isTypeError &&
        _types.isSubtypeOf(from, to, SubtypeCheckMode.withNullabilities)) {
      return jsFrom;
    }

    if (!isTypeError &&
        DartTypeEquivalence(_coreTypes, ignoreTopLevelNullability: true)
            .areEqual(from, to) &&
        _mustBeNonNullable(to)) {
      // If the underlying type is the same, we only need a null check.
      return runtimeCall('nullCast(#, #)', [jsFrom, _emitType(to)]);
    }

    // All Dart number types map to a JS double.  We can specialize these
    // cases.
    if (_typeRep.isNumber(from) && _typeRep.isNumber(to)) {
      // If `to` is some form of `num`, it should have been filtered above.

      // * -> double? | double* : no-op
      if (to == _coreTypes.doubleLegacyRawType ||
          to == _coreTypes.doubleNullableRawType) {
        return jsFrom;
      }

      // * -> double : null check
      if (to == _coreTypes.doubleNonNullableRawType) {
        if (from.nullability == Nullability.nonNullable) {
          return jsFrom;
        }
        return runtimeCall('nullCast(#, #)', [jsFrom, _emitType(to)]);
      }

      // * -> int : asInt check
      if (to == _coreTypes.intNonNullableRawType) {
        return runtimeCall('asInt(#)', [jsFrom]);
      }

      // * -> int? | int* : asNullableInt check
      if (to == _coreTypes.intLegacyRawType ||
          to == _coreTypes.intNullableRawType) {
        return runtimeCall('asNullableInt(#)', [jsFrom]);
      }
    }

    return _emitCast(jsFrom, to);
  }

  js_ast.Expression _emitCast(js_ast.Expression expr, DartType type) =>
      _types.isTop(type) ? expr : js.call('#.as(#)', [_emitType(type), expr]);

  @override
  js_ast.Expression visitSymbolLiteral(SymbolLiteral node) =>
      emitDartSymbol(node.value);

  @override
  js_ast.Expression visitTypeLiteral(TypeLiteral node) =>
      _emitTypeLiteral(node.type);

  js_ast.Expression _emitTypeLiteral(DartType type) {
    var typeRep = _emitType(type);
    // If the type is a type literal expression in Dart code, wrap the raw
    // runtime type in a "Type" instance.
    return _isInForeignJS ? typeRep : runtimeCall('wrapType(#)', [typeRep]);
  }

  @override
  js_ast.Expression visitThisExpression(ThisExpression node) => js_ast.This();

  @override
  js_ast.Expression visitRethrow(Rethrow node) {
    return runtimeCall('rethrow(#)', [_emitVariableRef(_rethrowParameter)]);
  }

  @override
  js_ast.Expression visitThrow(Throw node) =>
      runtimeCall('throw(#)', [_visitExpression(node.expression)]);

  @override
  js_ast.Expression visitListLiteral(ListLiteral node) {
    var elementType = node.typeArgument;
    var elements = _visitExpressionList(node.expressions);
    return _emitList(elementType, elements);
  }

  js_ast.Expression _emitList(
      DartType itemType, List<js_ast.Expression> items) {
    var list = js_ast.ArrayInitializer(items);

    // TODO(jmesserly): analyzer will usually infer `List<Object>` because
    // that is the least upper bound of the element types. So we rarely
    // generate a plain `List<dynamic>` anymore.
    if (itemType == const DynamicType()) return list;

    // Call `new JSArray<E>.of(list)`
    var arrayType = _emitInterfaceType(
        InterfaceType(_jsArrayClass, Nullability.legacy, [itemType]),
        emitNullability: false);
    return js.call('#.of(#)', [arrayType, list]);
  }

  js_ast.Expression _emitConstList(
      DartType elementType, List<js_ast.Expression> elements) {
    // dart.constList helper internally depends on _interceptors.JSArray.
    _declareBeforeUse(_jsArrayClass);
    return cacheConst(
        runtimeCall('constList([#], #)', [elements, _emitType(elementType)]));
  }

  @override
  js_ast.Expression visitSetLiteral(SetLiteral node) {
    // TODO(markzipan): remove const check when we use front-end const eval
    if (!node.isConst) {
      var setType = _emitInterfaceType(
          InterfaceType(
              _linkedHashSetClass, Nullability.legacy, [node.typeArgument]),
          emitNullability: false);
      if (node.expressions.isEmpty) {
        return js.call('#.new()', [setType]);
      }
      return js.call(
          '#.from([#])', [setType, _visitExpressionList(node.expressions)]);
    }
    return _emitConstSet(
        node.typeArgument, _visitExpressionList(node.expressions));
  }

  js_ast.Expression _emitConstSet(
      DartType elementType, List<js_ast.Expression> elements) {
    return cacheConst(
        runtimeCall('constSet(#, [#])', [_emitType(elementType), elements]));
  }

  @override
  js_ast.Expression visitMapLiteral(MapLiteral node) {
    var entries = [
      for (var e in node.entries) ...[
        _visitExpression(e.key),
        _visitExpression(e.value),
      ],
    ];

    // TODO(markzipan): remove const check when we use front-end const eval
    if (!node.isConst) {
      var mapType = _emitMapImplType(
          node.getStaticType(_staticTypeContext) as InterfaceType);
      if (node.entries.isEmpty) {
        return js.call('new #.new()', [mapType]);
      }
      return js.call('new #.from([#])', [mapType, entries]);
    }
    return _emitConstMap(node.keyType, node.valueType, entries);
  }

  js_ast.Expression _emitConstMap(
      DartType keyType, DartType valueType, List<js_ast.Expression> entries) {
    return cacheConst(runtimeCall('constMap(#, #, [#])',
        [_emitType(keyType), _emitType(valueType), entries]));
  }

  @override
  js_ast.Expression visitAwaitExpression(AwaitExpression node) =>
      js_ast.Yield(_visitExpression(node.operand));

  @override
  js_ast.Expression visitFunctionExpression(FunctionExpression node) {
    var fn = _emitArrowFunction(node);
    if (!_reifyFunctionType(node.function)) return fn;
    return _emitFunctionTagged(
        fn, node.getStaticType(_staticTypeContext) as FunctionType);
  }

  js_ast.ArrowFun _emitArrowFunction(FunctionExpression node) {
    var f = _emitFunction(node.function, null);
    js_ast.Node body = f.body;

    // Simplify `=> { return e; }` to `=> e`
    if (body is js_ast.Block) {
      var block = body as js_ast.Block;
      if (block.statements.length == 1) {
        var s = block.statements[0];
        if (s is js_ast.Block) {
          block = s as js_ast.Block;
          s = block.statements.length == 1 ? block.statements[0] : null;
        }
        if (s is js_ast.Return && s.value != null) body = s.value;
      }
    }

    // Convert `function(...) { ... }` to `(...) => ...`
    // This is for readability, but it also ensures correct `this` binding.
    return js_ast.ArrowFun(f.params, body);
  }

  @override
  js_ast.Expression visitStringLiteral(StringLiteral node) =>
      js.escapedString(node.value, '"');

  @override
  js_ast.Expression visitIntLiteral(IntLiteral node) => js.uint64(node.value);

  @override
  js_ast.Expression visitDoubleLiteral(DoubleLiteral node) =>
      js.number(node.value);

  @override
  js_ast.Expression visitBoolLiteral(BoolLiteral node) =>
      js_ast.LiteralBool(node.value);

  @override
  js_ast.Expression visitNullLiteral(NullLiteral node) => js_ast.LiteralNull();

  @override
  js_ast.Expression visitLet(Let node) {
    var v = node.variable;
    var init = _visitExpression(v.initializer);
    var body = _visitExpression(node.body);
    var temp = _tempVariables.remove(v);
    if (temp != null) {
      if (_letVariables != null) {
        init = js_ast.Assignment(temp, init);
        _letVariables.add(temp);
      } else {
        // TODO(jmesserly): make sure this doesn't happen on any performance
        // critical call path.
        //
        // Annotations on a top-level, non-lazy function type should be the only
        // remaining use.
        return js_ast.Call(js_ast.ArrowFun([temp], body), [init]);
      }
    }
    return js_ast.Binary(',', init, body);
  }

  @override
  js_ast.Expression visitBlockExpression(BlockExpression node) {
    var jsExpr = _visitExpression(node.value);
    var jsStmts = [
      for (var s in node.body.statements) _visitStatement(s),
      js_ast.Return(jsExpr),
    ];
    var jsBlock = js_ast.Block(jsStmts);
    // BlockExpressions with async operations must be constructed
    // with a generator instead of a lambda.
    var finder = YieldFinder();
    jsBlock.accept(finder);
    if (finder.hasYield) {
      js_ast.Expression genFn = js_ast.Fun([], jsBlock, isGenerator: true);
      if (usesThisOrSuper(genFn)) genFn = js.call('#.bind(this)', genFn);
      var asyncLibrary = emitLibraryName(_coreTypes.asyncLibrary);
      var returnType = _emitType(node.getStaticType(_staticTypeContext));
      var asyncCall =
          js.call('#.async(#, #)', [asyncLibrary, returnType, genFn]);
      return js_ast.Yield(asyncCall);
    }
    return js_ast.Call(js_ast.ArrowFun([], jsBlock), []);
  }

  @override
  js_ast.Expression visitInstantiation(Instantiation node) {
    return runtimeCall('gbind(#, #)', [
      _visitExpression(node.expression),
      node.typeArguments.map(_emitType).toList()
    ]);
  }

  @override
  js_ast.Expression visitLoadLibrary(LoadLibrary node) =>
      runtimeCall('loadLibrary()');

  // TODO(jmesserly): DDC loads all libraries eagerly.
  // See
  // https://github.com/dart-lang/sdk/issues/27776
  // https://github.com/dart-lang/sdk/issues/27777
  @override
  js_ast.Expression visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      js.boolean(true);

  bool _reifyFunctionType(FunctionNode f) {
    if (_currentLibrary.importUri.scheme != 'dart') return true;
    var parent = f.parent;

    // SDK libraries can skip reification if they request it.
    bool reifyFunctionTypes(Expression a) =>
        isBuiltinAnnotation(a, '_js_helper', 'ReifyFunctionTypes');
    while (parent != null) {
      var a = findAnnotation(parent, reifyFunctionTypes);
      var value = _constants.getFieldValueFromAnnotation(a, 'value');
      if (value is bool) return value;
      parent = parent.parent;
    }
    return true;
  }

  bool _reifyTearoff(Member member) {
    return member is Procedure &&
        !member.isAccessor &&
        !member.isFactory &&
        !_isInForeignJS &&
        !usesJSInterop(member) &&
        _reifyFunctionType(member.function);
  }

  /// Returns the name value of the `JSExportName` annotation (when compiling
  /// the SDK), or `null` if there's none. This is used to control the name
  /// under which functions are compiled and exported.
  String _jsExportName(NamedNode n) {
    var library = getLibrary(n);
    if (library == null || library.importUri.scheme != 'dart') return null;

    return _annotationName(n, isJSExportNameAnnotation);
  }

  /// If [node] has annotation matching [test] and the first argument is a
  /// string, this returns the string value.
  ///
  /// Calls [findAnnotation] followed by [getNameFromAnnotation].
  String _annotationName(NamedNode node, bool Function(Expression) test) {
    return _constants.getFieldValueFromAnnotation(
        findAnnotation(node, test), 'name') as String;
  }

  @override
  js_ast.Expression cacheConst(js_ast.Expression jsExpr) {
    if (isSdkInternalRuntime(_currentLibrary)) {
      return super.cacheConst(jsExpr);
    }
    return jsExpr;
  }

  @override
  js_ast.Expression visitConstant(Constant node) {
    if (node is TearOffConstant) {
      // JS() or external JS consts should not be lazily loaded.
      var isSdk = node.procedure.enclosingLibrary.importUri.scheme == 'dart';
      if (_isInForeignJS) {
        return _emitStaticTarget(node.procedure);
      }
      if (node.procedure.isExternal && !isSdk) {
        return runtimeCall(
            'tearoffInterop(#)', [_emitStaticTarget(node.procedure)]);
      }
    }
    if (isSdkInternalRuntime(_currentLibrary) || node is PrimitiveConstant) {
      return super.visitConstant(node);
    }
    var constAlias = constAliasCache[node];
    if (constAlias != null) {
      return constAlias;
    }
    var constAliasString = 'C${constAliasCache.length}';
    var constAliasProperty = propertyName(constAliasString);

    _constTableCache[constAliasString] = js.call('void 0');
    var constAliasAccessor = _constTableCache.access(constAliasString);

    var constAccessor = js.call(
        '# || #.#', [constAliasAccessor, _constTable, constAliasProperty]);
    constAliasCache[node] = constAccessor;
    var constJs = super.visitConstant(node);

    var func = js_ast.Fun(
        [],
        js_ast.Block([
          js.statement('return # = #;', [constAliasAccessor, constJs])
        ]));
    var accessor = js_ast.Method(constAliasProperty, func, isGetter: true);
    _constLazyAccessors.add(accessor);
    return constAccessor;
  }

  @override
  js_ast.Expression visitNullConstant(NullConstant node) =>
      js_ast.LiteralNull();
  @override
  js_ast.Expression visitBoolConstant(BoolConstant node) =>
      js.boolean(node.value);
  @override
  js_ast.Expression visitIntConstant(IntConstant node) => js.number(node.value);
  @override
  js_ast.Expression visitDoubleConstant(DoubleConstant node) {
    var value = node.value;

    // Emit the constant as an integer, if possible.
    if (value.isFinite) {
      var intValue = value.toInt();
      const _MIN_INT32 = -0x80000000;
      const _MAX_INT32 = 0x7FFFFFFF;
      if (intValue.toDouble() == value &&
          intValue >= _MIN_INT32 &&
          intValue <= _MAX_INT32) {
        return js.number(intValue);
      }
    }
    if (value.isInfinite) {
      if (value.isNegative) {
        return js.call('-1 / 0');
      }
      return js.call('1 / 0');
    }
    if (value.isNaN) {
      return js.call('0 / 0');
    }
    return js.number(value);
  }

  @override
  js_ast.Expression visitStringConstant(StringConstant node) =>
      js.escapedString(node.value, '"');

  // DDC does not currently use the non-primivite constant nodes; rather these
  // are emitted via their normal expression nodes.
  @override
  js_ast.Expression defaultConstant(Constant node) => _emitInvalidNode(node);

  @override
  js_ast.Expression visitSymbolConstant(SymbolConstant node) =>
      emitDartSymbol(node.name);

  @override
  js_ast.Expression visitMapConstant(MapConstant node) {
    var entries = [
      for (var e in node.entries) ...[
        visitConstant(e.key),
        visitConstant(e.value),
      ],
    ];
    return _emitConstMap(node.keyType, node.valueType, entries);
  }

  @override
  js_ast.Expression visitListConstant(ListConstant node) => _emitConstList(
      node.typeArgument, node.entries.map(visitConstant).toList());

  @override
  js_ast.Expression visitSetConstant(SetConstant node) => _emitConstSet(
      node.typeArgument, node.entries.map(visitConstant).toList());

  @override
  js_ast.Expression visitInstanceConstant(InstanceConstant node) {
    _declareBeforeUse(node.classNode);
    js_ast.Property entryToProperty(MapEntry<Reference, Constant> entry) {
      var constant = visitConstant(entry.value);
      var member = entry.key.asField;
      var cls = member.enclosingClass;
      // Enums cannot be overridden, so we can safely use the field name
      // directly.  Otherwise, use a private symbol in case the field
      // was overridden.
      var symbol = cls.isEnum
          ? _emitMemberName(member.name.text, member: member)
          : getSymbol(emitClassPrivateNameSymbol(
              cls.enclosingLibrary, getLocalClassName(cls), member.name.text));
      return js_ast.Property(symbol, constant);
    }

    var type = _emitInterfaceType(
        node.getType(_staticTypeContext) as InterfaceType,
        emitNullability: false);
    var prototype = js.call('#.prototype', [type]);
    var properties = [
      js_ast.Property(propertyName('__proto__'), prototype),
      for (var e in node.fieldValues.entries.toList().reversed)
        entryToProperty(e),
    ];
    return canonicalizeConstObject(
        js_ast.ObjectInitializer(properties, multiline: true));
  }

  @override
  js_ast.Expression visitTearOffConstant(TearOffConstant node) {
    _declareBeforeUse(node.procedure.enclosingClass);
    return _emitStaticGet(node.procedure);
  }

  @override
  js_ast.Expression visitTypeLiteralConstant(TypeLiteralConstant node) =>
      _emitTypeLiteral(node.type);

  @override
  js_ast.Expression visitPartialInstantiationConstant(
          PartialInstantiationConstant node) =>
      canonicalizeConstObject(runtimeCall('gbind(#, #)', [
        visitConstant(node.tearOffConstant),
        node.types.map(_emitType).toList()
      ]));

  @override
  js_ast.Expression visitUnevaluatedConstant(UnevaluatedConstant node) =>
      throw UnsupportedError('Encountered an unevaluated constant: $node');

  @override
  js_ast.Expression visitFunctionTearOff(FunctionTearOff node) {
    return _emitPropertyGet(node.receiver, null, 'call');
  }
}

bool _isInlineJSFunction(Statement body) {
  var block = body;
  if (block is Block) {
    var statements = block.statements;
    if (statements.length != 1) return false;
    body = statements[0];
  }
  if (body is ReturnStatement) {
    var expr = body.expression;
    return expr is StaticInvocation && isInlineJS(expr.target);
  }
  return false;
}

/// Return true if this is one of the methods/properties on all Dart Objects
/// (toString, hashCode, noSuchMethod, runtimeType).
///
/// Operator == is excluded, as it is handled as part of the equality binary
/// operator.
bool _isObjectMember(String name) {
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

bool _isObjectMethodTearoff(String name) =>
    name == 'toString' || name == 'noSuchMethod';

bool _isObjectMethodCall(String name, Arguments args) {
  if (name == 'toString') {
    return args.positional.isEmpty && args.named.isEmpty && args.types.isEmpty;
  } else if (name == 'noSuchMethod') {
    return args.positional.length == 1 &&
        args.named.isEmpty &&
        args.types.isEmpty;
  }
  return false;
}

class _SwitchLabelState {
  String label;
  js_ast.Identifier variable;

  _SwitchLabelState(this.label, this.variable);
}
