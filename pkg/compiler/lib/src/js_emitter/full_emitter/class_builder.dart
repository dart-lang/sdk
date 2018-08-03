// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.full_emitter.class_builder;

import '../../elements/entities.dart';
import '../../js/js.dart' as jsAst;
import '../../js/js.dart' show js;
import '../../js_backend/js_backend.dart' show Namer;

/**
 * A data structure for collecting fragments of a class definition.
 */
class ClassBuilder {
  final List<jsAst.Property> properties = <jsAst.Property>[];
  final List<jsAst.Literal> fields = <jsAst.Literal>[];

  jsAst.Name superName;
  jsAst.Node functionType;
  List<jsAst.Expression> fieldMetadata;

  final Entity element;
  final Namer namer;
  final bool isForActualClass;

  ClassBuilder.forLibrary(LibraryEntity library, this.namer)
      : isForActualClass = false,
        element = library;

  ClassBuilder.forClass(ClassEntity cls, this.namer)
      : isForActualClass = true,
        element = cls;

  ClassBuilder.forStatics(this.element, this.namer) : isForActualClass = false;

  jsAst.Property addProperty(jsAst.Literal name, jsAst.Expression value) {
    jsAst.Property property = new jsAst.Property(js.quoteName(name), value);
    properties.add(property);
    return property;
  }

  jsAst.Property addPropertyByName(String name, jsAst.Expression value) {
    jsAst.Property property = new jsAst.Property(js.string(name), value);
    properties.add(property);
    return property;
  }

  void addField(jsAst.Literal field) {
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
    List<jsAst.Literal> parts = <jsAst.Literal>[];
    if (isForActualClass) {
      if (superName != null) {
        parts.add(superName);
        if (functionType != null) {
          // See [functionTypeEncodingDescription] above.
          parts.add(js.stringPart(':'));
          parts.add(functionType);
        }
      }
      parts.add(js.stringPart(';'));
    }
    // See [fieldEncodingDescription] above.
    parts.addAll(js.joinLiterals(fields, js.stringPart(',')));
    dynamic classData = js.concatenateStrings(parts, addQuotes: true);
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
      fieldsAndProperties.add(new jsAst.Property(
          js.string(namer.classDescriptorProperty), classData));
      fieldsAndProperties.addAll(properties);
    } else {
      fieldsAndProperties = properties;
    }
    return new jsAst.ObjectInitializer(fieldsAndProperties, isOneLiner: false);
  }
}
