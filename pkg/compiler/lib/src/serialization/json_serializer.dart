// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.json;

import 'dart:convert';

import 'keys.dart';
import 'serialization.dart';
import 'values.dart';

/// Serialization encoder for JSON.
class JsonSerializationEncoder implements SerializationEncoder {
  const JsonSerializationEncoder();

  String encode(ObjectValue objectValue) {
    try {
      return new JsonEncoder.withIndent(' ')
          .convert(const JsonValueEncoder().convert(objectValue));
    } on JsonUnsupportedObjectError catch (e) {
      throw 'Error encoding `${e.unsupportedObject}` '
          '(${e.unsupportedObject.runtimeType})';
    }
  }
}

/// Serialization decoder for JSON.
class JsonSerializationDecoder implements SerializationDecoder {
  const JsonSerializationDecoder();

  Map decode(String text) => JSON.decode(text);

  /// Returns the name of the [key] which used for to store a [Key] into a
  /// [Map]; corresponding to the encoding of object properties in
  /// [JsonValueEncoder.visitObject].
  getObjectPropertyValue(Key key) => key.name;
}

/// A [ValueVisitor] that computes a JSON object value.
class JsonValueEncoder implements ValueVisitor {
  const JsonValueEncoder();

  convert(Value value) => visit(value, null);

  @override
  visit(Value value, [arg]) => value.accept(this, arg);

  @override
  bool visitBool(BoolValue value, arg) => value.value;

  @override
  visitConstant(ConstantValue value, arg) => visit(value.id);

  @override
  visitDouble(DoubleValue value, arg) {
    double d = value.value;
    if (d.isNaN) {
      return 'NaN';
    } else if (d.isInfinite) {
      if (d.isNegative) {
        return '-Infinity';
      } else {
        return 'Infinity';
      }
    }
    return d;
  }

  @override
  visitElement(ElementValue value, arg) => visit(value.id);

  @override
  visitEnum(EnumValue value, arg) => value.value.index;

  @override
  int visitInt(IntValue value, arg) => value.value;

  @override
  List visitList(ListValue value, arg) => value.values.map(visit).toList();

  @override
  Map visitMap(MapValue value, arg) {
    Map<String, dynamic> map = <String, dynamic>{};
    value.map.forEach((String key, Value value) {
      map[key] = visit(value);
    });
    return map;
  }

  @override
  Map visitObject(ObjectValue value, arg) {
    Map<String, dynamic> map = <String, dynamic>{};
    value.map.forEach((Key key, Value value) {
      map[key.name] = visit(value);
    });
    return map;
  }

  @override
  String visitString(StringValue value, arg) => value.value;

  @override
  visitType(TypeValue value, arg) => visit(value.id);

  @override
  visitUri(UriValue value, arg) => '${value.value}';
}

/// [ValueVisitor] that generates a verbose JSON-like output.
class PrettyPrintEncoder implements ValueVisitor<dynamic, String> {
  StringBuffer buffer;

  String toText(Value value) {
    buffer = new StringBuffer();
    visit(value, '');
    String text = buffer.toString();
    buffer = null;
    return text;
  }

  @override
  void visit(Value value, String indentation) {
    value.accept(this, indentation);
  }

  @override
  void visitBool(BoolValue value, String indentation) {
    buffer.write(value.value);
  }

  @override
  void visitConstant(ConstantValue value, String indentation) {
    buffer.write('Constant(${value.id}):${value.constant.toDartText()}');
  }

  @override
  void visitDouble(DoubleValue value, String indentation) {
    buffer.write(value.value);
  }

  @override
  void visitElement(ElementValue value, String indentation) {
    buffer.write('Element(${value.id}):${value.element}');
  }

  @override
  void visitEnum(EnumValue value, String indentation) {
    buffer.write(value.value);
  }

  @override
  void visitInt(IntValue value, String indentation) {
    buffer.write(value.value);
  }

  @override
  void visitList(ListValue value, String indentation) {
    if (value.values.isEmpty) {
      buffer.write('[]');
    } else {
      buffer.write('[');
      bool needsComma = false;
      String nextIndentation = '${indentation}  ';
      for (Value element in value.values) {
        if (needsComma) {
          buffer.write(',');
        }
        buffer.write('\n$nextIndentation');
        visit(element, nextIndentation);
        needsComma = true;
      }
      buffer.write('\n$indentation]');
    }
  }

  @override
  void visitMap(MapValue value, String indentation) {
    if (value.map.isEmpty) {
      buffer.write('{}');
    } else {
      buffer.write('{');
      bool needsComma = false;
      String nextIndentation = '${indentation}  ';
      value.map.forEach((String key, Value subvalue) {
        if (needsComma) {
          buffer.write(',');
        }
        buffer.write('\n$nextIndentation$key: ');
        visit(subvalue, nextIndentation);
        needsComma = true;
      });
      buffer.write('\n$indentation}');
    }
  }

  @override
  void visitObject(ObjectValue value, String indentation) {
    if (value.map.isEmpty) {
      buffer.write('{}');
    } else {
      buffer.write('{');
      bool needsComma = false;
      String nextIndentation = '${indentation}  ';
      value.map.forEach((Key key, Value subvalue) {
        if (needsComma) {
          buffer.write(',');
        }
        buffer.write('\n$nextIndentation$key: ');
        visit(subvalue, nextIndentation);
        needsComma = true;
      });
      buffer.write('\n$indentation}');
    }
  }

  @override
  void visitString(StringValue value, String indentation) {
    buffer.write('"${value.value}"');
  }

  @override
  void visitType(TypeValue value, String indentation) {
    buffer.write('Type(${value.id}):${value.type}');
  }

  @override
  void visitUri(UriValue value, String indentation) {
    buffer.write('Uri(${value.value})');
  }
}
