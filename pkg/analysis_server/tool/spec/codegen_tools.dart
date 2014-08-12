// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tools for code generation.
 */
library codegen.tools;

import 'package:html5lib/dom.dart' as dom;

import 'text_formatter.dart';
import 'html_tools.dart';

/**
 * Join the given strings using camelCase.  If [capitalize] is true, the first
 * part will be capitalized as well.
 */
String camelJoin(List<String> parts, {bool capitalize: false}) {
  List<String> upcasedParts = <String>[];
  for (int i = 0; i < parts.length; i++) {
    if (i == 0 && !capitalize) {
      upcasedParts.add(parts[i]);
    } else {
      upcasedParts.add(parts[i][0].toUpperCase() + parts[i].substring(1));
    }
  }
  return upcasedParts.join();
}

final RegExp trailingWhitespaceRegExp = new RegExp(r' +$', multiLine: true);

/**
 * Mixin class for generating code.
 */
class CodeGenerator {
  _CodeGeneratorState _state;

  /**
   * Execute [callback], collecting any code that is output using [write]
   * or [writeln], and return the result as a string.
   */
  String collectCode(void callback()) {
    _CodeGeneratorState oldState = _state;
    try {
      _state = new _CodeGeneratorState();
      callback();
      return _state.buffer.toString().replaceAll(trailingWhitespaceRegExp, '');
    } finally {
      _state = oldState;
    }
  }

  /**
   * Output text without ending the current line.
   */
  void write(Object obj) {
    _state.write(obj.toString());
  }

  /**
   * Output text, ending the current line.
   */
  void writeln([Object obj = '']) {
    _state.write('$obj\n');
  }

  /**
   * Execute [callback], indenting any code it outputs by two spaces.
   */
  void indent(void callback()) => indentSpecial('  ', '  ', callback);

  /**
   * Execute [callback], using [additionalIndent] to indent any code it outputs.
   */
  void indentBy(String additionalIndent, void callback()) => indentSpecial(
      additionalIndent, additionalIndent, callback);

  /**
   * Execute [callback], using [additionalIndent] to indent any code it outputs.
   * The first line of output is indented by [firstAdditionalIndent] instead of
   * [additionalIndent].
   */
  void indentSpecial(String firstAdditionalIndent, String additionalIndent, void
      callback()) {
    String oldNextIndent = _state.nextIndent;
    String oldIndent = _state.indent;
    try {
      _state.nextIndent += firstAdditionalIndent;
      _state.indent += additionalIndent;
      callback();
    } finally {
      _state.nextIndent = oldNextIndent;
      _state.indent = oldIndent;
    }
  }

  /**
   * Measure the width of the current indentation level.
   */
  int get indentWidth => _state.nextIndent.length;

  /**
   * Generate a doc comment based on the HTML in [docs].
   *
   * If [javadocStyle] is true, then the output is compatable with Javadoc,
   * which understands certain HTML constructs.
   */
  void docComment(List<dom.Node> docs, {int width: 79, bool javadocStyle: false}) {
    writeln('/**');
    indentBy(' * ', () {
      write(nodesToText(docs, width - _state.indent.length, javadocStyle));
    });
    writeln(' */');
  }

  void outputHeader({bool javaStyle: false}) {
    String header;
    if(javaStyle) {
      header = '''
/*
 * Copyright (c) 2014, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 * 
 * This file has been automatically generated.  Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/spec/generate_files".
 */''';
    }
    else {
      header = '''
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/spec/generate_files".
''';
    }
    writeln(header.trim());
  }
}

/**
 * State used by [CodeGenerator].
 */
class _CodeGeneratorState {
  StringBuffer buffer = new StringBuffer();
  String nextIndent = '';
  String indent = '';
  bool indentNeeded = true;

  void write(String text) {
    List<String> lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (i == lines.length - 1 && lines[i].isEmpty) {
        break;
      }
      if (indentNeeded) {
        buffer.write(nextIndent);
        nextIndent = indent;
      }
      indentNeeded = false;
      buffer.write(lines[i]);
      if (i != lines.length - 1) {
        buffer.writeln();
        indentNeeded = true;
      }
    }
  }
}

/**
 * Mixin class for generating HTML representations of code that are suitable
 * for enclosing inside a <pre> element.
 */
abstract class HtmlCodeGenerator {
  _HtmlCodeGeneratorState _state;

  /**
   * Execute [callback], collecting any code that is output using [write],
   * [writeln], [add], or [addAll], and return the result as a list of DOM
   * nodes.
   */
  List<dom.Node> collectHtml(void callback()) {
    _HtmlCodeGeneratorState oldState = _state;
    try {
      _state = new _HtmlCodeGeneratorState();
      if (callback != null) {
        callback();
      }
      return _state.buffer;
    } finally {
      _state = oldState;
    }
  }

  /**
   * Add the given [node] to the HTML output.
   */
  void add(dom.Node node) {
    _state.add(node);
  }

  /**
   * Add the given [nodes] to the HTML output.
   */
  void addAll(Iterable<dom.Node> nodes) {
    for (dom.Node node in nodes) {
      _state.add(node);
    }
  }

  /**
   * Output text without ending the current line.
   */
  void write(Object obj) {
    _state.write(obj.toString());
  }

  /**
   * Output text, ending the current line.
   */
  void writeln([Object obj = '']) {
    _state.write('$obj\n');
  }

  /**
   * Execute [callback], indenting any code it outputs by two spaces.
   */
  void indent(void callback()) {
    String oldIndent = _state.indent;
    try {
      _state.indent += '  ';
      callback();
    } finally {
      _state.indent = oldIndent;
    }
  }

  /**
   * Execute [callback], wrapping its output in an element with the given
   * [name] and [attributes].
   */
  void element(String name, Map<String, String> attributes, [void callback()]) {
    add(makeElement(name, attributes, collectHtml(callback)));
  }
}

/**
 * State used by [HtmlCodeGenerator].
 */
class _HtmlCodeGeneratorState {
  List<dom.Node> buffer = <dom.Node>[];
  String indent = '';
  bool indentNeeded = true;

  void add(dom.Node node) {
    if (node is dom.Text) {
      write(node.text);
    } else {
      buffer.add(node);
    }
  }

  void write(String text) {
    if (text.isEmpty) {
      return;
    }
    if (indentNeeded) {
      buffer.add(new dom.Text(indent));
    }
    List<String> lines = text.split('\n');
    if (lines.last.isEmpty) {
      lines.removeLast();
      buffer.add(new dom.Text(lines.join('\n$indent') + '\n'));
      indentNeeded = true;
    } else {
      buffer.add(new dom.Text(lines.join('\n$indent')));
      indentNeeded = false;
    }
  }
}
