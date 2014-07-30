/// Internals to the tree builders.
library treebuilder;

import 'dart:collection';
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart' show getElementNameTuple;
import 'package:source_span/source_span.dart';
import 'constants.dart';
import 'list_proxy.dart';
import 'token.dart';
import 'utils.dart';

// The scope markers are inserted when entering object elements,
// marquees, table cells, and table captions, and are used to prevent formatting
// from "leaking" into tables, object elements, and marquees.
const Node Marker = null;

// TODO(jmesserly): this should extend ListBase<Element>, but my simple attempt
// didn't work.
class ActiveFormattingElements extends ListProxy<Element> {
  ActiveFormattingElements() : super();

  // Override the "add" method.
  // TODO(jmesserly): I'd rather not override this; can we do this in the
  // calling code instead?
  void add(Element node) {
    int equalCount = 0;
    if (node != Marker) {
      for (var element in reversed) {
        if (element == Marker) {
          break;
        }
        if (_nodesEqual(element, node)) {
          equalCount += 1;
        }
        if (equalCount == 3) {
          remove(element);
          break;
        }
      }
    }
    super.add(node);
  }
}

// TODO(jmesserly): this should exist in corelib...
bool _mapEquals(Map a, Map b) {
  if (a.length != b.length) return false;
  if (a.length == 0) return true;

  for (var keyA in a.keys) {
    var valB = b[keyA];
    if (valB == null && !b.containsKey(keyA)) {
      return false;
    }

    if (a[keyA] != valB) {
      return false;
    }
  }
  return true;
}


bool _nodesEqual(Element node1, Element node2) {
  return getElementNameTuple(node1) == getElementNameTuple(node2) &&
      _mapEquals(node1.attributes, node2.attributes);
}

/// Basic treebuilder implementation.
class TreeBuilder {
  final String defaultNamespace;

  Document document;

  final List<Element> openElements = <Element>[];

  final activeFormattingElements = new ActiveFormattingElements();

  Node headPointer;

  Node formPointer;

  /// Switch the function used to insert an element from the
  /// normal one to the misnested table one and back again
  bool insertFromTable;

  TreeBuilder(bool namespaceHTMLElements)
      : defaultNamespace = namespaceHTMLElements ? Namespaces.html : null {
    reset();
  }

  void reset() {
    openElements.clear();
    activeFormattingElements.clear();

    //XXX - rename these to headElement, formElement
    headPointer = null;
    formPointer = null;

    insertFromTable = false;

    document = new Document();
  }

  bool elementInScope(target, {String variant}) {
    //If we pass a node in we match that. if we pass a string
    //match any node with that name
    bool exactNode = target is Node;

    List listElements1 = scopingElements;
    List listElements2 = const [];
    bool invert = false;
    if (variant != null) {
      switch (variant) {
        case "button":
          listElements2 = const [const Pair(Namespaces.html, "button")];
          break;
        case "list":
          listElements2 = const [const Pair(Namespaces.html, "ol"),
                                 const Pair(Namespaces.html, "ul")];
          break;
        case "table":
          listElements1 = const [const Pair(Namespaces.html, "html"),
                                 const Pair(Namespaces.html, "table")];
          break;
        case "select":
          listElements1 = const [const Pair(Namespaces.html, "optgroup"),
                                 const Pair(Namespaces.html, "option")];
          invert = true;
          break;
        default:
          throw new StateError('We should never reach this point');
      }
    }

    for (var node in openElements.reversed) {
      if (!exactNode && node.localName == target ||
          exactNode && node == target) {
        return true;
      } else if (invert !=
          (listElements1.contains(getElementNameTuple(node)) ||
           listElements2.contains(getElementNameTuple(node)))) {
        return false;
      }
    }

    throw new StateError('We should never reach this point');
  }

  void reconstructActiveFormattingElements() {
    // Within this algorithm the order of steps described in the
    // specification is not quite the same as the order of steps in the
    // code. It should still do the same though.

    // Step 1: stop the algorithm when there's nothing to do.
    if (activeFormattingElements.length == 0) {
      return;
    }

    // Step 2 and step 3: we start with the last element. So i is -1.
    int i = activeFormattingElements.length - 1;
    var entry = activeFormattingElements[i];
    if (entry == Marker || openElements.contains(entry)) {
      return;
    }

    // Step 6
    while (entry != Marker && !openElements.contains(entry)) {
      if (i == 0) {
        //This will be reset to 0 below
        i = -1;
        break;
      }
      i -= 1;
      // Step 5: let entry be one earlier in the list.
      entry = activeFormattingElements[i];
    }

    while (true) {
      // Step 7
      i += 1;

      // Step 8
      entry = activeFormattingElements[i];

      // TODO(jmesserly): optimize this. No need to create a token.
      var cloneToken = new StartTagToken(
          entry.localName,
          namespace: entry.namespaceUri,
          data: new LinkedHashMap.from(entry.attributes))
          ..span = entry.sourceSpan;

      // Step 9
      var element = insertElement(cloneToken);

      // Step 10
      activeFormattingElements[i] = element;

      // Step 11
      if (element == activeFormattingElements.last) {
        break;
      }
    }
  }

  void clearActiveFormattingElements() {
    var entry = activeFormattingElements.removeLast();
    while (activeFormattingElements.length > 0 && entry != Marker) {
      entry = activeFormattingElements.removeLast();
    }
  }

  /// Check if an element exists between the end of the active
  /// formatting elements and the last marker. If it does, return it, else
  /// return null.
  Element elementInActiveFormattingElements(String name) {
    for (var item in activeFormattingElements.reversed) {
      // Check for Marker first because if it's a Marker it doesn't have a
      // name attribute.
      if (item == Marker) {
        break;
      } else if (item.localName == name) {
        return item;
      }
    }
    return null;
  }

  void insertRoot(Token token) {
    var element = createElement(token);
    openElements.add(element);
    document.nodes.add(element);
  }

  void insertDoctype(DoctypeToken token) {
    var doctype = new DocumentType(token.name, token.publicId, token.systemId)
        ..sourceSpan = token.span;
    document.nodes.add(doctype);
  }

  void insertComment(StringToken token, [Node parent]) {
    if (parent == null) {
      parent = openElements.last;
    }
    parent.nodes.add(new Comment(token.data)..sourceSpan = token.span);
  }

  /// Create an element but don't insert it anywhere
  Element createElement(StartTagToken token) {
    var name = token.name;
    var namespace = token.namespace;
    if (namespace == null) namespace = defaultNamespace;
    var element = document.createElementNS(namespace, name)
        ..attributes = token.data
        ..sourceSpan = token.span;
    return element;
  }

  Element insertElement(StartTagToken token) {
    if (insertFromTable) return insertElementTable(token);
    return insertElementNormal(token);
  }

  Element insertElementNormal(StartTagToken token) {
    var name = token.name;
    var namespace = token.namespace;
    if (namespace == null) namespace = defaultNamespace;
    var element = document.createElementNS(namespace, name)
        ..attributes = token.data
        ..sourceSpan = token.span;
    openElements.last.nodes.add(element);
    openElements.add(element);
    return element;
  }

  Element insertElementTable(token) {
    /// Create an element and insert it into the tree
    var element = createElement(token);
    if (!tableInsertModeElements.contains(openElements.last.localName)) {
      return insertElementNormal(token);
    } else {
      // We should be in the InTable mode. This means we want to do
      // special magic element rearranging
      var nodePos = getTableMisnestedNodePosition();
      if (nodePos[1] == null) {
        // TODO(jmesserly): I don't think this is reachable. If insertFromTable
        // is true, there will be a <table> element open, and it always has a
        // parent pointer.
        nodePos[0].nodes.add(element);
      } else {
        nodePos[0].insertBefore(element, nodePos[1]);
      }
      openElements.add(element);
    }
    return element;
  }

  /// Insert text data.
  void insertText(String data, FileSpan span) {
    var parent = openElements.last;

    if (!insertFromTable || insertFromTable &&
        !tableInsertModeElements.contains(openElements.last.localName)) {
      _insertText(parent, data, span);
    } else {
      // We should be in the InTable mode. This means we want to do
      // special magic element rearranging
      var nodePos = getTableMisnestedNodePosition();
      _insertText(nodePos[0], data, span, nodePos[1]);
    }
  }

  /// Insert [data] as text in the current node, positioned before the
  /// start of node [refNode] or to the end of the node's text.
  static void _insertText(Node parent, String data, FileSpan span,
      [Element refNode]) {
    var nodes = parent.nodes;
    if (refNode == null) {
      if (nodes.length > 0 && nodes.last is Text) {
        Text last = nodes.last;
        last.data = '${last.data}$data';

        if (span != null) {
          last.sourceSpan = span.file.span(last.sourceSpan.start.offset,
              span.end.offset);
        }
      } else {
        nodes.add(new Text(data)..sourceSpan = span);
      }
    } else {
      int index = nodes.indexOf(refNode);
      if (index > 0 && nodes[index - 1] is Text) {
        Text last = nodes[index - 1];
        last.data = '${last.data}$data';
      } else {
        nodes.insert(index, new Text(data)..sourceSpan = span);
      }
    }
  }

  /// Get the foster parent element, and sibling to insert before
  /// (or null) when inserting a misnested table node
  List<Node> getTableMisnestedNodePosition() {
    // The foster parent element is the one which comes before the most
    // recently opened table element
    // XXX - this is really inelegant
    Node lastTable = null;
    Node fosterParent = null;
    var insertBefore = null;
    for (var elm in openElements.reversed) {
      if (elm.localName == "table") {
        lastTable = elm;
        break;
      }
    }
    if (lastTable != null) {
      // XXX - we should really check that this parent is actually a
      // node here
      if (lastTable.parentNode != null) {
        fosterParent = lastTable.parentNode;
        insertBefore = lastTable;
      } else {
        fosterParent = openElements[openElements.indexOf(lastTable) - 1];
      }
    } else {
      fosterParent = openElements[0];
    }
    return [fosterParent, insertBefore];
  }

  void generateImpliedEndTags([String exclude]) {
    var name = openElements.last.localName;
    // XXX td, th and tr are not actually needed
    if (name != exclude && const ["dd", "dt", "li", "option", "optgroup", "p",
        "rp", "rt"].contains(name)) {
      openElements.removeLast();
      // XXX This is not entirely what the specification says. We should
      // investigate it more closely.
      generateImpliedEndTags(exclude);
    }
  }

  /// Return the final tree.
  Document getDocument() => document;

  /// Return the final fragment.
  DocumentFragment getFragment() {
    //XXX assert innerHTML
    var fragment = new DocumentFragment();
    openElements[0].reparentChildren(fragment);
    return fragment;
  }
}
