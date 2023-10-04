// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A lightweight HTML parser.
library;

// ignore: implementation_imports
import 'package:analyzer/src/manifest/manifest_validator.dart';

import 'html_dom.dart';

/// Given HTML text, return a parsed HTML tree.
Document parse(String htmlContents, Uri uri) {
  final RegExp commentRegex = RegExp(r'<!--[^>]+-->');

  Element createElement(XmlElement xmlElement) {
    // element
    var element = Element.tag(xmlElement.name);

    // attributes
    for (var MapEntry(:key, value: attribute)
        in xmlElement.attributes.entries) {
      element.attributes[key] = attribute.value;
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
    if (result.element case var element?) {
      var document = Document();
      document.append(createElement(element));
      return document;
    }

    result = parser.parseXmlTag();
  }

  throw 'parse error - element not found';
}
