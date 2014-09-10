// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transfomer that combines multiple dart script tags into a single one.
library polymer.src.build.script_compactor;

import 'dart:async';
import 'dart:convert';

import 'package:html5lib/dom.dart' show Document, Element, Text;
import 'package:html5lib/dom_parsing.dart';
import 'package:html5lib/parser.dart' show parseFragment;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' hide Element;
import 'package:analyzer/src/generated/element.dart' as analyzer show Element;
import 'package:barback/barback.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:smoke/codegen/generator.dart';
import 'package:smoke/codegen/recorder.dart';
import 'package:code_transformers/resolver.dart';
import 'package:code_transformers/src/dart_sdk.dart';
import 'package:template_binding/src/mustache_tokens.dart' show MustacheTokens;

import 'package:polymer_expressions/expression.dart' as pe;
import 'package:polymer_expressions/parser.dart' as pe;
import 'package:polymer_expressions/visitor.dart' as pe;

import 'common.dart';
import 'import_inliner.dart' show ImportInliner; // just for docs.
import 'messages.dart';

/// Combines Dart script tags into a single script tag, and creates a new Dart
/// file that calls the main function of each of the original script tags.
///
/// This transformer assumes that all script tags point to external files. To
/// support script tags with inlined code, use this transformer after running
/// [ImportInliner] on an earlier phase.
///
/// Internally, this transformer will convert each script tag into an import
/// statement to a library, and then uses `initPolymer` (see polymer.dart)  to
/// process `@initMethod` and `@CustomTag` annotations in those libraries.
class ScriptCompactor extends Transformer {
  final Resolvers resolvers;
  final TransformOptions options;

  ScriptCompactor(this.options, {String sdkDir})
      // TODO(sigmund): consider restoring here a resolver that uses the real
      // SDK once the analyzer is lazy and only an resolves what it needs:
      //: resolvers = new Resolvers(sdkDir != null ? sdkDir : dartSdkDirectory);
      : resolvers = new Resolvers.fromMock({
        // The list of types below is derived from:
        //   * types we use via our smoke queries, including HtmlElement and
        //     types from `_typeHandlers` (deserialize.dart)
        //   * types that are used internally by the resolver (see
        //   _initializeFrom in resolver.dart).
        'dart:core': '''
            library dart.core;
            class Object {}
            class Function {}
            class StackTrace {}
            class Symbol {}
            class Type {}

            class String extends Object {}
            class bool extends Object {}
            class num extends Object {}
            class int extends num {}
            class double extends num {}
            class DateTime extends Object {}
            class Null extends Object {}

            class Deprecated extends Object {
              final String expires;
              const Deprecated(this.expires);
            }
            const Object deprecated = const Deprecated("next release");
            class _Override { const _Override(); }
            const Object override = const _Override();
            class _Proxy { const _Proxy(); }
            const Object proxy = const _Proxy();

            class List<V> extends Object {}
            class Map<K, V> extends Object {}
            ''',
        'dart:html': '''
            library dart.html;
            class HtmlElement {}
            ''',
      });



  /// Only run on entry point .html files.
  // TODO(nweiz): This should just take an AssetId when barback <0.13.0 support
  // is dropped.
  Future<bool> isPrimary(idOrAsset) {
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return new Future.value(options.isHtmlEntryPoint(id));
  }

  Future apply(Transform transform) =>
      new _ScriptCompactor(transform, options, resolvers).apply();
}

/// Helper class mainly use to flatten the async code.
class _ScriptCompactor extends PolymerTransformer {
  final TransformOptions options;
  final Transform transform;
  final BuildLogger logger;
  final AssetId docId;
  final AssetId bootstrapId;

  /// HTML document parsed from [docId].
  Document document;

  /// List of ids for each Dart entry script tag (the main tag and any tag
  /// included on each custom element definition).
  List<AssetId> entryLibraries;

  /// Whether we are using the experimental bootstrap logic.
  bool experimentalBootstrap;

  /// Initializers that will register custom tags or invoke `initMethod`s.
  final List<_Initializer> initializers = [];

  /// Attributes published on a custom-tag. We make these available via
  /// reflection even if @published was not used.
  final Map<String, List<String>> publishedAttributes = {};

  /// Hook needed to access the analyzer within barback transformers.
  final Resolvers resolvers;

  /// Resolved types used for analyzing the user's sources and generating code.
  _ResolvedTypes types;

  /// The resolver instance associated with a single run of this transformer.
  Resolver resolver;

  /// Code generator used to create the static initialization for smoke.
  final generator = new SmokeCodeGenerator();

  _SubExpressionVisitor expressionVisitor;

  _ScriptCompactor(Transform transform, options, this.resolvers)
      : transform = transform,
        options = options,
        logger = new BuildLogger(
            transform, convertErrorsToWarnings: !options.releaseMode,
            detailsUri: 'http://goo.gl/5HPeuP'),
        docId = transform.primaryInput.id,
        bootstrapId = transform.primaryInput.id.addExtension('_bootstrap.dart');

  Future apply() =>
      _loadDocument()
      .then(_loadEntryLibraries)
      .then(_processHtml)
      .then(_emitNewEntrypoint)
      .then((_) {
        // Write out the logs collected by our [BuildLogger].
        if (options.injectBuildLogsInOutput) return logger.writeOutput();
      });

  /// Loads the primary input as an html document.
  Future _loadDocument() =>
      readPrimaryAsHtml(transform, logger).then((doc) { document = doc; });

  /// Populates [entryLibraries] as a list containing the asset ids of each
  /// library loaded on a script tag. The actual work of computing this is done
  /// in an earlier phase and emited in the `entrypoint._data` asset.
  Future _loadEntryLibraries(_) =>
      transform.readInputAsString(docId.addExtension('._data')).then((data) {
        var map = JSON.decode(data);
        experimentalBootstrap = map['experimental_bootstrap'];
        entryLibraries = map['script_ids']
              .map((id) => new AssetId.deserialize(id))
              .toList();
        return Future.forEach(entryLibraries, logger.addLogFilesFromAsset);
      });

  /// Removes unnecessary script tags, and identifies the main entry point Dart
  /// script tag (if any).
  void _processHtml(_) {
    for (var tag in document.querySelectorAll('script')) {
      var src = tag.attributes['src'];
      if (src == 'packages/polymer/boot.js') {
        tag.remove();
        continue;
      }
      if (tag.attributes['type'] == 'application/dart') {
        logger.warning(INTERNAL_ERROR_UNEXPECTED_SCRIPT, span: tag.sourceSpan);
      }
    }
  }

  /// Emits the main HTML and Dart bootstrap code for the application. If there
  /// were not Dart entry point files, then this simply emits the original HTML.
  Future _emitNewEntrypoint(_) {
    // If we don't find code, there is nothing to do.
    if (entryLibraries.isEmpty) return null;
    return _initResolver()
        .then(_extractUsesOfMirrors)
        .then(_emitFiles)
        .whenComplete(() {
          if (resolver != null) resolver.release();
        });
  }

  /// Load a resolver that computes information for every library in
  /// [entryLibraries], then use it to initialize the [recorder] (for import
  /// resolution) and to resolve specific elements (for analyzing the user's
  /// code).
  Future _initResolver() {
    // We include 'polymer.dart' to simplify how we do resolution below. This
    // way we can assume polymer is there, even if the user didn't include an
    // import to it. If not, the polymer build will fail with an error when
    // trying to create _ResolvedTypes below.
    var libsToLoad = [new AssetId('polymer', 'lib/polymer.dart')]
        ..addAll(entryLibraries);
    return resolvers.get(transform, libsToLoad).then((r) {
      resolver = r;
      types = new _ResolvedTypes(resolver);
    });
  }

  /// Inspects the entire program to find out anything that polymer accesses
  /// using mirrors and produces static information that can be used to replace
  /// the mirror-based loader and the uses of mirrors through the `smoke`
  /// package. This includes:
  ///
  ///   * visiting entry-libraries to extract initializers,
  ///   * visiting polymer-expressions to extract getters and setters,
  ///   * looking for published fields of custom elements, and
  ///   * looking for event handlers and callbacks of change notifications.
  ///
  void _extractUsesOfMirrors(_) {
    // Generate getters and setters needed to evaluate polymer expressions, and
    // extract information about published attributes.
    expressionVisitor = new _SubExpressionVisitor(generator, logger);
    new _HtmlExtractor(logger, generator, publishedAttributes,
        expressionVisitor).visit(document);

    // Create a recorder that uses analyzer data to feed data to [generator].
    var recorder = new Recorder(generator,
        (lib) => resolver.getImportUri(lib, from: bootstrapId).toString());

    // Process all classes and top-level functions to include initializers,
    // register custom elements, and include special fields and methods in
    // custom element classes.
    for (var id in entryLibraries) {
      var lib = resolver.getLibrary(id);
      for (var fun in _visibleTopLevelMethodsOf(lib)) {
        _processFunction(fun, id);
      }

      for (var cls in _visibleClassesOf(lib)) {
        _processClass(cls, id, recorder);
      }
    }
  }

  /// Process a class ([cls]). If it contains an appropriate [CustomTag]
  /// annotation, we include an initializer to register this class, and make
  /// sure to include everything that might be accessed or queried from them
  /// using the smoke package. In particular, polymer uses smoke for the
  /// following:
  ///    * invoke #registerCallback on custom elements classes, if present.
  ///    * query for methods ending in `*Changed`.
  ///    * query for methods with the `@ObserveProperty` annotation.
  ///    * query for non-final properties labeled with `@published`.
  ///    * read declarations of properties named in the `attributes` attribute.
  ///    * read/write the value of published properties .
  ///    * invoke methods in event handlers.
  _processClass(ClassElement cls, AssetId id, Recorder recorder) {
    if (!_hasPolymerMixin(cls)) return;

    // Check whether the class has a @CustomTag annotation. Typically we expect
    // a single @CustomTag, but it's possible to have several.
    var tagNames = [];
    for (var meta in cls.node.metadata) {
      var tagName = _extractTagName(meta, cls);
      if (tagName != null) tagNames.add(tagName);
    }

    if (cls.isPrivate && tagNames.isNotEmpty) {
      var name = tagNames.first;
      logger.error(PRIVATE_CUSTOM_TAG.create(
              {'name': name, 'class': cls.name}),
          span: _spanForNode(cls, cls.node.name));
      return;
    }

    // Include #registerCallback if it exists. Note that by default lookupMember
    // and query will also add the corresponding getters and setters.
    recorder.lookupMember(cls, 'registerCallback');

    // Include methods that end with *Changed.
    recorder.runQuery(cls, new QueryOptions(
          includeFields: false, includeProperties: false,
          includeInherited: true, includeMethods: true,
          includeUpTo: types.htmlElementElement,
          matches: (n) => n.endsWith('Changed') && n != 'attributeChanged'));

    // Include methods marked with @ObserveProperty.
    recorder.runQuery(cls, new QueryOptions(
          includeFields: false, includeProperties: false,
          includeInherited: true, includeMethods: true,
          includeUpTo: types.htmlElementElement,
          withAnnotations: [types.observePropertyElement]));

    // Include @published and @observable properties.
    // Symbols in @published are used when resolving bindings on published
    // attributes, symbols for @observable are used via path observers when
    // implementing *Changed an @ObserveProperty.
    // TODO(sigmund): consider including only those symbols mentioned in
    // *Changed and @ObserveProperty instead.
    recorder.runQuery(cls, new QueryOptions(
          includeUpTo: types.htmlElementElement,
          withAnnotations: [types.publishedElement, types.observableElement,
          types.computedPropertyElement]));

    // Include @ComputedProperty and process their expressions
    var computed = [];
    recorder.runQuery(cls, new QueryOptions(
          includeUpTo: types.htmlElementElement,
          withAnnotations: [types.computedPropertyElement]),
          results: computed);
    _processComputedExpressions(computed);

    for (var tagName in tagNames) {
      // Include an initializer that will call Polymer.register
      initializers.add(new _CustomTagInitializer(id, tagName, cls.displayName));

      // Include also properties published via the `attributes` attribute.
      var attrs = publishedAttributes[tagName];
      if (attrs == null) continue;
      for (var attr in attrs) {
        recorder.lookupMember(cls, attr, recursive: true,
            includeUpTo: types.htmlElementElement);
      }
    }
  }

  /// Determines if [cls] or a supertype has a mixin of the Polymer class.
  bool _hasPolymerMixin(ClassElement cls) {
    while (cls != types.htmlElementElement) {
      for (var m in cls.mixins) {
        if (m.element == types.polymerClassElement) return true;
      }
      if (cls.supertype == null) return false;
      cls = cls.supertype.element;
    }
    return false;
  }

  /// If [meta] is [CustomTag], extract the name associated with the tag.
  String _extractTagName(Annotation meta, ClassElement cls) {
    if (meta.element != types.customTagConstructor) return null;
    return _extractFirstAnnotationArgument(meta, 'CustomTag', cls);
  }

  /// Extract the first argument of an annotation and validate that it's type is
  /// String. For instance, return "bar" from `@Foo("bar")`.
  String _extractFirstAnnotationArgument(Annotation meta, String name,
      analyzer.Element context) {

    // Read argument from the AST
    var args = meta.arguments.arguments;
    if (args == null || args.length == 0) {
      logger.warning(MISSING_ANNOTATION_ARGUMENT.create({'name': name}),
          span: _spanForNode(context, meta));
      return null;
    }

    var lib = context;
    while (lib is! LibraryElement) lib = lib.enclosingElement;
    var res = resolver.evaluateConstant(lib, args[0]);
    if (!res.isValid || res.value.type != types.stringType) {
      logger.warning(INVALID_ANNOTATION_ARGUMENT.create({'name': name}),
          span: _spanForNode(context, args[0]));
      return null;
    }
    return res.value.stringValue;
  }

  /// Adds the top-level [function] as an initalizer if it's marked with
  /// `@initMethod`.
  _processFunction(FunctionElement function, AssetId id) {
    bool initMethodFound = false;
    for (var meta in function.metadata) {
      var e = meta.element;
      if (e is PropertyAccessorElement &&
          e.variable == types.initMethodElement) {
        initMethodFound = true;
        break;
      }
    }
    if (!initMethodFound) return;
    if (function.isPrivate) {
      logger.error(PRIVATE_INIT_METHOD.create({'name': function.displayName}),
          span: _spanForNode(function, function.node.name));
      return;
    }
    initializers.add(new _InitMethodInitializer(id, function.displayName));
  }

  /// Process members that are annotated with `@ComputedProperty` and records
  /// the accessors of their expressions.
  _processComputedExpressions(List<analyzer.Element> computed) {
    var constructor = types.computedPropertyElement.constructors.first;
    for (var member in computed) {
      for (var meta in member.node.metadata) {
        if (meta.element != constructor) continue;
        var expr = _extractFirstAnnotationArgument(
            meta, 'ComputedProperty', member);
        if (expr == null) continue;
        expressionVisitor.run(pe.parse(expr), true,
            _spanForNode(member.enclosingElement, meta.arguments.arguments[0]));
      }
    }
  }

  /// Writes the final output for the bootstrap Dart file and entrypoint HTML
  /// file.
  void _emitFiles(_) {
    StringBuffer code = new StringBuffer()..writeln(MAIN_HEADER);
    Map<AssetId, String> prefixes = {};
    int i = 0;
    for (var id in entryLibraries) {
      var url = assetUrlFor(id, bootstrapId, logger);
      if (url == null) continue;
      code.writeln("import '$url' as i$i;");
      if (options.injectBuildLogsInOutput) {
        code.writeln("import 'package:polymer/src/build/log_injector.dart';");
      }
      prefixes[id] = 'i$i';
      i++;
    }

    // Include smoke initialization.
    generator.writeImports(code);
    generator.writeTopLevelDeclarations(code);
    code.writeln('\nvoid main() {');
    code.write('  useGeneratedCode(');
    generator.writeStaticConfiguration(code);
    code.writeln(');');

    if (options.injectBuildLogsInOutput) {
      var buildUrl = "${path.basename(docId.path)}$LOG_EXTENSION";
      code.writeln("  new LogInjector().injectLogsFromUrl('$buildUrl');");
    }

    if (experimentalBootstrap) {
      code.write('  startPolymer([');
    } else {
      code.write('  configureForDeployment([');
    }

    // Include initializers to switch from mirrors_loader to static_loader.
    if (!initializers.isEmpty) {
      code.writeln();
      for (var init in initializers) {
        var initCode = init.asCode(prefixes[init.assetId]);
        code.write("      $initCode,\n");
      }
      code.writeln('    ]);');
    } else {
      if (experimentalBootstrap) logger.warning(NO_INITIALIZATION);
      code.writeln(']);');
    }
    if (!experimentalBootstrap) {
      code.writeln('  i${entryLibraries.length - 1}.main();');
    }

    // End of main().
    code.writeln('}');
    transform.addOutput(new Asset.fromString(bootstrapId, code.toString()));


    // Emit the bootstrap .dart file
    var srcUrl = path.url.basename(bootstrapId.path);
    document.body.nodes.add(parseFragment(
        '<script type="application/dart" src="$srcUrl"></script>'));

    // Add the styles for the logger widget.
    if (options.injectBuildLogsInOutput) {
      document.head.append(parseFragment(
          '<link rel="stylesheet" type="text/css"'
          ' href="packages/polymer/src/build/log_injector.css">'));
    }

    transform.addOutput(new Asset.fromString(docId, document.outerHtml));
  }

  _spanForNode(analyzer.Element context, AstNode node) {
    var file = resolver.getSourceFile(context);
    return file.span(node.offset, node.end);
  }
}

abstract class _Initializer {
  AssetId get assetId;
  String get symbolName;
  String asCode(String prefix);
}

class _InitMethodInitializer implements _Initializer {
  final AssetId assetId;
  final String methodName;
  String get symbolName => methodName;
  _InitMethodInitializer(this.assetId, this.methodName);

  String asCode(String prefix) => "$prefix.$methodName";
}

class _CustomTagInitializer implements _Initializer {
  final AssetId assetId;
  final String tagName;
  final String typeName;
  String get symbolName => typeName;
  _CustomTagInitializer(this.assetId, this.tagName, this.typeName);

  String asCode(String prefix) =>
      "() => Polymer.register('$tagName', $prefix.$typeName)";
}

const MAIN_HEADER = """
library app_bootstrap;

import 'package:polymer/polymer.dart';
""";


/// An html visitor that:
///   * finds all polymer expressions and records the getters and setters that
///     will be needed to evaluate them at runtime.
///   * extracts all attributes declared in the `attribute` attributes of
///     polymer elements.
class _HtmlExtractor extends TreeVisitor {
  final Map<String, List<String>> publishedAttributes;
  final SmokeCodeGenerator generator;
  final _SubExpressionVisitor expressionVisitor;
  final BuildLogger logger;
  bool _inTemplate = false;

  _HtmlExtractor(this.logger, this.generator, this.publishedAttributes,
      this.expressionVisitor);

  void visitElement(Element node) {
    if (_inTemplate) _processNormalElement(node);
    if (node.localName == 'polymer-element') {
      _processPolymerElement(node);
      _processNormalElement(node);
    }

    if (node.localName == 'template') {
      var last = _inTemplate;
      _inTemplate = true;
      super.visitElement(node);
      _inTemplate = last;
    } else {
      super.visitElement(node);
    }
  }

  void visitText(Text node) {
    if (!_inTemplate) return;
    var bindings = _Mustaches.parse(node.data);
    if (bindings == null) return;
    for (var e in bindings.expressions) {
      _addExpression(e, false, false, node.sourceSpan);
    }
  }

  /// Registers getters and setters for all published attributes.
  void _processPolymerElement(Element node) {
    var tagName = node.attributes['name'];
    var value = node.attributes['attributes'];
    if (value != null) {
      publishedAttributes[tagName] =
          value.split(ATTRIBUTES_REGEX).map((a) => a.trim()).toList();
    }
  }

  /// Produces warnings for misuses of on-foo event handlers, and for instanting
  /// custom tags incorrectly.
  void _processNormalElement(Element node) {
    var tag = node.localName;
    var isCustomTag = isCustomTagName(tag) || node.attributes['is'] != null;

    // Event handlers only allowed inside polymer-elements
    node.attributes.forEach((name, value) {
      var bindings = _Mustaches.parse(value);
      if (bindings == null) return;
      var isEvent = false;
      var isTwoWay = false;
      if (name is String) {
        name = name.toLowerCase();
        isEvent = name.startsWith('on-');
        isTwoWay = !isEvent && bindings.isWhole && (isCustomTag ||
            tag == 'input' && (name == 'value' || name =='checked') ||
            tag == 'select' && (name == 'selectedindex' || name == 'value') ||
            tag == 'textarea' && name == 'value');
      }
      for (var exp in bindings.expressions) {
        _addExpression(exp, isEvent, isTwoWay, node.sourceSpan);
      }
    });
  }

  void _addExpression(String stringExpression, bool inEvent, bool isTwoWay,
      SourceSpan span) {

    if (inEvent) {
      if (stringExpression.startsWith('@')) {
        logger.warning(AT_EXPRESSION_REMOVED, span: span);
        return;
      }

      if (stringExpression == '') return;
      if (stringExpression.startsWith('_')) {
        logger.warning(NO_PRIVATE_EVENT_HANDLERS, span: span);
        return;
      }
      generator.addGetter(stringExpression);
      generator.addSymbol(stringExpression);
    }
    expressionVisitor.run(pe.parse(stringExpression), isTwoWay, span);
  }
}

/// A polymer-expression visitor that records every getter and setter that will
/// be needed to evaluate a single expression at runtime.
class _SubExpressionVisitor extends pe.RecursiveVisitor {
  final SmokeCodeGenerator generator;
  final BuildLogger logger;
  bool _includeSetter;
  SourceSpan _currentSpan;

  _SubExpressionVisitor(this.generator, this.logger);

  /// Visit [exp], and record getters and setters that are needed in order to
  /// evaluate it at runtime. [includeSetter] is only true if this expression
  /// occured in a context where it could be updated, for example in two-way
  /// bindings such as `<input value={{exp}}>`.
  void run(pe.Expression exp, bool includeSetter, span) {
    _currentSpan = span;
    _includeSetter = includeSetter;
    visit(exp);
  }

  /// Adds a getter and symbol for [name], and optionally a setter.
  _add(String name) {
    if (name.startsWith('_')) {
      logger.warning(NO_PRIVATE_SYMBOLS_IN_BINDINGS, span: _currentSpan);
      return;
    }
    generator.addGetter(name);
    generator.addSymbol(name);
    if (_includeSetter) generator.addSetter(name);
  }

  void preVisitExpression(e) {
    // For two-way bindings the outermost expression may be updated, so we need
    // both the getter and the setter, but we only need the getter for
    // subexpressions. We exclude setters as soon as we go deeper in the tree,
    // except when we see a filter (that can potentially be a two-way
    // transformer).
    if (e is pe.BinaryOperator && e.operator == '|') return;
    _includeSetter = false;
  }

  visitIdentifier(pe.Identifier e) {
    if (e.value != 'this') _add(e.value);
    super.visitIdentifier(e);
  }

  visitGetter(pe.Getter e) {
    _add(e.name);
    super.visitGetter(e);
  }

  visitInvoke(pe.Invoke e) {
    _includeSetter = false; // Invoke is only valid as an r-value.
    if (e.method != null) _add(e.method);
    super.visitInvoke(e);
  }
}

/// Parses and collects information about bindings found in polymer templates.
class _Mustaches {
  /// Each expression that appears within `{{...}}` and `[[...]]`.
  final List<String> expressions;

  /// Whether the whole text returned by [parse] was a single expression.
  final bool isWhole;

  _Mustaches(this.isWhole, this.expressions);

  static _Mustaches parse(String text) {
    if (text == null || text.isEmpty) return null;
    // Use template-binding's parser, but provide a delegate function factory to
    // save the expressions without parsing them as [PropertyPath]s.
    var tokens = MustacheTokens.parse(text, (s) => () => s);
    if (tokens == null) return null;
    var length = tokens.length;
    bool isWhole = length == 1 && tokens.getText(length) == '' &&
        tokens.getText(0) == '';
    var expressions = new List(length);
    for (int i = 0; i < length; i++) {
      expressions[i] = tokens.getPrepareBinding(i)();
    }
    return new _Mustaches(isWhole, expressions);
  }
}

/// Holds types that are used in queries
class _ResolvedTypes {
  /// Element representing `HtmlElement`.
  final ClassElement htmlElementElement;

  /// Element representing `String`.
  final InterfaceType stringType;

  /// Element representing `Polymer`.
  final ClassElement polymerClassElement;

  /// Element representing the constructor of `@CustomTag`.
  final ConstructorElement customTagConstructor;

  /// Element representing the type of `@published`.
  final ClassElement publishedElement;

  /// Element representing the type of `@observable`.
  final ClassElement observableElement;

  /// Element representing the type of `@ObserveProperty`.
  final ClassElement observePropertyElement;

  /// Element representing the type of `@ComputedProperty`.
  final ClassElement computedPropertyElement;

  /// Element representing the `@initMethod` annotation.
  final TopLevelVariableElement initMethodElement;


  factory _ResolvedTypes(Resolver resolver) {
    // Load class elements that are used in queries for codegen.
    var polymerLib = resolver.getLibrary(
        new AssetId('polymer', 'lib/polymer.dart'));
    if (polymerLib == null) _definitionError('the polymer library');

    var htmlLib = resolver.getLibraryByUri(Uri.parse('dart:html'));
    if (htmlLib == null) _definitionError('the "dart:html" library');

    var coreLib = resolver.getLibraryByUri(Uri.parse('dart:core'));
    if (coreLib == null) _definitionError('the "dart:core" library');

    var observeLib = resolver.getLibrary(
        new AssetId('observe', 'lib/src/metadata.dart'));
    if (observeLib == null) _definitionError('the observe library');

    var initMethodElement = null;
    for (var unit in polymerLib.parts) {
      if (unit.uri == 'src/loader.dart') {
        initMethodElement = unit.topLevelVariables.firstWhere(
            (t) => t.displayName == 'initMethod');
        break;
      }
    }
    var customTagConstructor =
        _lookupType(polymerLib, 'CustomTag').constructors.first;
    var publishedElement = _lookupType(polymerLib, 'PublishedProperty');
    var observableElement = _lookupType(observeLib, 'ObservableProperty');
    var observePropertyElement = _lookupType(polymerLib, 'ObserveProperty');
    var computedPropertyElement = _lookupType(polymerLib, 'ComputedProperty');
    var polymerClassElement = _lookupType(polymerLib, 'Polymer');
    var htmlElementElement = _lookupType(htmlLib, 'HtmlElement');
    var stringType = _lookupType(coreLib, 'String').type;
    if (initMethodElement == null) _definitionError('@initMethod');

    return new _ResolvedTypes.internal(htmlElementElement, stringType,
      polymerClassElement, customTagConstructor, publishedElement,
      observableElement, observePropertyElement, computedPropertyElement,
      initMethodElement);
  }

  _ResolvedTypes.internal(this.htmlElementElement, this.stringType,
      this.polymerClassElement, this.customTagConstructor,
      this.publishedElement, this.observableElement,
      this.observePropertyElement, this.computedPropertyElement,
      this.initMethodElement);

  static _lookupType(LibraryElement lib, String typeName) {
    var result = lib.getType(typeName);
    if (result == null) _definitionError(typeName);
    return result;
  }

  static _definitionError(name) {
    throw new StateError("Internal error in polymer-builder: couldn't find "
        "definition of $name.");
  }
}

/// Retrieves all classses that are visible if you were to import [lib]. This
/// includes exported classes from other libraries.
List<ClassElement> _visibleClassesOf(LibraryElement lib) {
  var result = [];
  result.addAll(lib.units.expand((u) => u.types));
  for (var e in lib.exports) {
    var exported = e.exportedLibrary.units.expand((u) => u.types).toList();
    _filter(exported, e.combinators);
    result.addAll(exported);
  }
  return result;
}

/// Retrieves all top-level methods that are visible if you were to import
/// [lib]. This includes exported methods from other libraries too.
List<FunctionElement> _visibleTopLevelMethodsOf(LibraryElement lib) {
  var result = [];
  result.addAll(lib.units.expand((u) => u.functions));
  for (var e in lib.exports) {
    var exported = e.exportedLibrary.units
        .expand((u) => u.functions).toList();
    _filter(exported, e.combinators);
    result.addAll(exported);
  }
  return result;
}

/// Filters [elements] that come from an export, according to its show/hide
/// combinators. This modifies [elements] in place.
void _filter(List<analyzer.Element> elements,
    List<NamespaceCombinator> combinators) {
  for (var c in combinators) {
    if (c is ShowElementCombinator) {
      var show = c.shownNames.toSet();
      elements.retainWhere((e) => show.contains(e.displayName));
    } else if (c is HideElementCombinator) {
      var hide = c.hiddenNames.toSet();
      elements.removeWhere((e) => hide.contains(e.displayName));
    }
  }
}
