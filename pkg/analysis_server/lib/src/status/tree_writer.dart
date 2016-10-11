// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.status.tree_writer;

import 'dart:convert';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Utility methods that can be mixed in to classes that produce an HTML
 * representation of a tree structure.
 */
abstract class TreeWriter {
  /**
   * The buffer on which the HTML is to be written.
   */
  StringBuffer buffer;

  /**
   * The current level of indentation.
   */
  int indentLevel = 0;

  /**
   * A list containing the exceptions that were caught while attempting to write
   * out the tree structure.
   */
  List<CaughtException> exceptions = <CaughtException>[];

  void indent([int extra = 0]) {
    for (int i = 0; i < indentLevel; i++) {
      buffer.write('&#x250A;&nbsp;&nbsp;&nbsp;');
    }
    if (extra > 0) {
      buffer.write('&#x250A;&nbsp;&nbsp;&nbsp;');
      for (int i = 1; i < extra; i++) {
        buffer.write('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
      }
    }
  }

  /**
   * Write a representation of the given [properties] to the buffer.
   */
  void writeProperties(Map<String, Object> properties) {
    List<String> propertyNames = properties.keys.toList();
    propertyNames.sort();
    for (String propertyName in propertyNames) {
      writeProperty(propertyName, properties[propertyName]);
    }
  }

  /**
   * Write the [value] of the property with the given [name].
   */
  void writeProperty(String name, Object value) {
    if (value != null) {
      indent(2);
      buffer.write('$name = ');
      _writePropertyValue(value, indentLevel);
      buffer.write('<br>');
    }
  }

  String _toString(Object value) {
    try {
      if (value is Source) {
        return 'Source (uri="${value.uri}", path="${value.fullName}")';
      } else if (value is ElementAnnotationImpl) {
        StringBuffer buffer = new StringBuffer();
        buffer.write(_toString(value.element));
        EvaluationResultImpl result = value.evaluationResult;
        if (result == null) {
          buffer.write(': no result');
        } else {
          buffer.write(': value = ');
          buffer.write(result.value);
          buffer.write('; errors = ');
          buffer.write(result.errors);
        }
        return buffer.toString();
      } else {
        return value.toString();
      }
    } catch (exception, stackTrace) {
      exceptions.add(new CaughtException(exception, stackTrace));
    }
    return null;
  }

  /**
   * Write the [value] of the property with the given [name].
   */
  void _writePropertyValue(Object value, int baseIndent) {
    if (value is List) {
      if (value.isEmpty) {
        buffer.write('[]');
      } else {
        int elementIndent = baseIndent + 2;
        buffer.write('[<br>');
        for (Object element in value) {
          indent(elementIndent);
          _writePropertyValue(element, elementIndent);
          buffer.write('<br>');
        }
        indent(baseIndent);
        buffer.write(']');
      }
    } else {
      String valueString = _toString(value);
      if (valueString == null) {
        buffer.write('<span style="color: #FF0000">');
        buffer.write(HTML_ESCAPE.convert(value.runtimeType.toString()));
        buffer.write('</span>');
      } else {
        buffer.write(HTML_ESCAPE.convert(valueString));
      }
    }
  }
}
