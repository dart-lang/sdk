// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is for use in extracting messages from a Dart program
 * using the Intl.message() mechanism and writing them to a file for
 * translation. This provides only the stub of a mechanism, because it
 * doesn't define how the file should be written. It provides an
 * [IntlMessage] class that holds the extracted data and [parseString]
 * and [parseFile] methods which
 * can extract messages that conform to the expected pattern:
 *       (parameters) => Intl.message("Message $parameters", desc: ...);
 * It uses the analyzer_experimental package to do the parsing, so may
 * break if there are changes to the API that it provides.
 * An example can be found in test/message_extraction/extract_to_json.dart
 *
 * Note that this does not understand how to follow part directives, so it
 * has to explicitly be given all the files that it needs. A typical use case
 * is to run it on all .dart files in a directory.
 */
library extract_messages;

import 'dart:io';

import 'package:analyzer_experimental/analyzer.dart';
import 'package:intl/src/intl_message.dart';

/**
 * If this is true, print warnings for skipped messages. Otherwise, warnings
 * are suppressed.
 */
bool suppressWarnings = false;

/**
 * Parse the source of the Dart program file [file] and return a Map from
 * message names to [IntlMessage] instances.
 */
Map<String, IntlMessage> parseFile(File file) {
  var unit = parseDartFile(file.path);
  var visitor = new MessageFindingVisitor(unit, file.path);
  unit.accept(visitor);
  return visitor.messages;
}

/**
 * This visits the program source nodes looking for Intl.message uses
 * that conform to its pattern and then finding the
 */
class MessageFindingVisitor extends GeneralizingASTVisitor {

  /**
   * The root of the compilation unit, and the first node we visit. We hold
   * on to this for error reporting, as it can give us line numbers of other
   * nodes.
   */
  final CompilationUnit root;

  /**
   * An arbitrary string describing where the source code came from. Most
   * obviously, this could be a file path. We use this when reporting
   * invalid messages.
   */
  final String origin;

  MessageFindingVisitor(this.root, this.origin);

  /**
   * Accumulates the messages we have found.
   */
  final Map<String, IntlMessage> messages = new Map<String, IntlMessage>();

  /**
   * We keep track of the data from the last MethodDeclaration,
   * FunctionDeclaration or FunctionExpression that we saw on the way down,
   * as that will be the nearest parent of the Intl.message invocation.
   */
  FormalParameterList parameters;
  String name;

  /** Return true if [node] matches the pattern we expect for Intl.message() */
  bool looksLikeIntlMessage(MethodInvocation node) {
    if (node.methodName.name != "message") return false;
    if (!(node.target is SimpleIdentifier)) return false;
    SimpleIdentifier target = node.target;
    if (target.token.toString() != "Intl") return false;
    return true;
  }

  /**
   * Returns a String describing why the node is invalid, or null if no
   * reason is found, so it's presumed valid.
   */
  String checkValidity(MethodInvocation node) {
    // The containing function cannot have named parameters.
    if (parameters.parameters.any((each) => each.kind == ParameterKind.NAMED)) {
      return "Named parameters on message functions are not supported.";
    }
    var arguments = node.argumentList.arguments;
    if (!(arguments.first is StringLiteral)) {
      return "Intl.message messages must be string literals";
    }
    var namedArguments = arguments.skip(1);
    // This seems unlikely to happen, but make sure all are NamedExpression
    // before doing the tests below.
    if (!namedArguments.every((each) => each is NamedExpression)) {
      return "Message arguments except the message must be named";
    }
    var notArgs = namedArguments.where(
        (each) => each.name.label.name != 'args');
    var values = notArgs.map((each) => each.expression).toList();
    if (!values.every((each) => each is SimpleStringLiteral)) {
      "Intl.message arguments must be simple string literals";
    }
    if (!notArgs.any((each) => each.name.label.name == 'name')) {
      return "The 'name' argument for Intl.message must be specified";
    }
    var hasArgs = namedArguments.any((each) => each.name.label.name == 'args');
    var hasParameters = !parameters.parameters.isEmpty;
    if (!hasArgs && hasParameters) {
      return "The 'args' argument for Intl.message must be specified";
    }
    return null;
  }

  /**
   * Record the parameters of the function or method declaration we last
   * encountered before seeing the Intl.message call.
   */
  void visitMethodDeclaration(MethodDeclaration node) {
    parameters = node.parameters;
    String name = node.name.name;
    super.visitMethodDeclaration(node);
  }

  /**
   * Record the parameters of the function or method declaration we last
   * encountered before seeing the Intl.message call.
   */
  void visitFunctionExpression(FunctionExpression node) {
    parameters = node.parameters;
    name = null;
    super.visitFunctionExpression(node);
  }

  /**
   * Record the parameters of the function or method declaration we last
   * encountered before seeing the Intl.message call.
   */
  void visitFunctionDeclaration(FunctionDeclaration node) {
    parameters = node.functionExpression.parameters;
    name = node.name.name;
    super.visitFunctionDeclaration(node);
  }

  /**
   * Examine method invocations to see if they look like calls to Intl.message.
   */
  void visitMethodInvocation(MethodInvocation node) {
    addIntlMessage(node);
    return super.visitNode(node);
  }

  /**
   * Check that the node looks like an Intl.message invocation, and create
   * the [IntlMessage] object from it and store it in [messages].
   */
  void addIntlMessage(MethodInvocation node) {
    if (!looksLikeIntlMessage(node)) return;
    var reason = checkValidity(node);
    if (reason != null && !suppressWarnings) {
      print("Skipping invalid Intl.message invocation\n    <$node>");
      print("    reason: $reason");
      reportErrorLocation(node);
      return;
    }
    var message = messageFromMethodInvocation(node);
    if (message != null) messages[message.name] = message;
  }

  /**
   * Create an IntlMessage from [node] using the name and
   * parameters of the last function/method declaration we encountered
   * and the parameters to the Intl.message call.
   */
  IntlMessage messageFromMethodInvocation(MethodInvocation node) {
    var message = new IntlMessage();
    message.name = name;
    message.arguments = parameters.parameters.elements.map(
        (x) => x.identifier.name).toList();
    try {
      node.accept(new MessageVisitor(message));
    } on IntlMessageExtractionException catch (e) {
      message = null;
      print("Error $e");
      print("Processing <$node>");
      reportErrorLocation(node);
    }
    return message;
  }

  void reportErrorLocation(ASTNode node) {
    if (origin != null) print("    from $origin");
    var info = root.lineInfo;
    if (info != null) {
      var line = info.getLocation(node.offset);
      print("    line: ${line.lineNumber}, column: ${line.columnNumber}");
    }
  }
}

/**
 * Given a node that looks like an invocation of Intl.message, extract out
 * the message and the parameters and store them in [target].
 */
class MessageVisitor extends GeneralizingASTVisitor {
  IntlMessage target;

  MessageVisitor(IntlMessage this.target);

  /**
   * Extract out the message string. If it's an interpolation, turn it into
   * a single string with interpolation characters.
   */
  void visitArgumentList(ArgumentList node) {
    var interpolation = new InterpolationVisitor(target);
    node.arguments.elements.first.accept(interpolation);
    target.messagePieces = interpolation.pieces;
    super.visitArgumentList(node);
  }

  /**
   * Find the values of all the named arguments, remove quotes, and save them
   * into [target].
   */
  void visitNamedExpression(NamedExpression node) {
    var name = node.name.label.name;
    var exp = node.expression;
    var string = exp is SimpleStringLiteral ? exp.value : exp.toString();
    target[name] = string;
    super.visitNamedExpression(node);
  }
}

/**
 * Given an interpolation, find all of its chunks, validate that they are only
 * simple interpolations, and keep track of the chunks so that other parts
 * of the program can deal with the interpolations and the simple string
 * sections separately.
 */
class InterpolationVisitor extends GeneralizingASTVisitor {
  IntlMessage message;

  InterpolationVisitor(this.message);

  List pieces = [];
  String get extractedMessage => pieces.join();

  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    pieces.add(node.value);
    super.visitSimpleStringLiteral(node);
  }

  void visitInterpolationString(InterpolationString node) {
    pieces.add(node.value);
    super.visitInterpolationString(node);
  }

  // TODO(alanknight): The limitation to simple identifiers is important
  // to avoid letting translators write arbitrary code, but is a problem
  // for plurals.
  void visitInterpolationExpression(InterpolationExpression node) {
    if (node.expression is! SimpleIdentifier) {
      throw new IntlMessageExtractionException(
          "Only simple identifiers are allowed in message "
          "interpolation expressions.\nError at $node");
    }
    var index = arguments.indexOf(node.expression.toString());
    if (index == -1) {
      throw new IntlMessageExtractionException(
          "Cannot find argument ${node.expression}");
    }
    pieces.add(index);
    super.visitInterpolationExpression(node);
  }

  List get arguments => message.arguments;
}

/**
 * Exception thrown when we cannot process a message properly.
 */
class IntlMessageExtractionException implements Exception {
  /**
   * A message describing the error.
   */
  final String message;

  /**
   * Creates a new exception with an optional error [message].
   */
  const IntlMessageExtractionException([this.message = ""]);

  String toString() => "IntlMessageExtractionException: $message";
}