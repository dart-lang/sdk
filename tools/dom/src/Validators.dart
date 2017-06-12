// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

/**
 * Interface used to validate that only accepted elements and attributes are
 * allowed while parsing HTML strings into DOM nodes.
 *
 * In general, customization of validation behavior should be done via the
 * [NodeValidatorBuilder] class to mitigate the chances of incorrectly
 * implementing validation rules.
 */
abstract class NodeValidator {
  /**
   * Construct a default NodeValidator which only accepts whitelisted HTML5
   * elements and attributes.
   *
   * If a uriPolicy is not specified then the default uriPolicy will be used.
   */
  factory NodeValidator({UriPolicy uriPolicy}) =>
      new _Html5NodeValidator(uriPolicy: uriPolicy);

  factory NodeValidator.throws(NodeValidator base) =>
      new _ThrowsNodeValidator(base);

  /**
   * Returns true if the tagName is an accepted type.
   */
  bool allowsElement(Element element);

  /**
   * Returns true if the attribute is allowed.
   *
   * The attributeName parameter will always be in lowercase.
   *
   * See [allowsElement] for format of tagName.
   */
  bool allowsAttribute(Element element, String attributeName, String value);
}

/**
 * Performs sanitization of a node tree after construction to ensure that it
 * does not contain any disallowed elements or attributes.
 *
 * In general custom implementations of this class should not be necessary and
 * all validation customization should be done in custom NodeValidators, but
 * custom implementations of this class can be created to perform more complex
 * tree sanitization.
 */
abstract class NodeTreeSanitizer {
  /**
   * Constructs a default tree sanitizer which will remove all elements and
   * attributes which are not allowed by the provided validator.
   */
  factory NodeTreeSanitizer(NodeValidator validator) =>
      new _ValidatingTreeSanitizer(validator);

  /**
   * Called with the root of the tree which is to be sanitized.
   *
   * This method needs to walk the entire tree and either remove elements and
   * attributes which are not recognized as safe or throw an exception which
   * will mark the entire tree as unsafe.
   */
  void sanitizeTree(Node node);

  /**
   * A sanitizer for trees that we trust. It does no validation and allows
   * any elements. It is also more efficient, since it can pass the text
   * directly through to the underlying APIs without creating a document
   * fragment to be sanitized.
   */
  static const trusted = const _TrustedHtmlTreeSanitizer();
}

/**
 * A sanitizer for trees that we trust. It does no validation and allows
 * any elements.
 */
class _TrustedHtmlTreeSanitizer implements NodeTreeSanitizer {
  const _TrustedHtmlTreeSanitizer();

  sanitizeTree(Node node) {}
}

/**
 * Defines the policy for what types of uris are allowed for particular
 * attribute values.
 *
 * This can be used to provide custom rules such as allowing all http:// URIs
 * for image attributes but only same-origin URIs for anchor tags.
 */
abstract class UriPolicy {
  /**
   * Constructs the default UriPolicy which is to only allow Uris to the same
   * origin as the application was launched from.
   *
   * This will block all ftp: mailto: URIs. It will also block accessing
   * https://example.com if the app is running from http://example.com.
   */
  factory UriPolicy() => new _SameOriginUriPolicy();

  /**
   * Checks if the uri is allowed on the specified attribute.
   *
   * The uri provided may or may not be a relative path.
   */
  bool allowsUri(String uri);
}

/**
 * Allows URIs to the same origin as the current application was loaded from
 * (such as https://example.com:80).
 */
class _SameOriginUriPolicy implements UriPolicy {
  final AnchorElement _hiddenAnchor = new AnchorElement();
  final Location _loc = window.location;

  bool allowsUri(String uri) {
    _hiddenAnchor.href = uri;
    // IE leaves an empty hostname for same-origin URIs.
    return (_hiddenAnchor.hostname == _loc.hostname &&
            _hiddenAnchor.port == _loc.port &&
            _hiddenAnchor.protocol == _loc.protocol) ||
        (_hiddenAnchor.hostname == '' &&
            _hiddenAnchor.port == '' &&
            (_hiddenAnchor.protocol == ':' || _hiddenAnchor.protocol == ''));
  }
}

class _ThrowsNodeValidator implements NodeValidator {
  final NodeValidator validator;

  _ThrowsNodeValidator(this.validator) {}

  bool allowsElement(Element element) {
    if (!validator.allowsElement(element)) {
      throw new ArgumentError(Element._safeTagName(element));
    }
    return true;
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (!validator.allowsAttribute(element, attributeName, value)) {
      throw new ArgumentError(
          '${Element._safeTagName(element)}[$attributeName="$value"]');
    }
  }
}

/**
 * Standard tree sanitizer which validates a node tree against the provided
 * validator and removes any nodes or attributes which are not allowed.
 */
class _ValidatingTreeSanitizer implements NodeTreeSanitizer {
  NodeValidator validator;
  _ValidatingTreeSanitizer(this.validator) {}

  void sanitizeTree(Node node) {
    void walk(Node node, Node parent) {
      sanitizeNode(node, parent);

      var child = node.lastChild;
      while (null != child) {
        var nextChild;
        try {
          // Child may be removed during the walk, and we may not
          // even be able to get its previousNode.
          nextChild = child.previousNode;
        } catch (e) {
          // Child appears bad, remove it. We want to check the rest of the
          // children of node and, but we have no way of getting to the next
          // child, so start again from the last child.
          _removeNode(child, node);
          child = null;
          nextChild = node.lastChild;
        }
        if (child != null) walk(child, node);
        child = nextChild;
      }
    }

    walk(node, null);
  }

  /// Aggressively try to remove node.
  void _removeNode(Node node, Node parent) {
    // If we have the parent, it's presumably already passed more sanitization
    // or is the fragment, so ask it to remove the child. And if that fails
    // try to set the outer html.
    if (parent == null) {
      node.remove();
    } else {
      parent._removeChild(node);
    }
  }

  /// Sanitize the element, assuming we can't trust anything about it.
  void _sanitizeUntrustedElement(/* Element */ element, Node parent) {
    // If the _hasCorruptedAttributes does not successfully return false,
    // then we consider it corrupted and remove.
    // TODO(alanknight): This is a workaround because on Firefox
    // embed/object
    // tags typeof is "function", not "object". We don't recognize them, and
    // can't call methods. This does mean that you can't explicitly allow an
    // embed tag. The only thing that will let it through is a null
    // sanitizer that doesn't traverse the tree at all. But sanitizing while
    // allowing embeds seems quite unlikely. This is also the reason that we
    // can't declare the type of element, as an embed won't pass any type
    // check in dart2js.
    var corrupted = true;
    var attrs;
    var isAttr;
    try {
      // If getting/indexing attributes throws, count that as corrupt.
      attrs = element.attributes;
      isAttr = attrs['is'];
      var corruptedTest1 = Element._hasCorruptedAttributes(element);

      // On IE, erratically, the hasCorruptedAttributes test can return false,
      // even though it clearly is corrupted. A separate copy of the test
      // inlining just the basic check seems to help.
      corrupted = corruptedTest1
          ? true
          : Element._hasCorruptedAttributesAdditionalCheck(element);
    } catch (e) {}
    var elementText = 'element unprintable';
    try {
      elementText = element.toString();
    } catch (e) {}
    try {
      var elementTagName = Element._safeTagName(element);
      _sanitizeElement(element, parent, corrupted, elementText, elementTagName,
          attrs, isAttr);
    } on ArgumentError {
      // Thrown by _ThrowsNodeValidator
      rethrow;
    } catch (e) {
      // Unexpected exception sanitizing -> remove
      _removeNode(element, parent);
      window.console.warn('Removing corrupted element $elementText');
    }
  }

  /// Having done basic sanity checking on the element, and computed the
  /// important attributes we want to check, remove it if it's not valid
  /// or not allowed, either as a whole or particular attributes.
  void _sanitizeElement(Element element, Node parent, bool corrupted,
      String text, String tag, Map attrs, String isAttr) {
    if (false != corrupted) {
      _removeNode(element, parent);
      window.console
          .warn('Removing element due to corrupted attributes on <$text>');
      return;
    }
    if (!validator.allowsElement(element)) {
      _removeNode(element, parent);
      window.console.warn('Removing disallowed element <$tag> from $parent');
      return;
    }

    if (isAttr != null) {
      if (!validator.allowsAttribute(element, 'is', isAttr)) {
        _removeNode(element, parent);
        window.console.warn('Removing disallowed type extension '
            '<$tag is="$isAttr">');
        return;
      }
    }

    // TODO(blois): Need to be able to get all attributes, irrespective of
    // XMLNS.
    var keys = attrs.keys.toList();
    for (var i = attrs.length - 1; i >= 0; --i) {
      var name = keys[i];
      if (!validator.allowsAttribute(
          element, name.toLowerCase(), attrs[name])) {
        window.console.warn('Removing disallowed attribute '
            '<$tag $name="${attrs[name]}">');
        attrs.remove(name);
      }
    }

    if (element is TemplateElement) {
      TemplateElement template = element;
      sanitizeTree(template.content);
    }
  }

  /// Sanitize the node and its children recursively.
  void sanitizeNode(Node node, Node parent) {
    switch (node.nodeType) {
      case Node.ELEMENT_NODE:
        _sanitizeUntrustedElement(node, parent);
        break;
      case Node.COMMENT_NODE:
      case Node.DOCUMENT_FRAGMENT_NODE:
      case Node.TEXT_NODE:
      case Node.CDATA_SECTION_NODE:
        break;
      default:
        _removeNode(node, parent);
    }
  }
}
