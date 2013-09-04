// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Logic to validate that developers are correctly using Polymer constructs.
 * This is mainly used to produce warnings for feedback in the editor.
 */
library polymer.src.linter;

import 'dart:async';
import 'dart:mirrors';
import 'dart:convert' show JSON;

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';

import 'transform/common.dart';

typedef String MessageFormatter(String kind, String message, Span span);

/**
 * A linter that checks for common Polymer errors and produces warnings to
 * show on the editor or the command line. Leaves sources unchanged, but creates
 * a new asset containing all the warnings.
 */
class Linter extends Transformer {
  /** Only run on .html files. */
  final String allowedExtensions = '.html';

  final MessageFormatter _formatter;

  Linter([this._formatter]);

  Future apply(Transform transform) {
    var wrapper = new _LoggerInterceptor(transform, _formatter);
    var seen = new Set<AssetId>();
    var primary = transform.primaryInput;
    var id = primary.id;
    wrapper.addOutput(primary); // this phase is analysis only
    seen.add(id);
    return readPrimaryAsHtml(wrapper).then((document) {
      return _collectElements(document, id, wrapper, seen).then((elements) {
        new _LinterVisitor(wrapper, elements).visit(document);
        var messagesId = id.addExtension('.messages');
        wrapper.addOutput(new Asset.fromString(messagesId,
            wrapper._messages.join('\n')));
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
    var logger = transform.logger;
    // Note: the import order is relevant, so we visit in that order.
    return Future.forEach(_getImportedIds(document, sourceId, logger), (id) {
      if (seen.contains(id)) return new Future.value(null);
      seen.add(id);
      return readAsHtml(id, transform)
        .then((doc) => _collectElements(doc, id, transform, seen, elements));
    }).then((_) {
      _addElements(document, logger, elements);
      return elements;
    });
  }

  List<AssetId> _getImportedIds(
      Document document, AssetId sourceId, TranformLogger logger) {
    var importIds = [];
    for (var tag in document.queryAll('link')) {
      if (tag.attributes['rel'] != 'import') continue;
      var href = tag.attributes['href'];
      var id = resolve(sourceId, href, logger, tag.sourceSpan);
      if (id == null) continue;
      importIds.add(id);
    }
    return importIds;
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
          existing.span);
        logger.warning('duplicate definition for custom tag "$name" '
          ' (second definition).', span);
        continue;
      }

      elements[name] = new _ElementSummary(name, extendsTag, tag.sourceSpan);
    }
  }
}

/** A proxy of [Transform] that returns a different logger. */
// TODO(sigmund): get rid of this when barback supports a better way to log
// messages without printing them.
class _LoggerInterceptor implements Transform, TransformLogger {
  final Transform _original;
  final List<String> _messages = [];
  final MessageFormatter _formatter;

  _LoggerInterceptor(this._original, MessageFormatter formatter)
      : _formatter = formatter == null ? _defaultFormatter : formatter;

  TransformLogger get logger => this;

  noSuchMethod(Invocation m) => reflect(_original).delegate(m);

  // form TransformLogger:
  void warning(String message, [Span span]) => _write('warning', message, span);

  void error(String message, [Span span]) => _write('error', message, span);

  void _write(String kind, String message, Span span) {
    _messages.add(_formatter(kind, message, span));
  }
}

/**
 * Default formatter that generates messages using a format that can be parsed
 * by tools, such as the Dart Editor, for reporting error messages.
 */
String _defaultFormatter(String kind, String message, Span span) {
  return JSON.encode((span == null)
      ? [{'method': 'warning', 'params': {'message': message}}]
      : [{'method': kind,
          'params': {
            'file': span.sourceUrl,
            'message': message,
            'line': span.start.line + 1,
            'charStart': span.start.offset,
            'charEnd': span.end.offset,
          }}]);
}


/**
 * Information needed about other polymer-element tags in order to validate
 * how they are used and extended.
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
  Map<String, _ElementSummary> _elements;

  _LinterVisitor(this._logger, this._elements) {
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

  /** Produce warnings for invalid link-rel tags. */
  void _validateLinkElement(Element node) {
    var rel = node.attributes['rel'];
    if (rel != 'import' && rel != 'stylesheet') return;

    var href = node.attributes['href'];
    if (href != null && href != '') return;

    // TODO(sigmund): warn also if href can't be resolved.
    _logger.warning('link rel="$rel" missing href.', node.sourceSpan);
  }

  /** Produce warnings if using `<element>` instead of `<polymer-element>`. */
  void _validateElementElement(Element node) {
    _logger.warning('<element> elements are not supported, use'
        ' <polymer-element> instead', node.sourceSpan);
  }

  /**
   * Produce warnings if using `<polymer-element>` in the wrong place or if the
   * definition is not complete.
   */
  void _validatePolymerElement(Element node) {
    if (_inPolymerElement) {
      _logger.error('Nested polymer element definitions are not allowed.',
          node.sourceSpan);
      return;
    }

    var tagName = node.attributes['name'];
    var extendsTag = node.attributes['extends'];

    if (tagName == null) {
      _logger.error('Missing tag name of the custom element. Please include an '
          'attribute like \'name="your-tag-name"\'.',
          node.sourceSpan);
    } else if (!_isCustomTag(tagName)) {
      _logger.error('Invalid name "$tagName". Custom element names must have '
          'at least one dash and can\'t be any of the following names: '
          '${_invalidTagNames.keys.join(", ")}.',
          node.sourceSpan);
    }

    if (_elements[extendsTag] == null && _isCustomTag(extendsTag)) {
      _logger.warning('custom element with name "$extendsTag" not found.',
          node.sourceSpan);
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
    var src = node.attributes['src'];

    if (scriptType == null) {
      if (src == null && _inPolymerElement) {
        // TODO(sigmund): revisit this check once we start interop with polymer
        // elements written in JS. Maybe we need to inspect the contents of the
        // script to find whether there is an import or something that indicates
        // that the code is indeed using Dart.
        _logger.warning('script tag in polymer element with no type will '
            'be treated as JavaScript. Did you forget type="application/dart"?',
            node.sourceSpan);
      }
      if (src != null && src.endsWith('.dart')) {
        _logger.warning('script tag with .dart source file but no type will '
            'be treated as JavaScript. Did you forget type="application/dart"?',
            node.sourceSpan);
      }
      return;
    }

    if (scriptType != 'application/dart') return;

    if (src != null) {
      if (!src.endsWith('.dart')) {
        _logger.warning('"application/dart" scripts should '
            'use the .dart file extension.',
            node.sourceSpan);
      }

      if (node.innerHtml.trim() != '') {
        _logger.warning('script tag has "src" attribute and also has script '
            'text.', node.sourceSpan);
      }
    }
  }

  /**
   * Produces warnings for misuses of on-foo event handlers, and for instanting
   * custom tags incorrectly.
   */
  void _validateNormalElement(Element node) {
    // Event handlers only allowed inside polymer-elements
    node.attributes.forEach((name, value) {
      if (name.startsWith('on')) {
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
      _logger.warning('definition for custom element with tag name '
          '"$customTagName" not found.', node.sourceSpan);
      return;
    } 

    var baseTag = info.baseExtendsTag;
    if (baseTag != null && !hasIsAttribute) {
      _logger.warning(
          'custom element "$customTagName" extends from "$baseTag", but '
          'this tag will not include the default properties of "$baseTag". '
          'To fix this, either write this tag as <$baseTag '
          'is="$customTagName"> or remove the "extends" attribute from '
          'the custom element declaration.', node.sourceSpan);
      return;
    }
    
    if (hasIsAttribute && baseTag == null) {
      _logger.warning(
          'custom element "$customTagName" doesn\'t declare any type '
          'extensions. To fix this, either rewrite this tag as '
          '<$customTagName> or add \'extends="$nodeTag"\' to '
          'the custom element declaration.', node.sourceSpan);
      return;
    }
    
    if (hasIsAttribute && baseTag != nodeTag) {
      _logger.warning(
          'custom element "$customTagName" extends from "$baseTag". '
          'Did you mean to write <$baseTag is="$customTagName">?',
          node.sourceSpan);
    }
  }

  /** Validate event handlers are used correctly. */
  void _validateEventHandler(Element node, String name, String value) {
    if (!name.startsWith('on-')) {
      _logger.warning('Event handler "$name" will be interpreted as an inline'
          ' JavaScript event handler. Use the form '
          'on-event-name="handlerName" if you want a Dart handler '
          'that will automatically update the UI based on model changes.',
          node.sourceSpan);
      return;
    }

    if (!_inPolymerElement) {
      _logger.warning('Inline event handlers are only supported inside '
          'declarations of <polymer-element>.', node.sourceSpan);
    }

    if (value.contains('.') || value.contains('(')) {
      _logger.warning('Invalid event handler body "$value". Declare a method '
          'in your custom element "void handlerName(event, detail, target)" '
          'and use the form $name="handlerName".',
          node.sourceSpan);
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
