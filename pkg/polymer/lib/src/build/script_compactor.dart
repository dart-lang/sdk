// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transfomer that combines multiple dart script tags into a single one.
library polymer.src.build.script_compactor;

import 'dart:async';
import 'dart:convert';

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
class ScriptCompactor extends Transformer with PolymerTransformer {
  final TransformOptions options;

  ScriptCompactor(this.options);

  /// Only run on entry point .html files.
  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isHtmlEntryPoint(input.id));

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    var secondaryId = id.addExtension('.scriptUrls');
    var logger = transform.logger;
    return readPrimaryAsHtml(transform).then((document) {
      return transform.readInputAsString(secondaryId).then((libraryIds) {
        var libraries = (JSON.decode(libraryIds) as Iterable).map(
          (data) => new AssetId.deserialize(data)).toList();
        var mainLibraryId;
        var mainScriptTag;
        bool changed = false;

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
          mainLibraryId = resolve(id, src, logger, tag.sourceSpan);
          mainScriptTag = tag;
        }

        if (mainScriptTag == null) {
          // We didn't find any main library, nothing to do.
          transform.addOutput(transform.primaryInput);
          return null;
        }

        // Emit the bootstrap .dart file
        var bootstrapId = id.addExtension('_bootstrap.dart');
        mainScriptTag.attributes['src'] =
            path.url.basename(bootstrapId.path);

        libraries.add(mainLibraryId);
        var urls = libraries.map((id) => assetUrlFor(id, bootstrapId, logger))
            .where((url) => url != null).toList();
        var buffer = new StringBuffer()..writeln(MAIN_HEADER);
        int i = 0;
        for (; i < urls.length; i++) {
          buffer.writeln("import '${urls[i]}' as i$i;");
        }

        buffer..write('\n')
            ..writeln('void main() {')
            ..writeln('  configureForDeployment([');

        // Inject @CustomTag and @initMethod initializations for each library
        // that is sourced in a script tag.
        i = 0;
        return Future.forEach(libraries, (lib) {
          return _initializersOf(lib, transform, logger).then((initializers) {
            for (var init in initializers) {
              var code = init.asCode('i$i');
              buffer.write("      $code,\n");
            }
            i++;
          });
        }).then((_) {
          buffer..writeln('    ]);')
              ..writeln('  i${urls.length - 1}.main();')
              ..writeln('}');

          transform.addOutput(new Asset.fromString(
                bootstrapId, buffer.toString()));
          transform.addOutput(new Asset.fromString(id, document.outerHtml));
        });
      });
    });
  }

  /// Computes the initializers of [dartLibrary]. That is, a closure that calls
  /// Polymer.register for each @CustomTag, and any public top-level methods
  /// labeled with @initMethod.
  Future<List<_Initializer>> _initializersOf(
      AssetId dartLibrary, Transform transform, TransformLogger logger) {
    var initializers = [];
    return transform.readInputAsString(dartLibrary).then((code) {
      var file = new SourceFile.text(_simpleUriForSource(dartLibrary), code);
      var unit = parseCompilationUnit(code);

      return Future.forEach(unit.directives, (directive) {
        // Include anything from parts.
        if (directive is PartDirective) {
          var targetId = resolve(dartLibrary, directive.uri.stringValue,
              logger, _getSpan(file, directive));
          return _initializersOf(targetId, transform, logger)
              .then(initializers.addAll);
        }

        // Similarly, include anything from exports except what's filtered by
        // the show/hide combinators.
        if (directive is ExportDirective) {
          var targetId = resolve(dartLibrary, directive.uri.stringValue,
              logger, _getSpan(file, directive));
          return _initializersOf(targetId, transform, logger)
              .then((r) => _processExportDirective(directive, r, initializers));
        }
      }).then((_) {
        // Scan the code for classes and top-level functions.
        for (var node in unit.declarations) {
          if (node is ClassDeclaration) {
            _processClassDeclaration(node, initializers, file, logger);
          } else if (node is FunctionDeclaration &&
              node.metadata.any(_isInitMethodAnnotation)) {
            _processFunctionDeclaration(node, initializers, file, logger);
          }
        }
        return initializers;
      });
    });
  }

  static String _simpleUriForSource(AssetId source) =>
      source.path.startsWith('lib/')
      ? 'package:${source.package}/${source.path.substring(4)}' : source.path;

  /// Filter [exportedInitializers] according to [directive]'s show/hide
  /// combinators and add the result to [initializers].
  // TODO(sigmund): call the analyzer's resolver instead?
  static _processExportDirective(ExportDirective directive,
      List<_Initializer> exportedInitializers,
      List<_Initializer> initializers) {
    for (var combinator in directive.combinators) {
      if (combinator is ShowCombinator) {
        var show = combinator.shownNames.map((n) => n.name).toSet();
        exportedInitializers.retainWhere((e) => show.contains(e.symbolName));
      } else if (combinator is HideCombinator) {
        var hide = combinator.hiddenNames.map((n) => n.name).toSet();
        exportedInitializers.removeWhere((e) => hide.contains(e.symbolName));
      }
    }
    initializers.addAll(exportedInitializers);
  }

  /// Add an initializer to register [node] as a polymer element if it contains
  /// an appropriate [CustomTag] annotation.
  static _processClassDeclaration(ClassDeclaration node,
      List<_Initializer> initializers, SourceFile file,
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
      initializers.add(new _CustomTagInitializer(tagName, typeName));
    }
  }

  /// Add a method initializer for [function].
  static _processFunctionDeclaration(FunctionDeclaration function,
      List<_Initializer> initializers, SourceFile file,
      TransformLogger logger) {
    var name = function.name.name;
    if (name.startsWith('_')) {
      logger.error('@initMethod is no longer supported on private '
        'functions: $name', span: _getSpan(file, function.name));
      return;
    }
    initializers.add(new _InitMethodInitializer(name));
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
""";
