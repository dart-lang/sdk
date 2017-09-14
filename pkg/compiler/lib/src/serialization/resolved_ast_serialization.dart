// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.resolved_ast;

import 'package:front_end/src/fasta/parser.dart' show Parser, ParserError;
import 'package:front_end/src/fasta/scanner.dart';

import '../common.dart';
import '../common/resolution.dart';
import '../constants/expressions.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/elements.dart';
import '../elements/jumps.dart';
import '../elements/modelx.dart';
import '../elements/resolution_types.dart';
import '../parser/node_listener.dart' show NodeListener;
import '../resolution/enum_creator.dart';
import '../resolution/send_structure.dart';
import '../resolution/tree_elements.dart';
import '../tree/tree.dart';
import '../universe/selector.dart';
import 'keys.dart';
import 'modelz.dart';
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
  ENUM_NAME_FIELD,
  ENUM_VALUES_FIELD,
  ENUM_TO_STRING,
  FACTORY,
  FIELD,
  FUNCTION,
}

/// Serializer for [ResolvedAst]s.
class ResolvedAstSerializer extends Visitor {
  final SerializerPlugin nativeDataSerializer;
  final ObjectEncoder objectEncoder;
  final ResolvedAst resolvedAst;
  final AstIndexComputer indexComputer = new AstIndexComputer();
  final Map<int, ObjectEncoder> nodeData = <int, ObjectEncoder>{};
  ListEncoder _nodeDataEncoder;

  ResolvedAstSerializer(
      this.objectEncoder, this.resolvedAst, this.nativeDataSerializer);

  AstElement get element => resolvedAst.element;

  TreeElements get elements => resolvedAst.elements;

  Node get root => resolvedAst.node;

  Map<Node, int> get nodeIndices => indexComputer.nodeIndices;
  List<Node> get nodeList => indexComputer.nodeList;

  Map<JumpTarget, int> jumpTargetMap = <JumpTarget, int>{};
  Map<LabelDefinition, int> labelDefinitionMap = <LabelDefinition, int>{};

  /// Returns the unique id for [jumpTarget], creating it if necessary.
  int getJumpTargetId(JumpTarget jumpTarget) {
    return jumpTargetMap.putIfAbsent(jumpTarget, () => jumpTargetMap.length);
  }

  /// Returns the unique id for [labelDefinition], creating it if necessary.
  int getLabelDefinitionId(LabelDefinition labelDefinition) {
    return labelDefinitionMap.putIfAbsent(
        labelDefinition, () => labelDefinitionMap.length);
  }

  /// Serializes [resolvedAst] into [objectEncoder].
  void serialize() {
    objectEncoder.setEnum(Key.KIND, resolvedAst.kind);
    switch (resolvedAst.kind) {
      case ResolvedAstKind.PARSED:
        serializeParsed();
        break;
      case ResolvedAstKind.DEFAULT_CONSTRUCTOR:
      case ResolvedAstKind.FORWARDING_CONSTRUCTOR:
      case ResolvedAstKind.DEFERRED_LOAD_LIBRARY:
        // No additional properties.
        break;
    }
  }

  /// Serialize [ResolvedAst] that is defined in terms of an AST together with
  /// [TreeElements].
  void serializeParsed() {
    objectEncoder.setUri(Key.URI, resolvedAst.sourceUri, resolvedAst.sourceUri);
    AstKind kind;
    if (element.enclosingClass is EnumClassElement) {
      if (element.name == 'index') {
        kind = AstKind.ENUM_INDEX_FIELD;
      } else if (element.name == '_name') {
        kind = AstKind.ENUM_NAME_FIELD;
      } else if (element.name == 'values') {
        kind = AstKind.ENUM_VALUES_FIELD;
      } else if (element.name == 'toString') {
        kind = AstKind.ENUM_TO_STRING;
      } else if (element.isConstructor) {
        kind = AstKind.ENUM_CONSTRUCTOR;
      } else {
        assert(element.isConst,
            failedAt(element, "Unexpected enum member: $element"));
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
    objectEncoder.setEnum(Key.SUB_KIND, kind);
    root.accept(indexComputer);
    objectEncoder.setBool(Key.CONTAINS_TRY, elements.containsTryStatement);
    if (resolvedAst.body != null) {
      int index = nodeIndices[resolvedAst.body];
      assert(
          index != null,
          failedAt(
              element,
              "No index for body of $element: "
              "${resolvedAst.body} ($nodeIndices)."));
      objectEncoder.setInt(Key.BODY, index);
    }
    root.accept(this);
    if (jumpTargetMap.isNotEmpty) {
      ListEncoder list = objectEncoder.createList(Key.JUMP_TARGETS);
      for (JumpTarget jumpTarget in jumpTargetMap.keys) {
        serializeJumpTarget(jumpTarget, list.createObject());
      }
    }
    if (labelDefinitionMap.isNotEmpty) {
      ListEncoder list = objectEncoder.createList(Key.LABEL_DEFINITIONS);
      for (LabelDefinition labelDefinition in labelDefinitionMap.keys) {
        serializeLabelDefinition(labelDefinition, list.createObject());
      }
    }

    if (element is FunctionElement) {
      serializeParameterNodes(element);
    }
  }

  void serializeParameterNodes(FunctionElement function) {
    function.functionSignature.forEachParameter((_parameter) {
      ParameterElement parameter = _parameter;
      ParameterElement parameterImpl = parameter.implementation;
      // TODO(johnniwinther): Should we support element->node mapping as well?
      getNodeDataEncoder(parameterImpl.node)
          .setElement(PARAMETER_NODE, parameter);
      if (parameter.initializer != null) {
        getNodeDataEncoder(parameterImpl.initializer)
            .setElement(PARAMETER_INITIALIZER, parameter);
      }
    });
  }

  /// Serialize [target] into [encoder].
  void serializeJumpTarget(JumpTargetX jumpTarget, ObjectEncoder encoder) {
    encoder.setElement(Key.EXECUTABLE_CONTEXT, jumpTarget.executableContext);
    encoder.setInt(Key.NODE, nodeIndices[jumpTarget.statement]);
    encoder.setInt(Key.NESTING_LEVEL, jumpTarget.nestingLevel);
    encoder.setBool(Key.IS_BREAK_TARGET, jumpTarget.isBreakTarget);
    encoder.setBool(Key.IS_CONTINUE_TARGET, jumpTarget.isContinueTarget);
    if (jumpTarget.labels.isNotEmpty) {
      List<int> labelIdList = <int>[];
      for (LabelDefinition label in jumpTarget.labels) {
        labelIdList.add(getLabelDefinitionId(label));
      }
      encoder.setInts(Key.LABELS, labelIdList);
    }
  }

  /// Serialize [label] into [encoder].
  void serializeLabelDefinition(
      LabelDefinitionX labelDefinition, ObjectEncoder encoder) {
    encoder.setInt(Key.NODE, nodeIndices[labelDefinition.label]);
    encoder.setString(Key.NAME, labelDefinition.labelName);
    encoder.setBool(Key.IS_BREAK_TARGET, labelDefinition.isBreakTarget);
    encoder.setBool(Key.IS_CONTINUE_TARGET, labelDefinition.isContinueTarget);
    encoder.setInt(Key.JUMP_TARGET, getJumpTargetId(labelDefinition.target));
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
    assert(node != null, failedAt(element, "Node must be non-null."));
    int id = nodeIndices[node];
    assert(id != null, failedAt(element, "Node without id: $node"));
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
      serializeElementReference(element, Key.ELEMENT, Key.NAME,
          getNodeDataEncoder(node), nodeElement);
    }
    ResolutionDartType type = elements.getType(node);
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
    ResolutionDartType cachedType = elements.typesCache[node];
    if (cachedType != null) {
      getNodeDataEncoder(node).setType(Key.CACHED_TYPE, cachedType);
    }
    JumpTarget jumpTargetDefinition = elements.getTargetDefinition(node);
    if (jumpTargetDefinition != null) {
      getNodeDataEncoder(node).setInt(
          Key.JUMP_TARGET_DEFINITION, getJumpTargetId(jumpTargetDefinition));
    }
    var nativeData = elements.getNativeData(node);
    if (nativeData != null) {
      nativeDataSerializer.onData(
          nativeData, getNodeDataEncoder(node).createObject(Key.NATIVE));
    }
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
    JumpTarget jumpTarget = elements.getTargetOf(node);
    if (jumpTarget != null) {
      getNodeDataEncoder(node)
          .setInt(Key.JUMP_TARGET, getJumpTargetId(jumpTarget));
    }
    if (node.target != null) {
      LabelDefinition targetLabel = elements.getTargetLabel(node);
      if (targetLabel != null) {
        getNodeDataEncoder(node)
            .setInt(Key.TARGET_LABEL, getLabelDefinitionId(targetLabel));
      }
    }
  }

  @override
  visitLabel(Label node) {
    visitNode(node);
    LabelDefinition labelDefinition = elements.getLabelDefinition(node);
    if (labelDefinition != null) {
      getNodeDataEncoder(node)
          .setInt(Key.LABEL_DEFINITION, getLabelDefinitionId(labelDefinition));
    }
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    visitExpression(node);
    Element function = elements.getFunctionDefinition(node);
    if (function != null && function.isFunction && function.isLocal) {
      // Mark root nodes of local functions; these need their own ResolvedAst.
      getNodeDataEncoder(node).setElement(Key.FUNCTION, function);
      serializeParameterNodes(function);
    }
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

  /// Deserializes the [ResolvedAst]s for [element] and its nested local
  /// functions from [objectDecoder] and adds these to [resolvedAstMap].
  /// [parsing] and [getBeginToken] are used for parsing the [Node] for
  /// [element] from its source code.
  static void deserialize(
      Element element,
      ObjectDecoder objectDecoder,
      ParsingContext parsing,
      Token getBeginToken(Uri uri, int charOffset),
      DeserializerPlugin nativeDataDeserializer) {
    ResolvedAstKind kind =
        objectDecoder.getEnum(Key.KIND, ResolvedAstKind.values);
    switch (kind) {
      case ResolvedAstKind.PARSED:
        deserializeParsed(element, objectDecoder, parsing, getBeginToken,
            nativeDataDeserializer);
        break;
      case ResolvedAstKind.DEFAULT_CONSTRUCTOR:
      case ResolvedAstKind.FORWARDING_CONSTRUCTOR:
        (element as AstElementMixinZ).resolvedAst =
            new SynthesizedResolvedAst(element, kind);
        break;
      case ResolvedAstKind.DEFERRED_LOAD_LIBRARY:
        break;
    }
  }

  /// Deserialize the [ResolvedAst]s for the member [element] (constructor,
  /// method, or field) and its nested closures. The [ResolvedAst]s are added
  /// to [resolvedAstMap].
  static void deserializeParsed(
      AstElementMixinZ element,
      ObjectDecoder objectDecoder,
      ParsingContext parsing,
      Token getBeginToken(Uri uri, int charOffset),
      DeserializerPlugin nativeDataDeserializer) {
    DiagnosticReporter reporter = parsing.reporter;
    Uri uri = objectDecoder.getUri(Key.URI);

    /// Returns the first [Token] for parsing the [Node] for [element].
    Token readBeginToken() {
      int charOffset = objectDecoder.getInt(Key.OFFSET);
      Token beginToken = getBeginToken(uri, charOffset);
      if (beginToken == null) {
        // TODO(johnniwinther): Handle unfound tokens by adding an erroneous
        // resolved ast kind.
        reporter.internalError(
            element, "No token found for $element in $uri @ $charOffset");
      }
      return beginToken;
    }

    /// Create the [Node] for the element by parsing the source code.
    Node doParse(parse(Parser parser)) {
      return parsing.measure(() {
        return reporter.withCurrentElement(element, () {
          NodeListener listener = new NodeListener(
              parsing.getScannerOptionsFor(element), reporter, null);
          listener.memberErrors = listener.memberErrors.prepend(false);
          try {
            Parser parser = new Parser(listener);
            parse(parser);
          } on ParserError catch (e) {
            reporter.internalError(element, '$e');
          }
          return listener.popNode();
        });
      });
    }

    /// Computes the [Node] for the element based on the [AstKind].
    // ignore: MISSING_RETURN
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
        case AstKind.ENUM_NAME_FIELD:
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          Identifier identifier = builder.identifier('_name');
          VariableDefinitions node = new VariableDefinitions(
              null,
              builder.modifiers(isFinal: true),
              new NodeList.singleton(identifier));
          return node;
        case AstKind.ENUM_VALUES_FIELD:
          EnumClassElement enumClass = element.enclosingClass;
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
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
              null,
              builder.argumentList([]),
              builder.returnStatement(
                  builder.reference(builder.identifier('_name'))));
          return toStringNode;
        case AstKind.ENUM_CONSTRUCTOR:
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          VariableDefinitions indexDefinition =
              builder.initializingFormal('index');
          VariableDefinitions nameDefinition =
              builder.initializingFormal('_name');
          FunctionExpression constructorNode = builder.functionExpression(
              builder.modifiers(isConst: true),
              element.enclosingClass.name,
              null,
              builder.argumentList([indexDefinition, nameDefinition]),
              builder.emptyStatement());
          return constructorNode;
        case AstKind.ENUM_CONSTANT:
          EnumConstantElementZ enumConstant = element;
          EnumClassElement enumClass = element.enclosingClass;
          int index = enumConstant.index;
          AstBuilder builder = new AstBuilder(element.sourcePosition.begin);
          Identifier name = builder.identifier(element.name);

          String enumString = "${enumClass.name}.${element.name}";
          Expression initializer = builder.newExpression(
              enumClass.name,
              builder.argumentList([
                builder.literalInt(index),
                builder.literalString(enumString)
              ]),
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
                  "${uri} @ $getOrSetOffset");
            }
          }
          return doParse((parser) {
            parser.parseMember(beginToken);
          });
      }
    }

    AstKind kind = objectDecoder.getEnum(Key.SUB_KIND, AstKind.values);
    Node root = computeNode(kind);
    TreeElementMapping elements = new TreeElementMapping(element);
    AstIndexComputer indexComputer = new AstIndexComputer();
    List<Node> nodeList = indexComputer.nodeList;
    root.accept(indexComputer);
    elements.containsTryStatement = objectDecoder.getBool(Key.CONTAINS_TRY);

    Node body;
    int bodyNodeIndex = objectDecoder.getInt(Key.BODY, isOptional: true);
    if (bodyNodeIndex != null) {
      assert(
          bodyNodeIndex < nodeList.length,
          failedAt(
              element,
              "Body node index ${bodyNodeIndex} out of range. "
              "Node count: ${nodeList.length}"));
      body = nodeList[bodyNodeIndex];
    }

    List<JumpTarget> jumpTargets = <JumpTarget>[];
    Map<JumpTarget, List<int>> jumpTargetLabels = <JumpTarget, List<int>>{};
    List<LabelDefinition> labelDefinitions = <LabelDefinition>[];

    ListDecoder jumpTargetsDecoder =
        objectDecoder.getList(Key.JUMP_TARGETS, isOptional: true);
    if (jumpTargetsDecoder != null) {
      for (int i = 0; i < jumpTargetsDecoder.length; i++) {
        ObjectDecoder decoder = jumpTargetsDecoder.getObject(i);
        ExecutableElement executableContext =
            decoder.getElement(Key.EXECUTABLE_CONTEXT);
        Node statement = nodeList[decoder.getInt(Key.NODE)];
        int nestingLevel = decoder.getInt(Key.NESTING_LEVEL);
        JumpTargetX jumpTarget =
            new JumpTargetX(statement, nestingLevel, executableContext);
        jumpTarget.isBreakTarget = decoder.getBool(Key.IS_BREAK_TARGET);
        jumpTarget.isContinueTarget = decoder.getBool(Key.IS_CONTINUE_TARGET);
        jumpTargetLabels[jumpTarget] =
            decoder.getInts(Key.LABELS, isOptional: true);
        jumpTargets.add(jumpTarget);
      }
    }

    ListDecoder labelDefinitionsDecoder =
        objectDecoder.getList(Key.LABEL_DEFINITIONS, isOptional: true);
    if (labelDefinitionsDecoder != null) {
      for (int i = 0; i < labelDefinitionsDecoder.length; i++) {
        ObjectDecoder decoder = labelDefinitionsDecoder.getObject(i);
        Label label = nodeList[decoder.getInt(Key.NODE)];
        String labelName = decoder.getString(Key.NAME);
        JumpTarget target = jumpTargets[decoder.getInt(Key.JUMP_TARGET)];
        LabelDefinitionX labelDefinition =
            new LabelDefinitionX(label, labelName, target);
        labelDefinition.isBreakTarget = decoder.getBool(Key.IS_BREAK_TARGET);
        labelDefinition.isContinueTarget =
            decoder.getBool(Key.IS_CONTINUE_TARGET);
        labelDefinitions.add(labelDefinition);
      }
    }
    jumpTargetLabels.forEach((JumpTarget jumpTarget, List<int> labelIds) {
      if (labelIds.isEmpty) return;
      List<LabelDefinition> labels = <LabelDefinition>[];
      for (int labelId in labelIds) {
        labels.add(labelDefinitions[labelId]);
      }
      JumpTargetX target = jumpTarget;
      target.labels = labels;
    });

    ListDecoder dataDecoder = objectDecoder.getList(Key.DATA, isOptional: true);
    if (dataDecoder != null) {
      for (int i = 0; i < dataDecoder.length; i++) {
        ObjectDecoder objectDecoder = dataDecoder.getObject(i);
        int id = objectDecoder.getInt(Key.ID);
        Node node = nodeList[id];
        Element nodeElement = deserializeElementReference(
            element, Key.ELEMENT, Key.NAME, objectDecoder,
            isOptional: true);
        if (nodeElement != null) {
          elements[node] = nodeElement;
        }
        ResolutionDartType type =
            objectDecoder.getType(Key.TYPE, isOptional: true);
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
        ResolutionDartType cachedType =
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
        int targetDefinitionId =
            objectDecoder.getInt(Key.JUMP_TARGET_DEFINITION, isOptional: true);
        if (targetDefinitionId != null) {
          elements.defineTarget(node, jumpTargets[targetDefinitionId]);
        }
        int targetOfId =
            objectDecoder.getInt(Key.JUMP_TARGET, isOptional: true);
        if (targetOfId != null) {
          elements.registerTargetOf(node, jumpTargets[targetOfId]);
        }
        int labelDefinitionId =
            objectDecoder.getInt(Key.LABEL_DEFINITION, isOptional: true);
        if (labelDefinitionId != null) {
          elements.defineLabel(node, labelDefinitions[labelDefinitionId]);
        }
        int targetLabelId =
            objectDecoder.getInt(Key.TARGET_LABEL, isOptional: true);
        if (targetLabelId != null) {
          elements.registerTargetLabel(node, labelDefinitions[targetLabelId]);
        }
        ObjectDecoder nativeDataDecoder =
            objectDecoder.getObject(Key.NATIVE, isOptional: true);
        if (nativeDataDecoder != null) {
          var nativeData = nativeDataDeserializer.onData(nativeDataDecoder);
          if (nativeData != null) {
            elements.registerNativeData(node, nativeData);
          }
        }
        LocalFunctionElementZ function =
            objectDecoder.getElement(Key.FUNCTION, isOptional: true);
        if (function != null) {
          FunctionExpression functionExpression = node;
          function.resolvedAst = new ParsedResolvedAst(function,
              functionExpression, functionExpression.body, elements, uri);
        }
        // TODO(johnniwinther): Remove these when inference doesn't need `.node`
        // and `.initializer` of [ParameterElement]s.
        ParameterElementZ parameter =
            objectDecoder.getElement(PARAMETER_NODE, isOptional: true);
        if (parameter != null) {
          parameter.node = node;
        }
        parameter =
            objectDecoder.getElement(PARAMETER_INITIALIZER, isOptional: true);
        if (parameter != null) {
          parameter.initializer = node;
        }
      }
    }
    element.resolvedAst =
        new ParsedResolvedAst(element, root, body, elements, uri);
  }
}

const Key PARAMETER_NODE = const Key('parameter.node');
const Key PARAMETER_INITIALIZER = const Key('parameter.initializer');
