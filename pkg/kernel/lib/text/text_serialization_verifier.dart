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

class TextSerializationVerifier {
  static const bool showStackTrace = bool.fromEnvironment(
      "text_serialization.showStackTrace",
      defaultValue: false);

  /// List of status for all round-trip serialization attempts.
  final List<RoundTripStatus> _status = <RoundTripStatus>[];

  final CanonicalName root;

  TextSerializationVerifier({CanonicalName root})
      : root = root ?? new CanonicalName.root() {
    initializeSerializers();
  }

  /// List of errors produced during round trips on the visited nodes.
  Iterable<RoundTripStatus> get _failures => _status.where((s) => s.isFailure);

  List<RoundTripStatus> get failures => _failures.toList()..sort();

  void verify(Library node) {
    makeRoundTrip<Library>(node, librarySerializer);
  }

  T readNode<T extends TreeNode>(
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
      _status.add(
          new RoundTripDeserializationFailure(node, message, context: node));
      return null;
    }
    if (stream.moveNext()) {
      _status.add(new RoundTripDeserializationFailure(
          node, "unexpected trailing text",
          context: node));
    }
    if (result == null) {
      _status.add(new RoundTripDeserializationFailure(
          node, "Deserialization of the following returned null: '${input}'",
          context: node));
    }
    return result;
  }

  String writeNode<T extends TreeNode>(T node, TextSerializer<T> serializer) {
    StringBuffer buffer = new StringBuffer();
    try {
      serializer.writeTo(buffer, node,
          new SerializationState(new SerializationEnvironment(null)));
    } catch (exception, stackTrace) {
      String message =
          showStackTrace ? "${exception}\n${stackTrace}" : "${exception}";
      _status.add(new RoundTripInitialSerializationFailure(node, message,
          context: node));
    }
    return buffer.toString();
  }

  void makeRoundTrip<T extends TreeNode>(T node, TextSerializer<T> serializer) {
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
          context: node));
    } else {
      _status.add(new RoundTripSuccess(node, initial, context: node));
    }
  }

  List<RoundTripStatus> takeStatus() {
    List<RoundTripStatus> result = _status.toList()..sort();
    _status.clear();
    return result;
  }
}
