// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _NodeImpl extends _EventTargetImpl implements Node native "*Node" {
  _NodeListImpl get nodes() {
    final list = _childNodes;
    list._parent = this;
    return list;
  }

  void set nodes(Collection<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    // TODO(jacobr): there is a better way to do this.
    List copy = new List.from(value);
    nodes.clear();
    nodes.addAll(copy);
  }

  // TODO(jacobr): should we throw an exception if parent is already null?
  _NodeImpl remove() {
    if (this.parent != null) {
      this.parent._removeChild(this);
    }
    return this;
  }

  _NodeImpl replaceWith(Node otherNode) {
    try {
      this.parent._replaceChild(otherNode, this);
    } catch(var e) {
      
    };
    return this;
  }


  static final int ATTRIBUTE_NODE = 2;

  static final int CDATA_SECTION_NODE = 4;

  static final int COMMENT_NODE = 8;

  static final int DOCUMENT_FRAGMENT_NODE = 11;

  static final int DOCUMENT_NODE = 9;

  static final int DOCUMENT_POSITION_CONTAINED_BY = 0x10;

  static final int DOCUMENT_POSITION_CONTAINS = 0x08;

  static final int DOCUMENT_POSITION_DISCONNECTED = 0x01;

  static final int DOCUMENT_POSITION_FOLLOWING = 0x04;

  static final int DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;

  static final int DOCUMENT_POSITION_PRECEDING = 0x02;

  static final int DOCUMENT_TYPE_NODE = 10;

  static final int ELEMENT_NODE = 1;

  static final int ENTITY_NODE = 6;

  static final int ENTITY_REFERENCE_NODE = 5;

  static final int NOTATION_NODE = 12;

  static final int PROCESSING_INSTRUCTION_NODE = 7;

  static final int TEXT_NODE = 3;

  _NamedNodeMapImpl get _attributes() native "return this.attributes;";

  _NodeListImpl get _childNodes() native "return this.childNodes;";

  _NodeImpl get nextNode() native "return this.nextSibling;";

  _DocumentImpl get document() => _FixHtmlDocumentReference(_document);

  _EventTargetImpl get _document() native "return this.ownerDocument;";

  _NodeImpl get parent() native "return this.parentNode;";

  _NodeImpl get previousNode() native "return this.previousSibling;";

  String get text() native "return this.textContent;";

  void set text(String value) native "this.textContent = value;";

  _NodeImpl _appendChild(_NodeImpl newChild) native "return this.appendChild(newChild);";

  _NodeImpl clone(bool deep) native "return this.cloneNode(deep);";

  bool contains(_NodeImpl other) native;

  bool hasChildNodes() native;

  _NodeImpl insertBefore(_NodeImpl newChild, _NodeImpl refChild) native;

  _NodeImpl _removeChild(_NodeImpl oldChild) native "return this.removeChild(oldChild);";

  _NodeImpl _replaceChild(_NodeImpl newChild, _NodeImpl oldChild) native "return this.replaceChild(newChild, oldChild);";

}
