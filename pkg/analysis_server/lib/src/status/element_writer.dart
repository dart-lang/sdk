// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.status.element_writer;

import 'package:analysis_server/src/status/utilities.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A visitor that will produce an HTML representation of an element structure.
 */
class ElementWriter extends GeneralizingElementVisitor {
  /**
   * The buffer on which the HTML is to be written.
   */
  final StringBuffer buffer;

  /**
   * The current level of indentation.
   */
  int indentLevel = 0;

  /**
   * Initialize a newly created element writer to write the HTML representation
   * of visited elements on the given [buffer].
   */
  ElementWriter(this.buffer);

  @override
  void visitElement(Element element) {
    for (int i = 0; i < indentLevel; i++) {
      buffer.write('&#x250A;&nbsp;&nbsp;&nbsp;');
    }
    if (element.isSynthetic) {
      buffer.write('<i>');
    }
    buffer.write(encodeHtml(element.toString()));
    if (element.isSynthetic) {
      buffer.write('</i>');
    }
    buffer.write(' <span style="color:gray">(');
    buffer.write(element.runtimeType);
    buffer.write(')</span><br>');
    indentLevel++;
    try {
      element.visitChildren(this);
    } finally {
      indentLevel--;
    }
  }
}
