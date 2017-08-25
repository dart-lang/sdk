// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show min, max;

import 'package:analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart' show StringToken;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart'
    show TypeProvider, NamespaceBuilder;
import 'package:analyzer/src/generated/type_system.dart'
    show StrongTypeSystemImpl;
import 'package:analyzer/src/summary/idl.dart' show UnlinkedUnit;
import 'package:analyzer/src/summary/link.dart' as summary_link;
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart'
    show serializeAstUnlinked;
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/strong/ast_properties.dart';
import 'package:path/path.dart' show isWithin, relative, separator;

import '../closure/closure_annotator.dart' show ClosureAnnotator;
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import 'ast_builder.dart' show AstBuilder;
import 'compiler.dart' show BuildUnit, CompilerOptions, JSModuleFile;
import 'element_helpers.dart';
import 'extension_types.dart' show ExtensionTypeSet;
import 'js_interop.dart';
import 'js_metalet.dart' as JS;
import 'js_names.dart' as JS;
import 'js_typeref_codegen.dart' show JsTypeRefCodegen;
import 'js_typerep.dart' show JSTypeRep, JSType;
import 'module_builder.dart' show pathToJSIdentifier;
import 'nullable_type_inference.dart' show NullableTypeInference;
import 'property_model.dart';
import 'reify_coercions.dart' show CoercionReifier;
import 'side_effect_analysis.dart' show ConstFieldVisitor, isStateless;
import 'type_utilities.dart';

/// The code generator for Dart Dev Compiler.
///
/// Takes as input resolved Dart ASTs for every compilation unit in every
/// library in the module. Produces a single JavaScript AST for the module as
// output, along with its source map.
///
/// This class attempts to preserve identifier names and structure of the input
/// Dart code, whenever this is possible to do in the generated code.
///
// TODO(jmesserly): we should use separate visitors for statements and
// expressions. Declarations are handled directly, and many minor component
// AST nodes aren't visited, so the visitor pattern isn't helping except for
// expressions (which result in JS.Expression) and statements
// (which result in (JS.Statement).
class CodeGenerator extends Object
    with ClosureAnnotator, JsTypeRefCodegen, NullableTypeInference
    implements AstVisitor<JS.Node> {
  final AnalysisContext context;
  final SummaryDataStore summaryData;

  final CompilerOptions options;
  final StrongTypeSystemImpl rules;
  JSTypeRep typeRep;

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  ///
  /// We sometimes special case codegen for a single library, as it simplifies
  /// name scoping requirements.
  final _libraries = new Map<LibraryElement, JS.Identifier>();

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = new Map<LibraryElement, JS.TemporaryId>();

  /// The list of dart:_runtime SDK functions; these are assumed by other code
  /// in the SDK to be generated before anything else.
  final _internalSdkFunctions = <JS.ModuleItem>[];

  /// The list of output module items, in the order they need to be emitted in.
  final _moduleItems = <JS.ModuleItem>[];

  /// Table of named and possibly hoisted types.
  TypeTable _typeTable;

  /// The global extension type table.
  final ExtensionTypeSet _extensionTypes;

  /// The variable for the target of the current `..` cascade expression.
  ///
  /// Usually a [SimpleIdentifier], but it can also be other expressions
  /// that are safe to evaluate multiple times, such as `this`.
  Expression _cascadeTarget;

  /// The variable for the current catch clause
  SimpleIdentifier _catchParameter;

  /// In an async* function, this represents the stream controller parameter.
  JS.TemporaryId _asyncStarController;

  // TODO(jmesserly): fuse this with notNull check.
  final _privateNames =
      new HashMap<LibraryElement, HashMap<String, JS.TemporaryId>>();
  final _initializingFormalTemps =
      new HashMap<ParameterElement, JS.TemporaryId>();

  JS.Identifier _extensionSymbolsModule;
  JS.Identifier _runtimeModule;
  final namedArgumentTemp = new JS.TemporaryId('opts');

  final _hasDeferredSupertype = new HashSet<ClassElement>();

  /// The  type provider from the current Analysis [context].
  final TypeProvider types;

  final LibraryElement dartCoreLibrary;
  final LibraryElement dartJSLibrary;

  /// The dart:async `StreamIterator<>` type.
  final InterfaceType _asyncStreamIterator;

  /// The dart:core `identical` element.
  final FunctionElement _coreIdentical;

  /// The dart:_interceptors implementation elements.
  final ClassElement _jsArray;
  final ClassElement _jsBool;
  final ClassElement _jsNumber;
  final ClassElement _jsString;

  final ClassElement boolClass;
  final ClassElement intClass;
  final ClassElement doubleClass;
  final ClassElement interceptorClass;
  final ClassElement nullClass;
  final ClassElement numClass;
  final ClassElement objectClass;
  final ClassElement stringClass;
  final ClassElement functionClass;
  final ClassElement privateSymbolClass;

  ConstFieldVisitor _constants;

  /// The current function body being compiled.
  FunctionBody _currentFunction;

  HashMap<TypeDefiningElement, AstNode> _declarationNodes;

  /// The stack of currently emitting elements, if generating top-level code
  /// for them. This is not used when inside method bodies, because order does
  /// not matter for those.
  final _topLevelElements = <TypeDefiningElement>[];

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentElements.last == _topLevelElements.last
  //
  // TODO(jmesserly): ideally we'd only track types here, in other words,
  // TypeDefiningElement. However we still rely on this for [currentLibrary] so
  // we need something to be pushed always.
  final _currentElements = <Element>[];

  final _deferredProperties = new HashMap<PropertyAccessorElement, JS.Method>();

  BuildUnit _buildUnit;

  String _libraryRoot;

  bool _superAllowed = true;

  final _superHelpers = new Map<String, JS.Method>();

  List<TypeParameterType> _typeParamInConst;

  /// Whether we are currently generating code for the body of a `JS()` call.
  bool _isInForeignJS = false;

  /// Information about virtual and overridden fields/getters/setters in the
  /// class we're currently compiling, or `null` if we aren't compiling a class.
  ClassPropertyModel _classProperties;

  /// Information about virtual fields for all libraries in the current build
  /// unit.
  final virtualFields = new VirtualFieldModel();

  final _usedCovariantPrivateMembers = new HashSet<ExecutableElement>();

  CodeGenerator(
      AnalysisContext c, this.summaryData, this.options, this._extensionTypes)
      : context = c,
        rules = new StrongTypeSystemImpl(c.typeProvider),
        types = c.typeProvider,
        _asyncStreamIterator =
            _getLibrary(c, 'dart:async').getType('StreamIterator').type,
        _coreIdentical =
            _getLibrary(c, 'dart:core').publicNamespace.get('identical'),
        _jsArray = _getLibrary(c, 'dart:_interceptors').getType('JSArray'),
        _jsBool = _getLibrary(c, 'dart:_interceptors').getType('JSBool'),
        _jsString = _getLibrary(c, 'dart:_interceptors').getType('JSString'),
        _jsNumber = _getLibrary(c, 'dart:_interceptors').getType('JSNumber'),
        interceptorClass =
            _getLibrary(c, 'dart:_interceptors').getType('Interceptor'),
        dartCoreLibrary = _getLibrary(c, 'dart:core'),
        boolClass = _getLibrary(c, 'dart:core').getType('bool'),
        intClass = _getLibrary(c, 'dart:core').getType('int'),
        doubleClass = _getLibrary(c, 'dart:core').getType('double'),
        numClass = _getLibrary(c, 'dart:core').getType('num'),
        nullClass = _getLibrary(c, 'dart:core').getType('Null'),
        objectClass = _getLibrary(c, 'dart:core').getType('Object'),
        stringClass = _getLibrary(c, 'dart:core').getType('String'),
        functionClass = _getLibrary(c, 'dart:core').getType('Function'),
        privateSymbolClass =
            _getLibrary(c, 'dart:_internal').getType('PrivateSymbol'),
        dartJSLibrary = _getLibrary(c, 'dart:js') {
    typeRep = new JSTypeRep(rules, types);
  }

  Element get currentElement => _currentElements.last;

  LibraryElement get currentLibrary => currentElement.library;

  /// The main entry point to JavaScript code generation.
  ///
  /// Takes the metadata for the build unit, as well as resolved trees and
  /// errors, and computes the output module code and optionally the source map.
  JSModuleFile compile(BuildUnit unit, List<CompilationUnit> compilationUnits,
      List<String> errors) {
    _buildUnit = unit;
    _libraryRoot = _buildUnit.libraryRoot;
    if (!_libraryRoot.endsWith(separator)) {
      _libraryRoot += separator;
    }

    var module = _emitModule(compilationUnits, unit.name);
    var dartApiSummary = _summarizeModule(compilationUnits);

    return new JSModuleFile(unit.name, errors, options, module, dartApiSummary);
  }

  List<int> _summarizeModule(List<CompilationUnit> units) {
    if (!options.summarizeApi) return null;

    if (!units.any((u) => resolutionMap
        .elementDeclaredByCompilationUnit(u)
        .librarySource
        .isInSystemLibrary)) {
      var sdk = context.sourceFactory.dartSdk;
      summaryData.addBundle(
          null,
          sdk is SummaryBasedDartSdk
              ? sdk.bundle
              : (sdk as FolderBasedDartSdk).getSummarySdkBundle(true));
    }

    var assembler = new PackageBundleAssembler();

    var uriToUnit = new Map<String, UnlinkedUnit>.fromIterable(units,
        key: (u) => u.element.source.uri.toString(),
        value: (unit) {
          var unlinked = serializeAstUnlinked(unit);
          assembler.addUnlinkedUnit(unit.element.source, unlinked);
          return unlinked;
        });

    summary_link
        .link(
            uriToUnit.keys.toSet(),
            (uri) => summaryData.linkedMap[uri],
            (uri) => summaryData.unlinkedMap[uri] ?? uriToUnit[uri],
            context.declaredVariables.get,
            true)
        .forEach(assembler.addLinkedLibrary);

    var bundle = assembler.assemble();
    // Preserve only API-level information in the summary.
    bundle.flushInformative();
    return bundle.toBuffer();
  }

  JS.Program _emitModule(List<CompilationUnit> compilationUnits, String name) {
    if (_moduleItems.isNotEmpty) {
      throw new StateError('Can only call emitModule once.');
    }

    for (var unit in compilationUnits) {
      _usedCovariantPrivateMembers.addAll(getCovariantPrivateMembers(unit));
    }

    // Transform the AST to make coercions explicit.
    compilationUnits = CoercionReifier.reify(compilationUnits);

    if (compilationUnits.any((u) => isSdkInternalRuntime(
        resolutionMap.elementDeclaredByCompilationUnit(u).library))) {
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
    for (var unit in compilationUnits) {
      var library =
          resolutionMap.elementDeclaredByCompilationUnit(unit).library;
      if (unit.element != library.definingCompilationUnit) continue;

      var libraryTemp = isSdkInternalRuntime(library)
          ? _runtimeModule
          : new JS.TemporaryId(jsLibraryName(_libraryRoot, library));
      _libraries[library] = libraryTemp;
      items.add(new JS.ExportDeclaration(
          js.call('const # = Object.create(null)', [libraryTemp])));

      // dart:_runtime has a magic module that holds extension method symbols.
      // TODO(jmesserly): find a cleaner design for this.
      if (isSdkInternalRuntime(library)) {
        items.add(new JS.ExportDeclaration(js
            .call('const # = Object.create(null)', [_extensionSymbolsModule])));
      }
    }

    // Collect all class/type Element -> Node mappings
    // in case we need to forward declare any classes.
    _declarationNodes = new HashMap<TypeDefiningElement, AstNode>.identity();
    for (var unit in compilationUnits) {
      for (var declaration in unit.declarations) {
        var element = declaration.element;
        if (element is TypeDefiningElement) {
          _declarationNodes[element] = declaration;
        }
      }
    }
    if (compilationUnits.isNotEmpty) {
      _constants = new ConstFieldVisitor(context,
          dummySource: resolutionMap
              .elementDeclaredByCompilationUnit(compilationUnits.first)
              .source);
    }

    // Add implicit dart:core dependency so it is first.
    emitLibraryName(dartCoreLibrary);

    // Visit each compilation unit and emit its code.
    //
    // NOTE: declarations are not necessarily emitted in this order.
    // Order will be changed as needed so the resulting code can execute.
    // This is done by forward declaring items.
    compilationUnits.forEach(visitCompilationUnit);
    assert(_deferredProperties.isEmpty);

    // Visit directives (for exports)
    compilationUnits.forEach(_emitExportDirectives);

    // Declare imports
    _finishImports(items);

    // Discharge the type table cache variables and
    // hoisted definitions.
    items.addAll(_typeTable.discharge());
    items.addAll(_internalSdkFunctions);

    // Track the module name for each library in the module.
    // This data is only required for debugging.
    _moduleItems.add(js.statement(
        '#.trackLibraries(#, #, ${JSModuleFile.sourceMapHoleID});',
        [_runtimeModule, js.string(name), _librariesDebuggerObject()]));

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, _moduleItems);

    // Build the module.
    return new JS.Program(items, name: _buildUnit.name);
  }

  JS.ObjectInitializer _librariesDebuggerObject() {
    var properties = <JS.Property>[];
    _libraries.forEach((library, value) {
      // TODO(jacobr): we could specify a short library name instead of the
      // full library uri if we wanted to save space.
      properties.add(new JS.Property(
          js.string(jsLibraryDebuggerName(_libraryRoot, library)), value));
    });
    return new JS.ObjectInitializer(properties, multiline: true);
  }

  /// If [e] is a property accessor element, this returns the
  /// (possibly synthetic) field that corresponds to it, otherwise returns [e].
  Element _getNonAccessorElement(Element e) =>
      e is PropertyAccessorElement ? e.variable : e;

  /// Returns the name of [e] but removes trailing `=` from setter names.
  // TODO(jmesserly): it would be nice if Analyzer had something like this.
  // `Element.displayName` is close, but it also normalizes operator names in
  // a way we don't want.
  String _getElementName(Element e) => _getNonAccessorElement(e).name;

  bool _isExternal(Element e) =>
      e is ExecutableElement && e.isExternal ||
      e is PropertyInducingElement &&
          (e.getter.isExternal || e.setter.isExternal);

  bool _isJSElement(Element e) =>
      e?.library != null &&
      _isJSNative(e.library) &&
      (_isExternal(e) || e is ClassElement && _isJSNative(e));

  String _getJSNameWithoutGlobal(Element e) {
    if (!_isJSElement(e)) return null;
    var libraryJSName = getAnnotationName(e.library, isPublicJSAnnotation);
    var jsName =
        getAnnotationName(e, isPublicJSAnnotation) ?? _getElementName(e);
    return libraryJSName != null ? '$libraryJSName.$jsName' : jsName;
  }

  JS.Expression _emitJSInterop(Element e) {
    var jsName = _getJSNameWithoutGlobal(e);
    return jsName != null ? _emitJSInteropForGlobal(jsName) : null;
  }

  JS.Expression _emitJSInteropForGlobal(String name) {
    var access = _callHelper('global');
    for (var part in name.split('.')) {
      access = new JS.PropertyAccess(access, js.escapedString(part, "'"));
    }
    return access;
  }

  JS.Expression _emitJSInteropStaticMemberName(Element e) {
    if (!_isJSElement(e)) return null;
    var name = getAnnotationName(e, isPublicJSAnnotation);
    if (name != null) {
      if (name.contains('.')) {
        throw new UnsupportedError(
            'static members do not support "." in their names. '
            'See https://github.com/dart-lang/sdk/issues/27926');
      }
    } else {
      name = _getElementName(e);
    }
    return js.escapedString(name, "'");
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

  String _libraryToModule(LibraryElement library) {
    assert(!_libraries.containsKey(library));
    var source = library.source;
    // TODO(jmesserly): we need to split out HTML.
    if (source.uri.scheme == 'dart') {
      return JS.dartSdkModule;
    }
    var moduleName = _buildUnit.libraryToModule(source);
    if (moduleName == null) {
      throw new StateError('Could not find module containing "$library".');
    }
    return moduleName;
  }

  void _finishImports(List<JS.ModuleItem> items) {
    var modules = new Map<String, List<LibraryElement>>();

    for (var import in _imports.keys) {
      modules.putIfAbsent(_libraryToModule(import), () => []).add(import);
    }

    String coreModuleName;
    if (!_libraries.containsKey(dartCoreLibrary)) {
      coreModuleName = _libraryToModule(dartCoreLibrary);
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

  /// Called to emit all top-level declarations.
  ///
  /// During the course of emitting one item, we may emit another. For example
  ///
  ///     class D extends B { C m() { ... } }
  ///
  /// Because D depends on B, we'll emit B first if needed. However C is not
  /// used by top-level JavaScript code, so we can ignore that dependency.
  void _emitTypeDeclaration(TypeDefiningElement e) {
    var node = _declarationNodes.remove(e);
    if (node == null) return null; // not from this module or already loaded.

    _currentElements.add(e);

    // TODO(jmesserly): this is not really the right place for this.
    // Ideally we do this per function body.
    //
    // We'll need to be consistent about when we're generating functions, and
    // only run this on the outermost function, and not any closures.
    inferNullableTypes(node);

    _moduleItems.add(_visit(node));

    var last = _currentElements.removeLast();
    assert(identical(e, last));
  }

  /// Start generating top-level code for the element [e].
  ///
  /// Subsequent [emitDeclaration] calls will cause those elements to be
  /// generated before this one, until [finishTopLevel] is called.
  void _startTopLevelCodeForClass(TypeDefiningElement e) {
    assert(identical(e, currentElement));
    _topLevelElements.add(e);
  }

  /// Finishes the top-level code for the element [e].
  void _finishTopLevelCodeForClass(TypeDefiningElement e) {
    var last = _topLevelElements.removeLast();
    assert(identical(e, last));
  }

  /// To emit top-level module items, we sometimes need to reorder them.
  ///
  /// This function takes care of that, and also detects cases where reordering
  /// failed, and we need to resort to lazy loading, by marking the element as
  /// lazy. All elements need to be aware of this possibility and generate code
  /// accordingly.
  ///
  /// If we are not emitting top-level code, this does nothing, because all
  /// declarations are assumed to be available before we start execution.
  /// See [startTopLevel].
  void _declareBeforeUse(TypeDefiningElement e) {
    if (e == null) return;

    var topLevel = _topLevelElements;
    if (topLevel.isNotEmpty && identical(currentElement, topLevel.last)) {
      // If the item is from our library, try to emit it now.
      _emitTypeDeclaration(e);
    }
  }

  @override
  visitCompilationUnit(CompilationUnit unit) {
    // NOTE: this method isn't the right place to initialize
    // per-compilation-unit state. Declarations can be visited out of order,
    // this is only to catch things that haven't been emitted yet.
    //
    // See _emitTypeDeclaration.
    _currentElements.add(unit.element);
    var isInternalSdk = isSdkInternalRuntime(currentLibrary);
    List<VariableDeclaration> fields;
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        inferNullableTypes(declaration);
        if (isInternalSdk && declaration.variables.isFinal) {
          _emitInternalSdkFields(declaration.variables.variables);
        } else {
          (fields ??= []).addAll(declaration.variables.variables);
        }
        continue;
      }

      if (fields != null) {
        _emitTopLevelFields(fields);
        fields = null;
      }

      var element = declaration.element;
      if (element is TypeDefiningElement) {
        _emitTypeDeclaration(element);
        continue;
      }

      inferNullableTypes(declaration);
      var item = _visit(declaration);
      if (isInternalSdk && element is FunctionElement) {
        _internalSdkFunctions.add(item);
      } else {
        _moduleItems.add(item);
      }
    }

    if (fields != null) _emitTopLevelFields(fields);

    _currentElements.removeLast();
  }

  void _emitExportDirectives(CompilationUnit unit) {
    for (var directive in unit.directives) {
      _currentElements.add(directive.element);
      directive.accept(this);
      _currentElements.removeLast();
    }
  }

  @override
  visitLibraryDirective(LibraryDirective node) => null;

  @override
  visitImportDirective(ImportDirective node) {
    // We don't handle imports here.
    //
    // Instead, we collect imports whenever we need to generate a reference
    // to another library. This has the effect of collecting the actually used
    // imports.
    //
    // TODO(jmesserly): if this is a prefixed import, consider adding the prefix
    // as an alias?
    return null;
  }

  @override
  visitPartDirective(PartDirective node) => null;

  @override
  visitPartOfDirective(PartOfDirective node) => null;

  @override
  visitExportDirective(ExportDirective node) {
    ExportElement element = node.element;
    var currentLibrary = element.library;

    var currentNames = currentLibrary.publicNamespace.definedNames;
    var exportedNames =
        new NamespaceBuilder().createExportNamespaceForDirective(element);

    // We only need to export main as it is the only method part of the
    // publicly exposed JS API for a library.
    // TODO(jacobr): add a library level annotation indicating that all
    // contents of a library need to be exposed to JS.
    // https://github.com/dart-lang/sdk/issues/26368
    var export = exportedNames.get('main');

    if (export is FunctionElement) {
      // Don't allow redefining names from this library.
      if (currentNames.containsKey(export.name)) return null;

      var name = _emitTopLevelName(export);
      _moduleItems.add(js.statement(
          '#.# = #;', [emitLibraryName(currentLibrary), name.selector, name]));
    }
  }

  @override
  visitAsExpression(AsExpression node) {
    Expression fromExpr = node.expression;
    var from = getStaticType(fromExpr);
    var to = node.type.type;
    JS.Expression jsFrom = _visit(fromExpr);

    // If the check was put here by static analysis to ensure soundness, we
    // can't skip it. This happens because of unsound covariant generics:
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
    var isRequiredForSoundness = CoercionReifier.isRequiredForSoundness(node);
    if (!isRequiredForSoundness && rules.isSubtypeOf(from, to)) return jsFrom;

    // All Dart number types map to a JS double.
    if (typeRep.isNumber(from) && typeRep.isNumber(to)) {
      // Make sure to check when converting to int.
      if (from != types.intType && to == types.intType) {
        // TODO(jmesserly): fuse this with notNull check.
        // TODO(jmesserly): this does not correctly distinguish user casts from
        // required-for-soundness casts.
        return _callHelper('asInt(#)', jsFrom);
      }

      // A no-op in JavaScript.
      return jsFrom;
    }

    var code = isRequiredForSoundness ? '#._check(#)' : '#.as(#)';
    return js.call(code, [_emitType(to), jsFrom]);
  }

  @override
  visitIsExpression(IsExpression node) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    JS.Expression result;
    var type = node.type.type;
    var lhs = _visit(node.expression);
    var typeofName = _jsTypeofName(type);
    // Inline primitives other than int (which requires a Math.floor check).
    if (typeofName != null && type != types.intType) {
      result = js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    } else {
      // Always go through a runtime helper, because implicit interfaces.

      var castType = _emitType(type);

      result = js.call('#.is(#)', [castType, lhs]);
    }

    if (node.notOperator != null) {
      return js.call('!#', result);
    }
    return result;
  }

  String _jsTypeofName(DartType t) {
    if (typeRep.isNumber(t)) return 'number';
    if (t == types.stringType) return 'string';
    if (t == types.boolType) return 'boolean';
    return null;
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) => _emitTypedef(node);

  @override
  visitGenericTypeAlias(GenericTypeAlias node) => _emitTypedef(node);

  JS.Statement _emitTypedef(TypeAlias node) {
    var element = node.element as FunctionTypeAliasElement;
    FunctionType type;
    var typeFormals = element.typeParameters;
    if (element is GenericTypeAliasElement) {
      type = element.function.type;
    } else {
      type = element.type;
      if (typeFormals.isNotEmpty) {
        // Skip past the type formals, we'll add them back below, so these
        // type parameter names will end up in scope in the generated JS.
        type = type.instantiate(typeFormals.map((f) => f.type).toList());
      }
    }

    JS.Expression body = annotate(
        _callHelper('typedef(#, () => #)', [
          js.string(element.name, "'"),
          _emitType(type, nameType: false, lowerTypedef: true)
        ]),
        node,
        element);

    if (typeFormals.isNotEmpty) {
      return _defineClassTypeArguments(element, typeFormals,
          js.statement('const # = #;', [element.name, body]));
    } else {
      return js.statement('# = #;', [_emitTopLevelName(element), body]);
    }
  }

  @override
  JS.Expression visitTypeName(TypeName node) {
    if (node.type == null) {
      // TODO(jmesserly): if the type fails to resolve, should we generate code
      // that throws instead?
      assert(options.unsafeForceCompile || options.replCompile);
      return _callHelper('dynamic');
    }
    return _emitType(node.type);
  }

  @override
  JS.Statement visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement classElem = node.element;
    var supertype = classElem.supertype;

    var typeFormals = classElem.typeParameters;
    var isGeneric = typeFormals.isNotEmpty;

    // Special case where supertype is Object, and we mixin a single class.
    // The resulting 'class' is a mixable class in this case.
    bool isMixinAlias = supertype.isObject && classElem.mixins.length == 1;

    // TODO(jmesserly): what do we do if the mixin alias has implied superclass
    // covariance checks (due to new interfaces)? We can't add them without
    // messing up the inheritance chain and breaking the ability of the mixin
    // alias to be mixed in elsewhere. We're going to need something special,
    // like adding these checks when we copy in the methods.
    var jsMethods = <JS.Method>[];
    _emitSuperclassCovarianceChecks(node, jsMethods);
    var classExpr = isMixinAlias
        ? _emitClassHeritage(classElem)
        : _emitClassExpression(classElem, jsMethods);
    var className = isGeneric
        ? new JS.Identifier(classElem.name)
        : _emitTopLevelName(classElem);
    var block = <JS.Statement>[];

    if (isGeneric) {
      if (isMixinAlias) {
        block.add(js.statement('const # = #;', [className, classExpr]));
      } else {
        block.add(new JS.ClassDeclaration(classExpr));
      }
    } else {
      block.add(js.statement('# = #;', [className, classExpr]));
    }

    JS.Statement finishGenericTypeTest;

    if (!isMixinAlias) {
      block.addAll(_defineConstructors(classElem, className, [], []));
      finishGenericTypeTest = _emitClassTypeTests(classElem, className, block);
    }

    if (classElem.interfaces.isNotEmpty) {
      block.add(js.statement('#[#.implements] = () => #;', [
        className,
        _runtimeModule,
        new JS.ArrayInitializer(classElem.interfaces.map(_emitType).toList())
      ]));
    }

    if (isGeneric) {
      var classDef =
          _defineClassTypeArguments(classElem, typeFormals, _statement(block));
      if (finishGenericTypeTest == null) return classDef;
      block = [classDef, finishGenericTypeTest];
    }
    return _statement(block);
  }

  JS.Statement _emitJSType(Element e) {
    var jsTypeName = getAnnotationName(e, isJSAnnotation);
    if (jsTypeName == null || jsTypeName == e.name) return null;

    // We export the JS type as if it was a Dart type. For example this allows
    // `dom.InputElement` to actually be HTMLInputElement.
    // TODO(jmesserly): if we had the JS name on the Element, we could just
    // generate it correctly when we refer to it.
    return js.statement('# = #;', [_emitTopLevelName(e), jsTypeName]);
  }

  @override
  JS.Statement visitClassDeclaration(ClassDeclaration node) {
    var classElem = resolutionMap.elementDeclaredByClassDeclaration(node);

    // If this class is annotated with `@JS`, then there is nothing to emit.
    if (findAnnotation(classElem, isPublicJSAnnotation) != null) return null;

    // If this is a JavaScript type, emit it now and then exit.
    var jsTypeDef = _emitJSType(classElem);
    if (jsTypeDef != null) return jsTypeDef;

    var ctors = <ConstructorDeclaration>[];
    var allFields = <FieldDeclaration>[];
    var fields = <FieldDeclaration>[];
    var staticFields = <FieldDeclaration>[];
    var methods = <MethodDeclaration>[];

    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        ctors.add(member);
      } else if (member is FieldDeclaration) {
        allFields.add(member);
        (member.isStatic ? staticFields : fields).add(member);
      } else if (member is MethodDeclaration) {
        methods.add(member);
      }
    }

    JS.Expression className;
    if (classElem.typeParameters.isNotEmpty) {
      // Generic classes will be defined inside a function that closes over the
      // type parameter. So we can use their local variable name directly.
      className = new JS.Identifier(classElem.name);
    } else {
      className = _emitTopLevelName(classElem);
    }

    var savedClassProperties = _classProperties;
    _classProperties = new ClassPropertyModel.build(
        _extensionTypes,
        virtualFields,
        classElem,
        getClassCovariantParameters(node),
        _usedCovariantPrivateMembers);

    var jsCtors = _defineConstructors(classElem, className, fields, ctors);
    var classExpr = _emitClassExpression(classElem, _emitClassMethods(node),
        fields: allFields);

    var body = <JS.Statement>[];
    _initExtensionSymbols(classElem, methods, fields, body);
    _emitSuperHelperSymbols(body);

    // Emit the class, e.g. `core.Object = class Object { ... }`
    _defineClass(classElem, className, classExpr, body);
    body.addAll(jsCtors);

    // Emit things that come after the ES6 `class ... { ... }`.
    var jsPeerNames = _getJSPeerNames(classElem);
    JS.Statement deferredBaseClass =
        _setBaseClass(classElem, className, jsPeerNames, body);

    var finishGenericTypeTest = _emitClassTypeTests(classElem, className, body);

    _emitVirtualFieldSymbols(classElem, body);
    _emitClassSignature(methods, allFields, classElem, ctors, className, body);
    _defineExtensionMembers(className, body);
    _emitClassMetadata(node.metadata, className, body);

    JS.Statement classDef = _statement(body);

    var typeFormals = classElem.typeParameters;
    if (typeFormals.isNotEmpty) {
      classDef = _defineClassTypeArguments(
          classElem, typeFormals, classDef, className, deferredBaseClass);
    }

    body = <JS.Statement>[classDef];
    _emitStaticFields(staticFields, classElem, body);
    if (finishGenericTypeTest != null) body.add(finishGenericTypeTest);
    for (var peer in jsPeerNames) {
      _registerExtensionType(classElem, peer, body);
    }

    _classProperties = savedClassProperties;
    return _statement(body);
  }

  JS.Statement _emitClassTypeTests(ClassElement classElem,
      JS.Expression className, List<JS.Statement> body) {
    JS.Expression getInterfaceSymbol(ClassElement c) {
      var library = c.library;
      if (library.isDartCore || library.isDartAsync) {
        switch (c.name) {
          case 'List':
          case 'Map':
          case 'Iterable':
          case 'Future':
          case 'Stream':
          case 'StreamSubscription':
            return _callHelper('is' + c.name);
        }
      }
      return null;
    }

    void markSubtypeOf(JS.Expression testSymbol) {
      body.add(js.statement('#.prototype[#] = true', [className, testSymbol]));
    }

    for (var iface in classElem.interfaces) {
      var prop = getInterfaceSymbol(iface.element);
      if (prop != null) markSubtypeOf(prop);
    }

    if (classElem.library.isDartCore) {
      if (classElem == objectClass) {
        // Everything is an Object.
        body.add(js.statement(
            '#.is = function is_Object(o) { return true; }', [className]));
        body.add(js.statement(
            '#.as = function as_Object(o) { return o; }', [className]));
        body.add(js.statement(
            '#._check = function check_Object(o) { return o; }', [className]));
        return null;
      }
      if (classElem == stringClass) {
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
      if (classElem == functionClass) {
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
      if (classElem == intClass) {
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
      if (classElem == nullClass) {
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
      if (classElem == numClass || classElem == doubleClass) {
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
      if (classElem == boolClass) {
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
    if (classElem.library.isDartAsync) {
      if (classElem == types.futureOrType.element) {
        var typeParamT = classElem.typeParameters[0].type;
        var tOrFutureOfT = js.call('#.is(o) || #.is(o)', [
          _emitType(typeParamT),
          _emitType(types.futureType.instantiate([typeParamT]))
        ]);
        body.add(js.statement('''
            #.is = function is_FutureOr(o) {
              return #;
            }
            ''', [className, tOrFutureOfT]));
        body.add(js.statement('''
            #.as = function as_FutureOr(o) {
              if (o == null || #) return o;
              return #.castError(o, this, false);
            }
            ''', [className, tOrFutureOfT, _runtimeModule]));
        body.add(js.statement('''
            #._check = function check_FutureOr(o) {
              if (o == null || #) return o;
              return #.castError(o, this, true);
            }
            ''', [className, tOrFutureOfT, _runtimeModule]));
        return null;
      }
    }

    body.add(_callHelperStatement('addTypeTests(#);', [className]));

    if (classElem.typeParameters.isEmpty) return null;

    // For generics, testing against the default instantiation is common,
    // so optimize that.
    var isClassSymbol = getInterfaceSymbol(classElem);
    if (isClassSymbol == null) {
      // TODO(jmesserly): we could export these symbols, if we want to mark
      // implemented interfaces for user-defined classes.
      var id = new JS.TemporaryId("_is_${classElem.name}_default");
      _moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(id.name, "'")]));
      isClassSymbol = id;
    }
    // Marking every generic type instantiation as a subtype of its default
    // instantiation.
    markSubtypeOf(isClassSymbol);

    // Define the type tests on the default instantiation to check for that
    // marker.
    var defaultInst = _emitTopLevelName(classElem);

    // Return this `addTypeTests` call so we can emit it outside of the generic
    // type parameter scope.
    return _callHelperStatement(
        'addTypeTests(#, #);', [defaultInst, isClassSymbol]);
  }

  void _emitSuperHelperSymbols(List<JS.Statement> body) {
    for (var id in _superHelpers.values.map((m) => m.name as JS.TemporaryId)) {
      body.add(js.statement('const # = Symbol(#)', [id, js.string(id.name)]));
    }
    _superHelpers.clear();
  }

  void _emitVirtualFieldSymbols(
      ClassElement classElement, List<JS.Statement> body) {
    _classProperties.virtualFields.forEach((field, virtualField) {
      body.add(js.statement('const # = Symbol(#);',
          [virtualField, js.string('${classElement.name}.${field.name}')]));
    });
  }

  void _defineClass(ClassElement classElem, JS.Expression className,
      JS.ClassExpression classExpr, List<JS.Statement> body) {
    if (classElem.typeParameters.isNotEmpty) {
      body.add(new JS.ClassDeclaration(classExpr));
    } else {
      body.add(js.statement('# = #;', [className, classExpr]));
    }
  }

  List<JS.Identifier> _emitTypeFormals(List<TypeParameterElement> typeFormals) {
    return typeFormals
        .map((t) => new JS.Identifier(t.name))
        .toList(growable: false);
  }

  /// Emits a field declaration for TypeScript & Closure's ES6_TYPED
  /// (e.g. `class Foo { i: string; }`)
  JS.VariableDeclarationList _emitTypeScriptField(FieldDeclaration field) {
    return new JS.VariableDeclarationList(
        field.isStatic ? 'static' : null,
        field.fields.variables
            .map((decl) => new JS.VariableInitialization(
                new JS.Identifier(
                    // TODO(ochafik): use a refactored _emitMemberName instead.
                    decl.name.name,
                    type: emitTypeRef(resolutionMap
                        .elementDeclaredByVariableDeclaration(decl)
                        .type)),
                null))
            .toList(growable: false));
  }

  @override
  JS.Statement visitEnumDeclaration(EnumDeclaration node) {
    var element = resolutionMap.elementDeclaredByEnumDeclaration(node);
    var type = element.type;

    // Generate a class per section 13 of the spec.
    // TODO(vsm): Generate any accompanying metadata

    var fields = element.fields.where((f) => f.type == type).toList();

    // Create toString() method
    var nameProperties = new List<JS.Property>(fields.length);
    for (var i = 0; i < fields.length; ++i) {
      nameProperties[i] = new JS.Property(
          js.number(i), js.string('${type.name}.${fields[i].name}'));
    }
    var nameMap = new JS.ObjectInitializer(nameProperties, multiline: true);
    var toStringF = new JS.Method(js.string('toString'),
        js.call('function() { return #[this.index]; }', nameMap) as JS.Fun);

    // Create enum class
    var classExpr = new JS.ClassExpression(
        new JS.Identifier(type.name), _emitClassHeritage(element), [toStringF]);
    var id = _emitTopLevelName(element);

    // Emit metadata for synthetic enum index member.
    // TODO(jacobr): make field readonly when that is supported.
    var tInstanceFields = <JS.Property>[
      new JS.Property(
          _emitMemberName('index'), _emitFieldSignature(types.intType))
    ];
    var sigFields = <JS.Property>[];
    _buildSignatureField(sigFields, 'fields', tInstanceFields);
    var sig = new JS.ObjectInitializer(sigFields);

    var result = [
      js.statement('# = #', [id, classExpr]),
      js.statement(
          '(#.new = function(x) { this.index = x; }).prototype = #.prototype;',
          [id, id]),
      _callHelperStatement('setSignature(#, #);', [id, sig])
    ];

    // defineEnumValues internally depends on dart.constList which uses
    // _interceptors.JSArray.
    _declareBeforeUse(_jsArray);

    // Create static fields for each enum value, and the "values" getter
    result.add(_callHelperStatement('defineEnumValues(#, #);', [
      id,
      new JS.ArrayInitializer(fields.map((f) => _propertyName(f.name)).toList(),
          multiline: true)
    ]));

    return _statement(result);
  }

  /// Wraps a possibly generic class in its type arguments.
  JS.Statement _defineClassTypeArguments(TypeDefiningElement element,
      List<TypeParameterElement> formals, JS.Statement body,
      [JS.Expression className, JS.Statement deferredBaseClass]) {
    assert(formals.isNotEmpty);
    var typeConstructor = js.call('(#) => { #; #; return #; }', [
      _emitTypeFormals(formals),
      _typeTable.discharge(formals),
      body,
      element.name
    ]);

    var genericArgs = [typeConstructor];
    if (deferredBaseClass != null) {
      genericArgs.add(js.call('(#) => { #; }', [className, deferredBaseClass]));
    }

    var genericCall = _callHelper('generic(#)', [genericArgs]);

    if (element.library.isDartAsync &&
        (element.name == "Future" || element.name == "_Future")) {
      genericCall = _callHelper('flattenFutures(#)', [genericCall]);
    }
    var genericDef = js.statement(
        '# = #;', [_emitTopLevelName(element, suffix: r'$'), genericCall]);
    // TODO(jmesserly): this should be instantiate to bounds
    var dynType = fillDynamicTypeArgs(element.type);
    var genericInst = _emitType(dynType, lowerGeneric: true);
    return js.statement(
        '{ #; # = #; }', [genericDef, _emitTopLevelName(element), genericInst]);
  }

  bool _deferIfNeeded(DartType type, ClassElement current) {
    if (type is ParameterizedType) {
      var typeArguments = type.typeArguments;
      for (var typeArg in typeArguments) {
        var typeElement = typeArg.element;
        // FIXME(vsm): This does not track mutual recursive dependences.
        if (current == typeElement || _deferIfNeeded(typeArg, current)) {
          return true;
        }
      }
    }
    return false;
  }

  JS.ClassExpression _emitClassExpression(
      ClassElement element, List<JS.Method> methods,
      {List<FieldDeclaration> fields}) {
    String name = element.name;
    var heritage = _emitClassHeritage(element);
    var typeParams = _emitTypeFormals(element.typeParameters);
    var jsFields = fields?.map(_emitTypeScriptField)?.toList();

    return new JS.ClassExpression(new JS.Identifier(name), heritage, methods,
        typeParams: typeParams, fields: jsFields);
  }

  JS.Expression _emitClassHeritage(ClassElement element) {
    var type = element.type;
    if (type.isObject) return null;

    _startTopLevelCodeForClass(element);

    // List of "direct" supertypes (supertype + mixins)
    var basetypes = [type.superclass]..addAll(type.mixins);

    // If any of these are recursive (via type parameter), defer setting
    // the real superclass.
    if (basetypes.any((t) => _deferIfNeeded(t, element))) {
      // Fall back to raw type
      basetypes =
          basetypes.map((t) => fillDynamicTypeArgs(t.element.type)).toList();
      _hasDeferredSupertype.add(element);
    }

    // List of "direct" JS superclasses
    var baseclasses = basetypes
        .map((t) => _emitConstructorAccess(t, nameType: false))
        .toList();
    assert(baseclasses.isNotEmpty);
    var heritage = (baseclasses.length == 1)
        ? baseclasses.first
        : _callHelper('mixin(#)', [baseclasses]);

    _finishTopLevelCodeForClass(element);

    return heritage;
  }

  /// Provide Dart getters and setters that forward to the underlying native
  /// field.  Note that the Dart names are always symbolized to avoid
  /// conflicts.  They will be installed as extension methods on the underlying
  /// native type.
  List<JS.Method> _emitNativeFieldAccessors(FieldDeclaration node) {
    // TODO(vsm): Can this by meta-programmed?
    // E.g., dart.nativeField(symbol, jsName)
    // Alternatively, perhaps it could be meta-programmed directly in
    // dart.registerExtensions?
    var jsMethods = <JS.Method>[];
    if (!node.isStatic) {
      for (var decl in node.fields.variables) {
        var field = decl.element as FieldElement;
        var name = getAnnotationName(field, isJsName) ?? field.name;
        // Generate getter
        var fn = new JS.Fun([], js.statement('{ return this.#; }', [name]));
        var method =
            new JS.Method(_declareMemberName(field.getter), fn, isGetter: true);
        jsMethods.add(method);

        // Generate setter
        if (!decl.isFinal) {
          var value = new JS.TemporaryId('value');
          fn = new JS.Fun(
              [value], js.statement('{ this.# = #; }', [name, value]));
          method = new JS.Method(_declareMemberName(field.setter), fn,
              isSetter: true);
          jsMethods.add(method);
        }
      }
    }
    return jsMethods;
  }

  List<JS.Method> _emitClassMethods(ClassDeclaration node) {
    var element = resolutionMap.elementDeclaredByClassDeclaration(node);
    var type = element.type;
    var virtualFields = _classProperties.virtualFields;

    var jsMethods = <JS.Method>[];
    bool hasJsPeer = findAnnotation(element, isJsPeerInterface) != null;
    bool hasIterator = false;

    if (type.isObject) {
      // Dart does not use ES6 constructors.
      // Add an error to catch any invalid usage.
      jsMethods.add(
          new JS.Method(_propertyName('constructor'), js.call(r'''function() {
                  throw Error("use `new " + #.typeName(#.getReifiedType(this)) +
                      ".new(...)` to create a Dart object");
              }''', [_runtimeModule, _runtimeModule])));
    }
    for (var m in node.members) {
      if (m is ConstructorDeclaration) {
        if (m.factoryKeyword != null && !_externalOrNative(m)) {
          jsMethods.add(_emitFactoryConstructor(m));
        }
      } else if (m is MethodDeclaration) {
        jsMethods.add(_emitMethodDeclaration(type, m));

        if (m.element is PropertyAccessorElement) {
          jsMethods.add(_emitSuperAccessorWrapper(m, type));
        }

        if (!hasJsPeer && m.isGetter && m.name.name == 'iterator') {
          hasIterator = true;
          jsMethods.add(_emitIterable(type));
        }
      } else if (m is FieldDeclaration) {
        if (_extensionTypes.isNativeClass(element)) {
          jsMethods.addAll(_emitNativeFieldAccessors(m));
          continue;
        }
        if (m.isStatic) continue;
        for (VariableDeclaration field in m.fields.variables) {
          if (virtualFields.containsKey(field.element)) {
            jsMethods.addAll(_emitVirtualFieldAccessor(field));
          }
        }
      }
    }

    jsMethods.addAll(_classProperties.mockMembers.values
        .map((e) => _implementMockMember(e, type)));

    // If the type doesn't have an `iterator`, but claims to implement Iterable,
    // we inject the adaptor method here, as it's less code size to put the
    // helper on a parent class. This pattern is common in the core libraries
    // (e.g. IterableMixin<E> and IterableBase<E>).
    //
    // (We could do this same optimization for any interface with an `iterator`
    // method, but that's more expensive to check for, so it doesn't seem worth
    // it. The above case for an explicit `iterator` method will catch those.)
    if (!hasJsPeer && !hasIterator && _implementsIterable(type)) {
      jsMethods.add(_emitIterable(type));
    }

    // Add all of the super helper methods
    jsMethods.addAll(_superHelpers.values);

    _emitSuperclassCovarianceChecks(node, jsMethods);
    return jsMethods.where((m) => m != null).toList(growable: false);
  }

  void _emitSuperclassCovarianceChecks(
      Declaration node, List<JS.Method> methods) {
    var covariantParams = getSuperclassCovariantParameters(node);
    if (covariantParams == null) return;

    for (var member in covariantParams.map((p) => p.enclosingElement).toSet()) {
      var name = _declareMemberName(member);
      if (member is PropertyAccessorElement) {
        var param = member.parameters[0];
        assert(covariantParams.contains(param));
        methods.add(new JS.Method(
            name,
            js.call('function(x) { return super.#(#._check(x)); }',
                [name, _emitType(param.type)]),
            isSetter: true));
        methods.add(new JS.Method(
            name, js.call('function() { return super.#; }', [name]),
            isGetter: true));
      } else if (member is MethodElement) {
        var type = member.type;

        var body = <JS.Statement>[];
        var typeFormals = _emitTypeFormals(type.typeFormals);
        if (type.typeFormals.any(covariantParams.contains)) {
          body.add(js.statement(
              '#.checkBounds([#]);', [_emitType(type), typeFormals]));
        }

        var jsParams = <JS.Parameter>[];
        bool foundNamedParams = false;
        for (var param in member.parameters) {
          JS.Parameter jsParam;
          if (param.kind == ParameterKind.NAMED) {
            foundNamedParams = true;
            if (covariantParams.contains(param)) {
              var name = _propertyName(param.name);
              body.add(js.statement('if (# in #) #._check(#.#);', [
                name,
                namedArgumentTemp,
                _emitType(param.type),
                namedArgumentTemp,
                name
              ]));
            }
          } else {
            jsParam = _emitParameter(param);
            jsParams.add(jsParam);
            if (covariantParams.contains(param)) {
              if (param.kind == ParameterKind.POSITIONAL) {
                body.add(js.statement('if (# !== void 0) #._check(#);',
                    [jsParam, _emitType(param.type), jsParam]));
              } else {
                body.add(js.statement(
                    '#._check(#);', [_emitType(param.type), jsParam]));
              }
            }
          }
        }

        if (foundNamedParams) jsParams.add(namedArgumentTemp);

        if (typeFormals.isEmpty) {
          body.add(js.statement('return super.#(#);', [name, jsParams]));
        } else {
          body.add(js.statement(
              'return super.#(#)(#);', [name, typeFormals, jsParams]));
        }
        var fn = new JS.Fun(jsParams, new JS.Block(body),
            typeParams: typeFormals, returnType: emitTypeRef(type.returnType));
        methods.add(new JS.Method(name, _makeGenericFunction(fn)));
      } else {
        throw new StateError(
            'unable to generate a covariant check for element: `$member` '
            '(${member.runtimeType})');
      }
    }
  }

  /// Emits a Dart factory constructor to a JS static method.
  JS.Method _emitFactoryConstructor(ConstructorDeclaration node) {
    var element = node.element;
    var returnType = emitTypeRef(element.returnType);
    var name = _constructorName(element);
    JS.Fun fun;

    var redirect = node.redirectedConstructor;
    if (redirect != null) {
      // Wacky factory redirecting constructors: factory Foo.q(x, y) = Bar.baz;

      var newKeyword = redirect.staticElement.isFactory ? '' : 'new';
      // Pass along all arguments verbatim, and let the callee handle them.
      // TODO(jmesserly): we'll need something different once we have
      // rest/spread support, but this should work for now.
      var params =
          _emitFormalParameterList(node.parameters, destructure: false);

      fun = new JS.Fun(
          params,
          js.statement(
              '{ return $newKeyword #(#); }', [_visit(redirect), params]),
          returnType: returnType);
    } else {
      // Normal factory constructor
      var body = <JS.Statement>[];
      var init = _emitArgumentInitializers(node, constructor: true);
      if (init != null) body.add(init);
      body.add(_visit(node.body));

      var params = _emitFormalParameterList(node.parameters);
      fun = new JS.Fun(params, new JS.Block(body), returnType: returnType);
    }

    return annotate(new JS.Method(name, fun, isStatic: true), node, element);
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
  JS.Method _implementMockMember(ExecutableElement method, InterfaceType type) {
    var invocationProps = <JS.Property>[];
    addProperty(String name, JS.Expression value) {
      invocationProps.add(new JS.Property(js.string(name), value));
    }

    var args = new JS.TemporaryId('args');
    var fnArgs = <JS.Parameter>[];
    JS.Expression positionalArgs;

    if (method.type.namedParameterTypes.isNotEmpty) {
      addProperty('namedArguments', _callHelper('extractNamedArgs(#)', [args]));
    }

    if (method is MethodElement) {
      addProperty('isMethod', js.boolean(true));

      fnArgs.add(new JS.RestParameter(args));
      positionalArgs = args;
    } else {
      var property = method as PropertyAccessorElement;
      if (property.isGetter) {
        addProperty('isGetter', js.boolean(true));

        positionalArgs = new JS.ArrayInitializer([]);
      } else if (property.isSetter) {
        addProperty('isSetter', js.boolean(true));

        fnArgs.add(args);
        positionalArgs = new JS.ArrayInitializer([args]);
      }
    }

    var typeParams = _emitTypeFormals(method.type.typeFormals);
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

    if (!method.returnType.isDynamic) {
      fnBody = js.call('#._check(#)', [_emitType(method.returnType), fnBody]);
    }

    var fn = _makeGenericFunction(new JS.Fun(
        fnArgs, js.statement('{ return #; }', [fnBody]),
        typeParams: typeParams));

    return new JS.Method(
        _declareMemberName(method,
            useExtension: _extensionTypes.isNativeClass(type.element)),
        fn,
        isGetter: method is PropertyAccessorElement && method.isGetter,
        isSetter: method is PropertyAccessorElement && method.isSetter,
        isStatic: false);
  }

  /// This is called whenever a derived class needs to introduce a new field,
  /// shadowing a field or getter/setter pair on its parent.
  ///
  /// This is important because otherwise, trying to read or write the field
  /// would end up calling the getter or setter, and one of those might not even
  /// exist, resulting in a runtime error. Even if they did exist, that's the
  /// wrong behavior if a new field was declared.
  List<JS.Method> _emitVirtualFieldAccessor(VariableDeclaration field) {
    var element = field.element as FieldElement;
    var virtualField = _classProperties.virtualFields[element];
    var result = <JS.Method>[];
    var name = _declareMemberName(element.getter);

    var mocks = _classProperties.mockMembers;
    if (!mocks.containsKey(element.name)) {
      var getter = js.call('function() { return this[#]; }', [virtualField]);
      result.add(new JS.Method(name, getter, isGetter: true));
    }

    if (!mocks.containsKey(element.name + '=')) {
      var args = field.isFinal
          ? [new JS.Super(), name]
          : [new JS.This(), virtualField];

      String jsCode;
      var setter = element.setter;
      var covariantParams = _classProperties.covariantParameters;
      if (setter != null &&
          covariantParams != null &&
          covariantParams.contains(setter.parameters[0])) {
        args.add(_emitType(setter.parameters[0].type));
        jsCode = 'function(value) { #[#] = #._check(value); }';
      } else {
        jsCode = 'function(value) { #[#] = value; }';
      }

      result.add(new JS.Method(name, js.call(jsCode, args), isSetter: true));
    }

    return result;
  }

  /// Emit a getter or setter that simply forwards to the superclass getter or
  /// setter. This is needed because in ES6, if you only override a getter
  /// (alternatively, a setter), then there is an implicit override of the
  /// setter (alternatively, the getter) that does nothing.
  JS.Method _emitSuperAccessorWrapper(
      MethodDeclaration method, InterfaceType type) {
    var methodElement = method.element as PropertyAccessorElement;
    var field = methodElement.variable;
    if (!field.isSynthetic) return null;

    // Generate a corresponding virtual getter / setter.
    var name = _declareMemberName(methodElement);
    if (method.isGetter) {
      var setter = field.setter;
      if ((setter == null || setter.isAbstract) &&
          _classProperties.inheritedSetters.contains(field.name)) {
        // Generate a setter that forwards to super.
        var fn = js.call('function(value) { super[#] = value; }', [name]);
        return new JS.Method(name, fn, isSetter: true);
      }
    } else {
      var getter = field.getter;
      if ((getter == null || getter.isAbstract) &&
          _classProperties.inheritedGetters.contains(field.name)) {
        // Generate a getter that forwards to super.
        var fn = js.call('function() { return super[#]; }', [name]);
        return new JS.Method(name, fn, isGetter: true);
      }
    }
    return null;
  }

  bool _implementsIterable(InterfaceType t) =>
      t.interfaces.any((i) => i.element.type == types.iterableType);

  /// Support for adapting dart:core Iterable to ES6 versions.
  ///
  /// This lets them use for-of loops transparently:
  /// <https://github.com/lukehoban/es6features#iterators--forof>
  ///
  /// This will return `null` if the adapter was already added on a super type,
  /// otherwise it returns the adapter code.
  // TODO(jmesserly): should we adapt `Iterator` too?
  JS.Method _emitIterable(InterfaceType t) {
    // If a parent had an `iterator` (concrete or abstract) or implements
    // Iterable, we know the adapter is already there, so we can skip it as a
    // simple code size optimization.
    var parent = t.lookUpGetterInSuperclass('iterator', t.element.library);
    if (parent != null) return null;
    var parentType = findSupertype(t, _implementsIterable);
    if (parentType != null) return null;

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return new JS.Method(
        js.call('Symbol.iterator'),
        js.call('function() { return new #.JsIterator(this.#); }',
            [_runtimeModule, _emitMemberName('iterator', type: t)]) as JS.Fun);
  }

  JS.Expression _instantiateAnnotation(Annotation node) {
    var element = node.element;
    if (element is ConstructorElement) {
      return _emitInstanceCreationExpression(element, element.returnType,
          node.constructorName, node.arguments, true);
    } else {
      return _visit(node.name);
    }
  }

  /// Gets the JS peer for this Dart type if any, otherwise null.
  ///
  /// For example for dart:_interceptors `JSArray` this will return "Array",
  /// referring to the JavaScript built-in `Array` type.
  List<String> _getJSPeerNames(ClassElement classElem) {
    var jsPeerNames = getAnnotationName(
        classElem,
        (a) =>
            isJsPeerInterface(a) ||
            isNativeAnnotation(a) && _extensionTypes.isNativeClass(classElem));
    if (jsPeerNames != null) {
      // Omit the special name "!nonleaf" and any future hacks starting with "!"
      return jsPeerNames
          .split(',')
          .where((peer) => !peer.startsWith("!"))
          .toList();
    } else {
      return [];
    }
  }

  void _registerExtensionType(
      ClassElement classElem, String jsPeerName, List<JS.Statement> body) {
    if (jsPeerName != null) {
      body.add(_callHelperStatement('registerExtension(#, #);',
          [js.string(jsPeerName), _emitTopLevelName(classElem)]));
    }
  }

  JS.Statement _setBaseClass(ClassElement classElem, JS.Expression className,
      List<String> jsPeerNames, List<JS.Statement> body) {
    var typeFormals = classElem.typeParameters;
    if (jsPeerNames.length == 1 && typeFormals.isNotEmpty) {
      var newBaseClass = _callHelper('global.#', jsPeerNames[0]);
      body.add(_callHelperStatement(
          'setExtensionBaseClass(#, #);', [className, newBaseClass]));
    } else if (_hasDeferredSupertype.contains(classElem)) {
      // TODO(vsm): consider just threading the deferred supertype through
      // instead of recording classElem in a set on the class and recomputing
      var newBaseClass = _emitType(classElem.type.superclass,
          nameType: false, subClass: classElem, className: className);
      if (classElem.type.mixins.isNotEmpty) {
        var mixins = classElem.type.mixins
            .map((t) => _emitType(t, nameType: false))
            .toList();
        mixins.insert(0, newBaseClass);
        newBaseClass = _callHelper('mixin(#)', [mixins]);
      }
      var deferredBaseClass = _callHelperStatement(
          'setBaseClass(#, #);', [className, newBaseClass]);
      if (typeFormals.isNotEmpty) return deferredBaseClass;
      body.add(deferredBaseClass);
    }
    return null;
  }

  /// Defines all constructors for this class as ES5 constructors.
  List<JS.Statement> _defineConstructors(
      ClassElement classElem,
      JS.Expression className,
      List<FieldDeclaration> fields,
      List<ConstructorDeclaration> ctors) {
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
    var callMethod = classElem.type.lookUpInheritedGetterOrMethod('call');
    bool isCallable = callMethod is PropertyAccessorElement
        ? callMethod.returnType is FunctionType
        : callMethod != null;

    var body = <JS.Statement>[];
    if (isCallable) {
      // Our class instances will have JS `typeof this == "function"`,
      // so make sure to attach the runtime type information the same way
      // we would do it for function types.
      body.add(js.statement('#.prototype[#] = #;',
          [className, _callHelper('_runtimeType'), className]));
    }

    void addConstructor(ConstructorElement element, JS.Expression jsCtor) {
      var ctorName = _constructorName(element);
      if (JS.invalidStaticFieldName(element.name)) {
        jsCtor =
            _callHelper('defineValue(#, #, #)', [className, ctorName, jsCtor]);
      } else {
        jsCtor = js.call('#.# = #', [className, ctorName, jsCtor]);
      }
      body.add(js.statement('#.prototype = #.prototype;', [jsCtor, className]));
    }

    if (classElem.isMixinApplication) {
      var supertype = classElem.supertype;
      for (var ctor in classElem.constructors) {
        List<JS.Identifier> jsParams = _emitParametersForElement(ctor);
        var superCtor = supertype.lookUpConstructor(ctor.name, ctor.library);
        var superCall =
            _superConstructorCall(classElem, className, superCtor, jsParams);
        addConstructor(
            ctor,
            _finishConstructorFunction(
                jsParams,
                new JS.Block(superCall != null ? [superCall] : []),
                isCallable));
      }
      return body;
    }

    // Iff no constructor is specified for a class C, it implicitly has a
    // default constructor `C() : super() {}`, unless C is class Object.
    if (ctors.isEmpty) {
      var superCall = _superConstructorCall(classElem, className);
      var ctorBody = <JS.Statement>[_initializeFields(fields)];
      if (superCall != null) ctorBody.add(superCall);

      addConstructor(classElem.unnamedConstructor,
          _finishConstructorFunction([], new JS.Block(ctorBody), isCallable));
      return body;
    }

    bool foundConstructor = false;
    for (var ctor in ctors) {
      var element = ctor.element;
      if (element.isFactory || _externalOrNative(ctor)) continue;

      addConstructor(
          element, _emitConstructor(ctor, fields, isCallable, className));
      foundConstructor = true;
    }

    // If classElement has only factory constructors, and it can be mixed in,
    // then we need to emit a special hidden default constructor for use by
    // mixins.
    if (!foundConstructor && classElem.supertype.isObject) {
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

  /// Emits static fields for a class, and initialize them eagerly if possible,
  /// otherwise define them as lazy properties.
  void _emitStaticFields(List<FieldDeclaration> staticFields,
      ClassElement classElem, List<JS.Statement> body) {
    var lazyStatics = staticFields.expand((f) => f.fields.variables).toList();
    if (lazyStatics.isNotEmpty) {
      body.add(_emitLazyFields(classElem, lazyStatics));
    }
  }

  void _emitClassMetadata(List<Annotation> metadata, JS.Expression className,
      List<JS.Statement> body) {
    // Metadata
    if (options.emitMetadata && metadata.isNotEmpty) {
      body.add(js.statement('#[#.metadata] = () => #;', [
        className,
        _runtimeModule,
        new JS.ArrayInitializer(
            new List<JS.Expression>.from(metadata.map(_instantiateAnnotation)))
      ]));
    }
  }

  /// If a concrete class implements one of our extensions, we might need to
  /// add forwarders.
  void _defineExtensionMembers(
      JS.Expression className, List<JS.Statement> body) {
    void emitExtensions(
        JS.Expression target, Iterable<ExecutableElement> extensions) {
      if (extensions.isEmpty) return;

      var names = extensions
          .map((e) => _declareMemberName(e, useExtension: false))
          .toList();
      body.add(_callHelperStatement('defineExtensionMembers(#, #);', [
        target,
        new JS.ArrayInitializer(names, multiline: names.length > 4)
      ]));
    }

    // Define mixin members (if any) on the mixin class.
    var mixinClass = js.call('#.__proto__', [className]);
    emitExtensions(mixinClass, _classProperties.mixinExtensionMembers);
    emitExtensions(className, _classProperties.extensionMembers);
  }

  void _buildSignatureField(
      List<JS.Property> sigFields, String name, List<JS.Property> elements) {
    if (elements.isEmpty) return;
    var o = new JS.ObjectInitializer(elements, multiline: elements.length > 1);
    // TODO(vsm): Remove
    var e = js.call('() => #', o);
    sigFields.add(new JS.Property(_propertyName(name), e));
  }

  /// Emit the signature on the class recording the runtime type information
  void _emitClassSignature(
      List<MethodDeclaration> methods,
      List<FieldDeclaration> fields,
      ClassElement classElem,
      List<ConstructorDeclaration> ctors,
      JS.Expression className,
      List<JS.Statement> body) {
    if (classElem.interfaces.isNotEmpty) {
      body.add(js.statement('#[#.implements] = () => #;', [
        className,
        _runtimeModule,
        new JS.ArrayInitializer(
            new List<JS.Expression>.from(classElem.interfaces.map(_emitType)))
      ]));
    }

    var tStaticMethods = <JS.Property>[];
    var tInstanceMethods = <JS.Property>[];
    var tStaticGetters = <JS.Property>[];
    var tInstanceGetters = <JS.Property>[];
    var tStaticSetters = <JS.Property>[];
    var tInstanceSetters = <JS.Property>[];
    var sNames = <JS.Expression>[];
    for (MethodDeclaration node in methods) {
      var name = node.name.name;
      var element = resolutionMap.elementDeclaredByMethodDeclaration(node);
      // TODO(vsm): Clean up all the nasty duplication.
      if (node.isAbstract) {
        continue;
      }
      // Static getters/setters cannot be called with dynamic dispatch, nor
      // can they be torn off.
      // TODO(jmesserly): can we attach static method type info at the tearoff
      // point, and avoid saving the information otherwise? Same trick would
      // work for top-level functions.
      if (!options.emitMetadata &&
          node.isStatic &&
          (node.isGetter || node.isSetter)) {
        continue;
      }
      List<JS.Property> tMember;
      // TODO(jmesserly): these 3 variables should be typed.
      Function getOverride;
      Function lookup;
      Function elementToType;
      // TODO(jmesserly): we could reduce work by not saving a full function
      // type for getters/setters. These only need 1 type to be saved.
      if (node.isGetter) {
        elementToType = (ExecutableElement element) => element.type;
        getOverride = classElem.lookUpInheritedConcreteGetter;
        lookup = classElem.type.lookUpInheritedGetter;
        tMember = node.isStatic ? tStaticGetters : tInstanceGetters;
      } else if (node.isSetter) {
        elementToType = (ExecutableElement element) => element.type;
        getOverride = classElem.lookUpInheritedConcreteSetter;
        lookup = classElem.type.lookUpInheritedSetter;
        tMember = node.isStatic ? tStaticSetters : tInstanceSetters;
      } else {
        // Swap in "Object" for parameter types that are covariant, either via
        // the `covariant` keyword or because of covariant generics.
        elementToType = _getMemberRuntimeType;
        getOverride = classElem.lookUpInheritedConcreteMethod;
        lookup = classElem.type.lookUpInheritedMethod;
        tMember = node.isStatic ? tStaticMethods : tInstanceMethods;
      }

      DartType reifiedType = elementToType(element);
      // Don't add redundant signatures for inherited methods whose signature
      // did not change.  If we are not overriding, or if the thing we are
      // overriding has a different reified type from ourselves, we must
      // emit a signature on this class.  Otherwise we will inherit the
      // signature from the superclass.
      var needsSignature = getOverride(name, currentLibrary) == null ||
          elementToType(
                  lookup(name, library: currentLibrary, thisType: false)) !=
              reifiedType;

      var type = _emitAnnotatedFunctionType(reifiedType, node.metadata,
          parameters: node.parameters?.parameters,
          nameType: false,
          definite: true);

      if (needsSignature) {
        var memberName = _declareMemberName(element);
        var property = new JS.Property(memberName, type);
        tMember.add(property);
        // We record the names of static methods separately so we can
        // attach metadata to them individually.
        // TODO(leafp): Revisit this.
        if (node.isStatic && !node.isGetter && !node.isSetter) {
          sNames.add(memberName);
        }
      }
    }

    var tInstanceFields = <JS.Property>[];
    var tStaticFields = <JS.Property>[];
    for (FieldDeclaration node in fields) {
      // Only instance fields need to be saved for dynamic dispatch.
      var isStatic = node.isStatic;
      if (options.emitMetadata || !isStatic) {
        for (VariableDeclaration field in node.fields.variables) {
          var element = field.element as FieldElement;
          var fieldList = isStatic ? tStaticFields : tInstanceFields;

          var memberName = _declareMemberName(element.getter);
          var fieldSig = _emitFieldSignature(element.type,
              metadata: node.metadata, isFinal: element.isFinal);
          fieldList.add(new JS.Property(memberName, fieldSig));
        }
      }
    }

    var tCtors = <JS.Property>[];
    if (options.emitMetadata) {
      for (ConstructorDeclaration node in ctors) {
        var element = node.element;
        var memberName = _constructorName(element);
        var type = _emitAnnotatedFunctionType(element.type, node.metadata,
            parameters: node.parameters.parameters,
            nameType: false,
            definite: true);
        var property = new JS.Property(memberName, type);
        tCtors.add(property);
      }
    }
    var sigFields = <JS.Property>[];
    _buildSignatureField(sigFields, 'constructors', tCtors);
    _buildSignatureField(sigFields, 'fields', tInstanceFields);
    _buildSignatureField(sigFields, 'getters', tInstanceGetters);
    _buildSignatureField(sigFields, 'setters', tInstanceSetters);
    _buildSignatureField(sigFields, 'methods', tInstanceMethods);
    _buildSignatureField(sigFields, 'sfields', tStaticFields);
    _buildSignatureField(sigFields, 'sgetters', tStaticGetters);
    _buildSignatureField(sigFields, 'ssetters', tStaticSetters);
    _buildSignatureField(sigFields, 'statics', tStaticMethods);
    if (!tStaticMethods.isEmpty) {
      assert(!sNames.isEmpty);
      // Emit names so that we can lazily attach metadata to statics
      // TODO(leafp): revisit this strategy
      sigFields.add(new JS.Property(
          _propertyName('names'), new JS.ArrayInitializer(sNames)));
    }
    // We set signature here, even if empty, to simplify the work of
    // defineExtensionMembers at runtime. See _defineExtensionMembers.
    if (!sigFields.isEmpty ||
        _classProperties.extensionMembers.isNotEmpty ||
        _classProperties.mixinExtensionMembers.isNotEmpty) {
      var sig = new JS.ObjectInitializer(sigFields);
      body.add(_callHelperStatement('setSignature(#, #);', [className, sig]));
    }
    // Add static property dart._runtimeType to Object.
    // All other Dart classes will (statically) inherit this property.
    if (classElem == objectClass) {
      body.add(_callHelperStatement('tagComputed(#, () => #.#);',
          [className, emitLibraryName(dartCoreLibrary), 'Type']));
    }
  }

  /// Ensure `dartx.` symbols we will use are present.
  void _initExtensionSymbols(
      ClassElement classElem,
      List<MethodDeclaration> methods,
      List<FieldDeclaration> fields,
      List<JS.Statement> body) {
    if (_extensionTypes.hasNativeSubtype(classElem.type)) {
      var dartxNames = <JS.Expression>[];
      for (var m in methods) {
        if (!m.isAbstract &&
            !m.isStatic &&
            resolutionMap.elementDeclaredByMethodDeclaration(m).isPublic) {
          dartxNames.add(_declareMemberName(m.element, useExtension: false));
        }
      }
      for (var fieldDecl in fields) {
        if (!fieldDecl.isStatic) {
          for (var field in fieldDecl.fields.variables) {
            var e = field.element as FieldElement;
            if (e.isPublic) {
              dartxNames.add(_declareMemberName(e.getter, useExtension: false));
            }
          }
        }
      }
      if (dartxNames.isNotEmpty) {
        body.add(_callHelperStatement('defineExtensionNames(#)',
            [new JS.ArrayInitializer(dartxNames, multiline: true)]));
      }
    }
  }

  JS.Expression _emitConstructor(ConstructorDeclaration node,
      List<FieldDeclaration> fields, bool isCallable, JS.Expression className) {
    var params = _emitFormalParameterList(node.parameters);

    var savedFunction = _currentFunction;
    _currentFunction = node.body;

    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var body = _emitConstructorBody(node, fields, className);
    _superAllowed = savedSuperAllowed;
    _currentFunction = savedFunction;

    return _finishConstructorFunction(params, body, isCallable);
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

  FunctionType _getMemberRuntimeType(ExecutableElement element) {
    // Check whether we have any covariant parameters.
    // Usually we don't, so we can use the same type.
    if (!element.parameters.any(_isCovariant)) return element.type;

    var parameters = element.parameters
        .map((p) => new ParameterElementImpl.synthetic(p.name,
            _isCovariant(p) ? objectClass.type : p.type, p.parameterKind))
        .toList();

    var function = new FunctionElementImpl("", -1)
      ..isSynthetic = true
      ..returnType = element.returnType
      ..shareTypeParameters(element.typeParameters)
      ..parameters = parameters;
    return function.type = new FunctionTypeImpl(function);
  }

  JS.Expression _constructorName(ConstructorElement ctor) {
    var name = ctor.name;
    if (name == '') {
      // Default constructors (factory or not) use `new` as their name.
      return _propertyName('new');
    }
    return _emitMemberName(name, isStatic: true);
  }

  JS.Block _emitConstructorBody(ConstructorDeclaration node,
      List<FieldDeclaration> fields, JS.Expression className) {
    var body = <JS.Statement>[];
    ClassDeclaration cls = node.parent;

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    var init = _emitArgumentInitializers(node, constructor: true);
    if (init != null) body.add(init);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    var redirectCall = node.initializers.firstWhere(
        (i) => i is RedirectingConstructorInvocation,
        orElse: () => null);

    if (redirectCall != null) {
      body.add(_emitRedirectingConstructor(redirectCall, className));
      return new JS.Block(body);
    }

    // Generate field initializers.
    // These are expanded into each non-redirecting constructor.
    // In the future we may want to create an initializer function if we have
    // multiple constructors, but it needs to be balanced against readability.
    body.add(_initializeFields(fields, node));

    var superCall = node.initializers.firstWhere(
        (i) => i is SuperConstructorInvocation,
        orElse: () => null) as SuperConstructorInvocation;

    // If no superinitializer is provided, an implicit superinitializer of the
    // form `super()` is added at the end of the initializer list, unless the
    // enclosing class is class Object.
    var superCallArgs =
        superCall != null ? _emitArgumentList(superCall.argumentList) : null;
    var jsSuper = _superConstructorCall(
        cls.element, className, superCall?.staticElement, superCallArgs);
    if (jsSuper != null) body.add(annotate(jsSuper, superCall));

    body.add(_visit(node.body));
    return new JS.Block(body)..sourceInformation = node;
  }

  JS.Statement _emitRedirectingConstructor(
      RedirectingConstructorInvocation node, JS.Expression className) {
    var ctor = node.staticElement;
    // We can't dispatch to the constructor with `this.new` as that might hit a
    // derived class constructor with the same name.
    return js.statement('#.#.call(this, #);', [
      className,
      _constructorName(ctor),
      _emitArgumentList(node.argumentList)
    ]);
  }

  JS.Statement _superConstructorCall(
      ClassElement element, JS.Expression className,
      [ConstructorElement superCtor, List<JS.Expression> args]) {
    // Get the supertype's unnamed constructor.
    superCtor ??= element.supertype?.element?.unnamedConstructor;
    if (superCtor == null) {
      assert(element.type.isObject || options.unsafeForceCompile);
      return null;
    }

    // We can skip the super call if it's empty. Typically this happens for
    // things that extend Object.
    if (superCtor.name == '' && !_hasUnnamedSuperConstructor(element)) {
      return null;
    }

    var name = _constructorName(superCtor);
    return js.statement(
        '#.__proto__.#.call(this, #);', [className, name, args ?? []]);
  }

  bool _hasUnnamedSuperConstructor(ClassElement e) {
    var supertype = e.supertype;
    if (supertype == null) return false;
    if (_hasUnnamedConstructor(supertype.element)) return true;
    for (var mixin in e.mixins) {
      if (_hasUnnamedConstructor(mixin.element)) return true;
    }
    return false;
  }

  bool _hasUnnamedConstructor(ClassElement e) {
    if (e.type.isObject) return false;
    if (!e.unnamedConstructor.isSynthetic) return true;
    if (e.fields.any((f) => !f.isStatic && !f.isSynthetic)) return true;
    return _hasUnnamedSuperConstructor(e);
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  JS.Statement _initializeFields(List<FieldDeclaration> fieldDecls,
      [ConstructorDeclaration ctor]) {
    // Run field initializers if they can have side-effects.
    var fields = new Map<FieldElement, JS.Expression>();
    var unsetFields = new Map<FieldElement, VariableDeclaration>();
    for (var declaration in fieldDecls) {
      for (var fieldNode in declaration.fields.variables) {
        var element = fieldNode.element;
        if (_constants.isFieldInitConstant(fieldNode)) {
          unsetFields[element as FieldElement] = fieldNode;
        } else {
          fields[element as FieldElement] = _visitInitializer(fieldNode);
        }
      }
    }

    // Initialize fields from `this.fieldName` parameters.
    if (ctor != null) {
      for (var p in ctor.parameters.parameters) {
        var element = p.element;
        if (element is FieldFormalParameterElement) {
          fields[element.field] = _emitSimpleIdentifier(p.identifier);
        }
      }

      // Run constructor field initializers such as `: foo = bar.baz`
      for (var init in ctor.initializers) {
        if (init is ConstructorFieldInitializer) {
          var element = init.fieldName.staticElement as FieldElement;
          fields[element] = _visit(init.expression);
        } else if (init is AssertInitializer) {
          throw new UnimplementedError(
              'Assert initializers are not implemented. '
              'See https://github.com/dart-lang/sdk/issues/27809');
        }
      }
    }

    for (var f in fields.keys) unsetFields.remove(f);

    // Initialize all remaining fields
    unsetFields.forEach((element, fieldNode) {
      JS.Expression value;
      if (fieldNode.initializer != null) {
        value = _visit(fieldNode.initializer);
      } else {
        value = new JS.LiteralNull();
      }
      fields[element] = value;
    });

    var body = <JS.Statement>[];
    fields.forEach((FieldElement e, JS.Expression initialValue) {
      JS.Expression access =
          _classProperties.virtualFields[e] ?? _declareMemberName(e.getter);
      body.add(initialValue
          .toAssignExpression(js.call('this.#', [access]))
          .toStatement());
    });

    return _statement(body);
  }

  FormalParameterList _parametersOf(node) {
    // TODO(jmesserly): clean this up. If we can model ES6 spread/rest args, we
    // could handle argument initializers more consistently in a separate
    // lowering pass.
    if (node is ConstructorDeclaration) return node.parameters;
    if (node is MethodDeclaration) return node.parameters;
    if (node is FunctionDeclaration) node = node.functionExpression;
    return (node as FunctionExpression).parameters;
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  JS.Statement _emitArgumentInitializers(node, {bool constructor: false}) {
    // Constructor argument initializers are emitted earlier in the code, rather
    // than always when we visit the function body, so we control it explicitly.
    if (node is ConstructorDeclaration != constructor) return null;

    var parameters = _parametersOf(node);
    if (parameters == null) return null;

    var body = <JS.Statement>[];
    for (var param in parameters.parameters) {
      var jsParam = _emitSimpleIdentifier(param.identifier);

      if (!options.destructureNamedParams) {
        if (param.kind == ParameterKind.NAMED) {
          // Parameters will be passed using their real names, not the (possibly
          // renamed) local variable.
          var paramName = js.string(param.identifier.name, "'");

          // TODO(ochafik): Fix `'prop' in obj` to please Closure's renaming.
          body.add(js.statement('let # = # && # in # ? #.# : #;', [
            jsParam,
            namedArgumentTemp,
            paramName,
            namedArgumentTemp,
            namedArgumentTemp,
            paramName,
            _defaultParamValue(param),
          ]));
        } else if (param.kind == ParameterKind.POSITIONAL) {
          body.add(js.statement('if (# === void 0) # = #;',
              [jsParam, jsParam, _defaultParamValue(param)]));
        }
      }

      var paramElement = resolutionMap.elementDeclaredByFormalParameter(param);
      if (_isCovariant(paramElement)) {
        var castType = _emitType(paramElement.type);
        body.add(js.statement('#._check(#);', [castType, jsParam]));
      }
      if (_annotatedNullCheck(paramElement)) {
        body.add(nullParameterCheck(jsParam));
      }
    }
    return body.isEmpty ? null : _statement(body);
  }

  bool _isCovariant(ParameterElement p) {
    if (p.isCovariant) return true;
    var covariantParams = _classProperties?.covariantParameters;
    return covariantParams != null && covariantParams.contains(p);
  }

  JS.Expression _defaultParamValue(FormalParameter param) {
    if (param is DefaultFormalParameter && param.defaultValue != null) {
      return _visit(param.defaultValue);
    } else {
      return new JS.LiteralNull();
    }
  }

  JS.Fun _emitNativeFunctionBody(MethodDeclaration node) {
    String name =
        getAnnotationName(node.element, isJSAnnotation) ?? node.name.name;
    if (node.isGetter) {
      return new JS.Fun([], js.statement('{ return this.#; }', [name]));
    } else if (node.isSetter) {
      var params =
          _emitFormalParameterList(node.parameters, destructure: false);
      return new JS.Fun(
          params, js.statement('{ this.# = #; }', [name, params.last]));
    } else {
      return js.call(
          'function (...args) { return this.#.apply(this, args); }', name);
    }
  }

  JS.Method _emitMethodDeclaration(InterfaceType type, MethodDeclaration node) {
    if (node.isAbstract) {
      return null;
    }

    JS.Fun fn;
    if (_externalOrNative(node)) {
      if (node.isStatic) {
        // TODO(vsm): Do we need to handle this case?
        return null;
      }
      fn = _emitNativeFunctionBody(node);
    } else {
      fn = _emitFunctionBody(node.element, node.parameters, node.body);
    }

    return annotate(
        new JS.Method(_declareMemberName(node.element), fn,
            isGetter: node.isGetter,
            isSetter: node.isSetter,
            isStatic: node.isStatic),
        null, // don't annotate as this breaks stepping for one-line functions.
        node.element);
  }

  /// Transform the function so the last parameter is always returned.
  ///
  /// This is useful for indexed set methods, which otherwise would not have
  /// the right return value in JS.
  JS.Block _alwaysReturnLastParameter(JS.Block body, JS.Parameter lastParam) {
    JS.Statement blockBody = body;
    if (JS.Return.foundIn(body)) {
      // If a return is inside body, transform `(params) { body }` to
      // `(params) { (() => { body })(); return value; }`.
      // TODO(jmesserly): we could instead generate the return differently,
      // and avoid the immediately invoked function.
      blockBody = new JS.Call(new JS.ArrowFun([], body), []).toStatement();
    }
    return new JS.Block([blockBody, new JS.Return(lastParam)]);
  }

  @override
  JS.Statement visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.parent is CompilationUnit);

    if (_externalOrNative(node)) return null;

    if (node.isGetter || node.isSetter) {
      PropertyAccessorElement element = node.element;
      var pairAccessor = node.isGetter
          ? element.correspondingSetter
          : element.correspondingGetter;

      var jsCode = _emitTopLevelProperty(node);
      var props = <JS.Method>[jsCode];
      if (pairAccessor != null) {
        // If we have a getter/setter pair, they need to be defined together.
        // If this is the first one, save the generated code for later.
        // If this is the second one, get the saved code and emit both.
        var pairCode = _deferredProperties.remove(pairAccessor);
        if (pairCode == null) {
          _deferredProperties[element] = jsCode;
          return null;
        }
        props.add(pairCode);
      }
      return _callHelperStatement('copyProperties(#, { # });',
          [emitLibraryName(currentLibrary), props]);
    }

    var body = <JS.Statement>[];
    var fn = _emitFunction(node.functionExpression);

    if (currentLibrary.source.isInSystemLibrary &&
        _isInlineJSFunction(node.functionExpression)) {
      fn = _simplifyPassThroughArrowFunCallBody(fn);
    }

    var element = resolutionMap.elementDeclaredByFunctionDeclaration(node);
    var nameExpr = _emitTopLevelName(element);
    body.add(annotate(js.statement('# = #', [nameExpr, fn]), node, element));
    if (!isSdkInternalRuntime(element.library)) {
      body.add(_emitFunctionTagged(nameExpr, element.type, topLevel: true)
          .toStatement());
    }

    return _statement(body);
  }

  bool _isInlineJSFunction(FunctionExpression functionExpression) {
    var body = functionExpression.body;
    if (body is ExpressionFunctionBody) {
      return _isJSInvocation(body.expression);
    } else if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length == 1) {
        var stat = statements[0];
        if (stat is ReturnStatement) {
          return _isJSInvocation(stat.expression);
        }
      }
    }
    return false;
  }

  bool _isJSInvocation(Expression expr) =>
      expr is MethodInvocation && isInlineJS(expr.methodName.staticElement);

  // Simplify `(args) => (() => { ... })()` to `(args) => { ... }`.
  // Note: this allows silently passing args through to the body, which only
  // works if we don't do weird renamings of Dart params.
  JS.Fun _simplifyPassThroughArrowFunCallBody(JS.Fun fn) {
    if (fn.body is JS.Block && fn.body.statements.length == 1) {
      var stat = fn.body.statements.single;
      if (stat is JS.Return && stat.value is JS.Call) {
        JS.Call call = stat.value;
        if (call.target is JS.ArrowFun && call.arguments.isEmpty) {
          JS.ArrowFun innerFun = call.target;
          if (innerFun.params.isEmpty) {
            return new JS.Fun(fn.params, innerFun.body,
                typeParams: fn.typeParams, returnType: fn.returnType);
          }
        }
      }
    }
    return fn;
  }

  JS.Method _emitTopLevelProperty(FunctionDeclaration node) {
    var name = node.name.name;
    return annotate(
        new JS.Method(
            _propertyName(name), _emitFunction(node.functionExpression),
            isGetter: node.isGetter, isSetter: node.isSetter),
        node,
        node.element);
  }

  bool _executesAtTopLevel(AstNode node) {
    var ancestor = node.getAncestor((n) =>
        n is FunctionBody ||
        (n is FieldDeclaration && n.staticKeyword == null) ||
        (n is ConstructorDeclaration && n.constKeyword == null));
    return ancestor == null;
  }

  bool _typeIsLoaded(DartType type) {
    if (type is FunctionType && (type.name == '' || type.name == null)) {
      return (_typeIsLoaded(type.returnType) &&
          type.optionalParameterTypes.every(_typeIsLoaded) &&
          type.namedParameterTypes.values.every(_typeIsLoaded) &&
          type.normalParameterTypes.every(_typeIsLoaded));
    }
    if (type.isDynamic || type.isVoid || type.isBottom) return true;
    if (type is ParameterizedType && !type.typeArguments.every(_typeIsLoaded)) {
      return false;
    }
    return !_declarationNodes.containsKey(type.element);
  }

  JS.Expression _emitFunctionTagged(JS.Expression fn, DartType type,
      {topLevel: false}) {
    var lazy = topLevel && !_typeIsLoaded(type);
    var typeRep = _emitFunctionType(type, definite: true);
    if (lazy) {
      return _callHelper('lazyFn(#, () => #)', [fn, typeRep]);
    } else {
      return _callHelper('fn(#, #)', [fn, typeRep]);
    }
  }

  /// Emits an arrow FunctionExpression node.
  ///
  /// This should be used for all places in Dart's AST where FunctionExpression
  /// appears and the function is actually in an Expression context. These
  /// correspond to arrow functions in Dart.
  ///
  /// Contrast with [_emitFunction].
  @override
  JS.Expression visitFunctionExpression(FunctionExpression node) {
    assert(node.parent is! FunctionDeclaration &&
        node.parent is! MethodDeclaration);
    return _emitFunctionTagged(_emitArrowFunction(node), getStaticType(node),
        topLevel: _executesAtTopLevel(node));
  }

  JS.ArrowFun _emitArrowFunction(FunctionExpression node) {
    JS.Fun fn = _emitFunctionBody(node.element, node.parameters, node.body);

    return annotate(_toArrowFunction(fn), node);
  }

  JS.Fun _makeGenericFunction(JS.Fun fn) {
    if (fn.typeParams == null || fn.typeParams.isEmpty) return fn;

    return new JS.Fun(
        fn.typeParams,
        new JS.Block([
          // Convert the function to an => function, to ensure `this` binding.
          _toArrowFunction(fn).toReturn()
        ]));
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

  /// Emits a non-arrow FunctionExpression node.
  ///
  /// This should be used for all places in Dart's AST where FunctionExpression
  /// appears but the function is not actually in an Expression context, such
  /// as methods, properties, and top-level functions.
  ///
  /// Contrast with [visitFunctionExpression].
  JS.Fun _emitFunction(FunctionExpression node) {
    return annotate(
        _emitFunctionBody(node.element, node.parameters, node.body), node);
  }

  JS.Fun _emitFunctionBody(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    FunctionType type = element.type;

    // normal function (sync), vs (sync*, async, async*)
    var stdFn = !(element.isAsynchronous || element.isGenerator);
    var formals = _emitFormalParameterList(parameters, destructure: stdFn);
    JS.Block code = stdFn
        ? _visit(body)
        : new JS.Block(
            [_emitGeneratorFunctionBody(element, parameters, body).toReturn()]);
    var typeFormals = _emitTypeFormals(type.typeFormals);

    var returnType = emitTypeRef(type.returnType);
    if (type.typeFormals.isNotEmpty) {
      var block = <JS.Statement>[
        new JS.Block(_typeTable.discharge(type.typeFormals))
      ];

      var covariantParams = _classProperties?.covariantParameters;
      if (covariantParams != null &&
          type.typeFormals.any(covariantParams.contains)) {
        block.add(js.statement('#.checkBounds(#);',
            [_emitType(type), new JS.ArrayInitializer(typeFormals)]));
      }

      code = new JS.Block(block..add(code));
    }

    if (element.isOperator && element.name == '[]=' && formals.isNotEmpty) {
      // []= methods need to return the value. We could also address this at
      // call sites, but it's cleaner to instead transform the operator method.
      code = _alwaysReturnLastParameter(code, formals.last);
    }

    if (body is BlockFunctionBody) {
      var params = element.parameters.map((e) => e.name).toSet();
      bool shadowsParam = body.block.statements.any((s) =>
          s is VariableDeclarationStatement &&
          s.variables.variables.any((v) => params.contains(v.name.name)));
      if (shadowsParam) {
        code = new JS.Block([
          new JS.Block([code], isScope: true)
        ]);
      }
    }

    return _makeGenericFunction(new JS.Fun(formals, code,
        typeParams: typeFormals, returnType: returnType));
  }

  JS.Expression _emitGeneratorFunctionBody(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    var kind = element.isSynchronous ? 'sync' : 'async';
    if (element.isGenerator) kind += 'Star';

    // Transforms `sync*` `async` and `async*` function bodies
    // using ES6 generators.
    //
    // `sync*` wraps a generator in a Dart Iterable<T>:
    //
    // function name(<args>) {
    //   return dart.syncStar(function*(<args>) {
    //     <body>
    //   }, T, <args>).bind(this);
    // }
    //
    // We need to include <args> in case any are mutated, so each `.iterator`
    // gets the same initial values.
    //
    // TODO(jmesserly): we could omit the args for the common case where args
    // are not mutated inside the generator.
    //
    // In the future, we might be able to simplify this, see:
    // https://github.com/dart-lang/sdk/issues/28320
    // `async` works the same, but uses the `dart.async` helper.
    //
    // In the body of a `sync*` and `async`, `yield`/`await` are both generated
    // simply as `yield`.
    //
    // `async*` uses the `dart.asyncStar` helper, and also has an extra `stream`
    // argument to the generator, which is used for passing values to the
    // _AsyncStarStreamController implementation type.
    // `yield` is specially generated inside `async*`, see visitYieldStatement.
    // `await` is generated as `yield`.
    // runtime/_generators.js has an example of what the code is generated as.
    var savedController = _asyncStarController;
    var jsParams = _emitFormalParameterList(parameters);
    if (kind == 'asyncStar') {
      _asyncStarController = new JS.TemporaryId('stream');
      jsParams.insert(0, _asyncStarController);
    } else {
      _asyncStarController = null;
    }
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    // Visit the body with our async* controller set.
    var jsBody = _visit(body);
    _superAllowed = savedSuperAllowed;
    _asyncStarController = savedController;

    DartType returnType = _getExpectedReturnType(element);
    JS.Expression gen = new JS.Fun(jsParams, jsBody,
        isGenerator: true, returnType: emitTypeRef(returnType));
    if (JS.This.foundIn(gen)) {
      gen = js.call('#.bind(this)', gen);
    }

    var T = _emitType(returnType);
    return _callHelper('#(#)', [
      kind,
      [gen, T]..addAll(_emitFormalParameterList(parameters, destructure: false))
    ]);
  }

  @override
  JS.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      return js.comment('Unimplemented function get/set statement: $node');
    }

    var fn = _emitFunction(func.functionExpression);

    var name = new JS.Identifier(func.name.name);
    JS.Statement declareFn;
    if (JS.This.foundIn(fn)) {
      declareFn = js.statement('const # = #.bind(this);', [name, fn]);
    } else {
      declareFn = new JS.FunctionDeclaration(name, fn);
    }
    declareFn = annotate(declareFn, node, node.functionDeclaration.element);

    return new JS.Block([
      declareFn,
      _emitFunctionTagged(name,
              resolutionMap.elementDeclaredByFunctionDeclaration(func).type)
          .toStatement()
    ]);
  }

  /// Emits a simple identifier, including handling an inferred generic
  /// function instantiation.
  @override
  JS.Expression visitSimpleIdentifier(SimpleIdentifier node) {
    var typeArgs = _getTypeArgs(node.staticElement, node.staticType);
    var simpleId = _emitSimpleIdentifier(node);
    if (typeArgs == null) {
      return simpleId;
    }
    return _callHelper('gbind(#, #)', [simpleId, typeArgs]);
  }

  /// Emits a simple identifier, handling implicit `this` as well as
  /// going through the qualified library name if necessary, but *not* handling
  /// inferred generic function instantiation.
  JS.Expression _emitSimpleIdentifier(SimpleIdentifier node) {
    var accessor = resolutionMap.staticElementForIdentifier(node);
    if (accessor == null) {
      return _throwUnsafe('unresolved identifier: ' + (node.name ?? '<null>'));
    }

    // Get the original declaring element. If we had a property accessor, this
    // indirects back to a (possibly synthetic) field.
    var element = accessor;
    if (accessor is PropertyAccessorElement) element = accessor.variable;

    // type literal
    if (element is TypeDefiningElement) {
      _declareBeforeUse(element);

      var typeName = _emitType(fillDynamicTypeArgs(element.type));

      // If the type is a type literal expression in Dart code, wrap the raw
      // runtime type in a "Type" instance.
      if (!_isInForeignJS && _isTypeLiteral(node)) {
        typeName = _callHelper('wrapType(#)', typeName);
      }

      return typeName;
    }

    // library member
    if (element.enclosingElement is CompilationUnitElement) {
      return _emitTopLevelName(accessor);
    }

    var name = element.name;

    // Unqualified class member. This could mean implicit-this, or implicit
    // call to a static from the same class.
    if (element is ClassMemberElement && element is! ConstructorElement) {
      bool isStatic = element.isStatic;
      var type = element.enclosingElement.type;
      var member = _emitMemberName(name,
          isStatic: isStatic, type: type, element: accessor);

      if (isStatic) {
        var dynType = _emitStaticAccess(type);
        return new JS.PropertyAccess(dynType, member);
      }

      // For instance members, we add implicit-this.
      // For method tear-offs, we ensure it's a bound method.
      if (element is MethodElement &&
          !inInvocationContext(node) &&
          !_isJSNative(element.enclosingElement)) {
        return _callHelper('bind(this, #)', member);
      }
      return js.call('this.#', member);
    }

    if (element is ParameterElement) {
      return _emitParameter(element);
    }

    // If this is one of our compiler's temporary variables, return its JS form.
    if (element is TemporaryVariableElement) {
      return element.jsVariable;
    }

    return new JS.Identifier(name);
  }

  /// Returns `true` if the type name referred to by [node] is used in a
  /// position where it should evaluate as a type literal -- an object of type
  /// Type.
  bool _isTypeLiteral(SimpleIdentifier node) {
    var parent = node.parent;

    // Static member call.
    if (parent is MethodInvocation || parent is PropertyAccess) return false;

    // An expression like "a.b".
    if (parent is PrefixedIdentifier) {
      // In "a.b", "b" may be a type literal, but "a", is not.
      if (node != parent.identifier) return false;

      // If the prefix expression is itself used as an invocation, like
      // "a.b.c", then "b" is not a type literal.
      var grand = parent.parent;
      if (grand is MethodInvocation || grand is PropertyAccess) return false;

      return true;
    }

    // In any other context, it's a type literal.
    return true;
  }

  JS.Identifier _emitParameter(ParameterElement element,
      {bool declaration: false}) {
    // initializing formal parameter, e.g. `Point(this._x)`
    // TODO(jmesserly): type ref is not attached in this case.
    if (element.isInitializingFormal && element.isPrivate) {
      /// Rename private names so they don't shadow the private field symbol.
      /// The renamer would handle this, but it would prefer to rename the
      /// temporary used for the private symbol. Instead rename the parameter.
      return _initializingFormalTemps.putIfAbsent(
          element, () => new JS.TemporaryId(element.name.substring(1)));
    }

    var type = declaration ? emitTypeRef(element.type) : null;
    return new JS.Identifier(element.name, type: type);
  }

  List<Annotation> _parameterMetadata(FormalParameter p) =>
      (p is NormalFormalParameter)
          ? p.metadata
          : (p as DefaultFormalParameter).parameter.metadata;

  // Wrap a result - usually a type - with its metadata.  The runtime is
  // responsible for unpacking this.
  JS.Expression _emitAnnotatedResult(
      JS.Expression result, List<Annotation> metadata) {
    if (options.emitMetadata && metadata != null && metadata.isNotEmpty) {
      result = new JS.ArrayInitializer(
          [result]..addAll(metadata.map(_instantiateAnnotation)));
    }
    return result;
  }

  JS.Expression _emitAnnotatedType(DartType type, List<Annotation> metadata,
      {bool nameType: true}) {
    metadata ??= [];
    var typeName = _emitType(type, nameType: nameType);
    return _emitAnnotatedResult(typeName, metadata);
  }

  JS.Expression _emitFieldSignature(DartType type,
      {List<Annotation> metadata, bool isFinal: true}) {
    var args = [_emitType(type)];
    if (options.emitMetadata && metadata != null && metadata.isNotEmpty) {
      args.add(new JS.ArrayInitializer(
          metadata.map(_instantiateAnnotation).toList()));
    }
    return _callHelper(isFinal ? 'finalFieldType(#)' : 'fieldType(#)', [args]);
  }

  JS.ArrayInitializer _emitTypeNames(
      List<DartType> types, List<FormalParameter> parameters,
      {bool nameType: true}) {
    var result = <JS.Expression>[];
    for (int i = 0; i < types.length; ++i) {
      var metadata = parameters != null
          ? _parameterMetadata(parameters[i])
          : <Annotation>[];
      result.add(_emitAnnotatedType(types[i], metadata));
    }
    return new JS.ArrayInitializer(result);
  }

  JS.ObjectInitializer _emitTypeProperties(Map<String, DartType> types) {
    var properties = <JS.Property>[];
    types.forEach((name, type) {
      var key = _propertyName(name);
      var value = _emitType(type);
      properties.add(new JS.Property(key, value));
    });
    return new JS.ObjectInitializer(properties);
  }

  /// Emit the pieces of a function type, as an array of return type,
  /// regular args, and optional/named args.
  JS.Expression _emitFunctionType(FunctionType type,
      {List<FormalParameter> parameters,
      bool lowerTypedef: false,
      bool nameType: true,
      definite: false}) {
    var parameterTypes = type.normalParameterTypes;
    var optionalTypes = type.optionalParameterTypes;
    var namedTypes = type.namedParameterTypes;
    var rt = _emitType(type.returnType, nameType: nameType);

    var ra = _emitTypeNames(parameterTypes, parameters, nameType: nameType);

    List<JS.Expression> typeParts;
    if (namedTypes.isNotEmpty) {
      assert(optionalTypes.isEmpty);
      // TODO(vsm): Pass in annotations here as well.
      var na = _emitTypeProperties(namedTypes);
      typeParts = [rt, ra, na];
    } else if (optionalTypes.isNotEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(
          optionalTypes, parameters?.sublist(parameterTypes.length),
          nameType: nameType);
      typeParts = [rt, ra, oa];
    } else {
      typeParts = [rt, ra];
    }

    JS.Expression fullType;
    var typeFormals = type.typeFormals;
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

      helperCall = definite ? 'gFnType(#)' : 'gFnTypeFuzzy(#)';
      // If any explicit bounds were passed, emit them.
      if (typeFormals.any((t) => t.bound != null)) {
        var bounds = typeFormals.map((t) => _emitType(t.type.bound)).toList();
        typeParts.add(addTypeFormalsAsParameters(bounds));
      }
    } else {
      helperCall = definite ? 'fnType(#)' : 'fnTypeFuzzy(#)';
    }
    fullType = _callHelper(helperCall, [typeParts]);
    if (!nameType) return fullType;
    return _typeTable.nameType(type, fullType, definite: definite);
  }

  JS.Expression _emitAnnotatedFunctionType(
      FunctionType type, List<Annotation> metadata,
      {List<FormalParameter> parameters,
      bool lowerTypedef: false,
      bool nameType: true,
      bool definite: false}) {
    var result = _emitFunctionType(type,
        parameters: parameters,
        lowerTypedef: lowerTypedef,
        nameType: nameType,
        definite: definite);
    return _emitAnnotatedResult(result, metadata);
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  ///
  /// If [nameType] is true, then the type will be named.  In addition,
  /// if [hoistType] is true, then the named type will be hoisted.
  JS.Expression _emitConstructorAccess(DartType type, {bool nameType: true}) {
    return _emitJSInterop(type.element) ?? _emitType(type, nameType: nameType);
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  JS.Expression _emitStaticAccess(DartType type) {
    // Make sure we aren't attempting to emit a static access path to a type
    // that does not have a valid static access path.
    assert(!type.isVoid &&
        !type.isDynamic &&
        !type.isBottom &&
        type is! TypeParameterType);

    // For statics, we add the raw type name, without generics or
    // library prefix. We don't need those because static calls can't use
    // the generic type.
    type = fillDynamicTypeArgs(type);
    var element = type.element;
    _declareBeforeUse(element);

    var interop = _emitJSInterop(element);
    if (interop != null) return interop;

    assert(type.name != '' && type.name != null);

    return _emitTopLevelNameNoInterop(element);
  }

  /// Emits a Dart [type] into code.
  ///
  /// If [lowerTypedef] is set, a typedef will be expanded as if it were a
  /// function type. Similarly if [lowerGeneric] is set, the `List$()` form
  /// will be used instead of `List`. These flags are used when generating
  /// the definitions for typedefs and generic types, respectively.
  ///
  /// If [subClass] is set, then we are setting the base class for the given
  /// class and should emit the given [className], which will already be
  /// defined.
  ///
  /// If [nameType] is true, then the type will be named.  In addition,
  /// if [hoistType] is true, then the named type will be hoisted.
  JS.Expression _emitType(DartType type,
      {bool lowerTypedef: false,
      bool lowerGeneric: false,
      bool nameType: true,
      ClassElement subClass,
      JS.Expression className}) {
    // The void and dynamic types are not defined in core.
    if (type.isVoid) {
      return _callHelper('void');
    } else if (type.isDynamic) {
      return _callHelper('dynamic');
    } else if (type.isBottom) {
      return _callHelper('bottom');
    }

    var element = type.element;
    if (element is TypeDefiningElement) {
      _declareBeforeUse(element);
    }

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
    if (_isObjectLiteral(element)) {
      return _callHelper('anonymousJSType(#)', js.escapedString(element.name));
    }
    var jsName = _getJSNameWithoutGlobal(element);
    if (jsName != null) {
      return _callHelper('lazyJSType(() => #, #)',
          [_emitJSInteropForGlobal(jsName), js.escapedString(jsName)]);
    }

    // TODO(jmesserly): like constants, should we hoist function types out of
    // methods? Similar issue with generic types. For all of these, we may want
    // to canonicalize them too, at least when inside the same library.
    var name = type.name;
    if (name == '' || name == null || lowerTypedef) {
      // TODO(jmesserly): should we change how typedefs work? They currently
      // go through use similar logic as generic classes. This makes them
      // different from universal function types.
      return _emitFunctionType(type as FunctionType,
          lowerTypedef: lowerTypedef, nameType: nameType);
    }

    if (type is TypeParameterType) {
      _typeParamInConst?.add(type);
      return new JS.Identifier(name);
    }

    if (type == subClass?.type) return className;

    if (type is ParameterizedType) {
      var args = type.typeArguments;
      Iterable jsArgs = null;
      if (args.any((a) => !a.isDynamic)) {
        jsArgs = args.map((x) => _emitType(x,
            nameType: nameType, subClass: subClass, className: className));
      } else if (lowerGeneric || element == subClass) {
        jsArgs = [];
      }
      if (jsArgs != null) {
        var genericName = _emitTopLevelNameNoInterop(element, suffix: '\$');
        var typeRep = js.call('#(#)', [genericName, jsArgs]);
        return nameType ? _typeTable.nameType(type, typeRep) : typeRep;
      }
    }

    return _emitTopLevelNameNoInterop(element);
  }

  JS.PropertyAccess _emitTopLevelName(Element e, {String suffix: ''}) {
    return _emitJSInterop(e) ?? _emitTopLevelNameNoInterop(e, suffix: suffix);
  }

  JS.PropertyAccess _emitTopLevelNameNoInterop(Element e, {String suffix: ''}) {
    var name = getJSExportName(e) ?? _getElementName(e);
    return new JS.PropertyAccess(
        emitLibraryName(e.library), _propertyName(name + suffix));
  }

  @override
  JS.Expression visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;
    if (node.operator.type == TokenType.EQ) return _emitSet(left, right);
    var op = node.operator.lexeme;
    assert(op.endsWith('='));
    op = op.substring(0, op.length - 1); // remove trailing '='
    return _emitOpAssign(left, right, op, node.staticElement, context: node);
  }

  JS.MetaLet _emitOpAssign(
      Expression left, Expression right, String op, MethodElement element,
      {Expression context}) {
    if (op == '??') {
      // Desugar `l ??= r` as ((x) => x == null ? l = r : x)(l)
      // Note that if `x` contains subexpressions, we need to ensure those
      // are also evaluated only once. This is similar to desugaring for
      // postfix expressions like `i++`.

      // Handle the left hand side, to ensure each of its subexpressions are
      // evaluated only once.
      var vars = <JS.MetaLetVariable, JS.Expression>{};
      var x = _bindLeftHandSide(vars, left, context: left);
      // Capture the result of evaluating the left hand side in a temp.
      var t = _bindValue(vars, 't', x, context: x);
      return new JS.MetaLet(vars, [
        js.call('# == null ? # : #', [_visit(t), _emitSet(x, right), _visit(t)])
      ]);
    }

    // Desugar `x += y` as `x = x + y`, ensuring that if `x` has subexpressions
    // (for example, x is IndexExpression) we evaluate those once.
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var lhs = _bindLeftHandSide(vars, left, context: context);
    // TODO(leafp): The element for lhs here will be the setter element
    // instead of the getter element if lhs is a property access. This
    // interferes with nullability analysis.
    Expression inc = AstBuilder.binaryExpression(lhs, op, right)
      ..staticElement = element
      ..staticType = getStaticType(lhs);

    var castTo = getImplicitOperationCast(left);
    if (castTo != null) inc = CoercionReifier.castExpression(inc, castTo);
    return new JS.MetaLet(vars, [_emitSet(lhs, inc)]);
  }

  JS.Expression _emitSet(Expression left, Expression right) {
    if (left is IndexExpression) {
      var target = _getTarget(left);
      if (_useNativeJsIndexer(target.staticType)) {
        return js.call(
            '#[#] = #', [_visit(target), _visit(left.index), _visit(right)]);
      }
      return _emitSend(target, '[]=', [left.index, right]);
    }

    if (left is SimpleIdentifier) {
      return _emitSetSimpleIdentifier(left, right);
    }

    Expression target = null;
    SimpleIdentifier id;
    if (left is PropertyAccess) {
      if (left.operator.lexeme == '?.') {
        return _emitNullSafeSet(left, right);
      }
      target = _getTarget(left);
      id = left.propertyName;
    } else if (left is PrefixedIdentifier) {
      if (isLibraryPrefix(left.prefix)) {
        return _emitSet(left.identifier, right);
      }
      target = left.prefix;
      id = left.identifier;
    } else {
      assert(false);
    }

    if (isDynamicInvoke(target)) {
      return _callHelper('#(#, #, #)', [
        _emitDynamicOperationName('dput'),
        _visit(target),
        _emitMemberName(id.name),
        _visit(right)
      ]);
    }

    var accessor = id.staticElement;
    if (accessor is PropertyAccessorElement) {
      var field = accessor.variable;
      if (field is FieldElement) {
        return _emitSetField(left, right, field, _visit(target));
      }
    }

    return _badAssignment('Unhandled assignment', left, right);
  }

  JS.Expression _badAssignment(String problem, Expression lhs, Expression rhs) {
    // TODO(sra): We should get here only for compiler bugs or weirdness due to
    // --unsafe-force-compile. Once those paths have been addressed, throw at
    // compile time.
    return _callHelper('throwUnimplementedError((#, #, #))',
        [js.string('$lhs ='), _visit(rhs), js.string(problem)]);
  }

  /// Emits assignment to a simple identifier. Handles all legal simple
  /// identifier assignment targets (local, top level library member, implicit
  /// `this` or class, etc.)
  JS.Expression _emitSetSimpleIdentifier(
      SimpleIdentifier node, Expression right) {
    JS.Expression unimplemented() {
      return _badAssignment("Unimplemented: unknown name '$node'", node, right);
    }

    var accessor = resolutionMap.staticElementForIdentifier(node);
    if (accessor == null) return unimplemented();

    // Get the original declaring element. If we had a property accessor, this
    // indirects back to a (possibly synthetic) field.
    var element = accessor;
    if (accessor is PropertyAccessorElement) element = accessor.variable;

    if (element is TypeDefiningElement) {
      _declareBeforeUse(element);
    }

    if (element is LocalVariableElement || element is ParameterElement) {
      return _emitSetLocal(node, element, right);
    }

    if (element.enclosingElement is CompilationUnitElement) {
      // Top level library member.
      return _emitSetTopLevel(node, accessor, right);
    }

    // Unqualified class member. This could mean implicit `this`, or implicit
    // static from the same class.
    if (element is FieldElement) {
      return _emitSetField(node, right, element, new JS.This());
    }

    // We should not get here.
    return unimplemented();
  }

  /// Emits assignment to a simple local variable or parameter.
  JS.Expression _emitSetLocal(
      SimpleIdentifier node, Element element, Expression rhs) {
    JS.Expression target;
    if (element is TemporaryVariableElement) {
      // If this is one of our compiler's temporary variables, use its JS form.
      target = element.jsVariable;
    } else if (element is ParameterElement) {
      target = _emitParameter(element);
    } else {
      target = new JS.Identifier(element.name);
    }

    return _visit<JS.Expression>(rhs)
        .toAssignExpression(annotate(target, node));
  }

  /// Emits assignment to library scope element [element].
  JS.Expression _emitSetTopLevel(
      Expression lhs, PropertyAccessorElement element, Expression rhs) {
    return _visit<JS.Expression>(rhs)
        .toAssignExpression(annotate(_emitTopLevelName(element), lhs));
  }

  /// Emits assignment to a static field element or property.
  JS.Expression _emitSetField(Expression left, Expression right,
      FieldElement field, JS.Expression jsTarget) {
    var type = field.enclosingElement.type;
    var isStatic = field.isStatic;
    var member = _emitMemberName(field.name,
        isStatic: isStatic, type: type, element: field.setter);
    jsTarget = isStatic
        ? new JS.PropertyAccess(_emitStaticAccess(type), member)
        : _emitTargetAccess(jsTarget, member, field.setter);
    return _visit<JS.Expression>(right)
        .toAssignExpression(annotate(jsTarget, left));
  }

  JS.Expression _emitNullSafeSet(PropertyAccess node, Expression right) {
    // Emit `obj?.prop = expr` as:
    //
    //     (_ => _ == null ? null : _.prop = expr)(obj).
    //
    // We could use a helper, e.g.:  `nullSafeSet(e1, _ => _.v = e2)`
    //
    // However with MetaLet, we get clean code in statement or void context,
    // or when one of the expressions is stateless, which seems common.
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var left = _bindValue(vars, 'l', node.target);
    var body = js.call('# == null ? null : #',
        [_visit(left), _emitSet(_stripNullAwareOp(node, left), right)]);
    return new JS.MetaLet(vars, [body]);
  }

  @override
  JS.Block visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var savedFunction = _currentFunction;
    _currentFunction = node;
    var initArgs = _emitArgumentInitializers(node.parent);
    var ret = annotate(
        _visit<JS.Expression>(node.expression).toReturn(), node.expression);
    _currentFunction = savedFunction;
    var _statements = initArgs != null ? [initArgs, ret] : [ret];
    var block = annotate(new JS.Block(_statements), node);
    return block;
  }

  @override
  JS.Block visitEmptyFunctionBody(EmptyFunctionBody node) => new JS.Block([]);

  @override
  JS.Block visitBlockFunctionBody(BlockFunctionBody node) {
    var savedFunction = _currentFunction;
    _currentFunction = node;
    var initArgs = _emitArgumentInitializers(node.parent);
    var stmts = _visitList<JS.Statement>(node.block.statements);
    if (initArgs != null) stmts.insert(0, initArgs);
    _currentFunction = savedFunction;
    return new JS.Block(stmts);
  }

  @override
  JS.Block visitBlock(Block node) =>
      new JS.Block(_visitList(node.statements), isScope: true);

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (_isDeferredLoadLibrary(node.target, node.methodName)) {
      // We are calling loadLibrary() on a deferred library prefix.
      return _callHelper('loadLibrary()');
    }

    if (node.operator?.lexeme == '?.') {
      return _emitNullSafe(node);
    }

    var result = _emitForeignJS(node);
    if (result != null) return result;

    var target = _getTarget(node);
    if (target == null || isLibraryPrefix(target)) {
      return _emitFunctionCall(node);
    }
    if (node.methodName.name == 'call') {
      var targetType = resolutionMap.staticTypeForExpression(target);
      if (targetType is FunctionType) {
        // Call methods on function types should be handled as regular function
        // invocations.
        return _emitFunctionCall(node, node.target);
      }
      if (targetType.isDartCoreFunction || targetType.isDynamic) {
        // TODO(vsm): Can a call method take generic type parameters?
        return _emitDynamicInvoke(
            node, _visit(target), _emitArgumentList(node.argumentList));
      }
    }

    return _emitMethodCall(target, node);
  }

  JS.Expression _emitTarget(Expression target, Element member, bool isStatic) {
    if (isStatic) {
      if (member is ConstructorElement) {
        return _emitConstructorAccess(member.enclosingElement.type);
      }
      if (member is PropertyAccessorElement) {
        var field = member.variable;
        if (field is FieldElement) {
          return _emitStaticAccess(field.enclosingElement.type);
        }
      }
      if (member is MethodElement) {
        return _emitStaticAccess(member.enclosingElement.type);
      }
    }
    return _visit(target);
  }

  /// Emits the [JS.PropertyAccess] for accessors or method calls to
  /// [jsTarget].[jsName], replacing `super` if it is not allowed in scope.
  JS.Expression _emitTargetAccess(
      JS.Expression jsTarget, JS.Expression jsName, Element member) {
    if (!_superAllowed && jsTarget is JS.Super) {
      return _getSuperHelper(member, jsName)
        ..sourceInformation = jsTarget.sourceInformation;
    }
    return new JS.PropertyAccess(jsTarget, jsName);
  }

  JS.Expression _getSuperHelper(Element member, JS.Expression jsName) {
    var jsMethod = _superHelpers.putIfAbsent(member.name, () {
      if (member is PropertyAccessorElement) {
        var isSetter = member.isSetter;
        var fn = js.call(
            isSetter
                ? 'function(x) { super[#] = x; }'
                : 'function() { return super[#]; }',
            [jsName]);
        return new JS.Method(new JS.TemporaryId(member.variable.name), fn,
            isGetter: !isSetter, isSetter: isSetter);
      } else {
        var method = member as MethodElement;
        var name = method.name;
        // For generic methods, we can simply pass along the type arguments,
        // and let the resulting closure accept the actual arguments.
        List<JS.Identifier> params;
        if (method.typeParameters.isNotEmpty) {
          params = _emitTypeFormals(method.typeParameters);
        } else {
          params = [];
          for (var param in method.parameters) {
            if (param.parameterKind == ParameterKind.NAMED) {
              params.add(namedArgumentTemp);
              break;
            }
            params.add(new JS.Identifier(param.name));
          }
        }
        var fn = js.call(
            'function(#) { return super[#](#); }', [params, jsName, params]);
        return new JS.Method(new JS.TemporaryId(name), fn);
      }
    });
    return new JS.PropertyAccess(new JS.This(), jsMethod.name);
  }

  JS.Expression _emitMethodCall(Expression target, MethodInvocation node) {
    var args = _emitArgumentList(node.argumentList);
    var typeArgs = _emitInvokeTypeArguments(node);

    var type = getStaticType(target);
    var element = node.methodName.staticElement;
    bool isStatic = element is ExecutableElement && element.isStatic;
    var name = node.methodName.name;
    var jsName =
        _emitMemberName(name, type: type, isStatic: isStatic, element: element);

    JS.Expression jsTarget = _emitTarget(target, element, isStatic);
    if (isDynamicInvoke(target) || isDynamicInvoke(node.methodName)) {
      if (typeArgs != null) {
        return _callHelper('#(#, #, #, #)', [
          _emitDynamicOperationName('dgsend'),
          jsTarget,
          new JS.ArrayInitializer(typeArgs),
          jsName,
          args
        ]);
      } else {
        return _callHelper('#(#, #, #)',
            [_emitDynamicOperationName('dsend'), jsTarget, jsName, args]);
      }
    }
    if (_isObjectMemberCall(target, name)) {
      assert(typeArgs == null); // Object methods don't take type args.
      return _callHelper('#(#, #)', [name, jsTarget, args]);
    }
    jsTarget = _emitTargetAccess(jsTarget, jsName, element);
    var castTo = getImplicitOperationCast(node);
    if (castTo != null) {
      jsTarget = js.call('#._check(#)', [_emitType(castTo), jsTarget]);
    }
    if (typeArgs != null) jsTarget = new JS.Call(jsTarget, typeArgs);
    return new JS.Call(jsTarget, args);
  }

  JS.Expression _emitDynamicInvoke(
      InvocationExpression node, JS.Expression fn, List<JS.Expression> args) {
    var typeArgs = _emitInvokeTypeArguments(node);
    if (typeArgs != null) {
      return _callHelper(
          'dgcall(#, #, #)', [fn, new JS.ArrayInitializer(typeArgs), args]);
    } else {
      return _callHelper('dcall(#, #)', [fn, args]);
    }
  }

  bool _doubleEqIsIdentity(Expression left, Expression right) {
    // If we statically know LHS or RHS is null we can use ==.
    if (_isNull(left) || _isNull(right)) return true;
    // If the representation of the  two types will not induce conversion in
    // JS then we can use == .
    return !typeRep.equalityMayConvert(left.staticType, right.staticType);
  }

  bool _tripleEqIsIdentity(Expression left, Expression right) {
    // If either is non-nullable, then we don't need to worry about
    // equating null and undefined, and so we can use triple equals.
    return !isNullable(left) || !isNullable(right);
  }

  bool _isCoreIdentical(Expression node) {
    return node is Identifier && node.staticElement == _coreIdentical;
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

  JS.Expression _emitCoreIdenticalCall(List<Expression> arguments,
      {bool negated = false}) {
    if (arguments.length != 2) {
      // Shouldn't happen in typechecked code
      return _callHelper(
          'throw(Error("compile error: calls to `identical` require 2 args")');
    }
    var left = arguments[0];
    var right = arguments[1];
    var args = [_visit(left), _visit(right)];
    if (_tripleEqIsIdentity(left, right)) {
      return _emitJSTripleEq(args, negated: negated);
    }
    if (_doubleEqIsIdentity(left, right)) {
      return _emitJSDoubleEq(args, negated: negated);
    }
    var code = negated ? '!#' : '#';
    return js.call(code, new JS.Call(_emitTopLevelName(_coreIdentical), args));
  }

  /// Emits a function call, to a top-level function, local function, or
  /// an expression.
  JS.Expression _emitFunctionCall(InvocationExpression node,
      [Expression function]) {
    function ??= node.function;
    var castTo = getImplicitOperationCast(function);
    if (castTo != null) {
      function = CoercionReifier.castExpression(function, castTo);
    }
    if (_isCoreIdentical(function)) {
      return _emitCoreIdenticalCall(node.argumentList.arguments);
    }
    var fn = _visit(function);
    var args = _emitArgumentList(node.argumentList);
    if (isDynamicInvoke(function)) {
      return _emitDynamicInvoke(node, fn, args);
    }
    return new JS.Call(_applyInvokeTypeArguments(fn, node), args);
  }

  JS.Expression _applyInvokeTypeArguments(
      JS.Expression target, InvocationExpression node) {
    var typeArgs = _emitInvokeTypeArguments(node);
    if (typeArgs == null) return target;
    return new JS.Call(target, typeArgs);
  }

  List<JS.Expression> _emitInvokeTypeArguments(InvocationExpression node) {
    return _emitFunctionTypeArguments(
        node.function.staticType, node.staticInvokeType, node.typeArguments);
  }

  /// If `g` is a generic function type, and `f` is an instantiation of it,
  /// then this will return the type arguments to apply, otherwise null.
  List<JS.Expression> _emitFunctionTypeArguments(DartType g, DartType f,
      [TypeArgumentList typeArgs]) {
    if (g is FunctionType &&
        g.typeFormals.isNotEmpty &&
        f is FunctionType &&
        f.typeFormals.isEmpty) {
      return _recoverTypeArguments(g, f).map(_emitType).toList(growable: false);
    } else if (typeArgs != null) {
      // Dynamic calls may have type arguments, even though the function types
      // are not known.
      return typeArgs.arguments.map((argument) {
        if (argument is TypeName) {
          return visitTypeName(argument);
        } else {
          // TODO(brianwilkerson) Implement support for GenericFunctionType.
          throw new StateError(
              'Cannot compile type argument of kind ${argument.runtimeType}');
        }
      }).toList(growable: false);
    }
    return null;
  }

  /// Given a generic function type [g] and an instantiated function type [f],
  /// find a list of type arguments TArgs such that `g<TArgs> == f`,
  /// and return TArgs.
  ///
  /// This function must be called with type [f] that was instantiated from [g].
  Iterable<DartType> _recoverTypeArguments(FunctionType g, FunctionType f) {
    // TODO(jmesserly): this design is a bit unfortunate. It would be nice if
    // resolution could simply create a synthetic type argument list.
    assert(identical(g.element, f.element));
    assert(g.typeFormals.isNotEmpty && f.typeFormals.isEmpty);
    assert(g.typeFormals.length + g.typeArguments.length ==
        f.typeArguments.length);

    // Instantiation in Analyzer works like this:
    // Given:
    //     {U/T} <S> T -> S
    // Where {U/T} represents the typeArguments (U) and typeParameters (T) list,
    // and <S> represents the typeFormals.
    //
    // Now instantiate([V]), and the result should be:
    //     {U/T, V/S} T -> S.
    //
    // Therefore, we can recover the typeArguments from our instantiated
    // function.
    return f.typeArguments.skip(g.typeArguments.length);
  }

  /// Emits code for the `JS(...)` macro.
  _emitForeignJS(MethodInvocation node) {
    var e = node.methodName.staticElement;
    if (isInlineJS(e)) {
      var args = node.argumentList.arguments;
      // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
      var code = args[1];
      List<Expression> templateArgs;
      String source;
      if (code is StringInterpolation) {
        if (args.length > 2) {
          throw new ArgumentError(
              "Can't mix template args and string interpolation in JS calls.");
        }
        templateArgs = <Expression>[];
        source = code.elements.map((element) {
          if (element is InterpolationExpression) {
            templateArgs.add(element.expression);
            return '#';
          } else {
            return (element as InterpolationString).value;
          }
        }).join();
      } else {
        templateArgs = args.skip(2).toList();
        source = (code as StringLiteral).stringValue;
      }

      // TODO(vsm): Constructors in dart:html and friends are trying to
      // allocate a type defined on window/self, but this often conflicts a
      // with the generated extension class in scope.  We really should
      // qualify explicitly in dart:html itself.
      var constructorPattern = new RegExp("new [A-Z][A-Za-z]+\\(");
      if (constructorPattern.matchAsPrefix(source) != null) {
        var containingClass = node.parent;
        while (
            containingClass != null && containingClass is! ClassDeclaration) {
          containingClass = containingClass.parent;
        }
        if (containingClass is ClassDeclaration &&
            _extensionTypes.isNativeClass(containingClass.element)) {
          var constructorName = source.substring(4, source.indexOf('('));
          var className = containingClass.name.name;
          if (className == constructorName) {
            source =
                source.replaceFirst('new $className(', 'new self.$className(');
          }
        }
      }

      JS.Expression visitTemplateArg(Expression arg) {
        if (arg is InvocationExpression) {
          var e = arg is MethodInvocation
              ? arg.methodName.staticElement
              : (arg as FunctionExpressionInvocation).staticElement;
          if (e?.name == 'getGenericClass' &&
              e.library.name == 'dart._runtime' &&
              arg.argumentList.arguments.length == 1) {
            var typeArg = arg.argumentList.arguments[0];
            if (typeArg is SimpleIdentifier) {
              var typeElem = typeArg.staticElement;
              if (typeElem is TypeDefiningElement &&
                  typeElem.type is ParameterizedType) {
                return _emitTopLevelNameNoInterop(typeElem, suffix: '\$');
              }
            }
          }
        }
        return _visit(arg);
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
      assert(result is JS.Expression || node.parent is ExpressionStatement);
      return result;
    }
    return null;
  }

  @override
  JS.Expression visitFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      _emitFunctionCall(node);

  List<JS.Expression> _emitArgumentList(ArgumentList node) {
    var args = <JS.Expression>[];
    var named = <JS.Property>[];
    for (var arg in node.arguments) {
      if (arg is NamedExpression) {
        named.add(_visit(arg));
      } else if (arg is MethodInvocation && isJsSpreadInvocation(arg)) {
        args.add(
            new JS.RestParameter(_visit(arg.argumentList.arguments.single)));
      } else {
        args.add(_visit(arg));
      }
    }
    if (named.isNotEmpty) {
      args.add(new JS.ObjectInitializer(named));
    }
    return args;
  }

  @override
  JS.Property visitNamedExpression(NamedExpression node) {
    assert(node.parent is ArgumentList);
    return new JS.Property(
        _propertyName(node.name.label.name), _visit(node.expression));
  }

  List<JS.Parameter> _emitParametersForElement(ExecutableElement member) {
    var jsParams = <JS.Identifier>[];
    for (var p in member.parameters) {
      if (p.parameterKind != ParameterKind.NAMED) {
        jsParams.add(new JS.Identifier(p.name));
      } else {
        jsParams.add(new JS.TemporaryId('namedArgs'));
        break;
      }
    }
    return jsParams;
  }

  List<JS.Parameter> _emitFormalParameterList(FormalParameterList node,
      {bool destructure: true}) {
    if (node == null) return [];

    destructure = destructure && options.destructureNamedParams;

    var result = <JS.Parameter>[];
    var namedVars = <JS.DestructuredVariable>[];
    var hasNamedArgsConflictingWithObjectProperties = false;
    var needsOpts = false;

    for (FormalParameter param in node.parameters) {
      if (param.kind == ParameterKind.NAMED) {
        if (destructure) {
          if (_jsObjectProperties.contains(param.identifier.name)) {
            hasNamedArgsConflictingWithObjectProperties = true;
          }
          JS.Expression name;
          JS.SimpleBindingPattern structure = null;
          String paramName = param.identifier.name;
          if (JS.invalidVariableName(paramName)) {
            name = js.string(paramName);
            structure = new JS.SimpleBindingPattern(_visit(param.identifier));
          } else {
            name = _visit(param.identifier);
          }
          namedVars.add(new JS.DestructuredVariable(
              name: name,
              structure: structure,
              defaultValue: _defaultParamValue(param)));
        } else {
          needsOpts = true;
        }
      } else {
        var jsParam = _visit(param);
        result.add(param is DefaultFormalParameter && destructure
            ? new JS.DestructuredVariable(
                name: jsParam, defaultValue: _defaultParamValue(param))
            : jsParam);
      }
    }

    if (needsOpts) {
      result.add(namedArgumentTemp);
    } else if (namedVars.isNotEmpty) {
      // Note: `var {valueOf} = {}` extracts `Object.prototype.valueOf`, so
      // in case there are conflicting names we create an object without
      // any prototype.
      var defaultOpts = hasNamedArgsConflictingWithObjectProperties
          ? js.call('Object.create(null)')
          : js.call('{}');
      result.add(new JS.DestructuredVariable(
          structure: new JS.ObjectBindingPattern(namedVars),
          type: emitNamedParamsArgType(node.parameterElements),
          defaultValue: defaultOpts));
    }
    return result;
  }

  /// See ES6 spec (and `Object.getOwnPropertyNames(Object.prototype)`):
  /// http://www.ecma-international.org/ecma-262/6.0/#sec-properties-of-the-object-prototype-object
  /// http://www.ecma-international.org/ecma-262/6.0/#sec-additional-properties-of-the-object.prototype-object
  static final Set<String> _jsObjectProperties = new Set<String>()
    ..addAll([
      "constructor",
      "toString",
      "toLocaleString",
      "valueOf",
      "hasOwnProperty",
      "isPrototypeOf",
      "propertyIsEnumerable",
      "__defineGetter__",
      "__lookupGetter__",
      "__defineSetter__",
      "__lookupSetter__",
      "__proto__"
    ]);

  @override
  JS.Statement visitExpressionStatement(ExpressionStatement node) =>
      _visit(node.expression).toStatement();

  @override
  JS.EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      new JS.EmptyStatement();

  @override
  JS.Statement visitAssertStatement(AssertStatement node) {
    // TODO(jmesserly): only emit in checked mode.
    var condition = node.condition;
    var conditionType = condition.staticType;
    JS.Expression jsCondition = _visit(condition);

    if (conditionType is FunctionType &&
        conditionType.parameters.isEmpty &&
        conditionType.returnType == types.boolType) {
      jsCondition = _callHelper('test(#())', jsCondition);
    } else if (conditionType != types.boolType) {
      jsCondition = _callHelper('dassert(#)', jsCondition);
    } else if (isNullable(condition)) {
      jsCondition = _callHelper('test(#)', jsCondition);
    }
    return js.statement(' if (!#) #.assertFailed(#);', [
      jsCondition,
      _runtimeModule,
      node.message != null ? [_visit(node.message)] : []
    ]);
  }

  @override
  JS.Statement visitReturnStatement(ReturnStatement node) {
    var e = node.expression;
    if (e == null) return new JS.Return();
    return _visit<JS.Expression>(e).toReturn();
  }

  @override
  JS.Statement visitYieldStatement(YieldStatement node) {
    JS.Expression jsExpr = _visit(node.expression);
    var star = node.star != null;
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
  JS.Expression visitAwaitExpression(AwaitExpression node) {
    return new JS.Yield(_visit(node.expression));
  }

  /// This is not used--we emit top-level fields as we are emitting the
  /// compilation unit, see [_emitCompilationUnit].
  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    assert(false);
  }

  /// This is not used--we emit fields as we are emitting the class,
  /// see [visitClassDeclaration].
  @override
  visitFieldDeclaration(FieldDeclaration node) {
    assert(false);
  }

  @override
  JS.Statement visitVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    // Special case a single variable with an initializer.
    // This helps emit cleaner code for things like:
    //     var result = []..add(1)..add(2);
    var variables = node.variables.variables;
    if (variables.length == 1) {
      var v = variables[0];
      if (v.initializer != null) {
        var name = new JS.Identifier(v.name.name);
        var value = _annotatedNullCheck(v.element)
            ? notNull(v.initializer)
            : _visit<JS.Expression>(v.initializer);
        return value.toVariableDeclaration(name);
      }
    }
    return _visit<JS.Expression>(node.variables).toStatement();
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    return new JS.VariableDeclarationList('let', _visitList(node.variables));
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.element is PropertyInducingElement) {
      // All fields are handled elsewhere.
      assert(false);
      return null;
    }

    var name = new JS.Identifier(node.name.name,
        type: emitTypeRef(
            resolutionMap.elementDeclaredByVariableDeclaration(node).type));
    return new JS.VariableInitialization(name, _visitInitializer(node));
  }

  /// Emits a list of top-level field.
  void _emitTopLevelFields(List<VariableDeclaration> fields) {
    _moduleItems.add(_emitLazyFields(currentLibrary, fields));
  }

  /// Treat dart:_runtime fields as safe to eagerly evaluate.
  // TODO(jmesserly): it'd be nice to avoid this special case.
  void _emitInternalSdkFields(List<VariableDeclaration> fields) {
    for (var field in fields) {
      _moduleItems.add(annotate(
          js.statement('# = #;',
              [_emitTopLevelName(field.element), _visitInitializer(field)]),
          field,
          field.element));
    }
  }

  JS.Expression _visitInitializer(VariableDeclaration node) {
    var value = _annotatedNullCheck(node.element)
        ? notNull(node.initializer)
        : _visit(node.initializer);
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    return value ?? new JS.LiteralNull();
  }

  JS.Statement _emitLazyFields(
      Element target, List<VariableDeclaration> fields) {
    var methods = [];
    for (var node in fields) {
      var name = node.name.name;
      var element = node.element;
      assert(element.getAncestor((e) => identical(e, target)) != null,
          "target is $target but enclosing element is ${element.enclosingElement}");
      var access = _emitMemberName(name, isStatic: true);
      methods.add(annotate(
          new JS.Method(
              access,
              js.call('function() { return #; }', _visitInitializer(node))
                  as JS.Fun,
              isGetter: true),
          node,
          _findAccessor(element, getter: true)));

      // TODO(jmesserly): currently uses a dummy setter to indicate writable.
      if (!node.isFinal && !node.isConst) {
        methods.add(annotate(
            new JS.Method(access, js.call('function(_) {}') as JS.Fun,
                isSetter: true),
            node,
            _findAccessor(element, getter: false)));
      }
    }

    var objExpr = target is ClassElement
        ? _emitTopLevelName(target)
        : emitLibraryName(target);

    return _callHelperStatement('defineLazy(#, { # });', [objExpr, methods]);
  }

  PropertyAccessorElement _findAccessor(VariableElement element,
      {bool getter}) {
    var parent = element.enclosingElement;
    if (parent is ClassElement) {
      return getter
          ? parent.getGetter(element.name)
          : parent.getSetter(element.name);
    }
    return null;
  }

  JS.Expression _emitConstructorName(
      ConstructorElement element, DartType type, SimpleIdentifier name) {
    return _emitJSInterop(type.element) ??
        new JS.PropertyAccess(
            _emitConstructorAccess(type), _constructorName(element));
  }

  @override
  visitConstructorName(ConstructorName node) {
    return _emitConstructorName(node.staticElement, node.type.type, node.name);
  }

  JS.Expression _emitInstanceCreationExpression(
      ConstructorElement element,
      DartType type,
      SimpleIdentifier name,
      ArgumentList argumentList,
      bool isConst) {
    JS.Expression emitNew() {
      JS.Expression ctor;
      bool isFactory = false;
      bool isNative = false;
      if (element == null) {
        ctor = _throwUnsafe('unresolved constructor: ${type?.name ?? '<null>'}'
            '.${name?.name ?? '<unnamed>'}');
      } else {
        ctor = _emitConstructorName(element, type, name);
        isFactory = element.isFactory;
        var classElem = element.enclosingElement;
        isNative = _isJSNative(classElem);
      }
      var args = _emitArgumentList(argumentList);
      // Native factory constructors are JS constructors - use new here.
      return isFactory && !isNative
          ? new JS.Call(ctor, args)
          : new JS.New(ctor, args);
    }

    if (element != null && _isObjectLiteral(element.enclosingElement)) {
      return _emitObjectLiteral(argumentList);
    }
    if (isConst) return _emitConst(emitNew);
    return emitNew();
  }

  bool _isObjectLiteral(Element classElem) {
    return _isJSNative(classElem) &&
        findAnnotation(classElem, isJSAnonymousAnnotation) != null;
  }

  bool _isJSNative(Element e) =>
      findAnnotation(e, isPublicJSAnnotation) != null;

  JS.Expression _emitObjectLiteral(ArgumentList argumentList) {
    var args = _emitArgumentList(argumentList);
    if (args.isEmpty) {
      return js.call('{}');
    }
    assert(args.single is JS.ObjectInitializer);
    return args.single;
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = resolutionMap.staticElementForConstructorReference(node);
    var constructor = node.constructorName;
    var name = constructor.name;
    var type = constructor.type.type;
    if (node.isConst &&
        element?.name == 'fromEnvironment' &&
        element.library.isDartCore) {
      var value = node.accept(_constants.constantVisitor);

      if (value == null || value.isNull) {
        return new JS.LiteralNull();
      }
      // Handle unknown value: when the declared variable wasn't found, and no
      // explicit default value was passed either.
      // TODO(jmesserly): ideally Analyzer would simply resolve this to the
      // default value that is specified in the SDK. Instead we implement that
      // here. `bool.fromEnvironment` defaults to `false`, the others to `null`:
      // https://api.dartlang.org/stable/1.20.1/dart-core/bool/bool.fromEnvironment.html
      if (value.isUnknown) {
        return type == types.boolType
            ? js.boolean(false)
            : new JS.LiteralNull();
      }
      if (value.type == types.boolType) {
        var boolValue = value.toBoolValue();
        return boolValue != null ? js.boolean(boolValue) : new JS.LiteralNull();
      }
      if (value.type == types.intType) {
        var intValue = value.toIntValue();
        return intValue != null ? js.number(intValue) : new JS.LiteralNull();
      }
      if (value.type == types.stringType) {
        var stringValue = value.toStringValue();
        return stringValue != null
            ? js.escapedString(stringValue)
            : new JS.LiteralNull();
      }
      throw new StateError('failed to evaluate $node');
    }
    return _emitInstanceCreationExpression(
        element, type, name, node.argumentList, node.isConst);
  }

  bool isPrimitiveType(DartType t) => typeRep.isPrimitive(t);

  /// Given a Dart type return the known implementation type, if any.
  /// Given `bool`, `String`, or `num`/`int`/`double`,
  /// returns the corresponding type in `dart:_interceptors`:
  /// `JSBool`, `JSString`, and `JSNumber` respectively, otherwise null.
  InterfaceType getImplementationType(DartType t) {
    JSType rep = typeRep.typeFor(t);
    // Number, String, and Bool are final
    if (rep == JSType.jsNumber) return _jsNumber.type;
    if (rep == JSType.jsBoolean) return _jsBool.type;
    if (rep == JSType.jsString) return _jsString.type;
    return null;
  }

  JS.Statement nullParameterCheck(JS.Expression param) {
    var call = _callHelper('argumentError((#))', [param]);
    return js.statement('if (# == null) #;', [param, call]);
  }

  JS.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visit(expr);
    if (!isNullable(expr)) return jsExpr;
    return _callHelper('notNull(#)', jsExpr);
  }

  JS.Expression _emitEqualityOperator(BinaryExpression node, Token op) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var leftType = left.staticType;
    var negated = op.type == TokenType.BANG_EQ;

    if (left is SuperExpression) {
      return _emitSend(left, op.lexeme, [right]);
    }

    // Equality on enums and primitives is identity.
    // TODO(leafp): Walk the class hierarchy and check to see if == was
    // overridden
    var isEnum = leftType is InterfaceType && leftType.element.isEnum;
    var usesIdentity = typeRep.isPrimitive(leftType) ||
        isEnum ||
        _isNull(left) ||
        _isNull(right);

    // If we know that the left type uses identity for equality, we can
    // sometimes emit better code.
    if (usesIdentity) {
      return _emitCoreIdenticalCall([left, right], negated: negated);
    }

    var leftElement = leftType.element;

    // If either is null, we can use simple equality.
    // We need to equate null and undefined, so if both are nullable
    //  (but not known to be null), we cannot directly use JS ==
    //  unless we know that conversion will not happen.
    // Functions may or may not have an [dartx[`==`]] method attached.
    //   - If they are tearoffs they will, otherwise they won't and equality is
    // identity.
    // TODO(leafp): consider fixing this.
    //
    // Native types may not have equality on the prototype.
    // If left is not nullable, then we don't need to worry about
    // null/undefined.
    // TODO(leafp): consider using (left || dart.EQ)['=='](right))
    // when left is nullable but not falsey
    if ((leftElement is ClassElement && _isJSNative(leftElement)) ||
        typeRep.isUnknown(leftType) ||
        leftType is FunctionType ||
        isNullable(left)) {
      // Fall back to equality for now.
      var code = negated ? '!#.equals(#, #)' : '#.equals(#, #)';
      return js.call(code, [_runtimeModule, _visit(left), _visit(right)]);
    }

    var name = _emitMemberName('==', type: leftType);
    var code = negated ? '!#[#](#)' : '#[#](#)';
    return js.call(code, [_visit(left), name, _visit(right)]);
  }

  @override
  JS.Expression visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;

    // The operands of logical boolean operators are subject to boolean
    // conversion.
    if (op.type == TokenType.BAR_BAR ||
        op.type == TokenType.AMPERSAND_AMPERSAND) {
      return _visitTest(node);
    }

    if (op.type.isEqualityOperator) return _emitEqualityOperator(node, op);

    var left = node.leftOperand;
    var right = node.rightOperand;

    if (op.type.lexeme == '??') {
      // TODO(jmesserly): leave RHS for debugging?
      // This should be a hint or warning for dead code.
      if (!isNullable(left)) return _visit(left);

      var vars = <JS.MetaLetVariable, JS.Expression>{};
      // Desugar `l ?? r` as `l != null ? l : r`
      var l = _visit(_bindValue(vars, 'l', left, context: left));
      return new JS.MetaLet(vars, [
        js.call('# != null ? # : #', [l, l, _visit(right)])
      ]);
    }

    var leftType = getStaticType(left);
    var rightType = getStaticType(right);

    if (typeRep.binaryOperationIsPrimitive(leftType, rightType) ||
        leftType == types.stringType && op.type == TokenType.PLUS) {
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

      switch (op.type) {
        case TokenType.TILDE_SLASH:
          // `a ~/ b` is equivalent to `(a / b).truncate()`
          var div = AstBuilder.binaryExpression(left, '/', right)
            ..staticType = node.staticType;
          return _emitSend(div, 'truncate', []);

        case TokenType.PERCENT:
          // TODO(sra): We can generate `a % b + 0` if both are non-negative
          // (the `+ 0` is to coerce -0.0 to 0).
          return _emitSend(left, op.lexeme, [right]);

        case TokenType.AMPERSAND:
          return bitwise('# & #');

        case TokenType.BAR:
          return bitwise('# | #');

        case TokenType.CARET:
          return bitwise('# ^ #');

        case TokenType.GT_GT:
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
          return _emitSend(left, op.lexeme, [right]);

        case TokenType.LT_LT:
          if (_is31BitUnsigned(node)) {
            // Result is 31 bit unsigned which implies the shift count was small
            // enough not to pollute the sign bit.
            return binary('# << #');
          }
          if (_asIntInRange(right, 0, 31) != null) {
            return _coerceBitOperationResultToUnsigned(node, binary('# << #'));
          }
          return _emitSend(left, op.lexeme, [right]);

        default:
          // TODO(vsm): When do Dart ops not map to JS?
          return binary('# $op #');
      }
    }

    return _emitSend(left, op.lexeme, [right]);
  }

  /// Bit operations are coerced to values on [0, 2^32). The coercion changes
  /// the interpretation of the 32-bit value from signed to unsigned.  Most
  /// JavaScript operations interpret their operands as signed and generate
  /// signed results.
  JS.Expression _coerceBitOperationResultToUnsigned(
      Expression node, JS.Expression uncoerced) {
    // Don't coerce if the parent will coerce.
    AstNode parent = _parentOperation(node);
    if (_nodeIsBitwiseOperation(parent)) return uncoerced;

    // Don't do a no-op coerce if the most significant bit is zero.
    if (_is31BitUnsigned(node)) return uncoerced;

    // If the consumer of the expression is '==' or '!=' with a constant that
    // fits in 31 bits, adding a coercion does not change the result of the
    // comparison, e.g.  `a & ~b == 0`.
    if (parent is BinaryExpression) {
      var tokenType = parent.operator.type;
      Expression left = parent.leftOperand;
      Expression right = parent.rightOperand;
      if (tokenType == TokenType.EQ_EQ || tokenType == TokenType.BANG_EQ) {
        const int MAX = 0x7fffffff;
        if (_asIntInRange(right, 0, MAX) != null) return uncoerced;
        if (_asIntInRange(left, 0, MAX) != null) return uncoerced;
      } else if (tokenType == TokenType.GT_GT) {
        if (_isDefinitelyNonNegative(left) &&
            _asIntInRange(right, 0, 31) != null) {
          // Parent will generate `# >>> n`.
          return uncoerced;
        }
      }
    }
    return js.call('# >>> 0', uncoerced);
  }

  AstNode _parentOperation(AstNode node) {
    node = node.parent;
    while (node is ParenthesizedExpression) node = node.parent;
    return node;
  }

  bool _nodeIsBitwiseOperation(AstNode node) {
    if (node is BinaryExpression) {
      switch (node.operator.type) {
        case TokenType.AMPERSAND:
        case TokenType.BAR:
        case TokenType.CARET:
          return true;
      }
      return false;
    }
    if (node is PrefixExpression) {
      return node.operator.type == TokenType.TILDE;
    }
    return false;
  }

  int _asIntInRange(Expression expr, int low, int high) {
    expr = expr.unParenthesized;
    if (expr is IntegerLiteral) {
      if (expr.value >= low && expr.value <= high) return expr.value;
      return null;
    }

    Identifier id;
    if (expr is SimpleIdentifier) {
      id = expr;
    } else if (expr is PrefixedIdentifier && !expr.isDeferred) {
      id = expr.identifier;
    } else {
      return null;
    }
    var element = id.staticElement;
    if (element is PropertyAccessorElement && element.isGetter) {
      var variable = element.variable;
      int value = variable?.computeConstantValue()?.toIntValue();
      if (value != null && value >= low && value <= high) return value;
    }
    return null;
  }

  bool _isDefinitelyNonNegative(Expression expr) {
    expr = expr.unParenthesized;
    if (expr is IntegerLiteral) {
      return expr.value >= 0;
    }
    if (_nodeIsBitwiseOperation(expr)) return true;
    // TODO(sra): Lengths of known list types etc.
    return false;
  }

  /// Does the parent of [node] mask the result to [width] bits or fewer?
  bool _parentMasksToWidth(AstNode node, int width) {
    AstNode parent = _parentOperation(node);
    if (parent == null) return false;
    if (_nodeIsBitwiseOperation(parent)) {
      if (parent is BinaryExpression &&
          parent.operator.type == TokenType.AMPERSAND) {
        Expression left = parent.leftOperand;
        Expression right = parent.rightOperand;
        final int MAX = (1 << width) - 1;
        if (_asIntInRange(right, 0, MAX) != null) return true;
        if (_asIntInRange(left, 0, MAX) != null) return true;
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
      if (expr is IntegerLiteral) {
        return expr.value >= 0 ? expr.value.bitLength : MAX;
      }
      if (++depth > 5) return MAX;
      if (expr is BinaryExpression) {
        var left = expr.leftOperand.unParenthesized;
        var right = expr.rightOperand.unParenthesized;
        switch (expr.operator.type) {
          case TokenType.AMPERSAND:
            return min(bitWidth(left, depth), bitWidth(right, depth));

          case TokenType.BAR:
          case TokenType.CARET:
            return max(bitWidth(left, depth), bitWidth(right, depth));

          case TokenType.GT_GT:
            int shiftValue = _asIntInRange(right, 0, 31);
            if (shiftValue != null) {
              int leftWidth = bitWidth(left, depth);
              return leftWidth == MAX ? MAX : max(0, leftWidth - shiftValue);
            }
            return MAX;

          case TokenType.LT_LT:
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
      int value = _asIntInRange(expr, 0, 0x7fffffff);
      if (value != null) return value.bitLength;
      return MAX;
    }

    return bitWidth(expr, 0) < 32;
  }

  bool _isNull(Expression expr) =>
      expr is NullLiteral || getStaticType(expr).isDartCoreNull;

  SimpleIdentifier _createTemporary(String name, DartType type,
      {bool nullable: true, JS.Expression variable, bool dynamicInvoke}) {
    // We use an invalid source location to signal that this is a temporary.
    // See [_isTemporary].
    // TODO(jmesserly): alternatives are
    // * (ab)use Element.isSynthetic, which isn't currently used for
    //   LocalVariableElementImpl, so we could repurpose to mean "temp".
    // * add a new property to LocalVariableElementImpl.
    // * create a new subtype of LocalVariableElementImpl to mark a temp.
    var id = astFactory
        .simpleIdentifier(new StringToken(TokenType.IDENTIFIER, name, -1));

    variable ??= new JS.TemporaryId(name);

    id.staticElement = new TemporaryVariableElement.forNode(id, variable);
    id.staticType = type;
    setIsDynamicInvoke(id, dynamicInvoke ?? type.isDynamic);
    addTemporaryVariable(id.staticElement, nullable: nullable);
    return id;
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

  /// Returns a new expression, which can be be used safely *once* on the
  /// left hand side, and *once* on the right side of an assignment.
  /// For example: `expr1[expr2] += y` can be compiled as
  /// `expr1[expr2] = expr1[expr2] + y`.
  ///
  /// The temporary scope will ensure `expr1` and `expr2` are only evaluated
  /// once: `((x1, x2) => x1[x2] = x1[x2] + y)(expr1, expr2)`.
  ///
  /// If the expression does not end up using `x1` or `x2` more than once, or
  /// if those expressions can be treated as stateless (e.g. they are
  /// non-mutated variables), then the resulting code will be simplified
  /// automatically.
  ///
  /// [scope] can be mutated to contain any new temporaries that were created,
  /// unless [expr] is a SimpleIdentifier, in which case a temporary is not
  /// needed.
  Expression _bindLeftHandSide(
      Map<JS.MetaLetVariable, JS.Expression> scope, Expression expr,
      {Expression context}) {
    Expression result;
    if (expr is IndexExpression) {
      IndexExpression index = expr;
      result = astFactory.indexExpressionForTarget(
          _bindValue(scope, 'o', index.target, context: context),
          index.leftBracket,
          _bindValue(scope, 'i', index.index, context: context),
          index.rightBracket);
    } else if (expr is PropertyAccess) {
      PropertyAccess prop = expr;
      result = astFactory.propertyAccess(
          _bindValue(scope, 'o', _getTarget(prop), context: context),
          prop.operator,
          prop.propertyName);
    } else if (expr is PrefixedIdentifier) {
      PrefixedIdentifier ident = expr;
      if (isLibraryPrefix(ident.prefix)) {
        return expr;
      }
      result = astFactory.prefixedIdentifier(
          _bindValue(scope, 'o', ident.prefix, context: context)
              as SimpleIdentifier,
          ident.period,
          ident.identifier);
    } else {
      return expr as SimpleIdentifier;
    }
    result.staticType = expr.staticType;
    setIsDynamicInvoke(result, isDynamicInvoke(expr));
    return result;
  }

  /// Creates a temporary to contain the value of [expr]. The temporary can be
  /// used multiple times in the resulting expression. For example:
  /// `expr ** 2` could be compiled as `expr * expr`. The temporary scope will
  /// ensure `expr` is only evaluated once: `(x => x * x)(expr)`.
  ///
  /// If the expression does not end up using `x` more than once, or if those
  /// expressions can be treated as stateless (e.g. they are non-mutated
  /// variables), then the resulting code will be simplified automatically.
  ///
  /// [scope] will be mutated to contain the new temporary's initialization.
  Expression _bindValue(Map<JS.MetaLetVariable, JS.Expression> scope,
      String name, Expression expr,
      {Expression context}) {
    // No need to do anything for stateless expressions.
    if (isStateless(_currentFunction, expr, context)) return expr;

    var variable = new JS.MetaLetVariable(name);
    var t = _createTemporary(name, getStaticType(expr),
        variable: variable,
        dynamicInvoke: isDynamicInvoke(expr),
        nullable: isNullable(expr));
    scope[variable] = _visit(expr);
    return t;
  }

  /// Desugars postfix increment.
  ///
  /// In the general case [expr] can be one of [IndexExpression],
  /// [PrefixExpression] or [PropertyAccess] and we need to
  /// ensure sub-expressions are evaluated once.
  ///
  /// We also need to ensure we can return the original value of the expression,
  /// and that it is only evaluated once.
  ///
  /// We desugar this using let*.
  ///
  /// For example, `expr1[expr2]++` can be transformed to this:
  ///
  ///     // psuedocode mix of Scheme and JS:
  ///     (let* (x1=expr1, x2=expr2, t=expr1[expr2]) { x1[x2] = t + 1; t })
  ///
  /// The [JS.MetaLet] nodes automatically simplify themselves if they can.
  /// For example, if the result value is not used, then `t` goes away.
  @override
  JS.Expression visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (typeRep.unaryOperationIsPrimitive(dispatchType)) {
      if (!isNullable(expr)) {
        return js.call('#$op', _visit(expr));
      }
    }

    assert(op.lexeme == '++' || op.lexeme == '--');

    // Handle the left hand side, to ensure each of its subexpressions are
    // evaluated only once.
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var left = _bindLeftHandSide(vars, expr, context: expr);

    // Desugar `x++` as `(x1 = x0 + 1, x0)` where `x0` is the original value
    // and `x1` is the new value for `x`.
    var x = _bindValue(vars, 'x', left, context: expr);

    var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
    var increment = AstBuilder.binaryExpression(x, op.lexeme[0], one)
      ..staticElement = node.staticElement
      ..staticType = getStaticType(expr);

    var body = <JS.Expression>[_emitSet(left, increment), _visit(x)];
    return new JS.MetaLet(vars, body, statelessResult: true);
  }

  @override
  JS.Expression visitPrefixExpression(PrefixExpression node) {
    var op = node.operator;

    // Logical negation, `!e`, is a boolean conversion context since it is
    // defined as `e ? false : true`.
    if (op.lexeme == '!') return _visitTest(node);

    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (typeRep.unaryOperationIsPrimitive(dispatchType)) {
      if (op.lexeme == '~') {
        if (typeRep.isNumber(dispatchType)) {
          JS.Expression jsExpr = js.call('~#', notNull(expr));
          return _coerceBitOperationResultToUnsigned(node, jsExpr);
        }
        return _emitSend(expr, op.lexeme[0], []);
      }
      if (!isNullable(expr)) {
        return js.call('$op#', _visit(expr));
      }
      if (op.lexeme == '++' || op.lexeme == '--') {
        // We need a null check, so the increment must be expanded out.
        var vars = <JS.MetaLetVariable, JS.Expression>{};
        var x = _bindLeftHandSide(vars, expr, context: expr);

        var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
        var increment = AstBuilder.binaryExpression(x, op.lexeme[0], one)
          ..staticElement = node.staticElement
          ..staticType = getStaticType(expr);

        return new JS.MetaLet(vars, [_emitSet(x, increment)]);
      }
      return js.call('$op#', notNull(expr));
    }

    if (op.lexeme == '++' || op.lexeme == '--') {
      // Increment or decrement requires expansion.
      // Desugar `++x` as `x = x + 1`, ensuring that if `x` has subexpressions
      // (for example, x is IndexExpression) we evaluate those once.
      var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
      return _emitOpAssign(expr, one, op.lexeme[0], node.staticElement,
          context: expr);
    }

    var operatorName = op.lexeme;
    // Use the name from the Dart spec.
    if (operatorName == '-') operatorName = 'unary-';
    return _emitSend(expr, operatorName, []);
  }

  // Cascades can contain [IndexExpression], [MethodInvocation] and
  // [PropertyAccess]. The code generation for those is handled in their
  // respective visit methods.
  @override
  visitCascadeExpression(CascadeExpression node) {
    var savedCascadeTemp = _cascadeTarget;

    var vars = <JS.MetaLetVariable, JS.Expression>{};
    _cascadeTarget = _bindValue(vars, '_', node.target, context: node);
    var sections = _visitList<JS.Expression>(node.cascadeSections);
    sections.add(_visit(_cascadeTarget));
    var result = new JS.MetaLet(vars, sections, statelessResult: true);
    _cascadeTarget = savedCascadeTemp;
    return result;
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) =>
      // The printer handles precedence so we don't need to.
      _visit(node.expression);

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    return _emitParameter(node.element, declaration: true);
  }

  JS.Parameter _emitNormalFormalParameter(NormalFormalParameter node) {
    var id = _emitParameter(node.element, declaration: true);
    var isRestArg = findAnnotation(node.element, isJsRestAnnotation) != null;
    return isRestArg ? new JS.RestParameter(id) : id;
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) =>
      _emitNormalFormalParameter(node);

  @override
  visitFieldFormalParameter(FieldFormalParameter node) =>
      _emitNormalFormalParameter(node);

  @override
  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      _emitNormalFormalParameter(node);

  @override
  JS.This visitThisExpression(ThisExpression node) => new JS.This();

  @override
  JS.Expression visitSuperExpression(SuperExpression node) => new JS.Super();

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isDeferredLoadLibrary(node.prefix, node.identifier)) {
      // We are tearing off "loadLibrary" on a library prefix.
      return _callHelper('loadLibrary');
    }

    if (isLibraryPrefix(node.prefix)) {
      return _visit(node.identifier);
    } else {
      return _emitAccess(node.prefix, node.identifier, node.staticType);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (node.operator.lexeme == '?.') {
      return _emitNullSafe(node);
    }
    return _emitAccess(_getTarget(node), node.propertyName, node.staticType);
  }

  JS.Expression _emitNullSafe(Expression node) {
    // Desugar `obj?.name` as ((x) => x == null ? null : x.name)(obj)
    var target = _getTarget(node);
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var t = _bindValue(vars, 't', target, context: target);
    return new JS.MetaLet(vars, [
      js.call('# == null ? null : #',
          [_visit(t), _visit(_stripNullAwareOp(node, t))])
    ]);
  }

  // TODO(jmesserly): this is dropping source location.
  Expression _stripNullAwareOp(Expression node, Expression newTarget) {
    if (node is PropertyAccess) {
      return AstBuilder.propertyAccess(newTarget, node.propertyName);
    } else {
      var invoke = node as MethodInvocation;
      return AstBuilder.methodInvoke(newTarget, invoke.methodName,
          invoke.typeArguments, invoke.argumentList.arguments)
        ..staticInvokeType = invoke.staticInvokeType;
    }
  }

  /// Everything in Dart is an Object and supports the 4 members on Object,
  /// so we have to use a runtime helper to handle values such as `null` and
  /// native types.
  ///
  /// For example `null.toString()` is legal in Dart, so we need to generate
  /// that as `dart.toString(obj)`.
  bool _isObjectMemberCall(Expression target, String memberName) {
    if (!isObjectMember(memberName)) {
      return false;
    }

    // Check if the target could be `null`, is dynamic, or may be an extension
    // native type. In all of those cases we need defensive code generation.
    var type = getStaticType(target);

    return isNullable(target) ||
        type is FunctionType ||
        type.isDynamic ||
        (_extensionTypes.hasNativeSubtype(type) && target is! SuperExpression);
  }

  List<JS.Expression> _getTypeArgs(Element member, DartType instantiated) {
    DartType type;
    if (member is ExecutableElement) {
      type = member.type;
    } else if (member is VariableElement) {
      type = member.type;
    }

    // TODO(jmesserly): handle explicitly passed type args.
    if (type == null) return null;
    return _emitFunctionTypeArguments(type, instantiated);
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  JS.Expression _emitAccess(
      Expression target, SimpleIdentifier memberId, DartType resultType) {
    var accessor = memberId.staticElement;
    // If `member` is a getter/setter, get the corresponding
    var field = _getNonAccessorElement(accessor);
    String memberName = memberId.name;
    var typeArgs = _getTypeArgs(accessor, resultType);

    bool isStatic = field is ClassMemberElement && field.isStatic;
    var jsName = _emitMemberName(memberName,
        type: getStaticType(target), isStatic: isStatic, element: accessor);
    if (isDynamicInvoke(target)) {
      return _callHelper('#(#, #)',
          [_emitDynamicOperationName('dload'), _visit(target), jsName]);
    }

    var jsTarget = _emitTarget(target, accessor, isStatic);

    var isSuper = jsTarget is JS.Super;
    if (isSuper &&
        accessor.isSynthetic &&
        field is FieldElementImpl &&
        !virtualFields.isVirtual(field)) {
      // If super.x is a sealed field, then x is an instance property since
      // subclasses cannot override x.
      jsTarget = annotate(new JS.This(), target);
    }

    JS.Expression result;
    if (_isObjectMemberCall(target, memberName)) {
      if (_isObjectMethod(memberName)) {
        result = _callHelper('bind(#, #)', [jsTarget, jsName]);
      } else {
        result = _callHelper('#(#)', [memberName, jsTarget]);
      }
    } else if (accessor is MethodElement &&
        !isStatic &&
        !_isJSNative(accessor.enclosingElement)) {
      if (isSuper) {
        result = _callHelper('bind(this, #, #)',
            [jsName, _emitTargetAccess(jsTarget, jsName, accessor)]);
      } else {
        result = _callHelper('bind(#, #)', [jsTarget, jsName]);
      }
    } else {
      result = _emitTargetAccess(jsTarget, jsName, accessor);
    }
    return typeArgs == null
        ? result
        : _callHelper('gbind(#, #)', [result, typeArgs]);
  }

  JS.LiteralString _emitDynamicOperationName(String name) =>
      js.string(options.replCompile ? '${name}Repl' : name);

  /// Emits a generic send, like an operator method.
  ///
  /// **Please note** this function does not support method invocation syntax
  /// `obj.name(args)` because that could be a getter followed by a call.
  /// See [visitMethodInvocation].
  JS.Expression _emitSend(
      Expression target, String name, List<Expression> args) {
    var type = getStaticType(target);
    var memberName = _emitMemberName(name, type: type);
    if (isDynamicInvoke(target)) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': 'dindex', '[]=': 'dsetindex'}[name];
      if (dynamicHelper != null) {
        return _callHelper(
            '$dynamicHelper(#, #)', [_visit(target), _visitList(args)]);
      } else {
        return _callHelper(
            'dsend(#, #, #)', [_visit(target), memberName, _visitList(args)]);
      }
    }

    // Generic dispatch to a statically known method.
    return js.call('#.#(#)', [_visit(target), memberName, _visitList(args)]);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    var target = _getTarget(node);
    if (_useNativeJsIndexer(target.staticType)) {
      return new JS.PropertyAccess(_visit(target), _visit(node.index));
    }
    return _emitSend(target, '[]', [node.index]);
  }

  // TODO(jmesserly): ideally we'd check the method and see if it is marked
  // `external`, but that doesn't work because it isn't in the element model.
  bool _useNativeJsIndexer(DartType type) =>
      findAnnotation(type.element, isJSAnnotation) != null;

  /// Gets the target of a [PropertyAccess], [IndexExpression], or
  /// [MethodInvocation]. These three nodes can appear in a [CascadeExpression].
  Expression _getTarget(node) {
    assert(node is IndexExpression ||
        node is PropertyAccess ||
        node is MethodInvocation);
    return node.isCascaded ? _cascadeTarget : node.target;
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      _visitTest(node.condition),
      _visit(node.thenExpression),
      _visit(node.elseExpression)
    ]);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    var expr = _visit(node.expression);
    if (node.parent is ExpressionStatement) {
      return _callHelperStatement('throw(#);', expr);
    } else {
      return _callHelper('throw(#)', expr);
    }
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    if (node.parent is ExpressionStatement) {
      return js.statement('throw #;', _visit(_catchParameter));
    } else {
      return js.call('throw #', _visit(_catchParameter));
    }
  }

  /// Visits a statement, and ensures the resulting AST handles block scope
  /// correctly. Essentially, we need to promote a variable declaration
  /// statement into a block in some cases, e.g.
  ///
  ///     do var x = 5; while (false); // Dart
  ///     do { let x = 5; } while (false); // JS
  JS.Statement _visitScope(Statement stmt) {
    var result = _visit(stmt);
    if (result is JS.ExpressionStatement &&
        result.expression is JS.VariableDeclarationList) {
      return new JS.Block([result]);
    }
    return result;
  }

  @override
  JS.If visitIfStatement(IfStatement node) {
    return new JS.If(_visitTest(node.condition),
        _visitScope(node.thenStatement), _visitScope(node.elseStatement));
  }

  @override
  JS.For visitForStatement(ForStatement node) {
    var init = _visit(node.initialization);
    if (init == null) init = _visit(node.variables);
    var update = _visitListToBinary(node.updaters, ',');
    if (update != null) update = update.toVoidExpression();
    var condition = node.condition == null ? null : _visitTest(node.condition);
    return new JS.For(init, condition, update, _visitScope(node.body));
  }

  @override
  JS.While visitWhileStatement(WhileStatement node) {
    return new JS.While(_visitTest(node.condition), _visitScope(node.body));
  }

  @override
  JS.Do visitDoStatement(DoStatement node) {
    return new JS.Do(_visitScope(node.body), _visitTest(node.condition));
  }

  @override
  JS.Statement visitForEachStatement(ForEachStatement node) {
    if (node.awaitKeyword != null) {
      return _emitAwaitFor(node);
    }

    var init = _visit(node.identifier);
    var iterable = _visit(node.iterable);
    var body = _visitScope(node.body);
    if (init == null) {
      var name = node.loopVariable.identifier.name;
      init = js.call('let #', name);
      if (_annotatedNullCheck(node.loopVariable.element)) {
        body =
            new JS.Block([nullParameterCheck(new JS.Identifier(name)), body]);
      }
    }
    return new JS.ForOf(init, iterable, body);
  }

  JS.Statement _emitAwaitFor(ForEachStatement node) {
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
    var streamIterator = rules.instantiateToBounds(_asyncStreamIterator);
    var createStreamIter = _emitInstanceCreationExpression(
        (streamIterator.element as ClassElement).unnamedConstructor,
        streamIterator,
        null,
        AstBuilder.argumentList([node.iterable]),
        false);
    var iter = _visit(_createTemporary('it', streamIterator, nullable: false));

    var init = _visit(node.identifier);
    if (init == null) {
      init = js
          .call('let # = #.current', [node.loopVariable.identifier.name, iter]);
    } else {
      init = js.call('# = #.current', [init, iter]);
    }
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
          _visit(node.body),
          new JS.Yield(js.call('#.cancel()', iter))
        ]);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    var label = node.label;
    return new JS.Break(label?.name);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    var label = node.label;
    return new JS.Continue(label?.name);
  }

  @override
  visitTryStatement(TryStatement node) {
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var finallyBlock = _visit(node.finallyBlock);
    _superAllowed = savedSuperAllowed;
    return new JS.Try(
        _visit(node.body), _visitCatch(node.catchClauses), finallyBlock);
  }

  _visitCatch(NodeList<CatchClause> clauses) {
    if (clauses == null || clauses.isEmpty) return null;

    // TODO(jmesserly): need a better way to get a temporary variable.
    // This could incorrectly shadow a user's name.
    var savedCatch = _catchParameter;

    if (clauses.length == 1 && clauses.single.exceptionParameter != null) {
      // Special case for a single catch.
      _catchParameter = clauses.single.exceptionParameter;
    } else {
      _catchParameter = _createTemporary('e', types.dynamicType);
    }

    JS.Statement catchBody = js.statement('throw #;', _visit(_catchParameter));
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(clause, catchBody);
    }

    var catchVarDecl = _visit(_catchParameter);
    _catchParameter = savedCatch;
    return new JS.Catch(catchVarDecl, new JS.Block([catchBody]));
  }

  JS.Statement _catchClauseGuard(CatchClause clause, JS.Statement otherwise) {
    var then = visitCatchClause(clause);

    // Discard following clauses, if any, as they are unreachable.
    if (clause.exceptionType == null) return then;

    // TODO(jmesserly): this is inconsistent with [visitIsExpression], which
    // has special case for typeof.
    var castType = _emitType(clause.exceptionType.type);

    return new JS.If(js.call('#.is(#)', [castType, _visit(_catchParameter)]),
        then, otherwise);
  }

  JS.Statement _statement(List<JS.Statement> statements) {
    // TODO(jmesserly): empty block singleton?
    if (statements.length == 0) return new JS.Block([]);
    if (statements.length == 1) return statements[0];
    return new JS.Block(statements);
  }

  /// Visits the catch clause body. This skips the exception type guard, if any.
  /// That is handled in [_visitCatch].
  @override
  JS.Statement visitCatchClause(CatchClause node) {
    var body = <JS.Statement>[];

    var savedCatch = _catchParameter;
    if (node.catchKeyword != null) {
      var name = node.exceptionParameter;
      if (name != null && name != _catchParameter) {
        body.add(js
            .statement('let # = #;', [_visit(name), _visit(_catchParameter)]));
        _catchParameter = name;
      }
      if (node.stackTraceParameter != null) {
        var stackVar = node.stackTraceParameter.name;
        body.add(js.statement('let # = #.stackTrace(#);',
            [stackVar, _runtimeModule, _visit(name)]));
      }
    }

    body.add(new JS.Block(_visitList(node.body.statements)));
    _catchParameter = savedCatch;
    return _statement(body);
  }

  @override
  JS.Case visitSwitchCase(SwitchCase node) {
    var expr = _visit(node.expression);
    var body = _visitList<JS.Statement>(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return new JS.Case(expr, new JS.Block(body));
  }

  @override
  JS.Default visitSwitchDefault(SwitchDefault node) {
    var body = _visitList<JS.Statement>(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return new JS.Default(new JS.Block(body));
  }

  @override
  JS.Switch visitSwitchStatement(SwitchStatement node) =>
      new JS.Switch(_visit(node.expression), _visitList(node.members));

  @override
  JS.Statement visitLabeledStatement(LabeledStatement node) {
    var result = _visit(node.statement);
    for (var label in node.labels.reversed) {
      result = new JS.LabeledStatement(label.label.name, result);
    }
    return result;
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) => js.number(node.value);

  @override
  visitDoubleLiteral(DoubleLiteral node) => js.number(node.value);

  @override
  visitNullLiteral(NullLiteral node) => new JS.LiteralNull();

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    JS.Expression emitSymbol() {
      // TODO(vsm): Handle qualified symbols correctly.
      var last = node.components.last.toString();
      var name = js.string(node.components.join('.'), "'");
      if (last.startsWith('_')) {
        var nativeSymbol = _emitPrivateNameSymbol(currentLibrary, last);
        return js.call('new #.new(#, #)', [
          _emitConstructorAccess(privateSymbolClass.type),
          name,
          nativeSymbol
        ]);
      } else {
        return js
            .call('#.new(#)', [_emitConstructorAccess(types.symbolType), name]);
      }
    }

    return _emitConst(emitSymbol);
  }

  @override
  visitListLiteral(ListLiteral node) {
    var elementType = (node.staticType as InterfaceType).typeArguments[0];
    if (node.constKeyword == null) {
      return _emitList(elementType, _visitList(node.elements));
    }
    return _cacheConst(() {
      // dart.constList helper internally depends on _interceptors.JSArray.
      _declareBeforeUse(_jsArray);
      return _callHelper('constList(#, #)', [
        new JS.ArrayInitializer(_visitList(node.elements)),
        _emitType(elementType)
      ]);
    });
  }

  JS.Expression _emitList(DartType itemType, List<JS.Expression> items) {
    var list = new JS.ArrayInitializer(items);

    // TODO(jmesserly): analyzer will usually infer `List<Object>` because
    // that is the least upper bound of the element types. So we rarely
    // generate a plain `List<dynamic>` anymore.
    if (itemType.isDynamic) return list;

    // Call `new JSArray<E>.of(list)`
    var arrayType = _jsArray.type.instantiate([itemType]);
    return js.call('#.of(#)', [_emitType(arrayType), list]);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    // TODO(jmesserly): we can likely make these faster.
    JS.Expression emitMap() {
      var entries = node.entries;
      Object mapArguments = null;
      var type = node.staticType as InterfaceType;
      var typeArgs = type.typeArguments;
      var reifyTypeArgs = typeArgs.any((t) => !t.isDynamic);
      if (entries.isEmpty && !reifyTypeArgs) {
        mapArguments = [];
      } else if (entries.every((e) => e.key is StringLiteral)) {
        // Use JS object literal notation if possible, otherwise use an array.
        // We could do this any time all keys are non-nullable String type.
        // For now, support StringLiteral as the common non-nullable String case.
        var props = <JS.Property>[];
        for (var e in entries) {
          props.add(new JS.Property(_visit(e.key), _visit(e.value)));
        }
        mapArguments = new JS.ObjectInitializer(props);
      } else {
        var values = <JS.Expression>[];
        for (var e in entries) {
          values.add(_visit(e.key));
          values.add(_visit(e.value));
        }
        mapArguments = new JS.ArrayInitializer(values);
      }
      var types = <JS.Expression>[];
      if (reifyTypeArgs) {
        types.addAll(typeArgs.map((e) => _emitType(e)));
      }
      return _callHelper('map(#, #)', [mapArguments, types]);
    }

    if (node.constKeyword != null) return _emitConst(emitMap);
    return emitMap();
  }

  @override
  JS.LiteralString visitSimpleStringLiteral(SimpleStringLiteral node) =>
      js.escapedString(node.value, node.isSingleQuoted ? "'" : '"');

  @override
  JS.Expression visitAdjacentStrings(AdjacentStrings node) =>
      _visitListToBinary(node.strings, '+');

  @override
  JS.Expression visitStringInterpolation(StringInterpolation node) {
    var strings = <String>[];
    var interpolations = <JS.Expression>[];

    var expectString = true;
    for (var e in node.elements) {
      if (e is InterpolationString) {
        assert(expectString);
        expectString = false;

        // Escape the string as necessary for use in the eventual `` quotes.
        // TODO(jmesserly): this call adds quotes, and then we strip them off.
        var str = js.escapedString(e.value, '`').value;
        strings.add(str.substring(1, str.length - 1));
      } else {
        assert(!expectString);
        expectString = true;
        interpolations.add(_visit(e));
      }
    }
    return new JS.TaggedTemplate(
        _callHelper('str'), new JS.TemplateString(strings, interpolations));
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) =>
      _visit(node.expression);

  @override
  visitBooleanLiteral(BooleanLiteral node) => js.boolean(node.value);

  T _visit<T extends JS.Node>(AstNode node) {
    if (node == null) return null;
    var result = node.accept(this) as T;
    return result != null ? annotate(result, node) : null;
  }

  List<R> _visitList<R extends JS.Node>(Iterable<AstNode> nodes) {
    return nodes?.map<R>(_visit)?.toList();
  }

  /// Visits a list of expressions, creating a comma expression if needed in JS.
  JS.Expression _visitListToBinary(List<Expression> nodes, String operator) {
    if (nodes == null || nodes.isEmpty) return null;
    return new JS.Expression.binary(_visitList(nodes), operator);
  }

  /// Generates an expression for a boolean conversion context (if, while, &&,
  /// etc.), where conversions and null checks are implemented via `dart.test`
  /// to give a more helpful message.
  // TODO(sra): When nullablility is available earlier, it would be cleaner to
  // build an input AST where the boolean conversion is a single AST node.
  JS.Expression _visitTest(Expression node) {
    JS.Expression finish(JS.Expression result) {
      return annotate(result, node);
    }

    if (node is PrefixExpression && node.operator.lexeme == '!') {
      // TODO(leafp): consider a peephole opt for identical
      // and == here.
      return finish(js.call('!#', _visitTest(node.operand)));
    }
    if (node is ParenthesizedExpression) {
      return finish(_visitTest(node.expression));
    }
    if (node is BinaryExpression) {
      JS.Expression shortCircuit(String code) {
        return finish(js.call(code,
            [_visitTest(node.leftOperand), _visitTest(node.rightOperand)]));
      }

      var op = node.operator.type.lexeme;
      if (op == '&&') return shortCircuit('# && #');
      if (op == '||') return shortCircuit('# || #');
    }
    if (node is AsExpression && CoercionReifier.isRequiredForSoundness(node)) {
      assert(node.staticType == types.boolType);
      return _callHelper('dtest(#)', _visit(node.expression));
    }
    JS.Expression result = _visit(node);
    if (isNullable(node)) result = _callHelper('test(#)', result);
    return result;
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  JS.Expression _declareMemberName(ExecutableElement e, {bool useExtension}) {
    return _emitMemberName(_getElementName(e),
        isStatic: e.isStatic,
        useExtension:
            useExtension ?? _extensionTypes.isNativeClass(e.enclosingElement),
        element: e);
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
      Element element}) {
    // Static members skip the rename steps and may require JS interop renames.
    if (isStatic) {
      return _emitJSInteropStaticMemberName(element) ?? _propertyName(name);
    }

    // We allow some (illegal in Dart) member names to be used in our private
    // SDK code. These renames need to be included at every declaration,
    // including overrides in subclasses.
    if (element != null) {
      var runtimeName = getJSExportName(element);
      if (runtimeName != null) return _propertyName(runtimeName);
    }

    if (name.startsWith('_')) {
      return _emitPrivateNameSymbol(currentLibrary, name);
    }

    // When generating synthetic names, we use _ as the prefix, since Dart names
    // won't have this (eliminated above), nor will static names reach here.
    switch (name) {
      case '[]':
        name = '_get';
        break;
      case '[]=':
        name = '_set';
        break;
      case 'unary-':
        name = '_negate';
        break;
      case 'constructor':
      case 'prototype':
        name = '_$name';
        break;
    }

    var result = _propertyName(name);

    useExtension ??= _isSymbolizedMember(type, name);

    return useExtension
        ? js.call('#.#', [_extensionSymbolsModule, result])
        : result;
  }

  var _forwardingCache = new HashMap<Element, Map<String, ExecutableElement>>();

  Element _lookupForwardedMember(ClassElement element, String name) {
    // We only care about public methods.
    if (name.startsWith('_')) return null;

    var map = _forwardingCache.putIfAbsent(element, () => {});
    if (map.containsKey(name)) return map[name];

    // Note, for a public member, the library should not matter.
    var library = element.library;
    var member = element.lookUpMethod(name, library) ??
        element.lookUpGetter(name, library) ??
        element.lookUpSetter(name, library);
    member = (member != null &&
            member.isSynthetic &&
            member is PropertyAccessorElement)
        ? member.variable
        : member;
    map[name] = member;
    return member;
  }

  /// Don't symbolize native members that just forward to the underlying
  /// native member.  We limit this to non-renamed members as the receiver
  /// may be a mock type.
  ///
  /// Note, this is an underlying assumption here that, if another native type
  /// subtypes this one, it also forwards this member to its underlying native
  /// one without renaming.
  bool _isSymbolizedMember(DartType type, String name) {
    // Object members are handled separately.
    if (isObjectMember(name)) {
      return false;
    }

    while (type is TypeParameterType) {
      type = (type as TypeParameterType).bound;
    }
    if (type is InterfaceType) {
      var element = type.element;
      if (_extensionTypes.isNativeClass(element)) {
        var member = _lookupForwardedMember(element, name);

        // Fields on a native class are implicitly native.
        // Methods/getters/setters are marked external/native.
        if (member is FieldElement ||
            member is ExecutableElement && member.isExternal) {
          var jsName = getAnnotationName(member, isJsName);
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
      return _extensionTypes.isNativeInterface(element);
    }
    return false;
  }

  JS.TemporaryId _emitPrivateNameSymbol(LibraryElement library, String name) {
    return _privateNames
        .putIfAbsent(library, () => new HashMap())
        .putIfAbsent(name, () {
      var id = new JS.TemporaryId(name);
      _moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(id.name, "'")]));
      return id;
    });
  }

  bool _externalOrNative(node) =>
      node.externalKeyword != null || _functionBody(node) is NativeFunctionBody;

  FunctionBody _functionBody(node) =>
      node is FunctionDeclaration ? node.functionExpression.body : node.body;

  /// Returns the canonical name to refer to the Dart library.
  JS.Identifier emitLibraryName(LibraryElement library) {
    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(library,
            () => new JS.TemporaryId(jsLibraryName(_libraryRoot, library)));
  }

  T annotate<T extends JS.Node>(T node, AstNode original, [Element element]) {
    if (options.closure && element != null) {
      node.closureAnnotation =
          closureAnnotationFor(node, original, element, namedArgumentTemp.name);
    }
    return node..sourceInformation = original;
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
        return true;
    }
    return false;
  }

  bool _isObjectMethod(String name) =>
      name == 'toString' || name == 'noSuchMethod';

  // TODO(leafp): Various analyzer pieces computed similar things.
  // Share this logic somewhere?
  DartType _getExpectedReturnType(ExecutableElement element) {
    FunctionType functionType = element.type;
    if (functionType == null) {
      return DynamicTypeImpl.instance;
    }
    var type = functionType.returnType;

    InterfaceType expectedType = null;
    if (element.isAsynchronous) {
      if (element.isGenerator) {
        // Stream<T> -> T
        expectedType = types.streamType;
      } else {
        // Future<T> -> T
        expectedType = types.futureType;
      }
    } else {
      if (element.isGenerator) {
        // Iterable<T> -> T
        expectedType = types.iterableType;
      } else {
        // T -> T
        return type;
      }
    }
    if (type.isDynamic) {
      return type;
    } else if (type is InterfaceType && type.element == expectedType.element) {
      return type.typeArguments[0];
    } else {
      // TODO(leafp): The above only handles the case where the return type
      // is exactly Future/Stream/Iterable.  Handle the subtype case.
      return DynamicTypeImpl.instance;
    }
  }

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

  JS.Expression _throwUnsafe(String message) => _callHelper(
      'throw(Error(#))', js.escapedString("compile error: $message"));

  _unreachable(AstNode node) {
    throw new UnsupportedError(
        'tried to generate an unreachable node: `$node`');
  }

  /// Unused, see methods for emitting declarations.
  @override
  visitAnnotation(node) => _unreachable(node);

  /// Unused, see [_emitArgumentList].
  @override
  visitArgumentList(ArgumentList node) => _unreachable(node);

  /// Unused, see [_emitFieldInitializers].
  @override
  visitAssertInitializer(node) => _unreachable(node);

  /// Not visited, but maybe they should be?
  /// See <https://github.com/dart-lang/sdk/issues/29347>
  @override
  visitComment(node) => _unreachable(node);

  /// Not visited, but maybe they should be?
  /// See <https://github.com/dart-lang/sdk/issues/29347>
  @override
  visitCommentReference(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitConfiguration(node) => _unreachable(node);

  /// Unusued, see [_emitConstructor].
  @override
  visitConstructorDeclaration(node) => _unreachable(node);

  /// Unusued, see [_emitFieldInitializers].
  @override
  visitConstructorFieldInitializer(node) => _unreachable(node);

  /// Unusued, see [_emitRedirectingConstructor].
  @override
  visitRedirectingConstructorInvocation(node) => _unreachable(node);

  /// Unusued. Handled in [visitForEachStatement].
  @override
  visitDeclaredIdentifier(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitDottedName(node) => _unreachable(node);

  /// Unused, handled by [visitEnumDeclaration].
  @override
  visitEnumConstantDeclaration(node) => _unreachable(node); // see

  /// Unused, see [_emitClassHeritage].
  @override
  visitExtendsClause(node) => _unreachable(node);

  /// Unused, see [_emitFormalParameterList].
  @override
  visitFormalParameterList(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitShowCombinator(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitHideCombinator(node) => _unreachable(node);

  /// Unused, see [_emitClassHeritage].
  @override
  visitImplementsClause(node) => _unreachable(node);

  /// Unused, handled by [visitStringInterpolation].
  @override
  visitInterpolationString(node) => _unreachable(node);

  /// Unused, labels are handled by containing statements.
  @override
  visitLabel(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitLibraryIdentifier(node) => _unreachable(node);

  /// Unused, see [visitMapLiteral].
  @override
  visitMapLiteralEntry(node) => _unreachable(node);

  /// Unused, see [_emitMethodDeclaration].
  @override
  visitMethodDeclaration(node) => _unreachable(node);

  /// Unused, these are not visited.
  @override
  visitNativeClause(node) => _unreachable(node);

  /// Unused, these are not visited.
  @override
  visitNativeFunctionBody(node) => _unreachable(node);

  /// Unused, handled by [_emitConstructor].
  @override
  visitSuperConstructorInvocation(node) => _unreachable(node);

  /// Unused, this can be handled when emitting the module if needed.
  @override
  visitScriptTag(node) => _unreachable(node);

  /// Unused, see [_emitType].
  @override
  visitTypeArgumentList(node) => _unreachable(node);

  /// Unused, see [_emitType].
  @override
  visitTypeParameter(node) => _unreachable(node);

  /// Unused, see [_emitType].
  @override
  visitGenericFunctionType(node) => _unreachable(node);

  /// Unused, see [_emitType].
  @override
  visitTypeParameterList(node) => _unreachable(node);

  /// Unused, see [_emitClassHeritage].
  @override
  visitWithClause(node) => _unreachable(node);
}

/// Choose a canonical name from the [library] element.
///
/// This never uses the library's name (the identifier in the `library`
/// declaration) as it doesn't have any meaningful rules enforced.
String jsLibraryName(String libraryRoot, LibraryElement library) {
  var uri = library.source.uri;
  if (uri.scheme == 'dart') {
    return uri.path;
  }
  // TODO(vsm): This is not necessarily unique if '__' appears in a file name.
  var encodedSeparator = '__';
  String qualifiedPath;
  if (uri.scheme == 'package') {
    // Strip the package name.
    // TODO(vsm): This is not unique if an escaped '/'appears in a filename.
    // E.g., "foo/bar.dart" and "foo$47bar.dart" would collide.
    qualifiedPath = uri.pathSegments.skip(1).join(encodedSeparator);
  } else if (isWithin(libraryRoot, uri.toFilePath())) {
    qualifiedPath = relative(uri.toFilePath(), from: libraryRoot)
        .replaceAll(separator, encodedSeparator);
  } else {
    // We don't have a unique name.
    throw 'Invalid library root. $libraryRoot does not contain ${uri
        .toFilePath()}';
  }
  return pathToJSIdentifier(qualifiedPath);
}

/// Debugger friendly name for a Dart Library.
String jsLibraryDebuggerName(String libraryRoot, LibraryElement library) {
  var uri = library.source.uri;
  // For package: and dart: uris show the entire
  if (uri.scheme == 'dart' || uri.scheme == 'package') return uri.toString();

  var filePath = uri.toFilePath();
  if (!isWithin(libraryRoot, filePath)) {
    throw 'Invalid library root. $libraryRoot does not contain ${uri
        .toFilePath()}';
  }
  // Relative path to the library.
  return relative(filePath, from: libraryRoot);
}

/// Shorthand for identifier-like property names.
/// For now, we emit them as strings and the printer restores them to
/// identifiers if it can.
// TODO(jmesserly): avoid the round tripping through quoted form.
JS.LiteralString _propertyName(String name) => js.string(name, "'");

// TODO(jacobr): we would like to do something like the following
// but we don't have summary support yet.
// bool _supportJsExtensionMethod(AnnotatedNode node) =>
//    _getAnnotation(node, "SupportJsExtensionMethod") != null;

/// A special kind of element created by the compiler, signifying a temporary
/// variable. These objects use instance equality, and should be shared
/// everywhere in the tree where they are treated as the same variable.
class TemporaryVariableElement extends LocalVariableElementImpl {
  final JS.Expression jsVariable;

  TemporaryVariableElement.forNode(Identifier name, this.jsVariable)
      : super.forNode(name);

  int get hashCode => identityHashCode(this);

  bool operator ==(Object other) => identical(this, other);
}

bool isLibraryPrefix(Expression node) =>
    node is SimpleIdentifier && node.staticElement is PrefixElement;

LibraryElement _getLibrary(AnalysisContext c, String uri) =>
    c.computeLibraryElement(c.sourceFactory.forUri(uri));

/// Returns `true` if [target] is a prefix for a deferred library and [name]
/// is "loadLibrary".
///
/// If so, the expression should be compiled to call the runtime's
/// "loadLibrary" helper function.
bool _isDeferredLoadLibrary(Expression target, SimpleIdentifier name) {
  if (name.name != "loadLibrary") return false;

  if (target is! SimpleIdentifier) return false;
  var targetIdentifier = target as SimpleIdentifier;

  if (targetIdentifier.staticElement is! PrefixElement) return false;
  var prefix = targetIdentifier.staticElement as PrefixElement;

  // The library the prefix is referring to must come from a deferred import.
  var containingLibrary = resolutionMap
      .elementDeclaredByCompilationUnit(target.root as CompilationUnit)
      .library;
  var imports = containingLibrary.getImportsWithPrefix(prefix);
  return imports.length == 1 && imports[0].isDeferred;
}

bool _annotatedNullCheck(Element e) =>
    e != null && findAnnotation(e, isNullCheckAnnotation) != null;
