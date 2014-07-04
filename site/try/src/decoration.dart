// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.decoration;

import 'dart:html';

import 'shadow_root.dart' show
    setShadowRoot;

import 'editor.dart' show
    diagnostic;

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
    return element..append(diagnostic(nodes, tip));
  }
}

createAlert(text, [String cls]) {
  var classes = ['alert'];
  if (cls != null) {
    classes.add(cls);
  }
  SpanElement result = new SpanElement()
      ..classes.addAll(classes)
      ..style.fontWeight = 'normal';
  setShadowRoot(result, text);
  return result;
}

info(text) => createAlert(text, 'alert-info');

error(text) => createAlert(text, 'alert-error');

warning(text) => createAlert(text);

class CodeCompletionDecoration extends Decoration {
  const CodeCompletionDecoration(
      {String color: '#000000',
       bool bold: false,
       bool italic: false,
       bool stress: false,
       bool important: false})
      : super(color: color, bold: bold, italic: italic, stress: stress,
              important: important);

  static from(Decoration decoration) {
    return new CodeCompletionDecoration(
        color: decoration.color,
        bold: decoration.bold,
        italic: decoration.italic,
        stress: decoration.stress,
        important: decoration.important);
  }

  Element applyTo(text) {
    var codeCompletion = new DivElement()
        ..contentEditable = 'false'
        ..classes.add('dart-code-completion');
    return super.applyTo(text)
        ..classes.add('dart-code-completion-holder')
        ..nodes.add(codeCompletion);
  }
}
