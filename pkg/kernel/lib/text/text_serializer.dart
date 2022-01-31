// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.text_serializer;

import '../ast.dart';

import 'serializer_combinators.dart';

abstract class Tagger<T> {
  String tag(T object);
}

class NameTagger implements Tagger<Name> {
  const NameTagger();

  @override
  String tag(Name name) => name.isPrivate ? "private" : "public";
}

TextSerializer<Name> publicName =
    Wrapped<String, Name>((w) => w.text, (u) => Name(u), const DartString());

TextSerializer<Name> privateName = Wrapped<Tuple2<String, CanonicalName>, Name>(
    (w) => Tuple2(w.text, w.library!.reference.canonicalName!),
    (u) => Name.byReference(u.first, u.second.reference),
    Tuple2Serializer(DartString(), CanonicalNameSerializer()));

TextSerializer<Name> nameSerializer = new Case(
    const NameTagger(), {"public": publicName, "private": privateName});

class ExpressionTagger extends ExpressionVisitor<String>
    implements Tagger<Expression> {
  const ExpressionTagger();

  @override
  String tag(Expression expression) => expression.accept(this);

  @override
  String visitStringLiteral(StringLiteral _) => "string";
  @override
  String visitIntLiteral(IntLiteral _) => "int";
  @override
  String visitDoubleLiteral(DoubleLiteral _) => "double";
  @override
  String visitBoolLiteral(BoolLiteral _) => "bool";
  @override
  String visitNullLiteral(NullLiteral _) => "null";
  @override
  String visitInvalidExpression(InvalidExpression _) => "invalid";
  @override
  String visitNot(Not _) => "not";
  @override
  String visitLogicalExpression(LogicalExpression expression) {
    return logicalExpressionOperatorToString(expression.operatorEnum);
  }

  @override
  String visitStringConcatenation(StringConcatenation _) => "concat";
  @override
  String visitSymbolLiteral(SymbolLiteral _) => "symbol";
  @override
  String visitThisExpression(ThisExpression _) => "this";
  @override
  String visitRethrow(Rethrow _) => "rethrow";
  @override
  String visitThrow(Throw _) => "throw";
  @override
  String visitAwaitExpression(AwaitExpression _) => "await";
  @override
  String visitConditionalExpression(ConditionalExpression _) => "cond";
  @override
  String visitIsExpression(IsExpression _) => "is";
  @override
  String visitAsExpression(AsExpression _) => "as";
  @override
  String visitTypeLiteral(TypeLiteral _) => "type";
  @override
  String visitListLiteral(ListLiteral expression) {
    return expression.isConst ? "const-list" : "list";
  }

  @override
  String visitSetLiteral(SetLiteral expression) {
    return expression.isConst ? "const-set" : "set";
  }

  @override
  String visitMapLiteral(MapLiteral expression) {
    return expression.isConst ? "const-map" : "map";
  }

  @override
  String visitLet(Let _) => "let";

  @override
  String visitInstanceGet(InstanceGet _) => "get-instance";
  @override
  String visitInstanceSet(InstanceSet _) => "set-instance";
  @override
  String visitDynamicGet(DynamicGet _) => "get-dynamic";
  @override
  String visitDynamicSet(DynamicSet _) => "set-dynamic";
  @override
  String visitInstanceTearOff(InstanceTearOff _) => "tearoff-instance";
  @override
  String visitFunctionTearOff(FunctionTearOff _) => "tearoff-function";
  @override
  String visitSuperPropertyGet(SuperPropertyGet _) => "get-super";
  @override
  String visitSuperPropertySet(SuperPropertySet _) => "set-super";
  @override
  String visitInstanceInvocation(InstanceInvocation _) => "invoke-instance";
  @override
  String visitInstanceGetterInvocation(InstanceGetterInvocation _) =>
      "invoke-instance-getter";
  @override
  String visitDynamicInvocation(DynamicInvocation _) => "invoke-dynamic";
  @override
  String visitFunctionInvocation(FunctionInvocation _) => "invoke-function";
  @override
  String visitLocalFunctionInvocation(LocalFunctionInvocation _) =>
      "invoke-local-function";
  @override
  String visitEqualsNull(EqualsNull _) => "equals-null";
  @override
  String visitEqualsCall(EqualsCall _) => "equals-call";
  @override
  String visitSuperMethodInvocation(SuperMethodInvocation _) => "invoke-super";

  @override
  String visitVariableGet(VariableGet _) => "get-var";
  @override
  String visitVariableSet(VariableSet _) => "set-var";
  @override
  String visitStaticGet(StaticGet _) => "get-static";
  @override
  String visitStaticSet(StaticSet _) => "set-static";
  @override
  String visitStaticTearOff(StaticTearOff _) => "tearoff-static";
  @override
  String visitConstructorTearOff(ConstructorTearOff _) => "tearoff-constructor";
  @override
  String visitRedirectingFactoryTearOff(RedirectingFactoryTearOff _) =>
      "tearoff-redirecting-factory";
  @override
  String visitTypedefTearOff(TypedefTearOff _) => "tearoff-typedef";
  @override
  String visitStaticInvocation(StaticInvocation expression) {
    return expression.isConst ? "invoke-const-static" : "invoke-static";
  }

  @override
  String visitConstructorInvocation(ConstructorInvocation expression) {
    return expression.isConst
        ? "invoke-const-constructor"
        : "invoke-constructor";
  }

  @override
  String visitFunctionExpression(FunctionExpression _) => "fun";
  @override
  String visitListConcatenation(ListConcatenation _) => "lists";
  @override
  String visitSetConcatenation(SetConcatenation _) => "sets";
  @override
  String visitMapConcatenation(MapConcatenation _) => "maps";
  @override
  String visitBlockExpression(BlockExpression _) => "let-block";
  @override
  String visitInstantiation(Instantiation _) => "apply";
  @override
  String visitNullCheck(NullCheck _) => "not-null";
  @override
  String visitFileUriExpression(FileUriExpression _) => "with-uri";
  @override
  String visitCheckLibraryIsLoaded(CheckLibraryIsLoaded _) => "is-loaded";
  @override
  String visitLoadLibrary(LoadLibrary _) => "load";
  @override
  String visitConstantExpression(ConstantExpression _) => "const";
  @override
  String visitInstanceCreation(InstanceCreation _) => "object";

  @override
  String defaultExpression(Expression node) {
    throw new UnimplementedError(
        'Unimplemented expression $node (${node.runtimeType})');
  }
}

TextSerializer<InvalidExpression> invalidExpressionSerializer =
    new Wrapped<Tuple2<String?, Expression?>, InvalidExpression>(
        unwrapInvalidExpression,
        wrapInvalidExpression,
        Tuple2Serializer<String?, Expression?>(
            Optional(DartString()), Optional(expressionSerializer)));

Tuple2<String?, Expression?> unwrapInvalidExpression(
    InvalidExpression expression) {
  return Tuple2(expression.message, expression.expression);
}

InvalidExpression wrapInvalidExpression(Tuple2<String?, Expression?> tuple) {
  return new InvalidExpression(tuple.first, tuple.second);
}

TextSerializer<Not> notSerializer =
    new Wrapped<Expression, Not>(unwrapNot, wrapNot, expressionSerializer);

Expression unwrapNot(Not expression) => expression.operand;

Not wrapNot(Expression operand) => new Not(operand);

TextSerializer<LogicalExpression> logicalAndSerializer =
    new Wrapped<Tuple2<Expression, Expression>, LogicalExpression>(
        unwrapLogicalExpression,
        wrapLogicalAnd,
        new Tuple2Serializer(expressionSerializer, expressionSerializer));

Tuple2<Expression, Expression> unwrapLogicalExpression(
    LogicalExpression expression) {
  return new Tuple2(expression.left, expression.right);
}

LogicalExpression wrapLogicalAnd(Tuple2<Expression, Expression> tuple) {
  return new LogicalExpression(
      tuple.first, LogicalExpressionOperator.AND, tuple.second);
}

TextSerializer<LogicalExpression> logicalOrSerializer =
    new Wrapped<Tuple2<Expression, Expression>, LogicalExpression>(
        unwrapLogicalExpression,
        wrapLogicalOr,
        new Tuple2Serializer(expressionSerializer, expressionSerializer));

LogicalExpression wrapLogicalOr(Tuple2<Expression, Expression> tuple) {
  return new LogicalExpression(
      tuple.first, LogicalExpressionOperator.OR, tuple.second);
}

TextSerializer<StringConcatenation> stringConcatenationSerializer =
    new Wrapped<List<Expression>, StringConcatenation>(
        unwrapStringConcatenation,
        wrapStringConcatenation,
        new ListSerializer(expressionSerializer));

List<Expression> unwrapStringConcatenation(StringConcatenation expression) {
  return expression.expressions;
}

StringConcatenation wrapStringConcatenation(List<Expression> expressions) {
  return new StringConcatenation(expressions);
}

const TextSerializer<StringLiteral> stringLiteralSerializer =
    const Wrapped<String, StringLiteral>(
        unwrapStringLiteral, wrapStringLiteral, const DartString());

String unwrapStringLiteral(StringLiteral literal) => literal.value;

StringLiteral wrapStringLiteral(String value) => new StringLiteral(value);

const TextSerializer<IntLiteral> intLiteralSerializer =
    const Wrapped<int, IntLiteral>(
        unwrapIntLiteral, wrapIntLiteral, const DartInt());

int unwrapIntLiteral(IntLiteral literal) => literal.value;

IntLiteral wrapIntLiteral(int value) => new IntLiteral(value);

const TextSerializer<DoubleLiteral> doubleLiteralSerializer =
    const Wrapped<double, DoubleLiteral>(
        unwrapDoubleLiteral, wrapDoubleLiteral, const DartDouble());

double unwrapDoubleLiteral(DoubleLiteral literal) => literal.value;

DoubleLiteral wrapDoubleLiteral(double value) => new DoubleLiteral(value);

const TextSerializer<BoolLiteral> boolLiteralSerializer =
    const Wrapped<bool, BoolLiteral>(
        unwrapBoolLiteral, wrapBoolLiteral, const DartBool());

bool unwrapBoolLiteral(BoolLiteral literal) => literal.value;

BoolLiteral wrapBoolLiteral(bool value) => new BoolLiteral(value);

const TextSerializer<NullLiteral> nullLiteralSerializer =
    const Wrapped<void, NullLiteral>(
        unwrapNullLiteral, wrapNullLiteral, const Nothing());

void unwrapNullLiteral(NullLiteral literal) {}

NullLiteral wrapNullLiteral(void ignored) => new NullLiteral();

const TextSerializer<SymbolLiteral> symbolLiteralSerializer =
    const Wrapped<String, SymbolLiteral>(
        unwrapSymbolLiteral, wrapSymbolLiteral, const DartString());

String unwrapSymbolLiteral(SymbolLiteral expression) => expression.value;

SymbolLiteral wrapSymbolLiteral(String value) => new SymbolLiteral(value);

const TextSerializer<ThisExpression> thisExpressionSerializer =
    const Wrapped<void, ThisExpression>(
        unwrapThisExpression, wrapThisExpression, const Nothing());

void unwrapThisExpression(ThisExpression expression) {}

ThisExpression wrapThisExpression(void ignored) => new ThisExpression();

const TextSerializer<Rethrow> rethrowSerializer =
    const Wrapped<void, Rethrow>(unwrapRethrow, wrapRethrow, const Nothing());

void unwrapRethrow(Rethrow expression) {}

Rethrow wrapRethrow(void ignored) => new Rethrow();

TextSerializer<Throw> throwSerializer = new Wrapped<Expression, Throw>(
    unwrapThrow, wrapThrow, expressionSerializer);

Expression unwrapThrow(Throw expression) => expression.expression;

Throw wrapThrow(Expression expression) => new Throw(expression);

TextSerializer<AwaitExpression> awaitExpressionSerializer =
    new Wrapped<Expression, AwaitExpression>(
        unwrapAwaitExpression, wrapAwaitExpression, expressionSerializer);

Expression unwrapAwaitExpression(AwaitExpression expression) =>
    expression.operand;

AwaitExpression wrapAwaitExpression(Expression operand) =>
    new AwaitExpression(operand);

TextSerializer<ConditionalExpression> conditionalExpressionSerializer =
    new Wrapped<Tuple4<Expression, DartType, Expression, Expression>,
            ConditionalExpression>(
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

TextSerializer<IsExpression> isExpressionSerializer =
    new Wrapped<Tuple2<Expression, DartType>, IsExpression>(
        unwrapIsExpression,
        wrapIsExpression,
        new Tuple2Serializer(expressionSerializer, dartTypeSerializer));

Tuple2<Expression, DartType> unwrapIsExpression(IsExpression expression) {
  return new Tuple2(expression.operand, expression.type);
}

IsExpression wrapIsExpression(Tuple2<Expression, DartType> tuple) {
  return new IsExpression(tuple.first, tuple.second);
}

TextSerializer<AsExpression> asExpressionSerializer =
    new Wrapped<Tuple2<Expression, DartType>, AsExpression>(
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
    new Wrapped<DartType, TypeLiteral>(
        unwrapTypeLiteral, wrapTypeLiteral, dartTypeSerializer);

DartType unwrapTypeLiteral(TypeLiteral expression) => expression.type;

TypeLiteral wrapTypeLiteral(DartType type) => new TypeLiteral(type);

TextSerializer<ListLiteral> listLiteralSerializer =
    new Wrapped<Tuple2<DartType, List<Expression>>, ListLiteral>(
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

TextSerializer<ListLiteral> constListLiteralSerializer =
    new Wrapped<Tuple2<DartType, List<Expression>>, ListLiteral>(
        unwrapListLiteral,
        wrapConstListLiteral,
        new Tuple2Serializer(
            dartTypeSerializer, new ListSerializer(expressionSerializer)));

ListLiteral wrapConstListLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new ListLiteral(tuple.second,
      typeArgument: tuple.first, isConst: true);
}

TextSerializer<SetLiteral> setLiteralSerializer =
    new Wrapped<Tuple2<DartType, List<Expression>>, SetLiteral>(
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

TextSerializer<SetLiteral> constSetLiteralSerializer =
    new Wrapped<Tuple2<DartType, List<Expression>>, SetLiteral>(
        unwrapSetLiteral,
        wrapConstSetLiteral,
        new Tuple2Serializer(
            dartTypeSerializer, new ListSerializer(expressionSerializer)));

SetLiteral wrapConstSetLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new SetLiteral(tuple.second, typeArgument: tuple.first, isConst: true);
}

TextSerializer<MapLiteral> mapLiteralSerializer =
    new Wrapped<Tuple3<DartType, DartType, List<Expression>>, MapLiteral>(
        unwrapMapLiteral,
        wrapMapLiteral,
        new Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
            new ListSerializer(expressionSerializer)));

Tuple3<DartType, DartType, List<Expression>> unwrapMapLiteral(
    MapLiteral expression) {
  List<Expression> entries =
      new List.filled(2 * expression.entries.length, dummyExpression);
  for (int from = 0, to = 0; from < expression.entries.length; ++from) {
    MapLiteralEntry entry = expression.entries[from];
    entries[to++] = entry.key;
    entries[to++] = entry.value;
  }
  return new Tuple3(expression.keyType, expression.valueType, entries);
}

MapLiteral wrapMapLiteral(Tuple3<DartType, DartType, List<Expression>> tuple) {
  List<MapLiteralEntry> entries =
      new List.filled(tuple.third.length ~/ 2, dummyMapLiteralEntry);
  for (int from = 0, to = 0; to < entries.length; ++to) {
    entries[to] = new MapLiteralEntry(tuple.third[from++], tuple.third[from++]);
  }
  return new MapLiteral(entries,
      keyType: tuple.first, valueType: tuple.second, isConst: false);
}

TextSerializer<MapLiteral> constMapLiteralSerializer =
    new Wrapped<Tuple3<DartType, DartType, List<Expression>>, MapLiteral>(
        unwrapMapLiteral,
        wrapConstMapLiteral,
        new Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
            new ListSerializer(expressionSerializer)));

MapLiteral wrapConstMapLiteral(
    Tuple3<DartType, DartType, List<Expression>> tuple) {
  List<MapLiteralEntry> entries =
      new List.filled(tuple.third.length ~/ 2, dummyMapLiteralEntry);
  for (int from = 0, to = 0; to < entries.length; ++to) {
    entries[to] = new MapLiteralEntry(tuple.third[from++], tuple.third[from++]);
  }
  return new MapLiteral(entries,
      keyType: tuple.first, valueType: tuple.second, isConst: true);
}

TextSerializer<Let> letSerializer =
    new Wrapped<Tuple2<VariableDeclaration, Expression>, Let>(unwrapLet,
        wrapLet, new Bind(variableDeclarationSerializer, expressionSerializer));

Tuple2<VariableDeclaration, Expression> unwrapLet(Let expression) {
  return new Tuple2(expression.variable, expression.body);
}

Let wrapLet(Tuple2<VariableDeclaration, Expression> tuple) {
  return new Let(tuple.first, tuple.second);
}

TextSerializer<InstanceGet> instanceGetSerializer = new Wrapped<
        Tuple5<InstanceAccessKind, Expression, Name, CanonicalName, DartType>,
        InstanceGet>(
    unwrapInstanceGet,
    wrapInstanceGet,
    new Tuple5Serializer(instanceAccessKindSerializer, expressionSerializer,
        nameSerializer, canonicalNameSerializer, dartTypeSerializer));

Tuple5<InstanceAccessKind, Expression, Name, CanonicalName, DartType>
    unwrapInstanceGet(InstanceGet expression) {
  return new Tuple5(
      expression.kind,
      expression.receiver,
      expression.name,
      expression.interfaceTargetReference.canonicalName!,
      expression.resultType);
}

InstanceGet wrapInstanceGet(
    Tuple5<InstanceAccessKind, Expression, Name, CanonicalName, DartType>
        tuple) {
  return new InstanceGet.byReference(tuple.first, tuple.second, tuple.third,
      interfaceTargetReference: tuple.fourth.reference,
      resultType: tuple.fifth);
}

TextSerializer<InstanceSet> instanceSetSerializer = new Wrapped<
        Tuple5<InstanceAccessKind, Expression, Name, Expression, CanonicalName>,
        InstanceSet>(
    unwrapInstanceSet,
    wrapInstanceSet,
    new Tuple5Serializer(instanceAccessKindSerializer, expressionSerializer,
        nameSerializer, expressionSerializer, canonicalNameSerializer));

Tuple5<InstanceAccessKind, Expression, Name, Expression, CanonicalName>
    unwrapInstanceSet(InstanceSet expression) {
  return new Tuple5(expression.kind, expression.receiver, expression.name,
      expression.value, expression.interfaceTargetReference.canonicalName!);
}

InstanceSet wrapInstanceSet(
    Tuple5<InstanceAccessKind, Expression, Name, Expression, CanonicalName>
        tuple) {
  return new InstanceSet.byReference(
      tuple.first, tuple.second, tuple.third, tuple.fourth,
      interfaceTargetReference: tuple.fifth.reference);
}

TextSerializer<DynamicGet> dynamicGetSerializer =
    new Wrapped<Tuple3<DynamicAccessKind, Expression, Name>, DynamicGet>(
        unwrapDynamicGet,
        wrapDynamicGet,
        new Tuple3Serializer(
            dynamicAccessKindSerializer, expressionSerializer, nameSerializer));

Tuple3<DynamicAccessKind, Expression, Name> unwrapDynamicGet(
    DynamicGet expression) {
  return new Tuple3(expression.kind, expression.receiver, expression.name);
}

DynamicGet wrapDynamicGet(Tuple3<DynamicAccessKind, Expression, Name> tuple) {
  return new DynamicGet(tuple.first, tuple.second, tuple.third);
}

TextSerializer<DynamicSet> dynamicSetSerializer = new Wrapped<
        Tuple4<DynamicAccessKind, Expression, Name, Expression>, DynamicSet>(
    unwrapDynamicSet,
    wrapDynamicSet,
    new Tuple4Serializer(dynamicAccessKindSerializer, expressionSerializer,
        nameSerializer, expressionSerializer));

Tuple4<DynamicAccessKind, Expression, Name, Expression> unwrapDynamicSet(
    DynamicSet expression) {
  return new Tuple4(
      expression.kind, expression.receiver, expression.name, expression.value);
}

DynamicSet wrapDynamicSet(
    Tuple4<DynamicAccessKind, Expression, Name, Expression> tuple) {
  return new DynamicSet(tuple.first, tuple.second, tuple.third, tuple.fourth);
}

TextSerializer<InstanceTearOff> instanceTearOffSerializer = new Wrapped<
        Tuple5<InstanceAccessKind, Expression, Name, CanonicalName, DartType>,
        InstanceTearOff>(
    unwrapInstanceTearOff,
    wrapInstanceTearOff,
    new Tuple5Serializer(instanceAccessKindSerializer, expressionSerializer,
        nameSerializer, canonicalNameSerializer, dartTypeSerializer));

Tuple5<InstanceAccessKind, Expression, Name, CanonicalName, DartType>
    unwrapInstanceTearOff(InstanceTearOff expression) {
  return new Tuple5(
      expression.kind,
      expression.receiver,
      expression.name,
      expression.interfaceTargetReference.canonicalName!,
      expression.resultType);
}

InstanceTearOff wrapInstanceTearOff(
    Tuple5<InstanceAccessKind, Expression, Name, CanonicalName, DartType>
        tuple) {
  return new InstanceTearOff.byReference(tuple.first, tuple.second, tuple.third,
      interfaceTargetReference: tuple.fourth.reference,
      resultType: tuple.fifth);
}

TextSerializer<FunctionTearOff> functionTearOffSerializer =
    new Wrapped<Expression, FunctionTearOff>(
        unwrapFunctionTearOff, wrapFunctionTearOff, expressionSerializer);

Expression unwrapFunctionTearOff(FunctionTearOff expression) {
  return expression.receiver;
}

FunctionTearOff wrapFunctionTearOff(Expression expression) {
  return new FunctionTearOff(expression);
}

TextSerializer<SuperPropertyGet> superPropertyGetSerializer =
    new Wrapped<Name, SuperPropertyGet>(
        unwrapSuperPropertyGet, wrapSuperPropertyGet, nameSerializer);

Name unwrapSuperPropertyGet(SuperPropertyGet expression) {
  return expression.name;
}

SuperPropertyGet wrapSuperPropertyGet(Name name) {
  return new SuperPropertyGet(name);
}

TextSerializer<SuperPropertySet> superPropertySetSerializer =
    new Wrapped<Tuple2<Name, Expression>, SuperPropertySet>(
        unwrapSuperPropertySet,
        wrapSuperPropertySet,
        new Tuple2Serializer(nameSerializer, expressionSerializer));

Tuple2<Name, Expression> unwrapSuperPropertySet(SuperPropertySet expression) {
  return new Tuple2(expression.name, expression.value);
}

SuperPropertySet wrapSuperPropertySet(Tuple2<Name, Expression> tuple) {
  return new SuperPropertySet(tuple.first, tuple.second, null);
}

const Map<InstanceAccessKind, String> instanceAccessKindToName = const {
  InstanceAccessKind.Instance: "instance",
  InstanceAccessKind.Object: "object",
  InstanceAccessKind.Nullable: "nullable",
  InstanceAccessKind.Inapplicable: "inapplicable",
};

class InstanceAccessKindTagger implements Tagger<InstanceAccessKind> {
  const InstanceAccessKindTagger();

  @override
  String tag(InstanceAccessKind kind) {
    return instanceAccessKindToName[kind] ??
        (throw StateError("Unknown InstanceAccessKind flag value: ${kind}."));
  }
}

TextSerializer<InstanceAccessKind> instanceAccessKindSerializer =
    Case(InstanceAccessKindTagger(), convertFlagsMap(instanceAccessKindToName));

TextSerializer<InstanceInvocation> instanceInvocationSerializer = new Wrapped<
        Tuple6<InstanceAccessKind, Expression, Name, Arguments, CanonicalName,
            DartType>,
        InstanceInvocation>(
    unwrapInstanceInvocation,
    wrapInstanceInvocation,
    new Tuple6Serializer(
        instanceAccessKindSerializer,
        expressionSerializer,
        nameSerializer,
        argumentsSerializer,
        canonicalNameSerializer,
        dartTypeSerializer));

Tuple6<InstanceAccessKind, Expression, Name, Arguments, CanonicalName, DartType>
    unwrapInstanceInvocation(InstanceInvocation expression) {
  return new Tuple6(
      expression.kind,
      expression.receiver,
      expression.name,
      expression.arguments,
      expression.interfaceTargetReference.canonicalName!,
      expression.functionType);
}

InstanceInvocation wrapInstanceInvocation(
    Tuple6<InstanceAccessKind, Expression, Name, Arguments, CanonicalName,
            DartType>
        tuple) {
  return new InstanceInvocation.byReference(
      tuple.first, tuple.second, tuple.third, tuple.fourth,
      interfaceTargetReference: tuple.fifth.reference,
      functionType: tuple.sixth as FunctionType);
}

TextSerializer<
    InstanceGetterInvocation> instanceGetterInvocationSerializer = new Wrapped<
        Tuple6<InstanceAccessKind, Expression, Name, Arguments, CanonicalName,
            DartType?>,
        InstanceGetterInvocation>(
    unwrapInstanceGetterInvocation,
    wrapInstanceGetterInvocation,
    new Tuple6Serializer(
        instanceAccessKindSerializer,
        expressionSerializer,
        nameSerializer,
        argumentsSerializer,
        const CanonicalNameSerializer(),
        Optional(dartTypeSerializer)));

Tuple6<InstanceAccessKind, Expression, Name, Arguments, CanonicalName,
        DartType?>
    unwrapInstanceGetterInvocation(InstanceGetterInvocation expression) {
  return new Tuple6(
      expression.kind,
      expression.receiver,
      expression.name,
      expression.arguments,
      expression.interfaceTargetReference.canonicalName!,
      expression.functionType);
}

InstanceGetterInvocation wrapInstanceGetterInvocation(
    Tuple6<InstanceAccessKind, Expression, Name, Arguments, CanonicalName,
            DartType?>
        tuple) {
  return new InstanceGetterInvocation.byReference(
      tuple.first, tuple.second, tuple.third, tuple.fourth,
      interfaceTargetReference: tuple.fifth.reference,
      functionType: tuple.sixth as FunctionType?);
}

const Map<DynamicAccessKind, String> dynamicAccessKindToName = const {
  DynamicAccessKind.Dynamic: "dynamic",
  DynamicAccessKind.Never: "never",
  DynamicAccessKind.Invalid: "invalid",
  DynamicAccessKind.Unresolved: "unresolved",
};

class DynamicAccessKindTagger implements Tagger<DynamicAccessKind> {
  const DynamicAccessKindTagger();

  @override
  String tag(DynamicAccessKind kind) {
    return dynamicAccessKindToName[kind] ??
        (throw StateError("Unknown DynamicAccessKind flag value: ${kind}."));
  }
}

TextSerializer<DynamicAccessKind> dynamicAccessKindSerializer =
    Case(DynamicAccessKindTagger(), convertFlagsMap(dynamicAccessKindToName));

TextSerializer<DynamicInvocation> dynamicInvocationSerializer = new Wrapped<
        Tuple4<DynamicAccessKind, Expression, Name, Arguments>,
        DynamicInvocation>(
    unwrapDynamicInvocation,
    wrapDynamicInvocation,
    new Tuple4Serializer(dynamicAccessKindSerializer, expressionSerializer,
        nameSerializer, argumentsSerializer));

Tuple4<DynamicAccessKind, Expression, Name, Arguments> unwrapDynamicInvocation(
    DynamicInvocation expression) {
  return new Tuple4(expression.kind, expression.receiver, expression.name,
      expression.arguments);
}

DynamicInvocation wrapDynamicInvocation(
    Tuple4<DynamicAccessKind, Expression, Name, Arguments> tuple) {
  return new DynamicInvocation(
      tuple.first, tuple.second, tuple.third, tuple.fourth);
}

const Map<FunctionAccessKind, String> functionAccessKindToName = const {
  FunctionAccessKind.Function: "function",
  FunctionAccessKind.FunctionType: "function-type",
  FunctionAccessKind.Inapplicable: "inapplicable",
  FunctionAccessKind.Nullable: "nullable",
};

class FunctionAccessKindTagger implements Tagger<FunctionAccessKind> {
  const FunctionAccessKindTagger();

  @override
  String tag(FunctionAccessKind kind) {
    return functionAccessKindToName[kind] ??
        (throw StateError("Unknown FunctionAccessKind flag value: ${kind}."));
  }
}

TextSerializer<FunctionAccessKind> functionAccessKindSerializer =
    Case(FunctionAccessKindTagger(), convertFlagsMap(functionAccessKindToName));

TextSerializer<FunctionInvocation> functionInvocationSerializer = new Wrapped<
        Tuple4<FunctionAccessKind, Expression, Arguments, DartType?>,
        FunctionInvocation>(
    unwrapFunctionInvocation,
    wrapFunctionInvocation,
    new Tuple4Serializer(functionAccessKindSerializer, expressionSerializer,
        argumentsSerializer, new Optional(dartTypeSerializer)));

Tuple4<FunctionAccessKind, Expression, Arguments, DartType?>
    unwrapFunctionInvocation(FunctionInvocation expression) {
  return new Tuple4(expression.kind, expression.receiver, expression.arguments,
      expression.functionType);
}

FunctionInvocation wrapFunctionInvocation(
    Tuple4<FunctionAccessKind, Expression, Arguments, DartType?> tuple) {
  return new FunctionInvocation(tuple.first, tuple.second, tuple.third,
      functionType: tuple.fourth as FunctionType?);
}

TextSerializer<LocalFunctionInvocation> localFunctionInvocationSerializer =
    new Wrapped<Tuple3<VariableDeclaration, Arguments, DartType>,
            LocalFunctionInvocation>(
        unwrapLocalFunctionInvocation,
        wrapLocalFunctionInvocation,
        new Tuple3Serializer(const ScopedUse<VariableDeclaration>(),
            argumentsSerializer, dartTypeSerializer));

Tuple3<VariableDeclaration, Arguments, DartType> unwrapLocalFunctionInvocation(
    LocalFunctionInvocation expression) {
  return new Tuple3(
      expression.variable, expression.arguments, expression.functionType);
}

LocalFunctionInvocation wrapLocalFunctionInvocation(
    Tuple3<VariableDeclaration, Arguments, DartType> tuple) {
  return new LocalFunctionInvocation(tuple.first, tuple.second,
      functionType: tuple.third as FunctionType);
}

TextSerializer<EqualsNull> equalsNullSerializer =
    new Wrapped<Expression, EqualsNull>(
        unwrapEqualsNull, wrapEqualsNull, expressionSerializer);

Expression unwrapEqualsNull(EqualsNull expression) {
  return expression.expression;
}

EqualsNull wrapEqualsNull(Expression expression) {
  return new EqualsNull(expression);
}

TextSerializer<EqualsCall> equalsCallSerializer = new Wrapped<
        Tuple4<Expression, Expression, CanonicalName, DartType>, EqualsCall>(
    unwrapEqualsCall,
    wrapEqualsCall,
    new Tuple4Serializer(expressionSerializer, expressionSerializer,
        canonicalNameSerializer, dartTypeSerializer));

Tuple4<Expression, Expression, CanonicalName, DartType> unwrapEqualsCall(
    EqualsCall expression) {
  return new Tuple4(
      expression.left,
      expression.right,
      expression.interfaceTargetReference.canonicalName!,
      expression.functionType);
}

EqualsCall wrapEqualsCall(
    Tuple4<Expression, Expression, CanonicalName, DartType> tuple) {
  return new EqualsCall.byReference(tuple.first, tuple.second,
      interfaceTargetReference: tuple.third.reference,
      functionType: tuple.fourth as FunctionType);
}

TextSerializer<SuperMethodInvocation> superMethodInvocationSerializer =
    new Wrapped<Tuple2<Name, Arguments>, SuperMethodInvocation>(
        unwrapSuperMethodInvocation,
        wrapSuperMethodInvocation,
        new Tuple2Serializer(nameSerializer, argumentsSerializer));

Tuple2<Name, Arguments> unwrapSuperMethodInvocation(
    SuperMethodInvocation expression) {
  return new Tuple2(expression.name, expression.arguments);
}

SuperMethodInvocation wrapSuperMethodInvocation(Tuple2<Name, Arguments> tuple) {
  return new SuperMethodInvocation(tuple.first, tuple.second);
}

TextSerializer<VariableGet> variableGetSerializer =
    new Wrapped<Tuple2<VariableDeclaration, DartType?>, VariableGet>(
        unwrapVariableGet,
        wrapVariableGet,
        new Tuple2Serializer(const ScopedUse<VariableDeclaration>(),
            new Optional(dartTypeSerializer)));

Tuple2<VariableDeclaration, DartType?> unwrapVariableGet(VariableGet node) {
  return new Tuple2<VariableDeclaration, DartType?>(
      node.variable, node.promotedType);
}

VariableGet wrapVariableGet(Tuple2<VariableDeclaration, DartType?> tuple) {
  return new VariableGet(tuple.first, tuple.second);
}

TextSerializer<VariableSet> variableSetSerializer =
    new Wrapped<Tuple2<VariableDeclaration, Expression>, VariableSet>(
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

const CanonicalNameSerializer canonicalNameSerializer =
    const CanonicalNameSerializer();

class CanonicalNameSerializer extends TextSerializer<CanonicalName> {
  static const String delimiter = "::";

  const CanonicalNameSerializer();

  static void writeName(CanonicalName name, StringBuffer buffer) {
    if (!name.isRoot) {
      if (!name.parent!.isRoot) {
        writeName(name.parent!, buffer);
        buffer.write(delimiter);
      }
      buffer.write(name.name);
    }
  }

  @override
  CanonicalName readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    if (state == null) {
      throw StateError(
          "No deserialization state provided for ${runtimeType}.readFrom.");
    }
    String string = const DartString().readFrom(stream, state);
    CanonicalName name = state.nameRoot;
    for (String s in string.split(delimiter)) {
      name = name.getChild(s);
    }
    return name;
  }

  @override
  void writeTo(
      StringBuffer buffer, CanonicalName name, SerializationState? state) {
    StringBuffer sb = new StringBuffer();
    writeName(name, sb);
    const DartString().writeTo(buffer, sb.toString(), state);
  }
}

const TextSerializer<StaticGet> staticGetSerializer =
    const Wrapped(unwrapStaticGet, wrapStaticGet, canonicalNameSerializer);

CanonicalName unwrapStaticGet(StaticGet expression) {
  return expression.targetReference.canonicalName!;
}

StaticGet wrapStaticGet(CanonicalName name) {
  return new StaticGet.byReference(name.reference);
}

const TextSerializer<StaticTearOff> staticTearOffSerializer =
    const Wrapped<CanonicalName, StaticTearOff>(
        unwrapStaticTearOff, wrapStaticTearOff, canonicalNameSerializer);

CanonicalName unwrapStaticTearOff(StaticTearOff expression) {
  return expression.targetReference.canonicalName!;
}

StaticTearOff wrapStaticTearOff(CanonicalName name) {
  return new StaticTearOff.byReference(name.reference);
}

const TextSerializer<ConstructorTearOff> constructorTearOffSerializer =
    const Wrapped<CanonicalName, ConstructorTearOff>(unwrapConstructorTearOff,
        wrapConstructorTearOff, canonicalNameSerializer);

CanonicalName unwrapConstructorTearOff(ConstructorTearOff expression) {
  return expression.targetReference.canonicalName!;
}

ConstructorTearOff wrapConstructorTearOff(CanonicalName name) {
  return new ConstructorTearOff.byReference(name.reference);
}

const TextSerializer<RedirectingFactoryTearOff>
    redirectingFactoryTearOffSerializer =
    const Wrapped<CanonicalName, RedirectingFactoryTearOff>(
        unwrapRedirectingFactoryTearOff,
        wrapRedirectingFactoryTearOff,
        canonicalNameSerializer);

CanonicalName unwrapRedirectingFactoryTearOff(
    RedirectingFactoryTearOff expression) {
  return expression.targetReference.canonicalName!;
}

RedirectingFactoryTearOff wrapRedirectingFactoryTearOff(CanonicalName name) {
  return new RedirectingFactoryTearOff.byReference(name.reference);
}

final TextSerializer<TypedefTearOff> typedefTearOffSerializer = new Wrapped<
        Tuple2<List<TypeParameter>, Tuple2<Expression, List<DartType>>>,
        TypedefTearOff>(
    unwrapTypedefTearOff,
    wrapTypedefTearOff,
    Bind(
        typeParametersSerializer,
        Tuple2Serializer(
            expressionSerializer, ListSerializer(dartTypeSerializer))));

Tuple2<List<TypeParameter>, Tuple2<Expression, List<DartType>>>
    unwrapTypedefTearOff(TypedefTearOff node) {
  return new Tuple2(
      node.typeParameters, new Tuple2(node.expression, node.typeArguments));
}

TypedefTearOff wrapTypedefTearOff(
    Tuple2<List<TypeParameter>, Tuple2<Expression, List<DartType>>> tuple) {
  return new TypedefTearOff(
      tuple.first, tuple.second.first, tuple.second.second);
}

TextSerializer<StaticSet> staticSetSerializer =
    new Wrapped<Tuple2<CanonicalName, Expression>, StaticSet>(
        unwrapStaticSet,
        wrapStaticSet,
        new Tuple2Serializer(canonicalNameSerializer, expressionSerializer));

Tuple2<CanonicalName, Expression> unwrapStaticSet(StaticSet expression) {
  return new Tuple2(
      expression.targetReference.canonicalName!, expression.value);
}

StaticSet wrapStaticSet(Tuple2<CanonicalName, Expression> tuple) {
  return new StaticSet.byReference(tuple.first.reference, tuple.second);
}

TextSerializer<StaticInvocation> staticInvocationSerializer =
    new Wrapped<Tuple2<CanonicalName, Arguments>, StaticInvocation>(
        unwrapStaticInvocation,
        wrapStaticInvocation,
        new Tuple2Serializer(canonicalNameSerializer, argumentsSerializer));

Tuple2<CanonicalName, Arguments> unwrapStaticInvocation(
    StaticInvocation expression) {
  return new Tuple2(
      expression.targetReference.canonicalName!, expression.arguments);
}

StaticInvocation wrapStaticInvocation(Tuple2<CanonicalName, Arguments> tuple) {
  return new StaticInvocation.byReference(tuple.first.reference, tuple.second,
      isConst: false);
}

TextSerializer<StaticInvocation> constStaticInvocationSerializer =
    new Wrapped<Tuple2<CanonicalName, Arguments>, StaticInvocation>(
        unwrapStaticInvocation,
        wrapConstStaticInvocation,
        new Tuple2Serializer(canonicalNameSerializer, argumentsSerializer));

StaticInvocation wrapConstStaticInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new StaticInvocation.byReference(tuple.first.reference, tuple.second,
      isConst: true);
}

TextSerializer<ConstructorInvocation> constructorInvocationSerializer =
    new Wrapped<Tuple2<CanonicalName, Arguments>, ConstructorInvocation>(
        unwrapConstructorInvocation,
        wrapConstructorInvocation,
        new Tuple2Serializer(canonicalNameSerializer, argumentsSerializer));

Tuple2<CanonicalName, Arguments> unwrapConstructorInvocation(
    ConstructorInvocation expression) {
  return new Tuple2(
      expression.targetReference.canonicalName!, expression.arguments);
}

ConstructorInvocation wrapConstructorInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new ConstructorInvocation.byReference(
      tuple.first.reference, tuple.second,
      isConst: false);
}

TextSerializer<ConstructorInvocation> constConstructorInvocationSerializer =
    new Wrapped<Tuple2<CanonicalName, Arguments>, ConstructorInvocation>(
        unwrapConstructorInvocation,
        wrapConstConstructorInvocation,
        Tuple2Serializer(canonicalNameSerializer, argumentsSerializer));

ConstructorInvocation wrapConstConstructorInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new ConstructorInvocation.byReference(
      tuple.first.reference, tuple.second,
      isConst: true);
}

TextSerializer<FunctionExpression> functionExpressionSerializer =
    new Wrapped<FunctionNode, FunctionExpression>(unwrapFunctionExpression,
        wrapFunctionExpression, functionNodeSerializer);

FunctionNode unwrapFunctionExpression(FunctionExpression expression) {
  return expression.function;
}

FunctionExpression wrapFunctionExpression(FunctionNode node) {
  return new FunctionExpression(node);
}

TextSerializer<ListConcatenation> listConcatenationSerializer =
    Wrapped<Tuple2<DartType, List<Expression>>, ListConcatenation>(
        (lc) => Tuple2(lc.typeArgument, lc.lists),
        (t) => ListConcatenation(t.second, typeArgument: t.first),
        Tuple2Serializer(
            dartTypeSerializer, ListSerializer(expressionSerializer)));

TextSerializer<SetConcatenation> setConcatenationSerializer =
    Wrapped<Tuple2<DartType, List<Expression>>, SetConcatenation>(
        (sc) => Tuple2(sc.typeArgument, sc.sets),
        (t) => SetConcatenation(t.second, typeArgument: t.first),
        Tuple2Serializer(
            dartTypeSerializer, ListSerializer(expressionSerializer)));

TextSerializer<MapConcatenation> mapConcatenationSerializer =
    Wrapped<Tuple3<DartType, DartType, List<Expression>>, MapConcatenation>(
        (mc) => Tuple3(mc.keyType, mc.valueType, mc.maps),
        (t) => MapConcatenation(t.third, keyType: t.first, valueType: t.second),
        Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
            ListSerializer(expressionSerializer)));

TextSerializer<BlockExpression> blockExpressionSerializer =
    Wrapped<Tuple2<List<Statement>, Expression?>, BlockExpression>(
        (w) => Tuple2(w.body.statements, w.value),
        (u) => BlockExpression(Block(u.first), u.second!),
        const BlockSerializer());

TextSerializer<Instantiation> instantiationSerializer =
    Wrapped<Tuple2<Expression, List<DartType>>, Instantiation>(
        (i) => Tuple2(i.expression, i.typeArguments),
        (t) => Instantiation(t.first, t.second),
        Tuple2Serializer(
            expressionSerializer, ListSerializer(dartTypeSerializer)));

TextSerializer<NullCheck> nullCheckSerializer = Wrapped<Expression, NullCheck>(
    (nc) => nc.operand, (op) => NullCheck(op), expressionSerializer);

TextSerializer<FileUriExpression> fileUriExpressionSerializer =
    Wrapped<Tuple2<Expression, Uri>, FileUriExpression>(
        (fue) => Tuple2(fue.expression, fue.fileUri),
        (t) => FileUriExpression(t.first, t.second),
        Tuple2Serializer(expressionSerializer, const UriSerializer()));

TextSerializer<CheckLibraryIsLoaded> checkLibraryIsLoadedSerializer =
    Wrapped<LibraryDependency, CheckLibraryIsLoaded>((clil) => clil.import,
        (i) => CheckLibraryIsLoaded(i), libraryDependencySerializer);

TextSerializer<LoadLibrary> loadLibrarySerializer =
    Wrapped<LibraryDependency, LoadLibrary>(
        (ll) => ll.import, (i) => LoadLibrary(i), libraryDependencySerializer);

TextSerializer<ConstantExpression> constantExpressionSerializer =
    Wrapped<Tuple2<Constant, DartType>, ConstantExpression>(
        (ce) => Tuple2(ce.constant, ce.type),
        (t) => ConstantExpression(t.first, t.second),
        Tuple2Serializer(constantSerializer, dartTypeSerializer));

TextSerializer<InstanceCreation> instanceCreationSerializer = Wrapped<
        Tuple6<CanonicalName, List<DartType>, List<CanonicalName>,
            List<Expression>, List<AssertStatement>, List<Expression>>,
        InstanceCreation>(
    (ic) => Tuple6(
        ic.classReference.canonicalName!,
        ic.typeArguments,
        ic.fieldValues.keys.map((r) => r.canonicalName!).toList(),
        ic.fieldValues.values.toList(),
        ic.asserts,
        ic.unusedArguments),
    (t) => InstanceCreation(
        t.first.reference,
        t.second,
        Map.fromIterables(t.third.map((cn) => cn.reference), t.fourth),
        t.fifth,
        t.sixth),
    Tuple6Serializer(
        CanonicalNameSerializer(),
        ListSerializer(dartTypeSerializer),
        ListSerializer(CanonicalNameSerializer()),
        ListSerializer(expressionSerializer),
        ListSerializer(assertStatementSerializer),
        ListSerializer(expressionSerializer)));

Case<Expression> expressionSerializer =
    new Case.uninitialized(const ExpressionTagger());

TextSerializer<Expression?> nullableExpressionSerializer =
    new Optional(expressionSerializer);

TextSerializer<NamedExpression> namedExpressionSerializer =
    new Wrapped<Tuple2<String, Expression>, NamedExpression>(
        unwrapNamedExpression,
        wrapNamedExpression,
        new Tuple2Serializer(const DartString(), expressionSerializer));

Tuple2<String, Expression> unwrapNamedExpression(NamedExpression expression) {
  return new Tuple2(expression.name, expression.value);
}

NamedExpression wrapNamedExpression(Tuple2<String, Expression> tuple) {
  return new NamedExpression(tuple.first, tuple.second);
}

TextSerializer<Arguments> argumentsSerializer = new Wrapped<
        Tuple3<List<DartType>, List<Expression>, List<NamedExpression>>,
        Arguments>(
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

const Map<int, String> variableDeclarationFlagToName = const {
  VariableDeclaration.FlagFinal: "final",
  VariableDeclaration.FlagConst: "const",
  VariableDeclaration.FlagInitializingFormal: "field-formal",
  VariableDeclaration.FlagCovariantByDeclaration: "covariant",
  VariableDeclaration.FlagCovariantByClass: "generic-covariant-impl",
  VariableDeclaration.FlagLate: "late",
  VariableDeclaration.FlagRequired: "required",
  VariableDeclaration.FlagLowered: "lowered",
};

class VariableDeclarationFlagTagger implements Tagger<int> {
  @override
  String tag(int flag) {
    return variableDeclarationFlagToName[flag] ??
        (throw StateError("Unknown VariableDeclaration flag value: ${flag}."));
  }
}

TextSerializer<int> variableDeclarationFlagsSerializer =
    Wrapped<List<int>, int>(
        (w) => List.generate(30, (i) => w & (1 << i))
            .where((f) => f != 0)
            .toList(),
        (u) => u.fold(0, (fs, f) => fs |= f),
        ListSerializer(Case(VariableDeclarationFlagTagger(),
            convertFlagsMap(variableDeclarationFlagToName))));

TextSerializer<VariableDeclaration> variableDeclarationSerializer =
    Wrapped<Tuple2<String?, VariableDeclaration>, VariableDeclaration>(
        (v) => Tuple2(v.name, v),
        (t) => t.second..name = t.first,
        Binder<VariableDeclaration>(
          new Wrapped<Tuple4<int, DartType, Expression?, List<Expression>>,
                  VariableDeclaration>(
              (w) => Tuple4(w.flags, w.type, w.initializer, w.annotations),
              (u) => u.fourth.fold(
                  VariableDeclaration(null,
                      flags: u.first, type: u.second, initializer: u.third),
                  (v, a) => v..addAnnotation(a)),
              Tuple4Serializer(
                  variableDeclarationFlagsSerializer,
                  dartTypeSerializer,
                  new Optional(expressionSerializer),
                  new ListSerializer(expressionSerializer))),
        ));

TextSerializer<TypeParameter> typeParameterSerializer =
    Wrapped<Tuple2<String?, TypeParameter>, TypeParameter>(
        (p) => Tuple2(p.name, p),
        (t) => t.second..name = t.first,
        Binder<TypeParameter>(Wrapped<void, TypeParameter>(
            (_) => null, (_) => TypeParameter(), const Nothing())));

TextSerializer<List<TypeParameter>> typeParametersSerializer = new Zip(
    new Rebind(
        new Zip(
            new Rebind(new ListSerializer(typeParameterSerializer),
                new ListSerializer(dartTypeSerializer)),
            zipTypeParameterBound,
            unzipTypeParameterBound),
        new ListSerializer(dartTypeSerializer)),
    zipTypeParameterDefaultType,
    unzipTypeParameterDefaultType);

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

  @override
  String tag(DartType type) => type.accept(this);

  @override
  String visitInvalidType(InvalidType _) => "invalid";
  @override
  String visitDynamicType(DynamicType _) => "dynamic";
  @override
  String visitVoidType(VoidType _) => "void";
  @override
  String visitFunctionType(FunctionType _) => "->";
  @override
  String visitTypeParameterType(TypeParameterType _) => "par";
  @override
  String visitInterfaceType(InterfaceType _) => "interface";
  @override
  String visitNeverType(NeverType _) => "never";
  @override
  String visitTypedefType(TypedefType _) => "typedef";
  @override
  String visitFutureOrType(FutureOrType _) => "futureor";
  @override
  String visitNullType(NullType _) => "null-type";

  @override
  String defaultDartType(DartType node) {
    throw UnimplementedError('Unimplemented type $node (${node.runtimeType})');
  }
}

const TextSerializer<InvalidType> invalidTypeSerializer =
    const Wrapped<void, InvalidType>(
        unwrapInvalidType, wrapInvalidType, const Nothing());

void unwrapInvalidType(InvalidType type) {}

InvalidType wrapInvalidType(void ignored) => const InvalidType();

const TextSerializer<DynamicType> dynamicTypeSerializer =
    const Wrapped<void, DynamicType>(
        unwrapDynamicType, wrapDynamicType, const Nothing());

void unwrapDynamicType(DynamicType type) {}

DynamicType wrapDynamicType(void ignored) => const DynamicType();

const TextSerializer<VoidType> voidTypeSerializer =
    const Wrapped<void, VoidType>(
        unwrapVoidType, wrapVoidType, const Nothing());

void unwrapVoidType(VoidType type) {}

VoidType wrapVoidType(void ignored) => const VoidType();

const TextSerializer<NeverType> neverTypeSerializer =
    const Wrapped<void, NeverType>(
        unwrapNeverType, wrapNeverType, const Nothing());

void unwrapNeverType(NeverType type) {}

NeverType wrapNeverType(void ignored) => const NeverType.legacy();

// TODO(dmitryas):  Also handle nameParameters, and typedefType.
TextSerializer<FunctionType> functionTypeSerializer = new Wrapped<
        Tuple2<List<TypeParameter>,
            Tuple4<List<DartType>, List<DartType>, List<NamedType>, DartType>>,
        FunctionType>(
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
  return new FunctionType(tuple.second.first + tuple.second.second,
      tuple.second.fourth, Nullability.legacy,
      requiredParameterCount: tuple.second.first.length,
      typeParameters: tuple.first,
      namedParameters: tuple.second.third);
}

TextSerializer<NamedType> namedTypeSerializer =
    new Wrapped<Tuple2<String, DartType>, NamedType>(
        unwrapNamedType,
        wrapNamedType,
        Tuple2Serializer(const DartString(), dartTypeSerializer));

Tuple2<String, DartType> unwrapNamedType(NamedType namedType) {
  return new Tuple2(namedType.name, namedType.type);
}

NamedType wrapNamedType(Tuple2<String, DartType> tuple) {
  return new NamedType(tuple.first, tuple.second);
}

TextSerializer<TypeParameterType> typeParameterTypeSerializer =
    new Wrapped<Tuple2<TypeParameter, DartType?>, TypeParameterType>(
        unwrapTypeParameterType,
        wrapTypeParameterType,
        Tuple2Serializer(
            new ScopedUse<TypeParameter>(), new Optional(dartTypeSerializer)));

Tuple2<TypeParameter, DartType?> unwrapTypeParameterType(
    TypeParameterType node) {
  return new Tuple2(node.parameter, node.promotedBound);
}

TypeParameterType wrapTypeParameterType(
    Tuple2<TypeParameter, DartType?> tuple) {
  return new TypeParameterType(tuple.first, Nullability.legacy, tuple.second);
}

TextSerializer<InterfaceType> interfaceTypeSerializer =
    new Wrapped<Tuple2<CanonicalName, List<DartType>>, InterfaceType>(
        unwrapInterfaceType,
        wrapInterfaceType,
        Tuple2Serializer(
            canonicalNameSerializer, new ListSerializer(dartTypeSerializer)));

Tuple2<CanonicalName, List<DartType>> unwrapInterfaceType(InterfaceType node) {
  return new Tuple2(node.className.canonicalName!, node.typeArguments);
}

InterfaceType wrapInterfaceType(Tuple2<CanonicalName, List<DartType>> tuple) {
  return new InterfaceType.byReference(
      tuple.first.reference, Nullability.legacy, tuple.second);
}

TextSerializer<TypedefType> typedefTypeSerializer =
    new Wrapped<Tuple2<CanonicalName, List<DartType>>, TypedefType>(
        unwrapTypedefType,
        wrapTypedefType,
        Tuple2Serializer(
            canonicalNameSerializer, new ListSerializer(dartTypeSerializer)));

Tuple2<CanonicalName, List<DartType>> unwrapTypedefType(TypedefType node) {
  return new Tuple2(node.typedefReference.canonicalName!, node.typeArguments);
}

TypedefType wrapTypedefType(Tuple2<CanonicalName, List<DartType>> tuple) {
  return new TypedefType.byReference(
      tuple.first.reference, Nullability.legacy, tuple.second);
}

TextSerializer<FutureOrType> futureOrTypeSerializer =
    new Wrapped<DartType, FutureOrType>(
        unwrapFutureOrType, wrapFutureOrType, dartTypeSerializer);

DartType unwrapFutureOrType(FutureOrType node) {
  return node.typeArgument;
}

FutureOrType wrapFutureOrType(DartType typeArgument) {
  return new FutureOrType(typeArgument, Nullability.legacy);
}

TextSerializer<NullType> nullTypeSerializer =
    new Wrapped<void, NullType>(unwrapNullType, wrapNullType, const Nothing());

void unwrapNullType(NullType type) {}

NullType wrapNullType(void ignored) => const NullType();

Case<DartType> dartTypeSerializer =
    new Case.uninitialized(const DartTypeTagger());

class StatementTagger extends StatementVisitor<String>
    implements Tagger<Statement> {
  const StatementTagger();

  @override
  String tag(Statement statement) => statement.accept(this);

  @override
  String visitExpressionStatement(ExpressionStatement _) => "expr";
  @override
  String visitReturnStatement(ReturnStatement node) {
    return node.expression == null ? "ret-void" : "ret";
  }

  @override
  String visitYieldStatement(YieldStatement _) => "yield";
  @override
  String visitBlock(Block _) => "block";
  @override
  String visitVariableDeclaration(VariableDeclaration _) => "local";
  @override
  String visitIfStatement(IfStatement node) {
    return node.otherwise == null ? "if" : "if-else";
  }

  @override
  String visitEmptyStatement(EmptyStatement node) => "skip";
  @override
  String visitWhileStatement(WhileStatement node) => "while";
  @override
  String visitDoStatement(DoStatement node) => "do-while";
  @override
  String visitForStatement(ForStatement node) => "for";
  @override
  String visitForInStatement(ForInStatement node) {
    return node.isAsync ? "await-for-in" : "for-in";
  }

  @override
  String visitAssertStatement(AssertStatement node) => "assert";
  @override
  String visitAssertBlock(AssertBlock node) => "assert-block";
  @override
  String visitLabeledStatement(LabeledStatement node) => "label";
  @override
  String visitBreakStatement(BreakStatement node) => "break";
  @override
  String visitTryFinally(TryFinally node) => "try-finally";
  @override
  String visitTryCatch(TryCatch node) => "try-catch";
  @override
  String visitSwitchStatement(SwitchStatement node) => "switch";
  @override
  String visitContinueSwitchStatement(ContinueSwitchStatement node) =>
      "continue";
  @override
  String visitFunctionDeclaration(FunctionDeclaration node) => "local-fun";

  @override
  String defaultStatement(Statement node) {
    throw new UnimplementedError(
        "Unimplemented statement $node (${node.runtimeType})");
  }
}

TextSerializer<ExpressionStatement> expressionStatementSerializer =
    new Wrapped<Expression, ExpressionStatement>(unwrapExpressionStatement,
        wrapExpressionStatement, expressionSerializer);

Expression unwrapExpressionStatement(ExpressionStatement statement) {
  return statement.expression;
}

ExpressionStatement wrapExpressionStatement(Expression expression) {
  return new ExpressionStatement(expression);
}

TextSerializer<ReturnStatement> returnStatementSerializer =
    new Wrapped<Expression?, ReturnStatement>(
        unwrapReturnStatement, wrapReturnStatement, expressionSerializer);

Expression? unwrapReturnStatement(ReturnStatement statement) {
  return statement.expression;
}

ReturnStatement wrapReturnStatement(Expression? expression) {
  return new ReturnStatement(expression);
}

TextSerializer<ReturnStatement> returnVoidStatementSerializer =
    new Wrapped<void, ReturnStatement>(
        unwrapReturnVoidStatement, wrapReturnVoidStatement, const Nothing());

void unwrapReturnVoidStatement(void ignored) {}

ReturnStatement wrapReturnVoidStatement(void ignored) => new ReturnStatement();

TextSerializer<YieldStatement> yieldStatementSerializer =
    new Wrapped<Expression, YieldStatement>(
        unwrapYieldStatement, wrapYieldStatement, expressionSerializer);

Expression unwrapYieldStatement(YieldStatement node) => node.expression;

YieldStatement wrapYieldStatement(Expression expression) {
  return new YieldStatement(expression);
}

TextSerializer<AssertStatement> assertStatementSerializer =
    Wrapped<Tuple4<Expression, Expression?, int, int>, AssertStatement>(
        (a) => Tuple4(a.condition, a.message, a.conditionStartOffset,
            a.conditionEndOffset),
        (t) => AssertStatement(t.first,
            message: t.second,
            conditionStartOffset: t.third,
            conditionEndOffset: t.fourth),
        Tuple4Serializer(expressionSerializer, nullableExpressionSerializer,
            const DartInt(), const DartInt()));

TextSerializer<Block> blockSerializer =
    Wrapped<Tuple2<List<Statement>, Expression?>, Block>(
        (w) => Tuple2(w.statements, null),
        (u) => Block(u.first),
        const BlockSerializer());

TextSerializer<AssertBlock> assertBlockSerializer =
    Wrapped<Tuple2<List<Statement>, Expression?>, AssertBlock>(
        (w) => Tuple2(w.statements, null),
        (u) => AssertBlock(u.first),
        const BlockSerializer());

/// Serializer for [Block]s.
///
/// [BlockSerializer] is a combination of [ListSerializer] and [Bind].  As in
/// the case of [ListSerializer], [BlockSerializer] is a sequence of statements.
/// As in the case of [Bind], a statement in a block can be a
/// [VariableDeclaration] introducing binders that are bound in the rest of the
/// statements in the block.  Effectively, [BlockSerializer] could have been
/// expressed in terms of [ListSerializer] and [Bind], but that would transform
/// blocks like {stmt1; stmt2; stmt3;} into {stmt1; {stmt2; {stmt3; {}}}} via
/// the round-trip, and an extra pass will be required to flatten the
/// unnecessary nested blocks.  Instead, [BlockSerializer] is implemented
/// without direct invocations of either [ListSerializer] or [Bind], but with a
/// certain internal correspondence to how they work.
class BlockSerializer
    extends TextSerializer<Tuple2<List<Statement>, Expression?>> {
  const BlockSerializer();

  @override
  Tuple2<List<Statement>, Expression?> readFrom(
      Iterator<Object?> stream, DeserializationState? state) {
    if (state == null) {
      throw StateError(
          "No deserialization state provided for ${runtimeType}.readFrom.");
    }
    Object? iterator = stream.current;
    if (iterator is! Iterator) {
      throw StateError("Expected a list, found an atom: '${iterator}'.");
    }
    iterator.moveNext();
    List<Statement> statements = [];
    DeserializationState currentState = state;
    while (iterator.current != null) {
      currentState = new DeserializationState(
          new DeserializationEnvironment(currentState.environment),
          currentState.nameRoot);
      statements.add(statementSerializer.readFrom(iterator, currentState));
      currentState.environment.extend();
    }
    stream.moveNext();
    Expression? expression =
        nullableExpressionSerializer.readFrom(stream, currentState);
    return new Tuple2(statements, expression);
  }

  @override
  void writeTo(StringBuffer buffer, Tuple2<List<Statement>, Expression?> tuple,
      SerializationState? state) {
    if (state == null) {
      throw StateError(
          "No serialization state provided for ${runtimeType}.writeTo.");
    }
    buffer.write('(');
    SerializationState currentState = state;
    for (int i = 0; i < tuple.first.length; ++i) {
      if (i != 0) buffer.write(' ');
      currentState = new SerializationState(
          new SerializationEnvironment(currentState.environment));
      statementSerializer.writeTo(buffer, tuple.first[i], currentState);
      currentState.environment.extend();
    }
    buffer.write(') ');
    nullableExpressionSerializer.writeTo(buffer, tuple.second, currentState);
  }
}

TextSerializer<IfStatement> ifStatementSerializer =
    new Wrapped<Tuple2<Expression, Statement>, IfStatement>(
        unwrapIfStatement,
        wrapIfStatement,
        Tuple2Serializer(expressionSerializer, statementSerializer));

Tuple2<Expression, Statement> unwrapIfStatement(IfStatement node) {
  return new Tuple2(node.condition, node.then);
}

IfStatement wrapIfStatement(Tuple2<Expression, Statement> tuple) {
  return new IfStatement(tuple.first, tuple.second, null);
}

TextSerializer<IfStatement> ifElseStatementSerializer =
    new Wrapped<Tuple3<Expression, Statement, Statement?>, IfStatement>(
        unwrapIfElseStatement,
        wrapIfElseStatement,
        Tuple3Serializer<Expression, Statement, Statement?>(
            expressionSerializer, statementSerializer, statementSerializer));

Tuple3<Expression, Statement, Statement?> unwrapIfElseStatement(
    IfStatement node) {
  return new Tuple3(node.condition, node.then, node.otherwise);
}

IfStatement wrapIfElseStatement(
    Tuple3<Expression, Statement, Statement?> tuple) {
  return new IfStatement(tuple.first, tuple.second, tuple.third);
}

TextSerializer<EmptyStatement> emptyStatementSerializer =
    new Wrapped<void, EmptyStatement>(
        unwrapEmptyStatement, wrapEmptyStatement, const Nothing());

void unwrapEmptyStatement(EmptyStatement node) {}

EmptyStatement wrapEmptyStatement(void ignored) => new EmptyStatement();

TextSerializer<WhileStatement> whileStatementSerializer =
    new Wrapped<Tuple2<Expression, Statement>, WhileStatement>(
        unwrapWhileStatement,
        wrapWhileStatement,
        new Tuple2Serializer(expressionSerializer, statementSerializer));

Tuple2<Expression, Statement> unwrapWhileStatement(WhileStatement node) {
  return new Tuple2(node.condition, node.body);
}

WhileStatement wrapWhileStatement(Tuple2<Expression, Statement> tuple) {
  return new WhileStatement(tuple.first, tuple.second);
}

TextSerializer<DoStatement> doStatementSerializer =
    new Wrapped<Tuple2<Statement, Expression>, DoStatement>(
        unwrapDoStatement,
        wrapDoStatement,
        new Tuple2Serializer(statementSerializer, expressionSerializer));

Tuple2<Statement, Expression> unwrapDoStatement(DoStatement node) {
  return new Tuple2(node.body, node.condition);
}

DoStatement wrapDoStatement(Tuple2<Statement, Expression> tuple) {
  return new DoStatement(tuple.first, tuple.second);
}

TextSerializer<ForStatement> forStatementSerializer = Wrapped<
        Tuple2<List<VariableDeclaration>,
            Tuple3<Expression?, List<Expression>, Statement>>,
        ForStatement>(
    (w) => Tuple2(w.variables, Tuple3(w.condition, w.updates, w.body)),
    (u) =>
        ForStatement(u.first, u.second.first, u.second.second, u.second.third),
    new Bind(
        ListSerializer(variableDeclarationSerializer),
        new Tuple3Serializer(Optional(expressionSerializer),
            new ListSerializer(expressionSerializer), statementSerializer)));

TextSerializer<ForInStatement> forInStatementSerializer = new Wrapped<
        Tuple2<Expression, Tuple2<VariableDeclaration, Statement>>,
        ForInStatement>(
    unwrapForInStatement,
    wrapForInStatement,
    new Tuple2Serializer(expressionSerializer,
        new Bind(variableDeclarationSerializer, statementSerializer)));

Tuple2<Expression, Tuple2<VariableDeclaration, Statement>> unwrapForInStatement(
    ForInStatement node) {
  return new Tuple2(node.iterable, new Tuple2(node.variable, node.body));
}

ForInStatement wrapForInStatement(
    Tuple2<Expression, Tuple2<VariableDeclaration, Statement>> tuple) {
  return new ForInStatement(
      tuple.second.first, tuple.first, tuple.second.second);
}

TextSerializer<ForInStatement> awaitForInStatementSerializer = new Wrapped<
        Tuple2<Expression, Tuple2<VariableDeclaration, Statement>>,
        ForInStatement>(
    unwrapForInStatement,
    wrapAwaitForInStatement,
    new Tuple2Serializer(expressionSerializer,
        new Bind(variableDeclarationSerializer, statementSerializer)));

ForInStatement wrapAwaitForInStatement(
    Tuple2<Expression, Tuple2<VariableDeclaration, Statement>> tuple) {
  return new ForInStatement(
      tuple.second.first, tuple.first, tuple.second.second,
      isAsync: true);
}

TextSerializer<LabeledStatement> labeledStatementSerializer =
    Wrapped<Tuple2<LabeledStatement, Statement>, LabeledStatement>(
        (ls) => Tuple2(ls, ls.body),
        (t) => t.first..body = t.second,
        Bind(
            Wrapped<Tuple2<String?, LabeledStatement>, LabeledStatement>(
                (ls) => Tuple2("L", ls),
                (t) => t.second,
                Binder(Wrapped<void, LabeledStatement>(
                    (_) => null, (_) => LabeledStatement(null), Nothing()))),
            statementSerializer));

TextSerializer<BreakStatement> breakSerializer =
    new Wrapped<LabeledStatement, BreakStatement>(unwrapBreakStatement,
        wrapBreakStatement, const ScopedUse<LabeledStatement>());

LabeledStatement unwrapBreakStatement(BreakStatement node) {
  return node.target;
}

BreakStatement wrapBreakStatement(LabeledStatement node) {
  return new BreakStatement(node);
}

TextSerializer<TryFinally> tryFinallySerializer =
    Wrapped<Tuple2<Statement, Statement>, TryFinally>(
        (w) => Tuple2(w.body, w.finalizer),
        (u) => TryFinally(u.first, u.second),
        Tuple2Serializer(statementSerializer, statementSerializer));

TextSerializer<TryCatch> tryCatchSerializer =
    Wrapped<Tuple2<Statement, List<Catch>>, TryCatch>(
        (w) => Tuple2(w.body, w.catches),
        (u) => TryCatch(u.first, u.second),
        Tuple2Serializer(statementSerializer, ListSerializer(catchSerializer)));

TextSerializer<Catch> catchSerializer =
    Wrapped<
            Tuple2<
                DartType,
                Tuple2<Tuple2<VariableDeclaration?, VariableDeclaration?>,
                    Statement>>,
            Catch>(
        (w) =>
            Tuple2(w.guard, Tuple2(Tuple2(w.exception, w.stackTrace), w.body)),
        (u) => Catch(u.second.first.first, u.second.second,
            stackTrace: u.second.first.second, guard: u.first),
        Tuple2Serializer(
            dartTypeSerializer,
            Bind(
                Tuple2Serializer(Optional(variableDeclarationSerializer),
                    Optional(variableDeclarationSerializer)),
                statementSerializer)));

TextSerializer<SwitchStatement> switchStatementSerializer =
    Wrapped<Tuple2<Expression, List<SwitchCase>>, SwitchStatement>(
        (w) => Tuple2(w.expression, w.cases),
        (u) => SwitchStatement(u.first, u.second),
        Tuple2Serializer(
            expressionSerializer,
            Zip(
                Bind(ListSerializer<SwitchCase>(switchCaseSerializer),
                    ListSerializer(statementSerializer)),
                (SwitchCase c, Statement b) => c..body = b,
                (SwitchCase z) => Tuple2(z, z.body))));

class SwitchCaseTagger implements Tagger<SwitchCase> {
  @override
  String tag(SwitchCase node) {
    return node.isDefault ? "default" : "case";
  }
}

TextSerializer<SwitchCase> switchCaseCaseSerializer =
    Wrapped<Tuple2<String?, SwitchCase>, SwitchCase>(
        (w) => Tuple2("L", w),
        (u) => u.second,
        Binder(Wrapped<List<Expression>, SwitchCase>(
            (w) => w.expressions,
            (u) => SwitchCase(u, List.filled(u.length, 0), null),
            ListSerializer(expressionSerializer))));

TextSerializer<SwitchCase> switchCaseDefaultSerializer =
    Wrapped<Tuple2<String?, SwitchCase>, SwitchCase>(
        (w) => Tuple2("L", w),
        (u) => u.second,
        Binder(Wrapped<void, SwitchCase>(
            (w) => null, (u) => SwitchCase.defaultCase(null), Nothing())));

TextSerializer<SwitchCase> switchCaseSerializer = Case(SwitchCaseTagger(), {
  "case": switchCaseCaseSerializer,
  "default": switchCaseDefaultSerializer,
});

TextSerializer<ContinueSwitchStatement> continueSwitchStatementSerializer =
    Wrapped<SwitchCase, ContinueSwitchStatement>(
        (w) => w.target, (u) => ContinueSwitchStatement(u), ScopedUse());

TextSerializer<FunctionDeclaration> functionDeclarationSerializer =
    Wrapped<Tuple2<VariableDeclaration, FunctionNode>, FunctionDeclaration>(
        (w) => Tuple2(w.variable, w.function),
        (u) => FunctionDeclaration(u.first, u.second),
        Rebind(variableDeclarationSerializer, functionNodeSerializer));

Case<Statement> statementSerializer =
    new Case.uninitialized(const StatementTagger());

const Map<AsyncMarker, String> asyncMarkerToName = {
  AsyncMarker.Async: "async",
  AsyncMarker.Sync: "sync",
  AsyncMarker.AsyncStar: "async-star",
  AsyncMarker.SyncStar: "sync-star",
  AsyncMarker.SyncYielding: "sync-yielding",
};

class AsyncMarkerTagger implements Tagger<AsyncMarker> {
  const AsyncMarkerTagger();

  @override
  String tag(AsyncMarker node) {
    return asyncMarkerToName[node] ?? (throw new UnsupportedError("${node}"));
  }
}

TextSerializer<AsyncMarker> asyncMarkerSerializer =
    Case(AsyncMarkerTagger(), convertFlagsMap(asyncMarkerToName));

// '/**/' comments added to guide formatting.

TextSerializer<Tuple2<FunctionNode, List<Initializer>?>> /**/
    functionNodeWithInitializersSerializer = Wrapped<
            Tuple2<
                AsyncMarker,
                Tuple2<
                    /**/
                    Tuple2<
                        /**/
                        List<TypeParameter>,
                        Tuple3<
                            List<VariableDeclaration>,
                            List<VariableDeclaration>,
                            List<VariableDeclaration>>>,
                    Tuple3<DartType, List<Initializer>?, Statement?>>>,
            Tuple2<FunctionNode, List<Initializer>?>>(
        (w) => Tuple2(
            w.first.asyncMarker,
            Tuple2(
                Tuple2(
                    w.first.typeParameters,
                    Tuple3(
                        w.first.positionalParameters
                            .sublist(0, w.first.requiredParameterCount),
                        w.first.positionalParameters
                            .sublist(w.first.requiredParameterCount),
                        w.first.namedParameters)),
                Tuple3(w.first.returnType, w.second, w.first.body))),
        (u) => Tuple2(
            FunctionNode(u.second.second.third,
                typeParameters: u.second.first.first,
                positionalParameters:
                    u.second.first.second.first + u.second.first.second.second,
                namedParameters: u.second.first.second.third,
                requiredParameterCount: u.second.first.second.first.length,
                returnType: u.second.second.first,
                asyncMarker: u.first),
            u.second.second.second),
        Tuple2Serializer(
            asyncMarkerSerializer,
            Bind(
                Rebind(
                    typeParametersSerializer,
                    Tuple3Serializer(
                        ListSerializer(variableDeclarationSerializer),
                        ListSerializer(variableDeclarationSerializer),
                        ListSerializer(variableDeclarationSerializer))),
                Tuple3Serializer(
                    dartTypeSerializer,
                    Optional(ListSerializer(initializerSerializer)),
                    Optional(statementSerializer)))));

TextSerializer<FunctionNode> functionNodeSerializer =
    Wrapped<Tuple2<FunctionNode, List<Initializer>?>, FunctionNode>(
        (w) => Tuple2(w, null),
        (u) => u.first,
        functionNodeWithInitializersSerializer);

const Map<int, String> procedureFlagToName = const {
  Procedure.FlagStatic: "static",
  Procedure.FlagAbstract: "abstract",
  Procedure.FlagExternal: "external",
  Procedure.FlagConst: "const",
  Procedure.FlagRedirectingFactory: "redirecting-factory-constructor",
  Procedure.FlagExtensionMember: "extension-member",
  Procedure.FlagNonNullableByDefault: "non-nullable-by-default",
  Procedure.FlagSynthetic: "synthetic",
};

class ProcedureFlagTagger implements Tagger<int> {
  const ProcedureFlagTagger();

  @override
  String tag(int flag) {
    return procedureFlagToName[flag] ??
        (throw StateError("Unknown Procedure flag value: ${flag}."));
  }
}

TextSerializer<int> procedureFlagsSerializer = Wrapped<List<int>, int>(
    (w) => List.generate(30, (i) => w & (1 << i)).where((f) => f != 0).toList(),
    (u) => u.fold(0, (fs, f) => fs |= f),
    ListSerializer(
        Case(ProcedureFlagTagger(), convertFlagsMap(procedureFlagToName))));

const Map<int, String> fieldFlagToName = const {
  Field.FlagFinal: "final",
  Field.FlagConst: "const",
  Field.FlagStatic: "static",
  Field.FlagCovariant: "covariant",
  Field.FlagCovariantByClass: "generic-covariant-impl",
  Field.FlagLate: "late",
  Field.FlagExtensionMember: "extension-member",
  Field.FlagNonNullableByDefault: "non-nullable-by-default",
  Field.FlagInternalImplementation: "internal-implementation",
};

class FieldFlagTagger implements Tagger<int> {
  const FieldFlagTagger();

  @override
  String tag(int flag) {
    return fieldFlagToName[flag] ??
        (throw StateError("Unknown Field flag value: ${flag}."));
  }
}

TextSerializer<int> fieldFlagsSerializer = Wrapped<List<int>, int>(
    (w) => List.generate(30, (i) => w & (1 << i)).where((f) => f != 0).toList(),
    (u) => u.fold(0, (fs, f) => fs |= f),
    ListSerializer(Case(FieldFlagTagger(), convertFlagsMap(fieldFlagToName))));

const Map<int, String> constructorFlagToName = const {
  Constructor.FlagConst: "const",
  Constructor.FlagExternal: "external",
  Constructor.FlagSynthetic: "synthetic",
  Constructor.FlagNonNullableByDefault: "non-nullable-by-default",
};

class ConstructorFlagTagger implements Tagger<int> {
  const ConstructorFlagTagger();

  @override
  String tag(int flag) {
    return constructorFlagToName[flag] ??
        (throw StateError("Unknown Constructor flag value: ${flag}."));
  }
}

TextSerializer<int> constructorFlagsSerializer = Wrapped<List<int>, int>(
    (w) => List.generate(30, (i) => w & (1 << i)).where((f) => f != 0).toList(),
    (u) => u.fold(0, (fs, f) => fs |= f),
    ListSerializer(
        Case(ConstructorFlagTagger(), convertFlagsMap(constructorFlagToName))));

const Map<int, String> redirectingFactoryFlagToName = const {
  RedirectingFactory.FlagConst: "const",
  RedirectingFactory.FlagExternal: "external",
  RedirectingFactory.FlagNonNullableByDefault: "non-nullable-by-default",
};

class RedirectingFactoryFlagTagger implements Tagger<int> {
  const RedirectingFactoryFlagTagger();

  @override
  String tag(int flag) {
    return redirectingFactoryFlagToName[flag] ??
        (throw StateError("Unknown RedirectingFactory flag value: ${flag}."));
  }
}

TextSerializer<int> redirectingFactoryConstructorFlagsSerializer =
    Wrapped<List<int>, int>(
        (w) => List.generate(30, (i) => w & (1 << i))
            .where((f) => f != 0)
            .toList(),
        (u) => u.fold(0, (fs, f) => fs |= f),
        ListSerializer(Case(RedirectingFactoryFlagTagger(),
            convertFlagsMap(redirectingFactoryFlagToName))));

class MemberTagger implements Tagger<Member> {
  const MemberTagger();

  @override
  String tag(Member node) {
    if (node is Field) {
      return node.hasSetter ? "mutable-field" : "immutable-field";
    } else if (node is Constructor) {
      return "constructor";
    } else if (node is RedirectingFactory) {
      return "redirecting-factory-constructor";
    } else if (node is Procedure) {
      switch (node.kind) {
        case ProcedureKind.Method:
          return "method";
        case ProcedureKind.Getter:
          return "getter";
        case ProcedureKind.Setter:
          return "setter";
        case ProcedureKind.Operator:
          return "operator";
        case ProcedureKind.Factory:
          return "factory";
        default:
          throw new UnsupportedError("MemberTagger.tag(${node.kind})");
      }
    } else {
      throw UnimplementedError("MemberTagger.tag(${node.runtimeType})");
    }
  }
}

TextSerializer<Field> mutableFieldSerializer =
    Wrapped<Tuple5<Name, int, DartType, Expression?, Uri>, Field>(
        (w) => Tuple5(w.name, w.flags, w.type, w.initializer, w.fileUri),
        (u) => Field.mutable(u.first,
            type: u.third, initializer: u.fourth, fileUri: u.fifth)
          ..flags = u.second,
        Tuple5Serializer(nameSerializer, fieldFlagsSerializer,
            dartTypeSerializer, nullableExpressionSerializer, UriSerializer()));

TextSerializer<Field> immutableFieldSerializer =
    Wrapped<Tuple5<Name, int, DartType, Expression?, Uri>, Field>(
        (w) => Tuple5(w.name, w.flags, w.type, w.initializer, w.fileUri),
        (u) => Field.immutable(u.first,
            type: u.third, initializer: u.fourth, fileUri: u.fifth)
          ..flags = u.second,
        Tuple5Serializer(nameSerializer, fieldFlagsSerializer,
            dartTypeSerializer, nullableExpressionSerializer, UriSerializer()));

TextSerializer<Procedure> methodSerializer =
    Wrapped<Tuple4<Name, int, FunctionNode, Uri>, Procedure>(
        (w) => Tuple4(w.name, w.flags, w.function, w.fileUri),
        (u) =>
            Procedure(u.first, ProcedureKind.Method, u.third, fileUri: u.fourth)
              ..flags = u.second,
        Tuple4Serializer(nameSerializer, procedureFlagsSerializer,
            functionNodeSerializer, UriSerializer()));

TextSerializer<Procedure> getterSerializer =
    Wrapped<Tuple4<Name, int, FunctionNode, Uri>, Procedure>(
        (w) => Tuple4(w.name, w.flags, w.function, w.fileUri),
        (u) =>
            Procedure(u.first, ProcedureKind.Getter, u.third, fileUri: u.fourth)
              ..flags = u.second,
        Tuple4Serializer(nameSerializer, procedureFlagsSerializer,
            functionNodeSerializer, UriSerializer()));

TextSerializer<Procedure> setterSerializer =
    Wrapped<Tuple4<Name, int, FunctionNode, Uri>, Procedure>(
        (w) => Tuple4(w.name, w.flags, w.function, w.fileUri),
        (u) =>
            Procedure(u.first, ProcedureKind.Setter, u.third, fileUri: u.fourth)
              ..flags = u.second,
        Tuple4Serializer(nameSerializer, procedureFlagsSerializer,
            functionNodeSerializer, UriSerializer()));

TextSerializer<Procedure> operatorSerializer =
    Wrapped<Tuple4<Name, int, FunctionNode, Uri>, Procedure>(
        (w) => Tuple4(w.name, w.flags, w.function, w.fileUri),
        (u) => Procedure(u.first, ProcedureKind.Operator, u.third,
            fileUri: u.fourth)
          ..flags = u.second,
        Tuple4Serializer(nameSerializer, procedureFlagsSerializer,
            functionNodeSerializer, UriSerializer()));

TextSerializer<Procedure> factorySerializer =
    Wrapped<Tuple4<Name, int, FunctionNode, Uri>, Procedure>(
        (w) => Tuple4(w.name, w.flags, w.function, w.fileUri),
        (u) => Procedure(u.first, ProcedureKind.Factory, u.third,
            fileUri: u.fourth)
          ..flags = u.second,
        Tuple4Serializer(nameSerializer, procedureFlagsSerializer,
            functionNodeSerializer, UriSerializer()));

TextSerializer<Constructor> constructorSerializer = Wrapped<
        Tuple4<Name, int, Tuple2<FunctionNode, List<Initializer>?>, Uri>,
        Constructor>(
    (w) =>
        Tuple4(w.name, w.flags, Tuple2(w.function, w.initializers), w.fileUri),
    (u) => Constructor(u.third.first,
        name: u.first, initializers: u.third.second, fileUri: u.fourth)
      ..flags = u.second,
    Tuple4Serializer(nameSerializer, constructorFlagsSerializer,
        functionNodeWithInitializersSerializer, UriSerializer()));

TextSerializer<RedirectingFactory> redirectingFactoryConstructorSerializer
    // Comment added to direct formatter.
    = Wrapped<
            Tuple6<Name, int, FunctionNode, CanonicalName, List<DartType>, Uri>,
            RedirectingFactory>(
        (w) => Tuple6(w.name, w.flags, w.function,
            w.targetReference!.canonicalName!, w.typeArguments, w.fileUri),
        (u) => RedirectingFactory(u.fourth.reference,
            name: u.first,
            function: u.third,
            typeArguments: u.fifth,
            fileUri: u.sixth)
          ..flags = u.second,
        Tuple6Serializer(
            nameSerializer,
            redirectingFactoryConstructorFlagsSerializer,
            functionNodeSerializer,
            CanonicalNameSerializer(),
            ListSerializer(dartTypeSerializer),
            UriSerializer()));

Case<Member> memberSerializer = new Case.uninitialized(const MemberTagger());

TextSerializer<LibraryPart> libraryPartSerializer =
    Wrapped<Tuple2<String, List<Expression>>, LibraryPart>(
        (w) => Tuple2(w.partUri, w.annotations),
        (u) => LibraryPart(u.second, u.first),
        Tuple2Serializer(DartString(), ListSerializer(expressionSerializer)));

class LibraryTagger implements Tagger<Library> {
  const LibraryTagger();

  @override
  String tag(Library node) {
    return node.isNonNullableByDefault ? "null-safe" : "legacy";
  }
}

const Map<int, String> libraryFlagToName = const {
  Library.SyntheticFlag: "synthetic",
  Library.NonNullableByDefaultFlag: "nnbd",
  Library.NonNullableByDefaultModeBit1: "nnbd-bit1",
  Library.NonNullableByDefaultModeBit2: "nnbd-bit2",
};

class LibraryFlagTagger implements Tagger<int> {
  const LibraryFlagTagger();

  @override
  String tag(int flag) {
    return libraryFlagToName[flag] ??
        (throw StateError("Unknown Library flag value: ${flag}."));
  }
}

TextSerializer<int> libraryFlagsSerializer = Wrapped<List<int>, int>(
    (w) => List.generate(30, (i) => w & (1 << i)).where((f) => f != 0).toList(),
    (u) => u.fold(0, (fs, f) => fs |= f),
    ListSerializer(
        Case(LibraryFlagTagger(), convertFlagsMap(libraryFlagToName))));

TextSerializer<Library> librarySerializer = new Wrapped<
    Tuple8<Uri, int, List<LibraryPart>, List<Member>, List<Class>,
        List<Typedef>, List<Extension>, Uri>,
    Library>(
  (w) => Tuple8(w.importUri, w.flags, w.parts, [...w.fields, ...w.procedures],
      w.classes, w.typedefs, w.extensions, w.fileUri),
  (u) => Library(u.first,
      parts: u.third,
      fields: u.fourth.where((m) => m is Field).cast<Field>().toList(),
      procedures:
          u.fourth.where((m) => m is Procedure).cast<Procedure>().toList(),
      classes: u.fifth,
      typedefs: u.sixth,
      extensions: u.seventh,
      fileUri: u.eighth)
    ..flags = u.second,
  Tuple8Serializer(
      UriSerializer(),
      libraryFlagsSerializer,
      ListSerializer(libraryPartSerializer),
      ListSerializer(memberSerializer),
      ListSerializer(classSerializer),
      ListSerializer(typedefSerializer),
      ListSerializer(extensionSerializer),
      UriSerializer()),
);

TextSerializer<Component> componentSerializer =
    Wrapped<List<Library>, Component>(
        (w) => w.libraries,
        (u) => Component(nameRoot: CanonicalName.root(), libraries: u),
        ListSerializer(librarySerializer));

class ShowHideTagger implements Tagger<Combinator> {
  @override
  String tag(Combinator node) => node.isShow ? "show" : "hide";
}

TextSerializer<Combinator> showSerializer = Wrapped<List<String>, Combinator>(
    (c) => c.names, (ns) => Combinator(true, ns), ListSerializer(DartString()));

TextSerializer<Combinator> hideSerializer = Wrapped<List<String>, Combinator>(
    (c) => c.names,
    (ns) => Combinator(false, ns),
    ListSerializer(DartString()));

Case<Combinator> showHideSerializer = new Case(ShowHideTagger(), {
  "show": showSerializer,
  "hide": hideSerializer,
});

TextSerializer<LibraryDependency> libraryDependencySerializer = Wrapped<
        Tuple5<CanonicalName, String?, List<Combinator>, int, List<Expression>>,
        LibraryDependency>(
    (ld) => Tuple5(ld.importedLibraryReference.canonicalName!, ld.name,
        ld.combinators, ld.flags, ld.annotations),
    (t) => LibraryDependency.byReference(
        t.fourth, t.fifth, t.first.reference, t.second, t.third),
    Tuple5Serializer(
        CanonicalNameSerializer(),
        Optional(DartString()),
        ListSerializer(showHideSerializer),
        DartInt(),
        ListSerializer(expressionSerializer)));

class ConstantTagger extends ConstantVisitor<String>
    implements Tagger<Constant> {
  const ConstantTagger();

  @override
  String tag(Constant node) => node.accept(this);

  @override
  String visitBoolConstant(BoolConstant node) => "const-bool";
  @override
  String visitDoubleConstant(DoubleConstant node) => "const-double";
  @override
  String visitInstanceConstant(InstanceConstant node) => "const-object";
  @override
  String visitIntConstant(IntConstant node) => "const-int";
  @override
  String visitListConstant(ListConstant node) => "const-list";
  @override
  String visitMapConstant(MapConstant node) => "const-map";
  @override
  String visitNullConstant(NullConstant node) => "const-null";
  @override
  String visitInstantiationConstant(InstantiationConstant node) =>
      "const-apply";
  @override
  String visitSetConstant(SetConstant node) => "const-set";
  @override
  String visitStringConstant(StringConstant node) => "const-string";
  @override
  String visitSymbolConstant(SymbolConstant node) => "const-symbol";
  @override
  String visitStaticTearOffConstant(StaticTearOffConstant node) =>
      "const-tearoff-static";
  @override
  String visitConstructorTearOffConstant(ConstructorTearOffConstant node) =>
      "const-tearoff-constructor";
  @override
  String visitRedirectingFactoryTearOffConstant(
          RedirectingFactoryTearOffConstant node) =>
      "const-tearoff-redirecting-factory";
  @override
  String visitTypedefTearOffConstant(TypedefTearOffConstant node) =>
      "const-tearoff-typedef";
  @override
  String visitTypeLiteralConstant(TypeLiteralConstant node) => "const-type";
  @override
  String visitUnevaluatedConstant(UnevaluatedConstant node) => "const-expr";

  @override
  String defaultConstant(Constant node) {
    throw new UnimplementedError(
        'Unimplemented constant $node (${node.runtimeType})');
  }
}

TextSerializer<BoolConstant> boolConstantSerializer =
    Wrapped<bool, BoolConstant>(
        (w) => w.value, (u) => BoolConstant(u), DartBool());

TextSerializer<DoubleConstant> doubleConstantSerializer =
    Wrapped<double, DoubleConstant>(
        (w) => w.value, (u) => DoubleConstant(u), DartDouble());

TextSerializer<IntConstant> intConstantSerializer =
    Wrapped<int, IntConstant>((w) => w.value, (u) => IntConstant(u), DartInt());

TextSerializer<ListConstant> listConstantSerializer =
    Wrapped<Tuple2<DartType, List<Constant>>, ListConstant>(
        (w) => Tuple2(w.typeArgument, w.entries),
        (u) => ListConstant(u.first, u.second),
        Tuple2Serializer(
            dartTypeSerializer, ListSerializer(constantSerializer)));

TextSerializer<MapConstant> mapConstantSerializer =
    Wrapped<Tuple3<DartType, DartType, List<ConstantMapEntry>>, MapConstant>(
        (w) => Tuple3(w.keyType, w.valueType, w.entries),
        (u) => MapConstant(u.first, u.second, u.third),
        Tuple3Serializer(
            dartTypeSerializer,
            dartTypeSerializer,
            Zip(
                Tuple2Serializer(ListSerializer(constantSerializer),
                    ListSerializer(constantSerializer)),
                (Constant k, Constant v) => ConstantMapEntry(k, v),
                (z) => Tuple2(z.key, z.value))));

TextSerializer<NullConstant> nullConstantSerializer =
    Wrapped<void, NullConstant>((w) => null, (u) => NullConstant(), Nothing());

TextSerializer<InstantiationConstant> instantiationConstantSerializer =
    Wrapped<Tuple2<Constant, List<DartType>>, InstantiationConstant>(
        (w) => Tuple2(w.tearOffConstant, w.types),
        (u) => InstantiationConstant(u.first, u.second),
        Tuple2Serializer(
            constantSerializer, ListSerializer(dartTypeSerializer)));

TextSerializer<SetConstant> setConstantSerializer =
    Wrapped<Tuple2<DartType, List<Constant>>, SetConstant>(
        (w) => Tuple2(w.typeArgument, w.entries),
        (u) => SetConstant(u.first, u.second),
        Tuple2Serializer(
            dartTypeSerializer, ListSerializer(constantSerializer)));

TextSerializer<StringConstant> stringConstantSerializer =
    Wrapped<String, StringConstant>(
        (w) => w.value, (u) => StringConstant(u), DartString());

TextSerializer<SymbolConstant> symbolConstantSerializer =
    Wrapped<Tuple2<String, CanonicalName?>, SymbolConstant>(
        (w) => Tuple2(w.name, w.libraryReference?.canonicalName),
        (u) => SymbolConstant(u.first, u.second?.reference),
        Tuple2Serializer(DartString(), Optional(CanonicalNameSerializer())));

TextSerializer<StaticTearOffConstant> staticTearOffConstantSerializer =
    Wrapped<CanonicalName, StaticTearOffConstant>(
        (w) => w.targetReference.canonicalName!,
        (u) => StaticTearOffConstant.byReference(u.reference),
        CanonicalNameSerializer());

TextSerializer<ConstructorTearOffConstant>
    constructorTearOffConstantSerializer =
    Wrapped<CanonicalName, ConstructorTearOffConstant>(
        (w) => w.targetReference.canonicalName!,
        (u) => ConstructorTearOffConstant.byReference(u.reference),
        CanonicalNameSerializer());

TextSerializer<RedirectingFactoryTearOffConstant>
    redirectingFactoryTearOffConstantSerializer =
    Wrapped<CanonicalName, RedirectingFactoryTearOffConstant>(
        (w) => w.targetReference.canonicalName!,
        (u) => RedirectingFactoryTearOffConstant.byReference(u.reference),
        CanonicalNameSerializer());

final TextSerializer<TypedefTearOffConstant> typedefTearOffConstantSerializer =
    new Wrapped<Tuple2<List<TypeParameter>, Tuple2<Constant, List<DartType>>>,
            TypedefTearOffConstant>(
        unwrapTypedefTearOffConstant,
        wrapTypedefTearOffConstant,
        Bind(
            typeParametersSerializer,
            Tuple2Serializer(
                constantSerializer, ListSerializer(dartTypeSerializer))));

Tuple2<List<TypeParameter>, Tuple2<Constant, List<DartType>>>
    unwrapTypedefTearOffConstant(TypedefTearOffConstant node) {
  return new Tuple2(
      node.parameters, new Tuple2(node.tearOffConstant, node.types));
}

TypedefTearOffConstant wrapTypedefTearOffConstant(
    Tuple2<List<TypeParameter>, Tuple2<Constant, List<DartType>>> tuple) {
  return new TypedefTearOffConstant(
      tuple.first, tuple.second.first as TearOffConstant, tuple.second.second);
}

TextSerializer<TypeLiteralConstant> typeLiteralConstantSerializer =
    Wrapped<DartType, TypeLiteralConstant>(
        (w) => w.type, (u) => TypeLiteralConstant(u), dartTypeSerializer);

TextSerializer<UnevaluatedConstant> unevaluatedConstantSerializer =
    Wrapped<Expression, UnevaluatedConstant>((w) => w.expression,
        (u) => UnevaluatedConstant(u), expressionSerializer);

TextSerializer<InstanceConstant> instanceConstantSerializer =
    Wrapped<
            Tuple4<CanonicalName, List<DartType>, List<CanonicalName>,
                List<Constant>>,
            InstanceConstant>(
        (w) => Tuple4(
            w.classReference.canonicalName!,
            w.typeArguments,
            w.fieldValues.keys.map((r) => r.canonicalName!).toList(),
            w.fieldValues.values.toList()),
        (u) => InstanceConstant(u.first.reference, u.second,
            Map.fromIterables(u.third.map((c) => c.reference), u.fourth)),
        Tuple4Serializer(
            CanonicalNameSerializer(),
            ListSerializer(dartTypeSerializer),
            ListSerializer(CanonicalNameSerializer()),
            ListSerializer(constantSerializer)));

Case<Constant> constantSerializer = Case.uninitialized(ConstantTagger());

class InitializerTagger implements Tagger<Initializer> {
  const InitializerTagger();

  @override
  String tag(Initializer node) {
    if (node is AssertInitializer) {
      return "assert";
    } else if (node is FieldInitializer) {
      return "field";
    } else if (node is InvalidInitializer) {
      return "invalid";
    } else if (node is LocalInitializer) {
      return "local";
    } else if (node is RedirectingInitializer) {
      return "redirecting";
    } else if (node is SuperInitializer) {
      return "super";
    } else {
      throw UnimplementedError("InitializerTagger.tag(${node.runtimeType}).");
    }
  }
}

TextSerializer<AssertInitializer> assertInitializerSerializer =
    Wrapped<Statement, AssertInitializer>((w) => w.statement,
        (u) => AssertInitializer(u as AssertStatement), statementSerializer);

TextSerializer<FieldInitializer> fieldInitializerSerializer =
    Wrapped<Tuple2<CanonicalName, Expression>, FieldInitializer>(
        (w) => Tuple2(w.fieldReference.canonicalName!, w.value),
        (u) => FieldInitializer.byReference(u.first.reference, u.second),
        Tuple2Serializer(CanonicalNameSerializer(), expressionSerializer));

TextSerializer<InvalidInitializer> invalidInitializerSerializer =
    Wrapped<void, InvalidInitializer>(
        (_) => null, (_) => InvalidInitializer(), Nothing());

TextSerializer<LocalInitializer> localInitializerSerializer =
    Wrapped<VariableDeclaration, LocalInitializer>((w) => w.variable,
        (u) => LocalInitializer(u), variableDeclarationSerializer);

TextSerializer<RedirectingInitializer> redirectingInitializerSerializer =
    Wrapped<Tuple2<CanonicalName, Arguments>, RedirectingInitializer>(
        (w) => Tuple2(w.targetReference.canonicalName!, w.arguments),
        (u) => RedirectingInitializer.byReference(u.first.reference, u.second),
        Tuple2Serializer(CanonicalNameSerializer(), argumentsSerializer));

TextSerializer<SuperInitializer> superInitializerSerializer =
    Wrapped<Tuple2<CanonicalName, Arguments>, SuperInitializer>(
        (w) => Tuple2(w.targetReference.canonicalName!, w.arguments),
        (u) => SuperInitializer.byReference(u.first.reference, u.second),
        Tuple2Serializer(CanonicalNameSerializer(), argumentsSerializer));

Case<Initializer> initializerSerializer =
    Case.uninitialized(InitializerTagger());

TextSerializer<Supertype> supertypeSerializer =
    Wrapped<Tuple2<CanonicalName, List<DartType>>, Supertype>(
        (w) => Tuple2(w.className.canonicalName!, w.typeArguments),
        (u) => Supertype.byReference(u.first.reference, u.second),
        Tuple2Serializer(
            CanonicalNameSerializer(), ListSerializer(dartTypeSerializer)));

const Map<int, String> classFlagToName = const {
  Class.FlagAbstract: "abstract",
  Class.FlagEnum: "enum",
  Class.FlagAnonymousMixin: "anonymous-mixin",
  Class.FlagEliminatedMixin: "eliminated-mixin",
  Class.FlagMixinDeclaration: "mixin-declaration",
  Class.FlagHasConstConstructor: "has-const-constructor",
  Class.FlagMacro: "macro",
};

class ClassFlagTagger implements Tagger<int> {
  const ClassFlagTagger();

  @override
  String tag(int flag) {
    return classFlagToName[flag] ??
        (throw StateError("Unknown Class flag value: ${flag}."));
  }
}

TextSerializer<int> classFlagsSerializer = Wrapped<List<int>, int>(
    (w) => List.generate(30, (i) => w & (1 << i)).where((f) => f != 0).toList(),
    (u) => u.fold(0, (fs, f) => fs |= f),
    ListSerializer(Case(ClassFlagTagger(), convertFlagsMap(classFlagToName))));

TextSerializer<Class> classSerializer = Wrapped<
        Tuple4<
            String,
            int,
            Uri,
            Tuple2<
                List<TypeParameter>,
                /* Comment added to guide formatting. */
                Tuple4<Supertype?, Supertype?, List<Supertype>, List<Member>>>>,
        Class>(
    (w) => Tuple4(
        w.name,
        w.flags,
        w.fileUri,
        Tuple2(
            w.typeParameters,
            Tuple4(w.supertype, w.mixedInType, w.implementedTypes,
                <Member>[...w.fields, ...w.constructors, ...w.procedures]))),
    (u) => Class(
        name: u.first,
        typeParameters: u.fourth.first,
        supertype: u.fourth.second.first,
        mixedInType: u.fourth.second.second,
        implementedTypes: u.fourth.second.third,
        fields: u.fourth.second.fourth
            .where((m) => m is Field)
            .cast<Field>()
            .toList(),
        constructors: u.fourth.second.fourth
            .where((m) => m is Constructor)
            .cast<Constructor>()
            .toList(),
        procedures: u.fourth.second.fourth
            .where((m) => m is Procedure)
            .cast<Procedure>()
            .toList(),
        fileUri: u.third)
      ..flags = u.second,
    Tuple4Serializer(
        DartString(),
        classFlagsSerializer,
        UriSerializer(),
        Bind(
            typeParametersSerializer,
            Tuple4Serializer(
                Optional(supertypeSerializer),
                Optional(supertypeSerializer),
                ListSerializer(supertypeSerializer),
                ListSerializer(memberSerializer)))));

TextSerializer<Typedef> typedefSerializer = Wrapped<
        Tuple3<String, Tuple2<List<TypeParameter>, DartType>, Uri>, Typedef>(
    (w) => Tuple3(w.name, Tuple2(w.typeParameters, w.type!), w.fileUri),
    (u) => Typedef(u.first, u.second.second,
        typeParameters: u.second.first, fileUri: u.third),
    Tuple3Serializer(DartString(),
        Bind(typeParametersSerializer, dartTypeSerializer), UriSerializer()));

const Map<int, String> extensionMemberDescriptorFlagToName = const {
  ExtensionMemberDescriptor.FlagStatic: "static",
};

class ExtensionMemberDescriptorFlagTagger implements Tagger<int> {
  const ExtensionMemberDescriptorFlagTagger();

  @override
  String tag(int flag) {
    return extensionMemberDescriptorFlagToName[flag] ??
        (throw StateError(
            "Unknown ExtensionMemberDescriptor flag value: ${flag}."));
  }
}

TextSerializer<int> extensionMemberDescriptorFlagsSerializer =
    Wrapped<List<int>, int>(
        (w) => List.generate(30, (i) => w & (1 << i))
            .where((f) => f != 0)
            .toList(),
        (u) => u.fold(0, (fs, f) => fs |= f),
        ListSerializer(Case(ExtensionMemberDescriptorFlagTagger(),
            convertFlagsMap(extensionMemberDescriptorFlagToName))));

const Map<ExtensionMemberKind, String> extensionMemberKindToName = const {
  ExtensionMemberKind.Field: "field",
  ExtensionMemberKind.Method: "method",
  ExtensionMemberKind.Getter: "getter",
  ExtensionMemberKind.Setter: "setter",
  ExtensionMemberKind.Operator: "operator",
  ExtensionMemberKind.TearOff: "tearOff",
};

class ExtensionMemberKindTagger implements Tagger<ExtensionMemberKind> {
  const ExtensionMemberKindTagger();

  @override
  String tag(ExtensionMemberKind kind) {
    return extensionMemberKindToName[kind] ??
        (throw StateError("Unknown ExtensionMemberKind flag value: ${kind}."));
  }
}

TextSerializer<ExtensionMemberKind> extensionMemberKindSerializer = Case(
    ExtensionMemberKindTagger(), convertFlagsMap(extensionMemberKindToName));

TextSerializer<ExtensionMemberDescriptor> extensionMemberDescriptorSerializer =
    Wrapped<Tuple4<Name, ExtensionMemberKind, int, CanonicalName>,
            ExtensionMemberDescriptor>(
        (w) => Tuple4(w.name, w.kind, w.flags, w.member.canonicalName!),
        (u) => ExtensionMemberDescriptor(
            name: u.first, kind: u.second, member: u.fourth.reference)
          ..flags = u.third,
        Tuple4Serializer(
            nameSerializer,
            extensionMemberKindSerializer,
            extensionMemberDescriptorFlagsSerializer,
            CanonicalNameSerializer()));

TextSerializer<Extension> extensionSerializer = Wrapped<
        Tuple4<String, Tuple2<List<TypeParameter>, DartType>,
            List<ExtensionMemberDescriptor>, Uri>,
        Extension>(
    (w) => Tuple4(
        w.name, Tuple2(w.typeParameters, w.onType), w.members, w.fileUri),
    (u) => Extension(
        name: u.first,
        typeParameters: u.second.first,
        onType: u.second.second,
        members: u.third,
        fileUri: u.fourth),
    Tuple4Serializer(
        DartString(),
        Bind(typeParametersSerializer, dartTypeSerializer),
        ListSerializer(extensionMemberDescriptorSerializer),
        UriSerializer()));

void initializeSerializers() {
  expressionSerializer.registerTags({
    "string": stringLiteralSerializer,
    "int": intLiteralSerializer,
    "double": doubleLiteralSerializer,
    "bool": boolLiteralSerializer,
    "null": nullLiteralSerializer,
    "invalid": invalidExpressionSerializer,
    "not": notSerializer,
    "&&": logicalAndSerializer,
    "||": logicalOrSerializer,
    "concat": stringConcatenationSerializer,
    "symbol": symbolLiteralSerializer,
    "this": thisExpressionSerializer,
    "rethrow": rethrowSerializer,
    "throw": throwSerializer,
    "await": awaitExpressionSerializer,
    "cond": conditionalExpressionSerializer,
    "is": isExpressionSerializer,
    "as": asExpressionSerializer,
    "type": typeLiteralSerializer,
    "list": listLiteralSerializer,
    "const-list": constListLiteralSerializer,
    "set": setLiteralSerializer,
    "const-set": constSetLiteralSerializer,
    "map": mapLiteralSerializer,
    "const-map": constMapLiteralSerializer,
    "let": letSerializer,
    "get-instance": instanceGetSerializer,
    "set-instance": instanceSetSerializer,
    "get-dynamic": dynamicGetSerializer,
    "set-dynamic": dynamicSetSerializer,
    "tearoff-instance": instanceTearOffSerializer,
    "tearoff-function": functionTearOffSerializer,
    "get-super": superPropertyGetSerializer,
    "set-super": superPropertySetSerializer,
    "invoke-instance": instanceInvocationSerializer,
    "invoke-instance-getter": instanceGetterInvocationSerializer,
    "invoke-dynamic": dynamicInvocationSerializer,
    "invoke-function": functionInvocationSerializer,
    "invoke-local-function": localFunctionInvocationSerializer,
    "equals-null": equalsNullSerializer,
    "equals-call": equalsCallSerializer,
    "invoke-super": superMethodInvocationSerializer,
    "get-var": variableGetSerializer,
    "set-var": variableSetSerializer,
    "get-static": staticGetSerializer,
    "set-static": staticSetSerializer,
    "tearoff-static": staticTearOffSerializer,
    "tearoff-constructor": constructorTearOffSerializer,
    "tearoff-redirecting-factory": redirectingFactoryTearOffSerializer,
    "tearoff-typedef": typedefTearOffSerializer,
    "invoke-static": staticInvocationSerializer,
    "invoke-const-static": constStaticInvocationSerializer,
    "invoke-constructor": constructorInvocationSerializer,
    "invoke-const-constructor": constConstructorInvocationSerializer,
    "fun": functionExpressionSerializer,
    "lists": listConcatenationSerializer,
    "sets": setConcatenationSerializer,
    "maps": mapConcatenationSerializer,
    "let-block": blockExpressionSerializer,
    "apply": instantiationSerializer,
    "not-null": nullCheckSerializer,
    "with-uri": fileUriExpressionSerializer,
    "is-loaded": checkLibraryIsLoadedSerializer,
    "load": loadLibrarySerializer,
    "const": constantExpressionSerializer,
    "object": instanceCreationSerializer,
  });
  dartTypeSerializer.registerTags({
    "invalid": invalidTypeSerializer,
    "dynamic": dynamicTypeSerializer,
    "void": voidTypeSerializer,
    "->": functionTypeSerializer,
    "par": typeParameterTypeSerializer,
    "interface": interfaceTypeSerializer,
    "never": neverTypeSerializer,
    "typedef": typedefTypeSerializer,
    "futureor": futureOrTypeSerializer,
    "null-type": nullTypeSerializer,
  });
  statementSerializer.registerTags({
    "expr": expressionStatementSerializer,
    "ret": returnStatementSerializer,
    "ret-void": returnVoidStatementSerializer,
    "yield": yieldStatementSerializer,
    "block": blockSerializer,
    "local": variableDeclarationSerializer,
    "if": ifStatementSerializer,
    "if-else": ifElseStatementSerializer,
    "skip": emptyStatementSerializer,
    "while": whileStatementSerializer,
    "do-while": doStatementSerializer,
    "for": forStatementSerializer,
    "for-in": forInStatementSerializer,
    "await-for-in": awaitForInStatementSerializer,
    "assert": assertStatementSerializer,
    "assert-block": assertBlockSerializer,
    "label": labeledStatementSerializer,
    "break": breakSerializer,
    "try-finally": tryFinallySerializer,
    "try-catch": tryCatchSerializer,
    "switch": switchStatementSerializer,
    "continue": continueSwitchStatementSerializer,
    "local-fun": functionDeclarationSerializer,
  });
  memberSerializer.registerTags({
    "mutable-field": mutableFieldSerializer,
    "immutable-field": immutableFieldSerializer,
    "method": methodSerializer,
    "getter": getterSerializer,
    "setter": setterSerializer,
    "operator": operatorSerializer,
    "factory": factorySerializer,
    "constructor": constructorSerializer,
    "redirecting-factory-constructor": redirectingFactoryConstructorSerializer,
  });
  constantSerializer.registerTags({
    "const-bool": boolConstantSerializer,
    "const-double": doubleConstantSerializer,
    "const-int": intConstantSerializer,
    "const-list": listConstantSerializer,
    "const-map": mapConstantSerializer,
    "const-null": nullConstantSerializer,
    "const-apply": instantiationConstantSerializer,
    "const-set": setConstantSerializer,
    "const-string": stringConstantSerializer,
    "const-symbol": symbolConstantSerializer,
    "const-tearoff-static": staticTearOffConstantSerializer,
    "const-tearoff-constructor": constructorTearOffConstantSerializer,
    "const-tearoff-redirecting-factory":
        redirectingFactoryTearOffConstantSerializer,
    "const-tearoff-typedef": typedefTearOffConstantSerializer,
    "const-type": typeLiteralConstantSerializer,
    "const-expr": unevaluatedConstantSerializer,
    "const-object": instanceConstantSerializer,
  });
  initializerSerializer.registerTags({
    "assert": assertInitializerSerializer,
    "field": fieldInitializerSerializer,
    "invalid": invalidInitializerSerializer,
    "local": localInitializerSerializer,
    "redirecting": redirectingInitializerSerializer,
    "super": superInitializerSerializer,
  });
}

Map<String, Wrapped<void, T>> convertFlagsMap<T>(Map<T, String> map) {
  return map.entries.toMap(
      key: (e) => e.value,
      value: (e) => Wrapped<void, T>((_) => null, (_) => e.key, Nothing()));
}

extension MapFromIterable<E> on Iterable<E> {
  Map<K, V> toMap<K, V>(
      {required K Function(E) key, required V Function(E) value}) {
    return {for (E e in this) key(e): value(e)};
  }
}
