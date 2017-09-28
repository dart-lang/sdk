// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.constants;

import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../elements/elements.dart'
    show ConstructorElement, FieldElement, LocalVariableElement, MethodElement;
import '../elements/entities.dart' show FieldEntity;
import '../elements/operators.dart';
import '../elements/resolution_types.dart';
import '../universe/call_structure.dart' show CallStructure;
import 'keys.dart';
import 'serialization.dart';

/// Visitor that serializes a [ConstantExpression] by encoding it into an
/// [ObjectEncoder].
///
/// This class is called from the [Serializer] when a [ConstantExpression] needs
/// serialization. The [ObjectEncoder] ensures that any [Element],
/// [ResolutionDartType], and other [ConstantExpression] that the serialized
/// [ConstantExpression] depends upon are also serialized.
class ConstantSerializer
    extends ConstantExpressionVisitor<dynamic, ObjectEncoder> {
  const ConstantSerializer();

  @override
  void visitBinary(BinaryConstantExpression exp, ObjectEncoder encoder) {
    encoder.setEnum(Key.OPERATOR, exp.operator.kind);
    encoder.setConstant(Key.LEFT, exp.left);
    encoder.setConstant(Key.RIGHT, exp.right);
  }

  @override
  void visitConcatenate(
      ConcatenateConstantExpression exp, ObjectEncoder encoder) {
    encoder.setConstants(Key.ARGUMENTS, exp.expressions);
  }

  @override
  void visitConditional(
      ConditionalConstantExpression exp, ObjectEncoder encoder) {
    encoder.setConstant(Key.CONDITION, exp.condition);
    encoder.setConstant(Key.TRUE, exp.trueExp);
    encoder.setConstant(Key.FALSE, exp.falseExp);
  }

  @override
  void visitConstructed(
      ConstructedConstantExpression exp, ObjectEncoder encoder) {
    ConstructorElement constructor = exp.target;
    ResolutionInterfaceType type = exp.type;
    encoder.setElement(Key.ELEMENT, constructor);
    encoder.setType(Key.TYPE, type);
    encoder.setStrings(Key.NAMES, exp.callStructure.namedArguments);
    encoder.setConstants(Key.ARGUMENTS, exp.arguments);
  }

  @override
  void visitFunction(FunctionConstantExpression exp, ObjectEncoder encoder) {
    MethodElement function = exp.element;
    encoder.setElement(Key.ELEMENT, function);
  }

  @override
  void visitIdentical(IdenticalConstantExpression exp, ObjectEncoder encoder) {
    encoder.setConstant(Key.LEFT, exp.left);
    encoder.setConstant(Key.RIGHT, exp.right);
  }

  @override
  void visitList(ListConstantExpression exp, ObjectEncoder encoder) {
    ResolutionInterfaceType type = exp.type;
    encoder.setType(Key.TYPE, type);
    encoder.setConstants(Key.VALUES, exp.values);
  }

  @override
  void visitMap(MapConstantExpression exp, ObjectEncoder encoder) {
    ResolutionInterfaceType type = exp.type;
    encoder.setType(Key.TYPE, type);
    encoder.setConstants(Key.KEYS, exp.keys);
    encoder.setConstants(Key.VALUES, exp.values);
  }

  @override
  void visitBool(BoolConstantExpression exp, ObjectEncoder encoder) {
    encoder.setBool(Key.VALUE, exp.primitiveValue);
  }

  @override
  void visitInt(IntConstantExpression exp, ObjectEncoder encoder) {
    encoder.setInt(Key.VALUE, exp.primitiveValue);
  }

  @override
  void visitDouble(DoubleConstantExpression exp, ObjectEncoder encoder) {
    encoder.setDouble(Key.VALUE, exp.primitiveValue);
  }

  @override
  void visitString(StringConstantExpression exp, ObjectEncoder encoder) {
    encoder.setString(Key.VALUE, exp.primitiveValue);
  }

  @override
  void visitNull(NullConstantExpression exp, ObjectEncoder encoder) {
    // No additional data needed.
  }

  @override
  void visitSymbol(SymbolConstantExpression exp, ObjectEncoder encoder) {
    encoder.setString(Key.NAME, exp.name);
  }

  @override
  void visitType(TypeConstantExpression exp, ObjectEncoder encoder) {
    encoder.setType(Key.TYPE, exp.type);
    encoder.setString(Key.NAME, exp.name);
  }

  @override
  void visitUnary(UnaryConstantExpression exp, ObjectEncoder encoder) {
    encoder.setEnum(Key.OPERATOR, exp.operator.kind);
    encoder.setConstant(Key.EXPRESSION, exp.expression);
  }

  @override
  void visitField(FieldConstantExpression exp, ObjectEncoder encoder) {
    FieldElement field = exp.element;
    encoder.setElement(Key.ELEMENT, field);
  }

  @override
  void visitLocalVariable(
      LocalVariableConstantExpression exp, ObjectEncoder encoder) {
    LocalVariableElement local = exp.element;
    encoder.setElement(Key.ELEMENT, local);
  }

  @override
  void visitPositional(PositionalArgumentReference exp, ObjectEncoder encoder) {
    encoder.setInt(Key.INDEX, exp.index);
  }

  @override
  void visitNamed(NamedArgumentReference exp, ObjectEncoder encoder) {
    encoder.setString(Key.NAME, exp.name);
  }

  @override
  void visitBoolFromEnvironment(
      BoolFromEnvironmentConstantExpression exp, ObjectEncoder encoder) {
    encoder.setConstant(Key.NAME, exp.name);
    if (exp.defaultValue != null) {
      encoder.setConstant(Key.DEFAULT, exp.defaultValue);
    }
  }

  @override
  void visitIntFromEnvironment(
      IntFromEnvironmentConstantExpression exp, ObjectEncoder encoder) {
    encoder.setConstant(Key.NAME, exp.name);
    if (exp.defaultValue != null) {
      encoder.setConstant(Key.DEFAULT, exp.defaultValue);
    }
  }

  @override
  void visitStringFromEnvironment(
      StringFromEnvironmentConstantExpression exp, ObjectEncoder encoder) {
    encoder.setConstant(Key.NAME, exp.name);
    if (exp.defaultValue != null) {
      encoder.setConstant(Key.DEFAULT, exp.defaultValue);
    }
  }

  @override
  void visitStringLength(
      StringLengthConstantExpression exp, ObjectEncoder encoder) {
    encoder.setConstant(Key.EXPRESSION, exp.expression);
  }

  @override
  void visitDeferred(DeferredConstantExpression exp, ObjectEncoder encoder) {
    encoder.setElement(Key.PREFIX, exp.prefix);
    encoder.setConstant(Key.EXPRESSION, exp.expression);
  }
}

/// Utility class for deserializing [ConstantExpression]s.
///
/// This is used by the [Deserializer].
class ConstantDeserializer {
  /// Deserializes a [ConstantExpression] from an [ObjectDecoder].
  ///
  /// The class is called from the [Deserializer] when a [ConstantExpression]
  /// needs deserialization. The [ObjectDecoder] ensures that any [Element],
  /// [ResolutionDartType], and other [ConstantExpression] that the deserialized
  /// [ConstantExpression] depends upon are available.
  static ConstantExpression deserialize(ObjectDecoder decoder) {
    ConstantExpressionKind kind =
        decoder.getEnum(Key.KIND, ConstantExpressionKind.values);
    switch (kind) {
      case ConstantExpressionKind.BINARY:
        BinaryOperator operator = BinaryOperator
            .fromKind(decoder.getEnum(Key.OPERATOR, BinaryOperatorKind.values));
        return new BinaryConstantExpression(decoder.getConstant(Key.LEFT),
            operator, decoder.getConstant(Key.RIGHT));
      case ConstantExpressionKind.BOOL:
        return new BoolConstantExpression(decoder.getBool(Key.VALUE));
      case ConstantExpressionKind.BOOL_FROM_ENVIRONMENT:
        return new BoolFromEnvironmentConstantExpression(
            decoder.getConstant(Key.NAME),
            decoder.getConstant(Key.DEFAULT, isOptional: true));
      case ConstantExpressionKind.CONCATENATE:
        return new ConcatenateConstantExpression(
            decoder.getConstants(Key.ARGUMENTS));
      case ConstantExpressionKind.CONDITIONAL:
        return new ConditionalConstantExpression(
            decoder.getConstant(Key.CONDITION),
            decoder.getConstant(Key.TRUE),
            decoder.getConstant(Key.FALSE));
      case ConstantExpressionKind.CONSTRUCTED:
        ResolutionInterfaceType type = decoder.getType(Key.TYPE);
        ConstructorElement constructor = decoder.getElement(Key.ELEMENT);
        List<String> names = decoder.getStrings(Key.NAMES, isOptional: true);
        List<ConstantExpression> arguments =
            decoder.getConstants(Key.ARGUMENTS, isOptional: true);
        return new ConstructedConstantExpression(type, constructor,
            new CallStructure(arguments.length, names), arguments);
      case ConstantExpressionKind.DOUBLE:
        return new DoubleConstantExpression(decoder.getDouble(Key.VALUE));
      case ConstantExpressionKind.ERRONEOUS:
        break;
      case ConstantExpressionKind.FUNCTION:
        MethodElement function = decoder.getElement(Key.ELEMENT);
        return new FunctionConstantExpression(function, function.type);
      case ConstantExpressionKind.IDENTICAL:
        return new IdenticalConstantExpression(
            decoder.getConstant(Key.LEFT), decoder.getConstant(Key.RIGHT));
      case ConstantExpressionKind.INT:
        return new IntConstantExpression(decoder.getInt(Key.VALUE));
      case ConstantExpressionKind.INT_FROM_ENVIRONMENT:
        return new IntFromEnvironmentConstantExpression(
            decoder.getConstant(Key.NAME),
            decoder.getConstant(Key.DEFAULT, isOptional: true));
      case ConstantExpressionKind.LIST:
        ResolutionInterfaceType type = decoder.getType(Key.TYPE);
        return new ListConstantExpression(
            type, decoder.getConstants(Key.VALUES, isOptional: true));
      case ConstantExpressionKind.MAP:
        ResolutionInterfaceType type = decoder.getType(Key.TYPE);
        return new MapConstantExpression(
            type,
            decoder.getConstants(Key.KEYS, isOptional: true),
            decoder.getConstants(Key.VALUES, isOptional: true));
      case ConstantExpressionKind.NULL:
        return new NullConstantExpression();
      case ConstantExpressionKind.STRING:
        return new StringConstantExpression(decoder.getString(Key.VALUE));
      case ConstantExpressionKind.STRING_FROM_ENVIRONMENT:
        return new StringFromEnvironmentConstantExpression(
            decoder.getConstant(Key.NAME),
            decoder.getConstant(Key.DEFAULT, isOptional: true));
      case ConstantExpressionKind.STRING_LENGTH:
        return new StringLengthConstantExpression(
            decoder.getConstant(Key.EXPRESSION));
      case ConstantExpressionKind.SYMBOL:
        return new SymbolConstantExpression(decoder.getString(Key.NAME));
      case ConstantExpressionKind.TYPE:
        return new TypeConstantExpression(
            decoder.getType(Key.TYPE), decoder.getString(Key.NAME));
      case ConstantExpressionKind.UNARY:
        UnaryOperator operator = UnaryOperator
            .fromKind(decoder.getEnum(Key.OPERATOR, UnaryOperatorKind.values));
        return new UnaryConstantExpression(
            operator, decoder.getConstant(Key.EXPRESSION));
      case ConstantExpressionKind.FIELD:
        FieldElement field = decoder.getElement(Key.ELEMENT);
        return new FieldConstantExpression(field);
      case ConstantExpressionKind.LOCAL_VARIABLE:
        LocalVariableElement local = decoder.getElement(Key.ELEMENT);
        return new LocalVariableConstantExpression(local);

      case ConstantExpressionKind.POSITIONAL_REFERENCE:
        return new PositionalArgumentReference(decoder.getInt(Key.INDEX));
      case ConstantExpressionKind.NAMED_REFERENCE:
        return new NamedArgumentReference(decoder.getString(Key.NAME));
      case ConstantExpressionKind.DEFERRED:
        return new DeferredConstantExpression(
            decoder.getConstant(Key.EXPRESSION),
            decoder.getElement(Key.PREFIX));
      case ConstantExpressionKind.SYNTHETIC:
    }
    throw new UnsupportedError("Unexpected constant kind: ${kind} in $decoder");
  }
}

/// Visitor that serializes a [ConstantConstructor] by encoding it into an
/// [ObjectEncoder].
///
/// This class is called from the [ConstructorSerializer] when the [Serializer]
/// is serializing constant constructor. The [ObjectEncoder] ensures that any
/// [Element], [ResolutionDartType], and [ConstantExpression] that the
/// serialized [ConstantConstructor] depends upon are also serialized.
class ConstantConstructorSerializer
    extends ConstantConstructorVisitor<dynamic, ObjectEncoder> {
  const ConstantConstructorSerializer();

  @override
  void visit(ConstantConstructor constantConstructor, ObjectEncoder encoder) {
    encoder.setEnum(Key.KIND, constantConstructor.kind);
    constantConstructor.accept(this, encoder);
  }

  @override
  void visitGenerative(
      GenerativeConstantConstructor constructor, ObjectEncoder encoder) {
    ResolutionInterfaceType type = constructor.type;
    encoder.setType(Key.TYPE, type);
    MapEncoder defaults = encoder.createMap(Key.DEFAULTS);
    constructor.defaultValues.forEach((key, e) {
      defaults.setConstant('$key', e);
    });
    ListEncoder fields = encoder.createList(Key.FIELDS);
    constructor.fieldMap.forEach((FieldEntity _f, ConstantExpression e) {
      FieldElement f = _f;
      ObjectEncoder fieldSerializer = fields.createObject();
      fieldSerializer.setElement(Key.FIELD, f);
      fieldSerializer.setConstant(Key.CONSTANT, e);
    });
    if (constructor.superConstructorInvocation != null) {
      encoder.setConstant(
          Key.CONSTRUCTOR, constructor.superConstructorInvocation);
    }
  }

  @override
  void visitRedirectingFactory(
      RedirectingFactoryConstantConstructor constructor,
      ObjectEncoder encoder) {
    encoder.setConstant(
        Key.CONSTRUCTOR, constructor.targetConstructorInvocation);
  }

  @override
  void visitRedirectingGenerative(
      RedirectingGenerativeConstantConstructor constructor,
      ObjectEncoder encoder) {
    MapEncoder defaults = encoder.createMap(Key.DEFAULTS);
    constructor.defaultValues.forEach((key, ConstantExpression e) {
      defaults.setConstant('$key', e);
    });
    encoder.setConstant(Key.CONSTRUCTOR, constructor.thisConstructorInvocation);
  }

  @override
  void visitErroneous(
      ErroneousConstantConstructor constructor, ObjectEncoder arg) {
    throw new UnsupportedError("ConstantConstructorSerializer.visitErroneous");
  }
}

/// Utility class for deserializing [ConstantConstructor]s.
///
/// This is used by the [ConstructorElementZ].
class ConstantConstructorDeserializer {
  /// Deserializes a [ConstantConstructor] from an [ObjectDecoder].
  ///
  /// The class is called from the [Deserializer] when a constant constructor
  /// needs deserialization. The [ObjectDecoder] ensures that any [Element],
  /// [ResolutionDartType], and [ConstantExpression] that the deserialized
  /// [ConstantConstructor] depends upon are available.
  // ignore: MISSING_RETURN
  static ConstantConstructor deserialize(ObjectDecoder decoder) {
    ConstantConstructorKind kind =
        decoder.getEnum(Key.KIND, ConstantConstructorKind.values);

    ResolutionDartType readType() {
      return decoder.getType(Key.TYPE);
    }

    Map<dynamic /*int|String*/, ConstantExpression> readDefaults() {
      Map<dynamic, ConstantExpression> defaultValues =
          <dynamic, ConstantExpression>{};
      if (decoder.containsKey(Key.DEFAULTS)) {
        MapDecoder defaultsMap = decoder.getMap(Key.DEFAULTS);
        defaultsMap.forEachKey((String key) {
          int index = int.parse(key, onError: (_) => null);
          if (index != null) {
            defaultValues[index] = defaultsMap.getConstant(key);
          } else {
            defaultValues[key] = defaultsMap.getConstant(key);
          }
        });
      }
      return defaultValues;
    }

    Map<FieldElement, ConstantExpression> readFields() {
      Map<FieldElement, ConstantExpression> fieldMap =
          <FieldElement, ConstantExpression>{};
      if (decoder.containsKey(Key.FIELDS)) {
        ListDecoder fieldsList = decoder.getList(Key.FIELDS);
        for (int i = 0; i < fieldsList.length; i++) {
          ObjectDecoder object = fieldsList.getObject(i);
          FieldElement field = object.getElement(Key.FIELD);
          ConstantExpression constant = object.getConstant(Key.CONSTANT);
          fieldMap[field] = constant;
        }
      }
      return fieldMap;
    }

    ConstructedConstantExpression readConstructorInvocation() {
      return decoder.getConstant(Key.CONSTRUCTOR, isOptional: true);
    }

    switch (kind) {
      case ConstantConstructorKind.GENERATIVE:
        ResolutionInterfaceType type = readType();
        return new GenerativeConstantConstructor(
            type, readDefaults(), readFields(), readConstructorInvocation());
      case ConstantConstructorKind.REDIRECTING_GENERATIVE:
        return new RedirectingGenerativeConstantConstructor(
            readDefaults(), readConstructorInvocation());
      case ConstantConstructorKind.REDIRECTING_FACTORY:
        return new RedirectingFactoryConstantConstructor(
            readConstructorInvocation());
      case ConstantConstructorKind.ERRONEOUS:
        throw new UnsupportedError(
            'Unsupported constant constructor kind: $kind');
    }
  }
}
