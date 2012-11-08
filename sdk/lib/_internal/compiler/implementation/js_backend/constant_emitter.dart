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
   * The string is assumed quoted by single quote characters.
   */
  void writeEscapedString(DartString string,
                          CodeBuffer buffer,
                          Node diagnosticNode) {
    Iterator<int> iterator = string.iterator();
    while (iterator.hasNext) {
      int code = iterator.next();
      if (identical(code, $SQ)) {
        buffer.add(r"\'");
      } else if (identical(code, $LF)) {
        buffer.add(r'\n');
      } else if (identical(code, $CR)) {
        buffer.add(r'\r');
      } else if (identical(code, $LS)) {
        // This Unicode line terminator and $PS are invalid in JS string
        // literals.
        buffer.add(r'\u2028');
      } else if (identical(code, $PS)) {
        buffer.add(r'\u2029');
      } else if (identical(code, $BACKSLASH)) {
        buffer.add(r'\\');
      } else {
        if (code > 0xffff) {
          compiler.reportError(
              diagnosticNode,
              'Unhandled non-BMP character: U+${code.toRadixString(16)}');
        }
        // TODO(lrn): Consider whether all codes above 0x7f really need to
        // be escaped. We build a Dart string here, so it should be a literal
        // stage that converts it to, e.g., UTF-8 for a JS interpreter.
        if (code < 0x20) {
          buffer.add(r'\x');
          if (code < 0x10) buffer.add('0');
          buffer.add(code.toRadixString(16));
        } else if (code >= 0x80) {
          if (code < 0x100) {
            buffer.add(r'\x');
          } else {
            buffer.add(r'\u');
            if (code < 0x1000) {
              buffer.add('0');
            }
          }
          buffer.add(code.toRadixString(16));
        } else {
          buffer.addCharCode(code);
        }
      }
    }
  }

  void visitString(StringConstant constant) {
    buffer.add("'");
    writeEscapedString(constant.value, buffer, constant.node);
    buffer.add("'");
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
