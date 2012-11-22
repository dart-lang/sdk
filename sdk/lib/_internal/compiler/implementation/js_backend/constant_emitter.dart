// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class ConstantEmitter implements ConstantVisitor {
  final Compiler compiler;
  final Namer namer;

  CodeBuffer buffer;
  bool shouldEmitCanonicalVersion;

  ConstantEmitter(this.compiler, this.namer);

  /**
   * Unless the constant can be emitted multiple times (as for numbers and
   * strings) use the canonical name.
   */
  void emitCanonicalVersionOfConstant(Constant constant, CodeBuffer newBuffer) {
    shouldEmitCanonicalVersion = true;
    buffer = newBuffer;
    _visit(constant);
  }

  /**
   * Emit the JavaScript code of the constant. If the constant must be
   * canonicalized this method emits the initialization value.
   */
  void emitJavaScriptCodeForConstant(Constant constant, CodeBuffer newBuffer) {
    shouldEmitCanonicalVersion = false;
    buffer = newBuffer;
    _visit(constant);
  }

  _visit(Constant constant) {
    constant.accept(this);
  }

  void visitSentinel(SentinelConstant constant) {
    if (shouldEmitCanonicalVersion) {
      buffer.add(namer.CURRENT_ISOLATE);
    } else {
      compiler.internalError(
          "The parameter sentinel constant does not need specific JS code");
    }
  }

  void visitFunction(FunctionConstant constant) {
    if (shouldEmitCanonicalVersion) {
      buffer.add(namer.isolatePropertiesAccess(constant.element));
    } else {
      compiler.internalError(
          "The function constant does not need specific JS code");
    }
  }

  void visitNull(NullConstant constant) {
    buffer.add("null");
  }

  void visitInt(IntConstant constant) {
    buffer.add(constant.value.toString());
  }

  void visitDouble(DoubleConstant constant) {
    double value = constant.value;
    if (value.isNaN) {
      buffer.add("(0/0)");
    } else if (value == double.INFINITY) {
      buffer.add("(1/0)");
    } else if (value == -double.INFINITY) {
      buffer.add("(-1/0)");
    } else {
      buffer.add("$value");
    }
  }

  void visitTrue(TrueConstant constant) {
    buffer.add("true");
  }

  void visitFalse(FalseConstant constant) {
    buffer.add("false");
  }

  /**
   * Write the contents of the quoted string to a [CodeBuffer] in
   * a form that is valid as JavaScript string literal content.
   * The string is assumed quoted by double quote characters.
   */
  void visitString(StringConstant constant) {
    buffer.add('"');
    writeJsonEscapedCharsOn(constant.value.slowToString(), buffer);
    buffer.add('"');
  }

  void emitCanonicalVersion(Constant constant) {
    String name = namer.constantName(constant);
    buffer.add(namer.isolatePropertiesAccessForConstant(name));
  }

  void visitList(ListConstant constant) {
    if (shouldEmitCanonicalVersion) {
      emitCanonicalVersion(constant);
    } else {
      shouldEmitCanonicalVersion = true;
      buffer.add("${namer.ISOLATE}.makeConstantList");
      buffer.add("([");
      for (int i = 0; i < constant.entries.length; i++) {
        if (i != 0) buffer.add(", ");
        _visit(constant.entries[i]);
      }
      buffer.add("])");
    }
  }

  String getJsConstructor(ClassElement element) {
    return namer.isolatePropertiesAccess(element);
  }

  void visitMap(MapConstant constant) {
    if (shouldEmitCanonicalVersion) {
      emitCanonicalVersion(constant);
    } else {
      void writeJsMap() {
        buffer.add("{");
        int valueIndex = 0;
        for (int i = 0; i < constant.keys.entries.length; i++) {
          StringConstant key = constant.keys.entries[i];
          if (key.value == MapConstant.PROTO_PROPERTY) continue;

          if (valueIndex != 0) buffer.add(", ");

          // Keys in literal maps must be emitted in place.
          emitJavaScriptCodeForConstant(key, buffer);

          buffer.add(": ");
          emitCanonicalVersionOfConstant(constant.values[valueIndex++], buffer);
        }
        buffer.add("}");
        if (valueIndex != constant.values.length) {
          compiler.internalError("Bad value count.");
        }
      }

      void badFieldCountError() {
        compiler.internalError(
          "Compiler and ConstantMap disagree on number of fields.");
      }

      shouldEmitCanonicalVersion = true;

      ClassElement classElement = constant.type.element;
      buffer.add("new ");
      buffer.add(getJsConstructor(classElement));
      buffer.add("(");
      // The arguments of the JavaScript constructor for any given Dart class
      // are in the same order as the members of the class element.
      int emittedArgumentCount = 0;
      classElement.implementation.forEachInstanceField(
          (ClassElement enclosing, Element field) {
            if (emittedArgumentCount != 0) buffer.add(", ");
            if (field.name == MapConstant.LENGTH_NAME) {
              buffer.add(constant.keys.entries.length);
            } else if (field.name == MapConstant.JS_OBJECT_NAME) {
              writeJsMap();
            } else if (field.name == MapConstant.KEYS_NAME) {
              emitCanonicalVersionOfConstant(constant.keys, buffer);
            } else if (field.name == MapConstant.PROTO_VALUE) {
              assert(constant.protoValue != null);
              emitCanonicalVersionOfConstant(constant.protoValue, buffer);
            } else {
              badFieldCountError();
            }
            emittedArgumentCount++;
          },
          includeBackendMembers: true,
          includeSuperMembers: true);
      if ((constant.protoValue == null && emittedArgumentCount != 3) ||
          (constant.protoValue != null && emittedArgumentCount != 4)) {
        badFieldCountError();
      }
      buffer.add(")");
    }
  }

  void visitType(TypeConstant constant) {
    if (shouldEmitCanonicalVersion) {
      emitCanonicalVersion(constant);
    } else {
      SourceString helperSourceName =
          const SourceString('createRuntimeType');
      Element helper = compiler.findHelper(helperSourceName);
      JavaScriptBackend backend = compiler.backend;
      String helperName = backend.namer.getName(helper);
      DartType type = constant.representedType;
      Element element = type.element;
      String typeName;
      if (type.kind == TypeKind.INTERFACE) {
        typeName = backend.rti.generateRuntimeTypeString(element, 0);
      } else {
        assert(type.kind == TypeKind.TYPEDEF);
        typeName = element.name.slowToString();
      }
      buffer.add("${namer.CURRENT_ISOLATE}.$helperName('$typeName')");
    }
  }

  void visitConstructed(ConstructedConstant constant) {
    if (shouldEmitCanonicalVersion) {
      emitCanonicalVersion(constant);
    } else {
      shouldEmitCanonicalVersion = true;

      buffer.add("new ");
      buffer.add(getJsConstructor(constant.type.element));
      buffer.add("(");
      for (int i = 0; i < constant.fields.length; i++) {
        if (i != 0) buffer.add(", ");
        _visit(constant.fields[i]);
      }
      buffer.add(")");
    }
  }
}
