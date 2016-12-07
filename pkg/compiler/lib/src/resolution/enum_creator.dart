// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.enum_creator;

import '../common.dart';
import '../core_types.dart' show CoreTypes;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart';
import '../tokens/keyword.dart' show Keyword;
import '../tokens/precedence.dart';
import '../tokens/precedence_constants.dart' as Precedence;
import '../tokens/token.dart';
import '../tree/tree.dart';
import '../util/util.dart';

// TODO(johnniwinther): Merge functionality with the `TreePrinter`.
class AstBuilder {
  final int charOffset;

  AstBuilder(this.charOffset);

  Modifiers modifiers(
      {bool isConst: false, bool isFinal: false, bool isStatic: false}) {
    List identifiers = [];
    int flags = 0;
    if (isConst) {
      identifiers.add(identifier('const'));
      flags |= Modifiers.FLAG_CONST;
    }
    if (isFinal) {
      identifiers.add(identifier('final'));
      flags |= Modifiers.FLAG_FINAL;
    }
    if (isStatic) {
      identifiers.add(identifier('static'));
      flags |= Modifiers.FLAG_STATIC;
    }
    return new Modifiers.withFlags(
        new NodeList(null, linkedList(identifiers), null, ''), flags);
  }

  Token keywordToken(String text) {
    return new KeywordToken(Keyword.keywords[text], charOffset);
  }

  Token stringToken(String text) {
    return new StringToken.fromString(
        Precedence.IDENTIFIER_INFO, text, charOffset);
  }

  Token symbolToken(PrecedenceInfo info) {
    return new SymbolToken(info, charOffset);
  }

  Identifier identifier(String text) {
    Keyword keyword = Keyword.keywords[text];
    Token token;
    if (keyword != null) {
      token = new KeywordToken(Keyword.keywords[text], charOffset);
    } else {
      token = stringToken(text);
    }
    return new Identifier(token);
  }

  Link linkedList(List elements) {
    LinkBuilder builder = new LinkBuilder();
    elements.forEach((e) => builder.addLast(e));
    return builder.toLink();
  }

  NodeList argumentList(List<Node> nodes) {
    return new NodeList(symbolToken(Precedence.OPEN_PAREN_INFO),
        linkedList(nodes), symbolToken(Precedence.CLOSE_PAREN_INFO), ',');
  }

  Return returnStatement(Expression expression) {
    return new Return(keywordToken('return'),
        symbolToken(Precedence.SEMICOLON_INFO), expression);
  }

  FunctionExpression functionExpression(Modifiers modifiers, String name,
      NodeList typeVariables, NodeList argumentList, Statement body,
      [TypeAnnotation returnType]) {
    return new FunctionExpression(
        identifier(name),
        typeVariables,
        argumentList,
        body,
        returnType,
        modifiers,
        null, // Initializer.
        null, // get/set.
        null // Async modifier.
        );
  }

  EmptyStatement emptyStatement() {
    return new EmptyStatement(symbolToken(Precedence.COMMA_INFO));
  }

  LiteralInt literalInt(int value) {
    return new LiteralInt(stringToken('$value'), null);
  }

  LiteralString literalString(String text,
      {String prefix: '"', String suffix: '"'}) {
    return new LiteralString(
        stringToken('$prefix$text$suffix'), new DartString.literal(text));
  }

  LiteralList listLiteral(List<Node> elements, {bool isConst: false}) {
    return new LiteralList(
        null,
        new NodeList(
            symbolToken(Precedence.OPEN_SQUARE_BRACKET_INFO),
            linkedList(elements),
            symbolToken(Precedence.CLOSE_SQUARE_BRACKET_INFO),
            ','),
        isConst ? keywordToken('const') : null);
  }

  Node createDefinition(Identifier name, Expression initializer) {
    if (initializer == null) return name;
    return new SendSet(
        null,
        name,
        new Operator(symbolToken(Precedence.EQ_INFO)),
        new NodeList.singleton(initializer));
  }

  VariableDefinitions initializingFormal(String fieldName) {
    return new VariableDefinitions.forParameter(
        new NodeList.empty(),
        null,
        Modifiers.EMPTY,
        new NodeList.singleton(
            new Send(identifier('this'), identifier(fieldName))));
  }

  NewExpression newExpression(String typeName, NodeList arguments,
      {bool isConst: false}) {
    return new NewExpression(keywordToken(isConst ? 'const' : 'new'),
        new Send(null, identifier(typeName), arguments));
  }

  Send reference(Identifier identifier) {
    return new Send(null, identifier);
  }

  Send indexGet(Expression receiver, Expression index) {
    return new Send(receiver, new Operator(symbolToken(Precedence.INDEX_INFO)),
        new NodeList.singleton(index));
  }

  LiteralMapEntry mapLiteralEntry(Expression key, Expression value) {
    return new LiteralMapEntry(key, symbolToken(Precedence.COLON_INFO), value);
  }

  LiteralMap mapLiteral(List<LiteralMapEntry> entries, {bool isConst: false}) {
    return new LiteralMap(
        null, // Type arguments.
        new NodeList(
            symbolToken(Precedence.OPEN_CURLY_BRACKET_INFO),
            linkedList(entries),
            symbolToken(Precedence.CLOSE_CURLY_BRACKET_INFO),
            ','),
        isConst ? keywordToken('const') : null);
  }
}

/// This class generates the model for an enum class.
///
/// For instance
///
///     enum A { b, c, }
///
/// is modelled as
///
///     class A {
///       final int index;
///
///       const A(this.index);
///
///       String toString() {
///         return const <int, A>{0: 'A.b', 1: 'A.c'}[index];
///       }
///
///       static const A b = const A(0);
///       static const A c = const A(1);
///
///       static const List<A> values = const <A>[b, c];
///     }
///
// TODO(johnniwinther): Avoid creating synthesized ASTs for enums when SSA is
// removed.
class EnumCreator {
  final DiagnosticReporter reporter;
  final CoreTypes coreTypes;
  final EnumClassElementX enumClass;

  EnumCreator(this.reporter, this.coreTypes, this.enumClass);

  void createMembers() {
    Enum node = enumClass.node;
    InterfaceType enumType = enumClass.thisType;
    AstBuilder builder = new AstBuilder(enumClass.position.charOffset);

    InterfaceType intType = coreTypes.intType;
    InterfaceType stringType = coreTypes.stringType;

    EnumFieldElementX addInstanceMember(String name, InterfaceType type) {
      Identifier identifier = builder.identifier(name);
      VariableList variableList =
          new VariableList(builder.modifiers(isFinal: true));
      variableList.type = type;
      EnumFieldElementX variable = new EnumFieldElementX(
          identifier, enumClass, variableList, identifier);
      enumClass.addMember(variable, reporter);
      return variable;
    }

    EnumFieldElementX indexVariable = addInstanceMember('index', intType);

    VariableDefinitions indexDefinition = builder.initializingFormal('index');

    FunctionExpression constructorNode = builder.functionExpression(
        builder.modifiers(isConst: true),
        enumClass.name,
        null, // typeVariables
        builder.argumentList([indexDefinition]),
        builder.emptyStatement());

    EnumConstructorElementX constructor = new EnumConstructorElementX(
        enumClass, builder.modifiers(isConst: true), constructorNode);

    EnumFormalElementX indexFormal = new EnumFormalElementX(constructor,
        indexDefinition, builder.identifier('index'), indexVariable);

    FunctionSignatureX constructorSignature = new FunctionSignatureX(
        requiredParameters: [indexFormal],
        requiredParameterCount: 1,
        type: new FunctionType(
            constructor, const DynamicType(), <DartType>[intType]));
    constructor.functionSignature = constructorSignature;
    enumClass.addMember(constructor, reporter);

    List<EnumConstantElement> enumValues = <EnumConstantElement>[];
    int index = 0;
    List<Node> valueReferences = <Node>[];
    List<LiteralMapEntry> mapEntries = <LiteralMapEntry>[];
    for (Link<Node> link = node.names.nodes; !link.isEmpty; link = link.tail) {
      Identifier name = link.head;
      AstBuilder valueBuilder = new AstBuilder(name.token.charOffset);
      VariableList variableList = new VariableList(
          valueBuilder.modifiers(isStatic: true, isConst: true));
      variableList.type = enumType;

      // Add reference for the `values` field.
      valueReferences.add(valueBuilder.reference(name));

      // Add map entry for `toString` implementation.
      mapEntries.add(valueBuilder.mapLiteralEntry(
          valueBuilder.literalInt(index),
          valueBuilder.literalString('${enumClass.name}.${name.source}')));

      Expression initializer = valueBuilder.newExpression(enumClass.name,
          valueBuilder.argumentList([valueBuilder.literalInt(index)]),
          isConst: true);
      SendSet definition = valueBuilder.createDefinition(name, initializer);

      EnumConstantElementX field = new EnumConstantElementX(
          name, enumClass, variableList, definition, initializer, index);
      enumValues.add(field);
      enumClass.addMember(field, reporter);
      index++;
    }

    VariableList valuesVariableList =
        new VariableList(builder.modifiers(isStatic: true, isConst: true));
    valuesVariableList.type = coreTypes.listType(enumType);

    Identifier valuesIdentifier = builder.identifier('values');
    // TODO(johnniwinther): Add type argument.
    Expression initializer =
        builder.listLiteral(valueReferences, isConst: true);

    Node definition = builder.createDefinition(valuesIdentifier, initializer);

    EnumFieldElementX valuesVariable = new EnumFieldElementX(valuesIdentifier,
        enumClass, valuesVariableList, definition, initializer);

    enumClass.addMember(valuesVariable, reporter);

    // TODO(johnniwinther): Support return type. Note `String` might be prefixed
    // or not imported within the current library.
    FunctionExpression toStringNode = builder.functionExpression(
        Modifiers.EMPTY,
        'toString',
        null, // typeVariables
        builder.argumentList([]),
        builder.returnStatement(builder.indexGet(
            builder.mapLiteral(mapEntries, isConst: true),
            builder.reference(builder.identifier('index')))));

    EnumMethodElementX toString = new EnumMethodElementX(
        'toString', enumClass, Modifiers.EMPTY, toStringNode);
    FunctionSignatureX toStringSignature =
        new FunctionSignatureX(type: new FunctionType(toString, stringType));
    toString.functionSignature = toStringSignature;
    enumClass.addMember(toString, reporter);

    enumClass.enumValues = enumValues;
  }
}
