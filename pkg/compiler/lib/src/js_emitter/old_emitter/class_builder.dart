// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

/**
 * A data structure for collecting fragments of a class definition.
 */
class ClassBuilder {
  final List<jsAst.Property> properties = <jsAst.Property>[];
  final List<String> fields = <String>[];

  String superName;
  String functionType;
  List<jsAst.Node> fieldMetadata;

  final Element element;
  final Namer namer;

  ClassBuilder(this.element, this.namer);

  jsAst.Property addProperty(String name, jsAst.Expression value) {
    jsAst.Property property = new jsAst.Property(js.string(name), value);
    properties.add(property);
    return property;
  }

  void addField(String field) {
    fields.add(field);
  }

  static String functionTypeEncodingDescription =
      'For simple function types the function type is stored in the metadata '
      'and the index is encoded into the superclass field.';

  static String fieldEncodingDescription =
      'Fields are encoded as a comma separated list. If there is a superclass '
      '(and possibly a function type encoding) the fields are separated from '
      'the superclass by a semicolon.';

  jsAst.ObjectInitializer toObjectInitializer(
      {bool emitClassDescriptor: true}) {
    StringBuffer buffer = new StringBuffer();
    if (superName != null) {
      buffer.write(superName);
      if (functionType != null) {
        // See [functionTypeEncodingDescription] above.
        buffer.write(':$functionType');
      }
      buffer.write(';');
    }
    // See [fieldEncodingDescription] above.
    buffer.writeAll(fields, ',');
    var classData = js.string('$buffer');
    if (fieldMetadata != null) {
      // If we need to store fieldMetadata, classData is turned into an array,
      // and the field metadata is appended. So if classData is just a string,
      // there is no field metadata.
      classData =
          new jsAst.ArrayInitializer([classData]..addAll(fieldMetadata));
    }
    List<jsAst.Property> fieldsAndProperties;
    if (emitClassDescriptor) {
      fieldsAndProperties = <jsAst.Property>[];
      fieldsAndProperties.add(
          new jsAst.Property(
              js.string(namer.classDescriptorProperty), classData));
      fieldsAndProperties.addAll(properties);
    } else {
      fieldsAndProperties = properties;
    }
    return new jsAst.ObjectInitializer(fieldsAndProperties, isOneLiner: false);
  }
}
