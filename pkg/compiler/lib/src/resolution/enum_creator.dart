// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.enum_creator;

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/scanner/precedence.dart' as Precedence;
import 'package:front_end/src/scanner/token.dart' show TokenType;
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

  Token symbolToken(TokenType info) {
    return new SymbolToken(info, charOffset);
  }

  Identifier identifier(String text) {
    Keyword keyword = Keyword.keywords[text];
    Token token;
    if (keyword != null) {
      token = new KeywordToken(keyword, charOffset);
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
///       final String _name;
///
///       const A(this.index);
///
///       String toString() {
///         return _name;
///       }
///
///       static const A b = const A(0, "A.b");
///       static const A c = const A(1, "A.v");
///
///       static const List<A> values = const <A>[b, c];
///     }
///
// TODO(johnniwinther): Avoid creating synthesized ASTs for enums when SSA is
// removed.
class EnumCreator {
  final DiagnosticReporter reporter;
  final CommonElements commonElements;
  final EnumClassElementX enumClass;

  EnumCreator(this.reporter, this.commonElements, this.enumClass);

  void createMembers() {
    Enum node = enumClass.node;
    ResolutionInterfaceType enumType = enumClass.thisType;
    AstBuilder builder = new AstBuilder(enumClass.position.charOffset);

    ResolutionInterfaceType intType = commonElements.intType;
    ResolutionInterfaceType stringType = commonElements.stringType;

    EnumFieldElementX addInstanceMember(
        String name, ResolutionInterfaceType type) {
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
    EnumFieldElementX nameVariable = addInstanceMember('_name', stringType);

    VariableDefinitions indexDefinition = builder.initializingFormal('index');
    VariableDefinitions nameDefinition = builder.initializingFormal('_name');

    FunctionExpression constructorNode = builder.functionExpression(
        builder.modifiers(isConst: true),
        enumClass.name,
        null, // typeVariables
        builder.argumentList([indexDefinition, nameDefinition]),
        builder.emptyStatement());

    EnumConstructorElementX constructor = new EnumConstructorElementX(
        enumClass, builder.modifiers(isConst: true), constructorNode);

    EnumFormalElementX indexFormal = new EnumFormalElementX(constructor,
        indexDefinition, builder.identifier('index'), indexVariable);

    EnumFormalElementX nameFormal = new EnumFormalElementX(
        constructor, nameDefinition, builder.identifier('_name'), nameVariable);

    FunctionSignatureX constructorSignature = new FunctionSignatureX(
        requiredParameters: [indexFormal, nameFormal],
        requiredParameterCount: 2,
        type: new ResolutionFunctionType(
            constructor,
            const ResolutionDynamicType(),
            <ResolutionDartType>[intType, stringType]));
    constructor.functionSignature = constructorSignature;
    enumClass.addMember(constructor, reporter);

    List<EnumConstantElement> enumValues = <EnumConstantElement>[];
    int index = 0;
    List<Node> valueReferences = <Node>[];
    for (Link<Node> link = node.names.nodes; !link.isEmpty; link = link.tail) {
      Identifier name = link.head;
      AstBuilder valueBuilder = new AstBuilder(name.token.charOffset);
      VariableList variableList = new VariableList(
          valueBuilder.modifiers(isStatic: true, isConst: true));
      variableList.type = enumType;

      // Add reference for the `values` field.
      valueReferences.add(valueBuilder.reference(name));

      Expression initializer = valueBuilder.newExpression(
          enumClass.name,
          valueBuilder.argumentList([
            valueBuilder.literalInt(index),
            valueBuilder.literalString('${enumClass.name}.${name.source}')
          ]),
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
    ResolutionInterfaceType valuesType = commonElements.listType(enumType);
    valuesVariableList.type = valuesType;

    Identifier valuesIdentifier = builder.identifier('values');
    // TODO(28340): Add type argument.
    Expression initializer =
        builder.listLiteral(valueReferences, isConst: true);

    Node definition = builder.createDefinition(valuesIdentifier, initializer);

    EnumFieldElementX valuesVariable = new EnumFieldElementX(valuesIdentifier,
        enumClass, valuesVariableList, definition, initializer);

    enumClass.addMember(valuesVariable, reporter);

    FunctionExpression toStringNode = builder.functionExpression(
        Modifiers.EMPTY,
        'toString',
        null, // typeVariables
        builder.argumentList([]),
        builder
            .returnStatement(builder.reference(builder.identifier('_name'))));

    EnumMethodElementX toString = new EnumMethodElementX(
        'toString', enumClass, Modifiers.EMPTY, toStringNode);
    FunctionSignatureX toStringSignature = new FunctionSignatureX(
        type: new ResolutionFunctionType(toString, stringType));
    toString.functionSignature = toStringSignature;
    enumClass.addMember(toString, reporter);

    enumClass.enumValues = enumValues;
  }
}
