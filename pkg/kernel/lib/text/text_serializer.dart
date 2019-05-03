// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.text_serializer;

import '../ast.dart';

import 'serializer_combinators.dart';

import '../visitor.dart' show ExpressionVisitor;

abstract class Tagger<T extends Node> {
  String tag(T node);
}

class NameTagger implements Tagger<Name> {
  const NameTagger();

  String tag(Name name) => name.isPrivate ? "private" : "public";
}

TextSerializer<Name> publicName =
    new Wrapped(unwrapPublicName, wrapPublicName, const DartString());

String unwrapPublicName(Name name) => name.name;

Name wrapPublicName(String name) => new Name(name);

TextSerializer<Name> privateName = new Wrapped(unwrapPrivateName,
    wrapPrivateName, Tuple2Serializer(const DartString(), const DartString()));

Tuple2<String, String> unwrapPrivateName(Name name) {
  return new Tuple2(name.library.importUri.toString(), name.name);
}

Name wrapPrivateName(Tuple2<String, String> tuple) {
  // We need a map from import URI to libraries.  More generally, we will need
  // a way to map any 'named' node to the node's reference.
  throw UnimplementedError('deserialization of private names');
}

TextSerializer<Name> nameSerializer = new Case(const NameTagger(), [
  "public",
  "private",
], [
  publicName,
  privateName
]);

class ExpressionTagger extends ExpressionVisitor<String>
    implements Tagger<Expression> {
  const ExpressionTagger();

  String tag(Expression expression) => expression.accept(this);

  String visitStringLiteral(StringLiteral _) => "string";
  String visitIntLiteral(IntLiteral _) => "int";
  String visitDoubleLiteral(DoubleLiteral _) => "double";
  String visitBoolLiteral(BoolLiteral _) => "bool";
  String visitNullLiteral(NullLiteral _) => "null";
  String visitInvalidExpression(InvalidExpression _) => "invalid";
  String visitNot(Not _) => "not";
  String visitLogicalExpression(LogicalExpression expression) {
    return expression.operator;
  }

  String visitStringConcatenation(StringConcatenation _) => "concat";
  String visitSymbolLiteral(SymbolLiteral _) => "symbol";
  String visitThisExpression(ThisExpression _) => "this";
  String visitRethrow(Rethrow _) => "rethrow";
  String visitThrow(Throw _) => "throw";
  String visitAwaitExpression(AwaitExpression _) => "await";
  String visitConditionalExpression(ConditionalExpression _) => "cond";
  String visitIsExpression(IsExpression _) => "is";
  String visitAsExpression(AsExpression _) => "as";
  String visitTypeLiteral(TypeLiteral _) => "type";
  String visitListLiteral(ListLiteral expression) {
    return expression.isConst ? "const-list" : "list";
  }

  String visitSetLiteral(SetLiteral expression) {
    return expression.isConst ? "const-set" : "set";
  }

  String visitMapLiteral(MapLiteral expression) {
    return expression.isConst ? "const-map" : "map";
  }

  String visitLet(Let _) => "let";

  String visitPropertyGet(PropertyGet _) => "get-prop";
  String visitPropertySet(PropertySet _) => "set-prop";
  String visitSuperPropertyGet(SuperPropertyGet _) => "get-super";
  String visitSuperPropertySet(SuperPropertySet _) => "set-super";
  String visitMethodInvocation(MethodInvocation _) => "invoke-method";
  String visitSuperMethodInvocation(SuperMethodInvocation _) => "invoke-super";

  String visitVariableGet(VariableGet _) => "get-var";
  String visitVariableSet(VariableSet _) => "set-var";
  String visitStaticGet(StaticGet _) => "get-static";
  String visitStaticSet(StaticSet _) => "set-static";
  String visitDirectPropertyGet(DirectPropertyGet _) => "get-direct-prop";
  String visitDirectPropertySet(DirectPropertySet _) => "set-direct-prop";
  String visitStaticInvocation(StaticInvocation expression) {
    return expression.isConst ? "invoke-const-static" : "invoke-static";
  }

  String visitDirectMethodInvocation(DirectMethodInvocation _) {
    return "invoke-direct-method";
  }

  String visitConstructorInvocation(ConstructorInvocation expression) {
    return expression.isConst
        ? "invoke-const-constructor"
        : "invoke-constructor";
  }
}

TextSerializer<InvalidExpression> invalidExpressionSerializer = new Wrapped(
    unwrapInvalidExpression, wrapInvalidExpression, const DartString());

String unwrapInvalidExpression(InvalidExpression expression) {
  return expression.message;
}

InvalidExpression wrapInvalidExpression(String message) {
  return new InvalidExpression(message);
}

TextSerializer<Not> notSerializer =
    new Wrapped(unwrapNot, wrapNot, expressionSerializer);

Expression unwrapNot(Not expression) => expression.operand;

Not wrapNot(Expression operand) => new Not(operand);

TextSerializer<LogicalExpression> logicalAndSerializer = new Wrapped(
    unwrapLogicalExpression,
    wrapLogicalAnd,
    new Tuple2Serializer(expressionSerializer, expressionSerializer));

Tuple2<Expression, Expression> unwrapLogicalExpression(
    LogicalExpression expression) {
  return new Tuple2(expression.left, expression.right);
}

LogicalExpression wrapLogicalAnd(Tuple2<Expression, Expression> tuple) {
  return new LogicalExpression(tuple.first, '&&', tuple.second);
}

TextSerializer<LogicalExpression> logicalOrSerializer = new Wrapped(
    unwrapLogicalExpression,
    wrapLogicalOr,
    new Tuple2Serializer(expressionSerializer, expressionSerializer));

LogicalExpression wrapLogicalOr(Tuple2<Expression, Expression> tuple) {
  return new LogicalExpression(tuple.first, '||', tuple.second);
}

TextSerializer<StringConcatenation> stringConcatenationSerializer = new Wrapped(
    unwrapStringConcatenation,
    wrapStringConcatenation,
    new ListSerializer(expressionSerializer));

List<Expression> unwrapStringConcatenation(StringConcatenation expression) {
  return expression.expressions;
}

StringConcatenation wrapStringConcatenation(List<Expression> expressions) {
  return new StringConcatenation(expressions);
}

TextSerializer<StringLiteral> stringLiteralSerializer =
    new Wrapped(unwrapStringLiteral, wrapStringLiteral, const DartString());

String unwrapStringLiteral(StringLiteral literal) => literal.value;

StringLiteral wrapStringLiteral(String value) => new StringLiteral(value);

TextSerializer<IntLiteral> intLiteralSerializer =
    new Wrapped(unwrapIntLiteral, wrapIntLiteral, const DartInt());

int unwrapIntLiteral(IntLiteral literal) => literal.value;

IntLiteral wrapIntLiteral(int value) => new IntLiteral(value);

TextSerializer<DoubleLiteral> doubleLiteralSerializer =
    new Wrapped(unwrapDoubleLiteral, wrapDoubleLiteral, const DartDouble());

double unwrapDoubleLiteral(DoubleLiteral literal) => literal.value;

DoubleLiteral wrapDoubleLiteral(double value) => new DoubleLiteral(value);

TextSerializer<BoolLiteral> boolLiteralSerializer =
    new Wrapped(unwrapBoolLiteral, wrapBoolLiteral, const DartBool());

bool unwrapBoolLiteral(BoolLiteral literal) => literal.value;

BoolLiteral wrapBoolLiteral(bool value) => new BoolLiteral(value);

TextSerializer<NullLiteral> nullLiteralSerializer =
    new Wrapped(unwrapNullLiteral, wrapNullLiteral, const Nothing());

void unwrapNullLiteral(NullLiteral literal) {}

NullLiteral wrapNullLiteral(void ignored) => new NullLiteral();

TextSerializer<SymbolLiteral> symbolLiteralSerializer =
    new Wrapped(unwrapSymbolLiteral, wrapSymbolLiteral, const DartString());

String unwrapSymbolLiteral(SymbolLiteral expression) => expression.value;

SymbolLiteral wrapSymbolLiteral(String value) => new SymbolLiteral(value);

TextSerializer<ThisExpression> thisExpressionSerializer =
    new Wrapped(unwrapThisExpression, wrapThisExpression, const Nothing());

void unwrapThisExpression(ThisExpression expression) {}

ThisExpression wrapThisExpression(void ignored) => new ThisExpression();

TextSerializer<Rethrow> rethrowSerializer =
    new Wrapped(unwrapRethrow, wrapRethrow, const Nothing());

void unwrapRethrow(Rethrow expression) {}

Rethrow wrapRethrow(void ignored) => new Rethrow();

TextSerializer<Throw> throwSerializer =
    new Wrapped(unwrapThrow, wrapThrow, expressionSerializer);

Expression unwrapThrow(Throw expression) => expression.expression;

Throw wrapThrow(Expression expression) => new Throw(expression);

TextSerializer<AwaitExpression> awaitExpressionSerializer = new Wrapped(
    unwrapAwaitExpression, wrapAwaitExpression, expressionSerializer);

Expression unwrapAwaitExpression(AwaitExpression expression) =>
    expression.operand;

AwaitExpression wrapAwaitExpression(Expression operand) =>
    new AwaitExpression(operand);

TextSerializer<ConditionalExpression> conditionalExpressionSerializer =
    new Wrapped(
        unwrapConditionalExpression,
        wrapConditionalExpression,
        new Tuple4Serializer(expressionSerializer, dartTypeSerializer,
            expressionSerializer, expressionSerializer));

Tuple4<Expression, DartType, Expression, Expression>
    unwrapConditionalExpression(ConditionalExpression expression) {
  return new Tuple4(expression.condition, expression.staticType,
      expression.then, expression.otherwise);
}

ConditionalExpression wrapConditionalExpression(
    Tuple4<Expression, DartType, Expression, Expression> tuple) {
  return new ConditionalExpression(
      tuple.first, tuple.third, tuple.fourth, tuple.second);
}

TextSerializer<IsExpression> isExpressionSerializer = new Wrapped(
    unwrapIsExpression,
    wrapIsExpression,
    new Tuple2Serializer(expressionSerializer, dartTypeSerializer));

Tuple2<Expression, DartType> unwrapIsExpression(IsExpression expression) {
  return new Tuple2(expression.operand, expression.type);
}

IsExpression wrapIsExpression(Tuple2<Expression, DartType> tuple) {
  return new IsExpression(tuple.first, tuple.second);
}

TextSerializer<AsExpression> asExpressionSerializer = new Wrapped(
    unwrapAsExpression,
    wrapAsExpression,
    new Tuple2Serializer(expressionSerializer, dartTypeSerializer));

Tuple2<Expression, DartType> unwrapAsExpression(AsExpression expression) {
  return new Tuple2(expression.operand, expression.type);
}

AsExpression wrapAsExpression(Tuple2<Expression, DartType> tuple) {
  return new AsExpression(tuple.first, tuple.second);
}

TextSerializer<TypeLiteral> typeLiteralSerializer =
    new Wrapped(unwrapTypeLiteral, wrapTypeLiteral, dartTypeSerializer);

DartType unwrapTypeLiteral(TypeLiteral expression) => expression.type;

TypeLiteral wrapTypeLiteral(DartType type) => new TypeLiteral(type);

TextSerializer<ListLiteral> listLiteralSerializer = new Wrapped(
    unwrapListLiteral,
    wrapListLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

Tuple2<DartType, List<Expression>> unwrapListLiteral(ListLiteral expression) {
  return new Tuple2(expression.typeArgument, expression.expressions);
}

ListLiteral wrapListLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new ListLiteral(tuple.second,
      typeArgument: tuple.first, isConst: false);
}

TextSerializer<ListLiteral> constListLiteralSerializer = new Wrapped(
    unwrapListLiteral,
    wrapConstListLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

ListLiteral wrapConstListLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new ListLiteral(tuple.second,
      typeArgument: tuple.first, isConst: true);
}

TextSerializer<SetLiteral> setLiteralSerializer = new Wrapped(
    unwrapSetLiteral,
    wrapSetLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

Tuple2<DartType, List<Expression>> unwrapSetLiteral(SetLiteral expression) {
  return new Tuple2(expression.typeArgument, expression.expressions);
}

SetLiteral wrapSetLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new SetLiteral(tuple.second,
      typeArgument: tuple.first, isConst: false);
}

TextSerializer<SetLiteral> constSetLiteralSerializer = new Wrapped(
    unwrapSetLiteral,
    wrapConstSetLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

SetLiteral wrapConstSetLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new SetLiteral(tuple.second, typeArgument: tuple.first, isConst: true);
}

TextSerializer<MapLiteral> mapLiteralSerializer = new Wrapped(
    unwrapMapLiteral,
    wrapMapLiteral,
    new Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
        new ListSerializer(expressionSerializer)));

Tuple3<DartType, DartType, List<Expression>> unwrapMapLiteral(
    MapLiteral expression) {
  List<Expression> entries = new List(2 * expression.entries.length);
  for (int from = 0, to = 0; from < expression.entries.length; ++from) {
    MapEntry entry = expression.entries[from];
    entries[to++] = entry.key;
    entries[to++] = entry.value;
  }
  return new Tuple3(expression.keyType, expression.valueType, entries);
}

MapLiteral wrapMapLiteral(Tuple3<DartType, DartType, List<Expression>> tuple) {
  List<MapEntry> entries = new List(tuple.third.length ~/ 2);
  for (int from = 0, to = 0; to < entries.length; ++to) {
    entries[to] = new MapEntry(tuple.third[from++], tuple.third[from++]);
  }
  return new MapLiteral(entries,
      keyType: tuple.first, valueType: tuple.second, isConst: false);
}

TextSerializer<MapLiteral> constMapLiteralSerializer = new Wrapped(
    unwrapMapLiteral,
    wrapConstMapLiteral,
    new Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
        new ListSerializer(expressionSerializer)));

MapLiteral wrapConstMapLiteral(
    Tuple3<DartType, DartType, List<Expression>> tuple) {
  List<MapEntry> entries = new List(tuple.third.length ~/ 2);
  for (int from = 0, to = 0; to < entries.length; ++to) {
    entries[to] = new MapEntry(tuple.third[from++], tuple.third[from++]);
  }
  return new MapLiteral(entries,
      keyType: tuple.first, valueType: tuple.second, isConst: true);
}

TextSerializer<Let> letSerializer = new Wrapped(
    unwrapLet,
    wrapLet,
    new Bind(
        new Binder(variableDeclarationSerializer, getVariableDeclarationName,
            setVariableDeclarationName),
        expressionSerializer));

Tuple2<VariableDeclaration, Expression> unwrapLet(Let expression) {
  return new Tuple2(expression.variable, expression.body);
}

Let wrapLet(Tuple2<VariableDeclaration, Expression> tuple) {
  return new Let(tuple.first, tuple.second);
}

String getVariableDeclarationName(VariableDeclaration node) => node.name;

void setVariableDeclarationName(VariableDeclaration node, String name) {
  node.name = name;
}

TextSerializer<PropertyGet> propertyGetSerializer = new Wrapped(
    unwrapPropertyGet,
    wrapPropertyGet,
    new Tuple2Serializer(expressionSerializer, nameSerializer));

Tuple2<Expression, Name> unwrapPropertyGet(PropertyGet expression) {
  return new Tuple2(expression.receiver, expression.name);
}

PropertyGet wrapPropertyGet(Tuple2<Expression, Name> tuple) {
  return new PropertyGet(tuple.first, tuple.second);
}

TextSerializer<PropertySet> propertySetSerializer = new Wrapped(
    unwrapPropertySet,
    wrapPropertySet,
    new Tuple3Serializer(
        expressionSerializer, nameSerializer, expressionSerializer));

Tuple3<Expression, Name, Expression> unwrapPropertySet(PropertySet expression) {
  return new Tuple3(expression.receiver, expression.name, expression.value);
}

PropertySet wrapPropertySet(Tuple3<Expression, Name, Expression> tuple) {
  return new PropertySet(tuple.first, tuple.second, tuple.third);
}

TextSerializer<SuperPropertyGet> superPropertyGetSerializer =
    new Wrapped(unwrapSuperPropertyGet, wrapSuperPropertyGet, nameSerializer);

Name unwrapSuperPropertyGet(SuperPropertyGet expression) {
  return expression.name;
}

SuperPropertyGet wrapSuperPropertyGet(Name name) {
  return new SuperPropertyGet(name);
}

TextSerializer<SuperPropertySet> superPropertySetSerializer = new Wrapped(
    unwrapSuperPropertySet,
    wrapSuperPropertySet,
    new Tuple2Serializer(nameSerializer, expressionSerializer));

Tuple2<Name, Expression> unwrapSuperPropertySet(SuperPropertySet expression) {
  return new Tuple2(expression.name, expression.value);
}

SuperPropertySet wrapSuperPropertySet(Tuple2<Name, Expression> tuple) {
  return new SuperPropertySet(tuple.first, tuple.second, null);
}

TextSerializer<MethodInvocation> methodInvocationSerializer = new Wrapped(
    unwrapMethodInvocation,
    wrapMethodInvocation,
    new Tuple3Serializer(
        expressionSerializer, nameSerializer, argumentsSerializer));

Tuple3<Expression, Name, Arguments> unwrapMethodInvocation(
    MethodInvocation expression) {
  return new Tuple3(expression.receiver, expression.name, expression.arguments);
}

MethodInvocation wrapMethodInvocation(
    Tuple3<Expression, Name, Arguments> tuple) {
  return new MethodInvocation(tuple.first, tuple.second, tuple.third);
}

TextSerializer<SuperMethodInvocation> superMethodInvocationSerializer =
    new Wrapped(unwrapSuperMethodInvocation, wrapSuperMethodInvocation,
        new Tuple2Serializer(nameSerializer, argumentsSerializer));

Tuple2<Name, Arguments> unwrapSuperMethodInvocation(
    SuperMethodInvocation expression) {
  return new Tuple2(expression.name, expression.arguments);
}

SuperMethodInvocation wrapSuperMethodInvocation(Tuple2<Name, Arguments> tuple) {
  return new SuperMethodInvocation(tuple.first, tuple.second);
}

TextSerializer<VariableGet> variableGetSerializer = new Wrapped(
    unwrapVariableGet,
    wrapVariableGet,
    new Tuple2Serializer(const ScopedUse<VariableDeclaration>(),
        new Optional(dartTypeSerializer)));

Tuple2<VariableDeclaration, DartType> unwrapVariableGet(VariableGet node) {
  return new Tuple2<VariableDeclaration, DartType>(
      node.variable, node.promotedType);
}

VariableGet wrapVariableGet(Tuple2<VariableDeclaration, DartType> tuple) {
  return new VariableGet(tuple.first, tuple.second);
}

TextSerializer<VariableSet> variableSetSerializer = new Wrapped(
    unwrapVariableSet,
    wrapVariableSet,
    new Tuple2Serializer(
        const ScopedUse<VariableDeclaration>(), expressionSerializer));

Tuple2<VariableDeclaration, Expression> unwrapVariableSet(VariableSet node) {
  return new Tuple2<VariableDeclaration, Expression>(node.variable, node.value);
}

VariableSet wrapVariableSet(Tuple2<VariableDeclaration, Expression> tuple) {
  return new VariableSet(tuple.first, tuple.second);
}

class CanonicalNameSerializer extends TextSerializer<CanonicalName> {
  static const String delimiter = "::";

  const CanonicalNameSerializer();

  static void writeName(CanonicalName name, StringBuffer buffer) {
    if (!name.isRoot) {
      if (!name.parent.isRoot) {
        writeName(name.parent, buffer);
        buffer.write(delimiter);
      }
      buffer.write(name.name);
    }
  }

  CanonicalName readFrom(Iterator<Object> stream, DeserializationState state) {
    String string = const DartString().readFrom(stream, state);
    CanonicalName name = state.nameRoot;
    for (String s in string.split(delimiter)) {
      name = name.getChild(s);
    }
    return name;
  }

  void writeTo(
      StringBuffer buffer, CanonicalName name, SerializationState state) {
    StringBuffer sb = new StringBuffer();
    writeName(name, sb);
    const DartString().writeTo(buffer, sb.toString(), state);
  }
}

TextSerializer<StaticGet> staticGetSerializer =
    new Wrapped(unwrapStaticGet, wrapStaticGet, new CanonicalNameSerializer());

CanonicalName unwrapStaticGet(StaticGet expression) {
  return expression.targetReference.canonicalName;
}

StaticGet wrapStaticGet(CanonicalName name) {
  return new StaticGet.byReference(name.getReference());
}

TextSerializer<StaticSet> staticSetSerializer = new Wrapped(
    unwrapStaticSet,
    wrapStaticSet,
    new Tuple2Serializer(
        const CanonicalNameSerializer(), expressionSerializer));

Tuple2<CanonicalName, Expression> unwrapStaticSet(StaticSet expression) {
  return new Tuple2(expression.targetReference.canonicalName, expression.value);
}

StaticSet wrapStaticSet(Tuple2<CanonicalName, Expression> tuple) {
  return new StaticSet.byReference(tuple.first.getReference(), tuple.second);
}

TextSerializer<DirectPropertyGet> directPropertyGetSerializer = new Wrapped(
    unwrapDirectPropertyGet,
    wrapDirectPropertyGet,
    new Tuple2Serializer(
        expressionSerializer, const CanonicalNameSerializer()));

Tuple2<Expression, CanonicalName> unwrapDirectPropertyGet(
    DirectPropertyGet expression) {
  return new Tuple2(
      expression.receiver, expression.targetReference.canonicalName);
}

DirectPropertyGet wrapDirectPropertyGet(
    Tuple2<Expression, CanonicalName> tuple) {
  return new DirectPropertyGet.byReference(
      tuple.first, tuple.second.getReference());
}

TextSerializer<DirectPropertySet> directPropertySetSerializer = new Wrapped(
    unwrapDirectPropertySet,
    wrapDirectPropertySet,
    new Tuple3Serializer(expressionSerializer, const CanonicalNameSerializer(),
        expressionSerializer));

Tuple3<Expression, CanonicalName, Expression> unwrapDirectPropertySet(
    DirectPropertySet expression) {
  return new Tuple3(expression.receiver,
      expression.targetReference.canonicalName, expression.value);
}

DirectPropertySet wrapDirectPropertySet(
    Tuple3<Expression, CanonicalName, Expression> tuple) {
  return new DirectPropertySet.byReference(
      tuple.first, tuple.second.getReference(), tuple.third);
}

TextSerializer<StaticInvocation> staticInvocationSerializer = new Wrapped(
    unwrapStaticInvocation,
    wrapStaticInvocation,
    new Tuple2Serializer(const CanonicalNameSerializer(), argumentsSerializer));

Tuple2<CanonicalName, Arguments> unwrapStaticInvocation(
    StaticInvocation expression) {
  return new Tuple2(
      expression.targetReference.canonicalName, expression.arguments);
}

StaticInvocation wrapStaticInvocation(Tuple2<CanonicalName, Arguments> tuple) {
  return new StaticInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: false);
}

TextSerializer<StaticInvocation> constStaticInvocationSerializer = new Wrapped(
    unwrapStaticInvocation,
    wrapConstStaticInvocation,
    new Tuple2Serializer(const CanonicalNameSerializer(), argumentsSerializer));

StaticInvocation wrapConstStaticInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new StaticInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: true);
}

TextSerializer<DirectMethodInvocation> directMethodInvocationSerializer =
    new Wrapped(
        unwrapDirectMethodInvocation,
        wrapDirectMethodInvocation,
        new Tuple3Serializer(expressionSerializer,
            const CanonicalNameSerializer(), argumentsSerializer));

Tuple3<Expression, CanonicalName, Arguments> unwrapDirectMethodInvocation(
    DirectMethodInvocation expression) {
  return new Tuple3(expression.receiver,
      expression.targetReference.canonicalName, expression.arguments);
}

DirectMethodInvocation wrapDirectMethodInvocation(
    Tuple3<Expression, CanonicalName, Arguments> tuple) {
  return new DirectMethodInvocation.byReference(
      tuple.first, tuple.second.getReference(), tuple.third);
}

TextSerializer<ConstructorInvocation> constructorInvocationSerializer =
    new Wrapped(
        unwrapConstructorInvocation,
        wrapConstructorInvocation,
        new Tuple2Serializer(
            const CanonicalNameSerializer(), argumentsSerializer));

Tuple2<CanonicalName, Arguments> unwrapConstructorInvocation(
    ConstructorInvocation expression) {
  return new Tuple2(
      expression.targetReference.canonicalName, expression.arguments);
}

ConstructorInvocation wrapConstructorInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new ConstructorInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: false);
}

TextSerializer<ConstructorInvocation> constConstructorInvocationSerializer =
    new Wrapped(unwrapConstructorInvocation, wrapConstConstructorInvocation,
        Tuple2Serializer(const CanonicalNameSerializer(), argumentsSerializer));

ConstructorInvocation wrapConstConstructorInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new ConstructorInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: true);
}

Case<Expression> expressionSerializer =
    new Case.uninitialized(const ExpressionTagger());

TextSerializer<NamedExpression> namedExpressionSerializer = new Wrapped(
    unwrapNamedExpression,
    wrapNamedExpression,
    new Tuple2Serializer(const DartString(), expressionSerializer));

Tuple2<String, Expression> unwrapNamedExpression(NamedExpression expression) {
  return new Tuple2(expression.name, expression.value);
}

NamedExpression wrapNamedExpression(Tuple2<String, Expression> tuple) {
  return new NamedExpression(tuple.first, tuple.second);
}

TextSerializer<Arguments> argumentsSerializer = new Wrapped(
    unwrapArguments,
    wrapArguments,
    Tuple3Serializer(
        new ListSerializer(dartTypeSerializer),
        new ListSerializer(expressionSerializer),
        new ListSerializer(namedExpressionSerializer)));

Tuple3<List<DartType>, List<Expression>, List<NamedExpression>> unwrapArguments(
    Arguments arguments) {
  return new Tuple3(arguments.types, arguments.positional, arguments.named);
}

Arguments wrapArguments(
    Tuple3<List<DartType>, List<Expression>, List<NamedExpression>> tuple) {
  return new Arguments(tuple.second, types: tuple.first, named: tuple.third);
}

class VariableDeclarationTagger implements Tagger<VariableDeclaration> {
  const VariableDeclarationTagger();

  String tag(VariableDeclaration decl) {
    if (decl.isCovariant) throw UnimplementedError("covariant declaration");
    if (decl.isFieldFormal) throw UnimplementedError("initializing formal");
    if (decl.isConst) {
      // It's not clear what invariants we assume about const/final.  For now
      // throw if we have both.
      if (decl.isFinal) throw UnimplementedError("const and final");
      return "const";
    }
    if (decl.isFinal) {
      return "final";
    }
    return "var";
  }
}

TextSerializer<VariableDeclaration> varDeclarationSerializer = new Wrapped(
    unwrapVariableDeclaration,
    wrapVarDeclaration,
    Tuple4Serializer(
        const DartString(),
        dartTypeSerializer,
        new Optional(expressionSerializer),
        new ListSerializer(expressionSerializer)));

Tuple4<String, DartType, Expression, List<Expression>>
    unwrapVariableDeclaration(VariableDeclaration declaration) {
  return new Tuple4(declaration.name ?? "", declaration.type,
      declaration.initializer, declaration.annotations);
}

VariableDeclaration wrapVarDeclaration(
    Tuple4<String, DartType, Expression, List<Expression>> tuple) {
  var result = new VariableDeclaration(tuple.first.isEmpty ? null : tuple.first,
      initializer: tuple.third, type: tuple.second);
  for (int i = 0; i < tuple.fourth.length; ++i) {
    result.addAnnotation(tuple.fourth[i]);
  }
  return result;
}

TextSerializer<VariableDeclaration> finalDeclarationSerializer = new Wrapped(
    unwrapVariableDeclaration,
    wrapFinalDeclaration,
    Tuple4Serializer(
        const DartString(),
        dartTypeSerializer,
        new Optional(expressionSerializer),
        new ListSerializer(expressionSerializer)));

VariableDeclaration wrapFinalDeclaration(
    Tuple4<String, DartType, Expression, List<Expression>> tuple) {
  var result = new VariableDeclaration(tuple.first.isEmpty ? null : tuple.first,
      initializer: tuple.third, type: tuple.second, isFinal: true);
  for (int i = 0; i < tuple.fourth.length; ++i) {
    result.addAnnotation(tuple.fourth[i]);
  }
  return result;
}

TextSerializer<VariableDeclaration> constDeclarationSerializer = new Wrapped(
    unwrapVariableDeclaration,
    wrapConstDeclaration,
    Tuple4Serializer(
        const DartString(),
        dartTypeSerializer,
        new Optional(expressionSerializer),
        new ListSerializer(expressionSerializer)));

VariableDeclaration wrapConstDeclaration(
    Tuple4<String, DartType, Expression, List<Expression>> tuple) {
  var result = new VariableDeclaration(tuple.first.isEmpty ? null : tuple.first,
      initializer: tuple.third, type: tuple.second, isConst: true);
  for (int i = 0; i < tuple.fourth.length; ++i) {
    result.addAnnotation(tuple.fourth[i]);
  }
  return result;
}

TextSerializer<VariableDeclaration> variableDeclarationSerializer =
    new Case(const VariableDeclarationTagger(), [
  "var",
  "final",
  "const",
], [
  varDeclarationSerializer,
  finalDeclarationSerializer,
  constDeclarationSerializer,
]);

TextSerializer<TypeParameter> typeParameterSerializer =
    new Wrapped(unwrapTypeParameter, wrapTypeParameter, const DartString());

String unwrapTypeParameter(TypeParameter node) => node.name;

TypeParameter wrapTypeParameter(String name) => new TypeParameter(name);

TextSerializer<List<TypeParameter>> typeParametersSerializer = new Zip(
    new Rebind(
        new Zip(
            new Rebind(
                new ListSerializer(new Binder(typeParameterSerializer,
                    getTypeParameterName, setTypeParameterName)),
                new ListSerializer(dartTypeSerializer)),
            zipTypeParameterBound,
            unzipTypeParameterBound),
        new ListSerializer(dartTypeSerializer)),
    zipTypeParameterDefaultType,
    unzipTypeParameterDefaultType);

String getTypeParameterName(TypeParameter node) => node.name;

void setTypeParameterName(TypeParameter node, String name) {
  node.name = name;
}

TypeParameter zipTypeParameterBound(TypeParameter node, DartType bound) {
  return node..bound = bound;
}

Tuple2<TypeParameter, DartType> unzipTypeParameterBound(TypeParameter node) {
  return new Tuple2(node, node.bound);
}

TypeParameter zipTypeParameterDefaultType(
    TypeParameter node, DartType defaultType) {
  return node..defaultType = defaultType;
}

Tuple2<TypeParameter, DartType> unzipTypeParameterDefaultType(
    TypeParameter node) {
  return new Tuple2(node, node.defaultType);
}

class DartTypeTagger extends DartTypeVisitor<String>
    implements Tagger<DartType> {
  const DartTypeTagger();

  String tag(DartType type) => type.accept(this);

  String visitInvalidType(InvalidType _) => "invalid";
  String visitDynamicType(DynamicType _) => "dynamic";
  String visitVoidType(VoidType _) => "void";
  String visitBottomType(BottomType _) => "bottom";
  String visitFunctionType(FunctionType _) => "->";
  String visitTypeParameterType(TypeParameterType _) => "par";
}

TextSerializer<InvalidType> invalidTypeSerializer =
    new Wrapped(unwrapInvalidType, wrapInvalidType, const Nothing());

void unwrapInvalidType(InvalidType type) {}

InvalidType wrapInvalidType(void ignored) => const InvalidType();

TextSerializer<DynamicType> dynamicTypeSerializer =
    new Wrapped(unwrapDynamicType, wrapDynamicType, const Nothing());

void unwrapDynamicType(DynamicType type) {}

DynamicType wrapDynamicType(void ignored) => const DynamicType();

TextSerializer<VoidType> voidTypeSerializer =
    new Wrapped(unwrapVoidType, wrapVoidType, const Nothing());

void unwrapVoidType(VoidType type) {}

VoidType wrapVoidType(void ignored) => const VoidType();

TextSerializer<BottomType> bottomTypeSerializer =
    new Wrapped(unwrapBottomType, wrapBottomType, const Nothing());

void unwrapBottomType(BottomType type) {}

BottomType wrapBottomType(void ignored) => const BottomType();

// TODO(dmitryas):  Also handle nameParameters, and typedefType.
TextSerializer<FunctionType> functionTypeSerializer = new Wrapped(
    unwrapFunctionType,
    wrapFunctionType,
    new Bind(
        typeParametersSerializer,
        new Tuple4Serializer(
            new ListSerializer(dartTypeSerializer),
            new ListSerializer(dartTypeSerializer),
            new ListSerializer(namedTypeSerializer),
            dartTypeSerializer)));

Tuple2<List<TypeParameter>,
        Tuple4<List<DartType>, List<DartType>, List<NamedType>, DartType>>
    unwrapFunctionType(FunctionType type) {
  return new Tuple2(
      type.typeParameters,
      new Tuple4(
          type.positionalParameters.sublist(0, type.requiredParameterCount),
          type.positionalParameters.sublist(type.requiredParameterCount),
          type.namedParameters,
          type.returnType));
}

FunctionType wrapFunctionType(
    Tuple2<List<TypeParameter>,
            Tuple4<List<DartType>, List<DartType>, List<NamedType>, DartType>>
        tuple) {
  return new FunctionType(
      tuple.second.first + tuple.second.second, tuple.second.fourth,
      requiredParameterCount: tuple.second.first.length,
      typeParameters: tuple.first,
      namedParameters: tuple.second.third);
}

TextSerializer<NamedType> namedTypeSerializer = new Wrapped(unwrapNamedType,
    wrapNamedType, Tuple2Serializer(const DartString(), dartTypeSerializer));

Tuple2<String, DartType> unwrapNamedType(NamedType namedType) {
  return new Tuple2(namedType.name, namedType.type);
}

NamedType wrapNamedType(Tuple2<String, DartType> tuple) {
  return new NamedType(tuple.first, tuple.second);
}

TextSerializer<TypeParameterType> typeParameterTypeSerializer = new Wrapped(
    unwrapTypeParameterType,
    wrapTypeParameterType,
    Tuple2Serializer(
        new ScopedUse<TypeParameter>(), new Optional(dartTypeSerializer)));

Tuple2<TypeParameter, DartType> unwrapTypeParameterType(
    TypeParameterType node) {
  return new Tuple2(node.parameter, node.promotedBound);
}

TypeParameterType wrapTypeParameterType(Tuple2<TypeParameter, DartType> tuple) {
  return new TypeParameterType(tuple.first, tuple.second);
}

Case<DartType> dartTypeSerializer =
    new Case.uninitialized(const DartTypeTagger());

class StatementTagger extends StatementVisitor<String>
    implements Tagger<Statement> {
  const StatementTagger();

  String tag(Statement statement) => statement.accept(this);

  String visitExpressionStatement(ExpressionStatement _) => "expr";
}

TextSerializer<ExpressionStatement> expressionStatementSerializer = new Wrapped(
    unwrapExpressionStatement, wrapExpressionStatement, expressionSerializer);

Expression unwrapExpressionStatement(ExpressionStatement statement) {
  return statement.expression;
}

ExpressionStatement wrapExpressionStatement(Expression expression) {
  return new ExpressionStatement(expression);
}

Case<Statement> statementSerializer =
    new Case.uninitialized(const StatementTagger());

void initializeSerializers() {
  expressionSerializer.tags.addAll([
    "string",
    "int",
    "double",
    "bool",
    "null",
    "invalid",
    "not",
    "&&",
    "||",
    "concat",
    "symbol",
    "this",
    "rethrow",
    "throw",
    "await",
    "cond",
    "is",
    "as",
    "type",
    "list",
    "const-list",
    "set",
    "const-set",
    "map",
    "const-map",
    "let",
    "get-prop",
    "set-prop",
    "get-super",
    "set-super",
    "invoke-method",
    "invoke-super",
    "get-var",
    "set-var",
    "get-static",
    "set-static",
    "get-direct-prop",
    "set-direct-prop",
    "invoke-static",
    "invoke-const-static",
    "invoke-direct-method",
    "invoke-constructor",
    "invoke-const-constructor",
  ]);
  expressionSerializer.serializers.addAll([
    stringLiteralSerializer,
    intLiteralSerializer,
    doubleLiteralSerializer,
    boolLiteralSerializer,
    nullLiteralSerializer,
    invalidExpressionSerializer,
    notSerializer,
    logicalAndSerializer,
    logicalOrSerializer,
    stringConcatenationSerializer,
    symbolLiteralSerializer,
    thisExpressionSerializer,
    rethrowSerializer,
    throwSerializer,
    awaitExpressionSerializer,
    conditionalExpressionSerializer,
    isExpressionSerializer,
    asExpressionSerializer,
    typeLiteralSerializer,
    listLiteralSerializer,
    constListLiteralSerializer,
    setLiteralSerializer,
    constSetLiteralSerializer,
    mapLiteralSerializer,
    constMapLiteralSerializer,
    letSerializer,
    propertyGetSerializer,
    propertySetSerializer,
    superPropertyGetSerializer,
    superPropertySetSerializer,
    methodInvocationSerializer,
    superMethodInvocationSerializer,
    variableGetSerializer,
    variableSetSerializer,
    staticGetSerializer,
    staticSetSerializer,
    directPropertyGetSerializer,
    directPropertySetSerializer,
    staticInvocationSerializer,
    constStaticInvocationSerializer,
    directMethodInvocationSerializer,
    constructorInvocationSerializer,
    constConstructorInvocationSerializer,
  ]);
  dartTypeSerializer.tags.addAll([
    "invalid",
    "dynamic",
    "void",
    "bottom",
    "->",
    "par",
  ]);
  dartTypeSerializer.serializers.addAll([
    invalidTypeSerializer,
    dynamicTypeSerializer,
    voidTypeSerializer,
    bottomTypeSerializer,
    functionTypeSerializer,
    typeParameterTypeSerializer,
  ]);
  statementSerializer.tags.addAll([
    "expr",
  ]);
  statementSerializer.serializers.addAll([
    expressionStatementSerializer,
  ]);
}
