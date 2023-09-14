// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A lightweight DOM model.
library;

import 'dart:convert';

const _htmlEscape = HtmlEscape(HtmlEscapeMode.element);

class Document extends Element {
  static const Set<String> selfClosing = {
    'br',
    'link',
    'meta',
  };

  Document() : super.tag('');

  /// Return the full HTML text for the document.
  String get outerHtml {
    var buf = StringBuffer();

    void emitNode(Node node) {
      if (node is Element) {
        buf.write('<${node.name}');
        for (var attr in node.attributes.keys) {
          buf.write(' $attr="${node.attributes[attr]}"');
        }
        if (node.nodes.length == 1 &&
            node.nodes.first is Text &&
            !(node.nodes.first as Text).text.contains('\n')) {
          buf.write('>');
          var text = node.nodes.first as Text;
          buf.write(_htmlEscape.convert(text.text));
          buf.write('</${node.name}>');
        } else {
          buf.write('>');
          for (var child in node.nodes) {
            emitNode(child);
          }
          if (!selfClosing.contains(node.name)) {
            buf.write('</${node.name}>');
          }
        }
      } else if (node is Text) {
        buf.write(_htmlEscape.convert(node.text));
      } else {
        throw 'unknown node type: $node';
      }
    }

    buf.write('<!DOCTYPE html>');

    for (var child in nodes) {
      emitNode(child);
    }

    buf.writeln();

    return buf.toString();
  }
}

class Element extends Node {
  final String name;

  Map<String, String> attributes = {};

  Element.tag(this.name);

  List<Element> get children => nodes.whereType<Element>().toList();

  List<String> get classes {
    final classes = attributes['class'];
    if (classes != null) {
      return classes.split(' ').toList();
    } else {
      return const [];
    }
  }

  void append(Node child) {
    child.parent = this;
    nodes.add(child);
  }
}

abstract class Node {
  Element? parent;

  final List<Node> nodes = [];
}

class Text extends Node {
  static final RegExp tagRegex = RegExp(r'<[^>]+>');

  final String text;

  Text(this.text);

  @override
  List<Node> get nodes => const [];

  String get textRemoveTags {
    return text.replaceAll(tagRegex, '');
  }
}
