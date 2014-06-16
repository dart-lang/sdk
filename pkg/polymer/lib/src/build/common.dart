// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common methods used by transfomers.
library polymer.src.build.common;

import 'dart:async';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart' show Document;
import 'package:html5lib/parser.dart' show HtmlParser;
import 'package:path/path.dart' as path;
import 'package:observe/transformer.dart' show ObservableTransformer;
import 'package:source_maps/span.dart' show Span;

const _ignoredErrors = const [
  'unexpected-dash-after-double-dash-in-comment',
  'unexpected-char-in-comment',
];

/// Parses an HTML file [contents] and returns a DOM-like tree. Adds emitted
/// error/warning to [logger].
Document _parseHtml(String contents, String sourcePath, TransformLogger logger,
    {bool checkDocType: true, bool showWarnings: true}) {
  // TODO(jmesserly): make HTTP encoding configurable
  var parser = new HtmlParser(contents, encoding: 'utf8',
      generateSpans: true, sourceUrl: sourcePath);
  var document = parser.parse();

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  if (showWarnings) {
    for (var e in parser.errors) {
      if (_ignoredErrors.contains(e.errorCode)) continue;
      if (checkDocType || e.errorCode != 'expected-doctype-but-got-start-tag') {
        logger.warning(e.message, span: e.span);
      }
    }
  }
  return document;
}

/// Additional options used by polymer transformers
class TransformOptions {
  /// List of entrypoints paths. The paths are relative to the package root and
  /// are represented using posix style, which matches the representation used
  /// in asset ids in barback. If null, anything under 'web/' or 'test/' is
  /// considered an entry point.
  final List<String> entryPoints;

  /// True to enable Content Security Policy.
  /// This means the HTML page will include *.dart.precompiled.js
  ///
  /// This flag has no effect unless [directlyIncludeJS] is enabled.
  final bool contentSecurityPolicy;

  /// True to include the compiled JavaScript directly from the HTML page.
  /// If enabled this will remove "packages/browser/dart.js" and replace
  /// `type="application/dart"` scripts with equivalent *.dart.js files.
  ///
  /// If [contentSecurityPolicy] enabled, this will reference files
  /// named *.dart.precompiled.js.
  final bool directlyIncludeJS;

  /// Run transformers to create a releasable app. For example, include the
  /// minified versions of the polyfills rather than the debug versions.
  final bool releaseMode;

  /// True to run liner on all html files before starting other phases.
  // TODO(jmesserly): instead of this flag, we should only run linter on
  // reachable (entry point+imported) html if deploying. See dartbug.com/17199.
  final bool lint;

  TransformOptions({entryPoints, this.contentSecurityPolicy: false,
      this.directlyIncludeJS: true, this.releaseMode: true, this.lint: true})
      : entryPoints = entryPoints == null ? null
          : entryPoints.map(_systemToAssetPath).toList();

  /// Whether an asset with [id] is an entry point HTML file.
  bool isHtmlEntryPoint(AssetId id) {
    if (id.extension != '.html') return false;

    // Note: [id.path] is a relative path from the root of a package.
    if (entryPoints == null) {
      return id.path.startsWith('web/') || id.path.startsWith('test/');
    }

    return entryPoints.contains(id.path);
  }
}

/// Mixin for polymer transformers.
abstract class PolymerTransformer {
  TransformOptions get options;

  Future<Document> readPrimaryAsHtml(Transform transform) {
    var asset = transform.primaryInput;
    var id = asset.id;
    return asset.readAsString().then((content) {
      return _parseHtml(content, id.path, transform.logger,
        checkDocType: options.isHtmlEntryPoint(id));
    });
  }

  Future<Document> readAsHtml(AssetId id, Transform transform,
      {bool showWarnings: true}) {
    var primaryId = transform.primaryInput.id;
    bool samePackage = id.package == primaryId.package;
    var url = spanUrlFor(id, transform);
    return transform.readInputAsString(id).then((content) {
      return _parseHtml(content, url, transform.logger,
        checkDocType: samePackage && options.isHtmlEntryPoint(id),
        showWarnings: showWarnings);
    });
  }

  Future<bool> assetExists(AssetId id, Transform transform) =>
      transform.getInput(id).then((_) => true).catchError((_) => false);

  String toString() => 'polymer ($runtimeType)';
}

/// Gets the appropriate URL to use in a [Span] to produce messages
/// (e.g. warnings) for users. This will attempt to format the URL in the most
/// useful way:
///
/// - If the asset is within the primary package, then use the [id.path],
///   the user will know it is a file from their own code.
/// - If the asset is from another package, then use [assetUrlFor], this will
///   likely be a "package:" url to the file in the other package, which is
///   enough for users to identify where the error is.
String spanUrlFor(AssetId id, Transform transform) {
  var primaryId = transform.primaryInput.id;
  bool samePackage = id.package == primaryId.package;
  return samePackage ? id.path
      : assetUrlFor(id, primaryId, transform.logger, allowAssetUrl: true);
}

/// Transformer phases which should be applied to the Polymer package.
List<List<Transformer>> get phasesForPolymer =>
    [[new ObservableTransformer(['lib/src/instance.dart'])]];

/// Generate the import url for a file described by [id], referenced by a file
/// with [sourceId].
// TODO(sigmund): this should also be in barback (dartbug.com/12610)
String assetUrlFor(AssetId id, AssetId sourceId, TransformLogger logger,
    {bool allowAssetUrl: false}) {
  // use package: and asset: urls if possible
  if (id.path.startsWith('lib/')) {
    return 'package:${id.package}/${id.path.substring(4)}';
  }

  if (id.path.startsWith('asset/')) {
    if (!allowAssetUrl) {
      logger.error("asset urls not allowed. "
          "Don't know how to refer to $id from $sourceId");
      return null;
    }
    return 'asset:${id.package}/${id.path.substring(6)}';
  }

  // Use relative urls only if it's possible.
  if (id.package != sourceId.package) {
    logger.error("don't know how to refer to $id from $sourceId");
    return null;
  }

  var builder = path.url;
  return builder.relative(builder.join('/', id.path),
      from: builder.join('/', builder.dirname(sourceId.path)));
}


/// Convert system paths to asset paths (asset paths are posix style).
String _systemToAssetPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.posix.joinAll(path.split(assetPath));
}

/// These names have meaning in SVG or MathML, so they aren't allowed as custom
/// tags. See [isCustomTagName].
const invalidTagNames = const {
  'annotation-xml': '',
  'color-profile': '',
  'font-face': '',
  'font-face-src': '',
  'font-face-uri': '',
  'font-face-format': '',
  'font-face-name': '',
  'missing-glyph': '',
};

/// Returns true if this is a valid custom element name. See:
/// <http://w3c.github.io/webcomponents/spec/custom/#dfn-custom-element-type>
bool isCustomTagName(String name) {
  if (name == null || !name.contains('-')) return false;
  return !invalidTagNames.containsKey(name);
}

/// Regex to split names in the 'attributes' attribute, which supports 'a b c',
/// 'a,b,c', or even 'a b,c'. This is the same as in `lib/src/declaration.dart`.
final ATTRIBUTES_REGEX = new RegExp(r'\s|,');

const POLYMER_EXPERIMENTAL_HTML = 'packages/polymer/polymer_experimental.html';
