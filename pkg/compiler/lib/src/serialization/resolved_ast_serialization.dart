// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.resolved_ast;

import '../common.dart';
import '../common/resolution.dart';
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/elements.dart';
import '../parser/parser.dart' show Parser;
import '../parser/listener.dart' show ParserError;
import '../parser/node_listener.dart' show NodeListener;
import '../resolution/enum_creator.dart';
import '../resolution/send_structure.dart';
import '../resolution/tree_elements.dart';
import '../tree/tree.dart';
import '../tokens/token.dart';
import '../universe/selector.dart';
import 'keys.dart';
import 'serialization.dart';
import 'serialization_util.dart';

/// Visitor that computes a node-index mapping.
class AstIndexComputer extends Visitor {
  final Map<Node, int> nodeIndices = <Node, int>{};
  final List<Node> nodeList = <Node>[];

  @override
  visitNode(Node node) {
    nodeIndices.putIfAbsent(node, () {
      // Some nodes (like Modifier and empty NodeList) can be reused.
      nodeList.add(node);
      return nodeIndices.length;
    });
    node.visitChildren(this);
  }
}

/// The kind of AST node. Used for determining how to deserialize
/// [ResolvedAst]s.
enum AstKind {
  ENUM_CONSTRUCTOR,
  ENUM_CONSTANT,
  ENUM_INDEX_FIELD,
  ENUM_VALUES_FIELD,
  ENUM_TO_STRING,
  FACTORY,
  FIELD,
  FUNCTION,
}

/// Serializer for [ResolvedAst]s.
class ResolvedAstSerializer extends Visitor {
  final ObjectEncoder objectEncoder;
  final ResolvedAst resolvedAst;
  final AstIndexComputer indexComputer = new AstIndexComputer();
  final Map<int, ObjectEncoder> nodeData = <int, ObjectEncoder>{};
  ListEncoder _nodeDataEncoder;

  ResolvedAstSerializer(this.objectEncoder, this.resolvedAst);

  AstElement get element => resolvedAst.element;

  TreeElements get elements => resolvedAst.elements;

  Node get root => resolvedAst.node;

  Map<Node, int> get nodeIndices => indexComputer.nodeIndices;
  List<Node> get nodeList => indexComputer.nodeList;

  /// Serializes [resolvedAst] into [objectEncoder].
  void serialize() {
    objectEncoder.setUri(
        Key.URI,
        elements.analyzedElement.compilationUnit.script.resourceUri,
        elements.analyzedElement.compilationUnit.script.resourceUri);
    AstKind kind;
    if (element.enclosingClass is EnumClassElement) {
      if (element.name == 'index') {
        kind = AstKind.ENUM_INDEX_FIELD;
      } else if (element.name == 'values') {
        kind = AstKind.ENUM_VALUES_FIELD;
      } else if (element.name == 'toString') {
        kind = AstKind.ENUM_TO_STRING;
      } else if (element.isConstructor) {
        kind = AstKind.ENUM_CONSTRUCTOR;
      } else {
        assert(invariant(element, element.isConst,
            message: "Unexpected enum member: $element"));
        kind = AstKind.ENUM_CONSTANT;
      }
    } else {
      // [element] has a body that we'll need to re-parse. We store where to
      // start parsing from.
      objectEncoder.setInt(Key.OFFSET, root.getBeginToken().charOffset);
      if (element.isFactoryConstructor) {
        kind = AstKind.FACTORY;
      } else if (element.isField) {
        kind = AstKind.FIELD;
      } else {
        kind = AstKind.FUNCTION;
        FunctionExpression functionExpression = root.asFunctionExpression();
        if (functionExpression.getOrSet != null) {
          // Getters/setters need the get/set token to be parsed.
          objectEncoder.setInt(
              Key.GET_OR_SET, functionExpression.getOrSet.charOffset);
        }
      }
    }
    objectEncoder.setEnum(Key.KIND, kind);
    root.accept(indexComputer);
    root.accept(this);
  }

  /// Computes the [ListEncoder] for serializing data for nodes.
  ListEncoder get nodeDataEncoder {
    if (_nodeDataEncoder == null) {
      _nodeDataEncoder = objectEncoder.createList(Key.DATA);
    }
    return _nodeDataEncoder;
  }

  /// Computes the [ObjectEncoder] for serializing data for [node].
  ObjectEncoder getNodeDataEncoder(Node node) {
    int id = nodeIndices[node];
    return nodeData.putIfAbsent(id, () {
      ObjectEncoder objectEncoder = nodeDataEncoder.createObject();
      objectEncoder.setInt(Key.ID, id);
      return objectEncoder;
    });
  }

  @override
  visitNode(Node node) {
    Element nodeElement = elements[node];
    if (nodeElement != null) {
      if (nodeElement.enclosingClass != null &&
          nodeElement.enclosingClass.isUnnamedMixinApplication) {
        // TODO(johnniwinther): Handle references to members of unnamed mixin
        // applications.
      } else {
        getNodeDataEncoder(node).setElement(Key.ELEMENT, nodeElement);
      }
    }
    DartType type = elements.getType(node);
    if (type != null) {
      getNodeDataEncoder(node).setType(Key.TYPE, type);
    }
    Selector selector = elements.getSelector(node);
    if (selector != null) {
      serializeSelector(
          selector, getNodeDataEncoder(node).createObject(Key.SELECTOR));
    }
    ConstantExpression constant = elements.getConstant(node);
    if (constant != null) {
      getNodeDataEncoder(node).setConstant(Key.CONSTANT, constant);
    }
    DartType cachedType = elements.typesCache[node];
    if (cachedType != null) {
      getNodeDataEncoder(node).setType(Key.CACHED_TYPE, cachedType);
    }
    // TODO(johnniwinther): Serialize [JumpTarget]s.
    node.visitChildren(this);
  }

  @override
  visitSend(Send node) {
    visitExpression(node);
    SendStructure structure = elements.getSendStructure(node);
    if (structure != null) {
      serializeSendStructure(
          structure, getNodeDataEncoder(node).createObject(Key.SEND_STRUCTURE));
    }
  }

  @override
  visitNewExpression(NewExpression node) {
    visitExpression(node);
    NewStructure structure = elements.getNewStructure(node);
    if (structure != null) {
      serializeNewStructure(
          structure, getNodeDataEncoder(node).createObject(Key.NEW_STRUCTURE));
    }
  }

  @override
  visitGotoStatement(GotoStatement node) {
    visitStatement(node);
    // TODO(johnniwinther): Serialize [JumpTarget]s and [LabelDefinition]s.
  }

  @override
  visitLabel(Label node) {
    visitNode(node);
    // TODO(johnniwinther): Serialize[LabelDefinition]s.
  }
}

class ResolvedAstDeserializer {
  /// Find the [Token] at [offset] searching through successors of [token].
  static Token findTokenInStream(Token token, int offset) {
    while (token.charOffset <= offset && token.next != token) {
      if (token.charOffset == offset) {
        return token;
      }
      token = token.next;
    }
    return null;
  }

  /// Deserializes the [ResolvedAst] for [element] from [objectDecoder].
  /// [parsing] and [getBeginToken] are used for parsing the [Node] for
  /// [element] from its source code.
  static ResolvedAst deserialize(Element element, ObjectDecoder objectDecoder,
      Parsing parsing, Token getBeginToken(Uri uri, int charOffset)) {
    CompilationUnitElement compilationUnit = element.compilationUnit;
    DiagnosticReporter reporter = parsing.reporter;

    /// Returns the first [Token] for parsing the [Node] for [element].
    Token readBeginToken() {
      Uri uri = objectDecoder.getUri(Key.URI);
      int charOffset = objectDecoder.getInt(Key.OFFSET);
      Token beginToken = getBeginToken(uri, charOffset);
      if (beginToken == null) {
        reporter.internalError(
            element, "No token found for $element in $uri @ $charOffset");
      }
      return beginToken;
    }

    /// Create the [Node] for the element by parsing the source code.
    Node doParse(parse(Parser parser)) {
      return parsing.measure(() {
        return reporter.withCurrentElement(element, () {
          CompilationUnitElement unit = element.compilationUnit;
          NodeListener listener = new NodeListener(
              parsing.getScannerOptionsFor(element), reporter, null);
          listener.memberErrors = listener.memberErrors.prepend(false);
          try {
            Parser parser = new Parser(listener, parsing.parserOptions);
            parse(parser);
          } on ParserError catch (e) {
            reporter.internalError(element, '$e');
          }
          return listener.popNode();
        });
      });
    }

    /// Computes the [Node] for the element based on the [AstKind].
    Node computeNode(AstKind kind) {
      switch (kind) {
        case AstKind.ENUM_INDEX_FIELD:
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          Identifier identifier = builder.identifier('index');
          VariableDefinitions node = new VariableDefinitions(
              null,
              builder.modifiers(isFinal: true),
              new NodeList.singleton(identifier));
          return node;
        case AstKind.ENUM_VALUES_FIELD:
          EnumClassElement enumClass = element.enclosingClass;
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          List<FieldElement> enumValues = <FieldElement>[];
          List<Node> valueReferences = <Node>[];
          for (EnumConstantElement enumConstant in enumClass.enumValues) {
            AstBuilder valueBuilder =
                new AstBuilder(enumConstant.sourcePosition.begin);
            Identifier name = valueBuilder.identifier(enumConstant.name);

            // Add reference for the `values` field.
            valueReferences.add(valueBuilder.reference(name));
          }

          Identifier valuesIdentifier = builder.identifier('values');
          // TODO(johnniwinther): Add type argument.
          Expression initializer =
              builder.listLiteral(valueReferences, isConst: true);

          Node definition =
              builder.createDefinition(valuesIdentifier, initializer);
          VariableDefinitions node = new VariableDefinitions(
              null,
              builder.modifiers(isStatic: true, isConst: true),
              new NodeList.singleton(definition));
          return node;
        case AstKind.ENUM_TO_STRING:
          EnumClassElement enumClass = element.enclosingClass;
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          List<LiteralMapEntry> mapEntries = <LiteralMapEntry>[];
          for (EnumConstantElement enumConstant in enumClass.enumValues) {
            AstBuilder valueBuilder =
                new AstBuilder(enumConstant.sourcePosition.begin);
            Identifier name = valueBuilder.identifier(enumConstant.name);

            // Add map entry for `toString` implementation.
            mapEntries.add(valueBuilder.mapLiteralEntry(
                valueBuilder.literalInt(enumConstant.index),
                valueBuilder
                    .literalString('${enumClass.name}.${name.source}')));
          }

          // TODO(johnniwinther): Support return type. Note `String` might be
          // prefixed or not imported within the current library.
          FunctionExpression toStringNode = builder.functionExpression(
              Modifiers.EMPTY,
              'toString',
              builder.argumentList([]),
              builder.returnStatement(builder.indexGet(
                  builder.mapLiteral(mapEntries, isConst: true),
                  builder.reference(builder.identifier('index')))));
          return toStringNode;
        case AstKind.ENUM_CONSTRUCTOR:
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          VariableDefinitions indexDefinition =
              builder.initializingFormal('index');
          FunctionExpression constructorNode = builder.functionExpression(
              builder.modifiers(isConst: true),
              element.enclosingClass.name,
              builder.argumentList([indexDefinition]),
              builder.emptyStatement());
          return constructorNode;
        case AstKind.ENUM_CONSTANT:
          EnumConstantElement enumConstant = element;
          EnumClassElement enumClass = element.enclosingClass;
          int index = enumConstant.index;
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          Identifier name = builder.identifier(element.name);

          Expression initializer = builder.newExpression(
              enumClass.name, builder.argumentList([builder.literalInt(index)]),
              isConst: true);
          SendSet definition = builder.createDefinition(name, initializer);

          VariableDefinitions node = new VariableDefinitions(
              null,
              builder.modifiers(isStatic: true, isConst: true),
              new NodeList.singleton(definition));
          return node;
        case AstKind.FACTORY:
          Token beginToken = readBeginToken();
          return doParse((parser) => parser.parseFactoryMethod(beginToken));
        case AstKind.FIELD:
          Token beginToken = readBeginToken();
          return doParse((parser) => parser.parseMember(beginToken));
        case AstKind.FUNCTION:
          Token beginToken = readBeginToken();
          int getOrSetOffset =
              objectDecoder.getInt(Key.GET_OR_SET, isOptional: true);
          Token getOrSet;
          if (getOrSetOffset != null) {
            getOrSet = findTokenInStream(beginToken, getOrSetOffset);
            if (getOrSet == null) {
              reporter.internalError(
                  element,
                  "No token found for $element in "
                  "${objectDecoder.getUri(Key.URI)} @ $getOrSetOffset");
            }
          }
          return doParse((parser) {
            parser.parseFunction(beginToken, getOrSet);
          });
      }
    }

    AstKind kind = objectDecoder.getEnum(Key.KIND, AstKind.values);
    Node root = computeNode(kind);
    TreeElementMapping elements = new TreeElementMapping(element);
    AstIndexComputer indexComputer = new AstIndexComputer();
    Map<Node, int> nodeIndices = indexComputer.nodeIndices;
    List<Node> nodeList = indexComputer.nodeList;
    root.accept(indexComputer);
    ListDecoder dataDecoder = objectDecoder.getList(Key.DATA);
    if (dataDecoder != null) {
      for (int i = 0; i < dataDecoder.length; i++) {
        ObjectDecoder objectDecoder = dataDecoder.getObject(i);
        int id = objectDecoder.getInt(Key.ID);
        Node node = nodeList[id];
        Element nodeElement =
            objectDecoder.getElement(Key.ELEMENT, isOptional: true);
        if (nodeElement != null) {
          elements[node] = nodeElement;
        }
        DartType type = objectDecoder.getType(Key.TYPE, isOptional: true);
        if (type != null) {
          elements.setType(node, type);
        }
        ObjectDecoder selectorDecoder =
            objectDecoder.getObject(Key.SELECTOR, isOptional: true);
        if (selectorDecoder != null) {
          elements.setSelector(node, deserializeSelector(selectorDecoder));
        }
        ConstantExpression constant =
            objectDecoder.getConstant(Key.CONSTANT, isOptional: true);
        if (constant != null) {
          elements.setConstant(node, constant);
        }
        DartType cachedType =
            objectDecoder.getType(Key.CACHED_TYPE, isOptional: true);
        if (cachedType != null) {
          elements.typesCache[node] = cachedType;
        }
        ObjectDecoder sendStructureDecoder =
            objectDecoder.getObject(Key.SEND_STRUCTURE, isOptional: true);
        if (sendStructureDecoder != null) {
          elements.setSendStructure(
              node, deserializeSendStructure(sendStructureDecoder));
        }
        ObjectDecoder newStructureDecoder =
            objectDecoder.getObject(Key.NEW_STRUCTURE, isOptional: true);
        if (newStructureDecoder != null) {
          elements.setNewStructure(
              node, deserializeNewStructure(newStructureDecoder));
        }
      }
    }
    return new ResolvedAst(element, root, elements);
  }
}
