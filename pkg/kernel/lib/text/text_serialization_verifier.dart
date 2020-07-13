// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;

import '../ast.dart';

import '../text/serializer_combinators.dart';

import '../text/text_reader.dart' show TextIterator;

import '../text/text_serializer.dart';

const Uri noUri = null;

const int noOffset = -1;

abstract class RoundTripStatus implements Comparable<RoundTripStatus> {
  /// The round-trip serialization was run on that [node].
  final Node node;

  /// The context of the failure.
  ///
  /// The [context] node is a [TreeNode] and is set either to the node that the
  /// round-trip serialization failed on or to the closest parent with location.
  final TreeNode context;

  RoundTripStatus(this.node, {TreeNode context})
      : context = node is TreeNode && node.location != null ? node : context;

  Uri get uri => context?.location?.file;

  int get offset => context?.fileOffset;

  bool get isSuccess;

  bool get isFailure => !isSuccess;

  String get nameForDebugging;

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
        compareUri = -1;
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

      // The "success" outcome has the lowest index.  Make it so that it appears
      // last, and the failures are at the beginning and are more visible.
      if (isFailure && other.isSuccess) {
        return -1;
      }
      if (isSuccess && other.isFailure) {
        return 1;
      }

      return 0;
    } else if (node is TreeNode) {
      return -1;
    } else {
      return 1;
    }
  }

  void printOn(StringBuffer sb) {
    sb.writeln(""
        ";; -------------------------------------"
        "----------------------------------------");
    sb.writeln("Status: ${nameForDebugging}");
    sb.writeln("Node type: ${node.runtimeType}");
    sb.writeln("Node: ${json.encode(node.leakingDebugToString())}");
    if (node is TreeNode) {
      TreeNode treeNode = node;
      if (treeNode.parent != null) {
        sb.writeln("Parent type: ${treeNode.parent.runtimeType}");
        sb.writeln(
            "Parent: ${json.encode(treeNode.parent.leakingDebugToString())}");
      }
    }
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    printOn(sb);
    return sb.toString();
  }
}

class RoundTripSuccess extends RoundTripStatus {
  final String serialized;

  RoundTripSuccess(Node node, this.serialized, {TreeNode context})
      : super(node, context: context);

  @override
  bool get isSuccess => true;

  @override
  String get nameForDebugging => "RoundTripSuccess";

  @override
  void printOn(StringBuffer sb) {
    super.printOn(sb);
    sb.writeln("Serialized: ${serialized}");
  }
}

class RoundTripInitialSerializationFailure extends RoundTripStatus {
  final String message;

  RoundTripInitialSerializationFailure(Node node, this.message,
      {TreeNode context})
      : super(node, context: context);

  @override
  bool get isSuccess => false;

  @override
  String get nameForDebugging => "RoundTripInitialSerializationFailure";

  @override
  void printOn(StringBuffer sb) {
    super.printOn(sb);
    sb.writeln("Message: ${message}");
  }
}

class RoundTripDeserializationFailure extends RoundTripStatus {
  final String message;

  RoundTripDeserializationFailure(Node node, this.message, {TreeNode context})
      : super(node, context: context);

  @override
  bool get isSuccess => false;

  @override
  String get nameForDebugging => "RoundTripDeserializationFailure";

  @override
  void printOn(StringBuffer sb) {
    super.printOn(sb);
    sb.writeln("Message: ${message}");
  }
}

class RoundTripSecondSerializationFailure extends RoundTripStatus {
  final String initial;
  final String serialized;

  RoundTripSecondSerializationFailure(Node node, this.initial, this.serialized,
      {TreeNode context})
      : super(node, context: context);

  @override
  bool get isSuccess => false;

  @override
  String get nameForDebugging => "RoundTripSecondSerializationFailure";

  @override
  void printOn(StringBuffer sb) {
    super.printOn(sb);
    sb.writeln("Initial: ${initial}");
    sb.writeln("Serialized: ${serialized}");
  }
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

  static bool isSupported(Node node) => !isNotSupported(node);

  static bool isNotSupported(Node node) => false;
}

class TextSerializationVerifier extends RecursiveVisitor<void> {
  static const bool showStackTrace = bool.fromEnvironment(
      "text_serialization.showStackTrace",
      defaultValue: false);

  /// List of status for all round-trip serialization attempts.
  final List<RoundTripStatus> _status = <RoundTripStatus>[];

  final CanonicalName root;

  VerificationState _stateStackTop;

  TextSerializationVerifier({CanonicalName root})
      : root = root ?? new CanonicalName.root() {
    initializeSerializers();
  }

  /// List of errors produced during round trips on the visited nodes.
  Iterable<RoundTripStatus> get _failures => _status.where((s) => s.isFailure);

  List<RoundTripStatus> get failures => _failures.toList()..sort();

  VerificationState get currentState => _stateStackTop;

  TreeNode get lastSeenTreeNodeWithLocation {
    VerificationState state = _stateStackTop;
    while (state != null) {
      Node node = state.node;
      if (node is TreeNode && node.location != null) {
        return node;
      }
      state = state.parent;
    }
    return null;
  }

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
      makeRoundTripDispatch(node);
    }
    currentState.mergeToParent();
    dropState();
  }

  T readNode<T extends Node>(
      T node, String input, TextSerializer<T> serializer) {
    TextIterator stream = new TextIterator(input, 0);
    stream.moveNext();
    T result;
    try {
      result = serializer.readFrom(stream,
          new DeserializationState(new DeserializationEnvironment(null), root));
    } catch (exception, stackTrace) {
      String message =
          showStackTrace ? "${exception}\n${stackTrace}" : "${exception}";
      _status.add(new RoundTripDeserializationFailure(node, message,
          context: lastSeenTreeNodeWithLocation));
      return null;
    }
    if (stream.moveNext()) {
      _status.add(new RoundTripDeserializationFailure(
          node, "unexpected trailing text",
          context: lastSeenTreeNodeWithLocation));
    }
    if (result == null) {
      _status.add(new RoundTripDeserializationFailure(
          node, "Deserialization of the following returned null: '${input}'",
          context: lastSeenTreeNodeWithLocation));
    }
    return result;
  }

  String writeNode<T extends Node>(T node, TextSerializer<T> serializer) {
    StringBuffer buffer = new StringBuffer();
    try {
      serializer.writeTo(buffer, node,
          new SerializationState(new SerializationEnvironment(null)));
    } catch (exception, stackTrace) {
      String message =
          showStackTrace ? "${exception}\n${stackTrace}" : "${exception}";
      _status.add(new RoundTripInitialSerializationFailure(node, message,
          context: lastSeenTreeNodeWithLocation));
    }
    return buffer.toString();
  }

  void makeRoundTripDispatch(Node node) {
    if (node is DartType) {
      makeRoundTrip<DartType>(node, dartTypeSerializer);
    } else if (node is Expression) {
      makeRoundTrip<Expression>(node, expressionSerializer);
    } else if (node is Statement) {
      makeRoundTrip<Statement>(node, statementSerializer);
    } else if (node is Arguments) {
      makeRoundTrip<Arguments>(node, argumentsSerializer);
    } else if (node is FunctionNode) {
      makeRoundTrip<FunctionNode>(node, functionNodeSerializer);
    } else if (node is Member) {
      makeRoundTrip<Member>(node, memberSerializer);
    } else if (node is TypeParameter) {
      makeRoundTrip<TypeParameter>(node, typeParameterSerializer);
    } else if (node is NamedType) {
      makeRoundTrip<NamedType>(node, namedTypeSerializer);
    } else if (node is Name) {
      makeRoundTrip<Name>(node, nameSerializer);
    } else if (node is Combinator) {
      makeRoundTrip<Combinator>(node, showHideSerializer);
    } else if (node is LibraryDependency) {
      makeRoundTrip<LibraryDependency>(node, libraryDependencySerializer);
    } else if (node is Catch) {
      makeRoundTrip<Catch>(node, catchSerializer);
    } else if (node is SwitchCase) {
      makeRoundTrip<SwitchCase>(node, switchCaseSerializer);
    } else if (node is Initializer) {
      makeRoundTrip<Initializer>(node, initializerSerializer);
    } else if (node is Supertype) {
      makeRoundTrip<Supertype>(node, supertypeSerializer);
    } else if (node is Class) {
      makeRoundTrip<Class>(node, classSerializer);
    } else if (node is Extension) {
      makeRoundTrip<Extension>(node, extensionSerializer);
    } else if (node is Typedef) {
      makeRoundTrip<Typedef>(node, typedefSerializer);
    } else if (node is LibraryPart) {
      makeRoundTrip<LibraryPart>(node, libraryPartSerializer);
    } else if (node is Library) {
      makeRoundTrip<Library>(node, librarySerializer);
    } else if (node is Component) {
      makeRoundTrip<Component>(node, componentSerializer);
    } else {
      throw new StateError(
          "Don't know how to make a round trip for a supported node "
          "'${node.runtimeType}'");
    }
  }

  void makeRoundTrip<T extends Node>(T node, TextSerializer<T> serializer) {
    int failureCount = _failures.length;
    String initial = writeNode(node, serializer);
    if (_failures.length != failureCount) {
      return;
    }

    // Do the round trip.
    T deserialized = readNode(node, initial, serializer);
    if (_failures.length != failureCount) {
      return;
    }

    if (deserialized == null) {
      // The error is reported elsewhere for the case of null.
      return;
    }

    String serialized = writeNode(deserialized, serializer);
    if (_failures.length != failureCount) {
      return;
    }

    if (initial != serialized) {
      _status.add(new RoundTripSecondSerializationFailure(
          node, initial, serialized,
          context: lastSeenTreeNodeWithLocation));
    } else {
      _status.add(new RoundTripSuccess(node, initial,
          context: lastSeenTreeNodeWithLocation));
    }
  }

  List<RoundTripStatus> takeStatus() {
    List<RoundTripStatus> result = _status.toList()..sort();
    _status.clear();
    return result;
  }
}
