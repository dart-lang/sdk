// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Constant implements Hashable {
  const Constant();

  bool isNull() => false;
  bool isBool() => false;
  bool isTrue() => false;
  bool isFalse() => false;
  bool isInt() => false;
  bool isDouble() => false;
  bool isNum() => false;
  bool isString() => false;
  bool isList() => false;
  bool isMap() => false;
  bool isConstructedObject() => false;
  /** Returns true if the constant is null, a bool, a number or a string. */
  bool isPrimitive() => false;
  /** Returns true if the constant is a list, a map or a constructed object. */
  bool isObject() => false;

  bool isNaN() => false;

  abstract void _writeJsCode(StringBuffer buffer, ConstantHandler handler);
  /**
    * Unless the constant can be emitted multiple times (as for numbers and
    * strings) adds its canonical name to the buffer.
    */
  abstract void _writeCanonicalizedJsCode(StringBuffer buffer,
                                          ConstantHandler handler);
  abstract List<Constant> getDependencies();
}

class PrimitiveConstant extends Constant {
  abstract get value();
  const PrimitiveConstant();
  bool isPrimitive() => true;

  bool operator ==(var other) {
    if (other is !PrimitiveConstant) return false;
    PrimitiveConstant otherPrimitive = other;
    // We use == instead of === so that DartStrings compare correctly.
    return value == otherPrimitive.value;
  }

  String toString() => value.toString();
  // Primitive constants don't have dependencies.
  List<Constant> getDependencies() => const <Constant>[];
  abstract DartString toDartString();

  void _writeCanonicalizedJsCode(StringBuffer buffer, ConstantHandler handler) {
    _writeJsCode(buffer, handler);
  }
}

class NullConstant extends PrimitiveConstant {
  factory NullConstant() => const NullConstant._internal();
  const NullConstant._internal();
  bool isNull() => true;
  get value() => null;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    buffer.add("(void 0)");
  }

  // The magic constant has no meaning. It is just a random value.
  int hashCode() => 785965825;
  DartString toDartString() => const LiteralDartString("null");
}

class NumConstant extends PrimitiveConstant {
  abstract num get value();
  const NumConstant();
  bool isNum() => true;
}

class IntConstant extends NumConstant {
  final int value;
  factory IntConstant(int value) {
    switch (value) {
      case 0: return const IntConstant._internal(0);
      case 1: return const IntConstant._internal(1);
      case 2: return const IntConstant._internal(2);
      case 3: return const IntConstant._internal(3);
      case 4: return const IntConstant._internal(4);
      case 5: return const IntConstant._internal(5);
      case 6: return const IntConstant._internal(6);
      case 7: return const IntConstant._internal(7);
      case 8: return const IntConstant._internal(8);
      case 9: return const IntConstant._internal(9);
      case 10: return const IntConstant._internal(10);
      case -1: return const IntConstant._internal(-1);
      case -2: return const IntConstant._internal(-2);
      default: return new IntConstant._internal(value);
    }
  }
  const IntConstant._internal(this.value);
  bool isInt() => true;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    buffer.add("$value");
  }

  // We have to override the equality operator so that ints and doubles are
  // treated as separate constants.
  // The is [:!IntConstant:] check at the beginning of the function makes sure
  // that we compare only equal to integer constants.
  bool operator ==(var other) {
    if (other is !IntConstant) return false;
    IntConstant otherInt = other;
    return value == otherInt.value;
  }

  int hashCode() => value.hashCode();
  DartString toDartString() => new DartString.literal(value.toString());
}

class DoubleConstant extends NumConstant {
  final double value;
  factory DoubleConstant(double value) {
    if (value.isNaN()) {
      return const DoubleConstant._internal(double.NAN);
    } else if (value == double.INFINITY) {
      return const DoubleConstant._internal(double.INFINITY);
    } else if (value == -double.INFINITY) {
      return const DoubleConstant._internal(-double.INFINITY);
    } else if (value == 0.0 && !value.isNegative()) {
      return const DoubleConstant._internal(0.0);
    } else if (value == 1.0) {
      return const DoubleConstant._internal(1.0);
    } else {
      return new DoubleConstant._internal(value);
    }
  }
  const DoubleConstant._internal(this.value);
  bool isDouble() => true;
  bool isNaN() => value.isNaN();

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    if (value.isNaN()) {
      buffer.add("(0/0)");
    } else if (value == double.INFINITY) {
      buffer.add("(1/0)");
    } else if (value == -double.INFINITY) {
      buffer.add("(-1/0)");
    } else {
      buffer.add("$value");
    }
  }

  bool operator ==(var other) {
    if (other is !DoubleConstant) return false;
    DoubleConstant otherDouble = other;
    double otherValue = otherDouble.value;
    if (value == 0.0 && otherValue == 0.0) {
      return value.isNegative() == otherValue.isNegative();
    } else if (value.isNaN()) {
      return otherValue.isNaN();
    } else {
      return value == otherValue;
    }
  }

  int hashCode() => value.hashCode();
  DartString toDartString() => new DartString.literal(value.toString());
}

class BoolConstant extends PrimitiveConstant {
  factory BoolConstant(value) {
    return value ? new TrueConstant() : new FalseConstant();
  }
  const BoolConstant._internal();
  bool isBool() => true;

  BoolConstant unaryFold(String op) {
    if (op == "!") return new BoolConstant(!value);
    return null;
  }

  abstract BoolConstant negate();
}

class TrueConstant extends BoolConstant {
  final bool value = true;

  factory TrueConstant() => const TrueConstant._internal();
  const TrueConstant._internal() : super._internal();
  bool isTrue() => true;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    buffer.add("true");
  }

  FalseConstant negate() => new FalseConstant();

  bool operator ==(var other) => this === other;
  // The magic constant is just a random value. It does not have any
  // significance.
  int hashCode() => 499;
  DartString toDartString() => const LiteralDartString("true");
}

class FalseConstant extends BoolConstant {
  final bool value = false;

  factory FalseConstant() => const FalseConstant._internal();
  const FalseConstant._internal() : super._internal();
  bool isFalse() => true;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    buffer.add("false");
  }

  TrueConstant negate() => new TrueConstant();

  bool operator ==(var other) => this === other;
  // The magic constant is just a random value. It does not have any
  // significance.
  int hashCode() => 536555975;
  DartString toDartString() => const LiteralDartString("false");
}

class StringConstant extends PrimitiveConstant {
  final DartString value;
  int _hashCode;
  final Node node;

  StringConstant(this.value, this.node) {
    // TODO(floitsch): cache StringConstants.
    // TODO(floitsch): compute hashcode without calling toString() on the
    // DartString.
    _hashCode = value.slowToString().hashCode();
  }
  bool isString() => true;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    buffer.add("'");
    ConstantHandler.writeEscapedString(value, buffer, (reason) {
      handler.compiler.reportError(node, reason);
    });
    buffer.add("'");
  }

  bool operator ==(var other) {
    if (other is !StringConstant) return false;
    StringConstant otherString = other;
    return (_hashCode == otherString._hashCode) && (value == otherString.value);
  }

  int hashCode() => _hashCode;
  DartString toDartString() => value;
  int get length() => value.length;
}

class ObjectConstant extends Constant {
  final Type type;

  ObjectConstant(this.type);
  bool isObject() => true;

  // TODO(1603): The class should be marked as abstract, but the VM doesn't
  // currently allow this.
  abstract int hashCode();

  void _writeCanonicalizedJsCode(StringBuffer buffer, ConstantHandler handler) {
    String name = handler.getNameForConstant(this);
    buffer.add(handler.compiler.namer.isolatePropertiesAccessForConstant(name));
  }
}

class ListConstant extends ObjectConstant {
  final List<Constant> entries;
  int _hashCode;

  ListConstant(Type type, this.entries) : super(type) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant input in entries) hash ^= input.hashCode();
    _hashCode = hash;
  }
  bool isList() => true;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    // TODO(floitsch): we should not need to go through the compiler to make
    // the list constant.
    buffer.add("${handler.compiler.namer.ISOLATE}.makeConstantList");
    buffer.add("([");
    for (int i = 0; i < entries.length; i++) {
      if (i != 0) buffer.add(", ");
      Constant entry = entries[i];
      handler.writeConstant(buffer, entry);
    }
    buffer.add("])");
  }

  bool operator ==(var other) {
    if (other is !ListConstant) return false;
    ListConstant otherList = other;
    if (hashCode() != otherList.hashCode()) return false;
    // TODO(floitsch): verify that the generic types are the same.
    if (entries.length != otherList.entries.length) return false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i] != otherList.entries[i]) return false;
    }
    return true;
  }

  int hashCode() => _hashCode;

  List<Constant> getDependencies() => entries;

  int get length() => entries.length;
}

class MapConstant extends ObjectConstant {
  /**
   * The [PROTO_PROPERTY] must not be used as normal property in any JavaScript
   * object. It would change the prototype chain.
   */
  static final String PROTO_PROPERTY = "__proto__";

  /** The dart class implementing constant map literals. */
  static final SourceString DART_CLASS = const SourceString("ConstantMap");
  static final SourceString DART_PROTO_CLASS =
      const SourceString("ConstantProtoMap");
  static final SourceString LENGTH_NAME = const SourceString("length");
  static final SourceString JS_OBJECT_NAME = const SourceString("_jsObject");
  static final SourceString KEYS_NAME = const SourceString("_keys");
  static final SourceString PROTO_VALUE = const SourceString("_protoValue");

  final ListConstant keys;
  final List<Constant> values;
  final Constant protoValue;
  int _hashCode;

  MapConstant(Type type, this.keys, this.values, this.protoValue)
      : super(type) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant value in values) hash ^= value.hashCode();
    _hashCode = hash;
  }
  bool isMap() => true;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {

    void writeJsMap() {
      buffer.add("{");
      int valueIndex = 0;
      for (int i = 0; i < keys.entries.length; i++) {
        StringConstant key = keys.entries[i];
        if (key.value == const LiteralDartString(PROTO_PROPERTY)) continue;

        if (valueIndex != 0) buffer.add(", ");

        key._writeJsCode(buffer, handler);
        buffer.add(": ");
        Constant value = values[valueIndex++];
        handler.writeConstant(buffer, value);
      }
      buffer.add("}");
      if (valueIndex != values.length) {
        handler.compiler.internalError("Bad value count.");
      }
    }

    void badFieldCountError() {
      handler.compiler.internalError(
          "Compiler and ConstantMap disagree on number of fields.");
    }

    ClassElement classElement = type.element;
    buffer.add("new ");
    buffer.add(handler.getJsConstructor(classElement));
    buffer.add("(");
    // The arguments of the JavaScript constructor for any given Dart class
    // are in the same order as the members of the class element.
    int emittedArgumentCount = 0;
    classElement.forEachInstanceField(
        includeBackendMembers: true,
        includeSuperMembers: true,
        f: (ClassElement enclosing, Element field) {
      if (emittedArgumentCount != 0) buffer.add(", ");
      if (field.name == LENGTH_NAME) {
        buffer.add(keys.entries.length);
      } else if (field.name == JS_OBJECT_NAME) {
        writeJsMap();
      } else if (field.name == KEYS_NAME) {
        handler.writeConstant(buffer, keys);
      } else if (field.name == PROTO_VALUE) {
        assert(protoValue !== null);
        handler.writeConstant(buffer, protoValue);
      } else {
        badFieldCountError();
      }
      emittedArgumentCount++;
    });
    if ((protoValue === null && emittedArgumentCount != 3) ||
        (protoValue !== null && emittedArgumentCount != 4)) {
      badFieldCountError();
    }
    buffer.add(")");
  }

  bool operator ==(var other) {
    if (other is !MapConstant) return false;
    MapConstant otherMap = other;
    if (hashCode() != otherMap.hashCode()) return false;
    // TODO(floitsch): verify that the generic types are the same.
    if (keys != otherMap.keys) return false;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != otherMap.values[i]) return false;
    }
    return true;
  }

  int hashCode() => _hashCode;

  List<Constant> getDependencies() {
    List<Constant> result = <Constant>[keys];
    result.addAll(values);
    return result;
  }

  int get length() => keys.length;
}

class ConstructedConstant extends ObjectConstant {
  final List<Constant> fields;
  int _hashCode;

  ConstructedConstant(Type type, this.fields) : super(type) {
    assert(type !== null);
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant field in fields) {
      hash ^= field.hashCode();
    }
    hash ^= type.element.hashCode();
    _hashCode = hash;
  }
  bool isConstructedObject() => true;

  void _writeJsCode(StringBuffer buffer, ConstantHandler handler) {
    buffer.add("new ");
    buffer.add(handler.getJsConstructor(type.element));
    buffer.add("(");
    for (int i = 0; i < fields.length; i++) {
      if (i != 0) buffer.add(", ");
      Constant field = fields[i];
      handler.writeConstant(buffer, field);
    }
    buffer.add(")");
  }

  bool operator ==(var otherVar) {
    if (otherVar is !ConstructedConstant) return false;
    ConstructedConstant other = otherVar;
    if (hashCode() != other.hashCode()) return false;
    // TODO(floitsch): verify that the (generic) types are the same.
    if (type.element != other.type.element) return false;
    if (fields.length != other.fields.length) return false;
    for (int i = 0; i < fields.length; i++) {
      if (fields[i] != other.fields[i]) return false;
    }
    return true;
  }

  int hashCode() => _hashCode;
  List<Constant> getDependencies() => fields;
}

/**
 * The [ConstantHandler] keeps track of compile-time constants,
 * initializations of global and static fields, and default values of
 * optional parameters.
 */
class ConstantHandler extends CompilerTask {
  // Contains the initial value of fields. Must contain all static and global
  // initializations of used fields. May contain caches for instance fields.
  final Map<VariableElement, Constant> initialVariableValues;

  // Map from compile-time constants to their JS name.
  final Map<Constant, String> compiledConstants;

  // The set of variable elements that are in the process of being computed.
  final Set<VariableElement> pendingVariables;

  ConstantHandler(Compiler compiler)
      : initialVariableValues = new Map<VariableElement, Dynamic>(),
        compiledConstants = new Map<Constant, String>(),
        pendingVariables = new Set<VariableElement>(),
        super(compiler);
  String get name() => 'ConstantHandler';

  void registerCompileTimeConstant(Constant constant) {
    Function ifAbsentThunk = (() => compiler.namer.getFreshGlobalName("CTC"));
    compiledConstants.putIfAbsent(constant, ifAbsentThunk);
  }

  /**
   * Compiles the initial value of the given field and stores it in an internal
   * map.
   *
   * [WorkItem] must contain a [VariableElement] refering to a global or
   * static field.
   */
  void compileWorkItem(WorkItem work) {
    measure(() {
      assert(work.element.kind == ElementKind.FIELD
             || work.element.kind == ElementKind.PARAMETER
             || work.element.kind == ElementKind.FIELD_PARAMETER);
      VariableElement element = work.element;
      // Shortcut if it has already been compiled.
      if (initialVariableValues.containsKey(element)) return;
      compileVariableWithDefinitions(element, work.resolutionTree);
      assert(pendingVariables.isEmpty());
    });
  }

  Constant compileVariable(VariableElement element) {
    return measure(() {
      if (initialVariableValues.containsKey(element)) {
        Constant result = initialVariableValues[element];
        return result;
      }
      TreeElements definitions = compiler.analyzeElement(element);
      Constant constant = compileVariableWithDefinitions(element, definitions);
      return constant;
    });
  }

  Constant compileVariableWithDefinitions(VariableElement element,
                                          TreeElements definitions) {
    return measure(() {
      Node node = element.parseNode(compiler);
      if (pendingVariables.contains(element)) {
        MessageKind kind = MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS;
        compiler.reportError(node,
                             new CompileTimeConstantError(kind, const []));
      }
      pendingVariables.add(element);

      SendSet assignment = node.asSendSet();
      Constant value;
      if (assignment === null) {
        // No initial value.
        value = new NullConstant();
      } else {
        Node right = assignment.arguments.head;
        value = compileNodeWithDefinitions(right, definitions);
      }
      initialVariableValues[element] = value;
      pendingVariables.remove(element);
      return value;
    });
  }

  Constant compileNodeWithDefinitions(Node node, TreeElements definitions) {
    return measure(() {
      assert(node !== null);
      CompileTimeConstantEvaluator evaluator =
          new CompileTimeConstantEvaluator(definitions, compiler);
      return evaluator.evaluate(node);
    });
  }

  /** Attempts to compile a constant expression. Returns null if not possible */
  Constant tryCompileNodeWithDefinitions(Node node, TreeElements definitions) {
    return measure(() {
      assert(node !== null);
      try {
        TryCompileTimeConstantEvaluator evaluator =
            new TryCompileTimeConstantEvaluator(definitions, compiler);
        return evaluator.evaluate(node);
      } catch (CompileTimeConstantError exn) {
        return null;
      }
    });
  }

  /**
   * Returns a [List] of static non final fields that need to be initialized.
   * The list must be evaluated in order since the fields might depend on each
   * other.
   */
  List<VariableElement> getStaticNonFinalFieldsForEmission() {
    return initialVariableValues.getKeys().filter((element) {
      return element.kind == ElementKind.FIELD
          && !element.isInstanceMember()
          && !element.modifiers.isFinal();
    });
  }

  /**
   * Returns a [List] of static final fields that need to be initialized. The
   * list must be evaluated in order since the fields might depend on each
   * other.
   */
  List<VariableElement> getStaticFinalFieldsForEmission() {
    return initialVariableValues.getKeys().filter((element) {
      return element.kind == ElementKind.FIELD
          && !element.isInstanceMember()
          && element.modifiers.isFinal();
    });
  }

  List<Constant> getConstantsForEmission() {
    // We must emit dependencies before their uses.
    Set<Constant> seenConstants = new Set<Constant>();
    List<Constant> result = new List<Constant>();

    void addConstant(Constant constant) {
      if (!seenConstants.contains(constant)) {
        constant.getDependencies().forEach(addConstant);
        assert(!seenConstants.contains(constant));
        result.add(constant);
        seenConstants.add(constant);
      }
    }

    compiledConstants.forEach((Constant key, ignored) => addConstant(key));
    return result;
  }

  String getNameForConstant(Constant constant) {
    return compiledConstants[constant];
  }

  /** This function writes the constant in non-canonicalized form. */
  StringBuffer writeJsCode(StringBuffer buffer, Constant value) {
    value._writeJsCode(buffer, this);
    return buffer;
  }

  StringBuffer writeConstant(StringBuffer buffer, Constant value) {
    value._writeCanonicalizedJsCode(buffer, this);
    return buffer;
  }

  StringBuffer writeJsCodeForVariable(StringBuffer buffer,
                                      VariableElement element) {
    if (!initialVariableValues.containsKey(element)) {
      compiler.internalError("No initial value for given element",
                             element: element);
    }
    Constant constant = initialVariableValues[element];
    writeConstant(buffer, constant);
    return buffer;
  }

  /**
   * Write the contents of the quoted string to a [StringBuffer] in
   * a form that is valid as JavaScript string literal content.
   * The string is assumed quoted by single quote characters.
   */
  static void writeEscapedString(DartString string,
                                 StringBuffer buffer,
                                 void cancel(String reason)) {
    Iterator<int> iterator = string.iterator();
    while (iterator.hasNext()) {
      int code = iterator.next();
      if (code === $SQ) {
        buffer.add(@"\'");
      } else if (code === $LF) {
        buffer.add(@'\n');
      } else if (code === $CR) {
        buffer.add(@'\r');
      } else if (code === $LS) {
        // This Unicode line terminator and $PS are invalid in JS string
        // literals.
        buffer.add(@'\u2028');
      } else if (code === $PS) {
        buffer.add(@'\u2029');
      } else if (code === $BACKSLASH) {
        buffer.add(@'\\');
      } else {
        if (code > 0xffff) {
          cancel('Unhandled non-BMP character: U+${code.toRadixString(16)}');
        }
        // TODO(lrn): Consider whether all codes above 0x7f really need to
        // be escaped. We build a Dart string here, so it should be a literal
        // stage that converts it to, e.g., UTF-8 for a JS interpreter.
        if (code < 0x20) {
          buffer.add(@'\x');
          if (code < 0x10) buffer.add('0');
          buffer.add(code.toRadixString(16));
        } else if (code >= 0x80) {
          if (code < 0x100) {
            buffer.add(@'\x');
          } else {
            buffer.add(@'\u');
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

  String getJsConstructor(ClassElement element) {
    return compiler.namer.isolatePropertiesAccess(element);
  }
}

class CompileTimeConstantEvaluator extends AbstractVisitor {
  final TreeElements elements;
  final Compiler compiler;

  CompileTimeConstantEvaluator(this.elements, this.compiler);

  Constant evaluate(Node node) {
    return node.accept(this);
  }

  visitNode(Node node) {
    error(node);
  }

  Constant visitLiteralBool(LiteralBool node) {
    return new BoolConstant(node.value);
  }

  Constant visitLiteralDouble(LiteralDouble node) {
    return new DoubleConstant(node.value);
  }

  Constant visitLiteralInt(LiteralInt node) {
    return new IntConstant(node.value);
  }

  Constant visitLiteralList(LiteralList node) {
    if (!node.isConst()) error(node);
    List<Constant> arguments = <Constant>[];
    for (Link<Node> link = node.elements.nodes;
         !link.isEmpty();
         link = link.tail) {
      arguments.add(evaluate(link.head));
    }
    // TODO(floitsch): get type from somewhere.
    Type type = null;
    Constant constant = new ListConstant(type, arguments);
    compiler.constantHandler.registerCompileTimeConstant(constant);
    return constant;
  }

  Constant visitLiteralMap(LiteralMap node) {
    if (!node.isConst()) error(node);
    List<StringConstant> keys = <StringConstant>[];
    Map<StringConstant, Constant> map = new Map<StringConstant, Constant>();
    for (Link<Node> link = node.entries.nodes;
         !link.isEmpty();
         link = link.tail) {
      LiteralMapEntry entry = link.head;
      Constant key = evaluate(entry.key);
      if (!key.isString() || entry.key.asStringNode() === null) {
        MessageKind kind = MessageKind.KEY_NOT_A_STRING_LITERAL;
        compiler.reportError(entry.key, new ResolutionError(kind, const []));
      }
      StringConstant keyConstant = key;
      if (!map.containsKey(key)) keys.add(key);
      map[key] = evaluate(entry.value);
    }
    List<Constant> values = <Constant>[];
    Constant protoValue = null;
    for (StringConstant key in keys) {
      if (key.value == const LiteralDartString(MapConstant.PROTO_PROPERTY)) {
        protoValue = map[key];
      } else {
        values.add(map[key]);
      }
    }
    bool hasProtoKey = (protoValue !== null);
    // TODO(floitsch): this should be a List<String> type.
    Type keysType = null;
    ListConstant keysList = new ListConstant(keysType, keys);
    compiler.constantHandler.registerCompileTimeConstant(keysList);
    SourceString className = hasProtoKey
                             ? MapConstant.DART_PROTO_CLASS
                             : MapConstant.DART_CLASS;
    ClassElement classElement = compiler.jsHelperLibrary.find(className);
    classElement.ensureResolved(compiler);
    // TODO(floitsch): copy over the generic type.
    Type type = new InterfaceType(classElement);
    compiler.registerInstantiatedClass(classElement);
    Constant constant = new MapConstant(type, keysList, values, protoValue);
    compiler.constantHandler.registerCompileTimeConstant(constant);
    return constant;
  }

  Constant visitLiteralNull(LiteralNull node) {
    return new NullConstant();
  }

  Constant visitLiteralString(LiteralString node) {
    return new StringConstant(node.dartString, node);
  }

  Constant visitStringJuxtaposition(StringJuxtaposition node) {
    StringConstant left = evaluate(node.first);
    StringConstant right = evaluate(node.second);
    return new StringConstant(new DartString.concat(left.value, right.value),
                              node);
  }

  Constant visitStringInterpolation(StringInterpolation node) {
    StringConstant initialString = evaluate(node.string);
    DartString accumulator = initialString.value;
    for (StringInterpolationPart part in node.parts) {
      Constant expression = evaluate(part.expression);
      DartString expressionString;
      if (expression.isNum() || expression.isBool()) {
        PrimitiveConstant primitive = expression;
        expressionString = new DartString.literal(primitive.value.toString());
      } else if (expression.isString()) {
        PrimitiveConstant primitive = expression;
        expressionString = primitive.value;
      } else {
        error(part.expression);
      }
      accumulator = new DartString.concat(accumulator, expressionString);
      StringConstant partString = evaluate(part.string);
      accumulator = new DartString.concat(accumulator, partString.value);
    };
    return new StringConstant(accumulator, node);
  }

  // TODO(floitsch): provide better error-messages.
  Constant visitSend(Send send) {
    Element element = elements[send];
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.modifiers === null ||
          !element.modifiers.isFinal()) {
        error(send);
      }
      return compiler.compileVariable(element);
    } else if (send.isPrefix) {
      assert(send.isOperator);
      Constant receiverConstant = evaluate(send.receiver);
      Operator op = send.selector;
      Constant folded;
      switch (op.source.stringValue) {
        case "!":
          folded = const NotOperation().fold(receiverConstant);
          break;
        case "-":
          folded = const NegateOperation().fold(receiverConstant);
          break;
        case "~":
          folded = const BitNotOperation().fold(receiverConstant);
          break;
        default:
          compiler.internalError("Unexpected operator.", node: op);
          break;
      }
      if (folded === null) error(send);
      return folded;
    } else if (send.isOperator && !send.isPostfix) {
      assert(send.argumentCount() == 1);
      Constant left = evaluate(send.receiver);
      Constant right = evaluate(send.argumentsNode.nodes.head);
      Operator op = send.selector.asOperator();
      Constant folded = null;
      switch (op.source.stringValue) {
        case "+":
          folded = const AddOperation().fold(left, right);
          break;
        case "-":
          folded = const SubtractOperation().fold(left, right);
          break;
        case "*":
          folded = const MultiplyOperation().fold(left, right);
          break;
        case "/":
          folded = const DivideOperation().fold(left, right);
          break;
        case "%":
          folded = const ModuloOperation().fold(left, right);
          break;
        case "~/":
          folded = const TruncatingDivideOperation().fold(left, right);
          break;
        case "|":
          folded = const BitOrOperation().fold(left, right);
          break;
        case "&":
          folded = const BitAndOperation().fold(left, right);
          break;
        case "^":
          folded = const BitXorOperation().fold(left, right);
          break;
        case "||":
          folded = const BooleanOr().fold(left, right);
          break;
        case "&&":
          folded = const BooleanAnd().fold(left, right);
          break;
        case "<<":
          folded = const ShiftLeftOperation().fold(left, right);
          break;
        case ">>":
          folded = const ShiftRightOperation().fold(left, right);
          break;
        case "<":
          folded = const LessOperation().fold(left, right);
          break;
        case "<=":
          folded = const LessEqualOperation().fold(left, right);
          break;
        case ">":
          folded = const GreaterOperation().fold(left, right);
          break;
        case ">=":
          folded = const GreaterEqualOperation().fold(left, right);
          break;
        case "==":
          if (left.isPrimitive() && right.isPrimitive()) {
            folded = const EqualsOperation().fold(left, right);
          }
          break;
        case "===":
          if (left.isPrimitive() && right.isPrimitive()) {
            folded = const IdentityOperation().fold(left, right);
          }
          break;
        case "!=":
          if (left.isPrimitive() && right.isPrimitive()) {
            BoolConstant areEquals = const EqualsOperation().fold(left, right);
            if (areEquals === null) {
              folded = null;
            } else {
              folded = areEquals.negate();
            }
          }
          break;
        case "!==":
          if (left.isPrimitive() && right.isPrimitive()) {
            BoolConstant areIdentical =
                const IdentityOperation().fold(left, right);
            if (areIdentical === null) {
              folded = null;
            } else {
              folded = areIdentical.negate();
            }
          }
          break;
      }
      if (folded === null) error(send);
      return folded;
    }
    return super.visitSend(send);
  }

  visitSendSet(SendSet node) {
    error(node);
  }

  /** Returns the list of constants that are passed to the static function. */
  List<Constant> evaluateArgumentsToConstructor(Selector selector,
                                                Link<Node> arguments,
                                                FunctionElement target) {
    List<Constant> compiledArguments = <Constant>[];

    Function compileArgument = evaluate;
    Function compileConstant = compiler.compileVariable;
    bool succeeded = selector.addArgumentsToList(arguments,
                                                 compiledArguments,
                                                 target,
                                                 compileArgument,
                                                 compileConstant,
                                                 compiler);
    assert(succeeded);
    return compiledArguments;
  }

  Constant visitNewExpression(NewExpression node) {
    if (!node.isConst()) error(node);

    Send send = node.send;
    FunctionElement constructor = elements[send];
    ClassElement classElement = constructor.enclosingElement;
    if (classElement.isInterface()) {
      compiler.resolver.resolveMethodElement(constructor);
      constructor = constructor.defaultImplementation;
      classElement = constructor.enclosingElement;
    }

    Selector selector = elements.getSelector(send);
    List<Constant> arguments =
        evaluateArgumentsToConstructor(selector, send.arguments, constructor);
    ConstructorEvaluator evaluator =
        new ConstructorEvaluator(constructor, compiler);
    evaluator.evaluateConstructorFieldValues(arguments);
    List<Constant> jsNewArguments = evaluator.buildJsNewArguments(classElement);

    compiler.registerInstantiatedClass(classElement);
    // TODO(floitsch): take generic types into account.
    Type type = classElement.computeType(compiler);
    Constant constant = new ConstructedConstant(type, jsNewArguments);
    compiler.constantHandler.registerCompileTimeConstant(constant);
    return constant;
  }

  Constant visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  error(Node node) {
    // TODO(floitsch): get the list of constants that are currently compiled
    // and present some kind of stack-trace.
    MessageKind kind = MessageKind.NOT_A_COMPILE_TIME_CONSTANT;
    compiler.reportError(node, new CompileTimeConstantError(kind, const []));
  }
}

class TryCompileTimeConstantEvaluator extends CompileTimeConstantEvaluator {
  TryCompileTimeConstantEvaluator(TreeElements elements, Compiler compiler):
      super(elements, compiler);

  error(Node node) {
    // Just fail without reporting it anywhere.
    throw new CompileTimeConstantError(
        MessageKind.NOT_A_COMPILE_TIME_CONSTANT, const []);
  }
}

class ConstructorEvaluator extends CompileTimeConstantEvaluator {
  FunctionElement constructor;
  final Map<Element, Constant> definitions;
  final Map<Element, Constant> fieldValues;

  ConstructorEvaluator(FunctionElement constructor, Compiler compiler)
      : this.constructor = constructor,
        this.definitions = new Map<Element, Constant>(),
        this.fieldValues = new Map<Element, Constant>(),
        super(compiler.resolver.resolveMethodElement(constructor),
              compiler);

  Constant visitSend(Send send) {
    Element element = elements[send];
    if (Elements.isLocal(element)) {
      Constant constant = definitions[element];
      if (constant === null) {
        compiler.internalError("Local variable without value", node: send);
      }
      return constant;
    }
    return super.visitSend(send);
  }

  /**
   * Given the arguments (a list of constants) assigns them to the parameters,
   * updating the definitions map. If the constructor has field-initializer
   * parameters (like [:this.x:]), also updates the [fieldValues] map.
   */
  void assignArgumentsToParameters(List<Constant> arguments) {
    // Assign arguments to parameters.
    FunctionSignature parameters = constructor.computeSignature(compiler);
    int index = 0;
    parameters.forEachParameter((Element parameter) {
      Constant argument = arguments[index++];
      definitions[parameter] = argument;
      if (parameter.kind == ElementKind.FIELD_PARAMETER) {
        FieldParameterElement fieldParameterElement = parameter;
        fieldValues[fieldParameterElement.fieldElement] = argument;
      }
    });
  }

  void evaluateSuperOrRedirectSend(Selector selector,
                                   Link<Node> arguments,
                                   FunctionElement targetConstructor) {
    List<Constant> compiledArguments =
        evaluateArgumentsToConstructor(selector, arguments, targetConstructor);

    ConstructorEvaluator evaluator =
        new ConstructorEvaluator(targetConstructor, compiler);
    evaluator.evaluateConstructorFieldValues(compiledArguments);
    // Copy over the fieldValues from the super/redirect-constructor.
    evaluator.fieldValues.forEach((key, value) => fieldValues[key] = value);
  }

  /**
   * Runs through the initializers of the given [constructor] and updates
   * the [fieldValues] map.
   */
  void evaluateConstructorInitializers() {
    FunctionExpression functionNode = constructor.parseNode(compiler);
    NodeList initializerList = functionNode.initializers;

    bool foundSuperOrRedirect = false;

    if (initializerList !== null) {
      for (Link<Node> link = initializerList.nodes;
           !link.isEmpty();
           link = link.tail) {
        assert(link.head is Send);
        if (link.head is !SendSet) {
          // A super initializer or constructor redirection.
          Send call = link.head;
          FunctionElement targetConstructor = elements[call];
          Selector selector = elements.getSelector(call);
          Link<Node> arguments = call.arguments;
          evaluateSuperOrRedirectSend(selector, arguments, targetConstructor);
          foundSuperOrRedirect = true;
        } else {
          // A field initializer.
          SendSet init = link.head;
          Link<Node> initArguments = init.arguments;
          assert(!initArguments.isEmpty() && initArguments.tail.isEmpty());
          Constant fieldValue = evaluate(initArguments.head);
          fieldValues[elements[init]] = fieldValue;
        }
      }
    }

    if (!foundSuperOrRedirect) {
      // No super initializer found. Try to find the default constructor if
      // the class is not Object.
      ClassElement enclosingClass = constructor.enclosingElement;
      ClassElement superClass = enclosingClass.superclass;
      if (enclosingClass != compiler.objectClass) {
        assert(superClass !== null);
        assert(superClass.isResolved);
        FunctionElement targetConstructor =
            superClass.lookupConstructor(superClass.name);
        if (targetConstructor === null) {
          compiler.internalError("no default constructor available",
                                 node: functionNode);
        }

        evaluateSuperOrRedirectSend(Selector.INVOCATION_0,
                                    const EmptyLink<Node>(),
                                    targetConstructor);
      }
    }
  }

  /**
   * Simulates the execution of the [constructor] with the given
   * [arguments] to obtain the field values that need to be passed to the
   * native JavaScript constructor.
   */
  void evaluateConstructorFieldValues(List<Constant> arguments) {
    compiler.withCurrentElement(constructor, () {
      assignArgumentsToParameters(arguments);
      evaluateConstructorInitializers();
    });
  }

  List<Constant> buildJsNewArguments(ClassElement classElement) {
    List<Constant> jsNewArguments = <Constant>[];
    classElement.forEachInstanceField(
        includeBackendMembers: true,
        includeSuperMembers: true,
        f: (ClassElement enclosing, Element field) {
      Constant fieldValue = fieldValues[field];
      if (fieldValue === null) {
        // Use the default value.
        fieldValue = compiler.compileVariable(field);
      }
      jsNewArguments.add(fieldValue);
    });
    return jsNewArguments;
  }
}
