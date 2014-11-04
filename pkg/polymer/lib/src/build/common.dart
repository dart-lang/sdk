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
import 'package:code_transformers/messages/build_logger.dart';
import 'package:html5lib/dom.dart' show Document;
import 'package:html5lib/parser.dart' show HtmlParser;
import 'package:observe/transformer.dart' show ObservableTransformer;
import 'package:path/path.dart' as path;

import 'constants.dart';
import 'messages.dart';

export 'constants.dart';

const _ignoredErrors = const [
  'unexpected-dash-after-double-dash-in-comment',
  'unexpected-char-in-comment',
];

/// Parses an HTML file [contents] and returns a DOM-like tree. Adds emitted
/// error/warning to [logger].
Document _parseHtml(String contents, String sourcePath, BuildLogger logger,
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
        logger.warning(HTML5_WARNING.create({'message': e.message}),
            span: e.span);
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

  /// Map of stylesheet paths that should or should not be inlined. The paths
  /// are relative to the package root and are represented using posix style,
  /// which matches the representation used in asset ids in barback.
  ///
  /// There is an additional special key 'default' for the global default.
  final Map<String, bool> inlineStylesheets;

  /// True to enable Content Security Policy.
  /// This means the HTML page will not have inlined .js code.
  final bool contentSecurityPolicy;

  /// True to include the compiled JavaScript directly from the HTML page.
  /// If enabled this will remove "packages/browser/dart.js" and replace
  /// `type="application/dart"` scripts with equivalent *.dart.js files.
  final bool directlyIncludeJS;

  /// Run transformers to create a releasable app. For example, include the
  /// minified versions of the polyfills rather than the debug versions.
  final bool releaseMode;

  /// This will make a physical element appear on the page showing build logs.
  /// It will only appear when ![releaseMode] even if this is true.
  final bool injectBuildLogsInOutput;

  /// Rules to determine whether to run liner on an html file.
  // TODO(jmesserly): instead of this flag, we should only run linter on
  // reachable (entry point+imported) html if deploying. See dartbug.com/17199.
  final LintOptions lint;

  /// This will automatically inject `platform.js` from the `web_components`
  /// package in all entry points, if it is not already included.
  final bool injectPlatformJs;

  TransformOptions({entryPoints, this.inlineStylesheets,
      this.contentSecurityPolicy: false, this.directlyIncludeJS: true,
      this.releaseMode: true, this.lint: const LintOptions(),
      this.injectBuildLogsInOutput: false, this.injectPlatformJs: true})
      : entryPoints = entryPoints == null ? null
          : entryPoints.map(systemToAssetPath).toList();

  /// Whether an asset with [id] is an entry point HTML file.
  bool isHtmlEntryPoint(AssetId id) {
    if (id.extension != '.html') return false;

    // Note: [id.path] is a relative path from the root of a package.
    if (entryPoints == null) {
      return id.path.startsWith('web/') || id.path.startsWith('test/');
    }

    return entryPoints.contains(id.path);
  }

  // Whether a stylesheet with [id] should be inlined, the default is true.
  bool shouldInlineStylesheet(AssetId id) {
    // Note: [id.path] is a relative path from the root of a package.
    // Default is to inline everything
    if (inlineStylesheets == null) return true;
    // First check for the full asset path overrides.
    var override = inlineStylesheets[id.toString()];
    if (override != null) return override;
    // Then check just the path overrides (if the package was not specified).
    override = inlineStylesheets[id.path];
    if (override != null) return override;
    // Then check the global default setting.
    var globalDefault = inlineStylesheets['default'];
    return (globalDefault != null) ? globalDefault : true;
  }

  // Whether a stylesheet with [id] has an overriden inlining setting.
  bool stylesheetInliningIsOverridden(AssetId id) {
    return inlineStylesheets != null &&
        (inlineStylesheets.containsKey(id.toString())
          || inlineStylesheets.containsKey(id.path));
  }
}

class LintOptions {
  /// Whether lint is enabled.
  final bool enabled;

  /// Patterns explicitly included/excluded from linting (if any).
  final List<RegExp> patterns;

  /// When [patterns] is not null, whether they denote inclusion or exclusion.
  final bool isInclude;

  const LintOptions()
      : enabled = true, patterns = null, isInclude = true;
  const LintOptions.disabled()
      : enabled = false, patterns = null, isInclude = true;

  LintOptions.include(List<String> patterns)
      : enabled = true,
        isInclude = true,
        patterns = patterns.map((s) => new RegExp(s)).toList();

  LintOptions.exclude(List<String> patterns)
      : enabled = true,
        isInclude = false,
        patterns = patterns.map((s) => new RegExp(s)).toList();

  bool shouldLint(String fileName) {
    if (!enabled) return false;
    if (patterns == null) return isInclude;
    for (var pattern in patterns) {
      if (pattern.hasMatch(fileName)) return isInclude;
    }
    return !isInclude;
  }
}

/// Mixin for polymer transformers.
abstract class PolymerTransformer {
  TransformOptions get options;

  Future<Document> readPrimaryAsHtml(Transform transform, BuildLogger logger) {
    var asset = transform.primaryInput;
    var id = asset.id;
    return asset.readAsString().then((content) {
      return _parseHtml(content, id.path, logger,
        checkDocType: options.isHtmlEntryPoint(id));
    });
  }

  Future<Document> readAsHtml(AssetId id, Transform transform,
      BuildLogger logger,
      {bool showWarnings: true}) {
    var primaryId = transform.primaryInput.id;
    bool samePackage = id.package == primaryId.package;
    var url = spanUrlFor(id, transform, logger);
    return transform.readInputAsString(id).then((content) {
      return _parseHtml(content, url, logger,
        checkDocType: samePackage && options.isHtmlEntryPoint(id),
        showWarnings: showWarnings);
    });
  }

  Future<bool> assetExists(AssetId id, Transform transform) =>
      transform.getInput(id).then((_) => true).catchError((_) => false);

  String toString() => 'polymer ($runtimeType)';
}

/// Gets the appropriate URL to use in a span to produce messages (e.g.
/// warnings) for users. This will attempt to format the URL in the most useful
/// way:
///
/// - If the asset is within the primary package, then use the [id.path],
///   the user will know it is a file from their own code.
/// - If the asset is from another package, then use [assetUrlFor], this will
///   likely be a "package:" url to the file in the other package, which is
///   enough for users to identify where the error is.
String spanUrlFor(AssetId id, Transform transform, logger) {
  var primaryId = transform.primaryInput.id;
  bool samePackage = id.package == primaryId.package;
  return samePackage ? id.path
      : assetUrlFor(id, primaryId, logger, allowAssetUrl: true);
}

/// Transformer phases which should be applied to the Polymer package.
List<List<Transformer>> get phasesForPolymer =>
    [[new ObservableTransformer(['lib/src/instance.dart'])]];

/// Generate the import url for a file described by [id], referenced by a file
/// with [sourceId].
// TODO(sigmund): this should also be in barback (dartbug.com/12610)
String assetUrlFor(AssetId id, AssetId sourceId, BuildLogger logger,
    {bool allowAssetUrl: false}) {
  // use package: and asset: urls if possible
  if (id.path.startsWith('lib/')) {
    return 'package:${id.package}/${id.path.substring(4)}';
  }

  if (id.path.startsWith('asset/')) {
    if (!allowAssetUrl) {
      logger.error(INTERNAL_ERROR_DONT_KNOW_HOW_TO_IMPORT.create({
            'target': id,
            'source': sourceId,
            'extra': ' (asset urls not allowed.)'}));
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
String systemToAssetPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.posix.joinAll(path.split(assetPath));
}

/// Returns true if this is a valid custom element name. See:
/// <http://w3c.github.io/webcomponents/spec/custom/#dfn-custom-element-type>
bool isCustomTagName(String name) {
  if (name == null || !name.contains('-')) return false;
  return !invalidTagNames.containsKey(name);
}

/// Regex to split names in the 'attributes' attribute, which supports 'a b c',
/// 'a,b,c', or even 'a b,c'. This is the same as in `lib/src/declaration.dart`.
final ATTRIBUTES_REGEX = new RegExp(r'\s|,');
