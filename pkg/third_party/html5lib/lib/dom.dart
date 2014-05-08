/// A simple tree API that results from parsing html. Intended to be compatible
/// with dart:html, but it is missing many types and APIs.
library dom;

// TODO(jmesserly): lots to do here. Originally I wanted to generate this using
// our Blink IDL generator, but another idea is to directly use the excellent
// http://dom.spec.whatwg.org/ and http://html.spec.whatwg.org/ and just
// implement that.

import 'dart:collection';
import 'package:source_maps/span.dart' show FileSpan;

import 'src/constants.dart';
import 'src/css_class_set.dart';
import 'src/list_proxy.dart';
import 'src/query_selector.dart' as query;
import 'src/token.dart';
import 'src/tokenizer.dart';
import 'dom_parsing.dart';
import 'parser.dart';

export 'src/css_class_set.dart' show CssClassSet;

// TODO(jmesserly): this needs to be replaced by an AttributeMap for attributes
// that exposes namespace info.
class AttributeName implements Comparable {
  /// The namespace prefix, e.g. `xlink`.
  final String prefix;

  /// The attribute name, e.g. `title`.
  final String name;

  /// The namespace url, e.g. `http://www.w3.org/1999/xlink`
  final String namespace;

  const AttributeName(this.prefix, this.name, this.namespace);

  String toString() {
    // Implement:
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#serializing-html-fragments
    // If we get here we know we are xml, xmlns, or xlink, because of
    // [HtmlParser.adjustForeignAttriubtes] is the only place we create
    // an AttributeName.
    return prefix != null ? '$prefix:$name' : name;
  }

  int get hashCode {
    int h = prefix.hashCode;
    h = 37 * (h & 0x1FFFFF) + name.hashCode;
    h = 37 * (h & 0x1FFFFF) + namespace.hashCode;
    return h & 0x3FFFFFFF;
  }

  int compareTo(other) {
    // Not sure about this sort order
    if (other is! AttributeName) return 1;
    int cmp = (prefix != null ? prefix : "").compareTo(
          (other.prefix != null ? other.prefix : ""));
    if (cmp != 0) return cmp;
    cmp = name.compareTo(other.name);
    if (cmp != 0) return cmp;
    return namespace.compareTo(other.namespace);
  }

  bool operator ==(x) {
    if (x is! AttributeName) return false;
    return prefix == x.prefix && name == x.name && namespace == x.namespace;
  }
}

// http://dom.spec.whatwg.org/#parentnode
abstract class _ParentNode implements Node {
  // TODO(jmesserly): this is only a partial implementation

  /// Seaches for the first descendant node matching the given selectors, using
  /// a preorder traversal.
  ///
  /// NOTE: Not all selectors from
  /// [selectors level 4](http://dev.w3.org/csswg/selectors-4/)
  /// are implemented. For example, nth-child does not implement An+B syntax
  /// and *-of-type is not implemented. If a selector is not implemented this
  /// method will throw [UniplmentedError].
  Element querySelector(String selector) =>
      query.querySelector(this, selector);

  /// Returns all descendant nodes matching the given selectors, using a
  /// preorder traversal.
  ///
  /// NOTE: Not all selectors from
  /// [selectors level 4](http://dev.w3.org/csswg/selectors-4/)
  /// are implemented. For example, nth-child does not implement An+B syntax
  /// and *-of-type is not implemented. If a selector is not implemented this
  /// method will throw [UniplmentedError].
  List<Element> querySelectorAll(String selector) =>
      query.querySelectorAll(this, selector);
}

// http://dom.spec.whatwg.org/#interface-nonelementparentnode
abstract class _NonElementParentNode implements _ParentNode {
  // TODO(jmesserly): could be faster, should throw on invalid id.
  Element getElementById(String id) => querySelector('#$id');
}

// This doesn't exist as an interface in the spec, but it's useful to merge
// common methods from these:
// http://dom.spec.whatwg.org/#interface-document
// http://dom.spec.whatwg.org/#element
abstract class _ElementAndDocument implements _ParentNode {
  // TODO(jmesserly): could be faster, should throw on invalid tag/class names.

  List<Element> getElementsByTagName(String localName) =>
      querySelectorAll(localName);

  List<Element> getElementsByClassName(String classNames) =>
      querySelectorAll(classNames.splitMapJoin(' ',
          onNonMatch: (m) => m.isNotEmpty ? '.$m' : m,
          onMatch: (m) => ''));
}

/// Really basic implementation of a DOM-core like Node.
abstract class Node {
  static const int ATTRIBUTE_NODE = 2;
  static const int CDATA_SECTION_NODE = 4;
  static const int COMMENT_NODE = 8;
  static const int DOCUMENT_FRAGMENT_NODE = 11;
  static const int DOCUMENT_NODE = 9;
  static const int DOCUMENT_TYPE_NODE = 10;
  static const int ELEMENT_NODE = 1;
  static const int ENTITY_NODE = 6;
  static const int ENTITY_REFERENCE_NODE = 5;
  static const int NOTATION_NODE = 12;
  static const int PROCESSING_INSTRUCTION_NODE = 7;
  static const int TEXT_NODE = 3;

  /// The parent of the current node (or null for the document node).
  Node parentNode;

  /// The parent element of this node.
  ///
  /// Returns null if this node either does not have a parent or its parent is
  /// not an element.
  Element get parent => parentNode is Element ? parentNode : null;

  // TODO(jmesserly): should move to Element.
  /// A map holding name, value pairs for attributes of the node.
  ///
  /// Note that attribute order needs to be stable for serialization, so we use
  /// a LinkedHashMap. Each key is a [String] or [AttributeName].
  LinkedHashMap<dynamic, String> attributes = new LinkedHashMap();

  /// A list of child nodes of the current node. This must
  /// include all elements but not necessarily other node types.
  final NodeList nodes = new NodeList._();

  List<Element> _elements;

  // TODO(jmesserly): consider using an Expando for this, and put it in
  // dom_parsing. Need to check the performance affect.
  /// The source span of this node, if it was created by the [HtmlParser].
  FileSpan sourceSpan;

  /// The attribute spans if requested. Otherwise null.
  LinkedHashMap<dynamic, FileSpan> _attributeSpans;
  LinkedHashMap<dynamic, FileSpan> _attributeValueSpans;

  Node._() {
    nodes._parent = this;
  }

  /// If [sourceSpan] is available, this contains the spans of each attribute.
  /// The span of an attribute is the entire attribute, including the name and
  /// quotes (if any). For example, the span of "attr" in `<a attr="value">`
  /// would be the text `attr="value"`.
  LinkedHashMap<dynamic, FileSpan> get attributeSpans {
    _ensureAttributeSpans();
    return _attributeSpans;
  }

  /// If [sourceSpan] is available, this contains the spans of each attribute's
  /// value. Unlike [attributeSpans], this span will inlcude only the value.
  /// For example, the value span of "attr" in `<a attr="value">` would be the
  /// text `value`.
  LinkedHashMap<dynamic, FileSpan> get attributeValueSpans {
    _ensureAttributeSpans();
    return _attributeValueSpans;
  }

  List<Element> get children {
    if (_elements == null) {
      _elements = new FilteredElementList(this);
    }
    return _elements;
  }

  /// Returns a copy of this node.
  ///
  /// If [deep] is `true`, then all of this node's children and decendents are
  /// copied as well. If [deep] is `false`, then only this node is copied.
  Node clone(bool deep);

  int get nodeType;

  // http://domparsing.spec.whatwg.org/#extensions-to-the-element-interface
  String get _outerHtml {
    var str = new StringBuffer();
    _addOuterHtml(str);
    return str.toString();
  }

  String get _innerHtml {
    var str = new StringBuffer();
    _addInnerHtml(str);
    return str.toString();
  }

  // Implemented per: http://dom.spec.whatwg.org/#dom-node-textcontent
  String get text => null;
  set text(String value) {}

  void append(Node node) => nodes.add(node);

  Node get firstChild => nodes.isNotEmpty ? nodes[0] : null;

  void _addOuterHtml(StringBuffer str);

  void _addInnerHtml(StringBuffer str) {
    for (Node child in nodes) child._addOuterHtml(str);
  }

  Node remove() {
    // TODO(jmesserly): is parent == null an error?
    if (parentNode != null) {
      parentNode.nodes.remove(this);
    }
    return this;
  }

  /// Insert [node] as a child of the current node, before [refNode] in the
  /// list of child nodes. Raises [UnsupportedOperationException] if [refNode]
  /// is not a child of the current node. If refNode is null, this adds to the
  /// end of the list.
  void insertBefore(Node node, Node refNode) {
    if (refNode == null) {
      nodes.add(node);
    } else {
      nodes.insert(nodes.indexOf(refNode), node);
    }
  }

  /// Replaces this node with another node.
  Node replaceWith(Node otherNode) {
    if (parentNode == null) {
      throw new UnsupportedError('Node must have a parent to replace it.');
    }
    parentNode.nodes[parentNode.nodes.indexOf(this)] = otherNode;
    return this;
  }

  // TODO(jmesserly): should this be a property or remove?
  /// Return true if the node has children or text.
  bool hasContent() => nodes.length > 0;

  /// Move all the children of the current node to [newParent].
  /// This is needed so that trees that don't store text as nodes move the
  /// text in the correct way.
  void reparentChildren(Node newParent) {
    newParent.nodes.addAll(nodes);
    nodes.clear();
  }

  bool hasChildNodes() => !nodes.isEmpty;

  bool contains(Node node) => nodes.contains(node);

  /// Checks if this is a type selector.
  /// See <http://www.w3.org/TR/CSS2/grammar.html>.
  /// Note: this doesn't support '*', the universal selector, non-ascii chars or
  /// escape chars.
  bool _isTypeSelector(String selector) {
    // Parser:

    // element_name
    //   : IDENT | '*'
    //   ;

    // Lexer:

    // nmstart   [_a-z]|{nonascii}|{escape}
    // nmchar    [_a-z0-9-]|{nonascii}|{escape}
    // ident   -?{nmstart}{nmchar}*
    // nonascii  [\240-\377]
    // unicode   \\{h}{1,6}(\r\n|[ \t\r\n\f])?
    // escape    {unicode}|\\[^\r\n\f0-9a-f]

    // As mentioned above, no nonascii or escape support yet.
    int len = selector.length;
    if (len == 0) return false;

    int i = 0;
    const int DASH = 45;
    if (selector.codeUnitAt(i) == DASH) i++;

    if (i >= len || !isLetter(selector[i])) return false;
    i++;

    for (; i < len; i++) {
      if (!isLetterOrDigit(selector[i]) && selector.codeUnitAt(i) != DASH) {
        return false;
      }
    }

    return true;
  }

  /// Initialize [attributeSpans] using [sourceSpan].
  void _ensureAttributeSpans() {
    if (_attributeSpans != null) return;

    _attributeSpans = new LinkedHashMap<dynamic, FileSpan>();
    _attributeValueSpans = new LinkedHashMap<dynamic, FileSpan>();

    if (sourceSpan == null) return;

    var tokenizer = new HtmlTokenizer(sourceSpan.text, generateSpans: true,
        attributeSpans: true);

    tokenizer.moveNext();
    var token = tokenizer.current as StartTagToken;

    if (token.attributeSpans == null) return; // no attributes

    for (var attr in token.attributeSpans) {
      var offset = sourceSpan.start.offset;
      _attributeSpans[attr.name] = sourceSpan.file.span(
          offset + attr.start, offset + attr.end);
      if (attr.startValue != null) {
        _attributeValueSpans[attr.name] = sourceSpan.file.span(
            offset + attr.startValue, offset + attr.endValue);
      }
    }
  }

  _clone(Node shallowClone, bool deep) {
    if (deep) {
      for (var child in nodes) {
        shallowClone.append(child.clone(true));
      }
    }
    return shallowClone;
  }
}

class Document extends Node
    with _ParentNode, _NonElementParentNode, _ElementAndDocument {

  Document() : super._();
  factory Document.html(String html) => parse(html);

  int get nodeType => Node.DOCUMENT_NODE;

  // TODO(jmesserly): optmize this if needed
  Element get documentElement => querySelector('html');
  Element get head => documentElement.querySelector('head');
  Element get body => documentElement.querySelector('body');

  /// Returns a fragment of HTML or XML that represents the element and its
  /// contents.
  // TODO(jmesserly): this API is not specified in:
  // <http://domparsing.spec.whatwg.org/> nor is it in dart:html, instead
  // only Element has outerHtml. However it is quite useful. Should we move it
  // to dom_parsing, where we keep other custom APIs?
  String get outerHtml => _outerHtml;

  String toString() => "#document";

  void _addOuterHtml(StringBuffer str) => _addInnerHtml(str);

  Document clone(bool deep) => _clone(new Document(), deep);

  Element createElement(String tag) => new Element.tag(tag);

  // TODO(jmesserly): this is only a partial implementation of:
  // http://dom.spec.whatwg.org/#dom-document-createelementns
  Element createElementNS(String namespaceUri, String tag) {
    if (namespaceUri == '') namespaceUri = null;
    return new Element._(tag, namespaceUri);
  }

  DocumentFragment createDocumentFragment() => new DocumentFragment();
}

class DocumentFragment extends Node
    with _ParentNode, _NonElementParentNode {

  DocumentFragment() : super._();
  factory DocumentFragment.html(String html) => parseFragment(html);

  int get nodeType => Node.DOCUMENT_FRAGMENT_NODE;

  /// Returns a fragment of HTML or XML that represents the element and its
  /// contents.
  // TODO(jmesserly): this API is not specified in:
  // <http://domparsing.spec.whatwg.org/> nor is it in dart:html, instead
  // only Element has outerHtml. However it is quite useful. Should we move it
  // to dom_parsing, where we keep other custom APIs?
  String get outerHtml => _outerHtml;

  String toString() => "#document-fragment";

  DocumentFragment clone(bool deep) => _clone(new DocumentFragment(), deep);

  void _addOuterHtml(StringBuffer str) => _addInnerHtml(str);

  String get text => _getText(this);
  set text(String value) => _setText(this, value);
}

class DocumentType extends Node {
  final String name;
  final String publicId;
  final String systemId;

  DocumentType(String name, this.publicId, this.systemId)
      // Note: once Node.tagName is removed, don't pass "name" to super
      : name = name, super._();

  int get nodeType => Node.DOCUMENT_TYPE_NODE;

  String toString() {
    if (publicId != null || systemId != null) {
      // TODO(jmesserly): the html5 serialization spec does not add these. But
      // it seems useful, and the parser can handle it, so for now keeping it.
      var pid = publicId != null ? publicId : '';
      var sid = systemId != null ? systemId : '';
      return '<!DOCTYPE $name "$pid" "$sid">';
    } else {
      return '<!DOCTYPE $name>';
    }
  }


  void _addOuterHtml(StringBuffer str) {
    str.write(toString());
  }

  DocumentType clone(bool deep) => new DocumentType(name, publicId, systemId);
}

class Text extends Node {
  String data;

  Text(this.data) : super._();

  int get nodeType => Node.TEXT_NODE;

  String toString() => '"$data"';

  void _addOuterHtml(StringBuffer str) => writeTextNodeAsHtml(str, this);

  Text clone(bool deep) => new Text(data);

  String get text => data;
  set text(String value) { data = value; }
}

// TODO(jmesserly): Elements should have a pointer back to their document
class Element extends Node with _ParentNode, _ElementAndDocument {
  final String namespaceUri;

  /// The [local name](http://dom.spec.whatwg.org/#concept-element-local-name)
  /// of this element.
  final String localName;

  Element._(this.localName, [this.namespaceUri]) : super._();

  Element.tag(this.localName) : namespaceUri = Namespaces.html, super._();

  static final _START_TAG_REGEXP = new RegExp('<(\\w+)');

  static final _CUSTOM_PARENT_TAG_MAP = const {
    'body': 'html',
    'head': 'html',
    'caption': 'table',
    'td': 'tr',
    'colgroup': 'table',
    'col': 'colgroup',
    'tr': 'tbody',
    'tbody': 'table',
    'tfoot': 'table',
    'thead': 'table',
    'track': 'audio',
  };

  // TODO(jmesserly): this is from dart:html _ElementFactoryProvider...
  // TODO(jmesserly): have a look at fixing some things in dart:html, in
  // particular: is the parent tag map complete? Is it faster without regexp?
  // TODO(jmesserly): for our version we can do something smarter in the parser.
  // All we really need is to set the correct parse state.
  factory Element.html(String html) {

    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match != null) {
      tag = match.group(1).toLowerCase();
      if (_CUSTOM_PARENT_TAG_MAP.containsKey(tag)) {
        parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      }
    }

    var fragment = parseFragment(html, container: parentTag);
    Element element;
    if (fragment.children.length == 1) {
      element = fragment.children[0];
    } else if (parentTag == 'html' && fragment.children.length == 2) {
      // You'll always get a head and a body when starting from html.
      element = fragment.children[tag == 'head' ? 0 : 1];
    } else {
      throw new ArgumentError('HTML had ${fragment.children.length} '
          'top level elements but 1 expected');
    }
    element.remove();
    return element;
  }

  int get nodeType => Node.ELEMENT_NODE;

  // TODO(jmesserly): we can make this faster
  Element get previousElementSibling {
    if (parentNode == null) return null;
    var siblings = parentNode.nodes;
    for (int i = siblings.indexOf(this) - 1; i >= 0; i--) {
      var s = siblings[i];
      if (s is Element) return s;
    }
    return null;
  }

  Element get nextElementSibling {
    if (parentNode == null) return null;
    var siblings = parentNode.nodes;
    for (int i = siblings.indexOf(this) + 1; i < siblings.length; i++) {
      var s = siblings[i];
      if (s is Element) return s;
    }
    return null;
  }

  String toString() {
    var prefix = Namespaces.getPrefix(namespaceUri);
    return "<${prefix == null ? '' : '$prefix '}$localName>";
  }

  String get text => _getText(this);
  set text(String value) => _setText(this, value);

  /// Returns a fragment of HTML or XML that represents the element and its
  /// contents.
  String get outerHtml => _outerHtml;

  /// Returns a fragment of HTML or XML that represents the element's contents.
  /// Can be set, to replace the contents of the element with nodes parsed from
  /// the given string.
  String get innerHtml => _innerHtml;
  // TODO(jmesserly): deprecate in favor of:
  // <https://api.dartlang.org/apidocs/channels/stable/#dart-dom-html.Element@id_setInnerHtml>
  set innerHtml(String value) {
    nodes.clear();
    // TODO(jmesserly): should be able to get the same effect by adding the
    // fragment directly.
    nodes.addAll(parseFragment(value, container: localName).nodes);
  }

  void _addOuterHtml(StringBuffer str) {
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#serializing-html-fragments
    // Element is the most complicated one.
    str.write('<${_getSerializationPrefix(namespaceUri)}$localName');

    if (attributes.length > 0) {
      attributes.forEach((key, v) {
        // Note: AttributeName.toString handles serialization of attribute
        // namespace, if needed.
        str.write(' $key="${htmlSerializeEscape(v, attributeMode: true)}"');
      });
    }

    str.write('>');

    if (nodes.length > 0) {
      if (localName == 'pre' || localName == 'textarea' ||
          localName == 'listing') {
        final first = nodes[0];
        if (first is Text && first.data.startsWith('\n')) {
          // These nodes will remove a leading \n at parse time, so if we still
          // have one, it means we started with two. Add it back.
          str.write('\n');
        }
      }

      _addInnerHtml(str);
    }

    // void elements must not have an end tag
    // http://dev.w3.org/html5/markup/syntax.html#void-elements
    if (!isVoidElement(localName)) str.write('</$localName>');
  }

  static String _getSerializationPrefix(String uri) {
    if (uri == null ||
        uri == Namespaces.html ||
        uri == Namespaces.mathml ||
        uri == Namespaces.svg) {
      return '';
    }
    var prefix = Namespaces.getPrefix(uri);
    // TODO(jmesserly): the spec doesn't define "qualified name".
    // I'm not sure if this is correct, but it should parse reasonably.
    return prefix == null ? '' : '$prefix:';
  }

  Element clone(bool deep) {
    var result = new Element._(localName, namespaceUri)
        ..attributes = new LinkedHashMap.from(attributes);
    return _clone(result, deep);
  }

  // http://dom.spec.whatwg.org/#dom-element-id
  String get id {
    var result = attributes['id'];
    return result != null ? result : '';
  }

  set id(String value) {
    attributes['id'] = '$value';
  }

  // http://dom.spec.whatwg.org/#dom-element-classname
  String get className {
    var result = attributes['class'];
    return result != null ? result : '';
  }

  set className(String value) {
    attributes['class'] = '$value';
  }

  /**
   * The set of CSS classes applied to this element.
   *
   * This set makes it easy to add, remove or toggle the classes applied to
   * this element.
   *
   *     element.classes.add('selected');
   *     element.classes.toggle('isOnline');
   *     element.classes.remove('selected');
   */
  CssClassSet get classes => new ElementCssClassSet(this);
}

class Comment extends Node {
  String data;

  Comment(this.data) : super._();

  int get nodeType => Node.COMMENT_NODE;

  String toString() => "<!-- $data -->";

  void _addOuterHtml(StringBuffer str) {
    str.write("<!--$data-->");
  }

  Comment clone(bool deep) => new Comment(data);

  String get text => data;
  set text(String value) {
    this.data = value;
  }
}


// TODO(jmesserly): fix this to extend one of the corelib classes if possible.
// (The requirement to remove the node from the old node list makes it tricky.)
// TODO(jmesserly): is there any way to share code with the _NodeListImpl?
class NodeList extends ListProxy<Node> {
  // Note: this is conceptually final, but because of circular reference
  // between Node and NodeList we initialize it after construction.
  Node _parent;

  NodeList._();

  Node get first => this[0];

  Node _setParent(Node node) {
    // Note: we need to remove the node from its previous parent node, if any,
    // before updating its parent pointer to point at our parent.
    node.remove();
    node.parentNode = _parent;
    return node;
  }

  void add(Node value) {
    if (value is DocumentFragment) {
      addAll(value.nodes);
    } else {
      super.add(_setParent(value));
    }
  }

  void addLast(Node value) => add(value);

  void addAll(Iterable<Node> collection) {
    // Note: we need to be careful if collection is another NodeList.
    // In particular:
    //   1. we need to copy the items before updating their parent pointers,
    //     _flattenDocFragments does a copy internally.
    //   2. we should update parent pointers in reverse order. That way they
    //      are removed from the original NodeList (if any) from the end, which
    //      is faster.
    var list = _flattenDocFragments(collection);
    for (var node in list.reversed) _setParent(node);
    super.addAll(list);
  }

  void insert(int index, Node value) {
    if (value is DocumentFragment) {
      insertAll(index, value.nodes);
    } else {
      super.insert(index, _setParent(value));
    }
  }

  Node removeLast() => super.removeLast()..parentNode = null;

  Node removeAt(int i) => super.removeAt(i)..parentNode = null;

  void clear() {
    for (var node in this) node.parentNode = null;
    super.clear();
  }

  void operator []=(int index, Node value) {
    if (value is DocumentFragment) {
      removeAt(index);
      insertAll(index, value.nodes);
    } else {
      this[index].parentNode = null;
      super[index] = _setParent(value);
    }
  }

  // TODO(jmesserly): These aren't implemented in DOM _NodeListImpl, see
  // http://code.google.com/p/dart/issues/detail?id=5371
  void setRange(int start, int rangeLength, List<Node> from,
                [int startFrom = 0]) {
    if (from is NodeList) {
      // Note: this is presumed to make a copy
      from = from.sublist(startFrom, startFrom + rangeLength);
    }
    // Note: see comment in [addAll]. We need to be careful about the order of
    // operations if [from] is also a NodeList.
    for (int i = rangeLength - 1; i >= 0; i--) {
      this[start + i] = from[startFrom + i];
    }
  }

  void replaceRange(int start, int end, Iterable<Node> newContents) {
    removeRange(start, end);
    insertAll(start, newContents);
  }

  void removeRange(int start, int rangeLength) {
    for (int i = start; i < rangeLength; i++) this[i].parentNode = null;
    super.removeRange(start, rangeLength);
  }

  void removeWhere(bool test(Element e)) {
    for (var node in where(test)) {
      node.parentNode = null;
    }
    super.removeWhere(test);
  }

  void retainWhere(bool test(Element e)) {
    for (var node in where((n) => !test(n))) {
      node.parentNode = null;
    }
    super.retainWhere(test);
  }

  void insertAll(int index, Iterable<Node> collection) {
    // Note: we need to be careful how we copy nodes. See note in addAll.
    var list = _flattenDocFragments(collection);
    for (var node in list.reversed) _setParent(node);
    super.insertAll(index, list);
  }

  _flattenDocFragments(Iterable<Node> collection) {
    // Note: this function serves two purposes:
    //  * it flattens document fragments
    //  * it creates a copy of [collections] when `collection is NodeList`.
    var result = [];
    for (var node in collection) {
      if (node is DocumentFragment) {
        result.addAll(node.nodes);
      } else {
        result.add(node);
      }
    }
    return result;
  }
}


/// An indexable collection of a node's descendants in the document tree,
/// filtered so that only elements are in the collection.
// TODO(jmesserly): this was copied from dart:html
// TODO(jmesserly): "implements List<Element>" is a workaround for analyzer bug.
class FilteredElementList extends IterableBase<Element> with ListMixin<Element>
    implements List<Element> {

  final Node _node;
  final List<Node> _childNodes;

  /// Creates a collection of the elements that descend from a node.
  ///
  /// Example usage:
  ///
  ///     var filteredElements = new FilteredElementList(query("#container"));
  ///     // filteredElements is [a, b, c].
  FilteredElementList(Node node): _childNodes = node.nodes, _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): we don't always need to create a new list. For example
  // forEach, every, any, ... could directly work on the _childNodes.
  List<Element> get _filtered =>
    new List<Element>.from(_childNodes.where((n) => n is Element));

  void forEach(void f(Element element)) {
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  void set length(int newLength) {
    final len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw new ArgumentError("Invalid list length");
    }

    removeRange(newLength, len);
  }

  String join([String separator = ""]) => _filtered.join(separator);

  void add(Element value) {
    _childNodes.add(value);
  }

  void addAll(Iterable<Element> iterable) {
    for (Element element in iterable) {
      add(element);
    }
  }

  bool contains(Element element) {
    return element is Element && _childNodes.contains(element);
  }

  Iterable<Element> get reversed => _filtered.reversed;

  void sort([int compare(Element a, Element b)]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  void setRange(int start, int end, Iterable<Element> iterable,
                [int skipCount = 0]) {
    throw new UnimplementedError();
  }

  void fillRange(int start, int end, [Element fillValue]) {
    throw new UnimplementedError();
  }

  void replaceRange(int start, int end, Iterable<Element> iterable) {
    throw new UnimplementedError();
  }

  void removeRange(int start, int end) {
    _filtered.sublist(start, end).forEach((el) => el.remove());
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      result.remove();
    }
    return result;
  }

  Iterable map(f(Element element)) => _filtered.map(f);
  Iterable<Element> where(bool f(Element element)) => _filtered.where(f);
  Iterable expand(Iterable f(Element element)) => _filtered.expand(f);

  void insert(int index, Element value) {
    _childNodes.insert(index, value);
  }

  void insertAll(int index, Iterable<Element> iterable) {
    _childNodes.insertAll(index, iterable);
  }

  Element removeAt(int index) {
    final result = this[index];
    result.remove();
    return result;
  }

  bool remove(Object element) {
    if (element is! Element) return false;
    for (int i = 0; i < length; i++) {
      Element indexElement = this[i];
      if (identical(indexElement, element)) {
        indexElement.remove();
        return true;
      }
    }
    return false;
  }

  Element reduce(Element combine(Element value, Element element)) {
    return _filtered.reduce(combine);
  }

  dynamic fold(dynamic initialValue,
      dynamic combine(dynamic previousValue, Element element)) {
    return _filtered.fold(initialValue, combine);
  }

  bool every(bool f(Element element)) => _filtered.every(f);
  bool any(bool f(Element element)) => _filtered.any(f);
  List<Element> toList({ bool growable: true }) =>
      new List<Element>.from(this, growable: growable);
  Set<Element> toSet() => new Set<Element>.from(this);
  Element firstWhere(bool test(Element value), {Element orElse()}) {
    return _filtered.firstWhere(test, orElse: orElse);
  }

  Element lastWhere(bool test(Element value), {Element orElse()}) {
    return _filtered.lastWhere(test, orElse: orElse);
  }

  Element singleWhere(bool test(Element value)) {
    return _filtered.singleWhere(test);
  }

  Element elementAt(int index) {
    return this[index];
  }

  bool get isEmpty => _filtered.isEmpty;
  int get length => _filtered.length;
  Element operator [](int index) => _filtered[index];
  Iterator<Element> get iterator => _filtered.iterator;
  List<Element> sublist(int start, [int end]) =>
    _filtered.sublist(start, end);
  Iterable<Element> getRange(int start, int end) =>
    _filtered.getRange(start, end);
  int indexOf(Element element, [int start = 0]) =>
    _filtered.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) {
    if (start == null) start = length - 1;
    return _filtered.lastIndexOf(element, start);
  }

  Element get first => _filtered.first;

  Element get last => _filtered.last;

  Element get single => _filtered.single;
}

// http://dom.spec.whatwg.org/#dom-node-textcontent
// For Element and DocumentFragment
String _getText(Node node) =>
    (new _ConcatTextVisitor()..visit(node)).toString();

void _setText(Node node, String value) {
  node.nodes.clear();
  node.append(new Text(value));
}

class _ConcatTextVisitor extends TreeVisitor {
  final _str = new StringBuffer();

  String toString() => _str.toString();

  visitText(Text node) {
    _str.write(node.data);
  }
}
