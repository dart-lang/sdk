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
Map<String, MainMessage> parseFile(File file) {
  _root = parseDartFile(file.path);
  _origin = file.path;
  var visitor = new MessageFindingVisitor();
  _root.accept(visitor);
  return visitor.messages;
}

/**
 * The root of the compilation unit, and the first node we visit. We hold
 * on to this for error reporting, as it can give us line numbers of other
 * nodes.
 */
CompilationUnit _root;

/**
 * An arbitrary string describing where the source code came from. Most
 * obviously, this could be a file path. We use this when reporting
 * invalid messages.
 */
String _origin;

void _reportErrorLocation(ASTNode node) {
  if (_origin != null) print("    from $_origin");
  var info = _root.lineInfo;
  if (info != null) {
    var line = info.getLocation(node.offset);
    print("    line: ${line.lineNumber}, column: ${line.columnNumber}");
  }
}

/**
 * This visits the program source nodes looking for Intl.message uses
 * that conform to its pattern and then creating the corresponding
 * IntlMessage objects. We have to find both the enclosing function, and
 * the Intl.message invocation.
 */
class MessageFindingVisitor extends GeneralizingASTVisitor {

  MessageFindingVisitor();

  /**
   * Accumulates the messages we have found, keyed by name.
   */
  final Map<String, MainMessage> messages = new Map<String, MainMessage>();

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
      _reportErrorLocation(node);
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
  MainMessage messageFromMethodInvocation(MethodInvocation node) {
    var message = new MainMessage();
    message.name = name;
    message.arguments = parameters.parameters.elements.map(
        (x) => x.identifier.name).toList();
    var arguments = node.argumentList.arguments.elements;
    try {
      var interpolation = new InterpolationVisitor(message);
      arguments.first.accept(interpolation);
      message.messagePieces.addAll(interpolation.pieces);
    } on IntlMessageExtractionException catch (e) {
      message = null;
      print("Error $e");
      print("Processing <$node>");
      _reportErrorLocation(node);
    }
    for (NamedExpression namedArgument in arguments.skip(1)) {
      var name = namedArgument.name.label.name;
      var exp = namedArgument.expression;
      var string = exp is SimpleStringLiteral ? exp.value : exp.toString();
      message[name] = string;
    }
    return message;
  }
}

/**
 * Given an interpolation, find all of its chunks, validate that they are only
 * simple variable substitutions or else Intl.plural/gender calls,
 * and keep track of the pieces of text so that other parts
 * of the program can deal with the simple string sections and the generated
 * parts separately. Note that this is a SimpleASTVisitor, so it only
 * traverses one level of children rather than automatically recursing. If we
 * find a plural or gender, which requires recursion, we do it with a separate
 * special-purpose visitor.
 */
class InterpolationVisitor extends SimpleASTVisitor {
  Message message;

  InterpolationVisitor(this.message);

  List pieces = [];
  String get extractedMessage => pieces.join();

  void visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    super.visitAdjacentStrings(node);
  }

  void visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    super.visitStringInterpolation(node);
  }

  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    pieces.add(node.value);
    super.visitSimpleStringLiteral(node);
  }

  void visitInterpolationString(InterpolationString node) {
    pieces.add(node.value);
    super.visitInterpolationString(node);
  }

  void visitInterpolationExpression(InterpolationExpression node) {
    if (node.expression is SimpleIdentifier) {
      return handleSimpleInterpolation(node);
    } else {
      return lookForPluralOrGender(node);
    }
    // Note that we never end up calling super.
  }

  lookForPluralOrGender(InterpolationExpression node) {
    var visitor = new PluralAndGenderVisitor(pieces, message);
    node.accept(visitor);
    if (!visitor.foundPluralOrGender) {
      throw new IntlMessageExtractionException(
        "Only simple identifiers and Intl.plural/gender/select expressions "
        "are allowed in message "
        "interpolation expressions.\nError at $node");
    }
  }

  void handleSimpleInterpolation(InterpolationExpression node) {
    var index = arguments.indexOf(node.expression.toString());
    if (index == -1) {
      throw new IntlMessageExtractionException(
          "Cannot find argument ${node.expression}");
    }
    pieces.add(index);
  }

  List get arguments => message.arguments;
}

/**
 * A visitor to extract information from Intl.plural/gender sends. Note that
 * this is a SimpleASTVisitor, so it doesn't automatically recurse. So this
 * needs to be called where we expect a plural or gender immediately below.
 */
class PluralAndGenderVisitor extends SimpleASTVisitor {
  /**
   * A plural or gender always exists in the context of a parent message,
   * which could in turn also be a plural or gender.
   */
  ComplexMessage parent;

  /**
   * The pieces of the message. We are given an initial version of this
   * from our parent and we add to it as we find additional information.
   */
  List pieces;

  PluralAndGenderVisitor(this.pieces, this.parent) : super() {}

  /** This will be set to true if we find a plural or gender. */
  bool foundPluralOrGender = false;

  visitInterpolationExpression(InterpolationExpression node) {
    // TODO(alanknight): Provide better errors for malformed expressions.
    if (!looksLikePluralOrGender(node.expression)) return;
    var reason = checkValidity(node.expression);
    if (reason != null) throw reason;
    var message = messageFromMethodInvocation(node.expression);
    foundPluralOrGender = true;
    pieces.add(message);
    super.visitInterpolationExpression(node);
  }

  /** Return true if [node] matches the pattern we expect for Intl.message() */
  bool looksLikePluralOrGender(MethodInvocation node) {
    if (!["plural", "gender"].contains(node.methodName.name)) return false;
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
    // TODO(alanknight): Add reasonable validity checks.
  }

  /**
   * Create a MainMessage from [node] using the name and
   * parameters of the last function/method declaration we encountered
   * and the parameters to the Intl.message call.
   */
  messageFromMethodInvocation(MethodInvocation node) {
    var message;
    if (node.methodName.name == "gender") {
      message = new Gender();
    } else if (node.methodName.name == "plural") {
      message = new Plural();
    } else {
      throw new IntlMessageExtractionException("Invalid plural/gender message");
    }
    message.parent = parent;

    var arguments = node.argumentList.arguments.elements;
    for (var arg in arguments.where((each) => each is NamedExpression)) {
      try {
        var interpolation = new InterpolationVisitor(message);
        arg.expression.accept(interpolation);
        message[arg.name.label.token.toString()] = interpolation.pieces;
      } on IntlMessageExtractionException catch (e) {
        message = null;
        print("Error $e");
        print("Processing <$node>");
        _reportErrorLocation(node);
      }
    }
    var mainArg = node.argumentList.arguments.elements.firstWhere(
        (each) => each is! NamedExpression);
    if (mainArg is SimpleStringLiteral) {
      message.mainArgument = mainArg.toString();
    } else {
      message.mainArgument = mainArg.name;
    }
    return message;
  }
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