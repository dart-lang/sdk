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
 * It uses the analyzer package to do the parsing, so may
 * break if there are changes to the API that it provides.
 * An example can be found in test/message_extraction/extract_to_json.dart
 *
 * Note that this does not understand how to follow part directives, so it
 * has to explicitly be given all the files that it needs. A typical use case
 * is to run it on all .dart files in a directory.
 */
library extract_messages;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:intl/src/intl_message.dart';

/**
 * If this is true, print warnings for skipped messages. Otherwise, warnings
 * are suppressed.
 */
bool suppressWarnings = false;

/**
 * If this is true, then treat all warnings as errors.
 */
bool warningsAreErrors = false;

/**
 * This accumulates a list of all warnings/errors we have found. These are
 * saved as strings right now, so all that can really be done is print and
 * count them.
 */
List<String> warnings = [];

/** Were there any warnings or errors in extracting messages. */
bool get hasWarnings => warnings.isNotEmpty;

/**
 * Parse the source of the Dart program file [file] and return a Map from
 * message names to [IntlMessage] instances.
 */
Map<String, MainMessage> parseFile(File file) {
  try {
    _root = parseDartFile(file.path);
  } on AnalyzerErrorGroup catch (e) {
    print("Error in parsing ${file.path}, no messages extracted.");
    print("  $e");
    return {};
  }
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

String _reportErrorLocation(AstNode node) {
  var result = new StringBuffer();
  if (_origin != null) result.write("    from $_origin");
  var info = _root.lineInfo;
  if (info != null) {
    var line = info.getLocation(node.offset);
    result.write("    line: ${line.lineNumber}, column: ${line.columnNumber}");
  }
  return result.toString();
}

/**
 * This visits the program source nodes looking for Intl.message uses
 * that conform to its pattern and then creating the corresponding
 * IntlMessage objects. We have to find both the enclosing function, and
 * the Intl.message invocation.
 */
class MessageFindingVisitor extends GeneralizingAstVisitor {

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
    const validNames = const ["message", "plural", "gender", "select"];
    if (!validNames.contains(node.methodName.name)) return false;
    if (!(node.target is SimpleIdentifier)) return false;
    SimpleIdentifier target = node.target;
    return target.token.toString() == "Intl";
  }

  Message _expectedInstance(String type) {
    switch (type) {
      case 'message' : return new MainMessage();
      case 'plural' : return new Plural();
      case 'gender' : return new Gender();
      case 'select' : return new Select();
      default: return null;
    }
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
    var instance = _expectedInstance(node.methodName.name);
    return instance.checkValidity(node, arguments, name, parameters);
  }

  /**
   * Record the parameters of the function or method declaration we last
   * encountered before seeing the Intl.message call.
   */
  void visitMethodDeclaration(MethodDeclaration node) {
    parameters = node.parameters;
    if (parameters == null) {
      parameters = new FormalParameterList(null, [], null, null, null);
    }
    name = node.name.name;
    super.visitMethodDeclaration(node);
  }

  /**
   * Record the parameters of the function or method declaration we last
   * encountered before seeing the Intl.message call.
   */
  void visitFunctionDeclaration(FunctionDeclaration node) {
    parameters = node.functionExpression.parameters;
    if (parameters == null) {
      parameters = new FormalParameterList(null, [], null, null, null);
    }
    name = node.name.name;
    super.visitFunctionDeclaration(node);
  }

  /**
   * Examine method invocations to see if they look like calls to Intl.message.
   * If we've found one, stop recursing. This is important because we can have
   * Intl.message(...Intl.plural...) and we don't want to treat the inner
   * plural as if it was an outermost message.
   */
  void visitMethodInvocation(MethodInvocation node) {
    if (!addIntlMessage(node)) {
      super.visitMethodInvocation(node);
    }
  }

  /**
   * Check that the node looks like an Intl.message invocation, and create
   * the [IntlMessage] object from it and store it in [messages]. Return true
   * if we successfully extracted a message and should stop looking. Return
   * false if we didn't, so should continue recursing.
   */
  bool addIntlMessage(MethodInvocation node) {
    if (!looksLikeIntlMessage(node)) return false;
    var reason = checkValidity(node);
    if (reason != null) {
      if (!suppressWarnings) {
        var err = new StringBuffer()
            ..write("Skipping invalid Intl.message invocation\n    <$node>\n")
            ..writeAll(["    reason: $reason\n", _reportErrorLocation(node)]);
        warnings.add(err.toString());
        print(err);
      }
      // We found one, but it's not valid. Stop recursing.
      return true;
    }
    var message;
    if (node.methodName.name == "message") {
      message = messageFromIntlMessageCall(node);
    } else {
      message = messageFromDirectPluralOrGenderCall(node);
    }
    if (message != null) messages[message.name] = message;
    return true;
  }

  /**
   * Create a MainMessage from [node] using the name and
   * parameters of the last function/method declaration we encountered,
   * and the values we get by calling [extract]. We set those values
   * by calling [setAttribute]. This is the common parts between
   * [messageFromIntlMessageCall] and [messageFromDirectPluralOrGenderCall].
   */
  MainMessage _messageFromNode(MethodInvocation node, Function extract,
      Function setAttribute) {
    var message = new MainMessage();
    message.name = name;
    message.arguments = parameters.parameters.map(
        (x) => x.identifier.name).toList();
    var arguments = node.argumentList.arguments;
    extract(message, arguments);

    for (var namedArgument in arguments.where((x) => x is NamedExpression)) {
      var name = namedArgument.name.label.name;
      var exp = namedArgument.expression;
      var evaluator = new ConstantEvaluator();
      var basicValue = exp.accept(evaluator);
      var value = basicValue == ConstantEvaluator.NOT_A_CONSTANT ?
          exp.toString() : basicValue;
      setAttribute(message, name, value);
    }
    return message;
  }

  /**
   * Create a MainMessage from [node] using the name and
   * parameters of the last function/method declaration we encountered
   * and the parameters to the Intl.message call.
   */
  MainMessage messageFromIntlMessageCall(MethodInvocation node) {

    void extractFromIntlCall(MainMessage message, List arguments) {
      try {
        var interpolation = new InterpolationVisitor(message);
        arguments.first.accept(interpolation);
        message.messagePieces.addAll(interpolation.pieces);
      } on IntlMessageExtractionException catch (e) {
        message = null;
        var err = new StringBuffer()
            ..writeAll(["Error ", e, "\nProcessing <", node, ">\n"])
            ..write(_reportErrorLocation(node));
        print(err);
        warnings.add(err);
      }
    }

    void setValue(MainMessage message, String fieldName, Object fieldValue) {
      message[fieldName] = fieldValue;
    }

    return _messageFromNode(node, extractFromIntlCall, setValue);
  }

  /**
   * Create a MainMessage from [node] using the name and
   * parameters of the last function/method declaration we encountered
   * and the parameters to the Intl.plural or Intl.gender call.
   */
  MainMessage messageFromDirectPluralOrGenderCall(MethodInvocation node) {
    var pluralOrGender;

    void extractFromPluralOrGender(MainMessage message, _) {
      var visitor = new PluralAndGenderVisitor(message.messagePieces, message);
      node.accept(visitor);
      pluralOrGender = message.messagePieces.last;
    }

    void setAttribute(MainMessage msg, String fieldName, String fieldValue) {
      if (msg.attributeNames.contains(fieldName)) {
        msg[fieldName] = fieldValue;
      }
    }
    return _messageFromNode(node, extractFromPluralOrGender, setAttribute);
  }
}

/**
 * Given an interpolation, find all of its chunks, validate that they are only
 * simple variable substitutions or else Intl.plural/gender calls,
 * and keep track of the pieces of text so that other parts
 * of the program can deal with the simple string sections and the generated
 * parts separately. Note that this is a SimpleAstVisitor, so it only
 * traverses one level of children rather than automatically recursing. If we
 * find a plural or gender, which requires recursion, we do it with a separate
 * special-purpose visitor.
 */
class InterpolationVisitor extends SimpleAstVisitor {
  final Message message;

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
 * this is a SimpleAstVisitor, so it doesn't automatically recurse. So this
 * needs to be called where we expect a plural or gender immediately below.
 */
class PluralAndGenderVisitor extends SimpleAstVisitor {
  /**
   * A plural or gender always exists in the context of a parent message,
   * which could in turn also be a plural or gender.
   */
  final ComplexMessage parent;

  /**
   * The pieces of the message. We are given an initial version of this
   * from our parent and we add to it as we find additional information.
   */
  List pieces;

  /** This will be set to true if we find a plural or gender. */
  bool foundPluralOrGender = false;

  PluralAndGenderVisitor(this.pieces, this.parent) : super();

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

  visitMethodInvocation(MethodInvocation node) {
    pieces.add(messageFromMethodInvocation(node));
    super.visitMethodInvocation(node);
  }

  /** Return true if [node] matches the pattern for plural or gender message.*/
  bool looksLikePluralOrGender(MethodInvocation node) {
    if (!["plural", "gender", "select"].contains(node.methodName.name)) {
      return false;
    }
    if (!(node.target is SimpleIdentifier)) return false;
    SimpleIdentifier target = node.target;
    return target.token.toString() == "Intl";
  }

  /**
   * Returns a String describing why the node is invalid, or null if no
   * reason is found, so it's presumed valid.
   */
  String checkValidity(MethodInvocation node) {
    // TODO(alanknight): Add reasonable validity checks.
    return null;
  }

  /**
   * Create a MainMessage from [node] using the name and
   * parameters of the last function/method declaration we encountered            e
   * and the parameters to the Intl.message call.
   */
  Message messageFromMethodInvocation(MethodInvocation node) {
    var message;
    switch(node.methodName.name) {
      case "gender" : message = new Gender(); break;
      case "plural" : message = new Plural(); break;
      case "select" : message = new Select(); break;
      default: throw new IntlMessageExtractionException(
          "Invalid plural/gender/select message");
    }
    message.parent = parent;

    var arguments = message.argumentsOfInterestFor(node);
    arguments.forEach((key, value) {
      try {
        var interpolation = new InterpolationVisitor(message);
        value.accept(interpolation);
        message[key] = interpolation.pieces;
      } on IntlMessageExtractionException catch (e) {
        message = null;
        var err = new StringBuffer()
            ..writeAll(["Error ", e, "\nProcessing <", node, ">"])
            ..write(_reportErrorLocation(node));
        print(err);
        warnings.add(err);
      }
    });
    var mainArg = node.argumentList.arguments.firstWhere(
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
