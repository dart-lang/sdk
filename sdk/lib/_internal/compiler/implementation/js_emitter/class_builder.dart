// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

/**
 * A data structure for collecting fragments of a class definition.
 */
class ClassBuilder {
  final List<jsAst.Property> properties = <jsAst.Property>[];

  /// Set to true by user if class is indistinguishable from its superclass.
  bool isTrivial = false;

  // Has the same signature as [DefineStubFunction].
  void addProperty(String name, jsAst.Expression value) {
    properties.add(new jsAst.Property(js.string(name), value));
  }

  jsAst.Expression toObjectInitializer() {
    return new jsAst.ObjectInitializer(properties);
  }

  /// This method is temporary. Do not use it unless you're working on
  /// transforming code to build jsAst.Nodes.
  void writeOn_DO_NOT_USE(CodeBuffer buffer,
                          Compiler compiler,
                          String separatedBy) {
    for (jsAst.Property property in properties) {
      if (!buffer.isEmpty) buffer.write(separatedBy);
      buffer.write(jsAst.prettyPrint(property, compiler));
    }
  }
}
