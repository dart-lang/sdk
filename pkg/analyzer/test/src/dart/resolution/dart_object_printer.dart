// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/dart/constant/value.dart';

/// Prints [DartObjectImpl] as a tree, with values and fields.
class DartObjectPrinter {
  final StringBuffer sink;

  DartObjectPrinter(this.sink);

  void write(DartObjectImpl? object, String indent) {
    if (object != null) {
      var type = object.type;
      if (type.isDartCoreDouble) {
        sink.write('double ');
        sink.writeln(object.toDoubleValue());
      } else if (type.isDartCoreInt) {
        sink.write('int ');
        sink.writeln(object.toIntValue());
      } else if (type.isDartCoreString) {
        sink.write('String ');
        sink.writeln(object.toStringValue());
      } else if (object.isUserDefinedObject) {
        var newIndent = '$indent  ';
        var typeStr = type.getDisplayString(withNullability: true);
        sink.writeln(typeStr);
        var fields = object.fields;
        if (fields != null) {
          var sortedFields = SplayTreeMap.of(fields);
          for (var entry in sortedFields.entries) {
            sink.write(newIndent);
            sink.write('${entry.key}: ');
            write(entry.value, newIndent);
          }
        }
      } else {
        throw UnimplementedError();
      }
    } else {
      sink.writeln('<null>');
    }
  }
}
