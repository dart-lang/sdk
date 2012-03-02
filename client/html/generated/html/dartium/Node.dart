// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _NodeImpl extends _EventTargetImpl implements Node {
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

  _NodeImpl._wrap(ptr) : super._wrap(ptr);

  NamedNodeMap get _attributes() => _wrap(_ptr.attributes);

  NodeList get _childNodes() => _wrap(_ptr.childNodes);

  Node get nextNode() => _wrap(_ptr.nextSibling);

  Document get document() => _FixHtmlDocumentReference(_wrap(_ptr.ownerDocument));

  Node get parent() => _wrap(_ptr.parentNode);

  Node get previousNode() => _wrap(_ptr.previousSibling);

  String get text() => _wrap(_ptr.textContent);

  void set text(String value) { _ptr.textContent = _unwrap(value); }

  Node _appendChild(Node newChild) {
    return _wrap(_ptr.appendChild(_unwrap(newChild)));
  }

  Node clone(bool deep) {
    return _wrap(_ptr.cloneNode(_unwrap(deep)));
  }

  bool contains(Node other) {
    return _wrap(_ptr.contains(_unwrap(other)));
  }

  bool hasChildNodes() {
    return _wrap(_ptr.hasChildNodes());
  }

  Node insertBefore(Node newChild, Node refChild) {
    return _wrap(_ptr.insertBefore(_unwrap(newChild), _unwrap(refChild)));
  }

  Node _removeChild(Node oldChild) {
    return _wrap(_ptr.removeChild(_unwrap(oldChild)));
  }

  Node _replaceChild(Node newChild, Node oldChild) {
    return _wrap(_ptr.replaceChild(_unwrap(newChild), _unwrap(oldChild)));
  }

}
