// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ChildrenNodeList implements NodeList {
  // Raw node.
  final _node;
  final _childNodes;

  _ChildrenNodeList._wrap(var node)
    : _childNodes = node.childNodes,
      _node = node;

  List<Node> _toList() {
    final output = new List(_childNodes.length);
    for (int i = 0, len = _childNodes.length; i < len; i++) {
      output[i] = LevelDom.wrapNode(_childNodes[i]);
    }
    return output;
  }

  Node get first() {
    return LevelDom.wrapNode(_node.firstChild);
  }

  void forEach(void f(Node element)) {
    for (var node in _childNodes) {
      f(LevelDom.wrapNode(node));
    }
  }

  Collection<Node> filter(bool f(Node element)) {
    List<Node> output = new List<Node>();
    forEach((Node element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return output;
  }

  bool every(bool f(Node element)) {
    for(Node element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Node element)) {
    for(Node element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  bool isEmpty() {
    return _node.hasChildNodes();
  }

  int get length() {
    return _childNodes.length;
  }

  Node operator [](int index) {
    return LevelDom.wrapNode(_childNodes[index]);
  }

  void operator []=(int index, Node value) {
    _childNodes[index] = LevelDom.unwrap(value);
  }

   void set length(int newLength) {
     throw new UnsupportedOperationException('');
   }

  Node add(Node value) {
    _node.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Node addLast(Node value) {
    _node.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Iterator<Node> iterator() {
    return _toList().iterator();
  }

  void addAll(Collection<Node> collection) {
    for (Node node in collection) {
      _node.appendChild(LevelDom.unwrap(node));
    }
  }

  void sort(int compare(Node a, Node b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int indexOf(Node element, int startIndex) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int lastIndexOf(Node element, int startIndex) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void clear() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Node removeLast() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Node last() {
    return LevelDom.wrapNode(_node.lastChild);
  }
}

class NodeWrappingImplementation extends EventTargetWrappingImplementation implements Node {
  NodeList _nodes;

  NodeWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  NodeList get nodes() {
    if (_nodes === null) {
      _nodes = new _ChildrenNodeList._wrap(_ptr);
    }
    return _nodes;
  }

  Node get nextNode() => LevelDom.wrapNode(_ptr.nextSibling);

  Document get document() => LevelDom.wrapDocument(_ptr.ownerDocument);

  // TODO(jacobr): should we remove parentElement?
  Element get parentElement() => LevelDom.wrapElement(_ptr.parentElement);

  Node get parent() => LevelDom.wrapNode(_ptr.parentNode);

  Node get previousNode() => LevelDom.wrapNode(_ptr.previousSibling);

  String get text() => _ptr.textContent;

  void set text(String value) { _ptr.textContent = value; }

  // New methods implemented.
  Node replaceWith(Node otherNode) {
    try {
      _ptr.parentNode.replaceChild(LevelDom.unwrap(otherNode), _ptr);
    } catch(var e) {
      // TODO(jacobr): what should we return on failure?
    }
    return this;
  }

  Node remove() {
    // TODO(jacobr): should we throw an exception if parent is already null?
    if (_ptr.parentNode !== null) {
      _ptr.parentNode.removeChild(_ptr);
    }
    return this;
  }

  /**
   * Returns whether the node is attached to a document.
   */
  bool get inDocument() {
    var node = _ptr;
    // TODO(jacobr): is there a faster way to compute this?
    while(node !== null) {
      if (node.nodeType == 9) {
        return true;
      }
      node = node.parentNode;
    }
    return false;
  }

  // TODO(jacobr): implement this.  It is supported by Element.
  bool contains(Node otherNode) {
    if (nodes.length > 0) {
      // TODO(jacobr): implement.
      throw 'Contains not implemented yet for non-leaf and non-element nodes.';
    } else {
      return false;
    }
  }

  // TODO(jacobr): remove when/if List supports a method similar to
  // insertBefore or we switch NodeList to implement LinkedList rather than
  // array.
  Node insertBefore(Node newChild, Node refChild) {
    return LevelDom.wrapNode(_ptr.insertBefore(
        LevelDom.unwrap(newChild), LevelDom.unwrap(refChild)));
  }

  // TODO(jacobr): required for some benchmarks. Added to this class but not Node while
  // we decide what to do with it.
  Node cloneNode(bool deep) {
    return LevelDom.wrapNode(_ptr.cloneNode(deep));
  }
}
