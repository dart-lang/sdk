// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Logic to validate that developers are correctly using Polymer constructs.
/// This is mainly used to produce warnings for feedback in the editor.
library polymer.src.build.linter;

import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:code_transformers/assets.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:code_transformers/messages/messages.dart' show Message;
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';
import 'package:source_span/source_span.dart';

import 'common.dart';
import 'utils.dart';
import 'messages.dart';

/// A linter that checks for common Polymer errors and produces warnings to
/// show on the editor or the command line. Leaves sources unchanged, but
/// creates a new asset containing all the warnings.
class Linter extends Transformer with PolymerTransformer {
  final TransformOptions options;

  /// Only run on .html files.
  final String allowedExtensions = '.html';

  Linter(this.options);

  Future apply(Transform transform) {
    var seen = new Set<AssetId>();
    var primary = transform.primaryInput;
    var id = primary.id;
    transform.addOutput(primary); // this phase is analysis only
    seen.add(id);
    bool isEntryPoint = options.isHtmlEntryPoint(id);

    var logger = new BuildLogger(transform,
        convertErrorsToWarnings: !options.releaseMode,
        detailsUri: 'http://goo.gl/5HPeuP');

    return readPrimaryAsHtml(transform, logger).then((document) {
      return _collectElements(document, id, transform, logger, seen)
          .then((elements) {
        new _LinterVisitor(id, logger, elements, isEntryPoint).run(document);

        // Write out the logs collected by our [BuildLogger].
        if (options.injectBuildLogsInOutput && logger is BuildLogger) {
          return (logger as BuildLogger).writeOutput();
        }
      });
    });
  }

  /// Collect into [elements] any data about each polymer-element defined in
  /// [document] or any of it's imports, unless they have already been [seen].
  /// Elements are added in the order they appear, transitive imports are added
  /// first.
  Future<Map<String, _ElementSummary>> _collectElements(
      Document document, AssetId sourceId, Transform transform,
      BuildLogger logger, Set<AssetId> seen,
      [Map<String, _ElementSummary> elements]) {
    if (elements == null) elements = <String, _ElementSummary>{};
    return _getImportedIds(document, sourceId, transform, logger)
        // Note: the import order is relevant, so we visit in that order.
        .then((ids) => Future.forEach(ids,
              (id) => _readAndCollectElements(
                  id, transform, logger, seen, elements)))
        .then((_) {
          if (sourceId.package == 'polymer' &&
              sourceId.path == 'lib/src/js/polymer/polymer.html' &&
              elements['polymer-element'] == null) {
            elements['polymer-element'] =
                new _ElementSummary('polymer-element', null, null);
          }
          return _addElements(document, logger, elements);
        })
        .then((_) => elements);
  }

  Future _readAndCollectElements(AssetId id, Transform transform,
      BuildLogger logger, Set<AssetId> seen,
      Map<String, _ElementSummary> elements) {
    if (id == null || seen.contains(id)) return new Future.value(null);
    seen.add(id);
    return readAsHtml(id, transform, logger, showWarnings: false).then(
        (doc) => _collectElements(doc, id, transform, logger, seen, elements));
  }

  Future<List<AssetId>> _getImportedIds(
      Document document, AssetId sourceId, Transform transform,
      BuildLogger logger) {
    var importIds = [];
    for (var tag in document.querySelectorAll('link')) {
      if (tag.attributes['rel'] != 'import') continue;
      var href = tag.attributes['href'];
      var span = tag.sourceSpan;
      var id = uriToAssetId(sourceId, href, logger, span);
      if (id == null) continue;
      importIds.add(assetExists(id, transform).then((exists) {
        if (exists) return id;
        if (sourceId == transform.primaryInput.id) {
          logger.warning(IMPORT_NOT_FOUND.create(
                {'path': id.path, 'package': id.package}), span: span);
        }
      }));
    }
    return Future.wait(importIds);
  }

  void _addElements(Document document, BuildLogger logger,
      Map<String, _ElementSummary> elements) {
    for (var tag in document.querySelectorAll('polymer-element')) {
      var name = tag.attributes['name'];
      if (name == null) continue;
      var extendsTag = tag.attributes['extends'];
      var span = tag.sourceSpan;
      var existing = elements[name];
      if (existing != null) {

        // Report warning only once.
        if (existing.hasConflict) continue;
        existing.hasConflict = true;
        logger.warning(DUPLICATE_DEFINITION.create(
              {'name': name, 'second': ''}),
            span: existing.span);
        logger.warning(DUPLICATE_DEFINITION.create(
              {'name': name, 'second': ' (second definition).'}),
            span: span);
        continue;
      }

      elements[name] = new _ElementSummary(name, extendsTag, tag.sourceSpan);
    }
  }
}


/// Information needed about other polymer-element tags in order to validate
/// how they are used and extended.
///
/// Note: these are only created for polymer-element, because pure custom
/// elements don't have a declarative form.
class _ElementSummary {
  final String tagName;
  final String extendsTag;
  final SourceSpan span;

  _ElementSummary extendsType;
  bool hasConflict = false;

  String get baseExtendsTag {
    if (extendsType != null) return extendsType.baseExtendsTag;
    if (extendsTag != null && !extendsTag.contains('-')) return extendsTag;
    return null;
  }

  _ElementSummary(this.tagName, this.extendsTag, this.span);

  String toString() => "($tagName <: $extendsTag)";
}

class _LinterVisitor extends TreeVisitor {
  BuildLogger _logger;
  AssetId _sourceId;
  bool _inPolymerElement = false;
  bool _dartTagSeen = false;
  bool _polymerHtmlSeen = false;
  bool _polymerExperimentalHtmlSeen = false;
  bool _isEntryPoint;
  Map<String, _ElementSummary> _elements;

  _LinterVisitor(
      this._sourceId, this._logger, this._elements, this._isEntryPoint) {
    // We normalize the map, so each element has a direct reference to any
    // element it extends from.
    for (var tag in _elements.values) {
      var extendsTag = tag.extendsTag;
      if (extendsTag == null) continue;
      tag.extendsType = _elements[extendsTag];
    }
  }

  void visitElement(Element node) {
    switch (node.localName) {
      case 'link': _validateLinkElement(node); break;
      case 'element': _validateElementElement(node); break;
      case 'polymer-element': _validatePolymerElement(node); break;
      case 'script': _validateScriptElement(node); break;
      default:
         _validateNormalElement(node);
         super.visitElement(node);
         break;
    }
  }

  void run(Document doc) {
    visit(doc);

    if (_isEntryPoint && !_dartTagSeen && !_polymerExperimentalHtmlSeen) {
      _logger.warning(MISSING_INIT_POLYMER, span: doc.body.sourceSpan);
    }
  }

  /// Produce warnings for invalid link-rel tags.
  void _validateLinkElement(Element node) {
    var rel = node.attributes['rel'];
    if (rel != 'import' && rel != 'stylesheet') return;

    if (rel == 'import' && _dartTagSeen) {
      _logger.warning(MOVE_IMPORTS_UP, span: node.sourceSpan);
    }

    var href = node.attributes['href'];
    if (href == null || href == '') {
      _logger.warning(MISSING_HREF.create({'rel': rel}), span: node.sourceSpan);
      return;
    }

    if (rel != 'import') return;

    if (_inPolymerElement) {
      _logger.error(NO_IMPORT_WITHIN_ELEMENT, span: node.sourceSpan);
      return;
    }

    if (href == POLYMER_EXPERIMENTAL_HTML) {
      _polymerExperimentalHtmlSeen = true;
    }
    // TODO(sigmund): warn also if href can't be resolved.
  }

  /// Produce warnings if using `<element>` instead of `<polymer-element>`.
  void _validateElementElement(Element node) {
    _logger.warning(ELEMENT_DEPRECATED_EONS_AGO, span: node.sourceSpan);
  }

  /// Produce warnings if using `<polymer-element>` in the wrong place or if the
  /// definition is not complete.
  void _validatePolymerElement(Element node) {
    if (!_elements.containsKey('polymer-element')) {
      _logger.warning(usePolymerHtmlMessageFrom(_sourceId),
          span: node.sourceSpan);
    }

    if (_inPolymerElement) {
      _logger.error(NESTED_POLYMER_ELEMENT, span: node.sourceSpan);
      return;
    }

    var tagName = node.attributes['name'];
    var extendsTag = node.attributes['extends'];

    if (tagName == null) {
      _logger.error(MISSING_TAG_NAME, span: node.sourceSpan);
    } else if (!isCustomTagName(tagName)) {
      _logger.error(INVALID_TAG_NAME.create({'name': tagName}),
          span: node.sourceSpan);
    }

    if (_elements[extendsTag] == null && isCustomTagName(extendsTag)) {
      _logger.warning(CUSTOM_ELEMENT_NOT_FOUND.create({'tag': extendsTag}),
          span: node.sourceSpan);
    }

    var attrs = node.attributes['attributes'];
    if (attrs != null) {
      var attrsSpan = node.attributeSpans['attributes'];

      // names='a b c' or names='a,b,c'
      // record each name for publishing
      for (var attr in attrs.split(ATTRIBUTES_REGEX)) {
        if (!_validateCustomAttributeName(attr.trim(), attrsSpan)) break;
      }
    }

    var oldValue = _inPolymerElement;
    _inPolymerElement = true;
    super.visitElement(node);
    _inPolymerElement = oldValue;
  }

  /// Checks for multiple Dart script tags in the same page, which is invalid.
  void _validateScriptElement(Element node) {
    var scriptType = node.attributes['type'];
    var isDart = scriptType == 'application/dart';
    var src = node.attributes['src'];

    if (isDart) {
      if (_dartTagSeen) _logger.warning(ONLY_ONE_TAG, span: node.sourceSpan);
      if (_isEntryPoint && _polymerExperimentalHtmlSeen) {
        _logger.warning(NO_DART_SCRIPT_AND_EXPERIMENTAL, span: node.sourceSpan);
      }
      _dartTagSeen = true;
    }

    var isEmpty = node.innerHtml.trim() == '';

    if (src == null) {
      if (isDart && isEmpty) {
        _logger.warning(SCRIPT_TAG_SEEMS_EMPTY, span: node.sourceSpan);
      }
      return;
    }

    if (src.endsWith('.dart') && !isDart) {
      _logger.warning(EXPECTED_DART_MIME_TYPE, span: node.sourceSpan);
      return;
    }

    if (!src.endsWith('.dart') && isDart) {
      _logger.warning(EXPECTED_DART_EXTENSION, span: node.sourceSpan);
      return;
    }

    if (!isEmpty) {
      _logger.warning(FOUND_BOTH_SCRIPT_SRC_AND_TEXT, span: node.sourceSpan);
    }
  }

  /// Produces warnings for misuses of on-foo event handlers, and for instanting
  /// custom tags incorrectly.
  void _validateNormalElement(Element node) {
    // Event handlers only allowed inside polymer-elements
    node.attributes.forEach((name, value) {
      if (name is String && name.startsWith('on')) {
        _validateEventHandler(node, name, value);
      }
    });

    // Validate uses of custom-tags
    var nodeTag = node.localName;
    var hasIsAttribute;
    var customTagName;
    if (isCustomTagName(nodeTag)) {
      // <fancy-button>
      customTagName = nodeTag;
      hasIsAttribute = false;
    } else {
      // <button is="fancy-button">
      customTagName = node.attributes['is'];
      hasIsAttribute = true;
    }

    if (customTagName == null || 
        INTERNALLY_DEFINED_ELEMENTS.contains(customTagName)) {
      return;
    }
    
    var info = _elements[customTagName];
    if (info == null) {
      _logger.warning(CUSTOM_ELEMENT_NOT_FOUND.create({'tag': customTagName}),
          span: node.sourceSpan);
      return;
    }

    var baseTag = info.baseExtendsTag;
    if (baseTag != null && !hasIsAttribute) {
      _logger.warning(BAD_INSTANTIATION_MISSING_BASE_TAG.create(
            {'tag': customTagName, 'base': baseTag}), span: node.sourceSpan);
      return;
    }

    if (hasIsAttribute && baseTag == null) {
      _logger.warning(BAD_INSTANTIATION_BOGUS_BASE_TAG.create(
            {'tag': customTagName, 'base': nodeTag}), span: node.sourceSpan);
      return;
    }

    if (hasIsAttribute && baseTag != nodeTag) {
      _logger.warning(BAD_INSTANTIATION_WRONG_BASE_TAG.create(
            {'tag': customTagName, 'base': baseTag}), span: node.sourceSpan);
    }

    // FOUC check, if content is supplied
    if (!node.innerHtml.isEmpty) {
      var parent = node;
      var hasFoucFix = false;
      while (parent != null && !hasFoucFix) {
        if (parent.localName == 'polymer-element' ||
            parent.attributes['unresolved'] != null) {
          hasFoucFix = true;
        }
        if (parent.localName == 'body') break;
        parent = parent.parent;
      }
      if (!hasFoucFix) _logger.warning(POSSIBLE_FUOC, span: node.sourceSpan);
    }
  }

  /// Validate an attribute on a custom-element. Returns true if valid.
  bool _validateCustomAttributeName(String name, FileSpan span) {
    if (name.contains('-')) {
      var newName = toCamelCase(name);
      var alternative = '"$newName" or "${newName.toLowerCase()}"';
      _logger.warning(NO_DASHES_IN_CUSTOM_ATTRIBUTES.create(
            {'name': name, 'alternative': alternative}), span: span);
      return false;
    }
    return true;
  }

  /// Validate event handlers are used correctly.
  void _validateEventHandler(Element node, String name, String value) {
    if (!name.startsWith('on-')) return;

    if (!_inPolymerElement) {
      _logger.warning(EVENT_HANDLERS_ONLY_WITHIN_POLYMER,
          span: node.attributeSpans[name]);
      return;
    }


    // Valid bindings have {{ }}, don't look like method calls foo(bar), and are
    // non empty.
    if (!value.startsWith("{{") || !value.endsWith("}}") || value.contains('(')
        || value.substring(2, value.length - 2).trim() == '') {
      _logger.warning(INVALID_EVENT_HANDLER_BODY.create(
            {'value': value, 'name': name}),
          span: node.attributeSpans[name]);
    }
  }
}

Message usePolymerHtmlMessageFrom(AssetId id) {
  var segments = id.path.split('/');
  var upDirCount = 0;
  if (segments[0] == 'lib') {
    // lib/foo.html => ../../packages/
    upDirCount = segments.length;
  } else if (segments.length > 2) {
    // web/a/foo.html => ../packages/
    upDirCount = segments.length - 2;
  }
  var reachOutPrefix = '../' * upDirCount;
  return USE_POLYMER_HTML.create({'reachOutPrefix': reachOutPrefix});
}

const List<String> INTERNALLY_DEFINED_ELEMENTS = 
    const ['auto-binding-dart', 'polymer-element'];
