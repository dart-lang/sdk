// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

/**
 * Class which helps construct standard node validation policies.
 *
 * By default this will not accept anything, but the 'allow*' functions can be
 * used to expand what types of elements or attributes are allowed.
 *
 * All allow functions are additive- elements will be accepted if they are
 * accepted by any specific rule.
 *
 * It is important to remember that sanitization is not just intended to prevent
 * cross-site scripting attacks, but also to prevent information from being
 * displayed in unexpected ways. For example something displaying basic
 * formatted text may not expect `<video>` tags to appear. In this case an
 * empty NodeValidatorBuilder with just [allowTextElements] might be
 * appropriate.
 */
class NodeValidatorBuilder implements NodeValidator {
  final List<NodeValidator> _validators = <NodeValidator>[];

  NodeValidatorBuilder() {}

  /**
   * Creates a new NodeValidatorBuilder which accepts common constructs.
   *
   * By default this will accept HTML5 elements and attributes with the default
   * [UriPolicy] and templating elements.
   *
   * Notable syntax which is filtered:
   *
   * * Only known-good HTML5 elements and attributes are allowed.
   * * All URLs must be same-origin, use [allowNavigation] and [allowImages] to
   * specify additional URI policies.
   * * Inline-styles are not allowed.
   * * Custom element tags are disallowed, use [allowCustomElement].
   * * Custom tags extensions are disallowed, use [allowTagExtension].
   * * SVG Elements are not allowed, use [allowSvg].
   *
   * For scenarios where the HTML should only contain formatted text
   * [allowTextElements] is more appropriate.
   *
   * Use [allowSvg] to allow SVG elements.
   */
  NodeValidatorBuilder.common() {
    allowHtml5();
    allowTemplating();
  }

  /**
   * Allows navigation elements- Form and Anchor tags, along with common
   * attributes.
   *
   * The UriPolicy can be used to restrict the locations the navigation elements
   * are allowed to direct to. By default this will use the default [UriPolicy].
   */
  void allowNavigation([UriPolicy uriPolicy]) {
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }
    add(new _SimpleNodeValidator.allowNavigation(uriPolicy));
  }

  /**
   * Allows image elements.
   *
   * The UriPolicy can be used to restrict the locations the images may be
   * loaded from. By default this will use the default [UriPolicy].
   */
  void allowImages([UriPolicy uriPolicy]) {
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }
    add(new _SimpleNodeValidator.allowImages(uriPolicy));
  }

  /**
   * Allow basic text elements.
   *
   * This allows a subset of HTML5 elements, specifically just these tags and
   * no attributes.
   *
   * * B
   * * BLOCKQUOTE
   * * BR
   * * EM
   * * H1
   * * H2
   * * H3
   * * H4
   * * H5
   * * H6
   * * HR
   * * I
   * * LI
   * * OL
   * * P
   * * SPAN
   * * UL
   */
  void allowTextElements() {
    add(new _SimpleNodeValidator.allowTextElements());
  }

  /**
   * Allow inline styles on elements.
   *
   * If [tagName] is not specified then this allows inline styles on all
   * elements. Otherwise tagName limits the styles to the specified elements.
   */
  void allowInlineStyles({String tagName}) {
    if (tagName == null) {
      tagName = '*';
    } else {
      tagName = tagName.toUpperCase();
    }
    add(new _SimpleNodeValidator(null, allowedAttributes: ['$tagName::style']));
  }

  /**
   * Allow common safe HTML5 elements and attributes.
   *
   * This list is based off of the Caja whitelists at:
   * https://code.google.com/p/google-caja/wiki/CajaWhitelists.
   *
   * Common things which are not allowed are script elements, style attributes
   * and any script handlers.
   */
  void allowHtml5({UriPolicy uriPolicy}) {
    add(new _Html5NodeValidator(uriPolicy: uriPolicy));
  }

  /**
   * Allow SVG elements and attributes except for known bad ones.
   */
  void allowSvg() {
    add(new _SvgNodeValidator());
  }

  /**
   * Allow custom elements with the specified tag name and specified attributes.
   *
   * This will allow the elements as custom tags (such as <x-foo></x-foo>),
   * but will not allow tag extensions. Use [allowTagExtension] to allow
   * tag extensions.
   */
  void allowCustomElement(String tagName,
      {UriPolicy uriPolicy,
      Iterable<String> attributes,
      Iterable<String> uriAttributes}) {
    var tagNameUpper = tagName.toUpperCase();
    var attrs = attributes
        ?.map/*<String>*/((name) => '$tagNameUpper::${name.toLowerCase()}');
    var uriAttrs = uriAttributes
        ?.map/*<String>*/((name) => '$tagNameUpper::${name.toLowerCase()}');
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }

    add(new _CustomElementNodeValidator(
        uriPolicy, [tagNameUpper], attrs, uriAttrs, false, true));
  }

  /**
   * Allow custom tag extensions with the specified type name and specified
   * attributes.
   *
   * This will allow tag extensions (such as <div is="x-foo"></div>),
   * but will not allow custom tags. Use [allowCustomElement] to allow
   * custom tags.
   */
  void allowTagExtension(String tagName, String baseName,
      {UriPolicy uriPolicy,
      Iterable<String> attributes,
      Iterable<String> uriAttributes}) {
    var baseNameUpper = baseName.toUpperCase();
    var tagNameUpper = tagName.toUpperCase();
    var attrs = attributes
        ?.map/*<String>*/((name) => '$baseNameUpper::${name.toLowerCase()}');
    var uriAttrs = uriAttributes
        ?.map/*<String>*/((name) => '$baseNameUpper::${name.toLowerCase()}');
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }

    add(new _CustomElementNodeValidator(uriPolicy,
        [tagNameUpper, baseNameUpper], attrs, uriAttrs, true, false));
  }

  void allowElement(String tagName,
      {UriPolicy uriPolicy,
      Iterable<String> attributes,
      Iterable<String> uriAttributes}) {
    allowCustomElement(tagName,
        uriPolicy: uriPolicy,
        attributes: attributes,
        uriAttributes: uriAttributes);
  }

  /**
   * Allow templating elements (such as <template> and template-related
   * attributes.
   *
   * This still requires other validators to allow regular attributes to be
   * bound (such as [allowHtml5]).
   */
  void allowTemplating() {
    add(new _TemplatingNodeValidator());
  }

  /**
   * Add an additional validator to the current list of validators.
   *
   * Elements and attributes will be accepted if they are accepted by any
   * validators.
   */
  void add(NodeValidator validator) {
    _validators.add(validator);
  }

  bool allowsElement(Element element) {
    return _validators.any((v) => v.allowsElement(element));
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    return _validators
        .any((v) => v.allowsAttribute(element, attributeName, value));
  }
}

class _SimpleNodeValidator implements NodeValidator {
  final Set<String> allowedElements = new Set<String>();
  final Set<String> allowedAttributes = new Set<String>();
  final Set<String> allowedUriAttributes = new Set<String>();
  final UriPolicy uriPolicy;

  factory _SimpleNodeValidator.allowNavigation(UriPolicy uriPolicy) {
    return new _SimpleNodeValidator(uriPolicy, allowedElements: const [
      'A',
      'FORM'
    ], allowedAttributes: const [
      'A::accesskey',
      'A::coords',
      'A::hreflang',
      'A::name',
      'A::shape',
      'A::tabindex',
      'A::target',
      'A::type',
      'FORM::accept',
      'FORM::autocomplete',
      'FORM::enctype',
      'FORM::method',
      'FORM::name',
      'FORM::novalidate',
      'FORM::target',
    ], allowedUriAttributes: const [
      'A::href',
      'FORM::action',
    ]);
  }

  factory _SimpleNodeValidator.allowImages(UriPolicy uriPolicy) {
    return new _SimpleNodeValidator(uriPolicy, allowedElements: const [
      'IMG'
    ], allowedAttributes: const [
      'IMG::align',
      'IMG::alt',
      'IMG::border',
      'IMG::height',
      'IMG::hspace',
      'IMG::ismap',
      'IMG::name',
      'IMG::usemap',
      'IMG::vspace',
      'IMG::width',
    ], allowedUriAttributes: const [
      'IMG::src',
    ]);
  }

  factory _SimpleNodeValidator.allowTextElements() {
    return new _SimpleNodeValidator(null, allowedElements: const [
      'B',
      'BLOCKQUOTE',
      'BR',
      'EM',
      'H1',
      'H2',
      'H3',
      'H4',
      'H5',
      'H6',
      'HR',
      'I',
      'LI',
      'OL',
      'P',
      'SPAN',
      'UL',
    ]);
  }

  /**
   * Elements must be uppercased tag names. For example `'IMG'`.
   * Attributes must be uppercased tag name followed by :: followed by
   * lowercase attribute name. For example `'IMG:src'`.
   */
  _SimpleNodeValidator(this.uriPolicy,
      {Iterable<String> allowedElements,
      Iterable<String> allowedAttributes,
      Iterable<String> allowedUriAttributes}) {
    this.allowedElements.addAll(allowedElements ?? const []);
    allowedAttributes = allowedAttributes ?? const [];
    allowedUriAttributes = allowedUriAttributes ?? const [];
    var legalAttributes = allowedAttributes
        .where((x) => !_Html5NodeValidator._uriAttributes.contains(x));
    var extraUriAttributes = allowedAttributes
        .where((x) => _Html5NodeValidator._uriAttributes.contains(x));
    this.allowedAttributes.addAll(legalAttributes);
    this.allowedUriAttributes.addAll(allowedUriAttributes);
    this.allowedUriAttributes.addAll(extraUriAttributes);
  }

  bool allowsElement(Element element) {
    return allowedElements.contains(Element._safeTagName(element));
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    var tagName = Element._safeTagName(element);
    if (allowedUriAttributes.contains('$tagName::$attributeName')) {
      return uriPolicy.allowsUri(value);
    } else if (allowedUriAttributes.contains('*::$attributeName')) {
      return uriPolicy.allowsUri(value);
    } else if (allowedAttributes.contains('$tagName::$attributeName')) {
      return true;
    } else if (allowedAttributes.contains('*::$attributeName')) {
      return true;
    } else if (allowedAttributes.contains('$tagName::*')) {
      return true;
    } else if (allowedAttributes.contains('*::*')) {
      return true;
    }
    return false;
  }
}

class _CustomElementNodeValidator extends _SimpleNodeValidator {
  final bool allowTypeExtension;
  final bool allowCustomTag;

  _CustomElementNodeValidator(
      UriPolicy uriPolicy,
      Iterable<String> allowedElements,
      Iterable<String> allowedAttributes,
      Iterable<String> allowedUriAttributes,
      bool allowTypeExtension,
      bool allowCustomTag)
      : this.allowTypeExtension = allowTypeExtension == true,
        this.allowCustomTag = allowCustomTag == true,
        super(uriPolicy,
            allowedElements: allowedElements,
            allowedAttributes: allowedAttributes,
            allowedUriAttributes: allowedUriAttributes);

  bool allowsElement(Element element) {
    if (allowTypeExtension) {
      var isAttr = element.attributes['is'];
      if (isAttr != null) {
        return allowedElements.contains(isAttr.toUpperCase()) &&
            allowedElements.contains(Element._safeTagName(element));
      }
    }
    return allowCustomTag &&
        allowedElements.contains(Element._safeTagName(element));
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (allowsElement(element)) {
      if (allowTypeExtension &&
          attributeName == 'is' &&
          allowedElements.contains(value.toUpperCase())) {
        return true;
      }
      return super.allowsAttribute(element, attributeName, value);
    }
    return false;
  }
}

class _TemplatingNodeValidator extends _SimpleNodeValidator {
  static const _TEMPLATE_ATTRS = const <String>[
    'bind',
    'if',
    'ref',
    'repeat',
    'syntax'
  ];

  final Set<String> _templateAttrs;

  _TemplatingNodeValidator()
      : _templateAttrs = new Set<String>.from(_TEMPLATE_ATTRS),
        super(null,
            allowedElements: ['TEMPLATE'],
            allowedAttributes:
                _TEMPLATE_ATTRS.map((attr) => 'TEMPLATE::$attr')) {}

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (super.allowsAttribute(element, attributeName, value)) {
      return true;
    }

    if (attributeName == 'template' && value == "") {
      return true;
    }

    if (element.attributes['template'] == "") {
      return _templateAttrs.contains(attributeName);
    }
    return false;
  }
}

class _SvgNodeValidator implements NodeValidator {
  bool allowsElement(Element element) {
    if (element is svg.ScriptElement) {
      return false;
    }
    // Firefox 37 has issues with creating foreign elements inside a
    // foreignobject tag as SvgElement. We don't want foreignobject contents
    // anyway, so just remove the whole tree outright. And we can't rely
    // on IE recognizing the SvgForeignObject type, so go by tagName. Bug 23144
    if (element is svg.SvgElement &&
        Element._safeTagName(element) == 'foreignObject') {
      return false;
    }
    if (element is svg.SvgElement) {
      return true;
    }
    return false;
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (attributeName == 'is' || attributeName.startsWith('on')) {
      return false;
    }
    return allowsElement(element);
  }
}
