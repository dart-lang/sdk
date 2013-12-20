// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Logic to validate that developers are correctly using Polymer constructs.
 * This is mainly used to produce warnings for feedback in the editor.
 */
library polymer.src.build.linter;

import 'dart:io';
import 'dart:async';
import 'dart:mirrors';
import 'dart:convert' show JSON;

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';
import 'package:source_maps/span.dart';

import 'common.dart';
import 'utils.dart';

/**
 * A linter that checks for common Polymer errors and produces warnings to
 * show on the editor or the command line. Leaves sources unchanged, but creates
 * a new asset containing all the warnings.
 */
class Linter extends Transformer with PolymerTransformer {
  final TransformOptions options;

  /** Only run on .html files. */
  final String allowedExtensions = '.html';

  Linter(this.options);

  Future apply(Transform transform) {
    var seen = new Set<AssetId>();
    var primary = transform.primaryInput;
    var id = primary.id;
    transform.addOutput(primary); // this phase is analysis only
    seen.add(id);
    return readPrimaryAsHtml(transform).then((document) {
      return _collectElements(document, id, transform, seen).then((elements) {
        bool isEntrypoint = options.isHtmlEntryPoint(id);
        new _LinterVisitor(transform.logger, elements, isEntrypoint)
            .run(document);
      });
    });
  }

  /**
   * Collect into [elements] any data about each polymer-element defined in
   * [document] or any of it's imports, unless they have already been [seen].
   * Elements are added in the order they appear, transitive imports are added
   * first.
   */
  Future<Map<String, _ElementSummary>> _collectElements(
      Document document, AssetId sourceId, Transform transform,
      Set<AssetId> seen, [Map<String, _ElementSummary> elements]) {
    if (elements == null) elements = <String, _ElementSummary>{};
    return _getImportedIds(document, sourceId, transform)
        // Note: the import order is relevant, so we visit in that order.
        .then((ids) => Future.forEach(ids,
              (id) => _readAndCollectElements(id, transform, seen, elements)))
        .then((_) => _addElements(document, transform.logger, elements))
        .then((_) => elements);
  }

  Future _readAndCollectElements(AssetId id, Transform transform,
      Set<AssetId> seen, Map<String, _ElementSummary> elements) {
    if (id == null || seen.contains(id)) return new Future.value(null);
    seen.add(id);
    return readAsHtml(id, transform).then(
        (doc) => _collectElements(doc, id, transform, seen, elements));
  }

  Future<List<AssetId>> _getImportedIds(
      Document document, AssetId sourceId, Transform transform) {
    var importIds = [];
    var logger = transform.logger;
    for (var tag in document.queryAll('link')) {
      if (tag.attributes['rel'] != 'import') continue;
      var href = tag.attributes['href'];
      var span = tag.sourceSpan;
      var id = resolve(sourceId, href, logger, span);
      if (id == null ||
          (id.package == 'polymer' && id.path == 'lib/init.html')) continue;
      importIds.add(assetExists(id, transform).then((exists) {
        if (exists) return id;
        if (sourceId == transform.primaryInput.id) {
          logger.error('couldn\'t find imported asset "${id.path}" in package '
              '"${id.package}".', span: span);
        }
      }));
    }
    return Future.wait(importIds);
  }

  void _addElements(Document document, TransformLogger logger,
      Map<String, _ElementSummary> elements) {
    for (var tag in document.queryAll('polymer-element')) {
      var name = tag.attributes['name'];
      if (name == null) continue;
      var extendsTag = tag.attributes['extends'];
      var span = tag.sourceSpan;
      var existing = elements[name];
      if (existing != null) {

        // Report warning only once.
        if (existing.hasConflict) continue;
        existing.hasConflict = true;
        logger.warning('duplicate definition for custom tag "$name".',
          span: existing.span);
        logger.warning('duplicate definition for custom tag "$name" '
          ' (second definition).', span: span);
        continue;
      }

      elements[name] = new _ElementSummary(name, extendsTag, tag.sourceSpan);
    }
  }
}


/**
 * Information needed about other polymer-element tags in order to validate
 * how they are used and extended.
 *
 * Note: these are only created for polymer-element, because pure custom
 * elements don't have a declarative form.
 */
class _ElementSummary {
  final String tagName;
  final String extendsTag;
  final Span span;

  _ElementSummary extendsType;
  bool hasConflict = false;

  String get baseExtendsTag => extendsType == null
      ? extendsTag : extendsType.baseExtendsTag;

  _ElementSummary(this.tagName, this.extendsTag, this.span);

  String toString() => "($tagName <: $extendsTag)";
}

class _LinterVisitor extends TreeVisitor {
  TransformLogger _logger;
  bool _inPolymerElement = false;
  bool _dartTagSeen = false;
  bool _isEntrypoint;
  Map<String, _ElementSummary> _elements;

  _LinterVisitor(this._logger, this._elements, this._isEntrypoint) {
    // We normalize the map, so each element has a direct reference to any
    // element it extends from.
    for (var tag in _elements.values) {
      var extendsTag = tag.extendsTag;
      if (extendsTag == null) continue;
      tag.extendsType = _elements[extendsTag];
    }
  }

  void visitElement(Element node) {
    switch (node.tagName) {
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

    if (_isEntrypoint && !_dartTagSeen) {
      _logger.error(USE_INIT_DART, span: doc.body.sourceSpan);
    }
  }

  /** Produce warnings for invalid link-rel tags. */
  void _validateLinkElement(Element node) {
    var rel = node.attributes['rel'];
    if (rel != 'import' && rel != 'stylesheet') return;

    if (rel == 'import' && _dartTagSeen) {
      _logger.warning(
          "Move HTML imports above your Dart script tag.",
          span: node.sourceSpan);
    }

    var href = node.attributes['href'];
    if (href != null && href != '') return;

    // TODO(sigmund): warn also if href can't be resolved.
    _logger.warning('link rel="$rel" missing href.', span: node.sourceSpan);
  }

  /** Produce warnings if using `<element>` instead of `<polymer-element>`. */
  void _validateElementElement(Element node) {
    _logger.warning('<element> elements are not supported, use'
        ' <polymer-element> instead', span: node.sourceSpan);
  }

  /**
   * Produce warnings if using `<polymer-element>` in the wrong place or if the
   * definition is not complete.
   */
  void _validatePolymerElement(Element node) {
    if (_inPolymerElement) {
      _logger.error('Nested polymer element definitions are not allowed.',
          span: node.sourceSpan);
      return;
    }

    var tagName = node.attributes['name'];
    var extendsTag = node.attributes['extends'];

    if (tagName == null) {
      _logger.error('Missing tag name of the custom element. Please include an '
          'attribute like \'name="your-tag-name"\'.',
          span: node.sourceSpan);
    } else if (!_isCustomTag(tagName)) {
      _logger.error('Invalid name "$tagName". Custom element names must have '
          'at least one dash and can\'t be any of the following names: '
          '${_invalidTagNames.keys.join(", ")}.',
          span: node.sourceSpan);
    }

    if (_elements[extendsTag] == null && _isCustomTag(extendsTag)) {
      _logger.warning('custom element with name "$extendsTag" not found.',
          span: node.sourceSpan);
    }

    var attrs = node.attributes['attributes'];
    if (attrs != null) {
      var attrsSpan = node.attributeSpans['attributes'];

      // names='a b c' or names='a,b,c'
      // record each name for publishing
      for (var attr in attrs.split(attrs.contains(',') ? ',' : ' ')) {
        // remove excess ws
        attr = attr.trim();
        if (!_validateCustomAttributeName(attr, attrsSpan)) break;
      }
    }

    var oldValue = _inPolymerElement;
    _inPolymerElement = true;
    super.visitElement(node);
    _inPolymerElement = oldValue;
  }

  /**
   * Produces warnings for malformed script tags. In html5 leaving off type= is
   * fine, but it defaults to text/javascript. Because this might be a common
   * error, we warn about it when  src file ends in .dart, but the type is
   * incorrect, or when users write code in an inline script tag of a custom
   * element.
   *
   * The hope is that these cases shouldn't break existing valid code, but that
   * they'll help Polymer authors avoid having their Dart code accidentally
   * interpreted as JavaScript by the browser.
   */
  void _validateScriptElement(Element node) {
    var scriptType = node.attributes['type'];
    var isDart = scriptType == 'application/dart';
    var src = node.attributes['src'];

    if (scriptType == null) {
      if (src == null && _inPolymerElement) {
        // TODO(sigmund): revisit this check once we start interop with polymer
        // elements written in JS. Maybe we need to inspect the contents of the
        // script to find whether there is an import or something that indicates
        // that the code is indeed using Dart.
        _logger.warning('script tag in polymer element with no type will '
            'be treated as JavaScript. Did you forget type="application/dart"?',
            span: node.sourceSpan);
      }
    } else if (isDart) {
      if (_dartTagSeen) {
        _logger.warning('Only one "application/dart" script tag per document '
            'is allowed.', span: node.sourceSpan);
      }
      _dartTagSeen = true;
    }

    if (src == null) return;

    if (src == 'packages/polymer/boot.js') {
      _logger.warning(BOOT_JS_DEPRECATED, span: node.sourceSpan);
      return;
    }

    if (src.endsWith('.dart') && !isDart) {
      _logger.warning('Wrong script type, expected type="application/dart".',
          span: node.sourceSpan);
      return;
    }

    if (!src.endsWith('.dart') && isDart) {
      _logger.warning('"application/dart" scripts should '
          'use the .dart file extension.',
          span: node.sourceSpan);
      return;
    }

    if (node.innerHtml.trim() != '') {
      _logger.warning('script tag has "src" attribute and also has script '
          'text.', span: node.sourceSpan);
    }
  }

  /**
   * Produces warnings for misuses of on-foo event handlers, and for instanting
   * custom tags incorrectly.
   */
  void _validateNormalElement(Element node) {
    // Event handlers only allowed inside polymer-elements
    node.attributes.forEach((name, value) {
      if (name is String && name.startsWith('on')) {
        _validateEventHandler(node, name, value);
      }
    });

    // Validate uses of custom-tags
    var nodeTag = node.tagName;
    var hasIsAttribute;
    var customTagName;
    if (_isCustomTag(nodeTag)) {
      // <fancy-button>
      customTagName = nodeTag;
      hasIsAttribute = false;
    } else {
      // <button is="fancy-button">
      customTagName = node.attributes['is'];
      hasIsAttribute = true;
    }

    if (customTagName == null || customTagName == 'polymer-element') return;

    var info = _elements[customTagName];
    if (info == null) {
      // TODO(jmesserly): this warning is wrong if someone is using raw custom
      // elements. Is there another way we can handle this warning that won't
      // generate false positives?
      _logger.warning('definition for Polymer element with tag name '
          '"$customTagName" not found.', span: node.sourceSpan);
      return;
    }

    var baseTag = info.baseExtendsTag;
    if (baseTag != null && !hasIsAttribute) {
      _logger.warning(
          'custom element "$customTagName" extends from "$baseTag", but '
          'this tag will not include the default properties of "$baseTag". '
          'To fix this, either write this tag as <$baseTag '
          'is="$customTagName"> or remove the "extends" attribute from '
          'the custom element declaration.', span: node.sourceSpan);
      return;
    }

    if (hasIsAttribute && baseTag == null) {
      _logger.warning(
          'custom element "$customTagName" doesn\'t declare any type '
          'extensions. To fix this, either rewrite this tag as '
          '<$customTagName> or add \'extends="$nodeTag"\' to '
          'the custom element declaration.', span: node.sourceSpan);
      return;
    }

    if (hasIsAttribute && baseTag != nodeTag) {
      _logger.warning(
          'custom element "$customTagName" extends from "$baseTag". '
          'Did you mean to write <$baseTag is="$customTagName">?',
          span: node.sourceSpan);
    }
  }

  /**
   * Validate an attribute on a custom-element. Returns true if valid.
   */
  bool _validateCustomAttributeName(String name, FileSpan span) {
    if (name.contains('-')) {
      var newName = toCamelCase(name);
      _logger.warning('PolymerElement no longer recognizes attribute names with '
          'dashes such as "$name". Use "$newName" or "${newName.toLowerCase()}" '
          'instead (both forms are equivalent in HTML).', span: span);
      return false;
    }
    return true;
  }

  /** Validate event handlers are used correctly. */
  void _validateEventHandler(Element node, String name, String value) {
    if (!name.startsWith('on-')) {
      _logger.warning('Event handler "$name" will be interpreted as an inline'
          ' JavaScript event handler. Use the form '
          'on-event-name="handlerName" if you want a Dart handler '
          'that will automatically update the UI based on model changes.',
          span: node.attributeSpans[name]);
      return;
    }

    if (!_inPolymerElement) {
      _logger.warning('Inline event handlers are only supported inside '
          'declarations of <polymer-element>.',
          span: node.attributeSpans[name]);
    }

    if (value.contains('.') || value.contains('(')) {
      _logger.warning('Invalid event handler body "$value". Declare a method '
          'in your custom element "void handlerName(event, detail, target)" '
          'and use the form $name="handlerName".',
          span: node.attributeSpans[name]);
    }
  }
}


// These names have meaning in SVG or MathML, so they aren't allowed as custom
// tags.
var _invalidTagNames = const {
  'annotation-xml': '',
  'color-profile': '',
  'font-face': '',
  'font-face-src': '',
  'font-face-uri': '',
  'font-face-format': '',
  'font-face-name': '',
  'missing-glyph': '',
};

/**
 * Returns true if this is a valid custom element name. See:
 * <https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/custom/index.html#dfn-custom-element-name>
 */
bool _isCustomTag(String name) {
  if (name == null || !name.contains('-')) return false;
  return !_invalidTagNames.containsKey(name);
}

const String USE_INIT_DART =
    'To run a polymer application, you need to call "initPolymer". You can '
    'either include a generic script tag that does this for you:'
    '\'<script type="application/dart">export "package:polymer/init.dart";'
    '</script>\' or add your own script tag and call that function. '
    'Make sure the script tag is placed after all HTML imports.';

const String BOOT_JS_DEPRECATED =
    '"boot.js" is now deprecated. Instead, you can initialize your polymer '
    'application by calling "initPolymer()" in your main. If you don\'t have a '
    'main, then you can include our generic main by adding the following '
    'script tag to your page: \'<script type="application/dart">export '
    '"package:polymer/init.dart";</script>\'. Additionally you need to '
    'include: \'<script src="packages/browser/dart.js"></script>\' in the page '
    'too. Make sure these script tags come after all HTML imports.';
