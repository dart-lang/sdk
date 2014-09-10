// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transfomer that inlines polymer-element definitions from html imports.
library polymer.src.build.import_inliner;

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/assets.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:path/path.dart' as path;
import 'package:html5lib/dom.dart' show
    Document, DocumentFragment, Element, Node;
import 'package:html5lib/dom_parsing.dart' show TreeVisitor;
import 'package:source_maps/refactor.dart' show TextEditTransaction;
import 'package:source_span/source_span.dart';

import 'common.dart';
import 'messages.dart';

// TODO(sigmund): move to web_components package (dartbug.com/18037).
class _HtmlInliner extends PolymerTransformer {
  final TransformOptions options;
  final Transform transform;
  final BuildLogger logger;
  final AssetId docId;
  final seen = new Set<AssetId>();
  final scriptIds = <AssetId>[];
  final extractedFiles = new Set<AssetId>();
  bool experimentalBootstrap = false;

  /// The number of extracted inline Dart scripts. Used as a counter to give
  /// unique-ish filenames.
  int inlineScriptCounter = 0;

  _HtmlInliner(TransformOptions options, Transform transform)
      : options = options,
        transform = transform,
        logger = new BuildLogger(transform,
            convertErrorsToWarnings: !options.releaseMode,
            detailsUri: 'http://goo.gl/5HPeuP'),
        docId = transform.primaryInput.id;

  Future apply() {
    seen.add(docId);

    Document document;
    bool changed = false;

    return readPrimaryAsHtml(transform, logger).then((doc) {
      document = doc;
      changed = new _UrlNormalizer(transform, docId, logger).visit(document)
        || changed;
      
      experimentalBootstrap = document.querySelectorAll('link').any((link) =>
          link.attributes['rel'] == 'import' &&
          link.attributes['href'] == POLYMER_EXPERIMENTAL_HTML);
      changed = _extractScripts(document) || changed;
      return _visitImports(document);
    }).then((importsFound) {
      changed = changed || importsFound;
      return _removeScripts(document);
    }).then((scriptsRemoved) {
      changed = changed || scriptsRemoved;

      var output = transform.primaryInput;
      if (changed) output = new Asset.fromString(docId, document.outerHtml);
      transform.addOutput(output);

      // We produce a secondary asset with extra information for later phases.
      transform.addOutput(new Asset.fromString(
          docId.addExtension('._data'),
          JSON.encode({
            'experimental_bootstrap': experimentalBootstrap,
            'script_ids': scriptIds,
          }, toEncodable: (id) => id.serialize())));

      // Write out the logs collected by our [BuildLogger].
      if (options.injectBuildLogsInOutput) {
        return logger.writeOutput();
      }
    });
  }

  /// Visits imports in [document] and add the imported documents to documents.
  /// Documents are added in the order they appear, transitive imports are added
  /// first.
  ///
  /// Returns `true` if and only if the document was changed and should be
  /// written out.
  Future<bool> _visitImports(Document document) {
    bool changed = false;

    _moveHeadToBody(document);

    // Note: we need to preserve the import order in the generated output.
    return Future.forEach(document.querySelectorAll('link'), (Element tag) {
      var rel = tag.attributes['rel'];
      if (rel != 'import' && rel != 'stylesheet') return null;

      // Note: URL has already been normalized so use docId.
      var href = tag.attributes['href'];
      var id = uriToAssetId(docId, href, logger, tag.sourceSpan,
          errorOnAbsolute: rel != 'stylesheet');

      if (rel == 'import') {
        changed = true;
        if (id == null || !seen.add(id)) {
          tag.remove();
          return null;
        }
        return _inlineImport(id, tag);

      } else if (rel == 'stylesheet') {
        if (id == null) return null;
        if (!options.shouldInlineStylesheet(id)) return null;

        changed = true;
        return _inlineStylesheet(id, tag);
      }
    }).then((_) => changed);
  }

  /// To preserve the order of scripts with respect to inlined
  /// link rel=import, we move both of those into the body before we do any
  /// inlining.
  ///
  /// Note: we do this for stylesheets as well to preserve ordering with
  /// respect to eachother, because stylesheets can be pulled in transitively
  /// from imports.
  // TODO(jmesserly): vulcanizer doesn't need this because they inline JS
  // scripts, causing them to be naturally moved as part of the inlining.
  // Should we do the same? Alternatively could we inline head into head and
  // body into body and avoid this whole thing?
  void _moveHeadToBody(Document doc) {
    var insertionPoint = doc.body.firstChild;
    for (var node in doc.head.nodes.toList(growable: false)) {
      if (node is! Element) continue;
      var tag = node.localName;
      var type = node.attributes['type'];
      var rel = node.attributes['rel'];
      if (tag == 'style' || tag == 'script' &&
            (type == null || type == TYPE_JS || type == TYPE_DART) ||
          tag == 'link' && (rel == 'stylesheet' || rel == 'import')) {
        // Move the node into the body, where its contents will be placed.
        doc.body.insertBefore(node, insertionPoint);
      }
    }
  }

  /// Loads an asset identified by [id], visits its imports and collects its
  /// html imports. Then inlines it into the main document.
  Future _inlineImport(AssetId id, Element link) {
    return readAsHtml(id, transform, logger).catchError((error) {
      logger.error(INLINE_IMPORT_FAIL.create({'error': error}),
          span: link.sourceSpan);
    }).then((doc) {
      if (doc == null) return false;
      new _UrlNormalizer(transform, id, logger).visit(doc);
      return _visitImports(doc).then((_) {
        // _UrlNormalizer already ensures there is a library name.
        _extractScripts(doc, injectLibraryName: false);

        // TODO(jmesserly): figure out how this is working in vulcanizer.
        // Do they produce a <body> tag with a <head> and <body> inside?
        var imported = new DocumentFragment();
        imported.nodes..addAll(doc.head.nodes)..addAll(doc.body.nodes);
        link.replaceWith(imported);

        // Make sure to grab any logs from the inlined import.
        return logger.addLogFilesFromAsset(id);
      });
    });
  }

  Future _inlineStylesheet(AssetId id, Element link) {
    return transform.readInputAsString(id).catchError((error) {
      // TODO(jakemac): Move this warning to the linter once we can make it run
      // always (see http://dartbug.com/17199). Then hide this error and replace
      // with a comment pointing to the linter error (so we don't double warn).
      logger.warning(INLINE_STYLE_FAIL.create({'error': error}),
          span: link.sourceSpan);
    }).then((css) {
      if (css == null) return null;
      css = new _UrlNormalizer(transform, id, logger).visitCss(css);
      var styleElement = new Element.tag('style')..text = css;
      // Copy over the extra attributes from the link tag to the style tag.
      // This adds support for no-shim, shim-shadowdom, etc.
      link.attributes.forEach((key, value) {
        if (!IGNORED_LINKED_STYLE_ATTRS.contains(key)) {
          styleElement.attributes[key] = value;
        }
      });
      link.replaceWith(styleElement);
    });
  }

  /// Remove all Dart scripts and remember their [AssetId]s for later use.
  ///
  /// Dartium only allows a single script tag per page, so we can't inline
  /// the script tags. Instead we remove them entirely.
  Future<bool> _removeScripts(Document doc) {
    bool changed = false;
    return Future.forEach(doc.querySelectorAll('script'), (script) {
      if (script.attributes['type'] == TYPE_DART) {
        changed = true;
        script.remove();
        var src = script.attributes['src'];
        var srcId = uriToAssetId(docId, src, logger, script.sourceSpan);

        // We check for extractedFiles because 'hasInput' below is only true for
        // assets that existed before this transformer runs (hasInput is false
        // for files created by [_extractScripts]).
        if (extractedFiles.contains(srcId)) {
          scriptIds.add(srcId);
          return true;
        }

        return transform.hasInput(srcId).then((exists) {
          if (!exists) {
            logger.warning(SCRIPT_FILE_NOT_FOUND.create({'url': src}),
              span: script.sourceSpan);
          } else {
            scriptIds.add(srcId);
          }
        });
      }
    }).then((_) => changed);
  }

  /// Split inline scripts into their own files. We need to do this for dart2js
  /// to be able to compile them.
  ///
  /// This also validates that there weren't any duplicate scripts.
  bool _extractScripts(Document doc, {bool injectLibraryName: true}) {
    bool changed = false;
    for (var script in doc.querySelectorAll('script')) {
      var src = script.attributes['src'];
      if (src != null) continue;

      var type = script.attributes['type'];
      var isDart = type == TYPE_DART;

      var shouldExtract = isDart ||
          (options.contentSecurityPolicy && (type == null || type == TYPE_JS));
      if (!shouldExtract) continue;

      var extension =  isDart ? 'dart' : 'js';
      final filename = path.url.basename(docId.path);
      final count = inlineScriptCounter++;
      var code = script.text;
      // TODO(sigmund): ensure this path is unique (dartbug.com/12618).
      script.attributes['src'] = src = '$filename.$count.$extension';
      script.text = '';
      changed = true;

      var newId = docId.addExtension('.$count.$extension');
      if (isDart && injectLibraryName && !_hasLibraryDirective(code)) {
        var libName = _libraryNameFor(docId, count);
        code = "library $libName;\n$code";
      }
      extractedFiles.add(newId);
      transform.addOutput(new Asset.fromString(newId, code));
    }
    return changed;
  }
}

/// Transform AssetId into a library name. For example:
///
///     myPkgName|lib/foo/bar.html -> myPkgName.foo.bar_html
///     myPkgName|web/foo/bar.html -> myPkgName.web.foo.bar_html
///
/// This should roughly match the recommended library name conventions.
String _libraryNameFor(AssetId id, int suffix) {
  var name = '${path.withoutExtension(id.path)}_'
      '${path.extension(id.path).substring(1)}';
  if (name.startsWith('lib/')) name = name.substring(4);
  name = name.split('/').map((part) {
    part = part.replaceAll(_INVALID_LIB_CHARS_REGEX, '_');
    if (part.startsWith(_NUM_REGEX)) part = '_${part}';
    return part;
  }).join(".");
  return '${id.package}.${name}_$suffix';
}

/// Parse [code] and determine whether it has a library directive.
bool _hasLibraryDirective(String code) =>
    parseDirectives(code, suppressErrors: true)
        .directives.any((d) => d is LibraryDirective);


/// Recursively inlines the contents of HTML imports. Produces as output a
/// single HTML file that inlines the polymer-element definitions, and a text
/// file that contains, in order, the URIs to each library that sourced in a
/// script tag.
///
/// This transformer assumes that all script tags point to external files. To
/// support script tags with inlined code, use this transformer after running
/// [InlineCodeExtractor] on an earlier phase.
class ImportInliner extends Transformer {
  final TransformOptions options;

  ImportInliner(this.options);

  /// Only run on entry point .html files.
  // TODO(nweiz): This should just take an AssetId when barback <0.13.0 support
  // is dropped.
  Future<bool> isPrimary(idOrAsset) {
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return new Future.value(options.isHtmlEntryPoint(id));
  }

  Future apply(Transform transform) =>
      new _HtmlInliner(options, transform).apply();
}

const TYPE_DART = 'application/dart';
const TYPE_JS = 'text/javascript';

/// Internally adjusts urls in the html that we are about to inline.
class _UrlNormalizer extends TreeVisitor {
  final Transform transform;

  /// Asset where the original content (and original url) was found.
  final AssetId sourceId;

  /// Counter used to ensure that every library name we inject is unique.
  int _count = 0;

  /// Path to the top level folder relative to the transform primaryInput.
  /// This should just be some arbitrary # of ../'s.
  final String topLevelPath;

  /// Whether or not the normalizer has changed something in the tree.
  bool changed = false;

  final BuildLogger logger;

  _UrlNormalizer(transform, this.sourceId, this.logger)
      : transform = transform,
        topLevelPath =
          '../' * (transform.primaryInput.id.path.split('/').length - 2);

  visit(Node node) {
    super.visit(node);
    return changed;
  }

  visitElement(Element node) {
    // TODO(jakemac): Support custom elements that extend html elements which
    // have url-like attributes. This probably means keeping a list of which
    // html elements support each url-like attribute.
    if (!isCustomTagName(node.localName)) {
      node.attributes.forEach((name, value) {
        if (_urlAttributes.contains(name)) {
          if (!name.startsWith('_') && value.contains(_BINDING_REGEX)) {
            logger.warning(USE_UNDERSCORE_PREFIX.create({'name': name}),
                span: node.sourceSpan, asset: sourceId);
          } else if (name.startsWith('_') && !value.contains(_BINDING_REGEX)) {
            logger.warning(DONT_USE_UNDERSCORE_PREFIX.create(
                  {'name': name.substring(1)}),
                span: node.sourceSpan, asset: sourceId);
          }
          if (value != '' && !value.trim().startsWith(_BINDING_REGEX)) {
            node.attributes[name] = _newUrl(value, node.sourceSpan);
            changed = changed || value != node.attributes[name];
          }
        }
      });
    }
    if (node.localName == 'style') {
      node.text = visitCss(node.text);
      changed = true;
    } else if (node.localName == 'script' &&
        node.attributes['type'] == TYPE_DART &&
        !node.attributes.containsKey('src')) {
      // TODO(jmesserly): we might need to visit JS too to handle ES Harmony
      // modules.
      node.text = visitInlineDart(node.text);
      changed = true;
    }
    return super.visitElement(node);
  }

  static final _URL = new RegExp(r'url\(([^)]*)\)', multiLine: true);
  static final _QUOTE = new RegExp('["\']', multiLine: true);

  /// Visit the CSS text and replace any relative URLs so we can inline it.
  // Ported from:
  // https://github.com/Polymer/vulcanize/blob/c14f63696797cda18dc3d372b78aa3378acc691f/lib/vulcan.js#L149
  // TODO(jmesserly): use csslib here instead? Parsing with RegEx is sadness.
  // Maybe it's reliable enough for finding URLs in CSS? I'm not sure.
  String visitCss(String cssText) {
    var url = spanUrlFor(sourceId, transform, logger);
    var src = new SourceFile(cssText, url: url);
    return cssText.replaceAllMapped(_URL, (match) {
      // Extract the URL, without any surrounding quotes.
      var span = src.span(match.start, match.end);
      var href = match[1].replaceAll(_QUOTE, '');
      href = _newUrl(href, span);
      return 'url($href)';
    });
  }

  String visitInlineDart(String code) {
    var unit = parseDirectives(code, suppressErrors: true);
    var file = new SourceFile(code,
        url: spanUrlFor(sourceId, transform, logger));
    var output = new TextEditTransaction(code, file);
    var foundLibraryDirective = false;
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        var uri = directive.uri.stringValue;
        var span = _getSpan(file, directive.uri);

        var id = uriToAssetId(sourceId, uri, logger, span,
            errorOnAbsolute: false);
        if (id == null) continue;

        var primaryId = transform.primaryInput.id;
        var newUri = assetUrlFor(id, primaryId, logger);
        if (newUri != uri) {
          output.edit(span.start.offset, span.end.offset, "'$newUri'");
        }
      } else if (directive is LibraryDirective) {
        foundLibraryDirective = true;
      }
    }

    if (!foundLibraryDirective) {
      // Ensure all inline scripts also have a library name.
      var libName = _libraryNameFor(sourceId, _count++);
      output.edit(0, 0, "library $libName;\n");
    }

    if (!output.hasEdits) return code;

    // TODO(sigmund): emit source maps when barback supports it (see
    // dartbug.com/12340)
    return (output.commit()..build(file.url.toString())).text;
  }

  String _newUrl(String href, SourceSpan span) {
    // Placeholder for everything past the start of the first binding.
    const placeholder = '_';
    // We only want to parse the part of the href leading up to the first
    // binding, anything after that is not informative.
    var hrefToParse;
    var firstBinding = href.indexOf(_BINDING_REGEX);
    if (firstBinding == -1) {
      hrefToParse = href;
    } else if (firstBinding == 0) {
      return href;
    } else {
      hrefToParse = '${href.substring(0, firstBinding)}$placeholder';
    }

    var uri = Uri.parse(hrefToParse);
    if (uri.isAbsolute) return href;
    if (!uri.scheme.isEmpty) return href;
    if (!uri.host.isEmpty) return href;
    if (uri.path.isEmpty) return href;  // Implies standalone ? or # in URI.
    if (path.isAbsolute(href)) return href;

    var id = uriToAssetId(sourceId, hrefToParse, logger, span);
    if (id == null) return href;
    var primaryId = transform.primaryInput.id;

    // Build the new path, placing back any suffixes that we stripped earlier.
    var prefix = (firstBinding == -1) ? id.path
        : id.path.substring(0, id.path.length - placeholder.length);
    var suffix = (firstBinding == -1) ? '' : href.substring(firstBinding);
    var newPath = '$prefix$suffix';

    if (newPath.startsWith('lib/')) {
      return '${topLevelPath}packages/${id.package}/${newPath.substring(4)}';
    }

    if (newPath.startsWith('asset/')) {
      return '${topLevelPath}assets/${id.package}/${newPath.substring(6)}';
    }

    if (primaryId.package != id.package) {
      // Techincally we shouldn't get there
      logger.error(INTERNAL_ERROR_DONT_KNOW_HOW_TO_IMPORT.create({
          'target': id, 'source': primaryId, 'extra': ''}), span: span);
      return href;
    }

    var builder = path.url;
    return builder.relative(builder.join('/', newPath),
        from: builder.join('/', builder.dirname(primaryId.path)));
  }
}

/// HTML attributes that expect a URL value.
/// <http://dev.w3.org/html5/spec/section-index.html#attributes-1>
///
/// Every one of these attributes is a URL in every context where it is used in
/// the DOM. The comments show every DOM element where an attribute can be used.
///
/// The _* version of each attribute is also supported, see http://goo.gl/5av8cU
const _urlAttributes = const [
  'action', '_action',          // in form
  'background', '_background',  // in body
  'cite', '_cite',              // in blockquote, del, ins, q
  'data', '_data',              // in object
  'formaction', '_formaction',  // in button, input
  'href', '_href',              // in a, area, link, base, command
  'icon', '_icon',              // in command
  'manifest', '_manifest',      // in html
  'poster', '_poster',          // in video
  'src', '_src',                // in audio, embed, iframe, img, input, script,
                                //    source, track,video
];

/// When inlining <link rel="stylesheet"> tags copy over all attributes to the
/// style tag except these ones.
const IGNORED_LINKED_STYLE_ATTRS =
    const ['charset', 'href', 'href-lang', 'rel', 'rev'];

/// Global RegExp objects.
final _INVALID_LIB_CHARS_REGEX = new RegExp('[^a-z0-9_]');
final _NUM_REGEX = new RegExp('[0-9]');
final _BINDING_REGEX = new RegExp(r'(({{.*}})|(\[\[.*\]\]))');

_getSpan(SourceFile file, AstNode node) => file.span(node.offset, node.end);
