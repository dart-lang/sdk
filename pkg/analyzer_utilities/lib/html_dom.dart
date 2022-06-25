// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A lightweight html parser and DOM model.

import 'dart:convert';

// ignore: implementation_imports
import 'package:analyzer/src/manifest/manifest_validator.dart';

const _htmlEscape = HtmlEscape(HtmlEscapeMode.element);

abstract class Node {
  Element? parent;

  final List<Node> nodes = [];
}

class Element extends Node {
  String name;

  Map<String, String> attributes = {};

  List<Element> get children => nodes.whereType<Element>().toList();

  Element.tag(this.name);

  // This is for compatibility with the package:html DOM API.
  String? get localName => name;

  void append(Node child) {
    child.parent = this;
    nodes.add(child);
  }

  List<String> get classes {
    final classes = attributes['class'];
    if (classes != null) {
      return classes.split(' ').toList();
    } else {
      return const [];
    }
  }
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

/// Given HTML text, return a parsed HTML tree.
Document parse(String htmlContents, Uri uri) {
  final RegExp commentRegex = RegExp(r'<!--[^>]+-->');

  Element createElement(XmlElement xmlElement) {
    // element
    var element = Element.tag(xmlElement.name);

    // attributes
    for (var key in xmlElement.attributes.keys) {
      element.attributes[key] = xmlElement.attributes[key]!.value;
    }

    // From the immediate children, determine where the text between the tags is
    // report any such non empty text as Text nodes.
    var text = xmlElement.sourceSpan?.text ?? '';

    if (!text.endsWith('/>')) {
      var indices = <int>[];
      var offset = xmlElement.sourceSpan!.start.offset;

      indices.add(text.indexOf('>') + 1);
      for (var child in xmlElement.children) {
        var childSpan = child.sourceSpan!;
        indices.add(childSpan.start.offset - offset);
        indices.add(childSpan.end.offset - offset);
      }
      indices.add(text.lastIndexOf('<'));

      var textNodes = <Text>[];
      for (var index = 0; index < indices.length; index += 2) {
        var start = indices[index];
        var end = indices[index + 1];
        // Remove html comments (<!--  -->) from text.
        textNodes.add(
          Text(text.substring(start, end).replaceAll(commentRegex, '')),
        );
      }

      element.append(textNodes.removeAt(0));

      for (var child in xmlElement.children) {
        element.append(createElement(child));
        element.append(textNodes.removeAt(0));
      }

      element.nodes.removeWhere((node) => node is Text && node.text.isEmpty);
    }

    return element;
  }

  var parser = ManifestParser.general(htmlContents, uri: uri);
  var result = parser.parseXmlTag();

  while (result.parseResult != ParseTagResult.eof.parseResult) {
    if (result.element != null) {
      var document = Document();
      document.append(createElement(result.element!));
      return document;
    }

    result = parser.parseXmlTag();
  }

  throw 'parse error - element not found';
}
