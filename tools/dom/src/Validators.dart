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
        _hiddenAnchor.protocol == ':');
  }
}


class _ThrowsNodeValidator implements NodeValidator {
  final NodeValidator validator;

  _ThrowsNodeValidator(this.validator) {}

  bool allowsElement(Element element) {
    if (!validator.allowsElement(element)) {
      throw new ArgumentError(element.tagName);
    }
    return true;
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (!validator.allowsAttribute(element, attributeName, value)) {
      throw new ArgumentError('${element.tagName}[$attributeName="$value"]');
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
    void walk(Node node) {
      sanitizeNode(node);

      var child = node.lastChild;
      while (child != null) {
        // Child may be removed during the walk.
        var nextChild = child.previousNode;
        walk(child);
        child = nextChild;
      }
    }
    walk(node);
  }

  void sanitizeNode(Node node) {
    switch (node.nodeType) {
      case Node.ELEMENT_NODE:
        Element element = node;
        var attrs = element.attributes;
        if (!validator.allowsElement(element)) {
          element.remove();
          break;
        }

        var isAttr = attrs['is'];
        if (isAttr != null) {
          if (!validator.allowsAttribute(element, 'is', isAttr)) {
            element.remove();
            break;
          }
        }

        // TODO(blois): Need to be able to get all attributes, irrespective of
        // XMLNS.
        var keys = attrs.keys.toList();
        for (var i = attrs.length - 1; i >= 0; --i) {
          var name = keys[i];
          if (!validator.allowsAttribute(element, name.toLowerCase(),
              attrs[name])) {
            attrs.remove(name);
          }
        }

        if (element is TemplateElement) {
          TemplateElement template = element;
          sanitizeTree(template.content);
        }
        break;
      case Node.COMMENT_NODE:
      case Node.DOCUMENT_FRAGMENT_NODE:
      case Node.TEXT_NODE:
      case Node.CDATA_SECTION_NODE:
        break;
      default:
        node.remove();
    }
  }
}
