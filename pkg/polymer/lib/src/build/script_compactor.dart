// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transfomer that combines multiple dart script tags into a single one.
library polymer.src.build.script_compactor;

import 'dart:async';
import 'dart:convert';

import 'package:html5lib/dom.dart' show Document, Element;
import 'package:analyzer/src/generated/ast.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:source_maps/span.dart' show SourceFile;

import 'import_inliner.dart' show ImportInliner; // just for docs.
import 'common.dart';

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
  final TransformOptions options;

  ScriptCompactor(this.options);

  /// Only run on entry point .html files.
  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isHtmlEntryPoint(input.id));

  Future apply(Transform transform) =>
      new _ScriptCompactor(transform, options).apply();
}

/// Helper class mainly use to flatten the async code.
class _ScriptCompactor extends PolymerTransformer {
  final TransformOptions options;
  final Transform transform;
  final TransformLogger logger;
  final AssetId docId;
  final AssetId bootstrapId;

  Document document;
  List<AssetId> entryLibraries;
  AssetId mainLibraryId;
  Element mainScriptTag;
  final Map<AssetId, List<_Initializer>> initializers = {};

  _ScriptCompactor(Transform transform, this.options)
      : transform = transform,
        logger = transform.logger,
        docId = transform.primaryInput.id,
        bootstrapId = transform.primaryInput.id.addExtension('_bootstrap.dart');

  Future apply() =>
      _loadDocument()
      .then(_loadEntryLibraries)
      .then(_processHtml)
      .then(_emitNewEntrypoint);

  /// Loads the primary input as an html document.
  Future _loadDocument() =>
      readPrimaryAsHtml(transform).then((doc) { document = doc; });

  /// Populates [entryLibraries] as a list containing the asset ids of each
  /// library loaded on a script tag. The actual work of computing this is done
  /// in an earlier phase and emited in the `entrypoint.scriptUrls` asset.
  Future _loadEntryLibraries(_) =>
      transform.readInputAsString(docId.addExtension('.scriptUrls'))
          .then((libraryIds) {
        entryLibraries = (JSON.decode(libraryIds) as Iterable)
            .map((data) => new AssetId.deserialize(data)).toList();
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
      if (tag.attributes['type'] != 'application/dart') continue;
      if (src == null) {
        logger.warning('unexpected script without a src url. The '
          'ScriptCompactor transformer should run after running the '
          'InlineCodeExtractor', span: tag.sourceSpan);
        continue;
      }
      if (mainLibraryId != null) {
        logger.warning('unexpected script. Only one Dart script tag '
          'per document is allowed.', span: tag.sourceSpan);
        tag.remove();
        continue;
      }
      mainLibraryId = resolve(docId, src, logger, tag.sourceSpan);
      mainScriptTag = tag;
    }
  }

  /// Emits the main HTML and Dart bootstrap code for the application. If there
  /// were not Dart entry point files, then this simply emits the original HTML.
  Future _emitNewEntrypoint(_) {
    if (mainScriptTag == null) {
      // We didn't find any main library, nothing to do.
      transform.addOutput(transform.primaryInput);
      return null;
    }

    // Emit the bootstrap .dart file
    mainScriptTag.attributes['src'] = path.url.basename(bootstrapId.path);
    entryLibraries.add(mainLibraryId);
    return _computeInitializers().then(_createBootstrapCode).then((code) {
      transform.addOutput(new Asset.fromString(bootstrapId, code));
      transform.addOutput(new Asset.fromString(docId, document.outerHtml));
    });
  }

  /// Emits the actual bootstrap code.
  String _createBootstrapCode(_) {
    StringBuffer code = new StringBuffer()..writeln(MAIN_HEADER);
    for (int i = 0; i < entryLibraries.length; i++) {
      var url = assetUrlFor(entryLibraries[i], bootstrapId, logger);
      if (url != null) code.writeln("import '$url' as i$i;");
    }

    code..write('\n')
        ..writeln('void main() {')
        ..writeln('  configureForDeployment([');

    // Inject @CustomTag and @initMethod initializations for each library
    // that is sourced in a script tag.
    for (int i = 0; i < entryLibraries.length; i++) {
      for (var init in initializers[entryLibraries[i]]) {
        var initCode = init.asCode('i$i');
        code.write("      $initCode,\n");
      }
    }
    code..writeln('    ]);')
        ..writeln('  i${entryLibraries.length - 1}.main();')
        ..writeln('}');
    return code.toString();
  }

  /// Computes initializers needed for each library in [entryLibraries]. Results
  /// are available afterwards in [initializers].
  Future _computeInitializers() => Future.forEach(entryLibraries, (lib) {
      return _initializersOf(lib).then((res) {
        initializers[lib] = res;
      });
    });

  /// Computes the initializers of [dartLibrary]. That is, a closure that calls
  /// Polymer.register for each @CustomTag, and any public top-level methods
  /// labeled with @initMethod.
  Future<List<_Initializer>> _initializersOf(AssetId dartLibrary) {
    var result = [];
    return transform.readInputAsString(dartLibrary).then((code) {
      var file = new SourceFile.text(_simpleUriForSource(dartLibrary), code);
      var unit = parseCompilationUnit(code);

      return Future.forEach(unit.directives, (directive) {
        // Include anything from parts.
        if (directive is PartDirective) {
          var targetId = resolve(dartLibrary, directive.uri.stringValue,
              logger, _getSpan(file, directive));
          return _initializersOf(targetId).then(result.addAll);
        }

        // Similarly, include anything from exports except what's filtered by
        // the show/hide combinators.
        if (directive is ExportDirective) {
          var targetId = resolve(dartLibrary, directive.uri.stringValue,
              logger, _getSpan(file, directive));
          return _initializersOf(targetId).then(
            (r) => _processExportDirective(directive, r, result));
        }
      }).then((_) {
        // Scan the code for classes and top-level functions.
        for (var node in unit.declarations) {
          if (node is ClassDeclaration) {
            _processClassDeclaration(node, result, file, logger);
          } else if (node is FunctionDeclaration &&
              node.metadata.any(_isInitMethodAnnotation)) {
            _processFunctionDeclaration(node, result, file, logger);
          }
        }
        return result;
      });
    });
  }

  static String _simpleUriForSource(AssetId source) =>
      source.path.startsWith('lib/')
      ? 'package:${source.package}/${source.path.substring(4)}' : source.path;

  /// Filter [exportedInitializers] according to [directive]'s show/hide
  /// combinators and add the result to [result].
  // TODO(sigmund): call the analyzer's resolver instead?
  static _processExportDirective(ExportDirective directive,
      List<_Initializer> exportedInitializers,
      List<_Initializer> result) {
    for (var combinator in directive.combinators) {
      if (combinator is ShowCombinator) {
        var show = combinator.shownNames.map((n) => n.name).toSet();
        exportedInitializers.retainWhere((e) => show.contains(e.symbolName));
      } else if (combinator is HideCombinator) {
        var hide = combinator.hiddenNames.map((n) => n.name).toSet();
        exportedInitializers.removeWhere((e) => hide.contains(e.symbolName));
      }
    }
    result.addAll(exportedInitializers);
  }

  /// Add an initializer to register [node] as a polymer element if it contains
  /// an appropriate [CustomTag] annotation.
  static _processClassDeclaration(ClassDeclaration node,
      List<_Initializer> result, SourceFile file,
      TransformLogger logger) {
    for (var meta in node.metadata) {
      if (!_isCustomTagAnnotation(meta)) continue;
      var args = meta.arguments.arguments;
      if (args == null || args.length == 0) {
        logger.error('Missing argument in @CustomTag annotation',
            span: _getSpan(file, meta));
        continue;
      }

      var tagName = args[0].stringValue;
      var typeName = node.name.name;
      if (typeName.startsWith('_')) {
        logger.error('@CustomTag is no longer supported on private '
          'classes: $tagName', span: _getSpan(file, node.name));
        continue;
      }
      result.add(new _CustomTagInitializer(tagName, typeName));
    }
  }

  /// Add a method initializer for [function].
  static _processFunctionDeclaration(FunctionDeclaration function,
      List<_Initializer> result, SourceFile file,
      TransformLogger logger) {
    var name = function.name.name;
    if (name.startsWith('_')) {
      logger.error('@initMethod is no longer supported on private '
        'functions: $name', span: _getSpan(file, function.name));
      return;
    }
    result.add(new _InitMethodInitializer(name));
  }
}

// TODO(sigmund): consider support for importing annotations with prefixes.
bool _isInitMethodAnnotation(Annotation node) =>
    node.name.name == 'initMethod' && node.constructorName == null &&
    node.arguments == null;
bool _isCustomTagAnnotation(Annotation node) => node.name.name == 'CustomTag';

abstract class _Initializer {
  String get symbolName;
  String asCode(String prefix);
}

class _InitMethodInitializer implements _Initializer {
  String methodName;
  String get symbolName => methodName;
  _InitMethodInitializer(this.methodName);

  String asCode(String prefix) => "$prefix.$methodName";
}

class _CustomTagInitializer implements _Initializer {
  String tagName;
  String typeName;
  String get symbolName => typeName;
  _CustomTagInitializer(this.tagName, this.typeName);

  String asCode(String prefix) =>
      "() => Polymer.register('$tagName', $prefix.$typeName)";
}

_getSpan(SourceFile file, AstNode node) => file.span(node.offset, node.end);

const MAIN_HEADER = """
library app_bootstrap;

import 'package:polymer/polymer.dart';
import 'package:smoke/static.dart' as smoke;
""";
