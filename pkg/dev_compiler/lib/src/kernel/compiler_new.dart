// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' show max, min;

import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart'
    show ExtensionIndex;
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:js_shared/synced/embedded_names.dart' show JsGetName, JsBuiltin;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/src/dart_type_equivalence.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart' show SourceLocation;

import '../command/options.dart' show Options;
import '../compiler/js_names.dart' as js_ast;
import '../compiler/js_utils.dart' as js_ast;
import '../compiler/module_builder.dart'
    show isSdkInternalRuntimeUri, libraryUriToJsIdentifier;
import '../compiler/module_containers.dart' show ModuleItemContainer;
import '../compiler/rewrite_async.dart';
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show ModuleItem, js;
import '../js_ast/source_map_printer.dart'
    show NodeEnd, NodeSpan, HoverComment, continueSourceMap;
import 'compiler.dart' as old;
import 'constants.dart';
import 'future_or_normalizer.dart';
import 'js_interop.dart';
import 'js_typerep.dart';
import 'kernel_helpers.dart';
import 'native_types.dart';
import 'nullable_inference.dart';
import 'property_model.dart';
import 'target.dart' show allowedNativeTest;
import 'type_environment.dart';
import 'type_recipe_generator.dart';
import 'type_table.dart';

/// Name used as a prefix for extension symbols and the identifier of the object
/// used to store them.
final _extensionSymbolHolderName = 'dartx';

/// A prefix for symbols used to store lazily evaluated field values.
///
/// Names prefixed with this must not be reset across hot reloads.
final _fieldValueStorePrefix = '_#v_';

/// Symbol data used to map library members kernel nodes to identifiers used
/// in the compiled JavaScript.
///
/// This data is intended to be serialized and consumed by the debugger.
class SymbolData {
  /// Maps each `Class` node compiled in the module to the `Identifier`s used to
  /// name the class in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  final classIdentifiers = <Class, js_ast.Identifier>{};

  /// Maps each class `Member` node compiled in the module to the name used for
  /// the member in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  final memberNames = <Member, String>{};

  /// Maps each `Procedure` node compiled in the module to the `Identifier`s
  /// used to name the class in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  final procedureIdentifiers = <Procedure, js_ast.Identifier>{};

  /// Maps each `VariableDeclaration` node compiled in the module to the name
  /// used for the variable in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  final variableIdentifiers = <VariableDeclaration, js_ast.Identifier>{};
}

/// Compiles a kernel [Component] to a bundle of individual libraries.
class LibraryBundleCompiler implements old.Compiler {
  final ClassHierarchy _hierarchy;
  final Options _options;
  final Map<Library, Component> _importToSummary;
  final Map<Component, String> _summaryToModule;
  final CoreTypes _coreTypes;
  final Ticker? _ticker;
  final _symbolData = SymbolData();
  final _libraryCompilers = <Library, LibraryCompiler>{};

  LibraryBundleCompiler(
    Component component,
    this._hierarchy,
    this._options,
    this._importToSummary,
    this._summaryToModule, {
    CoreTypes? coreTypes,
    Ticker? ticker,
  })  : _coreTypes = coreTypes ?? CoreTypes(component),
        _ticker = ticker;

  @override
  Map<Class, js_ast.Identifier> get classIdentifiers =>
      _symbolData.classIdentifiers;
  @override
  Map<Member, String> get memberNames => _symbolData.memberNames;
  @override
  Map<Procedure, js_ast.Identifier> get procedureIdentifiers =>
      _symbolData.procedureIdentifiers;
  @override
  Map<VariableDeclaration, js_ast.Identifier> get variableIdentifiers =>
      _symbolData.variableIdentifiers;

  @override
  js_ast.Program emitModule(Component component) {
    assert(_options.emitLibraryBundle);
    _ticker?.logMs('Emitting library bundle');
    var compiledLibraries = <js_ast.Program>[];
    for (var library in component.libraries) {
      var libraryCompiler = LibraryCompiler(
        component,
        _hierarchy,
        _options,
        _importToSummary,
        _summaryToModule,
        coreTypes: _coreTypes,
        ticker: _ticker,
        symbolData: _symbolData,
      );
      _libraryCompilers[library] = libraryCompiler;
      compiledLibraries.add(libraryCompiler.emitLibrary(library));
    }
    // TODO(nshahan): Nothing about these symbols requires them to be
    // represented in a library. These could be moved to a construct outside
    // of the language that is provided to libraries that need it.
    if (component.libraries.contains(_coreTypes.coreLibrary)) {
      // Collect all extension symbols from all SDK libraries.
      var allSymbols = {
        for (var compiler in _libraryCompilers.values)
          ...compiler._extensionSymbols
      };
      // Create dartx library
      var id = js_ast.Identifier(_extensionSymbolHolderName);
      var statements = [
        for (var entry in allSymbols.entries)
          js.statement('# = Symbol(#);', [
            js_ast.PropertyAccess(id, js.string(entry.key)),
            js.string('$_extensionSymbolHolderName.${entry.key}')
          ]),
        js.statement('# = #', [
          js_ast.PropertyAccess.field(id, 'link'),
          js_ast.NamedFunction(
              js_ast.ScopedId('link__$_extensionSymbolHolderName'),
              js_ast.Fun(const [], js_ast.Block(const [])))
        ]),
      ];

      compiledLibraries.insert(
          0,
          js_ast.Program(statements,
              name: _extensionSymbolHolderName, librarySelfVar: id));
    }
    return js_ast.LibraryBundle(compiledLibraries,
        header: _generateCompilationHeader());
  }

  @override
  js_ast.Fun emitFunctionIncremental(List<js_ast.ModuleItem> items,
      Library library, Class? cls, FunctionNode functionNode, String name) {
    return _libraryCompilers[library]!
        ._emitFunctionIncremental(items, library, cls, functionNode, name);
  }

  /// Creates header comments with helpful compilation information.
  List<js_ast.Comment> _generateCompilationHeader() {
    var headerOptions = [
      if (_options.canaryFeatures) 'canary',
      if (_options.emitLibraryBundle) 'emitLibraryBundle',
      'soundNullSafety(${_options.soundNullSafety})',
      'enableAsserts(${_options.enableAsserts})',
    ];
    var enabledExperiments = <String>[];
    _options.experiments.forEach((key, value) {
      if (value) enabledExperiments.add(key);
    });
    var header = [
      js_ast.Comment(
          'Generated by DDC, the Dart Development Compiler (to JavaScript).'),
      js_ast.Comment('Version: ${io.Platform.version}'),
      js_ast.Comment('Module: ${_options.moduleName}'),
      js_ast.Comment('Flags: ${headerOptions.join(', ')}'),
      if (enabledExperiments.isNotEmpty)
        js_ast.Comment('Experiments: ${enabledExperiments.join(', ')}')
    ];
    return header;
  }
}

class LibraryCompiler extends ComputeOnceConstantVisitor<js_ast.Expression>
    with OnceConstantVisitorDefaultMixin<js_ast.Expression>
    implements
        StatementVisitor<js_ast.Statement>,
        ExpressionVisitor<js_ast.Expression> {
  final Options _options;
  final SymbolData _symbolData;

  /// Maps each `Class` node compiled in the module to the `Identifier`s used to
  /// name the class in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  Map<Class, js_ast.Identifier> get classIdentifiers =>
      _symbolData.classIdentifiers;

  /// Maps each class `Member` node compiled in the module to the name used for
  /// the member in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  Map<Member, String> get memberNames => _symbolData.memberNames;

  /// Maps each `Procedure` node compiled in the module to the `Identifier`s
  /// used to name the class in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  Map<Procedure, js_ast.Identifier> get procedureIdentifiers =>
      _symbolData.procedureIdentifiers;

  /// Maps each `VariableDeclaration` node compiled in the module to the name
  /// used for the variable in JavaScript.
  ///
  /// This mapping is used when generating the symbol information for the
  /// module.
  Map<VariableDeclaration, js_ast.Identifier> get variableIdentifiers =>
      _symbolData.variableIdentifiers;

  /// Identifiers for kernel variables with an analgous identifier in JS.
  ///
  /// [VariableDeclaration.name] is not necessarily a safe identifier for JS
  /// transpiled code. The same name can be used in shadowing contexts. We map
  /// each kernel variable to a [js_ast.ScopedId] so that at code emission
  /// time, references that would be shadowed are given a unique name. If there
  /// is no risk of shadowing, the original name will be used.
  final Map<VariableDeclaration, js_ast.ScopedId> _variableTempIds = {};

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
  VariableDeclaration? _rethrowParameter;

  /// Temporary variables mapped to their corresponding JavaScript variable.
  final _tempVariables = <VariableDeclaration, js_ast.ScopedId>{};

  /// Let variables collected for the given function.
  List<js_ast.ScopedId>? _letVariables;

  final _constTable = js_ast.Identifier('CT');

  /// Constant getters used to populate the constant table.
  final _constLazyAccessors = <js_ast.Method>[];

  /// Container for holding the results of lazily-evaluated constants.
  var _constTableCache = ModuleItemContainer<String>.asArray('C');

  /// Tracks the index in [_moduleItems] where the const table must be inserted.
  /// Required for SDK builds due to internal circular dependencies.
  /// E.g., dart.constList depends on JSArray.
  int _constTableInsertionIndex = 0;

  /// The class that is emitting its base class or mixin references, otherwise
  /// null.
  ///
  /// This is not used when inside the class method bodies, or for other type
  /// information such as `implements`.
  Class? _classEmittingExtends;

  /// The class that is emitting its signature information, otherwise null.
  Class? _classEmittingSignatures;

  /// The current type environment of type parameters introduced to the scope
  /// via generic classes and functions.
  DDCTypeEnvironment _currentTypeEnvironment = const EmptyTypeEnvironment();

  final TypeRecipeGenerator _typeRecipeGenerator;

  /// Visitor used for testing static invocations in the dart:_rti library to
  /// determine if they are suitable for inlining at call sites.
  final BasicInlineTester _inlineTester;

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentClass == _classEmittingTopLevel
  ///
  Class? _currentClass;

  /// The current source file URI for emitting in the source map.
  Uri? _currentUri;

  late Component _component;

  /// The current library being compiled.
  Library? _currentLibrary;

  /// The current function being compiled, if any.
  FunctionNode? _currentFunction;

  /// Library link method statements that perform class hierarchy connections
  /// like `class C extends E`.
  final List<js_ast.Statement> _classExtendsLinks = [];

  /// Library link method statements that define extension members on mixin
  /// classes.
  final List<js_ast.Statement> _mixinClassDefineExtensionMemberLinks = [];

  /// Library link method statements that define extension members on classes.
  final List<js_ast.Statement> _defineExtensionMemberLinks = [];

  /// Library link method statements that apply mixins.
  final List<js_ast.Statement> _mixinApplicationLinks = [];

  /// Library link method statements that apply extensions on native types.
  final List<js_ast.Statement> _nativeExtensionLinks = [];

  /// Library link method statements that create type rules.
  final List<js_ast.Statement> _typeRuleLinks = [];

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
  late TypeTable _typeTable;

  /// The global extension type table.
  // TODO(jmesserly): rename to `_nativeTypes`
  final NativeTypeSet _extensionTypes;

  final CoreTypes _coreTypes;

  final TypeEnvironment _types;

  final StatefulStaticTypeContext _staticTypeContext;

  final ClassHierarchy _hierarchy;

  /// Information about virtual and overridden fields/getters/setters in the
  /// class we're currently compiling, or `null` if we aren't compiling a class.
  ClassPropertyModel? _classProperties;

  /// Information about virtual fields for all libraries in the current build
  /// unit.
  final _virtualFields = VirtualFieldModel();

  final JSTypeRep _typeRep;

  bool _superAllowed = true;
  bool _optimizeNonVirtualFieldAccess = true;

  final _superHelpers = <String, js_ast.Method>{};

  /// Cache for the results of calling [_requiresRtiForInstantiation].
  final _requiresRtiForInstantiationCache = <Class, bool>{};

  /// Reserved parameter used to reference RTI objects passed to generic
  /// constructors/factories and generic method signatures.
  final _rtiParam = js_ast.ScopedId('_ti');

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
  final _constAliasCache = HashMap<Constant, js_ast.Expression>();

  /// Maps uri strings in asserts and elsewhere to hoisted identifiers.
  var _uriContainer = ModuleItemContainer<String>.asArray('I');

  /// Index of extension and extension type members in order to filter static
  /// interop members.
  // TODO(srujzs): Is there some way to share this from the js_util_optimizer to
  // avoid having to recompute?
  final ExtensionIndex _extensionIndex;

  /// When inside a `[]=` operator, this will be a non-null value that should be
  /// returned by any `return;` statement.
  ///
  /// This lets DDC use the setter method's return value directly.
  final _operatorSetResultStack = <js_ast.Identifier?>[];

  /// Private member names in this module, organized by their library.
  final _privateNames = HashMap<Library, HashMap<String, js_ast.ScopedId>>();

  /// Holds all top-level JS symbols (used for caching or indexing fields).
  final _symbolContainer = ModuleItemContainer<js_ast.Identifier>.asObject('S',
      keyToString: (js_ast.Identifier i) => i.name);

  /// Extension member symbols for adding Dart members to JS types.
  ///
  /// These are added to the [_extensionSymbolsLibraryId]; see that field for more
  /// information.
  final _extensionSymbols = <String, js_ast.ScopedId>{};

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  final _libraries = <Library, js_ast.Identifier>{};

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = <Library, js_ast.Identifier>{};

  /// Incremental mode for expression compilation.
  ///
  /// If set to true, triggers emitting all used types, symbols, libraries,
  /// constants, urs inside the generated function.
  bool _incrementalMode = false;

  /// Modules and libraries accessed during compilation in incremental mode.
  final _incrementalModules = <String, Set<String>>{};

  /// The identifier used to reference DDC's core "dart:_runtime" library from
  /// generated JS code, typically called "dart" e.g. `dart.dcall`.
  late final js_ast.Identifier _runtimeLibraryId;

  /// The library referred to by [_runtimeLibraryId].
  final Library _runtimeLibrary;

  /// The identifier used to reference DDC's "extension method" symbols, used to
  /// safely add Dart-specific member names to JavaScript classes, such as
  /// primitive types (e.g. String) or DOM types in "dart:html".
  late final js_ast.Identifier _extensionSymbolsLibraryId;

  /// The identifier used to reference DDC's core "dart:_rti" library from
  /// generated JS code.
  ///
  /// Must manually name the dart:_rti library because there are local variables
  /// within the library that inadvertently shadow the default name.
  final _rtiLibraryId = js_ast.ScopedId('dart_rti');

  /// The library referred to by [_rtiLibraryId].
  final Library _rtiLibrary;

  /// The `Rti` class defined in [_rtiLibrary].
  final Class _rtiClass;

  /// Whether we're currently building the SDK, which may require special
  /// bootstrapping logic.
  ///
  /// This is initialized by [emitModule], which must be called before
  /// accessing this field.
  late final bool _isBuildingSdk;

  /// Whether or not to move top level symbols into top-level containers.
  ///
  /// This is set in both [emitModule] and [_emitLibrary].
  /// Depends on [_isBuildingSdk].
  bool _containerizeSymbols = false;

  /// The temporary variable that stores named arguments (these are passed via a
  /// JS object literal, to match JS conventions).
  final _namedArgumentTemp = js_ast.ScopedId('opts');

  /// The list of output module items, in the order they need to be emitted in.
  final _moduleItems = <js_ast.ModuleItem>[];

  /// The entrypoint method of a dynamic module, if any.
  Procedure? _dynamicEntrypoint;

  final Class _jsArrayClass;
  final Class _privateSymbolClass;
  final Class _linkedHashMapImplClass;
  final Class _identityHashMapImplClass;
  final Class _linkedHashSetClass;
  final Class _linkedHashSetImplClass;
  final Class _identityHashSetImplClass;
  // Helpers for async function lowering
  final Member _asyncStartMember;
  final Member _asyncAwaitMember;
  final Member _asyncReturnMember;
  final Member _asyncRethrowMember;
  final Member _asyncMakeCompleterMember;
  final Member _asyncWrapJsFunctionMember;
  // Helpers for sync* function lowering
  final Member _syncStarMakeIterableMember;
  final Member _syncStarIteratorCurrentMember;
  final Member _syncStarIteratorDatumMember;
  final Member _syncStarIteratorYieldStarMember;
  // Helpers for async* function lowering
  final Member _asyncStarHelperMember;
  final Member _asyncStreamOfControllerMember;
  final Member _asyncMakeAsyncStarStreamControllerMember;
  final Member _asyncIterationMarkerYieldSingleMember;
  final Member _asyncIterationMarkerYieldStarMember;
  final Class _asyncStreamIteratorClass;

  final Procedure _assertInteropMethod;

  final DevCompilerConstants _constants;

  final NullableInference _nullableInference;

  bool _moduleEmitted = false;

  /// Supports verbose logging with a timer.
  Ticker? _ticker;

  factory LibraryCompiler(
    Component component,
    ClassHierarchy hierarchy,
    Options options,
    Map<Library, Component> importToSummary,
    Map<Component, String> summaryToModule, {
    CoreTypes? coreTypes,
    Ticker? ticker,
    required SymbolData symbolData,
  }) {
    coreTypes ??= CoreTypes(component);
    var types = TypeEnvironment(coreTypes, hierarchy);
    var constants = DevCompilerConstants();
    var nativeTypes = NativeTypeSet(coreTypes, constants, component);
    var jsTypeRep = JSTypeRep(types, hierarchy);
    var staticTypeContext = StatefulStaticTypeContext.stacked(types);
    return LibraryCompiler._(
      ticker,
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
      symbolData,
    );
  }

  LibraryCompiler._(
      this._ticker,
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
      this._summaryToModule,
      this._symbolData)
      : _jsArrayClass = sdk.getClass('dart:_interceptors', 'JSArray'),
        _privateSymbolClass = sdk.getClass('dart:_js_helper', 'PrivateSymbol'),
        _linkedHashMapImplClass = sdk.getClass('dart:_js_helper', 'LinkedMap'),
        _identityHashMapImplClass =
            sdk.getClass('dart:_js_helper', 'IdentityMap'),
        _linkedHashSetClass = sdk.getClass('dart:collection', 'LinkedHashSet'),
        _linkedHashSetImplClass = sdk.getClass('dart:_js_helper', 'LinkedSet'),
        _identityHashSetImplClass =
            sdk.getClass('dart:_js_helper', 'IdentitySet'),
        _assertInteropMethod =
            sdk.getTopLevelProcedure('dart:_runtime', 'assertInterop'),
        _asyncStartMember =
            sdk.getTopLevelMember('dart:async', '_asyncStartSync'),
        _asyncAwaitMember = sdk.getTopLevelMember('dart:async', '_asyncAwait'),
        _asyncReturnMember =
            sdk.getTopLevelMember('dart:async', '_asyncReturn'),
        _asyncRethrowMember =
            sdk.getTopLevelMember('dart:async', '_asyncRethrow'),
        _asyncMakeCompleterMember =
            sdk.getTopLevelMember('dart:async', '_makeAsyncAwaitCompleter'),
        _asyncWrapJsFunctionMember =
            sdk.getTopLevelMember('dart:async', '_wrapJsFunctionForAsync'),
        _syncStarMakeIterableMember =
            sdk.getTopLevelMember('dart:async', '_makeSyncStarIterable'),
        _syncStarIteratorCurrentMember =
            sdk.getMember('dart:async', '_SyncStarIterator', '_current'),
        _syncStarIteratorDatumMember =
            sdk.getMember('dart:async', '_SyncStarIterator', '_datum'),
        _syncStarIteratorYieldStarMember =
            sdk.getMember('dart:async', '_SyncStarIterator', '_yieldStar'),
        _asyncStarHelperMember =
            sdk.getTopLevelMember('dart:async', '_asyncStarHelper'),
        _asyncStreamOfControllerMember =
            sdk.getTopLevelMember('dart:async', '_streamOfController'),
        _asyncMakeAsyncStarStreamControllerMember = sdk.getTopLevelMember(
            'dart:async', '_makeAsyncStarStreamController'),
        _asyncIterationMarkerYieldSingleMember =
            sdk.getMember('dart:async', '_IterationMarker', 'yieldSingle'),
        _asyncIterationMarkerYieldStarMember =
            sdk.getMember('dart:async', '_IterationMarker', 'yieldStar'),
        _asyncStreamIteratorClass =
            sdk.getClass('dart:async', 'StreamIterator'),
        _futureOrNormalizer = FutureOrNormalizer(_coreTypes),
        _typeRecipeGenerator = TypeRecipeGenerator(_coreTypes, _hierarchy),
        _extensionIndex =
            ExtensionIndex(_coreTypes, _staticTypeContext.typeEnvironment),
        _inlineTester = BasicInlineTester(_constants),
        _runtimeLibrary = sdk.getLibrary('dart:_runtime'),
        _rtiLibrary = sdk.getLibrary('dart:_rti'),
        _rtiClass = sdk.getClass('dart:_rti', 'Rti');

  /// The library for dart:core in the SDK.
  Library get _coreLibrary => _coreTypes.coreLibrary;

  /// The type used for private Dart [Symbol]s.
  InterfaceType get _privateSymbolType =>
      _coreTypes.nonNullableRawType(_privateSymbolClass);

  /// The type used for public Dart [Symbol]s.
  InterfaceType get _internalSymbolType =>
      _coreTypes.nonNullableRawType(_coreTypes.internalSymbolClass);

  final FutureOrNormalizer _futureOrNormalizer;

  /// Module can be emitted only once, and the compiler can be reused after
  /// only in incremental mode, for expression compilation only.
  js_ast.Program emitLibrary(Library library) {
    if (_moduleEmitted) {
      throw StateError('Can only call emitLibrary once.');
    }
    _ticker?.logMs('Emitting library');
    _currentLibrary = library;
    _component = library.enclosingComponent!;
    _isBuildingSdk = library.importUri.scheme == 'dart';

    // For runtime performance reasons, we only containerize SDK symbols in web
    // libraries. Otherwise, we use a 600-member cutoff before a module is
    // containerized. This is somewhat arbitrary but works promisingly for the
    // SDK and Flutter Web.
    if (!_isBuildingSdk) {
      // The number of DDC top-level symbols scales with the number of
      // non-static class members across an entire module.
      var uniqueNames = HashSet<String>();
      library.classes.forEach((Class c) {
        c.members.forEach((m) {
          var isStatic =
              m is Field ? m.isStatic : (m is Procedure ? m.isStatic : false);
          if (isStatic) return;
          var name = js_ast.toJSIdentifier(
              m.name.text.replaceAll(js_ast.invalidCharInIdentifier, '_'));
          uniqueNames.add(name);
        });
      });
      _containerizeSymbols = uniqueNames.length > 600;
    }
    var items = _startLibrary(library);
    _nullableInference.allowNotNullDeclarations = _isBuildingSdk;
    _typeTable = TypeTable('T', _runtimeCall);
    // Insert a circular reference so neither the constant table or its cache
    // are optimized away by V8. Required for expression evaluation.
    var constTableDeclaration =
        js.statement('const # = Object.create({# : () => (#, #)});', [
      _constTable,
      js_ast.LiteralString('_'),
      _constTableCache.containerId,
      _constTable
    ]);
    _moduleItems.add(constTableDeclaration);

    // Record a safe index after the declaration of type generators and
    // top-level symbols but before the declaration of any functions.
    // Various preliminary data structures must be inserted here prior before
    // referenced by the rest of the module.
    var safeDeclarationIndex = _moduleItems.length;
    _constTableInsertionIndex = safeDeclarationIndex;

    // Add implicit dart:core dependency so it is first.
    _emitLibraryName(_coreTypes.coreLibrary);
    _ticker?.logMs('Added table declarations');

    // Visit the library and emit its code.
    //
    // NOTE: classes are not necessarily emitted in this order.
    // Order will be changed as needed so the resulting code can execute.
    // This is done by forward declaring items.
    _emitLibrary(library);
    _ticker?.logMs('Emitted library: ${library.importUri}');

    // Emit hoisted assert strings
    _moduleItems.insertAll(safeDeclarationIndex, _uriContainer.emit());

    _moduleItems.insertAll(safeDeclarationIndex, _constTableCache.emit());

    if (_constLazyAccessors.isNotEmpty) {
      var constTableBody = _runtimeStatement(
          'defineLazy(#, { # })', [_constTable, _constLazyAccessors]);
      _moduleItems.insert(_constTableInsertionIndex, constTableBody);
      _constLazyAccessors.clear();
    }

    // Register the local const cache for this module so it can be cleared on a
    // hot restart.
    if (_constTableCache.isNotEmpty) {
      _moduleItems.add(_runtimeCall('moduleConstCaches.set(#, #)', [
        js_ast.string(_options.moduleName),
        _constTableCache.containerId
      ]).toStatement());
    }
    _ticker?.logMs('Added table caches');
    // Add all type hierarchy rules for the interface types used in this module.
    // TODO(nshahan) This is likely more information than the application
    // really uses. It could be reduced to only the types of values that are
    // potentially "live" in the module which includes the types of all the
    // constructor invocations and the types of the constructors torn off
    // (potentially constructed) within the module. The current constructor
    // tearoff lowering does make this harder to know since all constructors
    // appeared to be invoked in the body of the method created by the
    // lowering. For now we over estimate and simply use all the interface
    // types introduced by all the classes defined in the module.
    for (var cls in library.classes) {
      var type = cls.getThisType(_coreTypes, Nullability.nonNullable);
      _typeRecipeGenerator.addLiveTypeAncestries(type);
    }
    var universeClass =
        _rtiLibrary.classes.firstWhere((cls) => cls.name == '_Universe');

    // Emits either an 'addRules', 'addOrUpdateRules', or 'deleteRules'
    // statement for a JSON-serializable [rules] made of RTI type rules.
    //
    // 'addRules' overrides existing state. Calling this function multiple
    // times is safe for types whose hierarchies can be exhaustively
    // discovered at compile-time, which is true for all types that aren't
    // 'LegacyJavaScriptObject'.
    //
    // TODO: The above assumption may not hold if a class's hierarchy
    // changes after a hot reload. Outdated 'addRules' invocations (during
    // linking) may clobber updated type rules.
    js_ast.Statement emitRulesStatement(Object? rules,
        {required String rulesFunction}) {
      var template = '#._Universe.#(#, JSON.parse(#))';
      var rulesExpr = js.call(template, [
        _emitLibraryName(_rtiLibrary),
        _emitMemberName(rulesFunction, memberClass: universeClass),
        _runtimeCall('typeUniverse'),
        js.string(jsonEncode(rules), "'")
      ]);
      return rulesExpr.toStatement();
    }

    // We must emit type rules for every interface type encountered by DDC,
    // with several caveats:
    // 1) 'LegacyJavaScriptObject' has special treatment. Its hierarchy
    //    accumulates across libraries and must always be emitted in 'append'
    //    mode ('addOrUpdateRules') to avoid clobbering its previous state.
    // 2) We manually add rules for mutual subtype relationships between
    //    'LegacyJavaScriptObject' and all JavaScript interop classes. There is
    //    special redirecting rule logic in the dart:_rti library for interop
    //    types because otherwise they would duplicate a lot of supertype
    //    information.
    // 3) The RTI treats an empty type hierarchy as implicitly containing
    //    'Object'. We explicitly emit 'deleteRules' instructions in case
    //    a type hierarchy was deleted or edited to extend 'Object' after hot
    //    reload.
    var legacyJavaScriptObjectRecipe = _typeRecipeGenerator.interfaceTypeRecipe(
        _coreTypes.index
            .getClass('dart:_interceptors', 'LegacyJavaScriptObject'));
    var legacyJavaScriptObjectRules = _typeRecipeGenerator
        .liveInterfaceTypeRules[legacyJavaScriptObjectRecipe];
    var typeRulesExceptLegacyJavaScriptObject = _typeRecipeGenerator
        .liveInterfaceTypeRules
      ..remove(legacyJavaScriptObjectRecipe);
    var typesThatOnlyExtendObject =
        Set.from(_typeRecipeGenerator.visitedInterfaceTypeRecipes)
          ..removeAll(typeRulesExceptLegacyJavaScriptObject.keys)
          ..remove(legacyJavaScriptObjectRecipe);
    var legacyJavaScriptObjectMutualSubtypingRules =
        _typeRecipeGenerator.updateLegacyJavaScriptObjectRules;

    if (typeRulesExceptLegacyJavaScriptObject.isNotEmpty) {
      _typeRuleLinks.add(emitRulesStatement(
          typeRulesExceptLegacyJavaScriptObject,
          rulesFunction: 'addRules'));
    }
    if (typesThatOnlyExtendObject.isNotEmpty) {
      _typeRuleLinks.add(emitRulesStatement(typesThatOnlyExtendObject.toList(),
          rulesFunction: 'deleteRules'));
    }
    if (legacyJavaScriptObjectRules != null) {
      _typeRuleLinks.add(emitRulesStatement({
        legacyJavaScriptObjectRecipe: legacyJavaScriptObjectRules,
      }, rulesFunction: 'addOrUpdateRules'));
    }
    if (legacyJavaScriptObjectMutualSubtypingRules.isNotEmpty) {
      _typeRuleLinks.add(emitRulesStatement(
          legacyJavaScriptObjectMutualSubtypingRules,
          rulesFunction: 'addOrUpdateRules'));
    }

    var jsInteropTypeRecipes = _typeRecipeGenerator.visitedJsInteropTypeRecipes;
    if (jsInteropTypeRecipes.isNotEmpty) {
      // Update the `LegacyJavaScriptObject` class with the type tags for all
      // interop types in this module. This is the quick path for simple type
      // tests that matches the rules encoded above.
      var legacyJavaScriptObjectClass = _coreTypes.index
          .getClass('dart:_interceptors', 'LegacyJavaScriptObject');
      var legacyJavaScriptObjectClassRef = _emitClassRef(
          legacyJavaScriptObjectClass.getThisType(
              _coreTypes, Nullability.nonNullable));
      var interopRecipesArray = js_ast.stringArray([
        _typeRecipeGenerator.interfaceTypeRecipe(legacyJavaScriptObjectClass),
        ...jsInteropTypeRecipes
      ]);
      var jsInteropRules = _runtimeStatement('addRtiResources(#, #)',
          [legacyJavaScriptObjectClassRef, interopRecipesArray]);
      _typeRuleLinks.add(jsInteropRules);
    }

    // Annotates the type parameter variances for each interface.
    var typeVariances = _typeRecipeGenerator.variances;
    if (typeVariances.isNotEmpty) {
      var addTypeParameterVariancesTemplate = '#._Universe.#(#, JSON.parse(#))';
      var addTypeParameterVariancesStatement =
          js.call(addTypeParameterVariancesTemplate, [
        _emitLibraryName(_rtiLibrary),
        _emitMemberName('addTypeParameterVariances',
            memberClass: universeClass),
        _runtimeCall('typeUniverse'),
        js.string(jsonEncode(typeVariances), "'")
      ]).toStatement();
      _typeRuleLinks.add(addTypeParameterVariancesStatement);
    }

    // Certain RTIs must be emitted during RTI normalization. We cache these
    // eagerly with 'findType' (without normalization) to avoid infinite loops.
    // See normalization functions in: sdk/lib/_internal/js_shared/lib/rti.dart
    if (_isSdkInternalRuntime(_currentLibrary!)) {
      var prerequisiteRtiTypes = [
        _coreTypes.objectLegacyRawType,
        _coreTypes.objectNullableRawType,
        NeverType.legacy()
      ];
      prerequisiteRtiTypes.forEach((type) {
        var recipe = _typeRecipeGenerator
            .recipeInEnvironment(type, EmptyTypeEnvironment())
            .recipe;
        _typeRuleLinks.add(js.call('#.findType("$recipe")',
            [_emitLibraryName(_rtiLibrary)]).toStatement());
      });
    }

    // Insert a check that runs when loading this module to verify that the null
    // safety mode it was compiled in matches the mode used when compiling the
    // dart sdk module.
    //
    // This serves as a sanity check at runtime that we don't have an
    // infrastructure issue that loaded js files compiled with different modes
    // into the same application.
    js_ast.LiteralBool soundNullSafety;
    switch (_component.mode) {
      case NonNullableByDefaultCompiledMode.Strong:
        soundNullSafety = js_ast.LiteralBool(true);
      case NonNullableByDefaultCompiledMode.Weak:
        soundNullSafety = js_ast.LiteralBool(false);
      default:
        throw StateError('Unsupported Null Safety mode ${_component.mode}, '
            'in ${_component.location?.file}.');
    }
    if (!_isBuildingSdk) {
      items.add(_runtimeStatement(
          '_checkModuleNullSafetyMode(#)', [soundNullSafety]));
    }

    // Additional method used by the module system to link class hierarchies.
    _moduleItems.add(_emitLibraryLinkMethod(_currentLibrary!));
    _ticker?.logMs('Emitted library link method');

    // Visit directives (for exports)
    _emitExports(library);
    _ticker?.logMs('Emitted exports');

    // Declare imports and extension symbols
    _emitImportsAndExtensionSymbols(items,
        forceExtensionSymbols: allowedNativeTest(library.importUri));
    _ticker?.logMs('Emitted imports and extension symbols');

    // Emit the hoisted type table cache variables
    items.addAll(_typeTable.dischargeBoundTypes());
    _ticker?.logMs('Emitted type table');

    var compiledLibrary = _finishLibrary(
        items, '${library.importUri}', _emitLibraryName(library));
    _ticker?.logMs('Finished emitting module');

    // Mark as finished for incremental mode, so it is safe to
    // switch to the incremental mode for expression compilation.
    _moduleEmitted = true;
    return compiledLibrary;
  }

  /// Returns a method that will perform all class hierarchy operations for the
  /// classes defined in this module.
  ///
  /// At a high level this method performs the prototype stitching for all
  /// `class A extends B` relationships but in practice will also include the
  /// operations that implicitly depend on those relationships to be established
  /// so they can walk the prototype chain.
  js_ast.Statement _emitLibraryLinkMethod(Library library) {
    var libraryName = _emitLibraryName(library);
    var nameExpr = js_ast.PropertyAccess.field(libraryName, 'link');
    var functionName = _emitScopedId('link__${_jsLibraryName(library)}');

    var parameters = const <js_ast.Parameter>[];
    var body = js_ast.Block([
      ..._classExtendsLinks,
      // The ordering of extensions member definition and mixin applications
      // is fragile but important for the correct functionality of the html and
      // friends libraries. All mixins should have extension members defined
      // before being applied. Mixin classes are handled here, regular mixins
      // are handled inside the mixin application closure.
      ..._mixinClassDefineExtensionMemberLinks,
      ..._mixinApplicationLinks,
      // Extension members defined and mixed in above will be discovered during
      // the prototype walk during these extension member definitions.
      ..._defineExtensionMemberLinks,
      ..._nativeExtensionLinks,
      ..._typeRuleLinks,
    ]);
    var function =
        js_ast.NamedFunction(functionName, js_ast.Fun(parameters, body));
    return js.statement('# = #', [nameExpr, function]);
  }

  /// Choose a canonical name from the [library] element.
  String _jsLibraryName(Library library) {
    return libraryUriToJsIdentifier(library.importUri);
  }

  /// Choose a module-unique name from the [library] element.
  ///
  /// Returns null if no alias exists or there are multiple output paths
  /// (e.g., when compiling the Dart SDK).
  ///
  /// This never uses the library's name (the identifier in the `library`
  /// declaration) as it doesn't have any meaningful rules enforced.
  String? _jsLibraryAlias(Library library) {
    var uri = library.importUri.normalizePath();
    if (uri.isScheme('dart')) return null;

    Iterable<String> segments;
    if (uri.isScheme('package')) {
      // Strip the package name.
      segments = uri.pathSegments.skip(1);
    } else {
      segments = uri.pathSegments;
    }

    var qualifiedPath =
        js_ast.pathToJSIdentifier(p.withoutExtension(segments.join('/')));
    return qualifiedPath == _jsLibraryName(library) ? null : qualifiedPath;
  }

  /// Debugger friendly name for a Dart [library].
  String _jsLibraryDebuggerName(Library library) => '${library.importUri}';

  /// Debugger friendly names for all parts in a Dart [library].
  Iterable<String> _jsPartDebuggerNames(Library library) =>
      library.parts.map((part) => part.partUri);

  /// True when [library] is the sdk internal library 'dart:_internal'.
  bool _isDartInternal(Library library) => _isDartLibrary(library, '_internal');

  /// True when [library] is the sdk internal library 'dart:_js_helper'.
  bool _isDartJsHelper(Library library) =>
      _isDartLibrary(library, '_js_helper');

  /// True when [library] is the sdk internal library 'dart:_internal'.
  bool _isDartForeignHelper(Library library) =>
      _isDartLibrary(library, '_foreign_helper');

  /// True when [library] is the sdk library 'dart:js_util'.
  bool _isDartJsUtil(Library library) => _isDartLibrary(library, 'js_util');

  /// Returns true if [library] is identified by [name].
  bool _isDartLibrary(Library library, String name) {
    var importUri = library.importUri;
    return importUri.isScheme('dart') && importUri.path == name;
  }

  /// Returns true if the library [l] is "dart:_runtime".
  bool _isSdkInternalRuntime(Library l) {
    return isSdkInternalRuntimeUri(l.importUri);
  }

  /// Gets the module import URI that contains [library].
  String _libraryToModule(Library library, {bool throwIfNotFound = true}) {
    if (library.importUri.isScheme('dart')) {
      // TODO(jmesserly): we need to split out HTML.
      return js_ast.dartSdkModule;
    }
    var summary = _importToSummary[library];
    if (summary == null) {
      if (throwIfNotFound) {
        throw StateError('Could not find summary for library "$library".');
      }
      return '';
    }
    var moduleName = _summaryToModule[summary];
    if (moduleName == null) {
      if (throwIfNotFound) {
        throw StateError('Could not find module name for library "$library" '
            'from component "$summary".');
      }
      return '';
    }
    return moduleName;
  }

  void _emitLibrary(Library library) {
    _staticTypeContext.enterLibrary(_currentLibrary!);

    if (_isBuildingSdk) {
      _containerizeSymbols = _isWebLibrary(library.importUri);
    }

    if (_isSdkInternalRuntime(library)) {
      // Add embedded globals.
      _moduleItems.add(
          _runtimeCall('typeUniverse = #', [js_ast.createRtiUniverse()])
              .toStatement());
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
      _emitLibraryMembers(library);
      library.classes.forEach(_emitClass);
    } else {
      library.classes.forEach(_emitClass);
      _emitLibraryMembers(library);
    }
    _staticTypeContext.leaveLibrary(_currentLibrary!);
  }

  void _emitExports(Library library) {
    library.additionalExports.forEach(_emitExport);
  }

  void _emitExport(Reference export) {
    var library = _currentLibrary!;

    // We only need to export main as it is the only method part of the
    // publicly exposed JS API for a library.

    var node = export.node;
    if (node is Procedure && node.name.text == 'main') {
      // Don't allow redefining names from this library.
      var name = _emitTopLevelName(node);
      _moduleItems.add(js.statement(
          '#.# = #;', [_emitLibraryName(library), name.selector, name]));
    }
  }

  /// Called to emit class declarations.
  ///
  /// Class hierarchy links are collected but not emitted as part of the
  /// declaration. Those operations will be contained in the link method for the
  /// library.
  void _emitClass(Class c) {
    // Avoid attempting to compile classes we reach through emitting class
    // extends supertypes when they are not members of the library being
    // compiled.
    // TODO(nshahan): Once `_declareBeforeUse` is removed this escape hatch will
    // no longer be necessary.
    if (c.enclosingLibrary != _currentLibrary) return;
    var savedClass = _currentClass;
    var savedLibrary = _currentLibrary;
    var savedUri = _currentUri;
    _currentClass = c;
    _currentLibrary = c.enclosingLibrary;
    _currentUri = c.fileUri;
    var savedTypeEnvironment = _currentTypeEnvironment;
    // When compiling the type heritage of the class we can't reference an rti
    // object attached to an instance. Instead we construct a type environment
    // manually when needed. Later we use the rti attached to an instance for
    // a simpler representation within instance members of the class.
    _currentTypeEnvironment = ClassTypeEnvironment(c.typeParameters);

    // Mixins are unrolled in _defineClass.
    if (!c.isAnonymousMixin) {
      // If this class is annotated with `@JS`, then we only need to emit the
      // non-external factories and static members.
      if (!hasJSInteropAnnotation(c)) {
        _moduleItems.add(_emitClassDeclaration(c));
      } else {
        var interopClassDef = _emitJSInteropClassNonExternalMembers(c);
        if (interopClassDef != null) _moduleItems.add(interopClassDef);
      }
    }

    // The const table depends on dart.defineLazy, so emit it after the SDK.
    if (_isSdkInternalRuntime(_currentLibrary!)) {
      _constTableInsertionIndex = _moduleItems.length;
    }

    _currentClass = savedClass;
    _currentLibrary = savedLibrary;
    _currentUri = savedUri;
    _currentTypeEnvironment = savedTypeEnvironment;
  }

  static js_ast.Identifier _emitIdentifier(String name) =>
      js_ast.Identifier(js_ast.toJSIdentifier(name));

  static js_ast.ScopedId _emitScopedId(String name,
          {bool needsCapture = false}) =>
      js_ast.ScopedId(js_ast.toJSIdentifier(name), needsCapture: needsCapture);

  js_ast.Statement _emitClassDeclaration(Class c) {
    var className = _emitTopLevelNameNoExternalInterop(c);
    var savedClassProperties = _classProperties;
    _classProperties =
        ClassPropertyModel.build(_types, _extensionTypes, _virtualFields, c);

    var body = <js_ast.Statement>[];

    // ClassPropertyModel.build introduces symbols for virtual field accessors.
    _classProperties!.virtualFields.forEach((field, virtualField) {
      // TODO(vsm): Clean up this logic.
      //
      // Typically, [emitClassPrivateNameSymbol] creates a new symbol.  If it
      // is called multiple times, that symbol is cached.  If the former,
      // assign directly to [virtualField].  If the latter, copy the old
      // variable to [virtualField].
      var symbol = _emitClassPrivateNameSymbol(
          c.enclosingLibrary, getLocalClassName(c), field, virtualField);
      if (symbol != virtualField) {
        _addSymbol(virtualField, _getSymbolValue(symbol));
        if (!_containerizeSymbols) {
          body.add(js.statement('const # = #;', [virtualField, symbol]));
        }
      }
    });

    var jsCtors = _defineConstructors(c, className);
    var jsProperties = _emitClassProperties(c);
    var jsStaticMethodTypeTags = <js_ast.Statement>[];
    for (var member in c.procedures) {
      // TODO(#57049): We tag all static members because we don't know if
      // they've been changed after a hot reload. This won't be necessary if we
      // can tag them during the delta diff phase.
      if (member.isStatic && _reifyTearoff(member) && !member.isExternal) {
        var propertyAccessor = _emitStaticTarget(member);
        var result = js.call(
            '#.#', [propertyAccessor.receiver, propertyAccessor.selector]);
        // We only need to tag static functions that are torn off at
        // compile-time. We attach these at late so tearoffs have access to
        // their types.
        var reifiedType = member.function
            .computeThisFunctionType(member.enclosingLibrary.nonNullable);
        jsStaticMethodTypeTags.add(
            _emitFunctionTagged(result, reifiedType, asLazy: true)
                .toStatement());
      }
    }

    _emitSuperHelperSymbols(body);

    // Emit the class, e.g. `core.Object = class Object { ... }`
    _defineClass(c, className, jsProperties, body);
    body.addAll(jsCtors);
    body.addAll(jsStaticMethodTypeTags);

    // Emit things that come after the ES6 `class ... { ... }`.

    /// Collects all implemented types in the ancestry of [cls].
    Iterable<Supertype> transitiveImplementedTypes(Class cls) {
      var allImplementedTypes = <Supertype>{};
      var toVisit = ListQueue<Supertype>()..addAll(cls.implementedTypes);
      if (cls.isMixinApplication) {
        // Implemented types can come through the immediate mixin so we seed
        // the search with it as well.
        var mixedInType = cls.mixedInType;
        if (mixedInType != null) toVisit.add(mixedInType);
      }
      while (toVisit.isNotEmpty) {
        var supertype = toVisit.removeFirst();
        var superclass = supertype.classNode;
        if (allImplementedTypes.contains(supertype) ||
            superclass == _coreTypes.objectClass) {
          continue;
        }
        toVisit.addAll(superclass.supers);
        // Skip encoding the synthetic classes in the type rules because they
        // will never be instantiated or appear in type tests.
        if (superclass.isAnonymousMixin) continue;
        allImplementedTypes.add(supertype);
      }
      return allImplementedTypes;
    }

    // Tag all classes with the resources needed by the dart:_rti library.
    var name = _typeRecipeGenerator.interfaceTypeRecipe(c);
    var implementedRecipes = [
      name,
      for (var type in transitiveImplementedTypes(c))
        _typeRecipeGenerator.interfaceTypeRecipe(type.classNode)
    ];
    body.add(_runtimeStatement('addRtiResources(#, #)',
        [className, js_ast.stringArray(implementedRecipes)]));
    _emitClassSignature(c, className, body);
    _initExtensionSymbols(c);
    if (c.isMixinClass || c.isLegacyMixinEligible(_coreTypes)) {
      _defineExtensionMembers(className, _mixinClassDefineExtensionMemberLinks);
    } else if (!c.isMixinDeclaration) {
      _defineExtensionMembers(className, _defineExtensionMemberLinks);
    }

    var typeFormals = c.typeParameters;
    if (typeFormals.isNotEmpty) {
      var genericClassStmts =
          _defineGenericClass(typeFormals, js_ast.Statement.from(body));
      body = [...genericClassStmts];
    }

    if (c == _coreTypes.objectClass) {
      // Avoid polluting the native JavaScript Object prototype with the members
      // of the Dart Core Object class.
      // Instead, just assign the identity equals method.
      _nativeExtensionLinks.add(_runtimeStatement('_installIdentityEquals()'));
    } else {
      for (var peer in _extensionTypes.getNativePeers(c)) {
        _registerExtensionType(c, peer, body);
      }
    }
    _classProperties = savedClassProperties;
    return js_ast.Statement.from(body);
  }

  /// Emits a class declaration for the JS interop class [c] for any
  /// non-external factories or static members.
  ///
  /// If [c] is not an interop class or does not contain non-external factories
  /// or static members, returns null.
  js_ast.Statement? _emitJSInteropClassNonExternalMembers(Class c) {
    if (!hasJSInteropAnnotation(c)) return null;
    var className = _emitTopLevelNameNoExternalInterop(c);

    // Non-external procedures and statics are still emitted
    var nonExternalProperties = <js_ast.Property>[];
    // Add factories and static methods.
    for (var procedure in c.procedures) {
      if (procedure.isExternal) continue;
      // Don't emit tear-offs for @staticInterop members as they're disallowed.
      if (_isStaticInteropTearOff(procedure)) continue;
      if (procedure.isFactory && !procedure.isRedirectingFactory) {
        // Skip redirecting factories (they've already been resolved).
        var factory = _emitFactoryConstructor(procedure);
        if (factory != null) nonExternalProperties.add(factory);
      } else if (procedure.isStatic) {
        var staticMethod = _emitMethodDeclaration(procedure);
        if (staticMethod != null) nonExternalProperties.add(staticMethod);
      }
    }

    // Add static fields and setters.
    var staticFields =
        c.fields.where((f) => f.isStatic && !f.isExternal).toList();
    var staticFieldNames = Set.of(staticFields.map((f) => f.name));
    var staticSetters = c.procedures.where(
        (p) => p.isStatic && p.isAccessor && staticFieldNames.contains(p.name));
    var members = [...staticFields, ...staticSetters];
    if (members.isNotEmpty) {
      nonExternalProperties.addAll(_emitLazyMembers(
          _emitTopLevelNameNoExternalInterop(c),
          members,
          (n) => _emitStaticMemberName(n.name.text)));
    }

    // Avoid unnecessary code emission if there are no members we care about.
    if (nonExternalProperties.isNotEmpty) {
      // Note that this class has no heritage. This class should never be used
      // as a type. It's merely a placeholder for static members.
      var body = <js_ast.Statement>[
        _emitClassStatement(c, className, null, nonExternalProperties)
            .toStatement()
      ];
      var typeFormals = c.typeParameters;
      if (typeFormals.isNotEmpty) {
        var genericClassStmts =
            _defineGenericClass(typeFormals, js_ast.Statement.from(body));
        body = genericClassStmts;
      }
      return js_ast.Statement.from(body);
    }
    return null;
  }

  /// Emits a generic class with additional initialization logic.
  List<js_ast.Statement> _defineGenericClass(
      List<TypeParameter> formals, js_ast.Statement body) {
    assert(formals.isNotEmpty);
    return [
      ..._typeTable.dischargeFreeTypes(formals),
      body,
    ];
  }

  js_ast.Statement _emitClassStatement(Class c, js_ast.Expression className,
      js_ast.Expression? heritage, List<js_ast.Property> properties) {
    var classIdentifier = _emitScopedId(getLocalClassName(c));
    if (_options.emitDebugSymbols) classIdentifiers[c] = classIdentifier;
    if (heritage != null) {
      _classExtendsLinks
          .add(_runtimeStatement('classExtends(#, #)', [className, heritage]));
    }
    var classExpr = js_ast.ClassExpression(classIdentifier, null, properties);
    var libraryExpr = (className as js_ast.PropertyAccess).receiver;
    var propertyExpr = className.selector;
    return _runtimeStatement(
        'declareClass(#, #, #)', [libraryExpr, propertyExpr, classExpr]);
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
      List<js_ast.Property> properties,
      List<js_ast.Statement> body) {
    var staticProperties = properties.where((m) => m.isStatic).toList();
    var instanceProperties = properties.where((m) => !m.isStatic).toList();

    body.add(_emitClassStatement(c, className, heritage, staticProperties));
    var superclassId = _emitScopedId(getLocalClassName(c.superclass!));
    var classId = className is js_ast.Identifier
        ? className
        : _emitScopedId(getLocalClassName(c));

    var mixinMemberClass =
        js_ast.ClassExpression(classId, superclassId, instanceProperties);

    js_ast.Node arrowFnBody = mixinMemberClass;
    var extensionInit = <js_ast.Statement>[];
    // The extension members need to be defined here when the class is created
    // inside the `mixinOn` closure. The prototype chain is connected in this
    // closure as well so it is safe to perform this operation here instead of
    // the link method.
    _defineExtensionMembers(classId, extensionInit);
    if (extensionInit.isNotEmpty) {
      extensionInit.insert(0, mixinMemberClass.toStatement());
      extensionInit.add(classId.toReturn());
      arrowFnBody = js_ast.Block(extensionInit);
    }

    body.add(js.statement('#[#] = #', [
      className,
      _runtimeCall('mixinOn'),
      js_ast.ArrowFun([superclassId], arrowFnBody)
    ]));
  }

  /// Emits code required to represent [c] as a series of statements in [body].
  ///
  /// [properties] holds methods, fields, or properties in [c].
  void _defineClass(Class c, js_ast.Expression className,
      List<js_ast.Property> properties, List<js_ast.Statement> body) {
    if (c == _coreTypes.objectClass) {
      body.add(_emitClassStatement(c, className, null, properties));
      return;
    }

    js_ast.Expression emitClassRef(InterfaceType t) {
      // TODO(jmesserly): investigate this. It seems like `lazyJSType` is
      // invalid for use in an `extends` clause, hence this workaround.
      return _emitJSInterop(t.classNode) ?? _emitClassRef(t);
    }

    // Find the real (user declared) superclass and the list of mixins.
    // We'll use this to unroll the intermediate classes.
    //
    // TODO(jmesserly): consider using Kernel's mixin unrolling.
    var superclass = _superClassAsWritten(c);
    var supertype = identical(c.superclass, superclass)
        ? c.supertype!.asInterfaceType
        : _hierarchy.getClassAsInstanceOf(c, superclass)!.asInterfaceType;
    // All mixins (real and anonymous) classes applied to c.
    var mixinApplications = [
      if (c.mixedInClass != null) c.mixedInClass,
      for (var sc = c.superclass!;
          sc.isAnonymousMixin && sc.mixedInClass != null;
          sc = sc.superclass!)
        sc,
    ].reversed.toList();

    var hasUnnamedSuper = _hasUnnamedInheritedConstructor(superclass);

    void emitMixinConstructors(js_ast.Expression className,
        Class mixinSuperclass, Class mixinClass, InterfaceType mixin) {
      for (var ctor in mixinSuperclass.constructors) {
        var savedUri = _currentUri;
        _currentUri = ctor.enclosingClass.fileUri;

        var sharedParams = _emitParameters(ctor.function, isForwarding: true);
        var mixinConstructorParams = [
          if (_requiresRtiForInstantiation(mixinSuperclass)) _rtiParam,
          ...sharedParams
        ];
        var superConstructorArgs = [
          if (_requiresRtiForInstantiation(ctor.enclosingClass))
            js_ast.LiteralNull(),
          ...sharedParams
        ];

        js_ast.Statement? mixinCtor;
        if (_hasUnnamedConstructor(mixin.classNode)) {
          var mixinRti = _requiresRtiForInstantiation(mixin.classNode)
              ? js_ast.LiteralNull()
              : null;
          mixinCtor = js.statement('#.#.call(this, #);', [
            emitClassRef(mixin),
            _usesMixinNew(mixin.classNode)
                ? _runtimeCall('mixinNew')
                : _constructorName(''),
            [if (mixinRti != null) mixinRti],
          ]);
        }

        var name = ctor.name.text;
        var ctorBody = [
          if (mixinCtor != null) mixinCtor,
          if (name != '' || hasUnnamedSuper)
            _emitSuperConstructorCall(
                ctor, className, name, superConstructorArgs),
        ];
        // TODO(nshahan) Record the name for this constructor in memberNames.
        body.add(_addConstructorToClass(c, className, _constructorName(name),
            js_ast.Fun(mixinConstructorParams, js_ast.Block(ctorBody))));
        _currentUri = savedUri;
      }
    }

    var savedTopLevelClass = _classEmittingExtends;
    _classEmittingExtends = c;

    // Unroll mixins.
    var baseClass = emitClassRef(supertype);

    // TODO(jmesserly): we need to unroll kernel mixins because the synthetic
    // classes lack required synthetic members, such as constructors.
    //
    // Also, we need to generate one extra level of nesting for alias classes.
    for (var i = 0; i < mixinApplications.length; i++) {
      var m = mixinApplications[i]!;
      var mixinClass = m.isAnonymousMixin ? m.mixedInClass! : m;
      var mixinType =
          _hierarchy.getClassAsInstanceOf(c, mixinClass)!.asInterfaceType;
      var mixinName =
          '${getLocalClassName(superclass)}_${getLocalClassName(mixinClass)}';
      var mixinId = _emitScopedId('$mixinName\$');
      // Collect all forwarding stub members from anonymous mixins classes.
      // These can contain covariant parameter checks that need to be applied.
      var savedClassProperties = _classProperties;
      _classProperties =
          ClassPropertyModel.build(_types, _extensionTypes, _virtualFields, m);
      var forwardingMembers = {
        for (var procedure in m.procedures)
          if (procedure.isForwardingStub && !procedure.isAbstract)
            procedure.name.text: procedure
      };
      // Mixin applications can introduce their own reference to the type
      // parameters from the class being mixed in and their use can appear in
      // the forwarding stubs.
      var savedTypeEnvironment = _currentTypeEnvironment;
      if (m.typeParameters.isNotEmpty) {
        assert(_currentTypeEnvironment is ClassTypeEnvironment);
        _currentTypeEnvironment = ClassTypeEnvironment(m.typeParameters);
      }
      var forwardingMethodStubs = <js_ast.Method>[];
      for (var s in forwardingMembers.values) {
        // Members are marked as "forwarding stubs" when they require a type
        // check of the arguments before calling super. It is assumed here that
        // no getters will be marked as a "forwarding stub".
        assert(!s.isGetter);
        var stub = _emitMethodDeclaration(s);
        if (stub != null) forwardingMethodStubs.add(stub);
        // If there are getters matching the setters somewhere above in the
        // class hierarchy we must also generate a forwarding getter due to the
        // representation used in the compiled JavaScript.
        if (s.isSetter) {
          var getterWrapper = _emitSuperAccessorWrapper(s, const {}, const {});
          if (getterWrapper != null) forwardingMethodStubs.add(getterWrapper);
        }
      }
      _currentTypeEnvironment = savedTypeEnvironment;
      _classProperties = savedClassProperties;

      // Bind the mixin class to a name to workaround a V8 bug with es6 classes
      // and anonymous function names.
      // TODO(leafp:) Eliminate this once the bug is fixed:
      // https://bugs.chromium.org/p/v8/issues/detail?id=7069
      body.add(js.statement('const # = #', [
        mixinId,
        js_ast.ClassExpression(
            _emitScopedId(mixinName), null, forwardingMethodStubs)
      ]));
      _classExtendsLinks
          .add(_runtimeStatement('classExtends(#, #)', [mixinId, baseClass]));
      emitMixinConstructors(mixinId, superclass, mixinClass, mixinType);
      hasUnnamedSuper = hasUnnamedSuper || _hasUnnamedConstructor(mixinClass);
      _mixinApplicationLinks.add(_runtimeStatement(
          'applyMixin(#, #)', [mixinId, emitClassRef(mixinType)]));
      baseClass = mixinId;
    }

    if (c.isMixinDeclaration && !c.isMixinClass) {
      _emitMixinStatement(c, className, baseClass, properties, body);
    } else {
      body.add(_emitClassStatement(c, className, baseClass, properties));
    }

    _classEmittingExtends = savedTopLevelClass;
  }

  /// Defines all constructors for this class as ES5 constructors.
  List<js_ast.Statement> _defineConstructors(
      Class c, js_ast.Expression className) {
    var body = <js_ast.Statement>[];
    if (c.isAnonymousMixin) {
      // We already handled this when we defined the class.
      return body;
    }

    void addConstructor(js_ast.LiteralString name, js_ast.Expression jsCtor) {
      body.add(_addConstructorToClass(c, className, name, jsCtor));
    }

    var fields = c.fields;
    for (var ctor in c.constructors) {
      if (ctor.isExternal) continue;
      var constructorName = _constructorName(ctor.name.text);
      memberNames[ctor] = constructorName.valueWithoutQuotes;
      addConstructor(
          constructorName, _emitConstructor(ctor, fields, className));
    }

    // If classElement has only factory constructors, and it can be mixed in,
    // then we need to emit a special hidden default constructor for use by
    // mixins.
    if (_usesMixinNew(c)) {
      body.add(
          js.statement('(#[#] = function() { # }).prototype = #.prototype;', [
        className,
        _runtimeCall('mixinNew'),
        [_initializeFields(fields)],
        className
      ]));
    }

    return body;
  }

  void _emitDartSymbols(
      Iterable<js_ast.ScopedId> vars, List<js_ast.ModuleItem> body) {
    for (var id in vars) {
      body.add(js.statement('const # = Symbol(#)', [id, js.string(id.name)]));
    }
  }

  void _emitSuperHelperSymbols(List<js_ast.Statement> body) {
    _emitDartSymbols(
        _superHelpers.values.map((m) => m.name as js_ast.ScopedId), body);
    _superHelpers.clear();
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
          .map((e) => _propertyName(js_ast.memberNameForDartMember(e)))
          .toList();
      body.add(_runtimeStatement('#(#, #)', [
        helperName,
        className,
        js_ast.ArrayInitializer(names, multiline: names.length > 4)
      ]));
    }

    var props = _classProperties!;
    emitExtensions('defineExtensionMethods', props.extensionMethods);
    emitExtensions('defineExtensionAccessors', props.extensionAccessors);
  }

  /// Emit the signature on the class recording the runtime type information
  void _emitClassSignature(
      Class c, js_ast.Expression className, List<js_ast.Statement> body) {
    var savedTypeEnvironment = _currentTypeEnvironment;
    _currentTypeEnvironment =
        RtiTypeEnvironment(_currentTypeEnvironment.classTypeParameters);
    var savedClass = _classEmittingSignatures;
    _classEmittingSignatures = c;

    void emitSignature(String name, List<js_ast.Property> elements) {
      if (elements.isEmpty) return;

      js_ast.Statement setSignature;
      if (!name.startsWith('Static')) {
        var proto = c == _coreTypes.objectClass
            ? js.call('Object.create(null)')
            : _runtimeCall('get${name}s(#)', [
                _emitJSObjectGetPrototypeOf(className, fullyQualifiedName: true)
              ]);

        setSignature = _runtimeStatement('set${name}Signature(#, () => #)', [
          className,
          _emitJSObjectSetPrototypeOf(
              js_ast.ObjectInitializer(elements,
                  multiline: elements.length > 1),
              proto,
              fullyQualifiedName: true)
        ]);
      } else {
        // TODO(40273) Only tagging with the names of static members until the
        // debugger consumes signature information from symbol files.
        setSignature = _runtimeStatement('set${name}Signature(#, () => #)', [
          className,
          js_ast.ArrayInitializer(elements.map((e) => e.name).toList())
        ]);
      }

      body.add(setSignature);
    }

    js_ast.Expression emitClassFieldSignature(Field field, Class fromClass) {
      var fieldType =
          _typeFromClass(field.type, field.enclosingClass!, fromClass)
              .extensionTypeErasure;
      var uri = fieldType is InterfaceType
          ? _cacheUri(
              _jsLibraryDebuggerName(fieldType.classNode.enclosingLibrary))
          : null;
      var isConst = js.boolean(field.isConst);
      var isFinal = js.boolean(field.isFinal);
      var type = _emitType(fieldType);
      var typeResolver = js_ast.ArrowFun([_rtiParam], type);
      return uri == null
          ? js('{type: #, isConst: #, isFinal: #}',
              [typeResolver, isConst, isFinal])
          : js('{type: #, isConst: #, isFinal: #, libraryUri: #}',
              [typeResolver, isConst, isFinal, uri]);
    }

    var extMethods = _classProperties!.extensionMethods;
    var extAccessors = _classProperties!.extensionAccessors;
    var staticMethods = <js_ast.Property>[];
    var instanceMethods = <js_ast.Property>[];
    var instanceMethodsDefaultTypeArgs = <js_ast.Property>[];
    var staticGetters = <js_ast.Property>[];
    var instanceGetters = <js_ast.Property>[];
    var staticSetters = <js_ast.Property>[];
    var instanceSetters = <js_ast.Property>[];
    List<js_ast.Property> getSignatureList(Procedure p) {
      // TODO(40273) Skip for all statics when the debugger consumes signature
      // information from symbol files.
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
      // Static getters/setters cannot be called with dynamic dispatch or torn
      // off. Static methods can't be called with dynamic dispatch and are
      // tagged with a type when torn off. Most are implicitly const and
      // canonicalized. Static signatures are only used by the debugger and are
      // not needed for runtime correctness.
      // TODO(40273) Skip for all statics when the debugger consumes signature
      // information from symbol files.
      if (isTearOffLowering(member)) continue;

      var name = member.name.text;
      var reifiedType = _memberRuntimeType(member, c) as FunctionType;

      // Don't add redundant signatures for inherited methods whose signature
      // did not change.  If we are not overriding, or if the thing we are
      // overriding has a different reified type from ourselves, we must
      // emit a signature on this class.  Otherwise we will inherit the
      // signature from the superclass.
      var memberOverride = c.superclass != null
          ? _hierarchy.getDispatchTarget(c.superclass!, member.name,
              setter: member.isSetter)
          : null;

      var needsSignature = memberOverride == null ||
          reifiedType != _memberRuntimeType(memberOverride, c);

      if (needsSignature) {
        js_ast.Expression type;
        var memberName = _declareMemberName(member);
        if (member.isAccessor) {
          // These signatures are used for dynamic access and to inform the
          // debugger. The `arrayRti` accessor is only used by the dart:_rti
          // library internals and should not be included in the accessible
          // signatures.
          if (c == _jsArrayClass && name == 'arrayRti') continue;
          type = _emitType(member.isGetter
              ? reifiedType.returnType
              : reifiedType.positionalParameters[0]);
        } else {
          type = _emitType(reifiedType);
          if (!member.isStatic && reifiedType.typeParameters.isNotEmpty) {
            // Instance methods with generic type parameters require extra
            // information to support dynamic calls. The default values for the
            // type parameters are encoded into a separate storage object for
            // use at runtime.
            var defaultTypeArgs = js_ast.ArrayInitializer([
              for (var parameter in reifiedType.typeParameters)
                _emitType(parameter.defaultType)
            ]);
            var typeResolver = js_ast.ArrowFun([_rtiParam], defaultTypeArgs);
            var property = js_ast.Property(memberName, typeResolver);
            instanceMethodsDefaultTypeArgs.add(property);
            // As seen below, sometimes the member signatures are added again
            // using the extension symbol as the name. That logic is duplicated
            // here to ensure there are always default type arguments accessible
            // via the same name as the signature.
            // TODO(52867): Cleanup default type argument duplication.
            if (extMethods.contains(name) || extAccessors.contains(name)) {
              var property = js_ast.Property(
                  _declareMemberName(member, useExtension: true), typeResolver);
              instanceMethodsDefaultTypeArgs.add(property);
            }
          }
        }
        var typeResolver = js_ast.ArrowFun([_rtiParam], type);
        var property = js_ast.Property(memberName, typeResolver);
        var signatures = getSignatureList(member);
        signatures.add(property);
        if (!member.isStatic &&
            (extMethods.contains(name) || extAccessors.contains(name))) {
          // TODO(52867): Cleanup signature duplication.
          var typeResolver = js_ast.ArrowFun([_rtiParam], type);
          var property = js_ast.Property(
              _declareMemberName(member, useExtension: true), typeResolver);
          signatures.add(property);
        }
      }
    }

    emitSignature('Method', instanceMethods);
    emitSignature('MethodsDefaultTypeArg', instanceMethodsDefaultTypeArgs);
    // TODO(40273) Skip for all statics when the debugger consumes signature
    // information from symbol files.
    emitSignature('StaticMethod', staticMethods);
    emitSignature('Getter', instanceGetters);
    emitSignature('Setter', instanceSetters);
    emitSignature('StaticGetter', staticGetters);
    emitSignature('StaticSetter', staticSetters);
    body.add(_runtimeStatement('setLibraryUri(#, #)',
        [className, _cacheUri(_jsLibraryDebuggerName(c.enclosingLibrary))]));

    var instanceFields = <js_ast.Property>[];
    var staticFields = <js_ast.Property>[];

    var classFields = c.fields.toList();
    for (var field in classFields) {
      // Static fields cannot be called with dynamic dispatch or torn off. The
      // signatures are only used by the debugger and are not needed for runtime
      // correctness.
      var memberName = _declareMemberName(field);
      var fieldSig = emitClassFieldSignature(field, c);
      var property = js_ast.Property(memberName, fieldSig);
      // TODO(40273) Skip static fields when the debugger consumes signature
      // information from symbol files.
      (field.isStatic ? staticFields : instanceFields).add(property);
    }
    emitSignature('Field', instanceFields);
    // TODO(40273) Skip for all statics when the debugger consumes signature
    // information from symbol files.
    emitSignature('StaticField', staticFields);
    _classEmittingSignatures = savedClass;
    _currentTypeEnvironment = savedTypeEnvironment;
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
      var fComputed =
          f.computeThisFunctionType(member.enclosingLibrary.nonNullable);
      var fComputedNamedByName = {
        for (NamedType namedParameter in fComputed.namedParameters)
          namedParameter.name: namedParameter
      };
      DartType reifyParameter(
              VariableDeclaration parameter, DartType fComputedParameter) =>
          isCovariantParameter(parameter)
              ? _coreTypes.objectRawType(member.enclosingLibrary.nullable)
              : fComputedParameter;
      NamedType reifyNamedParameter(
          VariableDeclaration parameter, NamedType fComputedNamedParameter) {
        assert(parameter.name == fComputedNamedParameter.name);
        return NamedType(parameter.name!,
            reifyParameter(parameter, fComputedNamedParameter.type));
      }

      // TODO(jmesserly): do covariant type parameter bounds also need to be
      // reified as `Object`?
      result = FunctionType(
          List<DartType>.generate(
              f.positionalParameters.length,
              (index) => reifyParameter(f.positionalParameters[index],
                  fComputed.positionalParameters[index])),
          f.returnType,
          Nullability.nonNullable,
          namedParameters: List<NamedType>.generate(
              f.namedParameters.length,
              (index) => reifyNamedParameter(f.namedParameters[index],
                  fComputedNamedByName[f.namedParameters[index].name]!))
            ..sort(),
          typeParameters: fComputed.typeParameters,
          requiredParameterCount: f.requiredParameterCount);
    }
    return _typeFromClass(result, member.enclosingClass!, fromClass)
        as FunctionType;
  }

  DartType _typeFromClass(DartType type, Class superclass, Class subclass) {
    if (identical(superclass, subclass)) return type;
    return Substitution.fromSupertype(
            _hierarchy.getClassAsInstanceOf(subclass, superclass)!)
        .substituteType(type);
  }

  js_ast.Expression _emitConstructor(
      Constructor node, List<Field> fields, js_ast.Expression className) {
    var savedUri = _currentUri;
    _currentUri = node.fileUri;
    _staticTypeContext.enterMember(node);
    var savedTypeEnvironment = _currentTypeEnvironment;
    _currentTypeEnvironment =
        ClassTypeEnvironment(node.enclosingClass.typeParameters);

    var params = <js_ast.Parameter>[];
    // Generic class constructors accept their RTI as their first argument.
    params.addAll(_emitParameters(node.function));
    var body = _withCurrentFunction(
        node.function,
        () => _superDisallowed(
            () => _emitConstructorBody(node, fields, className)));

    var end = _nodeEnd(node.fileEndOffset);
    _currentUri = savedUri;
    _staticTypeContext.leaveMember(node);
    end ??= _nodeEnd(node.enclosingClass.fileEndOffset);

    var constructor = js_ast.Fun([
      if (_requiresRtiForInstantiation(node.enclosingClass)) _rtiParam,
      ...params
    ], js_ast.Block(body))
      ..sourceInformation = end;

    _currentTypeEnvironment = savedTypeEnvironment;
    return constructor;
  }

  List<js_ast.Statement> _emitConstructorBody(
    Constructor node,
    List<Field> fields,
    js_ast.Expression className,
  ) {
    var cls = node.enclosingClass;

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    var fn = node.function;
    var body = _emitArgumentInitializers(fn, node.name.text);

    // Class instances with type arguments are bound to their RTI on creation.
    // This must be bound early, as instantiated fields may reference this RTI.
    if (_requiresRtiForInstantiation(cls)) {
      // Only set the rti if there isn't one already. This avoids superclasses
      // overwriting the value already set by a subclass.
      var rtiProperty = _propertyName(js_ast.FixedNames.rtiName);
      body.add(js.statement('this.# = this.# || # || #', [
        rtiProperty,
        rtiProperty,
        _rtiParam,
        _runtimeCall('getReifiedType(this)')
      ]));
    }

    // Redirecting constructors are not allowed to have conventional
    // initializers but can have variable declarations in the form of
    // initializers to support named arguments appearing anywhere in the
    // arguments list.
    if (node.initializers.any((i) => i is RedirectingInitializer)) {
      body.add(_emitRedirectingConstructor(node.initializers, className));
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
    var superCall = node.initializers.whereType<SuperInitializer>().firstOrNull;
    var jsSuper = _emitSuperConstructorCallIfNeeded(cls, className, superCall);
    if (jsSuper != null) {
      // TODO(50465) Fix incorrect assumption there should always be a super
      // initializer here.
      if (superCall != null) jsSuper.sourceInformation = _nodeStart(superCall);
      body.add(jsSuper);
    }

    body.add(_emitFunctionScopedBody(fn));
    return body;
  }

  /// Returns the "actual" superclass of [c].
  ///
  /// Walks up the superclass chain looking for the first actual class
  /// skipping any synthetic classes inserted by the CFE.
  Class _superClassAsWritten(Class c) {
    var superclass = c.superclass!;
    while (superclass.isAnonymousMixin) {
      superclass = superclass.superclass!;
    }
    return superclass;
  }

  /// Returns `true` if [cls] requires/accepts an RTI during instantiation.
  ///
  /// We check [cls]'s transitive super classes for generic type parameters,
  /// but we do not consider anonymous mixins, implemented types or mixin on
  /// clauses - as their constructors are never invoked via super calls.
  /// Synthetic mixins are also skipped (despite sometimes having type
  /// parameters) since they can't be referenced during instantiation.
  ///
  /// Context: type arguments must be provided to a generic class during its
  /// instantiation. To avoid extraneous RTI evals, we pass the entire class's
  /// RTI instead of each type parameter's RTI individually. RTIs are attached
  /// to the instance on the hidden '$ti' field (see: FixedNames.rtiName). We
  /// attach RTIs eagerly (i.e., closer to the 'leaf' than the 'root') for
  /// simplicity. Setters on 'this' propagate up super calls since Dart super
  /// calls are synthetic. Ordinary JS super calls would require us to
  /// propagate the RTI all the way to the 'uppermost' generic class.
  bool _requiresRtiForInstantiation(Class? cls) {
    if (cls == null) return false;
    var cachedResult = _requiresRtiForInstantiationCache[cls];
    if (cachedResult != null) return cachedResult;
    // Skip synthetic mixins since their RTIs are never needed during
    // instantiation.
    if (cls.isAnonymousMixin) {
      cls = _superClassAsWritten(cls);
    }
    var hasTypeParameters = cls.typeParameters.isNotEmpty ||
        _requiresRtiForInstantiation(cls.superclass);
    _requiresRtiForInstantiationCache[cls] = hasTypeParameters;
    return hasTypeParameters;
  }

  js_ast.LiteralString _constructorName(String name) {
    if (name == '') {
      // Default constructors (factory or not) use `new` as their name.
      return _propertyName('new');
    }
    return _emitStaticMemberName(name);
  }

  js_ast.Statement _emitRedirectingConstructor(
      List<Initializer> initializers, js_ast.Expression className) {
    var jsInitializers = <js_ast.Statement>[];
    for (var init in initializers) {
      if (init is LocalInitializer) {
        // Temporary locals are created when named arguments don't appear at
        // the end of the arguments list.
        jsInitializers.add(visitVariableDeclaration(init.variable));
      } else if (init is RedirectingInitializer) {
        var rtiParam = _requiresRtiForInstantiation(init.target.enclosingClass)
            ? _rtiParam
            : null;
        // We can't dispatch to the constructor with `this.new` as that might
        // hit a derived class constructor with the same name.
        var initializer = js.statement('#.#.call(this, #);', [
          className,
          _constructorName(init.target.name.text),
          [
            if (rtiParam != null) rtiParam,
            ..._emitArgumentList(init.arguments, types: false)
          ]
        ]);
        jsInitializers.add(initializer);
      }
    }
    return js_ast.Block(jsInitializers);
  }

  js_ast.Statement? _emitSuperConstructorCallIfNeeded(
      Class c, js_ast.Expression className, SuperInitializer? superInit) {
    if (c == _coreTypes.objectClass) return null;

    Constructor ctor;
    List<js_ast.Expression> args;
    if (superInit == null) {
      ctor = unnamedConstructor(c.superclass!)!;
      args = [];
    } else {
      ctor = superInit.target;
      var savedTypeEnvironment = _currentTypeEnvironment;
      _currentTypeEnvironment = ClassTypeEnvironment(c.typeParameters);
      // An RTI will already have been set at the constructor call site, so
      // pass nothing if the superclass is expecting an RTI.
      var rti = _requiresRtiForInstantiation(ctor.enclosingClass)
          ? js_ast.LiteralNull()
          : null;
      args = [
        if (rti != null) rti,
        ..._emitArgumentList(superInit.arguments, types: true)
      ];

      _currentTypeEnvironment = savedTypeEnvironment;
    }
    // We can skip the super call if it's empty. Most commonly this happens for
    // things that extend Object, and don't have any field initializers or their
    // own default constructor.
    if (ctor.name.text == '' && !_hasUnnamedSuperConstructor(c)) {
      return null;
    }
    return _emitSuperConstructorCall(ctor, className, ctor.name.text, args);
  }

  js_ast.Statement _emitSuperConstructorCall(Constructor constructor,
      js_ast.Expression className, String name, List<js_ast.Expression> args) {
    return js.statement('#.#.call(this, #);', [
      _emitJSObjectGetPrototypeOf(className, fullyQualifiedName: true),
      _constructorName(name),
      args
    ]);
  }

  bool _hasUnnamedInheritedConstructor(Class? c) {
    if (c == null) return false;
    return _hasUnnamedConstructor(c) || _hasUnnamedSuperConstructor(c);
  }

  bool _hasUnnamedSuperConstructor(Class c) {
    return _hasUnnamedConstructor(c.mixedInClass) ||
        _hasUnnamedInheritedConstructor(c.superclass);
  }

  bool _hasUnnamedConstructor(Class? c) {
    if (c == null || c == _coreTypes.objectClass) return false;
    var ctor = unnamedConstructor(c);
    if (ctor != null && !ctor.isSynthetic) return true;
    return c.fields.any((f) => !f.isStatic);
  }

  js_ast.Expression _emitFieldValueAccessor(Field f) {
    var virtualField = _classProperties!.virtualFields[f];
    // Avoid calling getSymbol on _declareMemberName since _declareMemberName
    // calls _emitMemberName downstream, which already invokes getSymbol.
    var access =
        virtualField == null ? _declareMemberName(f) : _getSymbol(virtualField);
    return access;
  }

  js_ast.Expression _emitFieldInit(
      Field f, Expression? initializer, TreeNode hoverInfo) {
    var access = _emitFieldValueAccessor(f);
    var jsInit = _visitInitializer(initializer, f.annotations);
    return jsInit.toAssignExpression(
        js.call('this.#', [access])..sourceInformation = _nodeStart(hoverInfo));
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  js_ast.Statement _initializeFields(List<Field> fields, [Constructor? ctor]) {
    // Run field initializers if they can have side-effects.
    var ctorFields = ctor?.initializers
        .whereType<FieldInitializer>()
        .map((c) => c.field)
        .toSet();

    var body = <js_ast.Statement>[];
    for (var f in fields) {
      if (f.isStatic) continue;
      var init = f.initializer;
      if (ctorFields != null &&
          ctorFields.contains(f) &&
          (init == null || _constants.isConstant(init))) {
        continue;
      }
      _staticTypeContext.enterMember(f);
      body.add(_emitFieldInit(f, init, f).toStatement());
      _staticTypeContext.leaveMember(f);
    }

    // Run constructor field initializers such as `: foo = bar.baz`
    if (ctor != null) {
      for (var init in ctor.initializers) {
        if (init is FieldInitializer) {
          body.add(_emitFieldInit(init.field, init.value, init).toStatement());
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
      Expression? init, List<Expression> annotations) {
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    if (init == null) return js_ast.LiteralNull();
    return _annotatedNullCheck(annotations)
        ? _notNull(init)
        : _visitExpression(init);
  }

  js_ast.Expression _notNull(Expression expr) {
    var jsExpr = _visitExpression(expr);
    if (!_isNullable(expr)) return jsExpr;
    return _runtimeCall('notNull(#)', [jsExpr]);
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
      js_ast.LiteralString name, js_ast.Expression jsCtor) {
    jsCtor = _defineValueOnClass(c, className, name, jsCtor);
    return js.statement('#.prototype = #.prototype;', [jsCtor, className]);
  }

  /// Whether any superclass of [c] defines a static [name].
  bool _superclassHasStatic(Class c, String memberName) {
    // Note: because we're only considering statics, we can ignore mixins.
    // We're only trying to find conflicts due to JS inheriting statics.
    var superclass = c.superclass;
    var name = Name(memberName, c.enclosingLibrary);
    while (true) {
      if (superclass == null) return false;
      for (var m in superclass.members) {
        if (m.name == name &&
            (m is Procedure && m.isStatic || m is Field && m.isStatic)) {
          return true;
        }
      }
      superclass = superclass.superclass;
    }
  }

  /// Emits a value store and getter/setter pair for [member] that constitutes
  /// a static field.
  List<js_ast.Property> _emitStaticFieldAndAccessor(Member member) {
    return _emitLazyMember(
        _emitTopLevelNameNoExternalInterop(member.enclosingClass!),
        member,
        (m) => _emitStaticMemberName(m.name.text));
  }

  /// Emits class methods and properties.
  List<js_ast.Property> _emitClassProperties(Class c) {
    var virtualFields = _classProperties!.virtualFields;

    var jsProperties = <js_ast.Property?>[];
    var hasJsPeer = _extensionTypes.isNativeClass(c);
    var hasIterator = false;

    if (c == _coreTypes.objectClass) {
      // Dart does not use ES6 constructors.
      // Add an error to catch any invalid usage.
      jsProperties.add(js_ast.Method(
          _propertyName('constructor'),
          js.fun(r'''function() {
                throw Error("use `new " + # +
                    ".new(...)` to create a Dart object");
              }''', [
            _runtimeCall('typeName(#)', [_runtimeCall('getReifiedType(this)')])
          ])));
    } else if (c == _jsArrayClass) {
      // Provide access to the Array constructor property, so it works like
      // other native types (rather than calling the Dart Object "constructor"
      // above, which throws).
      //
      // This will become obsolete when
      // https://github.com/dart-lang/sdk/issues/31003 is addressed.
      jsProperties.add(js_ast.Method(
          _propertyName('constructor'), js.fun(r'function() { return []; }')));
    }

    for (var m in c.fields) {
      if (m.isStatic) {
        jsProperties.addAll(_emitStaticFieldAndAccessor(m));
      } else if (_extensionTypes.isNativeClass(c)) {
        jsProperties.addAll(_emitNativeFieldAccessors(m));
      } else if (virtualFields.containsKey(m)) {
        jsProperties.addAll(_emitVirtualFieldAccessor(m));
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
      _currentUri = m.isNoSuchMethodForwarder ? null : m.fileUri;
      if (_isForwardingStub(m)) {
        // TODO(jmesserly): is there any other kind of forwarding stub?
        jsProperties.addAll(_emitCovarianceCheckStub(m));
      } else if (m.isFactory) {
        if (m.isRedirectingFactory) {
          // Skip redirecting factories (they've already been resolved).
        } else {
          jsProperties.add(_emitFactoryConstructor(m));
        }
      } else if (m.isAccessor) {
        jsProperties.add(_emitMethodDeclaration(m));
        jsProperties.add(_emitSuperAccessorWrapper(m, getters, setters));
        if (!hasJsPeer && m.isGetter && m.name.text == 'iterator') {
          hasIterator = true;
          jsProperties.add(_emitIterable(c));
        }
      } else {
        jsProperties.add(_emitMethodDeclaration(m));
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
      jsProperties.add(_emitIterable(c));
    }

    // Add all of the super helper methods
    jsProperties.addAll(_superHelpers.values);

    return jsProperties.nonNulls.toList();
  }

  bool _isForwardingStub(Procedure member) {
    if (member.isForwardingStub || member.isForwardingSemiStub) {
      if (!_currentLibrary!.importUri.isScheme('dart')) return true;
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
  js_ast.Method? _emitMethodDeclaration(Procedure member) {
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
      fn = _withMethodDeclarationContext(
          member,
          () => _emitFunction(member.function, member.name.text,
              functionBody: _toSourceLocation(member.fileOffset),
              functionEnd: _toSourceLocation(member.fileEndOffset)));
    }

    var method = js_ast.Method(_declareMemberName(member), fn,
        isGetter: member.isGetter,
        isSetter: member.isSetter,
        isStatic: member.isStatic);

    if (isTearOffLowering(member)) {
      // Remove all source information from static methods introduced by the
      // constructor tearoff CFE lowering.
      method.accept(js_ast.SourceInformationClearer());
    } else {
      method.sourceInformation = _nodeEnd(member.fileEndOffset);
    }
    return method;
  }

  js_ast.Fun _emitNativeFunctionBody(Procedure node) {
    var name = _annotationName(node, isJSAnnotation) ?? node.name.text;
    if (node.isGetter) {
      var returnValue = js('this.#', [name]);
      if (_isNullCheckableNative(node)) {
        // Add a potential null-check on native getter if type is non-nullable.
        returnValue = _runtimeCall('checkNativeNonNull(#)', [returnValue]);
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
        returnValue = _runtimeCall('checkNativeNonNull(#)', [returnValue]);
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
    var superMember = member.concreteForwardingStubTarget ??
        member.abstractForwardingStubTarget;

    if (superMember == null) return const [];

    DartType substituteType(DartType t) {
      return _typeFromClass(t, superMember.enclosingClass!, enclosingClass!);
    }

    var superMemberFunction = superMember.function;
    var name = _declareMemberName(member);
    if (member.isSetter) {
      if (superMember is Field && isCovariantField(superMember) ||
          superMember is Procedure &&
              isCovariantParameter(
                  superMemberFunction!.positionalParameters[0])) {
        return const [];
      }
      var setterType =
          substituteType(superMember.superSetterType).extensionTypeErasure;
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

    var superMethodType = substituteType(superMemberFunction!
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
      var jsParam = _emitIdentifier(param.name!);
      jsParams.add(jsParam);

      if (isCovariantParameter(param) &&
          !isCovariantParameter(superMemberFunction.positionalParameters[i])) {
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
          !isCovariantParameter(superMemberFunction.namedParameters
              .firstWhere((n) => n.name == param.name))) {
        var name = _propertyName(param.name!);
        var paramType = superMethodType.namedParameters
            .firstWhere((n) => n.name == param.name);
        body.add(js.statement('if (#) #;', [
          _namedArgumentProbe(name),
          _emitCast(
              js_ast.PropertyAccess(_namedArgumentTemp, name), paramType.type)
        ]));
      }
    }

    if (body.isEmpty) return const []; // No checks were needed.

    if (namedParameters.isNotEmpty) jsParams.add(_namedArgumentTemp);
    body.add(js.statement('return super.#(#);', [name, jsParams]));
    return [js_ast.Method(name, js_ast.Fun(jsParams, js_ast.Block(body)))];
  }

  /// Emits a Dart factory constructor to a JS static method.
  js_ast.Method? _emitFactoryConstructor(Procedure node) {
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
    var savedTypeEnvironment = _currentTypeEnvironment;
    _currentTypeEnvironment = RtiTypeEnvironment([
      ...function.typeParameters,
      ..._currentTypeEnvironment.classTypeParameters
    ]);
    var jsBody = js_ast.Block(_withCurrentFunction(function, () {
      var block = _emitArgumentInitializers(function, name);
      block.add(_emitFunctionScopedBody(function));
      return block;
    }));
    var jsName = _constructorName(name);
    memberNames[node] = jsName.valueWithoutQuotes;

    // Generic class constructors accept their RTI as their first argument.
    var method = js_ast.Method(
      jsName,
      js_ast.Fun(
        [
          if (_requiresRtiForInstantiation(node.enclosingClass)) _rtiParam,
          ..._emitParameters(function)
        ],
        jsBody,
      ),
      isStatic: true,
    )..sourceInformation = _nodeEnd(node.fileEndOffset);
    _currentTypeEnvironment = savedTypeEnvironment;
    return method;
  }

  /// Emits the expression necessary to access a constructor of [type];
  js_ast.Expression _emitConstructorAccess(InterfaceType type) =>
      _emitJSInterop(type.classNode) ?? _emitClassRef(type);

  /// This is called whenever a derived class needs to introduce a new field,
  /// shadowing a field or getter/setter pair on its parent.
  ///
  /// This is important because otherwise, trying to read or write the field
  /// would end up calling the getter or setter, and one of those might not even
  /// exist, resulting in a runtime error. Even if they did exist, that's the
  /// wrong behavior if a new field was declared.
  List<js_ast.Method> _emitVirtualFieldAccessor(Field field) {
    var virtualFieldSymbol = _emitFieldValueAccessor(field);
    var name = _declareMemberName(field);
    var initializer = _visitInitializer(field.initializer, field.annotations);
    var getter = _emitLazyInitializingFunction(
      js.call('this.#', virtualFieldSymbol),
      initializer,
      field,
    );
    var jsGetter = js_ast.Method(name, getter, isGetter: true)
      ..sourceInformation = _nodeStart(field);

    var body = <js_ast.Statement>[];
    var value = _emitIdentifier('value');
    // Avoid adding a null checks on forwarding field setters.
    if (field.hasSetter &&
        _requiresExtraNullCheck(field.setterType, field.annotations)) {
      body.add(
          _nullSafetyParameterCheck(value, field.location, field.name.text));
    }
    var args = field.isFinal
        ? [js_ast.Super(), name, value]
        : [
            js_ast.This(),
            virtualFieldSymbol,
            if (isCovariantField(field)) _emitCast(value, field.type) else value
          ];
    body.add(js.call('#[#] = #', args).toStatement());
    var jsSetter = js_ast.Method(name, js_ast.Fun([value], js_ast.Block(body)),
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
      var value = _emitScopedId('value');
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
  js_ast.Method? _emitSuperAccessorWrapper(Procedure member,
      Map<String, Procedure> getters, Map<String, Procedure> setters) {
    if (member.isAbstract) return null;

    var name = member.name.text;
    var memberName = _declareMemberName(member);
    if (member.isGetter) {
      if (!setters.containsKey(name) &&
          _classProperties!.inheritedSetters.contains(name)) {
        // Generate a setter that forwards to super.
        var fn = js.fun('function(value) { super[#] = value; }', [memberName]);
        return js_ast.Method(memberName, fn, isSetter: true);
      }
    } else {
      assert(member.isSetter);
      if (!getters.containsKey(name) &&
          _classProperties!.inheritedGetters.contains(name)) {
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
  js_ast.Method? _emitIterable(Class c) {
    var iterable = _hierarchy.getClassAsInstanceOf(c, _coreTypes.iterableClass);
    if (iterable == null) return null;
    var superclass = c.superclass!;
    // If a parent had an `iterator` (concrete or abstract) or implements
    // Iterable, we know the adapter is already there, so we can skip it as a
    // simple code size optimization.
    var parent = _hierarchy.getDispatchTarget(superclass, Name('iterator'));
    if (parent != null) return null;

    var parentIterable =
        _hierarchy.getClassAsInstanceOf(superclass, _coreTypes.iterableClass);
    if (parentIterable != null) return null;

    if (c.enclosingLibrary.importUri.isScheme('dart') &&
        c.procedures.any((m) => _jsExportName(m) == 'Symbol.iterator')) {
      return null;
    }

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return js_ast.Method(
        js.call('Symbol.iterator'),
        // TODO(nshahan) Don't access values in `runtimeModule` outside of
        // `runtimeCall`.
        js.call('function() { return new #.JsIterator(this.#); }', [
          _emitLibraryName(_runtimeLibrary),
          _emitMemberName('iterator', memberClass: _coreTypes.iterableClass)
        ]) as js_ast.Fun);
  }

  void _registerExtensionType(
      Class c, String jsPeerName, List<js_ast.Statement> body) {
    var className = _emitTopLevelName(c);
    // TODO(55547): Move these operations to the library link method.
    if (_typeRep.isPrimitive(_coreTypes.nonNullableRawType(c))) {
      body.add(_runtimeStatement(
          'definePrimitiveHashCode(#.prototype)', [className]));
    }
    _nativeExtensionLinks.add(_runtimeStatement(
        'registerExtension(#, #)', [js.string(jsPeerName), className]));
  }

  /// Generates an entrypoint function for [field] that returns the value in
  /// [valueCache] or initializes it to [initializer] on first access.
  ///
  /// [valueCache] is 'undefined' when uninitialized and holds a special
  /// sentinel value if [field] is final to detect multiple initializations.
  js_ast.Fun _emitLazyInitializingFunction(js_ast.Expression valueCache,
      js_ast.Expression initializer, Field field) {
    // We avoid emitting casts for top level fields in the legacy SDK since
    // some are used for legacy type checks and must be initialized to avoid
    // infinite loops.
    var initialFieldValueExpression =
        !_options.soundNullSafety && _isSdkInternalRuntime(_currentLibrary!)
            ? valueCache
            : _emitCast(valueCache, field.type);

    // Lazy static fields require an additional type check around their value
    // cache if their type is updated after hot reload. To avoid a type check
    // on every access, the generated getter overrides itself with a direct
    // access on its underlying value cache on first access.
    // TODO(markzipan): The performance ramifications of a lookup vs
    // self-rewriting "smart" getter are unknown. We should revisit this if
    // property accesses become a bottleneck.
    if (field.isStatic) {
      var getterName = memberNames[field]!;
      // Final fields are generated with additional logic to detect
      // initialization cycles via a special sentinel.
      if (field.isFinal) {
        var finalLateInitDetectorSentinel = _getSymbol(
            _emitPrivateNameSymbol(field.enclosingLibrary, '_#initializing'));
        // Emits code like:
        //
        // if ([valueCache] === _#initializing)
        //   dart.throwLateInitializationError(field);
        // if ([valueCache] === void 0) {
        //   [valueCache] = _#initializing;
        //   try {
        //     [valueCache] = initializer;
        //   } catch (e) {
        //     // Reset the sentinel on error so it can be reinitialized.
        //     if ([valueCache] === _#initializing) {
        //       [valueCache] = void 0;
        //     }
        //     throw e;
        //   }
        // }
        // _typeCheck([valueCache]);
        // Object.defineProperty(this, field, {
        //   get() {
        //     return [valueCache];
        //   }
        // });
        // return this.field;
        return js.fun(r'''
        function() {
          if (# === #) #;
          if (# === void 0) {
            # = #;
            try {
              # = #;
            } catch (e) {
              if (# === #) {
                # = void 0;
              }
              throw e;
            }
          }
          #;
          Object.defineProperty(this, #, {
            get() {
              return #;
            }
          });
          return this.#;
        }
      ''', [
          valueCache,
          finalLateInitDetectorSentinel,
          _runtimeCall(
            'throwLateInitializationError(#)',
            [js.string(field.name.text)],
          ),
          valueCache,
          valueCache,
          finalLateInitDetectorSentinel,
          valueCache,
          initializer,
          valueCache,
          finalLateInitDetectorSentinel,
          valueCache,
          initialFieldValueExpression,
          js.string(getterName),
          valueCache,
          getterName,
        ]);
      } else {
        // Emits code like:
        //
        // if ([valueCache] === void 0) {
        //   [valueCache] = initializer;
        // }
        // _typeCheck([valueCache]);
        // Object.defineProperty(this, field, {
        //   get() {
        //     return [valueCache];
        //   }
        // });
        // return this.field;
        return js.fun(r'''
        function() {
          if (# === void 0) {
            # = #;
          }
          #;
          Object.defineProperty(this, #, {
            get() {
              return #;
            }
          });
          return this.#;
          }
      ''', [
          valueCache,
          valueCache,
          initializer,
          initialFieldValueExpression,
          js.string(getterName),
          valueCache,
          getterName,
        ]);
      }
    }
    // Final fields are generated with additional logic to detect
    // initialization cycles via a special sentinel.
    if (field.isFinal) {
      var finalLateInitDetectorSentinel = _getSymbol(
          _emitPrivateNameSymbol(field.enclosingLibrary, '_#initializing'));
      // Emits code like:
      //
      // if ([valueCache] === _#initializing)
      //   dart.throwLateInitializationError(field);
      // if ([valueCache] === void 0) {
      //   [valueCache] = _#initializing;
      //   try {
      //     [valueCache] = initializer;
      //   } catch (e) {
      //     // Reset the sentinel on error so it can be reinitialized.
      //     if ([valueCache] === _#initializing) {
      //       [valueCache] = void 0;
      //     }
      //     throw e;
      //   }
      // }
      // return [valueCache];
      return js.fun(r'''
        function() {
          if (# === #) #;
          if (# === void 0) {
            # = #;
            try {
              # = #;
            } catch (e) {
              if (# === #) {
                # = void 0;
              }
              throw e;
            }
          }
          return #;
        }
      ''', [
        valueCache,
        finalLateInitDetectorSentinel,
        _runtimeCall(
          'throwLateInitializationError(#)',
          [js.string(field.name.text)],
        ),
        valueCache,
        valueCache,
        finalLateInitDetectorSentinel,
        valueCache,
        initializer,
        valueCache,
        finalLateInitDetectorSentinel,
        valueCache,
        initialFieldValueExpression,
      ]);
    } else {
      return js.fun(r'''
        function() {
          if (# === void 0) {
            # = #;
          }
          return #;
        }
      ''', [
        valueCache,
        valueCache,
        initializer,
        initialFieldValueExpression,
      ]);
    }
  }

  /// Emit a lazy field (i.e., late or static).
  ///
  /// Lazy fields are represented as an inlined initializer and a value store.
  /// Value stores are JS symbols prefixed by [_fieldValueStorePrefix], are
  /// initialized on first access, and are not replaced after a hot reload.
  List<js_ast.Property> _emitLazyMember(js_ast.Expression objExpr,
      Member member, js_ast.LiteralString Function(Member) emitMemberName) {
    _currentUri = member.fileUri;
    _staticTypeContext.enterMember(member);
    var access = emitMemberName(member);
    memberNames[member] = access.valueWithoutQuotes;
    var properties = <js_ast.Property>[];

    if (member is Field) {
      // Add this field's value store. Lazy members must be prefixed by
      // [_fieldValueStorePrefix] to allow correct hot reload semantics.
      // TODO(markzipan): Const values are emitted along the lazy pathway, but
      // their hot reload semantics seem to permit their values to change after
      // initialization. Revisit this later as we work on consts.
      var fieldValueStoreName = member.isConst
          ? memberNames[member]!
          : '$_fieldValueStorePrefix${memberNames[member]!}';
      var memberValueStore = _getSymbol(
          _emitPrivateNameSymbol(_currentLibrary!, fieldValueStoreName));
      properties.add(js_ast.Property(memberValueStore, js.call('void 0'),
          isStatic: member.isStatic && member.enclosingClass != null,
          isClassProperty: member.enclosingClass != null));

      var initializer =
          _visitInitializer(member.initializer, member.annotations);
      var getter = _emitLazyInitializingFunction(
          js.call('this.#', memberValueStore), initializer, member);
      properties.add(js_ast.Method(access, getter,
          isGetter: true,
          isStatic: member.isStatic && member.enclosingClass != null)
        ..sourceInformation = _hoverComment(
          js_ast.PropertyAccess(objExpr, access),
          member.fileOffset,
          member.name.text.length,
        ));

      if (!member.isFinal && !member.isConst) {
        var body = <js_ast.Statement>[];
        var param = _emitIdentifier('v');
        if (_requiresExtraNullCheck(member.setterType, member.annotations)) {
          body.add(_nullSafetyParameterCheck(
              param, member.location, member.name.text));
        }
        body.add(js.statement('this.# = #;', [memberValueStore, param]));
        // Even when no null check is present a dummy setter is still required
        // to indicate writeable.
        properties.add(js_ast.Method(
          access,
          js_ast.Fun([param], js_ast.Block(body)),
          isSetter: true,
          isStatic: member.isStatic && member.enclosingClass != null,
        ));
      }
    } else if (member is Procedure) {
      properties.add(js_ast.Method(
        access,
        _emitFunction(member.function, member.name.text),
        isGetter: member.isGetter,
        isSetter: member.isSetter,
        isStatic: member.isStatic && member.enclosingClass != null,
      )..sourceInformation = _hoverComment(
          js_ast.PropertyAccess(objExpr, access),
          member.fileOffset,
          member.name.text.length));
    } else {
      throw UnsupportedError(
          'Unsupported lazy member type ${member.runtimeType}: $member');
    }
    _staticTypeContext.leaveMember(member);
    return properties;
  }

  /// Emits [members] as lazy fields.
  List<js_ast.Property> _emitLazyMembers(
    js_ast.Expression objExpr,
    Iterable<Member> members,
    js_ast.LiteralString Function(Member) emitMemberName,
  ) {
    var properties = <js_ast.Property>[];
    var savedUri = _currentUri;

    for (var member in members) {
      properties.addAll(_emitLazyMember(objExpr, member, emitMemberName));
    }
    _currentUri = savedUri;
    return properties;
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
    return _emitJSInterop(n) ??
        _emitTopLevelNameNoExternalInterop(n, suffix: suffix);
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  js_ast.Expression _declareMemberName(Member m, {bool? useExtension}) {
    var c = m.enclosingClass;
    return _emitMemberName(m.name.text,
        isStatic: m is Field ? m.isStatic : (m as Procedure).isStatic,
        useExtension:
            useExtension ?? c != null && _extensionTypes.isNativeClass(c),
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
  ///     <, >, <=, >=, ==, -, +, /, ~/, *, %, |, ^, &, <<, >>, >>>, []=, [], ~
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
      bool? useExtension,
      Member? member,
      Class? memberClass}) {
    // Static members skip the rename steps and may require JS interop renames.
    if (isStatic) {
      var memberName = _emitStaticMemberName(name, member);
      if (member != null && !isTearOffLowering(member)) {
        // No need to track the names of methods that were created by the CFE
        // lowering and don't exist in the original source code.
        memberNames[member] = memberName.valueWithoutQuotes;
      }
      return memberName;
    }

    // We allow some (illegal in Dart) member names to be used in our private
    // SDK code. These renames need to be included at every declaration,
    // including overrides in subclasses.
    if (member != null) {
      var runtimeName = _jsExportName(member);
      if (runtimeName != null) {
        var parts = runtimeName.split('.');
        // TODO(nshahan) Record the name for this member in memberNames.
        if (parts.length < 2) return _propertyName(runtimeName);

        js_ast.Expression result = _emitIdentifier(parts[0]);
        for (var i = 1; i < parts.length; i++) {
          result = js_ast.PropertyAccess(result, _propertyName(parts[i]));
        }
        // TODO(nshahan) Record the name for this member in memberNames.
        return result;
      }
    }

    memberClass ??= member?.enclosingClass;
    if (name.startsWith('_')) {
      // Use the library that this private member's name is scoped to.
      var memberLibrary = member?.name.library ??
          memberClass?.enclosingLibrary ??
          _currentLibrary!;
      if (member != null) {
        // TODO(40273) Move this name collection to another location.
        // We really only want to collect member names when the member is created,
        // not called.
        // Wrap the name as a symbol here so it matches what you would find at
        // runtime when you get all properties and symbols from an instance.
        memberNames[member] = 'Symbol($name)';
      }
      return _getSymbol(_emitPrivateNameSymbol(memberLibrary, name));
    }

    useExtension ??= _isSymbolizedMember(memberClass, name);
    name = js_ast.memberNameForDartMember(name, _isExternal(member));
    if (useExtension) {
      // TODO(nshahan) Record the name for this member in memberNames.
      return _getSymbol(_getExtensionSymbolInternal(name));
    }
    var memberName = _propertyName(name);
    if (member != null) {
      // TODO(40273) Move this name collection to another location.
      // We really only want to collect member names when the member is created,
      // not called.
      memberNames[member] = memberName.valueWithoutQuotes;
    }
    return memberName;
  }

  /// Don't symbolize native members that just forward to the underlying
  /// native member.  We limit this to non-renamed members as the receiver
  /// may be a mock type.
  ///
  /// Note, this is an underlying assumption here that, if another native type
  /// subtypes this one, it also forwards this member to its underlying native
  /// one without renaming.
  bool _isSymbolizedMember(Class? c, String name) {
    if (c == null) {
      return _isObjectMember(name);
    }
    c = _typeRep.getImplementationClass(_coreTypes.nonNullableRawType(c)) ?? c;
    if (_extensionTypes.isNativeClass(c)) {
      var member = _lookupForwardedMember(c, name);

      // Fields on a native class are implicitly native.
      // Methods/getters/setters are marked external/native.
      if (member is Field || _isExternal(member)) {
        // If the native member needs to be null-checked and we're running in
        // sound null-safety, we require symbolizing it in order to access the
        // null-check at the member definition.
        if (_isNullCheckableNative(member!)) return true;
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

  final _forwardingCache = HashMap<Class, Map<String, Member?>>();

  Member? _lookupForwardedMember(Class c, String name) {
    // We only care about public methods.
    if (name.startsWith('_')) return null;

    var map = _forwardingCache.putIfAbsent(c, () => {});

    return map.putIfAbsent(
        name,
        () =>
            _hierarchy.getDispatchTarget(c, Name(name)) ??
            _hierarchy.getDispatchTarget(c, Name(name), setter: true));
  }

  js_ast.LiteralString _emitStaticMemberName(String name, [NamedNode? member]) {
    if (member != null) {
      var jsName = _emitJSInteropExternalStaticMemberName(member);
      if (jsName != null) return jsName;

      // Allow the Dart SDK to assign names to statics with the @JSExportName
      // annotation.
      var exportName = _jsExportName(member);
      if (exportName != null) return _propertyName(exportName);
    }
    if (member is Procedure && member.isFactory) {
      return _constructorName(member.name.text);
    }
    switch (name) {
      // Reserved for the compiler to do `x as T`.
      case 'as':
      // Reserved for the SDK to compute `Type.toString()`.
      case 'name':
      // Reserved by JS, not a valid static member name.
      case 'prototype':
        name += '_';
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

  /// If [f] is a function passed to JS, make it throw at runtime when called if
  /// it isn't wrapped with `allowInterop`.
  ///
  /// Arguments which are _directly_ wrapped at the site they are passed are
  /// unmodified.
  Expression _assertInterop(Expression f) {
    // Erasing any extension types here for legacy JS interop support but if
    // using the new extension type interop the type system requires that
    // `.toJS` was called.
    var type = f.getStaticType(_staticTypeContext).extensionTypeErasure;
    if (type is FunctionType ||
        (type is InterfaceType && type.classNode == _coreTypes.functionClass)) {
      if (!isAllowInterop(f)) {
        return StaticInvocation(
            _assertInteropMethod, Arguments([f], types: [type]));
      }
    }
    return f;
  }

  /// Emit the name associated with external static members of interop classes.
  js_ast.LiteralString? _emitJSInteropExternalStaticMemberName(NamedNode n) {
    if (!usesJSInterop(n)) return null;
    if (n is Member && !n.isExternal) return null;
    var name = _annotationName(n, isJSInteropAnnotation) ?? getTopLevelName(n);
    assert(!name.contains('.'),
        'JS interop checker rejects dotted names on static class members');
    return js.escapedString(name, "'");
  }

  /// Emit the top-level name associated with [n], which should not be an
  /// external interop member.
  js_ast.PropertyAccess _emitTopLevelNameNoExternalInterop(NamedNode n,
      {String suffix = ''}) {
    // Some native tests use top-level native methods.
    var isTopLevelNative = n is Member && isNative(n);
    return js_ast.PropertyAccess(
        isTopLevelNative
            ? _runtimeCall('global.self')
            : _emitLibraryName(getLibrary(n)),
        _emitTopLevelMemberName(n, suffix: suffix));
  }

  /// Emits the member name portion of a top-level member.
  ///
  /// NOTE: usually you should use [_emitTopLevelName] instead of this. This
  /// function does not handle JS interop.
  js_ast.LiteralString _emitTopLevelMemberName(NamedNode n,
      {String suffix = ''}) {
    var name = _jsExportName(n) ?? getTopLevelName(n);
    return _propertyName(name + suffix);
  }

  bool _isExternal(Member? m) {
    // Corresponds to the names in memberNameForDartMember in
    // compiler/js_names.dart.
    const renamedJsMembers = ['prototype', 'constructor'];
    if (m is Procedure) {
      if (m.isExternal) return true;
      if (m.isNoSuchMethodForwarder) {
        if (renamedJsMembers.contains(m.name.text)) {
          return _hasExternalProcedure(m.enclosingClass!, m.name.text);
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
        if (c.supertype != null) c.supertype!.classNode,
        for (var t in c.implementedTypes) t.classNode,
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

  String? _jsNameWithoutGlobal(NamedNode n) {
    if (!usesJSInterop(n)) return null;
    var libraryJSName = _annotationName(getLibrary(n), isJSInteropAnnotation);
    var jsName =
        _annotationName(n, isJSInteropAnnotation) ?? getTopLevelName(n);
    return libraryJSName != null ? '$libraryJSName.$jsName' : jsName;
  }

  String? _emitJsNameWithoutGlobal(NamedNode n) {
    if (!usesJSInterop(n)) return null;
    _setEmitIfIncrementalLibrary(getLibrary(n));
    return _jsNameWithoutGlobal(n);
  }

  js_ast.PropertyAccess? _emitJSInterop(NamedNode n) {
    var jsName = _emitJsNameWithoutGlobal(n);
    if (jsName == null) return null;
    return _emitJSInteropForGlobal(jsName);
  }

  js_ast.PropertyAccess _emitJSInteropForGlobal(String name) {
    var parts = name.split('.');
    if (parts.isEmpty) parts = [''];
    js_ast.PropertyAccess? access;
    for (var part in parts) {
      access = js_ast.PropertyAccess(
          access ?? _runtimeCall('global'), js.escapedString(part, "'"));
    }
    return access!;
  }

  /// Emits top level library procedures and fields.
  ///
  /// Top level fields are represented as an initializer and a value store.
  /// The getter initializes the value on first access, and an accompanying
  /// setter (if not final) sets the underlying value store. Value stores
  /// prefixed by [_fieldValueStorePrefix] are not replaced after a hot reload.
  void _emitLibraryMembers(Library library) {
    var libraryProperties = <js_ast.Property>[];

    // Emit procedures
    var procedures = library.procedures
        .where((p) =>
            !p.isExternal && !p.isAbstract && !_isStaticInteropTearOff(p))
        .toList();
    for (var p in procedures) {
      if (!p.isAccessor) {
        _moduleItems.add(_emitLibraryFunction(p));
      }
      // TODO(#57049): We tag all static members because we don't know if
      // they've been changed after a hot reload. This won't be necessary if we
      // can tag them during the delta diff phase.
      if (p.isStatic && _reifyTearoff(p) && !p.isExternal) {
        var nameExpr = _emitTopLevelName(p);
        _moduleItems.add(_emitFunctionTagged(
                nameExpr,
                p.function
                    .computeThisFunctionType(p.enclosingLibrary.nonNullable),
                asLazy: true)
            .toStatement());
      }
    }
    var accessors =
        procedures.where((p) => p.isAccessor).map(_emitLibraryAccessor);
    libraryProperties.addAll(accessors);

    // Emit fields
    var fields = library.fields;
    if (_isSdkInternalRuntime(_currentLibrary!)) {
      /// Treat dart:_runtime fields as safe to eagerly evaluate.
      // TODO(jmesserly): it'd be nice to avoid this special case.
      var lazyFields = <Field>[];
      var savedUri = _currentUri;

      // Helper functions to test if a constructor invocation is internal and
      // should be eagerly evaluated.
      bool isInternalConstructor(ConstructorInvocation node) {
        var type = node.getStaticType(_staticTypeContext) as InterfaceType;
        var library = type.classNode.enclosingLibrary;
        return _isSdkInternalRuntime(library);
      }

      for (var field in fields) {
        _staticTypeContext.enterMember(field);
        var init = field.initializer;
        if (init == null ||
            init is BasicLiteral ||
            init is ConstructorInvocation && isInternalConstructor(init) ||
            init is StaticInvocation && isInlineJS(init.target)) {
          _currentUri = field.fileUri;
          _moduleItems.add(js.statement('# = #;', [
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

    var libraryExpr = _emitLibraryName(_currentLibrary!);
    if (fields.isNotEmpty) {
      libraryProperties.addAll(
          _emitLazyMembers(libraryExpr, fields, _emitTopLevelMemberName));
    }

    if (libraryProperties.isNotEmpty) {
      var propertiesObject = js_ast.ObjectInitializer(libraryProperties);
      _moduleItems.add(_runtimeStatement(
          'declareTopLevelProperties(#, #)', [libraryExpr, propertiesObject]));
    }
  }

  /// Check whether [p] is a tear-off for an external or synthetic static
  /// interop member.
  ///
  /// Users are disallowed from using these tear-offs, so we should avoid
  /// emitting them.
  bool _isStaticInteropTearOff(Procedure p) {
    final extensionMember = _extensionIndex.getExtensionMemberForTearOff(p);
    if (extensionMember != null && extensionMember.asProcedure.isExternal) {
      return true;
    }
    final extensionTypeMember =
        _extensionIndex.getExtensionTypeMemberForTearOff(p);
    if (extensionTypeMember != null &&
        extensionTypeMember.asProcedure.isExternal) {
      return true;
    }
    final enclosingClass = p.enclosingClass;
    if (enclosingClass != null && isStaticInteropType(enclosingClass)) {
      // @staticInterop types can't use generative constructors, so we only
      // check for tear-offs of factories. The one exception is a tear-off of a
      // default constructor, which is disallowed on @staticInterop classes.
      final factoryName = extractConstructorNameFromTearOff(p.name);
      if (factoryName != null) {
        if (factoryName.isEmpty &&
            enclosingClass.constructors.any((constructor) =>
                constructor.isSynthetic && constructor.name.text.isEmpty)) {
          return true;
        }
        if (enclosingClass.procedures.any((procedure) =>
            procedure.isFactory &&
            procedure.isExternal &&
            procedure.name.text == factoryName)) {
          return true;
        }
      }
    }
    return false;
  }

  js_ast.Method _emitLibraryAccessor(Procedure node) {
    var savedUri = _currentUri;
    _staticTypeContext.enterMember(node);
    _currentUri = node.fileUri;

    var name = node.name.text;
    memberNames[node] = name;
    var result = js_ast.Method(
        _propertyName(name), _emitFunction(node.function, name),
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
    var fn = _emitFunction(p.function, p.name.text,
        functionBody: _toSourceLocation(p.fileOffset),
        functionEnd: _toSourceLocation(p.fileEndOffset))
      ..sourceInformation = _nodeEnd(p.fileEndOffset);

    if (_currentLibrary!.importUri.isScheme('dart') &&
        _isInlineJSFunction(p.function.body)) {
      fn = js_ast.simplifyPassThroughArrowFunCallBody(fn);
    }

    var nameExpr = _emitTopLevelName(p);
    var jsName = _safeFunctionNameForSafari(p.name.text, fn);
    var functionName = _emitScopedId(jsName);
    procedureIdentifiers[p] = functionName;
    body.add(js.statement(
        '# = #', [nameExpr, js_ast.NamedFunction(functionName, fn)]));

    _currentUri = savedUri;
    _staticTypeContext.leaveMember(p);

    if (_options.dynamicModule &&
        p.annotations.any((a) => _isEntrypointPragma(a, _coreTypes))) {
      if (_dynamicEntrypoint == null) {
        if (p.function.requiredParameterCount > 0) {
          // TODO(sigmund): this error should be caught by a kernel checker that
          // runs prior to DDC.
          throw StateError('Entrypoint ${p.name.text} must accept being called '
              'with 0 arguments.');
        } else {
          _dynamicEntrypoint = p;
        }
      } else {
        // TODO(sigmund): this error should be caught by a kernel checker that
        // runs prior to DDC.
        throw StateError('A module should define a single entrypoint.');
      }
    }

    return js_ast.Statement.from(body);
  }

  /// Choose a safe name for [fn].
  ///
  /// Most of the time we use [candidateName], except if the name collides
  /// with a parameter name and the function contains default parameter values.
  ///
  /// In ES6, functions containing default parameter values, which DDC
  /// generates when Dart uses positional optional parameters, cannot have
  /// two parameters with the same name. Because we have a similar restriction
  /// in Dart, this is not normally an issue we need to pay attention to.
  /// However, a bug in Safari makes it a syntax error to have the function
  /// name overlap with the parameter names as well. This rename works around
  /// such bug (dartbug.com/43520).
  static String _safeFunctionNameForSafari(
      String candidateName, js_ast.Fun fn) {
    if (fn.params.any((p) => p is js_ast.DestructuredVariable)) {
      while (fn.params.any((a) => a.parameterName == candidateName)) {
        candidateName = '$candidateName\$';
      }
    }
    return candidateName;
  }

  js_ast.Expression _emitFunctionTagged(js_ast.Expression fn, FunctionType type,
      {bool asLazy = false}) {
    var typeRep = _emitType(
        // Avoid tagging a closure as Function? or Function*
        type.withDeclaredNullability(Nullability.nonNullable));
    if (type.typeParameters.isEmpty) {
      return asLazy
          ? _runtimeCall('lazyFn(#, () => #)', [fn, typeRep])
          : _runtimeCall('fn(#, #)', [fn, typeRep]);
    } else {
      var typeParameterDefaults = [
        for (var parameter in type.typeParameters)
          _emitType(parameter.defaultType)
      ];
      var defaultInstantiatedBounds =
          _emitConstList(const DynamicType(), typeParameterDefaults);
      return asLazy
          ? _runtimeCall('lazyGFn(#, () => #, () => #)',
              [fn, typeRep, defaultInstantiatedBounds])
          : _runtimeCall(
              'gFn(#, #, #)', [fn, typeRep, defaultInstantiatedBounds]);
    }
  }

  /// Returns an expression that evaluates to the rti object from the dart:_rti
  /// library that represents [type].
  ///
  /// [emitJSInteropGenericClassTypeParametersAsAny] indicates that we should
  /// emit the statically declared type as a JS interop generic class's type
  /// argument (rather than substituting Any). Any is required for correctness
  /// in most cases except for uses in non-external JS interop factories.
  /// Note: This only applies to the old style package:js interop and isn't
  /// necessary for any forms of static JS interop.
  js_ast.Expression _emitType(DartType type,
      {bool emitJSInteropGenericClassTypeParametersAsAny = true}) {
    /// Returns an expression that evaluates a type [recipe] within the type
    /// [environment].
    ///
    /// At runtime the expression will evaluate to an rti object.
    js_ast.Expression emitRtiEval(
            js_ast.Expression environment, String recipe) =>
        js.call('#.#("$recipe")',
            [environment, _emitMemberName('_eval', memberClass: _rtiClass)]);

    /// Returns an expression that binds a type [parameter] within the type
    /// [environment].
    ///
    /// At runtime the expression will evaluate to an rti object that has been
    /// extended to include the provided [parameter].
    js_ast.Expression emitRtiBind(
        js_ast.Expression environment, TypeParameter parameter) {
      return js.call('#.#(#)', [
        environment,
        _emitMemberName('_bind', memberClass: _rtiClass),
        _emitTypeParameter(parameter)
      ]);
    }

    /// Returns an expression that evaluates a type [recipe] in a type
    /// [environment] resulting in an rti object.
    js_ast.Expression evalInEnvironment(
        DDCTypeEnvironment environment, String recipe) {
      switch (environment) {
        case EmptyTypeEnvironment():
          return js
              .call('#._Universe.eval(#._theUniverse(), "$recipe", true)', [
            _emitLibraryName(_rtiLibrary),
            _emitLibraryName(_rtiLibrary),
          ]);
        case BindingTypeEnvironment():
          js_ast.Expression env;
          if (environment.isSingleTypeParameter) {
            // An environment with a single type parameter can be simplified to
            // just that parameter.
            env = _emitTypeParameter(environment.functionTypeParameters.single);
            // Skip a no-op evaluation and just return the parameter.
            if (recipe == '0') return env;
          } else {
            var environmentTypes = environment.functionTypeParameters;
            // Create a dummy interface type to "hold" type arguments.
            env =
                emitRtiEval(_emitTypeParameter(environmentTypes.first), '@<0>');
            // Bind remaining type arguments.
            for (var i = 1; i < environmentTypes.length; i++) {
              env = emitRtiBind(env, environmentTypes[i]);
            }
          }
          return emitRtiEval(env, recipe);
        case RtiTypeEnvironment():
          // RTI type environments are already constructed and attached to the
          // provided RTI.
          var env = _rtiParam;
          return emitRtiEval(env, recipe);
        case ClassTypeEnvironment():
          // Class type environments are already constructed and attached to the
          // instance of a generic class.
          var env =
              js.call('#.instanceType(this)', [_emitLibraryName(_rtiLibrary)]);
          return emitRtiEval(env, recipe);
        case ExtendedClassTypeEnvironment():
          // Class type environments are already constructed and attached to the
          // instance of a generic class, but function type parameters need to
          // be bound.
          var env =
              js.call('#.instanceType(this)', [_emitLibraryName(_rtiLibrary)]);
          // Bind extra type parameters.
          for (var parameter in environment.functionTypeParameters) {
            env = emitRtiBind(env, parameter);
          }
          return emitRtiEval(env, recipe);
      }
      _typeCompilationError(type,
          'Unexpected DDCTypeEnvironment type (${environment.runtimeType}).');
    }

    var normalizedType =
        _futureOrNormalizer.normalize(type.extensionTypeErasure);
    try {
      var result = _typeRecipeGenerator.recipeInEnvironment(
          normalizedType, _currentTypeEnvironment,
          emitJSInteropGenericClassTypeParametersAsAny:
              emitJSInteropGenericClassTypeParametersAsAny);
      var typeRep =
          evalInEnvironment(result.requiredEnvironment, result.recipe);
      return typeRep;
    } on UnsupportedError catch (e) {
      _typeCompilationError(normalizedType, e.message ?? 'Unknown Error');
    }
  }

  js_ast.Expression _emitInvalidNode(Node node, [String message = '']) {
    if (message.isNotEmpty) message += ' ';
    return _runtimeCall('throwUnimplementedError(#)',
        [js.escapedString('node <${node.runtimeType}> $message`$node`')]);
  }

  /// Emits a reference to the class described by [type].
  ///
  /// The nullability of [type] is not considered because it is meaningless when
  /// describing a reference to the class itself.
  ///
  /// For generic classes, type arguments are not needed since they are
  /// resolved late via an RTI lookup.
  ///
  /// Note that for `package:js` types, this will emit the class we emitted
  /// using `_emitJSInteropClassNonExternalMembers`, and not the runtime type
  /// that we synthesize for `package:js` types.
  js_ast.Expression _emitClassRef(InterfaceType type) {
    if (!_emittingClassExtends && type.typeArguments.isNotEmpty) {
      var genericName = _emitTopLevelNameNoExternalInterop(type.classNode);
      return js.call('#', [genericName]);
    }
    return _emitTopLevelNameNoExternalInterop(type.classNode);
  }

  Never _typeCompilationError(DartType type, String description) =>
      throw UnsupportedError('$description Encountered while compiling '
          '${_currentLibrary!.fileUri}, which contains the type: $type.');

  bool get _emittingClassExtends =>
      _currentClass != null && identical(_currentClass, _classEmittingExtends);

  /// Emits an expression that lets you access statics on a [type] from code.
  js_ast.Expression _emitConstructorName(InterfaceType type, Member c) {
    var isSyntheticDefault =
        c is Constructor && c.isSynthetic && c.name.text.isEmpty;
    // If it's an external constructor or synthetic default, use the JS
    // constructor.
    var jsConstructor = _emitJSInterop(type.classNode);
    if (jsConstructor != null && (c.isExternal || isSyntheticDefault)) {
      return jsConstructor;
    }
    // If it's non-external but belongs to an interop class, we want the class
    // reference we defined in `_emitJSInteropClassNonExternalMembers`.
    return js_ast.PropertyAccess(
        _emitClassRef(type), _constructorName(c.name.text));
  }

  /// Emits an expression that lets you access statics on [c] from code.
  ///
  /// If [isExternal] is false, emits the non-external name.
  js_ast.Expression _emitStaticClassName(Class c, bool isExternal) {
    return isExternal
        ? _emitTopLevelName(c)
        : _emitTopLevelNameNoExternalInterop(c);
  }

  js_ast.Identifier _emitTypeParameter(
      /* TypeParameter | StructuralParameter */ Object t) {
    assert(t is TypeParameter || t is StructuralParameter);
    return _emitIdentifier(getTypeParameterName(t));
  }

  /// Set incremental mode for expression compilation.
  ///
  /// Called for each expression compilation to set the incremental mode
  /// and clear referenced items.
  ///
  /// Sets all tables and internal structures to incremental mode so
  /// only referenced items will be emitted in a generated function.
  ///
  /// The compiler cannot revert to non-incremental mode, and requires the
  /// original module to be already emitted by the same compiler instance.
  void _setIncrementalMode() {
    if (!_moduleEmitted) {
      throw StateError(
          'Cannot run in incremental mode before module completion');
    }
    _incrementalModules.clear();
    _privateNames.clear();
    _symbolContainer.setIncrementalMode();
    _incrementalMode = true;

    _constTableCache = ModuleItemContainer<String>.asArray('C');
    _constLazyAccessors.clear();
    _constAliasCache.clear();

    _uriContainer = ModuleItemContainer<String>.asArray('I');

    _typeTable.typeContainer.setIncrementalMode();
  }

  /// Emits function after initial compilation.
  ///
  /// Emits function from kernel [functionNode] with name [name] in the context
  /// of [library] and [cls], after the initial compilation of the module is
  /// finished. For example, this happens in expression compilation during
  /// expression evaluation initiated by the user from the IDE and coordinated
  /// by the debugger.
  /// Triggers incremental mode, which only emits symbols, types, constants,
  /// libraries, and uris referenced in the expression compilation result.
  js_ast.Fun _emitFunctionIncremental(List<ModuleItem> items, Library library,
      Class? cls, FunctionNode functionNode, String name) {
    // Setup context.
    _currentLibrary = library;
    _staticTypeContext.enterLibrary(_currentLibrary!);
    _currentClass = cls;
    // Generic parameters should be evaluated in a class environment if
    // provided. Otherwise we default to an empty type environment.
    if (cls != null) {
      _currentTypeEnvironment = ClassTypeEnvironment(cls.typeParameters);
    }

    // Keep all symbols in containers.
    _containerizeSymbols = true;

    // Set all tables to incremental mode, so we can only emit elements that
    // were referenced the compiled code for the expression.
    _setIncrementalMode();

    // Do not add formal parameter checks for the top-level synthetic function
    // generated for expression evaluation, as those parameters are a set of
    // variables from the current scope, and should already be checked in the
    // original code.
    _checkParameters = false;

    // Emit function while recoding elements accessed from tables.
    var fun = _emitFunction(functionNode, name);

    var extensionSymbols = <js_ast.Statement>[];
    _emitExtensionSymbols(extensionSymbols);

    // Add all elements from tables accessed in the function
    var body = js_ast.Block([
      ...extensionSymbols,
      ..._typeTable.dischargeBoundTypes(),
      ..._symbolContainer.emit(),
      ..._emitConstTable(),
      ..._uriContainer.emit(),
      ...fun.body.statements
    ]);

    // Import all necessary libraries, including libraries accessed from the
    // current module and libraries accessed from the type table.
    for (var library in _typeTable.incrementalLibraries()) {
      _setEmitIfIncrementalLibrary(library);
    }
    _emitImports(items);
    _emitExportsAsImports(items, _currentLibrary!);

    return js_ast.Fun(fun.params, body);
  }

  List<js_ast.Statement> _emitConstTable() {
    var constTable = <js_ast.Statement>[];
    if (_constLazyAccessors.isNotEmpty) {
      constTable
          .add(js.statement('const # = Object.create(null);', [_constTable]));

      constTable.add(_runtimeStatement(
          'defineLazy(#, { # })', [_constTable, _constLazyAccessors]));

      constTable.addAll(_constTableCache.emit());
    }
    return constTable;
  }

  js_ast.Fun _emitFunction(FunctionNode f, String? name,
      {SourceLocation? functionEnd, SourceLocation? functionBody}) {
    var savedTypeEnvironment = _currentTypeEnvironment;
    if (f.typeParameters.isNotEmpty) {
      _currentTypeEnvironment =
          _currentTypeEnvironment.extend(f.typeParameters);
    }
    var formals = _emitParameters(f);
    var typeFormals = _emitTypeFormals(f.typeParameters);

    var parent = f.parent;
    if (_reifyGenericFunction(parent is Member ? parent : null)) {
      formals.insertAll(0, typeFormals);
    }

    // TODO(jmesserly): need a way of determining if parameters are
    // potentially mutated in Kernel. For now we assume all parameters are.
    _enterFunction(name, formals, () => true);

    var block = js_ast.Block(_withCurrentFunction(f, () {
      final bodyPrefix = _emitArgumentInitializers(f, name);

      // Do the async transformation before adding parameter initialization
      // logic. Any parameter initialization should be performed synchronously
      // before the async body is evaluated.
      final bodyFn =
          js_ast.Fun(formals, js_ast.Block([_emitFunctionScopedBody(f)]));
      final rewrittenFunction = _rewriteAsyncFunction(
          bodyFn, f.asyncMarker, name, f.emittedValueType,
          functionEnd: functionEnd,
          functionBody: functionBody,
          bodyPrefix: bodyPrefix);
      formals = rewrittenFunction.params;
      return rewrittenFunction.body.statements;
    }));

    block = _exitFunction(formals, block);
    var fn = js_ast.Fun(formals, block);

    _currentTypeEnvironment = savedTypeEnvironment;
    return fn;
  }

  /// Transforms [fun]'s body to support async execution if the function is
  /// async, sync*, or async*.
  ///
  /// [bodyPrefix] will get prepended to the body of the rewritten function and
  /// any references to parameters within it will be replaced with the correct
  /// temporary ID for that parameter.
  js_ast.Fun _rewriteAsyncFunction(js_ast.Fun fun, AsyncMarker asyncMarker,
      String? name, DartType? asyncType,
      {SourceLocation? functionEnd,
      SourceLocation? functionBody,
      List<js_ast.Statement>? bodyPrefix}) {
    AsyncRewriterBase? asyncRewriter;
    final bodyName = _emitScopedId('t\$async${name ?? 'Body'}');
    switch (asyncMarker) {
      case AsyncMarker.Sync:
        break;
      case AsyncMarker.Async:
        asyncRewriter = AsyncRewriter(
            asyncStart: _emitTopLevelNameNoExternalInterop(_asyncStartMember),
            asyncAwait: _emitTopLevelNameNoExternalInterop(_asyncAwaitMember),
            asyncReturn: _emitTopLevelNameNoExternalInterop(_asyncReturnMember),
            asyncRethrow:
                _emitTopLevelNameNoExternalInterop(_asyncRethrowMember),
            completerFactory:
                _emitTopLevelNameNoExternalInterop(_asyncMakeCompleterMember),
            completerFactoryTypeArguments: [
              _emitType(asyncType!),
            ],
            wrapBody:
                _emitTopLevelNameNoExternalInterop(_asyncWrapJsFunctionMember),
            bodyName: bodyName);
      case AsyncMarker.SyncStar:
        asyncRewriter = SyncStarRewriter(
            makeSyncStarIterable:
                _emitTopLevelNameNoExternalInterop(_syncStarMakeIterableMember),
            syncStarIterableTypeArgument: _emitType(asyncType!),
            iteratorCurrentValueProperty: _emitMemberName('_current',
                member: _syncStarIteratorCurrentMember),
            iteratorDatumProperty:
                _emitMemberName('_datum', member: _syncStarIteratorDatumMember),
            yieldStarSelector: _emitMemberName('_yieldStar',
                member: _syncStarIteratorYieldStarMember),
            bodyName: bodyName);
      case AsyncMarker.AsyncStar:
        asyncRewriter = AsyncStarRewriter(
            asyncStarHelper:
                _emitTopLevelNameNoExternalInterop(_asyncStarHelperMember),
            streamOfController: _emitTopLevelNameNoExternalInterop(
                _asyncStreamOfControllerMember),
            newController: _emitTopLevelNameNoExternalInterop(
                _asyncMakeAsyncStarStreamControllerMember),
            newControllerTypeArguments: [_emitType(asyncType!)],
            yieldExpression:
                _emitStaticGet(_asyncIterationMarkerYieldSingleMember),
            yieldStarExpression:
                _emitStaticGet(_asyncIterationMarkerYieldStarMember),
            wrapBody:
                _emitTopLevelNameNoExternalInterop(_asyncWrapJsFunctionMember),
            bodyName: bodyName);
    }
    if (asyncRewriter != null) {
      return asyncRewriter.rewrite(fun, functionBody, functionEnd,
          bodyPrefix: bodyPrefix);
    } else if (bodyPrefix != null) {
      fun.body.statements.insertAll(0, bodyPrefix);
    }
    return fun;
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
    if (f.namedParameters.isNotEmpty) result.add(_namedArgumentTemp);
    return result;
  }

  List<js_ast.Identifier> _emitTypeFormals(
      List< /*TypeParameter | StructuralParameter */ Object> typeFormals) {
    assert(typeFormals is List<TypeParameter> ||
        typeFormals is List<StructuralParameter>);
    return typeFormals
        .map((t) => _emitIdentifier(getTypeParameterName(t)))
        .toList();
  }

  List<js_ast.Statement> _withCurrentFunction(
      FunctionNode fn, List<js_ast.Statement> Function() action) {
    var savedFunction = _currentFunction;
    _currentFunction = fn;
    if (_isDartLibrary(_currentLibrary!, '_rti') ||
        _isSdkInternalRuntime(_currentLibrary!)) {
      _nullableInference.treatDeclaredTypesAsSound = true;
    }
    _nullableInference.enterFunction(fn);
    var result = _withLetScope(action);
    _nullableInference.exitFunction(fn);
    _nullableInference.treatDeclaredTypesAsSound = false;

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

  /// Executes [action] in context of the current [member].
  ///
  /// Saves and restores important context information about the member
  /// that can be used to generate code inside the body of the member.
  T _withMethodDeclarationContext<T>(Procedure member, T Function() action) {
    // Mixin applications require using 'super' in calls to members of
    // the super class. Store this information to disable non-virtual
    // super field access optimization when compiling the member body.
    var savedOptimizeNonVirtualFieldAccess = _optimizeNonVirtualFieldAccess;
    _optimizeNonVirtualFieldAccess =
        member.stubKind != ProcedureStubKind.ConcreteMixinStub;
    var result = action();
    _optimizeNonVirtualFieldAccess = savedOptimizeNonVirtualFieldAccess;
    return result;
  }

  /// Returns true if the underlying type does not accept a null value.
  bool _mustBeNonNullable(DartType type) =>
      type.nullability == Nullability.nonNullable;

  /// Returns `true` when an additional null check is needed because of the
  /// null safety compile mode, the null safety migration status of the current
  /// library and the provided [type] with its [annotations].
  bool _requiresExtraNullCheck(DartType type, List<Expression> annotations) =>
      !_options.soundNullSafety &&
      // Libraries that haven't been migrated to null safety represent
      // non-nullable as legacy.
      _currentLibrary!.nonNullable == Nullability.nonNullable &&
      _mustBeNonNullable(type) &&
      !_annotatedNotNull(annotations) &&
      // Trust the nullability of types in the dart:_rti library.
      !_isDartLibrary(_currentLibrary!, '_rti');

  /// Returns a null check for [value] that if fails produces an error message
  /// containing the [location] and [name] of the original value being checked.
  ///
  /// This is used to generate checks for non-nullable parameters when running
  /// with weak null safety. The checks can be silent, warn, or throw, depending
  /// on the flags set in the SDK at runtime.
  js_ast.Statement _nullSafetyParameterCheck(
      js_ast.Identifier value, Location? location, String? name) {
    // TODO(nshahan): Remove when weak mode null safety assertions are no longer
    // supported.
    // The check on `field.setterType` is per:
    // https://github.com/dart-lang/language/blob/master/accepted/2.12/nnbd/feature-specification.md#automatic-debug-assertion-insertion
    var condition = js.call('# == null', [value]);
    // Offsets are not available for compiler-generated variables
    // Get the best available location even if the offset is missing.
    // https://github.com/dart-lang/sdk/issues/34942
    return js.statement(' if (#) #;', [
      condition,
      _runtimeCall('nullFailed(#, #, #, #)', [
        location != null
            ? _cacheUri(location.file.toString())
            : js_ast.LiteralNull(),
        js.number(location?.line ?? -1),
        js.number(location?.column ?? -1),
        js.escapedString('$name')
      ])
    ]);
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  List<js_ast.Statement> _emitArgumentInitializers(
      FunctionNode f, String? name) {
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
      } else if (_requiresExtraNullCheck(p.type, p.annotations)) {
        body.add(_nullSafetyParameterCheck(jsParam, p.location, p.name));
      }
    }

    for (var p in f.positionalParameters) {
      var jsParam = _emitVariableRef(p);
      if (_checkParameters) {
        initParameter(p, jsParam);
      }
    }
    for (var p in f.namedParameters) {
      // Parameters will be passed using their real names, not the (possibly
      // renamed) local variable.
      var jsParam = _emitVariableDef(p);
      var paramName = _propertyName(p.name!);
      var defaultValue = _defaultParamValue(p);
      body.add(js.statement('let # = # && # ? #.# : #;', [
        jsParam,
        _namedArgumentTemp,
        _namedArgumentProbe(paramName),
        _namedArgumentTemp,
        paramName,
        defaultValue,
      ]));

      if (_checkParameters) {
        initParameter(p, jsParam);
      }
    }

    // '_checkParameters = false' is only needed once, while processing formal
    // parameters of the synthetic function from expression evaluation - it
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

  bool _reifyGenericFunction(Member? m) =>
      m == null ||
      // JS interop members should not pass type arguments.
      !isJsMember(m) &&
          !(m.enclosingLibrary.importUri.isScheme('dart') &&
              m.annotations.any((a) =>
                  isBuiltinAnnotation(a, '_js_helper', 'NoReifyGeneric')));

  js_ast.Statement _nullParameterCheck(js_ast.Expression param) {
    var call = _runtimeCall('argumentError((#))', [param]);
    return js.statement('if (# == null) #;', [param, call]);
  }

  js_ast.Expression _defaultParamValue(VariableDeclaration p) {
    if (p.initializer != null) {
      return _visitExpression(p.initializer!);
    } else {
      return js_ast.LiteralNull();
    }
  }

  /// Returns a test for the existence of [propertyName] in the named argument
  /// package.
  js_ast.Expression _namedArgumentProbe(js_ast.LiteralString propertyName) =>
      // If the name collides with the names in the native JavaScript object
      // prototype then use a slower but more direct test to avoid
      // accidentally finding a value up the prototype chain.
      js_ast.objectProperties.contains(propertyName.valueWithoutQuotes)
          ? _runtimeCall('hOP.call(#, #)', [_namedArgumentTemp, propertyName])
          : js.call('# in #', [propertyName, _namedArgumentTemp]);

  void _emitCovarianceBoundsCheck(
      List< /* TypeParameter | StructuralParameter */ Object> typeFormals,
      List<js_ast.Statement> body) {
    assert(typeFormals is List<TypeParameter> ||
        typeFormals is List<StructuralParameter>);
    for (var t in typeFormals) {
      bool? isCovariantByClass;
      DartType bound;
      String name;
      DartType typeParameterType;
      if (t is TypeParameter) {
        isCovariantByClass = t.isCovariantByClass;
        bound = t.bound.extensionTypeErasure;
        name = t.name!;
        typeParameterType = TypeParameterType(t, Nullability.undetermined);
      } else {
        t as StructuralParameter;
        bound = t.bound.extensionTypeErasure;
        name = t.name!;
        typeParameterType =
            StructuralParameterType(t, Nullability.undetermined);
      }

      if (isCovariantByClass != null &&
          isCovariantByClass &&
          !_types.isTop(bound)) {
        body.add(_runtimeStatement('checkTypeBound(#, #, #)', [
          _emitType(typeParameterType),
          _emitType(bound),
          _propertyName(name)
        ]));
      }
    }
  }

  js_ast.Statement _visitStatement(Statement s) {
    var result = s.accept(this);

    // In most cases, a Dart expression statement with a child expression
    // compile to a JS expression statement with a child expression.
    //
    //   ExpressionStatement                         js_ast.ExpressionStatement
    //            |           --> compiles to -->                 |
    //        Expression                                  js_ast.Expression
    //
    // Both the expression statement and child expression nodes contain their
    // own source location information.
    //
    // In the case of a debugger() call, the code compiles to a single node.
    //
    //   ExpressionStatement                         js_ast.DebuggerStatement
    //            |           --> compiles to -->
    //        Expression
    //
    // The js_ast.DebuggerStatement already has the correct source information
    // attached so we avoid overwriting with the incorrect source location from
    // [s].
    // TODO(jmesserly): is the `is! Block` still necessary?
    if (!(s is Block || result is js_ast.DebuggerStatement)) {
      result.sourceInformation ??= _nodeStart(s);
    }

    // The statement might be the target of a break or continue with a label.
    var name = _labelNames[s];
    if (name != null) result = js_ast.LabeledStatement(name, result);
    return result;
  }

  js_ast.Statement _emitFunctionScopedBody(FunctionNode f) {
    var jsBody = _visitStatement(f.body!);
    return _emitScopedBody(f, jsBody);
  }

  js_ast.Statement _emitScopedBody(FunctionNode f, js_ast.Statement body) {
    if (f.positionalParameters.isNotEmpty || f.namedParameters.isNotEmpty) {
      // Handle shadowing of parameters by local variables, which is allowed in
      // Dart but not in JS.
      //
      // We need this for all function types, including generator-based ones
      // (sync*/async/async*). Our code generator assumes it can emit names for
      // named argument initialization, and sync* functions also emit locally
      // modified parameters into the function's scope.
      var parameterNames = {
        for (var p in f.positionalParameters) p.name!,
        for (var p in f.namedParameters) p.name!,
      };

      return body.toScopedBlock(parameterNames);
    }
    return body;
  }

  /// Visits [nodes] with [_visitExpression].
  List<js_ast.Expression> _visitExpressionList(Iterable<Expression> nodes) {
    return nodes.map(_visitExpression).toList();
  }

  /// Generates an expression for a boolean conversion context (if, while, &&,
  /// etc.), where conversions and null checks are implemented via `dart.test`
  /// to give a more helpful message.
  // TODO(sra): When nullablility is available earlier, it would be cleaner to
  // build an input AST where the boolean conversion is a single AST node.
  js_ast.Expression _visitTest(Expression node) {
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
          _types.coreTypes.boolRawType(_currentLibrary!.nonNullable));
      return _runtimeCall('dtest(#)', [_visitExpression(node.operand)]);
    }

    var result = _visitExpression(node);
    if (_isNullable(node)) result = _runtimeCall('test(#)', [result]);
    return result;
  }

  js_ast.Expression _visitExpression(Expression e) {
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
  SourceLocation? _nodeStart(TreeNode node) => node is StringConcatenation
      // Manually selecting the location of the first element to work around the
      // location on the StringConcatenation node that points to the end of
      // String. See https://github.com/dart-lang/sdk/issues/55690.
      ? _toSourceLocation(node.expressions.first.fileOffset)
      : _toSourceLocation(node.fileOffset);

  /// Gets the end position of [node] for use in source mapping.
  ///
  /// This is mainly used for things that compile to JS functions. JS wants a
  /// marking on the end of all functions for stepping purposes.
  ///
  /// This can be used to complete a hover span, when we know the start position
  /// has already been emitted. For example, `foo.bar` we only need to mark the
  /// end of `.bar` to ensure `foo.bar` has a hover tooltip.
  NodeEnd? _nodeEnd(int endOffset) {
    var loc = _toSourceLocation(endOffset);
    return loc != null ? NodeEnd(loc) : null;
  }

  /// Combines [_nodeStart] with the variable name length to produce a hoverable
  /// span for the variable.
  //
  // TODO(jmesserly): we need a lot more nodes to support hover.
  NodeSpan? _variableSpan(int offset, int nameLength) {
    var start = _toSourceLocation(offset);
    var end = _toSourceLocation(offset + nameLength);
    return start != null && end != null ? NodeSpan(start, end) : null;
  }

  SourceLocation? _toSourceLocation(int offset) {
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
  HoverComment? _hoverComment(
      js_ast.Expression expr, int offset, int nameLength) {
    var start = _toSourceLocation(offset);
    var end = _toSourceLocation(offset + nameLength);
    return start != null && end != null ? HoverComment(expr, start, end) : null;
  }

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
    // unnecessary nested block.
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
    _uriContainer.setEmitIfIncremental(uri);
    return _uriContainer.access(uri);
  }

  @override
  js_ast.Statement visitAssertStatement(AssertStatement node) {
    if (!_options.enableAsserts) return js_ast.EmptyStatement();
    var condition = node.condition;
    var conditionType =
        condition.getStaticType(_staticTypeContext).extensionTypeErasure;
    var jsCondition = _visitExpression(condition);

    if (conditionType != _coreTypes.boolLegacyRawType &&
        conditionType != _coreTypes.boolNullableRawType &&
        conditionType != _coreTypes.boolNonNullableRawType) {
      jsCondition = _runtimeCall('dtest(#)', [jsCondition]);
    } else if (_isNullable(condition)) {
      // TODO(nshahan): Is this branch even reachable in null safe code?
      jsCondition = _runtimeCall('test(#)', [jsCondition]);
    }

    SourceLocation? location;
    late String conditionSource;
    var assertLocation = node.location;
    if (assertLocation != null) {
      var fileUri = assertLocation.file;
      var source = node.enclosingComponent!.uriToSource[fileUri]!.text;
      conditionSource =
          source.substring(node.conditionStartOffset, node.conditionEndOffset);
      // Assertions that appear in debugger expressions have a synthetic Uri
      // that is different than the current library where the expression will
      // be evaluated.
      var savedUri = _currentUri;
      _currentUri = fileUri;
      location = _toSourceLocation(node.conditionStartOffset)!;
      _currentUri = savedUri;
    } else {
      // If the location is ever null, only show the error with the condition
      // AST instead of the source.
      conditionSource = node.condition.toString();
    }
    return js.statement(' if (!#) #;', [
      jsCondition,
      _runtimeCall('assertFailed(#, #, #, #, #)', [
        if (node.message == null)
          js_ast.LiteralNull()
        else
          _visitExpression(node.message!),
        if (location == null)
          _cacheUri('<unknown source>')
        else
          _cacheUri(location.sourceUrl.toString()),
        // Lines and columns are typically printed with 1 based indexing.
        js.number(location == null ? -1 : location.line + 1),
        js.number(location == null ? -1 : location.column + 1),
        js.escapedString(conditionSource),
      ])
    ]);
  }

  bool _isBreakable(Statement stmt) {
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
    List<LabeledStatement>? saved;
    // If the effective target is known then this statement is either contained
    // in a labeled statement or a loop.  It has already been processed when
    // the enclosing statement was visited.
    if (!_effectiveTargets.containsKey(node)) {
      // Find the effective target by bypassing and collecting labeled
      // statements.
      var statements = [node];
      var target = node.body;
      while (target is LabeledStatement) {
        var labeled = target;
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
      if (_isBreakable(target)) {
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
      return js_ast.Break(_switchLabelStates[node.target.body]!.label);
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
    var name = _labelNames[target!];
    if (name == null) _labelNames[target] = name = 'L${_labelNames.length}';

    // It is a break if the target labeled statement encloses the effective
    // target.
    Statement current = node.target;
    while (current is LabeledStatement) {
      current = current.body;
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
      var labeled = body;
      _currentContinueTargets.add(labeled);
      _effectiveTargets[labeled] = loop;
      body = labeled.body;
    }
    return body;
  }

  T _translateLoop<T extends js_ast.Statement>(
      Statement node, T Function() action) {
    List<LabeledStatement>? savedBreakTargets;
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
  js_ast.Statement visitForStatement(ForStatement node) {
    return _translateLoop(node, () {
      js_ast.VariableInitialization emitForInitializer(VariableDeclaration v) =>
          js_ast.VariableInitialization(_emitVariableDef(v),
              _visitInitializer(v.initializer, v.annotations));

      if (node.variables.any(containsFunctionExpression)) {
        return _rewriteAsWhile(node);
      }
      var init = node.variables.map(emitForInitializer).toList();
      var initList =
          init.isEmpty ? null : js_ast.VariableDeclarationList('let', init);
      var updates = node.updates;
      js_ast.Expression? update;
      if (updates.isNotEmpty) {
        update = js_ast.Expression.binary(
                updates.map(_visitExpression).toList(), ',')
            .toVoidExpression();
      }
      var condition =
          node.condition != null ? _visitTest(node.condition!) : null;
      var body = _visitScope(_effectiveBodyOf(node, node.body));

      return js_ast.For(initList, condition, update, body);
    });
  }

  /// Rewrites a `for(;;)` style loop as a while loop to produce the correct
  /// semantics when loop variable initialziers contain function expressions
  /// that close over other loop variables.
  ///
  /// The Dart semantics expect that every loop iteration gets fresh loop
  /// variables that can be closed over. The initialization is only executed
  /// for the first iteration. In later iterations, the fresh loop variables are
  /// initalized to the values from the end of the previous iteration.
  ///
  /// These semantics differ from JavaScript when there are closures capturing
  /// loop variables so the simple lowering doesn't work as expected.
  ///
  /// A for loop like:
  ///
  /// ```
  /// for(var v1 = init1, v2 = init2; condition; updates) { body }
  /// ```
  ///
  /// Produces a rewrite like:
  ///
  /// ```
  /// var initFlag = true;
  /// var prev_v1, prev_v2;
  /// while (true) {
  ///   var v1, v2;
  ///   if (initFlag) {
  ///     initFlag = false;
  ///     v1 = inti1;
  ///     v2 = init2;
  ///   } else {
  ///     v1 = prev_v1;
  ///     v2 = prev_v2;
  ///     updates;
  ///   }
  ///   if (!condition) break;
  ///   body;
  ///   prev_v1 = v1;
  ///   prev_v2 = v2;
  /// }
  /// ```
  js_ast.Statement _rewriteAsWhile(ForStatement node) {
    var initFlagTempId = _emitScopedId('t#_init');
    var loopVariableIds = {
      for (var variable in node.variables) variable: _emitVariableDef(variable),
    };
    var prevVariableTempIds = {
      for (var variable in node.variables)
        variable: _emitScopedId('t#_prev_${variable.name!}'),
    };
    var inits = js_ast.Block([
      // Set init flag to false so the initialization only happens on the first
      // iteration of the while loop.
      js.statement('# = false;', [initFlagTempId]),
      // Initialize fresh loop variables to initial values.
      for (var variable in node.variables)
        js.statement('# = #;', [
          loopVariableIds[variable]!,
          _visitInitializer(variable.initializer, variable.annotations)
        ]),
    ]);
    var prevInits = js_ast.Block([
      // Intialize fresh loop variables with the value from the previous
      // iteration.
      for (var variable in node.variables)
        js.statement('# = #;',
            [loopVariableIds[variable], prevVariableTempIds[variable]]),
      // Original update expressions.
      for (var update in node.updates) _visitExpression(update).toStatement(),
    ]);
    return js_ast.Block([
      // Create temporary variables for the intialization flag and previous
      // loop variables.
      js_ast.VariableDeclarationList('let', [
        js_ast.VariableInitialization(initFlagTempId, js_ast.LiteralBool(true)),
        for (var variable in node.variables)
          js_ast.VariableInitialization(prevVariableTempIds[variable]!, null),
      ]).toStatement(),
      // The for loop transformed into a while loop.
      js_ast.While(
          js_ast.LiteralBool(true),
          js_ast.Block([
            // Create fresh loop variables every iteration.
            if (node.variables.isNotEmpty)
              js_ast.VariableDeclarationList('let', [
                for (var variable in node.variables)
                  js_ast.VariableInitialization(
                      loopVariableIds[variable]!, null)
              ]).toStatement(),
            // Initialize loop variables.
            js_ast.If(initFlagTempId, inits, prevInits),
            // Loop condition guard.
            if (node.condition != null)
              js.statement('if (!#) break;', [_visitTest(node.condition!)])
                ..sourceInformation = _nodeStart(node.condition!),
            // Original loop body.
            _visitScope(_effectiveBodyOf(node, node.body)),
            // Save previous loop variables
            for (var variable in node.variables)
              js.statement('# = #;',
                  [prevVariableTempIds[variable]!, _emitVariableRef(variable)])
                // Map these locations to the variable declaration so stepping
                // in the Dart debugger doesn't jump to the previous line when
                // stepping.
                ..sourceInformation = _nodeStart(variable),
          ]))
        // The while loop gets mapped to the orginal for loop location.
        ..sourceInformation = _nodeStart(node),
    ])
      // Clear the source mapping on the outer block so it doesn't automatically
      // get mapped to the for loop node in _visitStatement.
      ..sourceInformation = continueSourceMap;
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

      if (node.variable.name != null &&
          js_ast.variableIsReferenced(node.variable.name!, iterable)) {
        var temp = _emitScopedId('iter');
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
        _asyncStreamIteratorClass, _currentLibrary!.nonNullable);
    var streamIteratorRti = _emitType(streamIterator);
    var createStreamIter = js_ast.Call(
        _emitConstructorName(
            streamIterator,
            _asyncStreamIteratorClass.procedures
                .firstWhere((p) => p.isFactory && p.name.text == '')),
        [streamIteratorRti, _visitExpression(node.iterable)]);

    var iter = _emitScopedId('iter');

    var savedContinueTargets = _currentContinueTargets;
    var savedBreakTargets = _currentBreakTargets;
    _currentContinueTargets = <LabeledStatement>[];
    _currentBreakTargets = <LabeledStatement>[];
    var loopStmt = js.statement('while (#) { let # = #.current; #; }', [
      js_ast.Await(js.call('#.moveNext()', iter))
        ..sourceInformation = _nodeStart(node.variable),
      _emitVariableDef(node.variable),
      iter,
      _visitStatement(node.body)
    ]);

    // Any label on the Dart loop statement should target the inner loop rather
    // than the try-block we will wrap it in.
    final loopLabelName = _labelNames.remove(node);
    if (loopLabelName != null) {
      loopStmt = js_ast.LabeledStatement(loopLabelName, loopStmt);
    }

    var awaitForStmt = js_ast.Block([
      js_ast.ExpressionStatement(js_ast.VariableDeclarationList(
          'let', [js_ast.VariableInitialization(iter, createStreamIter)])
        ..sourceInformation = _nodeStart(node.iterable)),
      js.statement('try { # } finally { #; }', [
        loopStmt,
        js_ast.Await(js.call('#.cancel()', iter))
          ..sourceInformation = _nodeStart(node.variable)
      ])
    ], isScope: true);

    _currentContinueTargets = savedContinueTargets;
    _currentBreakTargets = savedBreakTargets;
    return awaitForStmt;
  }

  @override
  js_ast.Statement visitSwitchStatement(SwitchStatement node) {
    // Switches with labeled continues are generated as an infinite loop with
    // an explicit variable for holding the switch's next case state and an
    // explicit label. Any implicit breaks are made explicit (e.g., when break
    // is omitted for the final case statement).
    var previous = _inLabeledContinueSwitch;
    _inLabeledContinueSwitch = hasLabeledContinue(node);

    var cases = <js_ast.SwitchClause>[];

    if (_inLabeledContinueSwitch) {
      var labelState = _emitScopedId('labelState');
      // TODO(markzipan): Retrieve the real label name with source offsets
      var labelName = 'SL${_switchLabelStates.length}';
      _switchLabelStates[node] = _SwitchLabelState(labelName, labelState);

      // Since we wrap the switch in a 'while (true)' loop the continue targets
      // within the switch will no longer target the correct loop so we need
      // explicit breaks.
      final savedCurrentContinueTargets = _currentContinueTargets;
      _currentContinueTargets = [];

      for (var c in node.cases) {
        var subcases =
            _visitSwitchCase(c, lastSwitchCase: c == node.cases.last);
        if (subcases.isNotEmpty) cases.addAll(subcases);
      }
      _currentContinueTargets = savedCurrentContinueTargets;

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
  /// [lastSwitchCase] is only used when the current switch statement contains
  /// labeled continues. Dart permits the final case to implicitly break, but
  /// switch statements with labeled continues must explicitly break/continue
  /// to escape the surrounding infinite loop.
  List<js_ast.SwitchClause> _visitSwitchCase(SwitchCase node,
      {bool lastSwitchCase = false}) {
    var cases = <js_ast.SwitchClause>[];
    var emptyBlock = js_ast.Block.empty();
    // TODO(jmesserly): make sure we are statically checking fall through
    var body = _visitStatement(node.body).toBlock();
    var expressions = node.expressions;
    var lastExpr =
        expressions.isNotEmpty && !node.isDefault ? expressions.last : null;
    for (var e in expressions) {
      var jsExpr = _visitExpression(e);
      if (e is ConstantExpression && e.constant is NullConstant) {
        // Coerce null and undefined by adding an extra case.
        cases.add(js_ast.Case(js_ast.Prefix('void', js.number(0)), emptyBlock));
      }
      cases.add(js_ast.Case(jsExpr, e == lastExpr ? body : emptyBlock));
    }
    if (node.isDefault) {
      cases.add(js_ast.Default(body));
    }
    // Switch statements with continue labels must explicitly break from their
    // last case to escape the additional loop around the switch.
    if (lastSwitchCase && _inLabeledContinueSwitch && cases.isNotEmpty) {
      // TODO(markzipan): avoid generating unreachable breaks
      var switchStmt = node.parent as SwitchStatement;
      assert(_switchLabelStates.containsKey(node.parent));
      var breakStmt = js_ast.Break(_switchLabelStates[switchStmt]!.label);
      var switchBody = js_ast.Block(cases.last.body.statements..add(breakStmt));
      var lastCase = cases.last;
      var updatedSwitch = lastCase is js_ast.Case
          ? js_ast.Case(lastCase.expression, switchBody)
          : js_ast.Default(switchBody);
      cases.removeLast();
      cases.add(updatedSwitch);
    }
    return cases;
  }

  @override
  js_ast.Statement visitContinueSwitchStatement(ContinueSwitchStatement node) {
    var switchStmt = node.target.parent as SwitchStatement;
    if (_inLabeledContinueSwitch &&
        _switchLabelStates.containsKey(switchStmt)) {
      var switchState = _switchLabelStates[switchStmt]!;
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
    bool isTriviallyTrue(condition) =>
        condition is js_ast.LiteralBool && condition.value;

    bool isTriviallyFalse(condition) =>
        condition is js_ast.LiteralBool && !condition.value;

    var condition = _visitTest(node.condition);
    if (isTriviallyTrue(condition)) return _visitScope(node.then);
    var otherwise = node.otherwise;
    var hasElse = otherwise != null;
    if (isTriviallyFalse(condition)) {
      return hasElse ? _visitScope(otherwise) : js_ast.EmptyStatement();
    }
    return hasElse
        ? js_ast.If(condition, _visitScope(node.then), _visitScope(otherwise))
        : js_ast.If.noElse(condition, _visitScope(node.then));
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
    var expression = node.expression;
    var value = expression == null ? null : _visitExpression(expression);
    return _emitReturnStatement(value);
  }

  @override
  js_ast.Statement visitTryCatch(TryCatch node) {
    return js_ast.Try(
        _visitStatement(node.body).toBlock(), _visitCatch(node.catches), null);
  }

  js_ast.Catch? _visitCatch(List<Catch> clauses) {
    if (clauses.isEmpty) return null;

    var caughtError = VariableDeclaration('#e', isSynthesized: true);
    var savedRethrow = _rethrowParameter;
    _rethrowParameter = caughtError;

    // If we have more than one catch clause, always create a temporary so we
    // don't shadow any names.
    var exceptionParameter =
        (clauses.length == 1 ? clauses[0].exception : null) ??
            VariableDeclaration('#ex', isSynthesized: true);

    var stackTraceParameter =
        (clauses.length == 1 ? clauses[0].stackTrace : null) ??
            (clauses.any((c) => c.stackTrace != null)
                ? VariableDeclaration('#st', isSynthesized: true)
                : null);

    js_ast.Statement catchBody = js_ast.Throw(_emitVariableRef(caughtError));
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(
          clause, catchBody, exceptionParameter, stackTraceParameter);
    }
    var catchStatements = [
      js.statement('let # = #', [
        _emitVariableDef(exceptionParameter),
        _runtimeCall('getThrown(#)', [_emitVariableRef(caughtError)])
      ]),
      if (stackTraceParameter != null)
        js.statement('let # = #', [
          _emitVariableDef(stackTraceParameter),
          _runtimeCall('stackTrace(#)', [_emitVariableRef(caughtError)])
        ]),
      catchBody,
    ];
    _rethrowParameter = savedRethrow;
    return js_ast.Catch(_emitVariableDef(caughtError),
        js_ast.Block(catchStatements, isScope: true));
  }

  js_ast.Statement _catchClauseGuard(
      Catch node,
      js_ast.Statement otherwise,
      VariableDeclaration exceptionParameter,
      VariableDeclaration? stackTraceParameter) {
    var body = <js_ast.Statement>[];
    var vars = HashSet<String>();

    void declareVariable(
        VariableDeclaration? variable, VariableDeclaration? value) {
      if (variable == null || value == null) return;
      vars.add(variable.name!);
      if (variable.name != value.name) {
        body.add(js.statement('let # = #',
            [_emitVariableDef(variable), _emitVariableRef(value)]));
      }
    }

    declareVariable(node.exception, exceptionParameter);
    declareVariable(node.stackTrace, stackTraceParameter);

    body.add(_visitStatement(node.body).toScopedBlock(vars));
    // Each catch clause defines its own scope.
    var then = js_ast.Block(body, isScope: true);
    var guardType = node.guard.extensionTypeErasure;
    // Discard following clauses, if any, as they are unreachable.
    if (_types.isTop(guardType)) return then;

    var condition =
        _emitIsExpression(VariableGet(exceptionParameter), guardType);
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
    return js_ast.DartYield(
        _visitExpression(node.expression), node.isYieldStar);
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
    declareFn = js_ast.toBoundFunctionStatement(fn, name);
    if (_reifyFunctionType(func)) {
      declareFn = js_ast.Block([
        declareFn,
        _emitFunctionTagged(_emitVariableRef(node.variable),
                func.computeThisFunctionType(_currentLibrary!.nonNullable))
            .toStatement()
      ]);
    }
    return declareFn;
  }

  @override
  js_ast.Expression visitInvalidExpression(InvalidExpression node) =>
      _emitInvalidNode(node);

  @override
  js_ast.Expression visitConstantExpression(ConstantExpression node) =>
      visitConstant(node.constant);

  @override
  js_ast.Expression visitVariableGet(VariableGet node) {
    var v = node.variable;
    var id = _emitVariableRef(v);
    if (id.name == v.name) {
      id = id.withSourceInformation(
          _variableSpan(node.fileOffset, v.name!.length));
    }
    return id;
  }

  /// Detects temporary variables so we can avoid displaying
  /// them in the debugger if needed.
  bool _isTemporaryVariable(VariableDeclaration v) {
    // Late local variables are be exposed to the debugger for inspection and
    // evaluation by treating the backing store local variable as a regular
    // non-temporary variable.
    // See https://github.com/dart-lang/sdk/issues/55918
    if (isLateLoweredLocal(v)) return false;
    return v.isLowered ||
        v.isSynthesized ||
        v.name == null ||
        v.name!.startsWith('#');
  }

  /// Creates a temporary name recognized by the debugger.
  /// Assumes `_isTemporaryVariable(v)`  is true.
  String? _debuggerFriendlyTemporaryVariableName(VariableDeclaration v) {
    assert(_isTemporaryVariable(v));

    // Show extension 'this' in the debugger.
    // Do not show the rest of temporary variables.
    if (isExtensionThis(v)) {
      return extractLocalNameFromVariable(v);
    } else if (v.name != null) {
      return 't\$${v.name}';
    }
    return null;
  }

  js_ast.ScopedId _emitVariableRef(VariableDeclaration v) {
    if (_isTemporaryVariable(v)) {
      var name = _debuggerFriendlyTemporaryVariableName(v);
      name ??= 't\$${_tempVariables.length}';
      return _tempVariables.putIfAbsent(v, () => _emitScopedId(name!));
    }
    var name = v.name!;
    if (isLateLoweredLocal(v)) {
      // Late local variables are be exposed to the debugger for inspection and
      // evaluation by treating the backing store local variable as a regular
      // non-temporary variable.
      // See https://github.com/dart-lang/sdk/issues/55918
      name = extractLocalNameFromLateLoweredLocal(name);
    }
    return js_ast.ScopedId.from(
        _variableTempIds[v] ??= _emitScopedId(name, needsCapture: true));
  }

  /// Emits the declaration of a variable.
  ///
  /// This is similar to [_emitVariableRef] but it also attaches source
  /// location information, so hover will work as expected.
  js_ast.Identifier _emitVariableDef(VariableDeclaration v) {
    var identifier = _emitVariableRef(v)..sourceInformation = _nodeStart(v);
    variableIdentifiers[v] = identifier;
    return identifier;
  }

  js_ast.Statement? _initLetVariables() {
    var letVars = _letVariables!;
    if (letVars.isEmpty) return null;
    var result = js_ast.VariableDeclarationList('let',
            letVars.map((v) => js_ast.VariableInitialization(v, null)).toList())
        .toStatement();
    letVars.clear();
    return result;
  }

  // TODO(jmesserly): resugar operators for kernel, such as ++x, x++, x+=.
  @override
  js_ast.Expression visitVariableSet(VariableSet node) {
    // Make the source information of the assignment use the start of the right
    // hand side, to help normalize the inconsistent locations of the CFE
    // lowerings for ++x, x++, x+=, etc.
    // See https://github.com/dart-lang/sdk/issues/55691.
    return _visitExpression(node.value)
        .toAssignExpression(_emitVariableRef(node.variable))
      ..sourceInformation = _nodeStart(node.value);
  }

  @override
  js_ast.Expression visitDynamicGet(DynamicGet node) {
    var jsReceiver = _visitExpression(node.receiver);
    var jsMemberName = _emitMemberName(node.name.text);
    return _runtimeCall('dload$_replSuffix(#, #)', [jsReceiver, jsMemberName]);
  }

  @override
  js_ast.Expression visitInstanceGet(InstanceGet node) {
    // TODO(nshahan): Marking an end span for property accessors would improve
    // source maps and hovering in the debugger. Unfortunately this is not
    // possible as Kernel does not store this data.
    var member = node.interfaceTarget;
    var receiver = node.receiver;
    var jsReceiver = _visitExpression(receiver);
    if (_isNonStaticJsInteropCallMember(member)) {
      // Historically DDC has treated this as a "callable class" and the access
      // of `.call` as a no-op.
      //
      // This is here to preserve the existing behavior for the non-static
      // JavaScript interop (including some failing cases) but could potentially
      // be cleaned up as a breaking change.
      return jsReceiver;
    }
    var memberName = node.name.text;
    if (_isObjectGetter(memberName) &&
        _shouldCallObjectMemberHelper(receiver)) {
      // The names of the static helper methods in the runtime must match the
      // names of the Object instance getters.
      return _runtimeCall('#(#)', [memberName, jsReceiver]);
    }
    // Otherwise generate this as a normal typed property get.
    var jsMemberName =
        _emitMemberName(memberName, member: node.interfaceTarget);
    var instanceGet = js_ast.PropertyAccess(jsReceiver, jsMemberName);
    return _isNullCheckableJsInterop(node.interfaceTarget)
        ? _wrapWithJsInteropNullCheck(instanceGet)
        : instanceGet;
  }

  @override
  js_ast.Expression visitRecordIndexGet(RecordIndexGet node) =>
      _emitRecordElementGet(node.receiver, '\$${node.index + 1}');

  @override
  js_ast.Expression visitRecordNameGet(RecordNameGet node) =>
      _emitRecordElementGet(node.receiver, node.name);

  js_ast.Expression _emitRecordElementGet(
          Expression receiver, String elementName) =>
      js_ast.PropertyAccess(
          _visitExpression(receiver), _emitMemberName(elementName));

  @override
  js_ast.Expression visitInstanceTearOff(InstanceTearOff node) {
    var member = node.interfaceTarget;
    var receiver = node.receiver;
    var jsReceiver = _visitExpression(receiver);
    if (_isNonStaticJsInteropCallMember(member)) {
      // Historically DDC has treated this as a "callable class" and the tearoff
      // of `.call` as a no-op.
      //
      // This is here to preserve the existing behavior for the non-static
      // JavaScript interop (including some failing cases) but could potentially
      // be cleaned up as a breaking change.
      return jsReceiver;
    }
    var memberName = node.name.text;
    if (_isObjectMethodTearoff(memberName) &&
        _shouldCallObjectMemberHelper(receiver)) {
      // The names of the static helper methods in the runtime must start with
      // the names of the Object instance methods.
      var tearOffName = '${memberName}Tearoff';
      return _runtimeCall('#(#)', [tearOffName, jsReceiver]);
    }
    var jsMemberName = _emitMemberName(memberName, member: member);
    if (_reifyTearoff(member)) {
      return _runtimeCall('tearoff(#, #)', [jsReceiver, jsMemberName]);
    }
    var jsPropertyAccess = js_ast.PropertyAccess(jsReceiver, jsMemberName);
    return isJsMember(member)
        ? _runtimeCall('tearoffInterop(#, #)',
            [jsPropertyAccess, js.boolean(_isNullCheckableJsInterop(member))])
        : jsPropertyAccess;
  }

  /// Returns `true` when [member] is a `.call` member (field, getter or method)
  /// of a non-static JavaScript interop class.
  bool _isNonStaticJsInteropCallMember(Member member) =>
      member.name.text == 'call' && isNonStaticJsInterop(member);

  @override
  js_ast.Expression visitDynamicSet(DynamicSet node) {
    return _emitPropertySet(node.receiver, null, node.value, node.name.text);
  }

  @override
  js_ast.Expression visitInstanceSet(InstanceSet node) {
    return _emitPropertySet(
        node.receiver, node.interfaceTarget, node.value, node.name.text);
  }

  /// True when the result of evaluating [e] is not known to have the Object
  /// members installed so a helper method should be called instead of a direct
  /// instance invocation.
  ///
  /// This is a best effort approach determined by the static type information
  /// and may return `true` when the evaluation result does in fact have the
  /// members at runtime.
  bool _shouldCallObjectMemberHelper(Expression e) {
    if (_isNullable(e)) return true;
    var type = e.getStaticType(_staticTypeContext).extensionTypeErasure;
    if (type is RecordType || type is FunctionType) return false;
    if (type is InterfaceType) {
      // TODO(nshahan): This could be expanded to any classes where we know all
      // implementations at compile time and none of them are JS interop.
      var cls = type.classNode;
      // NOTE: This is not guaranteed to always be true. Currently in the SDK
      // none of the final classes or their subtypes use JavaScript interop.
      // If that was to ever change, this check will need to be updated.
      // For now, this is a shortcut since all subclasses of a class are not
      // immediately accessible.
      if (cls.isFinal && cls.enclosingLibrary.importUri.isScheme('dart')) {
        return false;
      }
    }
    // Constants have a static type known at compile time that will not be a
    // subtype at runtime.
    return !_triviallyConstNoInterop(e);
  }

  /// True when [e] is known to evaluate to a constant that has an interface
  /// type that is not a JavaScript interop type.
  ///
  /// This is a simple approach and not an exhaustive search.
  bool _triviallyConstNoInterop(Expression? e) {
    if (e is ConstantExpression) {
      var type = e.constant.getType(_staticTypeContext).extensionTypeErasure;
      if (type is InterfaceType) return !usesJSInterop(type.classNode);
    } else if (e is StaticGet && e.target.isConst) {
      var target = e.target;
      if (target is Field) {
        return _triviallyConstNoInterop(target.initializer);
      }
    } else if (e is VariableGet && e.variable.isConst) {
      return _triviallyConstNoInterop(e.variable.initializer);
    }
    return false;
  }

  /// Returns [expression] wrapped in an optional null check.
  ///
  /// The null check is enabled by setting a flag during the application
  /// bootstrap via `jsInteropNonNullAsserts(true)` in the SDK runtime library.
  js_ast.Expression _wrapWithJsInteropNullCheck(js_ast.Expression expression) =>
      _runtimeCall('jsInteropNullCheck(#)', [expression]);

  /// Returns `true` when [member] is a JavaScript interop API that should be
  /// checked to be not null when the runtime flag `--interop-null-assertions`
  /// is enabled.
  ///
  /// These APIs are defined using the non-static package:js interop library and
  /// are typed to be non-nullable.
  bool _isNullCheckableJsInterop(Member member) {
    var type =
        member is Procedure ? member.function.returnType : member.getterType;
    return type.nullability == Nullability.nonNullable &&
        isNonStaticJsInterop(member);
  }

  /// Return whether [member] returns a native object whose type needs to be
  /// null-checked in sound null-safety.
  ///
  /// This is true for non-nullable native return types.
  bool _isNullCheckableNative(Member member) {
    var c = member.enclosingClass;
    return _options.soundNullSafety &&
        member.isExternal &&
        c != null &&
        _extensionTypes.isNativeClass(c) &&
        member is Procedure &&
        member.function.returnType.isPotentiallyNonNullable &&
        _isWebLibrary(member.enclosingLibrary.importUri);
  }

  // TODO(jmesserly): can we encapsulate REPL name lookups and remove this?
  // _emitMemberName would be a nice place to handle it, but we don't have
  // access to the target expression there (needed for `dart.replNameLookup`).
  String get _replSuffix => _options.replCompile ? 'Repl' : '';

  js_ast.Expression _emitPropertySet(Expression receiver, Member? member,
      Expression value, String memberName) {
    var jsName = _emitMemberName(memberName, member: member);

    if (member != null && isJsMember(member)) {
      value = _assertInterop(value);
    }

    var jsReceiver = _visitExpression(receiver);
    var jsValue = _visitExpression(value);

    if (member == null) {
      return _runtimeCall(
          'dput$_replSuffix(#, #, #)', [jsReceiver, jsName, jsValue]);
    }
    return js.call('#.# = #', [jsReceiver, jsName, jsValue]);
  }

  @override
  js_ast.Expression visitAbstractSuperPropertyGet(
      AbstractSuperPropertyGet node) {
    return _emitSuperPropertyGet(node.interfaceTarget);
  }

  @override
  js_ast.Expression visitSuperPropertyGet(SuperPropertyGet node) {
    return _emitSuperPropertyGet(node.interfaceTarget);
  }

  js_ast.Expression _emitSuperPropertyGet(Member target) {
    if (_reifyTearoff(target)) {
      if (_superAllowed) {
        var jsTarget = _emitSuperTarget(target);
        return _runtimeCall('bind(this, #, #)', [jsTarget.selector, jsTarget]);
      } else {
        return _emitSuperTearoff(target);
      }
    }
    return _emitSuperTarget(target);
  }

  @override
  js_ast.Expression visitAbstractSuperPropertySet(
      AbstractSuperPropertySet node) {
    return _emitSuperPropertySet(node.interfaceTarget, node.value);
  }

  @override
  js_ast.Expression visitSuperPropertySet(SuperPropertySet node) {
    return _emitSuperPropertySet(node.interfaceTarget, node.value);
  }

  js_ast.Expression _emitSuperPropertySet(Member target, Expression value) {
    var jsTarget = _emitSuperTarget(target, setter: true);
    return _visitExpression(value).toAssignExpression(jsTarget);
  }

  @override
  js_ast.Expression visitStaticGet(StaticGet node) {
    final target = node.target;
    if (_isDartJsHelper(target.enclosingLibrary)) {
      final name = target.name.text;
      if (name == 'staticInteropGlobalContext') {
        return _runtimeCall('global');
      }
    }
    var staticGet = _emitStaticGet(target);
    return _isNullCheckableJsInterop(target)
        ? _wrapWithJsInteropNullCheck(staticGet)
        : staticGet;
  }

  @override
  js_ast.Expression visitStaticTearOff(StaticTearOff node) =>
      _emitStaticGet(node.target);

  js_ast.Expression _emitStaticGet(Member target) {
    var propertyAccessor = _emitStaticTarget(target);
    var context = propertyAccessor.receiver;
    var property = propertyAccessor.selector;
    var result = js.call('#.#', [context, property]);
    if (_reifyTearoff(target)) {
      return _runtimeCall('staticTearoff(#, #)', [context, property]);
    }
    return result;
  }

  @override
  js_ast.Expression visitStaticSet(StaticSet node) {
    var target = node.target;
    var result = _emitStaticTarget(target);
    var value = isJsMember(target) ? _assertInterop(node.value) : node.value;
    return _visitExpression(value).toAssignExpression(result);
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
    var invocation = _emitMethodCall(
        node.receiver, node.interfaceTarget, node.arguments, node);
    return _isNullCheckableJsInterop(node.interfaceTarget)
        ? _wrapWithJsInteropNullCheck(invocation)
        : invocation;
  }

  @override
  js_ast.Expression visitInstanceGetterInvocation(
      InstanceGetterInvocation node) {
    var getterInvocation = _emitMethodCall(
        node.receiver, node.interfaceTarget, node.arguments, node);
    return _isNullCheckableJsInterop(node.interfaceTarget)
        ? _wrapWithJsInteropNullCheck(getterInvocation)
        : getterInvocation;
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
        negated: false);
  }

  @override
  js_ast.Expression visitEqualsNull(EqualsNull node) {
    return _emitCoreIdenticalCall([node.expression, NullLiteral()],
        negated: false);
  }

  js_ast.Expression _emitMethodCall(Expression receiver, Member? target,
      Arguments arguments, InvocationExpression node) {
    var name = node.name.text;

    /// Returns `true` when [node] represents an invocation of `List.add()` that
    /// can be optimized.
    ///
    /// The optimized add operation can skip checks for a growable or modifiable
    /// list and the element type is known to be invariant so it can skip the
    /// type check.
    bool isNativeListInvariantAdd(InvocationExpression node) {
      if (node is InstanceInvocation &&
          node.isInvariant &&
          node.name.text == 'add') {
        // The call to add is marked as invariant, so the type check on the
        // parameter to add is not needed.
        var receiver = node.receiver;
        if (receiver is VariableGet &&
            receiver.variable.isFinal &&
            !receiver.variable.isLate) {
          // The receiver is a final variable, so it only contains the
          // initializer value. Also, avoid late variables in case the CFE
          // lowering of late variables is changed in the future.
          var initializer = receiver.variable.initializer;
          if (initializer is ListLiteral) {
            // The initializer is a list literal, so we know the list can be
            // grown, modified, and is represented by a JavaScript Array.
            return true;
          }
          if (initializer is StaticInvocation &&
              initializer.target.enclosingClass == _coreTypes.listClass &&
              initializer.target.name.text == 'of' &&
              initializer.arguments.named.isEmpty) {
            // The initializer is a `List.of()` call from the dart:core library
            // and the growable named argument has not been passed (it defaults
            // to true).
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
        // Erasing extension types here doesn't make sense. If there is an
        // extension type on dynamic or Function it will only be callable if it
        // defines a call method which would be invoked statically.
        _isDynamicOrFunction(target.getterType);
    if (name == 'call') {
      // Erasing the extension types here to support existing callable behaivor
      // on the old style JS interop types that are callable. This should be
      // safe as it is a compile time error to try to dynamically invoke a call
      // method that is inherited from an extension type.
      var receiverType =
          receiver.getStaticType(_staticTypeContext).extensionTypeErasure;
      if (isCallingDynamicField || _isDynamicOrFunction(receiverType)) {
        return _emitDynamicInvoke(jsReceiver, null, args, arguments);
      } else if (_isDirectCallable(receiverType)) {
        // Call methods on function types should be handled as function calls.
        return js_ast.Call(jsReceiver, args);
      }
    }

    var jsName = _emitMemberName(name, member: target);

    // Handle Object methods that are supported by `null` and potentially
    // JavaScript interop values.
    if (_isObjectMethodCall(name, arguments)) {
      if (_shouldCallObjectMemberHelper(receiver)) {
        // The names of the static helper methods in the runtime must match the
        // names of the Object instance members.
        return _runtimeCall('#(#, #)', [name, jsReceiver, args]);
      }
      // Otherwise generate this as a normal typed method call.
    } else if (target == null || isCallingDynamicField) {
      return _emitDynamicInvoke(jsReceiver, jsName, args, arguments);
    }
    // TODO(jmesserly): remove when Kernel desugars this for us.
    // Handle `o.m(a)` where `o.m` is a getter returning a class with `call`.
    if (target is Field || target is Procedure && target.isAccessor) {
      // We must erase the extension type to find the `call` method.
      // If the extension type has a runtime representation with a `call`:
      //
      // ```
      // extension type Ext(C c) implements C {...}
      // class C {
      //   call() {...}
      // }
      // ```
      //
      // We can always erase eagerly becuase:
      //  - Extension types that do not implment an interface that exposes a
      //    `call` method will result in a static error at the call site.
      //  - Calls to extension types that implement their own call method are
      //    lowered by the CFE to top level static method calls.
      var fromType = target!.getterType.extensionTypeErasure;
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
      js_ast.Expression? methodName,
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

    return _runtimeCall(jsCode, jsArgs);
  }

  bool _isDirectCallable(DartType t) =>
      t is FunctionType || (t is InterfaceType && usesJSInterop(t.classNode));

  js_ast.Expression? _implicitCallTarget(InterfaceType from) {
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
      Expression expr, Member? target, InvocationExpression node) {
    var op = node.name.text;
    if (target != null) {
      var dispatchType = _coreTypes.nonNullableRawType(target.enclosingClass!);
      if (_typeRep.unaryOperationIsPrimitive(dispatchType)) {
        if (op == '~') {
          if (_typeRep.isNumber(dispatchType)) {
            return _coerceBitOperationResultToUnsigned(
                node, js.call('~#', _notNull(expr)));
          }
          return _emitOperatorCall(expr, target, op, []);
        }
        if (op == 'unary-') op = '-';
        return js.call('$op#', _notNull(expr));
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
    Expression? left;
    late Expression right;
    late String op;
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

  int? _asIntInRange(Expression expr, int low, int high) {
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
        final max = (1 << width) - 1;
        if (left != null) {
          if (_asIntInRange(right, 0, max) != null) return true;
          if (_asIntInRange(left, 0, max) != null) return true;
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

  js_ast.Expression _emitBinaryOperator(Expression left, Member? target,
      Expression right, InvocationExpression node) {
    var op = node.name.text;
    if (op == '==') return _emitEqualityOperator(left, target, right);

    // TODO(jmesserly): using the target type here to work around:
    // https://github.com/dart-lang/sdk/issues/33293
    if (target != null) {
      var targetClass = target.enclosingClass!;
      var leftType = _coreTypes.nonNullableRawType(targetClass);
      var rightType = right.getStaticType(_staticTypeContext);

      if (_typeRep.binaryOperationIsPrimitive(leftType, rightType) ||
          targetClass == _coreTypes.stringClass && op == '+') {
        // Inline operations on primitive types where possible.
        // TODO(jmesserly): inline these from dart:core instead of hardcoding
        // the implementation details here.

        /// Emits an inlined binary operation using the JS [code], adding null
        /// checks if needed to ensure we throw the appropriate error.
        js_ast.Expression binary(String code) {
          return js.call(code, [_notNull(left), _notNull(right)])
            ..sourceInformation = continueSourceMap;
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
          return js.call(code, [_notNull(left), _visitTest(right)]);
        }

        switch (op) {
          case '~/':
            // `a ~/ b` is equivalent to `(a / b).truncate()`
            return js.call('(# / #).#()', [
              _notNull(left),
              _notNull(right),
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

          case '>>>':
            if (_asIntInRange(right, 0, 31) != null) {
              return binary('# >>> #');
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
      Expression left, Member? target, Expression right,
      {bool negated = false}) {
    var targetClass = target?.enclosingClass;
    var leftType = left.getStaticType(_staticTypeContext).extensionTypeErasure;

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

    if (_shouldCallObjectMemberHelper(left)) {
      // The LHS isn't guaranteed to have an equals method we need to use a
      // runtime helper.
      return js.call(negated ? '!#' : '#', [
        _runtimeCall(
            'equals(#, #)', [_visitExpression(left), _visitExpression(right)])
      ]);
    }
    // Otherwise it is safe to call the equals method on the LHS directly.
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
      Expression receiver, Member? target, String name, List<Expression> args) {
    // TODO(jmesserly): calls that don't pass `element` are probably broken for
    // `super` calls from disallowed super locations.
    var memberName = _emitMemberName(name, member: target);
    if (target == null) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': 'dindex', '[]=': 'dsetindex'}[name];
      if (dynamicHelper != null) {
        return _runtimeCall('$dynamicHelper(#, #)',
            [_visitExpression(receiver), _visitExpressionList(args)]);
      } else {
        return _runtimeCall('dsend(#, #, [#])', [
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
  js_ast.Expression visitAbstractSuperMethodInvocation(
      AbstractSuperMethodInvocation node) {
    return _emitSuperMethodInvocation(node.interfaceTarget, node.arguments);
  }

  @override
  js_ast.Expression visitSuperMethodInvocation(SuperMethodInvocation node) {
    return _emitSuperMethodInvocation(node.interfaceTarget, node.arguments);
  }

  js_ast.Expression _emitSuperMethodInvocation(
      Member target, Arguments arguments) {
    return js_ast.Call(
        _emitSuperTarget(target), _emitArgumentList(arguments, target: target));
  }

  /// Emits the [js_ast.PropertyAccess] for accessors or method calls to
  /// [jsTarget].[jsName], replacing `super` if it is not allowed in scope.
  js_ast.PropertyAccess _emitSuperTarget(Member member, {bool setter = false}) {
    var jsName = _emitMemberName(member.name.text, member: member);
    // Optimize access to non-virtual fields, if allowed in the current context.
    if (_optimizeNonVirtualFieldAccess &&
        member is Field &&
        !_virtualFields.isVirtual(member)) {
      return js_ast.PropertyAccess(js_ast.This(), jsName);
    }
    if (_superAllowed) return js_ast.PropertyAccess(js_ast.Super(), jsName);

    // If we can't emit `super` in this context, generate a helper that does it
    // for us, and call the helper.
    //
    // NOTE: This is intended to help in the cases of calling a `super` getter,
    // setter, or method. For the case of tearing off a `super` method in
    // contexts where `super` isn't allowed, see [_emitSuperTearoff].
    var name = member.name.text;
    var getter = (member is Field && !setter) ||
        (member is Procedure && member.isGetter);
    // Prefix applied to the name only used in the compiler for a map key. This
    // name does not make its way into the compiled program.
    var lookupPrefix = setter
        ? r'set$'
        : getter
            ? r'get$'
            : '';
    var jsMethod = _superHelpers.putIfAbsent('$lookupPrefix$name', () {
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

        return js_ast.Method(_emitScopedId(name), fn,
            isGetter: !setter, isSetter: setter);
      } else {
        var function = member.function;
        var params = [
          ..._emitTypeFormals(function.typeParameters),
          for (var param in function.positionalParameters)
            _emitIdentifier(param.name!),
          if (function.namedParameters.isNotEmpty) _namedArgumentTemp,
        ];

        var fn = js.fun(
            'function(#) { return super[#](#); }', [params, jsName, params]);
        name = js_ast.friendlyNameForDartOperator[name] ?? name;
        return js_ast.Method(_emitScopedId(name), fn);
      }
    });
    return js_ast.PropertyAccess(js_ast.This(), jsMethod.name);
  }

  /// Generates a helper method that is inserted into the class that binds a
  /// tearoff of [member] from `super` and returns a call to the helper.
  ///
  /// This method assumes `super` is not allowed in the current context.
  // TODO(nshahan) Replace with a kernel transform and synthetic method filters
  // for devtools.
  js_ast.Expression _emitSuperTearoff(Member member) {
    var jsName = _emitMemberName(member.name.text, member: member);
    var name = '_#super#tearOff#${member.name.text}';
    var jsMethod = _superHelpers.putIfAbsent(name, () {
      var jsReturnValue =
          _runtimeCall('bind(this, #, super[#])', [jsName, jsName]);
      var fn = js.fun('function() { return #; }', [jsReturnValue]);
      name = js_ast.friendlyNameForDartOperator[name] ?? name;
      return js_ast.Method(_emitScopedId(name), fn);
    });
    return js_ast.Call(js_ast.PropertyAccess(js_ast.This(), jsMethod.name), []);
  }

  /// If [e] is a [TypeLiteral] or a [TypeLiteralConstant] expression, return
  /// the underlying [DartType], otherwise returns null.
  // TODO(sigmund,nshahan): remove all uses of type literals in the runtime
  // libraries, so that this pattern can be deleted.
  DartType? _getTypeLiteralType(Expression e) {
    if (e is TypeLiteral) return e.type;
    if (e is ConstantExpression) {
      var constant = e.constant;
      if (constant is TypeLiteralConstant) {
        return constant.type.withDeclaredNullability(Nullability.nonNullable);
      }
    }
    return null;
  }

  @override
  js_ast.Expression visitStaticInvocation(StaticInvocation node) {
    var target = node.target;
    if (isInlineJS(target)) return _emitInlineJSCode(node) as js_ast.Expression;
    if (target.isFactory) return _emitFactoryInvocation(node);

    var enclosingLibrary = target.enclosingLibrary;
    if (_isDartLibrary(enclosingLibrary, '_rti') &&
        _inlineTester.canInline(target.function)) {
      // Transform code that would otherwise appear as a static invocation:
      // ```
      // if (_rti._isString(object)) {...}
      // ```
      //
      // to be avoid cost of extra function calls:
      //
      // ```
      // if (typeof object == "string") {...}
      // ```
      var body = node.target.function.body;
      Expression? bodyToInline;
      // Extract the body.
      if (body is ReturnStatement) {
        // Ex: foo() => <body>;
        bodyToInline = body.expression;
      } else if (body is Block) {
        // Ex: foo() { <body> }
        var singleStatement = body.statements.single;
        if (singleStatement is ReturnStatement) {
          bodyToInline = singleStatement.expression;
        }
      }
      if (bodyToInline != null) {
        // Clone the function parameters and create the mappings from the clone
        // to the argument passed.
        var cloner = CloneVisitorNotMembers();
        var originalParameters = target.function.positionalParameters;
        var replacementArguments = node.arguments.positional;
        var replacements = {
          for (var i = 0; i < originalParameters.length; i++)
            originalParameters[i].accept(cloner) as VariableDeclaration:
                replacementArguments[i],
        };
        // Clone the body using the same cloner to ensure the cloned parameters
        // are correctly linked to their accesses.
        var cloneToInline = bodyToInline.accept(cloner);
        // Substitute the use of the parameters with the values passed.
        var replacer = VariableGetReplacer(replacements);
        var replaced = cloneToInline.accept(replacer) as Expression;
        // Compile the result normally and wrap in parenthesis.
        return js.call('(#)', [replaced.accept(this)]);
      }
    }

    if (_isDartInternal(enclosingLibrary)) {
      var args = node.arguments;
      if (args.positional.length == 1 &&
          args.types.length == 1 &&
          args.named.isEmpty &&
          target.name.text == 'unsafeCast') {
        // Optimize some internal SDK calls by avoiding the insertion of a
        // runtime cast.
        return args.positional.single.accept(this);
      } else if (node.arguments.positional.length == 2 &&
          node.arguments.types.length == 1 &&
          node.arguments.named.isEmpty &&
          target.name.text == 'extractTypeArguments') {
        // Inline the extraction and method call at compile time because we
        // don't preserve the original type argument names into the runtime.
        // Those names are needed in the evaluation string used to extract the
        // types from the provided instance.
        // At this time the only two uses of this method are extracting from
        // `Iterable` and `Map`. There are no extension type uses so no need for
        // erasure here.
        var extractionType = node.arguments.types.single;
        if (extractionType is! InterfaceType) {
          throw UnsupportedError(
              'Type arguments can only be extracted from interface types: '
              'found $extractionType (${extractionType.runtimeType}) at '
              '${node.location}');
        }
        var extractionTypeParameters = extractionType.classNode.typeParameters;
        if (extractionTypeParameters.isEmpty) {
          throw UnsupportedError(
              'The extraction type must have type arguments to be extracted: '
              'found $extractionType (${extractionType.runtimeType}) at '
              '${node.location}');
        }
        var extractionTypeParameterNames = extractionTypeParameters
            .map((p) => '${extractionType.classNode.name}.${p.name!}');
        var instance = node.arguments.positional.first.accept(this);
        var function = node.arguments.positional.last.accept(this);
        var extractedTypeArgs = js_ast.ArrayInitializer([
          for (var recipe in extractionTypeParameterNames)
            js.call('#.#(#, "$recipe")', [
              _emitLibraryName(_rtiLibrary),
              _emitMemberName('evalInInstance', memberClass: _rtiClass),
              instance
            ])
        ]);
        return _runtimeCall('dgcall(#, #, [])', [function, extractedTypeArgs]);
      }
    }

    if (_isDartForeignHelper(enclosingLibrary)) {
      var args = node.arguments.positional;
      var typeArgs = node.arguments.types;
      var name = target.name.text;

      if (args.isEmpty) {
        if (typeArgs.isEmpty && name == 'DART_RUNTIME_LIBRARY') {
          return _emitLibraryName(_runtimeLibrary);
        }
        if (typeArgs.length == 1) {
          if (name == 'TYPE_REF') {
            return _emitType(typeArgs.single);
          }
          if (name == 'LEGACY_TYPE_REF') {
            return _emitType(
                typeArgs.single.withDeclaredNullability(Nullability.legacy));
          }
        }
      }
      if (args.length == 1) {
        if (name == 'getInterceptor') {
          var argExpression = args.single.accept(this);
          return _runtimeCall('getInterceptorForRti(#)', [argExpression]);
        }
        if (name == 'JS_GET_NAME') {
          var staticGet = args.single as StaticGet;
          var enumField = staticGet.target as Field;
          return _emitExpressionForJsGetName(_asJsGetName(enumField));
        }
        if (name == 'JS_CLASS_REF') {
          var constNode = args.single as ConstantExpression;
          var typeConstant = constNode.constant as TypeLiteralConstant;
          var type = typeConstant.type;
          if (type is NullType) {
            return _emitTopLevelName(_coreTypes.deprecatedNullClass);
          }
          if (type is! InterfaceType) {
            throw UnsupportedError(
                'JS_CLASS_REF only supports interface types: found $type '
                '(${type.runtimeType}) at ${node.location}');
          }
          return _emitTopLevelName(type.classNode);
        }
        if (name == 'RAW_DART_FUNCTION_REF') {
          var expression = args.single as ConstantExpression;
          var fn = expression.constant as StaticTearOffConstant;
          return _emitStaticTarget(fn.target);
        }
        if (name == 'JS_GET_FLAG') {
          var flag = args.single as StringLiteral;
          var value = flag.value;
          return switch (value) {
            'DEV_COMPILER' => js.boolean(true),
            'PRINT_LEGACY_STARS' => js.boolean(_options.printLegacyStars),
            'LEGACY' => _options.soundNullSafety
                ? js.boolean(false)
                // When running the new runtime type system with weak null
                // safety this flag gets toggled when performing `is` and `as`
                // checks. This allows DDC to produce optional warnings or
                // errors when tests pass but would fail in sound null safety.
                : _runtimeCall('legacyTypeChecks'),
            'SOUND_NULL_SAFETY' => js.boolean(_options.soundNullSafety),
            'EXTRA_NULL_SAFETY_CHECKS' => _options.soundNullSafety
                ? js.boolean(false)
                // When running the new runtime type system with weak null
                // safety this flag gets toggled when performing `is` and `as`
                // checks. This allows DDC to produce optional warnings or
                // errors when tests pass but would fail in sound null safety.
                : _runtimeCall('extraNullSafetyChecks'),
            'MINIFIED' => js.boolean(false),
            'VARIANCE' =>
              // Variance is turned on by default, but only interfaces that have
              // at least one type parameter with non-legacy variance will have
              // extra information recorded.
              js.boolean(true),
            _ => throw UnsupportedError(
                'Unknown JS_GET_FLAG "$value" at ${node.location}')
          };
        }
      } else if (args.length == 2) {
        if (name == 'JS_EMBEDDED_GLOBAL') return _emitEmbeddedGlobal(node);
        if (name == 'JS_STRING_CONCAT') {
          var left = _visitExpression(args.first);
          var right = _visitExpression(args.last);
          return js.call('# + #', [left, right]);
        }
      }
      if (name == 'JS_BUILTIN') {
        var staticGet = args[1] as StaticGet;
        var enumField = staticGet.target as Field;
        return _emitOperationForJsBuiltIn(_asJsBuiltin(enumField));
      }
      if (name == 'JS_RAW_EXCEPTION') {
        // Serves as a way to access the wrapped JS exception.
        return _emitVariableRef(_rethrowParameter!);
      }
      if (name == 'JS_RTI_PARAMETER') {
        return _rtiParam;
      }
    }

    if (_isSdkInternalRuntime(enclosingLibrary)) {
      var name = target.name.text;
      if (node.arguments.positional.length == 1) {
        var firstArg = node.arguments.positional.single;
        if (name == 'extensionSymbol' && firstArg is StringLiteral) {
          return _getSymbol(_getExtensionSymbolInternal(firstArg.value));
        }
      } else if (node.arguments.positional.length == 2) {
        var firstArg = node.arguments.positional[0];
        var secondArg = node.arguments.positional[1];
        var type = _getTypeLiteralType(secondArg);
        if (name == '_jsInstanceOf' &&
            type is InterfaceType &&
            type.typeArguments.isEmpty) {
          return js.call('# instanceof #',
              [_visitExpression(firstArg), _emitTopLevelName(type.classNode)]);
        }
      }
    }
    if (_isDartJsHelper(enclosingLibrary)) {
      var name = target.name.text;
      if (name == 'jsObjectGetPrototypeOf') {
        var obj = node.arguments.positional.single;
        return _emitJSObjectGetPrototypeOf(_visitExpression(obj),
            fullyQualifiedName: false);
      }
      if (name == 'jsObjectSetPrototypeOf') {
        var obj = node.arguments.positional.first;
        var prototype = node.arguments.positional.last;
        return _emitJSObjectSetPrototypeOf(
            _visitExpression(obj), _visitExpression(prototype),
            fullyQualifiedName: false);
      }
    }
    if (target.isExternal &&
        target.isExtensionTypeMember &&
        target.function.namedParameters.isNotEmpty) {
      // JS interop checks assert that only external extension type constructors
      // and factories have named parameters.
      assert(target.function.positionalParameters.isEmpty);
      return _emitObjectLiteral(
          Arguments(node.arguments.positional,
              types: node.arguments.types, named: node.arguments.named),
          target);
    }
    if (target == _coreTypes.identicalProcedure) {
      return _emitCoreIdenticalCall(node.arguments.positional);
    }
    if (_isDebuggerCall(target)) {
      return _emitDebuggerCall(node) as js_ast.Expression;
    }
    if (_isDartJsUtil(enclosingLibrary)) {
      // We try and do further inlining here for the unchecked/trusted-type
      // variants of js_util methods. Note that we only lower the methods that
      // are used in transformations and are private. Also note that this
      // inlining ignores `sdk/lib/_internal/js_shared/lib/js_util_patch.dart`'s
      // implementations for the lowered methods.
      //
      // If you update the code there, you should update the code here.
      // Long-term, we'll need a better IR to lower interop methods to, or a DDC
      // inliner to do the inlining for us.
      var name = target.name.text;
      if (name == '_getPropertyTrustType') {
        return js_ast.PropertyAccess(
            _visitExpression(node.arguments.positional[0]),
            _visitExpression(node.arguments.positional[1]));
      } else if (name == '_setPropertyUnchecked') {
        return _visitExpression(node.arguments.positional[2])
            .toAssignExpression(js_ast.PropertyAccess(
                _visitExpression(node.arguments.positional[0]),
                _visitExpression(node.arguments.positional[1])));
      } else if (RegExp(r'^\_callMethodUnchecked(TrustType)?[0-4]')
          .hasMatch(name)) {
        // Note that we don't lower `_callMethodTrustType`. This is because it
        // uses `assertInterop` checks.
        var trustType = name.contains('TrustType');
        var args = <js_ast.Expression>[];
        assert(node.arguments.named.isEmpty);
        // Ignore the receiver and name of the method.
        for (var i = 2; i < node.arguments.positional.length; i++) {
          args.add(_visitExpression(node.arguments.positional[i]));
        }
        js_ast.Expression call = js_ast.Call(
            js_ast.PropertyAccess(
                _visitExpression(node.arguments.positional[0]),
                _visitExpression(node.arguments.positional[1])),
            args);
        if (!trustType) {
          call = _emitCast(call, node.arguments.types[0]);
        }
        return call;
      } else if (RegExp(r'^\_callConstructorUnchecked[0-4]').hasMatch(name)) {
        var args = <js_ast.Expression>[];
        assert(node.arguments.named.isEmpty);
        // Ignore the constructor.
        for (var i = 1; i < node.arguments.positional.length; i++) {
          args.add(_visitExpression(node.arguments.positional[i]));
        }
        return _emitCast(
            js_ast.New(_visitExpression(node.arguments.positional[0]), args),
            node.arguments.types[0]);
      }
    }

    var fn = _emitStaticTarget(target);
    var args = _emitArgumentList(node.arguments, target: target);
    var staticCall = js_ast.Call(fn, args);
    return _isNullCheckableJsInterop(target)
        ? _wrapWithJsInteropNullCheck(staticCall)
        : staticCall;
  }

  js_ast.Expression _emitJSObjectGetPrototypeOf(js_ast.Expression obj,
          {required bool fullyQualifiedName}) =>
      fullyQualifiedName
          ? _runtimeCall('global.Object.getPrototypeOf(#)', [obj])
          : js.call('Object.getPrototypeOf(#)', obj);

  js_ast.Expression _emitJSObjectSetPrototypeOf(
          js_ast.Expression obj, js_ast.Expression prototype,
          {required bool fullyQualifiedName}) =>
      fullyQualifiedName
          ? _runtimeCall('global.Object.setPrototypeOf(#, #)', [obj, prototype])
          : js.call('Object.setPrototypeOf(#, #)', [obj, prototype]);

  bool _isDebuggerCall(Procedure target) {
    return target.name.text == 'debugger' &&
        target.enclosingLibrary.importUri.toString() == 'dart:developer';
  }

  js_ast.Node _emitDebuggerCall(StaticInvocation node) {
    var args = node.arguments.named;
    var isStatement = node.parent is ExpressionStatement;
    var debuggerStatement =
        js_ast.DebuggerStatement().withSourceInformation(_nodeStart(node));
    if (args.isEmpty) {
      // Inline `debugger()` with no arguments, as a statement if possible,
      // otherwise as an immediately invoked function.
      return isStatement
          ? debuggerStatement
          : js.call('(() => { #; return true})()', [debuggerStatement]);
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
        ? js.statement('if (#) #;', [when, debuggerStatement])
        : js.call(
            '# && (() => { #; return true })()', [when, debuggerStatement]);
  }

  /// Emits the target of a [StaticInvocation], [StaticGet], or [StaticSet].
  js_ast.PropertyAccess _emitStaticTarget(Member target) {
    var c = target.enclosingClass;
    if (c != null) {
      // A static native element should just forward directly to the JS type's
      // member, for example `Css.supports(...)` in dart:html should be replaced
      // by a direct call to the DOM API: `global.CSS.supports`.
      var isExternal = _isExternal(target);
      if (isExternal && (target as Procedure).isStatic) {
        var nativeName = _extensionTypes.getNativePeers(c);
        if (nativeName.isNotEmpty) {
          var annotationName = _annotationName(target, isJSName);
          var memberName = annotationName == null
              ? _emitStaticMemberName(target.name.text, target)
              : js.string(annotationName);
          return js_ast.PropertyAccess(
              _runtimeCall('global.#', [nativeName[0]]), memberName);
        }
      }
      return js_ast.PropertyAccess(_emitStaticClassName(c, isExternal),
          _emitStaticMemberName(target.name.text, target));
    }
    return _emitTopLevelName(target);
  }

  List<js_ast.Expression> _emitArgumentList(Arguments node,
      {bool types = true, Member? target}) {
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
    return js_ast.Property(_propertyName(arg.name), _visitExpression(value));
  }

  /// Emits code for the `JS(...)` macro.
  js_ast.Node _emitInlineJSCode(StaticInvocation node) {
    var args = node.arguments.positional;
    // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
    var code = args[1];
    List<Expression> templateArgs;
    String source;
    if (code is ConstantExpression) {
      templateArgs = args.skip(2).toList();
      source = (code.constant as StringConstant).value;
    } else if (code is StringConcatenation) {
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
    if (_isWebLibrary(_currentLibrary!.importUri) && _options.soundNullSafety) {
      var type = node.getStaticType(_staticTypeContext);
      if (type.isPotentiallyNonNullable) {
        result = _runtimeCall('checkNativeNonNull(#)', [result]);
      }
    }

    assert(result is js_ast.Expression ||
        result is js_ast.Statement && node.parent is ExpressionStatement);
    return result.withSourceInformation(_nodeStart(node));
  }

  js_ast.Expression _emitEmbeddedGlobal(StaticInvocation node) {
    var constantExpression = node.arguments.positional[1] as ConstantExpression;
    var name = constantExpression.constant as StringConstant;
    var value = name.value;
    if (value == 'arrayRti') {
      // Special case for the rti on a JSArray. These are defined via the dartx
      // extension functionality.
      return _emitMemberName('arrayRti', memberClass: _jsArrayClass);
    }
    return _runtimeCall('#', [name.value]);
  }

  /// Returns the string literal that is to be used as the result of a call to
  /// [JS_GET_NAME] for [name].
  js_ast.Expression _emitExpressionForJsGetName(JsGetName name) {
    switch (name) {
      case JsGetName.OPERATOR_IS_PREFIX:
        return js.string(js_ast.FixedNames.operatorIsPrefix);
      case JsGetName.SIGNATURE_NAME:
        return _runtimeCall(
            '#', [js.string(js_ast.FixedNames.operatorSignature)]);
      case JsGetName.RTI_NAME:
        return js.string(js_ast.FixedNames.rtiName);
      case JsGetName.FUTURE_CLASS_TYPE_NAME:
        return js.string(
            _typeRecipeGenerator.interfaceTypeRecipe(_coreTypes.futureClass));
      case JsGetName.LIST_CLASS_TYPE_NAME:
        return js.string(
            _typeRecipeGenerator.interfaceTypeRecipe(_coreTypes.listClass));
      case JsGetName.RTI_FIELD_AS:
        return _emitMemberName(js_ast.FixedNames.rtiAsField,
            memberClass: _rtiClass);
      case JsGetName.RTI_FIELD_IS:
        return _emitMemberName(js_ast.FixedNames.rtiIsField,
            memberClass: _rtiClass);
      default:
        throw UnsupportedError('JsGetName has no name for "$name".');
    }
  }

  /// Returns the expression that is to be used as the result of a call to
  /// [JS_BUILTIN] for [builtin].
  js_ast.Expression _emitOperationForJsBuiltIn(JsBuiltin builtin) {
    switch (builtin) {
      case JsBuiltin.dartClosureConstructor:
        // TODO(48585) Is this safe or will it conflict with functions that
        // enter the program through JS Interop?
        return js.call('Function');
      case JsBuiltin.dartObjectConstructor:
        return _emitTopLevelName(_coreTypes.objectClass);
      default:
        throw UnsupportedError('JsBuiltin has no operation for "$builtin".');
    }
  }

  String _enumValueName(Field field) {
    var enumName = field.enclosingClass!.name;
    var valueName = field.name.text;
    return '$enumName.$valueName';
  }

  JsGetName _asJsGetName(Field field) => JsGetName.values
      .firstWhere((val) => val.toString() == _enumValueName(field));

  JsBuiltin _asJsBuiltin(Field field) => JsBuiltin.values
      .firstWhere((val) => val.toString() == _enumValueName(field));

  bool _isWebLibrary(Uri importUri) =>
      importUri.isScheme('dart') &&
      (importUri.path == 'html' ||
          importUri.path == 'svg' ||
          importUri.path == 'indexed_db' ||
          importUri.path == 'web_audio' ||
          importUri.path == 'web_gl' ||
          importUri.path == 'web_sql' ||
          importUri.path == 'html_common');

  bool _isNull(Expression expr) =>
      expr is NullLiteral ||
      expr.getStaticType(_staticTypeContext).extensionTypeErasure is NullType;

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
    return !_isNullable(left) || !_isNullable(right);
  }

  /// Returns true if [expr] can be null.
  bool _isNullable(Expression expr) {
    if (_isDartLibrary(_currentLibrary!, '_rti') ||
        _isSdkInternalRuntime(_currentLibrary!)) {
      _nullableInference.treatDeclaredTypesAsSound = true;
    }
    final result = _nullableInference.isNullable(expr);
    _nullableInference.treatDeclaredTypesAsSound = false;
    return result;
  }

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
      return _runtimeCall(
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

  /// Returns true if this [member] is a JS interop member.
  bool isJSInteropMember(Member member) =>
      member.isExternal && hasJSInteropAnnotation(member.enclosingClass!);

  @override
  js_ast.Expression visitConstructorInvocation(ConstructorInvocation node) {
    var ctor = node.target;
    var ctorClass = ctor.enclosingClass;
    var args = node.arguments;
    if (isJSAnonymousType(ctorClass)) return _emitObjectLiteral(args, ctor);
    // JS interop constructor calls do not provide an RTI at the call site.
    var shouldProvideRti =
        !isJSInteropMember(ctor) && _requiresRtiForInstantiation(ctorClass);
    var rti = shouldProvideRti
        ? _emitType(node.constructedType,
            emitJSInteropGenericClassTypeParametersAsAny: false)
        : null;
    var result = js_ast.New(
      _emitConstructorName(node.constructedType, ctor),
      [
        if (rti != null) rti,
        ..._emitArgumentList(args, types: false, target: ctor)
      ],
    );
    return node.isConst ? _canonicalizeConstObject(result) : result;
  }

  js_ast.Expression _emitFactoryInvocation(StaticInvocation node) {
    var args = node.arguments;
    var ctor = node.target;
    var ctorClass = ctor.enclosingClass!;
    // JS interop constructor calls do not require an RTI at the call site.
    if (isJSInteropMember(ctor)) {
      return _emitJSInteropNew(ctor, args);
    }

    var type = ctorClass.typeParameters.isEmpty
        ? _coreTypes.nonNullableRawType(ctorClass)
        : InterfaceType(ctorClass, Nullability.nonNullable, args.types);

    if (isFromEnvironmentInvocation(_coreTypes, node)) {
      var value = _constants.evaluate(node);
      if (value is PrimitiveConstant) {
        return visitConstant(value);
      }
    }

    if (args.positional.isEmpty &&
        args.named.isEmpty &&
        ctorClass.enclosingLibrary.importUri.isScheme('dart')) {
      // Skip the slow SDK factory constructors when possible.
      switch (ctorClass.name) {
        case 'Map':
        case 'HashMap':
        case 'LinkedHashMap':
          if (ctor.name.text == '') {
            var mapType = _createMapImplType(type);
            var mapClass = _emitClassRef(mapType);
            var rti = _emitType(mapType);
            return js.call('new #.new(#)', [mapClass, rti]);
          } else if (ctor.name.text == 'identity') {
            var mapType = _createMapImplType(type, identity: true);
            var mapClass = _emitClassRef(mapType);
            var rti = _emitType(mapType);
            return js.call('new #.new(#)', [mapClass, rti]);
          }
        case 'Set':
        case 'HashSet':
        case 'LinkedHashSet':
          if (ctor.name.text == '') {
            var setType = _createSetImplType(type);
            var setClass = _emitClassRef(setType);
            var rti = _emitType(setType);
            return js.call('new #.new(#)', [setClass, rti]);
          } else if (ctor.name.text == 'identity') {
            var setType = _createSetImplType(type, identity: true);
            var setClass = _emitClassRef(setType);
            var rti = _emitType(setType);
            return js.call('new #.new(#)', [setClass, rti]);
          }
        case 'List':
          if (ctor.name.text == '') {
            return _emitList(type.typeArguments[0], []);
          }
      }
    }
    var rti = _requiresRtiForInstantiation(ctorClass)
        ? _emitType(type, emitJSInteropGenericClassTypeParametersAsAny: false)
        : null;
    var result = js_ast.Call(_emitConstructorName(type, ctor),
        [if (rti != null) rti, ..._emitArgumentList(args, types: false)]);
    return node.isConst ? _canonicalizeConstObject(result) : result;
  }

  js_ast.Expression _emitJSInteropNew(Member ctor, Arguments args) {
    var ctorClass = ctor.enclosingClass!;
    if (isJSAnonymousType(ctorClass)) return _emitObjectLiteral(args, ctor);
    // JS interop constructor calls do not require an RTI at the call site.
    return js_ast.New(
        _emitConstructorName(_coreTypes.nonNullableRawType(ctorClass), ctor),
        _emitArgumentList(args, types: false, target: ctor));
  }

  InterfaceType _createMapImplType(InterfaceType type, {bool? identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) {
      return type.withDeclaredNullability(Nullability.nonNullable);
    }
    identity ??= _typeRep.isPrimitive(typeArgs[0]);
    var c = identity ? _identityHashMapImplClass : _linkedHashMapImplClass;
    return InterfaceType(c, Nullability.nonNullable, typeArgs);
  }

  InterfaceType _createSetImplType(InterfaceType type, {bool? identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) {
      return type.withDeclaredNullability(Nullability.nonNullable);
    }
    identity ??= _typeRep.isPrimitive(typeArgs[0]);
    var c = identity ? _identityHashSetImplClass : _linkedHashSetImplClass;
    return InterfaceType(c, Nullability.nonNullable, typeArgs);
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
    if (operand is EqualsCall) {
      return _emitEqualityOperator(
          operand.left, operand.interfaceTarget, operand.right,
          negated: true);
    } else if (operand is EqualsNull) {
      return _emitCoreIdenticalCall([operand.expression, NullLiteral()],
          negated: true);
    } else if (operand is StaticInvocation &&
        operand.target == _coreTypes.identicalProcedure) {
      return _emitCoreIdenticalCall(operand.arguments.positional,
          negated: true);
    }

    var jsOperand = _visitTest(operand);
    if (jsOperand is js_ast.LiteralBool) {
      // Flipping the value here for `!true` or `!false` allows for simpler
      // `if (true)` or `if (false)` detection and optimization.
      return js_ast.LiteralBool(!jsOperand.value)
              .withSourceInformation(jsOperand.sourceInformation)
          as js_ast.LiteralBool;
    }

    // Logical negation, `!e`, is a boolean conversion context since it is
    // defined as `e ? false : true`.
    return js.call('!#', jsOperand).withSourceInformation(continueSourceMap);
  }

  @override
  js_ast.Expression visitNullCheck(NullCheck node) {
    var expr = node.operand;
    var jsExpr = _visitExpression(expr);
    // If the expression is non-nullable already, this is a no-op.
    return _isNullable(expr) ? _runtimeCall('nullCheck(#)', [jsExpr]) : jsExpr;
  }

  @override
  js_ast.Expression visitLogicalExpression(LogicalExpression node) {
    // The operands of logical boolean operators are subject to boolean
    // conversion.
    return _visitTest(node);
  }

  @override
  js_ast.Expression visitConditionalExpression(ConditionalExpression node) {
    var condition = _visitTest(node.condition);
    if (condition is js_ast.LiteralBool) {
      if (condition.value) {
        // Avoid emitting conditional when one branch is effectively dead code.
        // ex: `true ? foo : bar` -> `foo`
        return _visitExpression(node.then);
      } else {
        // ex: `false ? foo : bar` -> `bar`
        return _visitExpression(node.otherwise);
      }
    }
    var then = _visitExpression(node.then);
    var otherwise = _visitExpression(node.otherwise);
    return js.call('# ? # : #', [condition, then, otherwise])
      ..sourceInformation =
          condition.sourceInformation ?? _nodeStart(node.condition);
  }

  @override
  js_ast.Expression visitStringConcatenation(StringConcatenation node) {
    var parts = <js_ast.Expression>[];
    for (var e in node.expressions) {
      var jsExpr = _visitExpression(e);
      if (jsExpr is js_ast.LiteralString && jsExpr.valueWithoutQuotes.isEmpty) {
        continue;
      }
      var type = e.getStaticType(_staticTypeContext).extensionTypeErasure;
      if (DartTypeEquivalence(_coreTypes, ignoreTopLevelNullability: true)
              .areEqual(type, _coreTypes.stringNonNullableRawType) &&
          !_isNullable(e)) {
        parts.add(jsExpr);
      } else if (_shouldCallObjectMemberHelper(e)) {
        parts.add(_runtimeCall('str(#)', [jsExpr]));
      } else {
        // It is safe to call a version of `str()` that does not probe for the
        // toString method before calling it.
        parts.add(_runtimeCall('strSafe(#)', [jsExpr]));
      }
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
  js_ast.Expression visitConstructorTearOff(ConstructorTearOff node) {
    throw UnsupportedError('Constructor tear off');
  }

  @override
  js_ast.Expression visitRedirectingFactoryTearOff(
      RedirectingFactoryTearOff node) {
    throw UnsupportedError('RedirectingFactory tear off');
  }

  @override
  js_ast.Expression visitTypedefTearOff(TypedefTearOff node) {
    throw UnsupportedError('Typedef instantiation');
  }

  @override
  js_ast.Expression visitIsExpression(IsExpression node) {
    return _emitIsExpression(node.operand, node.type.extensionTypeErasure);
  }

  js_ast.Expression _emitIsExpression(Expression operand, DartType type) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    var lhs = _visitExpression(operand);
    // It is invalid to use a simplified check for a native type in place of
    // a type test for a `TypeParameterType`. This is because at runtime type
    // parameters can be instantiated as the bottom type `Never` and
    // `val is Never` should always evaluate to false.
    var typeofName =
        type is TypeParameterType || type is StructuralParameterType
            ? null
            : _typeRep.typeFor(type).primitiveTypeOf;
    // Inline non-nullable primitive types other than int (which requires a
    // Math.floor check).
    if (typeofName != null &&
        type.nullability == Nullability.nonNullable &&
        type != _types.coreTypes.intNonNullableRawType) {
      return js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    }

    return js.call('#.#(#)', [
      _emitType(type),
      _emitMemberName(js_ast.FixedNames.rtiIsField, memberClass: _rtiClass),
      lhs
    ]);
  }

  @override
  js_ast.Expression visitAsExpression(AsExpression node) {
    var fromExpr = node.operand;
    var jsFrom = _visitExpression(fromExpr);
    if (node.isUnchecked) return jsFrom;
    var to = node.type.extensionTypeErasure;
    var from = fromExpr.getStaticType(_staticTypeContext).extensionTypeErasure;

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
      return _runtimeCall('nullCast(#, #)', [jsFrom, _emitType(to)]);
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
        return _runtimeCall('nullCast(#, #)', [jsFrom, _emitType(to)]);
      }

      // * -> int : asInt check
      if (to == _coreTypes.intNonNullableRawType) {
        return _runtimeCall('asInt(#)', [jsFrom]);
      }

      // * -> int? | int* : asNullableInt check
      if (to == _coreTypes.intLegacyRawType ||
          to == _coreTypes.intNullableRawType) {
        return _runtimeCall('asNullableInt(#)', [jsFrom]);
      }
    }

    return _emitCast(jsFrom, to);
  }

  js_ast.Expression _emitCast(js_ast.Expression expr, DartType type) {
    var normalizedType = type.extensionTypeErasure;
    if (_types.isTop(normalizedType)) return expr;
    return js.call('#.#(#)', [
      _emitType(normalizedType),
      _emitMemberName(js_ast.FixedNames.rtiAsField, memberClass: _rtiClass),
      expr
    ]);
  }

  @override
  js_ast.Expression visitSymbolLiteral(SymbolLiteral node) =>
      _emitDartSymbol(node.value);

  @override
  js_ast.Expression visitTypeLiteral(TypeLiteral node) =>
      _emitTypeLiteral(node.type);

  js_ast.Expression _emitTypeLiteral(DartType type) {
    var typeRep = _emitType(type);

    // TODO(46002) All `JS()` calls in the SDK should be explicit when using the
    // internal rti object by calling the `TYPE_REF` helper.
    if (_isInForeignJS) return typeRep;

    // If the type is a type literal expression in Dart code, wrap the raw
    // runtime type in a "Type" instance.
    return js.call(
        '#.createRuntimeType(#)', [_emitLibraryName(_rtiLibrary), typeRep]);
  }

  @override
  js_ast.Expression visitThisExpression(ThisExpression node) => js_ast.This();

  @override
  js_ast.Expression visitRethrow(Rethrow node) {
    return _runtimeCall('rethrow(#)', [_emitVariableRef(_rethrowParameter!)]);
  }

  @override
  js_ast.Expression visitThrow(Throw node) =>
      _runtimeCall('throw(#)', [_visitExpression(node.expression)]);

  @override
  js_ast.Expression visitListLiteral(ListLiteral node) {
    var elementType = node.typeArgument;
    var elements = _visitExpressionList(node.expressions);
    return _emitList(elementType, elements);
  }

  js_ast.Expression _emitList(
      DartType itemType, List<js_ast.Expression> items) {
    var list = js_ast.ArrayInitializer(items);

    // List's type parameter is default-initialized to dynamic in our runtime.
    if (itemType == const DynamicType()) return list;

    // Call `new JSArray<E>.of(list)`
    var type =
        InterfaceType(_jsArrayClass, Nullability.nonNullable, [itemType]);
    var arrayClass = _emitClassRef(type);
    var arrayRti = _emitType(type);
    return js.call('#.of(#, #)', [arrayClass, arrayRti, list]);
  }

  js_ast.Expression _emitConstList(
      DartType elementType, List<js_ast.Expression> elements) {
    return _runtimeCall(
        'constList(#, [#])', [_emitType(elementType), elements]);
  }

  @override
  js_ast.Expression visitSetLiteral(SetLiteral node) {
    // TODO(markzipan): remove const check when we use front-end const eval
    if (!node.isConst) {
      var type = InterfaceType(
          _linkedHashSetClass, Nullability.nonNullable, [node.typeArgument]);
      var setClass = _emitClassRef(type);
      var rti = _emitType(type);
      if (node.expressions.isEmpty) {
        return js.call('#.new(#)', [setClass, rti]);
      }
      return js.call('#.from(#, [#])',
          [setClass, rti, _visitExpressionList(node.expressions)]);
    }
    return _emitConstSet(
        node.typeArgument, _visitExpressionList(node.expressions));
  }

  js_ast.Expression _emitConstSet(
      DartType elementType, List<js_ast.Expression> elements) {
    return _runtimeCall('constSet(#, [#])', [_emitType(elementType), elements]);
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
      var type = node.getStaticType(_staticTypeContext) as InterfaceType;
      var mapType = _createMapImplType(type);
      var mapClass = _emitClassRef(mapType);
      var rti = _emitType(mapType);
      if (node.entries.isEmpty) {
        return js.call('new #.new(#)', [mapClass, rti]);
      }
      return js.call('new #.from(#, [#])', [mapClass, rti, entries]);
    }
    return _emitConstMap(node.keyType, node.valueType, entries);
  }

  js_ast.Expression _emitConstMap(
      DartType keyType, DartType valueType, List<js_ast.Expression> entries) {
    return _runtimeCall('constMap(#, #, [#])',
        [_emitType(keyType), _emitType(valueType), entries]);
  }

  /// Returns the key used for shape lookup at runtime.
  ///
  /// See `shapes` in dart:_runtime (records.dart) for a description.
  String _recordShapeKey(
      int positionalElementCount, Iterable<String> namedElementNames) {
    var elementCount = positionalElementCount + namedElementNames.length;
    return '$elementCount;${namedElementNames.join(',')}';
  }

  @override
  js_ast.Expression visitRecordLiteral(RecordLiteral node) {
    var names = node.named.map((element) => element.name);
    var positionalElementCount = node.positional.length;
    var shapeKey = _recordShapeKey(positionalElementCount, names);
    var shapeExpr = _runtimeCall('recordLiteral(#, #, #, [#])', [
      js.string(shapeKey),
      js.number(positionalElementCount),
      names.isEmpty ? js.call('void 0') : js.stringArray(names),
      [
        for (var positional in node.positional) _visitExpression(positional),
        for (var named in node.named) _visitExpression(named.value),
      ]
    ]);
    return shapeExpr;
  }

  @override
  js_ast.Expression visitAwaitExpression(AwaitExpression node) {
    var expression = _visitExpression(node.operand);
    var type = node.runtimeCheckType;
    if (type != null) {
      // When an expected runtime type is present there is a possible soundness
      // issue with the static types. The type of the await expression must be
      // checked at runtime to ensure soundness.
      var expectedType = _emitType(type);
      var asyncLibrary = _emitLibraryName(_coreTypes.asyncLibrary);
      expression = js.call('#.awaitWithTypeCheck(#, #)',
          [asyncLibrary, expectedType, expression]);
    }
    return js_ast.Await(expression);
  }

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
      var block = body;
      if (block.statements.length == 1) {
        var s = block.statements.single;
        if (s is js_ast.Block) {
          block = s;
          if (block.statements.length == 1) s = block.statements.single;
        }
        if (s is js_ast.Return && s.value != null) body = s.value!;
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
    var init = _visitExpression(v.initializer!);
    var body = _visitExpression(node.body);
    var temp = _tempVariables.remove(v);
    if (temp != null) {
      if (_letVariables != null) {
        init = js_ast.Assignment(temp, init);
        _letVariables!.add(temp);
      } else {
        // TODO(jmesserly): make sure this doesn't happen on any performance
        // critical call path.
        //
        // Annotations on a top-level, non-lazy function type should be the only
        // remaining use.
        var arrowFunction = js_ast.ArrowFun([temp], body);
        final asyncAnalysis = PreTranslationAnalysis((node) {
          throw UnsupportedError('Unknown node in block expression: $node');
        }, arrowFunction)
          ..analyze();
        final isAsyncIife = asyncAnalysis.hasAwaitOrYield.contains(body);
        if (isAsyncIife) {
          final transformedFunction = _rewriteAsyncFunction(
              js_ast.Fun([temp], js_ast.Block([js_ast.Return(body)])),
              AsyncMarker.Async,
              null,
              node.getStaticType(_staticTypeContext),
              functionBody: _toSourceLocation(node.fileOffset),
              functionEnd: _toSourceLocation(node.fileOffset));
          arrowFunction = js_ast.ArrowFun([temp], transformedFunction.body);
        }
        final call = js_ast.Call(arrowFunction, [init]);
        return isAsyncIife ? js_ast.Await(call) : call;
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
    final statementBlock = js_ast.Block(jsStmts);
    var arrowFunction = js_ast.ArrowFun(const [], statementBlock);
    final asyncAnalysis = PreTranslationAnalysis((node) {
      throw UnsupportedError(
          'Unknown node in block expression: $node (${node.runtimeType}, '
          '${node.sourceInformation})');
    }, arrowFunction)
      ..analyze();
    final isAsyncIife = asyncAnalysis.hasAwaitOrYield.contains(statementBlock);
    if (isAsyncIife) {
      final transformedFunction = _rewriteAsyncFunction(
          js_ast.Fun(const [], statementBlock),
          AsyncMarker.Async,
          null,
          node.getStaticType(_staticTypeContext),
          functionBody: _toSourceLocation(node.fileOffset),
          functionEnd: _toSourceLocation(node.fileOffset));
      arrowFunction = js_ast.ArrowFun(const [], transformedFunction.body);
    }
    final call = js_ast.Call(arrowFunction, const []);
    return isAsyncIife ? js_ast.Await(call) : call;
  }

  @override
  js_ast.Expression visitInstantiation(Instantiation node) {
    return _runtimeCall('gbind(#, #)', [
      _visitExpression(node.expression),
      node.typeArguments.map(_emitType).toList()
    ]);
  }

  @override
  js_ast.Expression visitLoadLibrary(LoadLibrary node) =>
      _runtimeCall('loadLibrary(#, #, #)', [
        js.string(node.import.enclosingLibrary.importUri.toString()),
        js.string(node.import.name!),
        js.string(
            _libraryToModule(node.import.targetLibrary, throwIfNotFound: false))
      ]);

  // TODO(jmesserly): DDC loads all libraries eagerly.
  // See
  // https://github.com/dart-lang/sdk/issues/27776
  // https://github.com/dart-lang/sdk/issues/27777
  @override
  js_ast.Expression visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      _runtimeCall('checkDeferredIsLoaded(#, #)', [
        js.string(node.import.enclosingLibrary.importUri.toString()),
        js.string(node.import.name!)
      ]);

  bool _reifyFunctionType(FunctionNode f) {
    var parent = f.parent;
    if (parent is FunctionDeclaration &&
        (isLateLoweredLocalGetter(parent.variable) ||
            isLateLoweredLocalSetter(parent.variable))) {
      // Late local variables are lowered to local get and set functions.
      // These functions should never need to be tagged with their types.
      return false;
    }
    if (!_currentLibrary!.importUri.isScheme('dart')) return true;

    // SDK libraries can skip reification if they request it.
    bool reifyFunctionTypes(Expression a) =>
        isBuiltinAnnotation(a, '_js_helper', 'ReifyFunctionTypes');
    while (parent != null) {
      var a = findAnnotation(parent, reifyFunctionTypes);
      if (a != null) {
        var value = _constants.getFieldValueFromAnnotation(a, 'value');
        if (value is bool) return value;
      }
      parent = parent.parent;
    }
    return true;
  }

  bool _reifyTearoff(Member member) {
    return member is Procedure &&
        !member.isAccessor &&
        !member.isFactory &&
        !(_isInForeignJS && _isBuildingSdk) &&
        !usesJSInterop(member) &&
        _reifyFunctionType(member.function);
  }

  /// Returns the name value of the `JSExportName` annotation (when compiling
  /// the SDK), or `null` if there's none. This is used to control the name
  /// under which functions are compiled and exported.
  String? _jsExportName(NamedNode n) {
    var library = getLibrary(n);
    if (!library.importUri.isScheme('dart')) return null;

    return _annotationName(n, isJSExportNameAnnotation);
  }

  /// If [node] has annotation matching [test] and the first argument is a
  /// string, this returns the string value.
  ///
  /// Calls [findAnnotation] followed by [getNameFromAnnotation].
  String? _annotationName(NamedNode node, bool Function(Expression) test) {
    var annotation = findAnnotation(node, test);
    return annotation != null
        ? _constants.getFieldValueFromAnnotation(annotation, 'name') as String?
        : null;
  }

  @override
  js_ast.Expression visitConstant(Constant node) {
    if (node is StaticTearOffConstant) {
      // JS() or external JS consts should not be lazily loaded.
      var isSdk = node.target.enclosingLibrary.importUri.isScheme('dart');
      if (_isInForeignJS) {
        return _emitStaticTarget(node.target);
      }
      if (node.target.isExternal && !isSdk) {
        return _runtimeCall('tearoffInterop(#, #)', [
          _emitStaticTarget(node.target),
          js.boolean(_isNullCheckableJsInterop(node.target))
        ]);
      }
    }
    if (node is TypeLiteralConstant) {
      // We bypass the use of constants, since types are already canonicalized
      // in the DDC output. DDC emits type literals in two contexts:
      //   * Foreign JS functions: we use the non-nullable version of some types
      //     directly in the runtime libraries (e.g. dart:_runtime). For
      //     correctness of those libraries, we need to remove the legacy marker
      //     that was added by the CFE normalization of type literals.
      //
      //   * Regular user code: we need to emit a canonicalized type. We do so
      //     by calling `wrapType` on the type at runtime. By emitting the
      //     non-nullable version we save some redundant work at runtime.
      //     Technically, emitting a legacy type in this case would be correct,
      //     only more verbose and inefficient.
      var type = node.type;
      if (type.nullability == Nullability.legacy) {
        type = type.withDeclaredNullability(Nullability.nonNullable);
      }
      assert(!_isInForeignJS ||
          type.nullability == Nullability.nonNullable ||
          // The types dynamic, void, and Null all intrinsically have
          // `Nullability.nullable` but are handled explicitly without emitting
          // the nullable runtime wrapper. They are safe to allow through
          // unchanged.
          type == const DynamicType() ||
          type == const NullType() ||
          type == const VoidType());
      return _emitTypeLiteral(type);
    }
    if (node is PrimitiveConstant) {
      return super.visitConstant(node);
    }

    // Avoid caching constants during evaluation while scoping issues remain.
    // See: #44713
    if (_constTableCache.incrementalMode) {
      return super.visitConstant(node);
    }

    var constAlias = _constAliasCache[node];
    if (constAlias != null) {
      return constAlias;
    }
    var constAliasString = 'C${_constAliasCache.length}';
    var constAliasProperty = _propertyName(constAliasString);

    _constTableCache[constAliasString] = js.call('void 0');
    var constAliasAccessor = _constTableCache.access(constAliasString);

    var constAccessor = js.call(
        '# || #.#', [constAliasAccessor, _constTable, constAliasProperty]);
    _constAliasCache[node] = constAccessor;
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
      const minInt32 = -0x80000000;
      const maxInt32 = 0x7FFFFFFF;
      if (intValue.toDouble() == value &&
          intValue >= minInt32 &&
          intValue <= maxInt32) {
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

  // DDC does not currently use the non-primitive constant nodes; rather these
  // are emitted via their normal expression nodes.
  @override
  js_ast.Expression defaultConstant(Constant node) => _emitInvalidNode(node);

  @override
  js_ast.Expression visitSymbolConstant(SymbolConstant node) =>
      _emitDartSymbol(node.name);

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
  js_ast.Expression visitRecordConstant(RecordConstant node) {
    // RecordConstant names are already sorted alphabetically in kernel.
    var names = node.named.keys;
    var positionalElementCount = node.positional.length;
    var shapeKey = _recordShapeKey(positionalElementCount, names);
    return _runtimeCall('recordLiteral(#, #, #, [#])', [
      js.string(shapeKey),
      js.number(positionalElementCount),
      names.isEmpty ? js.call('void 0') : js.stringArray(names),
      [
        ...node.positional.map(visitConstant),
        ...node.named.values.map(visitConstant)
      ]
    ]);
  }

  @override
  js_ast.Expression visitInstanceConstant(InstanceConstant node) {
    var savedTypeEnvironment = _currentTypeEnvironment;
    if (node.classNode.typeParameters.isNotEmpty) {
      _currentTypeEnvironment =
          ClassTypeEnvironment(node.classNode.typeParameters);
    }

    js_ast.Property entryToProperty(MapEntry<Reference, Constant> entry) {
      var constant = visitConstant(entry.value);
      var member = entry.key.asField;
      var cls = member.enclosingClass!;
      // Enums cannot be overridden, so we can safely use the field name
      // directly.  Otherwise, use a private symbol in case the field
      // was overridden.
      var symbol = cls.isEnum
          ? _emitMemberName(member.name.text, member: member)
          : _getSymbol(_emitClassPrivateNameSymbol(
              cls.enclosingLibrary, getLocalClassName(cls), member));
      return js_ast.Property(symbol, constant);
    }

    // Non-nullable is forced here because the type of an instance constant
    // should never appear as legacy "*" at runtime but the library where the
    // constant is defined can cause those types to appear here.
    var type = node
        .getType(_staticTypeContext)
        .withDeclaredNullability(Nullability.nonNullable);
    var classRef = _emitClassRef(type as InterfaceType);
    var prototype = js.call('#.prototype', [classRef]);
    var properties = [
      if (type.typeArguments.isNotEmpty)
        // Generic interface type instances require a type information tag.
        js_ast.Property(
            _propertyName(js_ast.FixedNames.rtiName), _emitType(type)),
      for (var e in node.fieldValues.entries.toList().reversed)
        entryToProperty(e),
    ];
    var constant = _canonicalizeConstObject(_emitJSObjectSetPrototypeOf(
        js_ast.ObjectInitializer(properties, multiline: true), prototype,
        fullyQualifiedName: false));
    _currentTypeEnvironment = savedTypeEnvironment;
    return constant;
  }

  /// Emits a private name JS Symbol for [member] unique to a Dart class
  /// [className].
  ///
  /// This is now required for fields of constant objects that may be overridden
  /// within the same library.
  js_ast.ScopedId _emitClassPrivateNameSymbol(
      Library library, String className, Member member,
      [js_ast.ScopedId? id]) {
    var name = '$className.${member.name.text}';
    // Wrap the name as a symbol here so it matches what you would find at
    // runtime when you get all properties and symbols from an instance.
    memberNames[member] = 'Symbol($name)';
    return _emitPrivateNameSymbol(library, name, id);
  }

  @override
  js_ast.Expression visitStaticTearOffConstant(StaticTearOffConstant node) {
    return _emitStaticGet(node.target);
  }

  @override
  js_ast.Expression visitTypeLiteralConstant(TypeLiteralConstant node) =>
      _emitTypeLiteral(node.type);

  @override
  js_ast.Expression visitInstantiationConstant(InstantiationConstant node) =>
      _canonicalizeConstObject(_runtimeCall('gbind(#, #)', [
        visitConstant(node.tearOffConstant),
        node.types.map(_emitType).toList()
      ]));

  @override
  js_ast.Expression visitUnevaluatedConstant(UnevaluatedConstant node) =>
      throw UnsupportedError('Encountered an unevaluated constant: $node');

  @override
  js_ast.Expression visitFunctionTearOff(FunctionTearOff node) {
    var receiver = node.receiver;
    var receiverType = receiver.getStaticType(_staticTypeContext);
    var jsReceiver = _visitExpression(receiver);
    if (receiverType is InterfaceType &&
        receiverType.classNode == _coreTypes.functionClass) {
      // Historically DDC has treated this case as a dynamic get and allowed it
      // to evaluate at runtime.
      //
      // This is here to preserve the existing behavior for the non-static
      // JavaScript interop (including some failing cases) but could potentially
      // be cleaned up as a breaking change.
      return _runtimeCall(
          'dload$_replSuffix(#, #)', [jsReceiver, js.string('call')]);
    }
    // Otherwise, tearoff of `call` on a function type is a no-op.
    return jsReceiver;
  }

  @override
  js_ast.Statement visitIfCaseStatement(IfCaseStatement node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError('ProgramCompiler.visitIfCaseStatement');
  }

  @override
  js_ast.Expression visitPatternAssignment(PatternAssignment node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError('ProgramCompiler.visitPatternAssignment');
  }

  @override
  js_ast.Statement visitPatternSwitchStatement(PatternSwitchStatement node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError('ProgramCompiler.visitPatternSwitchStatement');
  }

  @override
  js_ast.Statement visitPatternVariableDeclaration(
      PatternVariableDeclaration node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError('ProgramCompiler.visitPatternVariableDeclaration');
  }

  @override
  js_ast.Expression visitSwitchExpression(SwitchExpression node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError('ProgramCompiler.visitSwitchExpression');
  }

  @override
  js_ast.Expression visitAuxiliaryExpression(AuxiliaryExpression node) {
    throw UnsupportedError(
        'Unsupported auxiliary expression $node (${node.runtimeType}).');
  }

  @override
  js_ast.Statement visitAuxiliaryStatement(AuxiliaryStatement node) {
    throw UnsupportedError(
        'Unsupported auxiliary statement $node (${node.runtimeType}).');
  }

  void _setEmitIfIncrementalLibrary(Library library) {
    if (_incrementalMode) {
      _setEmitIfIncremental(_libraryToModule(library), _jsLibraryName(library));
    }
  }

  void _setEmitIfIncremental(String module, String library) {
    if (_incrementalMode) {
      _incrementalModules.putIfAbsent(module, () => {}).add(library);
    }
  }

  /// When compiling the body of a `operator []=` method, this will be non-null
  /// and will indicate the value that should be returned from any `return;`
  /// statements.
  js_ast.Identifier? get _operatorSetResult {
    var stack = _operatorSetResultStack;
    return stack.isEmpty ? null : stack.last;
  }

  /// Called when starting to emit methods/functions, in particular so we can
  /// implement special handling of the user-defined `[]=` and `==` methods.
  ///
  /// See also [_exitFunction] and [_emitReturnStatement].
  void _enterFunction(String? name, List<js_ast.Parameter> formals,
      bool Function() isLastParamMutated) {
    if (name == '[]=') {
      _operatorSetResultStack.add(isLastParamMutated()
          ? js_ast.ScopedId((formals.last as js_ast.Identifier).name)
          : formals.last as js_ast.Identifier);
    } else {
      _operatorSetResultStack.add(null);
    }
  }

  /// Called when finished emitting methods/functions, and must correspond to a
  /// previous [_enterFunction] call.
  js_ast.Block _exitFunction(
      List<js_ast.Parameter> formals, js_ast.Block code) {
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
  js_ast.Statement _emitReturnStatement(js_ast.Expression? value) {
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
  ///     _runtimeCall('asInt(#)', [<expr>])
  ///
  /// Generates a JS AST representing:
  ///
  ///     dart.asInt(<expr>)
  ///
  js_ast.Expression _runtimeCall(String code, [List<Object>? args]) {
    return js
        .call('#.$code', <Object>[_emitLibraryName(_runtimeLibrary), ...?args]);
  }

  /// Calls [_runtimeCall] and uses `toStatement()` to convert the resulting
  /// expression into a statement.
  js_ast.Statement _runtimeStatement(String code, [List<Object>? args]) =>
      _runtimeCall(code, args).toStatement();

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
  js_ast.ScopedId _emitPrivateNameSymbol(Library library, String name,
      [js_ast.ScopedId? id]) {
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
    js_ast.ScopedId initPrivateNameSymbol() {
      var idName = name.endsWith('=') ? name.replaceAll('=', '_') : name;
      idName = idName.replaceAll(js_ast.invalidCharInIdentifier, '_');
      var identifier = id ?? js_ast.ScopedId(idName);
      _addSymbol(
          identifier,
          _runtimeCall('privateName(#, #)',
              [js.string('${library.importUri}'), js.string(name)]));
      if (!_containerizeSymbols) {
        // TODO(vsm): Change back to `const`.
        // See https://github.com/dart-lang/sdk/issues/40380.
        _moduleItems.add(js.statement('var # = #', [
          identifier,
          _runtimeCall('privateName(#, #)',
              [js.string('${library.importUri}'), js.string(name)])
        ]));
      }
      return identifier;
    }

    var privateNames = _privateNames.putIfAbsent(library, () => HashMap());
    var symbolId = privateNames.putIfAbsent(name, initPrivateNameSymbol);

    _setEmitIfIncrementalLibrary(library);
    _setEmitIfIncremental(
        _libraryToModule(_coreLibrary), _runtimeLibraryId.name);
    _symbolContainer.setEmitIfIncremental(symbolId);

    return symbolId;
  }

  /// Emits an expression to set the property [nameExpr] on the class [className],
  /// with [value].
  ///
  /// This will use `className.name = value` if possible, otherwise it will use
  /// `dart.defineValue(className, name, value)`. This is required when
  /// `FunctionNode.prototype` already defines a getters with the same name.
  js_ast.Expression _defineValueOnClass(Class c, js_ast.Expression className,
      js_ast.Expression nameExpr, js_ast.Expression value) {
    var args = [className, nameExpr, value];
    if (nameExpr is js_ast.LiteralString) {
      var name = nameExpr.valueWithoutQuotes;
      if (js_ast.isFunctionPrototypeGetter(name) ||
          _superclassHasStatic(c, name)) {
        return _runtimeCall('defineValue(#, #, #)', args);
      }
    }
    return js.call('#.# = #', args);
  }

  /// Emits a Dart Symbol with the given member [symbolName].
  ///
  /// If the symbol refers to a private name, its library will be set to the
  /// [currentLibrary], so the Symbol is scoped properly.
  js_ast.Expression _emitDartSymbol(String symbolName) {
    // TODO(vsm): Handle qualified symbols correctly.
    var last = symbolName.split('.').last;
    var name = js.escapedString(symbolName, "'");
    js_ast.Expression result;
    if (last.startsWith('_')) {
      var nativeSymbolAccessor =
          _getSymbol(_emitPrivateNameSymbol(_currentLibrary!, last));
      result = js.call('new #.new(#, #)', [
        _emitConstructorAccess(_privateSymbolType),
        name,
        nativeSymbolAccessor
      ]);
    } else {
      result = js.call(
          'new #.new(#)', [_emitConstructorAccess(_internalSymbolType), name]);
    }
    return _canonicalizeConstObject(result);
  }

  /// Calls the `dart.const` function in "dart:_runtime" to canonicalize a
  /// constant instance of a user-defined class stored in [expr].
  js_ast.Expression _canonicalizeConstObject(js_ast.Expression expr) =>
      _runtimeCall('const(#)', [expr]);

  /// Emits preamble for the module containing [libraries], and returns the
  /// list of module items for further items to be added.
  ///
  /// The preamble consists of initializing the identifiers for each library,
  /// that will be used to store their members. It also generates the
  /// appropriate ES6 `export` declaration to export them from this module.
  ///
  /// After the code for all of the library members is emitted,
  /// [_emitImportsAndExtensionSymbols] should be used to emit imports/extension
  /// symbols into the list returned by this method. Finally, [_finishLibrary]
  /// can be called to complete the module and return the resulting JS AST.
  ///
  /// This also initializes several fields: [_runtimeLibraryId],
  /// [_extensionSymbolsLibraryId], and the [_libraries] map needed by
  /// [_emitLibraryName].
  List<js_ast.ModuleItem> _startLibrary(Library library) {
    if (_isSdkInternalRuntime(library)) {
      // Don't allow these to be renamed when we're building the SDK.
      // There is JS code in dart:* that depends on their names.
      _runtimeLibraryId = js_ast.Identifier('dart');
      _extensionSymbolsLibraryId =
          js_ast.Identifier(_extensionSymbolHolderName);
    } else {
      // Otherwise allow these to be renamed so users can write them.
      _runtimeLibraryId = js_ast.ScopedId('dart');
      _extensionSymbolsLibraryId = js_ast.ScopedId(_extensionSymbolHolderName);
    }

    // Initialize our library variables.
    var items = <js_ast.ModuleItem>[];
    var exports = <js_ast.NameSpecifier>[];
    if (_isSdkInternalRuntime(library)) {
      _libraries[library] = _runtimeLibraryId;
    } else {
      var libraryId = _isBuildingSdk && _isDartLibrary(library, '_rti')
          ? _rtiLibraryId
          : js_ast.ScopedId(_jsLibraryName(library));

      _libraries[library] = libraryId;
      var alias = _jsLibraryAlias(library);
      var aliasId = alias == null ? null : js_ast.ScopedId(alias);
      exports.add(js_ast.NameSpecifier(libraryId, asName: aliasId));
    }
    items.add(js_ast.ExportDeclaration(js_ast.ExportClause(exports)));

    if (_isSdkInternalRuntime(library)) {
      // Initialize the private name function.
      // To bootstrap the SDK, this needs to be emitted before other code.
      var privateNamesId = _emitScopedId('privateNames');
      items.add(js.statement('const # = new Map()', privateNamesId));
      items.add(_runtimeStatement(r'''
        privateName = function privateName(libraryUri, name) {
          let names = #.get(libraryUri);
          if (names == null) #.set(libraryUri, names = new Map());
          let symbol = names.get(name);
          if (symbol == null) names.set(name, symbol = Symbol(name));
          return symbol;
        }
      ''', [privateNamesId, privateNamesId]));
    }

    return items;
  }

  /// Returns the canonical name to refer to the Dart library.
  js_ast.Identifier _emitLibraryName(Library library) {
    _setEmitIfIncrementalLibrary(library);

    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(library, () {
          if (_isSdkInternalRuntime(library)) return _runtimeLibraryId;
          if (_isDartLibrary(library, '_rti')) return _rtiLibraryId;
          return js_ast.ScopedId(_jsLibraryName(library));
        });
  }

  /// Emits imports into [items].
  void _emitImports(List<js_ast.ModuleItem> items) {
    var modules = <String, List<Library>>{};
    for (var import in _imports.keys) {
      modules.putIfAbsent(_libraryToModule(import), () => []).add(import);
    }
    // TODO(nshahan): Update this code and the representation of
    // `ImportDeclaration`s when other module formats are no longer supported.
    modules.forEach((module, libraries) {
      if (!_incrementalMode || _incrementalModules.containsKey(module)) {
        var usedLibraries = _incrementalModules[module];

        // Generate import directives.
        //
        // Our import variables are temps and can get renamed. Since our renaming
        // is integrated into js_ast, it is aware of this possibility and will
        // generate an "as" if needed. For example:
        //
        //     import {foo} from 'foo';         // if no rename needed
        //     import {foo as foo$} from 'foo'; // if rename was needed
        //
        for (var library in libraries) {
          if (!_incrementalMode ||
              usedLibraries!.contains(_jsLibraryName(library))) {
            var alias = _jsLibraryAlias(library);
            if (alias != null) {
              var aliasId = js_ast.ScopedId(alias);
              items.add(js_ast.ImportDeclaration(
                  from: js.string('${library.importUri}'),
                  namedImports: [
                    js_ast.NameSpecifier(aliasId, asName: _imports[library])
                  ]));
            } else {
              items.add(js_ast.ImportDeclaration(
                  from: js.string('${library.importUri}'),
                  namedImports: [js_ast.NameSpecifier(_imports[library])]));
            }
          }
        }
      }
    });
    items.add(js_ast.ImportDeclaration(
        from: js.string(_extensionSymbolHolderName),
        namedImports: [js_ast.NameSpecifier(_extensionSymbolsLibraryId)]));
  }

  /// Emits extension methods into [items].
  void _emitExtensionSymbols(List<js_ast.ModuleItem> items,
      {bool forceExtensionSymbols = false}) {
    // Initialize extension symbols
    _extensionSymbols.forEach((name, id) {
      js_ast.Expression value = js_ast.PropertyAccess(
          _extensionSymbolsLibraryId, _propertyName(name));
      if (forceExtensionSymbols) {
        value = js.call('# || (# = Symbol(#))',
            [value, value, js.string('$_extensionSymbolHolderName.$name')]);
      }
      // Emit hoisted extension symbols that are marked as noEmit in regular as
      // well as incremental mode (if needed) since they are going to be
      // referenced as such in the generated expression.
      if (!_incrementalMode ||
          _symbolContainer.incrementalModuleItems.contains(id)) {
        if (!_symbolContainer.canEmit(id)) {
          // Extension symbols marked with noEmit are managed manually.
          // TODO(vsm): Change back to `const`.
          // See https://github.com/dart-lang/sdk/issues/40380.
          items.add(js.statement('var # = #;', [id, value]));
        }
      }
      if (_symbolContainer.incrementalModuleItems.contains(id)) {
        _setEmitIfIncremental(
            _libraryToModule(_coreLibrary), _extensionSymbolsLibraryId.name);
      }
      _symbolContainer[id] = value;
    });
  }

  /// Emits exports as imports into [items].
  ///
  /// Use information from exports to re-define library variables referenced
  /// inside compiled expressions in incremental mode. That matches importing
  /// a current module into the symbol used to represent the library during
  /// original compilation in [emitLibrary].
  ///
  /// Example of exports emitted to JavaScript during emitModule:
  ///
  /// ```
  /// dart.trackLibraries("web/main", { ... });
  /// // Exports:
  /// return {
  ///  web__main: main
  /// };
  /// ```
  ///
  /// The transformation to imports during expression compilation converts the
  /// exports above to:
  ///
  /// ```
  /// const web__main = require('web/main');
  /// const main = web__main.web__main;
  /// ```
  ///
  /// Where the compiled expression references `main`.
  void _emitExportsAsImports(List<js_ast.ModuleItem> items, Library current) {
    var exports = <js_ast.NameSpecifier>[];
    assert(_incrementalMode);
    assert(!_isBuildingSdk);

    var module = _libraryToModule(current);
    var usedLibraries = _incrementalModules[module] ?? {};

    if (usedLibraries.isNotEmpty) {
      _libraries.forEach((library, libraryId) {
        if (usedLibraries.contains(_jsLibraryName(library))) {
          var alias = _jsLibraryAlias(library);
          var aliasId = alias == null ? libraryId : js_ast.ScopedId(alias);
          var asName = alias == null ? null : libraryId;
          exports.add(js_ast.NameSpecifier(aliasId, asName: asName));
        }
      });

      items.add(js_ast.ImportDeclaration(
          namedImports: exports,
          from: js.string(current.importUri.toString(), "'")));
    }
  }

  /// Emits imports and extension methods into [items].
  void _emitImportsAndExtensionSymbols(List<js_ast.ModuleItem> items,
      {bool forceExtensionSymbols = false}) {
    _emitImports(items);
    _emitExtensionSymbols(items, forceExtensionSymbols: forceExtensionSymbols);
  }

  void _emitDebuggerExtensionInfo(String name) {
    var properties = <js_ast.Property>[];
    var parts = <js_ast.Property>[];
    _libraries.forEach((library, value) {
      // TODO(jacobr): we could specify a short library name instead of the
      // full library uri if we wanted to save space.
      var libraryName = js.escapedString(_jsLibraryDebuggerName(library));
      properties.add(js_ast.Property(libraryName, value));

      // Dynamic modules shouldn't define a library that was previously defined.
      // We leverage that we track which libraries have been defined via
      // `trackedLibraries` to query whether a library already exists.
      // TODO(sigmund): enable when `trackLibraries()` is added again.
      //if (_options.dynamicModule) {
      //  _moduleItems.add(js.statement('''if (# != null) {
      //          throw Error(
      //              "Dynamic module provides second definition for " + #);
      //      }''', [
      //    _runtimeCall('getLibrary(#)', [libraryName]),
      //    libraryName
      //  ]));
      //}

      var partNames = _jsPartDebuggerNames(library);
      if (partNames.isNotEmpty) {
        parts.add(js_ast.Property(libraryName, js.stringArray(partNames)));
      }
    });
    // TODO(nshahan) Update `trackLibraries()` in dart:_runtime to support this
    // new module format.
    // var module = js_ast.ObjectInitializer(properties, multiline: true);
    // var partMap = js_ast.ObjectInitializer(parts, multiline: true);

    // Track the module name for each library in the module.
    // This data is mainly consumed by the debugger and by the stack trace
    // mapper. It is also used for the experimental dynamic modules feature
    // to validate that a dynamic module doesn't reintroduce an existing
    // library.
    //
    // See also the implementation of this API in the SDK.
    //   _moduleItems.add(_runtimeStatement(
    //       'trackLibraries(#, #, #, $sourceMapLocationID)',
    //       [js.string(name), module, partMap]));
  }

  /// Returns an accessor for [id] via the symbol container.
  /// E.g., transforms $sym to S$5.$sym.
  ///
  /// A symbol lookup on an id marked no emit omits the symbol accessor.
  js_ast.Expression _getSymbol(js_ast.Identifier id) {
    _symbolContainer.setEmitIfIncremental(id);
    return _symbolContainer.canEmit(id) ? _symbolContainer.access(id) : id;
  }

  /// Returns the raw JS value associated with [id].
  js_ast.Expression _getSymbolValue(js_ast.Identifier id) {
    _symbolContainer.setEmitIfIncremental(id);
    return _symbolContainer[id]!;
  }

  /// Inserts a symbol into the symbol table.
  js_ast.Expression _addSymbol(js_ast.Identifier id, js_ast.Expression symbol) {
    _symbolContainer[id] = symbol;
    _symbolContainer.setEmitIfIncremental(id);
    if (!_containerizeSymbols) {
      _symbolContainer.setNoEmit(id);
    }
    return _symbolContainer[id]!;
  }

  /// Finishes the module created by [_startLibrary], by combining the preamble
  /// [items] with the [_moduleItems] that have been emitted.
  ///
  /// The [moduleName] should specify the module's name, and the items should
  /// be the list resulting from [_startLibrary], with additional items added,
  /// but not including the contents of [_moduleItems] (which will be handled
  /// by this method itself).
  ///
  /// Note, this function mutates the items list and returns it as the `body`
  /// field of the result.
  js_ast.Program _finishLibrary(List<js_ast.ModuleItem> items,
      String moduleName, js_ast.Identifier libraryId) {
    // TODO(jmesserly): there's probably further consolidation we can do
    // between DDC's two backends, by moving more code into this method, as the
    // code between `_startLibrary` and `_finishLibrary` is very similar in both.
    _emitDebuggerExtensionInfo(moduleName);

    // Emit all top-level JS symbol containers.
    items.addAll(_symbolContainer.emit());

    if (_dynamicEntrypoint != null) {
      // Expose the entrypoint of the dynamic module under a reserved name.
      // TODO(sigmund): this could use a reserved symbol from dartx.
      var name = _emitTopLevelName(_dynamicEntrypoint!);
      _moduleItems.add(js_ast.ExportDeclaration(
          js('var __dynamic_module_entrypoint__ = #', [name])));
    }

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, _moduleItems);
    _moduleItems.clear();

    // Build the module.
    return js_ast.Program(items, name: moduleName, librarySelfVar: libraryId);
  }

  /// Flattens blocks in [items] to a single list.
  ///
  /// This will not flatten blocks that are marked as being scopes.
  void _copyAndFlattenBlocks(
      List<js_ast.ModuleItem> result, Iterable<js_ast.ModuleItem> items) {
    for (var item in items) {
      if (item is js_ast.Block && !item.isScope) {
        _copyAndFlattenBlocks(result, item.statements);
      } else {
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
  js_ast.ScopedId _getExtensionSymbolInternal(String name) {
    if (!_extensionSymbols.containsKey(name)) {
      var id = js_ast.ScopedId(
          '\$${js_ast.friendlyNameForDartOperator[name] ?? name}');
      _extensionSymbols[name] = id;
      _addSymbol(id, id);
    }
    var symbolId = _extensionSymbols[name]!;
    _symbolContainer.setEmitIfIncremental(symbolId);
    return symbolId;
  }

  /// Shorthand for identifier-like property names.
  /// For now, we emit them as strings and the printer restores them to
  /// identifiers if it can.
  // TODO(jmesserly): avoid the round tripping through quoted form.
  js_ast.LiteralString _propertyName(String name) => js.string(name, "'");

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

bool _isInlineJSFunction(Statement? body) {
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

bool _isObjectGetter(String name) =>
    name == 'hashCode' || name == 'runtimeType';

bool _isObjectMethodTearoff(String name) =>
    // "==" isn't in here because there is no syntax to tear it off.
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

/// Whether [expression] is a constant of the form
/// `const pragma('dyn-module:entry-point')`.
///
/// Used to denote the entrypoint method of a dynamic module.
bool _isEntrypointPragma(Expression expression, CoreTypes coreTypes) {
  if (expression is! ConstantExpression) return false;
  final value = expression.constant;
  if (value is! InstanceConstant) return false;
  if (value.classReference != coreTypes.pragmaClass.reference) return false;
  final name = value.fieldValues[coreTypes.pragmaName.fieldReference];
  if (name is! StringConstant) return false;
  return name.value == 'dyn-module:entry-point';
}
