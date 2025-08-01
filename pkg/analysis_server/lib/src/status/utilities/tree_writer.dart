// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Utility methods that can be mixed in to classes that produce an HTML
/// representation of a tree structure.
mixin TreeWriter {
  /// The current level of indentation.
  int indentLevel = 0;

  /// A list containing the exceptions that were caught while attempting to
  /// write out the tree structure.
  List<CaughtException> exceptions = <CaughtException>[];

  /// The buffer on which the HTML is to be written.
  StringBuffer get buffer;

  void indent([int extra = 0]) {
    for (var i = 0; i < indentLevel; i++) {
      buffer.write('&#x250A;&nbsp;&nbsp;&nbsp;');
    }
    if (extra > 0) {
      buffer.write('&#x250A;&nbsp;&nbsp;&nbsp;');
      for (var i = 1; i < extra; i++) {
        buffer.write('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
      }
    }
  }

  /// Write a representation of the given [properties] to the buffer.
  void writeProperties(Map<String, Object?> properties) {
    var propertyNames = properties.keys.toList();
    propertyNames.sort();
    for (var propertyName in propertyNames) {
      writeProperty(propertyName, properties[propertyName]);
    }
  }

  /// Write the [value] of the property with the given [name].
  void writeProperty(String name, Object? value) {
    if (value != null) {
      indent(2);
      buffer.write('$name = ');
      _writePropertyValue(value, indentLevel);
      buffer.write('<br>');
    }
  }

  String? _toString(Object? value) {
    try {
      if (value is DirectiveUri) {
        if (value is DirectiveUriWithSource) {
          var sourceStr = _toString(value.source);
          return 'DirectiveUriWithSource (source=$sourceStr)';
        }
        return value.toString();
      } else if (value is Source) {
        return 'Source (uri="${value.uri}", path="${value.fullName}")';
      } else if (value is ElementAnnotationImpl) {
        var buffer = StringBuffer();
        buffer.write(_toString(value.element));
        var result = value.evaluationResult;
        switch (result) {
          case null:
            buffer.write(': no result');
          case DartObjectImpl():
            buffer.write(': value = ');
            buffer.write(result);
          case InvalidConstant():
            buffer.write('; errors = ');
            buffer.writeAll(value.constantEvaluationErrors, ', ');
        }
        return buffer.toString();
      } else {
        return value.toString();
      }
    } catch (exception, stackTrace) {
      exceptions.add(CaughtException(exception, stackTrace));
    }
    return null;
  }

  /// Writes the [value] of the property.
  void _writePropertyValue(Object value, int baseIndent) {
    if (value is List<Object>) {
      if (value.isEmpty) {
        buffer.write('[]');
      } else {
        var elementIndent = baseIndent + 2;
        buffer.write('[<br>');
        for (var element in value) {
          indent(elementIndent);
          _writePropertyValue(element, elementIndent);
          buffer.write('<br>');
        }
        indent(baseIndent);
        buffer.write(']');
      }
    } else {
      var valueString = _toString(value);
      if (valueString == null) {
        buffer.write('<span style="color: #FF0000">');
        buffer.write(htmlEscape.convert(value.runtimeType.toString()));
        buffer.write('</span>');
      } else {
        buffer.write(htmlEscape.convert(valueString));
      }
    }
  }
}
