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

class VerificationStatus {
  final Node node;
  int childrenCount = 0;
  final List<Node> supportedChildren = [];

  VerificationStatus(this.node);

  bool isFullySupported(TextSerializationVerifier verifier) {
    return verifier.isSupported(node) &&
        childrenCount == supportedChildren.length;
  }

  void addChild(Node child, bool isSupported) {
    ++childrenCount;
    if (isSupported) supportedChildren.add(child);
  }
}

class TextSerializationVerifier extends RecursiveVisitor<void> {
  static const bool showStackTrace = bool.fromEnvironment(
      "text_serialization.showStackTrace",
      defaultValue: false);

  /// List of errors produced during round trips on the visited nodes.
  final List<TextSerializationVerificationFailure> failures =
      <TextSerializationVerificationFailure>[];

  final CanonicalName root;

  Uri lastSeenUri = noUri;

  int lastSeenOffset = noOffset;

  List<VerificationStatus> _statusStack = [];

  TextSerializationVerifier({CanonicalName root})
      : root = root ?? new CanonicalName.root() {
    initializeSerializers();
  }

  bool get isRoot => _statusStack.isEmpty;

  VerificationStatus get currentStatus => _statusStack.last;

  void pushStatus(VerificationStatus status) {
    _statusStack.add(status);
  }

  VerificationStatus popStatus() {
    return _statusStack.removeLast();
  }

  void verify(Node node) {}

  void defaultNode(Node node) {
    enterNode(node);
    node.visitChildren(this);
    bool isFullySupported = exitNode(node);
    if (isFullySupported) {
      if (node is DartType) {
        makeRoundTrip<DartType>(node, dartTypeSerializer);
      } else if (node is Expression) {
        makeRoundTrip<Expression>(node, expressionSerializer);
      } else if (node is Statement) {
        makeRoundTrip<Statement>(node, statementSerializer);
      } else {
        throw new StateError(
            "Don't know how to make a round trip for a supported node '${node.runtimeType}'");
      }
    }
  }

  void enterNode(node) {
    storeLastSeenUriAndOffset(node);
    pushStatus(new VerificationStatus(node));
  }

  bool exitNode(node) {
    if (!identical(node, currentStatus.node)) {
      throw new StateError("Trying to remove node '${node}' from the stack, "
          "while another node '${currentStatus.node}' is on the top of it.");
    }
    VerificationStatus status = popStatus();
    bool isFullySupported = status.isFullySupported(this);
    if (!isRoot) {
      currentStatus.addChild(node, isFullySupported);
    }
    return isFullySupported;
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

  void makeRoundTrip<T extends Node>(T node, TextSerializer<T> serializer) {
    String initial = writeNode(node, serializer, lastSeenUri, lastSeenOffset);

    // Do the round trip.
    T deserialized = readNode(initial, serializer, lastSeenUri, lastSeenOffset);

    // The error is reported elsewhere for the case of null.
    if (deserialized == null) return;

    String serialized =
        writeNode(deserialized, serializer, lastSeenUri, lastSeenOffset);

    if (initial != serialized) {
      failures.add(new TextRoundTripFailure(
          initial, serialized, lastSeenUri, lastSeenOffset));
    }
  }

  bool isDartTypeSupported(DartType node) =>
      node is InvalidType ||
      node is DynamicType ||
      node is VoidType ||
      node is BottomType ||
      node is FunctionType ||
      node is TypeParameterType;

  bool isExpressionSupported(Expression node) =>
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

  bool isStatementSupported(Statement node) =>
      node is ExpressionStatement || node is ReturnStatement;

  bool isSupported(Node node) =>
      node is DartType && isDartTypeSupported(node) ||
      node is Expression && isExpressionSupported(node) ||
      node is Statement && isStatementSupported(node);
}
