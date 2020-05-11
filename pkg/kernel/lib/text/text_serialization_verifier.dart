// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

import '../text/serializer_combinators.dart'
    show DeserializationState, SerializationState, TextSerializer;

import '../text/text_reader.dart' show TextIterator;

import '../text/text_serializer.dart'
    show
        dartTypeSerializer,
        expressionSerializer,
        initializeSerializers,
        statementSerializer;

const Uri noUri = null;

const int noOffset = -1;

abstract class TextSerializationVerificationFailure {
  /// [Uri] of the file containing the expression that produced an error during
  /// the round trip.
  final Uri uri;

  /// Offset within the file with [uri] of the expression that produced an error
  /// during the round trip.
  final int offset;

  TextSerializationVerificationFailure(this.uri, this.offset);
}

class TextSerializationFailure extends TextSerializationVerificationFailure {
  final String message;

  TextSerializationFailure(this.message, Uri uri, int offset)
      : super(uri, offset);
}

class TextDeserializationFailure extends TextSerializationVerificationFailure {
  final String message;

  TextDeserializationFailure(this.message, Uri uri, int offset)
      : super(uri, offset);
}

class TextRoundTripFailure extends TextSerializationVerificationFailure {
  final String initial;
  final String serialized;

  TextRoundTripFailure(this.initial, this.serialized, Uri uri, int offset)
      : super(uri, offset);
}

class VerificationState {
  final VerificationState parent;

  final Node node;

  bool allChildrenAreSupported = true;
  final List<Node> roundTripReadyNodes = [];

  final Set<VariableDeclaration> variableDeclarations =
      new Set<VariableDeclaration>.identity();
  final Set<TypeParameter> typeParameters = new Set<TypeParameter>.identity();

  final Set<VariableDeclaration> usedVariables =
      new Set<VariableDeclaration>.identity();
  final Set<TypeParameter> usedTypeParameters =
      new Set<TypeParameter>.identity();

  VerificationState(this.parent, this.node);

  bool get isRoot => parent == null;

  bool get isFullySupported => isSupported(node) && allChildrenAreSupported;

  bool get hasSufficientScope {
    return usedVariables.every((v) => variableDeclarations.contains(v)) &&
        usedTypeParameters.every((p) => typeParameters.contains(p));
  }

  bool get isRoundTripReady => isFullySupported && hasSufficientScope;

  bool isVariableDeclared(VariableDeclaration node) {
    return variableDeclarations.contains(node) ||
        !isRoot && parent.isVariableDeclared(node);
  }

  bool isTypeParameterDeclared(TypeParameter node) {
    return typeParameters.contains(node) ||
        !isRoot && parent.isTypeParameterDeclared(node);
  }

  void handleChild(VerificationState childState) {
    allChildrenAreSupported =
        allChildrenAreSupported && childState.isFullySupported;
  }

  void handleDeclarations() {
    Node node = this.node;
    if (node is VariableDeclaration) {
      parent.variableDeclarations.add(node);
    }
    if (node is TypeParameter) {
      parent.typeParameters.add(node);
    }
    if (node is VariableGet) {
      usedVariables.add(node.variable);
    }
    if (node is VariableSet) {
      usedVariables.add(node.variable);
    }
    if (node is TypeParameterType) {
      usedTypeParameters.add(node.parameter);
    }
  }

  /// Computes round-trip ready nodes or propagates them further in the stack.
  ///
  /// The returned nodes are the roots of maximal-by-inclusion subtrees that are
  /// ready for the round-trip textual serialization.
  List<Node> takeRoundTripReadyNodes() {
    if (isRoot) {
      // If the node is the root of the AST and is round-trip ready, return just
      // the root because it's maximal-by-inclusion.
      // Otherwise, return the nodes collected so far.
      List<Node> result =
          isRoundTripReady ? <Node>[node] : roundTripReadyNodes.toList();
      roundTripReadyNodes.clear();
      return result;
    }

    // The algorithm in this branch is based on the following observations:
    //   - The isFullySupported property is monotonous.  That is, when traveling
    //     from a leaf to the root, the property may only change its value from
    //     true to false.
    //   - The isRoundTripReady property is not monotonous because the sub-tree
    //     that is ready for the round trip shouldn't contain free variables or
    //     free type parameters.
    //   - The isRoundTripReady property implies the isFullySupported property.

    if (!isFullySupported) {
      // We're out of the isFullySupported sub-tree, run the round trip on the
      // nodes that are ready for it so far -- they are maximal-by-inclusion by
      // construction.
      List<Node> result = roundTripReadyNodes.toList();
      roundTripReadyNodes.clear();
      return result;
    } else {
      // We're still in the isFullySupported sub-tree.  It's to early to decide
      // if the collected sub-trees or the node itself are maximal-by-inclusion.
      // The decision should be made in one of the parent nodes.  So, we just
      // propagate the information to the parent, returning an empty list for
      // the current node.
      if (isRoundTripReady) {
        // The current tree is ready for the round trip.  Its sub-trees, which
        // are also round-trip ready, are not maximal-by-inclusion.  So only the
        // node itself is passed to the parent.
        parent.roundTripReadyNodes.add(node);
      } else {
        // The node is not round-trip ready.  The round-trip ready sub-trees
        // collected so far remain the candidates for being
        // maximal-by-inclusion.
        parent.roundTripReadyNodes.addAll(roundTripReadyNodes);
      }
      return const <Node>[];
    }
  }

  /// Passes the necessary information to the parent when popped from the stack.
  void mergeToParent() {
    // Pass the free occurrences of variables and type parameters to the parent.
    if (parent != null) {
      parent.usedVariables
          .addAll(usedVariables.difference(variableDeclarations));
      parent.usedTypeParameters
          .addAll(usedTypeParameters.difference(typeParameters));
      parent.handleChild(this);
    }
  }

  static bool isDartTypeSupported(DartType node) =>
      node is InvalidType ||
      node is DynamicType ||
      node is VoidType ||
      node is BottomType ||
      node is FunctionType ||
      node is TypeParameterType ||
      node is InterfaceType;

  static bool isExpressionSupported(Expression node) =>
      node is StringLiteral ||
      node is SymbolLiteral ||
      node is IntLiteral ||
      node is DoubleLiteral ||
      node is BoolLiteral ||
      node is NullLiteral ||
      node is ListLiteral ||
      node is SetLiteral ||
      node is MapLiteral ||
      node is TypeLiteral ||
      node is InvalidExpression ||
      node is Not ||
      node is LogicalExpression ||
      node is StringConcatenation ||
      node is ThisExpression ||
      node is Rethrow ||
      node is Throw ||
      node is AwaitExpression ||
      node is ConditionalExpression ||
      node is IsExpression ||
      node is AsExpression ||
      node is Let ||
      node is PropertyGet ||
      node is PropertySet ||
      node is SuperPropertyGet ||
      node is SuperPropertySet ||
      node is MethodInvocation ||
      node is SuperMethodInvocation ||
      node is VariableGet ||
      node is VariableSet ||
      node is StaticGet ||
      node is StaticSet ||
      node is DirectPropertyGet ||
      node is DirectPropertySet ||
      node is StaticInvocation ||
      node is DirectMethodInvocation ||
      node is ConstructorInvocation ||
      node is FunctionExpression;

  static bool isStatementSupported(Statement node) =>
      node is ExpressionStatement ||
      node is ReturnStatement && node.expression != null;

  static bool isSupported(Node node) =>
      node is DartType && isDartTypeSupported(node) ||
      node is Expression && isExpressionSupported(node) ||
      node is Statement && isStatementSupported(node);
}

class TextSerializationVerifier extends RecursiveVisitor<void> {
  static const bool showStackTrace = bool.fromEnvironment(
      "text_serialization.showStackTrace",
      defaultValue: false);

  /// List of errors produced during round trips on the visited nodes.
  final List<TextSerializationVerificationFailure> failures =
      <TextSerializationVerificationFailure>[];

  /// List of status for all round-trip serialization attempts.
  final List<RoundTripStatus> status = <RoundTripStatus>[];

  final CanonicalName root;

  Uri lastSeenUri = noUri;

  int lastSeenOffset = noOffset;

  VerificationState _stateStackTop;

  TextSerializationVerifier({CanonicalName root})
      : root = root ?? new CanonicalName.root() {
    initializeSerializers();
  }

  VerificationState get currentState => _stateStackTop;

  void pushStateFor(Node node) {
    _stateStackTop = new VerificationState(_stateStackTop, node);
  }

  void dropState() {
    if (_stateStackTop == null) {
      throw new StateError("Attempting to remove a state from an empty stack.");
    }
    _stateStackTop = _stateStackTop.parent;
  }

  void verify(Node node) => node.accept(this);

  void defaultNode(Node node) {
    enterNode(node);
    node.visitChildren(this);
    exitNode(node);
  }

  void enterNode(node) {
    storeLastSeenUriAndOffset(node);
    pushStateFor(node);
    currentState.handleDeclarations();
  }

  void exitNode(node) {
    if (!identical(node, currentState.node)) {
      throw new StateError("Trying to remove node '${node}' from the stack, "
          "while another node '${currentState.node}' is on the top of it.");
    }
    List<Node> roundTripReadyNodes = currentState.takeRoundTripReadyNodes();
    for (Node node in roundTripReadyNodes) {
      status.add(makeRoundTripDispatch(node));
    }
    currentState.mergeToParent();
    dropState();
  }

  void storeLastSeenUriAndOffset(Node node) {
    if (node is TreeNode) {
      Location location = node.location;
      if (location != null) {
        lastSeenUri = location.file;
        lastSeenOffset = node.fileOffset;
      }
    }
  }

  T readNode<T extends Node>(
      String input, TextSerializer<T> serializer, Uri uri, int offset) {
    TextIterator stream = new TextIterator(input, 0);
    stream.moveNext();
    T result;
    try {
      result =
          serializer.readFrom(stream, new DeserializationState(null, root));
    } catch (exception, stackTrace) {
      String message =
          showStackTrace ? "${exception}\n${stackTrace}" : "${exception}";
      failures.add(new TextDeserializationFailure(message, uri, offset));
    }
    if (stream.moveNext()) {
      failures.add(new TextDeserializationFailure(
          "unexpected trailing text", uri, offset));
    }
    if (result == null) {
      failures.add(new TextDeserializationFailure(
          "Deserialization of the following returned null: '${input}'",
          uri,
          offset));
    }
    return result;
  }

  String writeNode<T extends Node>(
      T node, TextSerializer<T> serializer, Uri uri, int offset) {
    StringBuffer buffer = new StringBuffer();
    try {
      serializer.writeTo(buffer, node, new SerializationState(null));
    } catch (exception, stackTrace) {
      String message =
          showStackTrace ? "${exception}\n${stackTrace}" : "${exception}";
      failures.add(new TextSerializationFailure(message, uri, offset));
    }
    return buffer.toString();
  }

  RoundTripStatus makeRoundTripDispatch(Node node) {
    if (node is DartType) {
      return makeRoundTrip<DartType>(node, dartTypeSerializer);
    } else if (node is Expression) {
      return makeRoundTrip<Expression>(node, expressionSerializer);
    } else if (node is Statement) {
      return makeRoundTrip<Statement>(node, statementSerializer);
    } else {
      throw new StateError(
          "Don't know how to make a round trip for a supported node '${node.runtimeType}'");
    }
  }

  RoundTripStatus makeRoundTrip<T extends Node>(
      T node, TextSerializer<T> serializer) {
    String initial = writeNode(node, serializer, lastSeenUri, lastSeenOffset);

    // Do the round trip.
    T deserialized = readNode(initial, serializer, lastSeenUri, lastSeenOffset);

    // The error is reported elsewhere for the case of null.
    if (deserialized == null) {
      return new RoundTripStatus(false, node, initial);
    }

    String serialized =
        writeNode(deserialized, serializer, lastSeenUri, lastSeenOffset);

    if (initial != serialized) {
      failures.add(new TextRoundTripFailure(
          initial, serialized, lastSeenUri, lastSeenOffset));
      return new RoundTripStatus(false, node, initial);
    }
    return new RoundTripStatus(true, node, initial);
  }
}

class RoundTripStatus implements Comparable<RoundTripStatus> {
  final bool successful;
  final Node node;
  final String serialized;

  RoundTripStatus(this.successful, this.node, this.serialized)
      : assert(successful != null),
        assert(node != null),
        assert(serialized != null);

  void printOn(StringBuffer sb) {
    sb.writeln(
        ";; -----------------------------------------------------------------------------");
    sb.writeln("Status: ${successful ? "OK" : "ERROR"}");
    sb.writeln("Node type: ${node.runtimeType}");
    sb.writeln("Node: ${node.leakingDebugToString()}");
    if (node is TreeNode) {
      TreeNode treeNode = node;
      sb.writeln("Parent type: ${treeNode.parent.runtimeType}");
      sb.writeln("Parent: ${treeNode.parent.leakingDebugToString()}");
    }
    sb.writeln("Serialized: ${serialized}");
    sb.writeln();
  }

  int compareTo(RoundTripStatus other) {
    if (node is TreeNode && other.node is TreeNode) {
      TreeNode thisNode = this.node;
      TreeNode otherNode = other.node;
      Uri thisUri = thisNode.location?.file;
      Uri otherUri = otherNode.location?.file;
      int thisOffset = thisNode.fileOffset;
      int otherOffset = otherNode.fileOffset;

      int compareUri;
      if (thisUri == null && otherUri == null) {
        compareUri = 0;
      } else if (thisUri == null) {
        compareUri = 1;
      } else if (otherUri == null) {
        return -1;
      } else {
        assert(thisUri != null && otherUri != null);
        compareUri = thisUri.toString().compareTo(otherUri.toString());
      }
      if (compareUri != 0) return compareUri;

      int compareOffset;
      if (thisOffset == null && otherOffset == null) {
        compareOffset = 0;
      } else if (thisOffset == null) {
        compareOffset = 1;
      } else if (otherOffset == null) {
        compareOffset = -1;
      } else {
        compareOffset = thisOffset = otherOffset;
      }
      if (compareOffset != 0) return compareOffset;

      if (!successful && other.successful) {
        return -1;
      } else if (successful && !other.successful) {
        return 1;
      }

      return serialized.compareTo(other.serialized);
    } else if (node is TreeNode) {
      return -1;
    } else {
      return 1;
    }
  }
}
