// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.decoration;

import 'dart:html';

class Decoration {
  final String color;
  final bool bold;
  final bool italic;
  final bool stress;
  final bool important;

  const Decoration({this.color: '#000000',
                    this.bold: false,
                    this.italic: false,
                    this.stress: false,
                    this.important: false});

  Element applyTo(text) {
    if (text is String) {
      text = new Text(text);
    }
    if (bold) {
      text = new Element.tag('b')..append(text);
    }
    if (italic) {
      text = new Element.tag('i')..append(text);
    }
    if (stress) {
      text = new Element.tag('em')..append(text);
    }
    if (important) {
      text = new Element.tag('strong')..append(text);
    }
    return new SpanElement()..append(text)..style.color = color;
  }
}

class DiagnosticDecoration extends Decoration {
  final String kind;
  final String message;

  const DiagnosticDecoration(
      this.kind,
      this.message,
      {String color: '#000000',
       bool bold: false,
       bool italic: false,
       bool stress: false,
       bool important: false})
      : super(color: color, bold: bold, italic: italic, stress: stress,
              important: important);

  Element applyTo(text) {
    var element = super.applyTo(text);
    var nodes = new List.from(element.nodes);
    element.nodes.clear();
    var tip = new Text('');
    if (kind == 'error') {
      tip = error(message);
    }
    return element..append(
        new AnchorElement()
            ..classes.add('diagnostic')
            ..nodes.addAll(nodes)
            ..append(tip));
  }
}

info(text) {
  if (text is String) {
    text = new Text(text);
  }
  return new SpanElement()
      ..classes.addAll(['alert', 'alert-info'])
      ..style.opacity = '0.75'
      ..append(text);
}

error(text) {
  if (text is String) {
    text = new Text(text);
  }
  return new SpanElement()
      ..classes.addAll(['alert', 'alert-error'])
      ..style.opacity = '0.75'
      ..append(text);
}

warning(text) {
  if (text is String) {
    text = new Text(text);
  }
  return new SpanElement()
      ..classes.add('alert')
      ..style.opacity = '0.75'
      ..append(text);
}
