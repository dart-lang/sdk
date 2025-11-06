// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:io' show File, Platform, stderr;
import 'dart:math' show Random;

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';

List<Node> stack = [];
Map<String, Node> data = {};

void main() {
  initialize(Platform.script.resolve("Dart.g"));
  print(createRandomProgram(includeWhy: true));
}

void initialize(Uri dartG) {
  parseDartG(dartG);
  postParse();
}

String createRandomProgram({required bool includeWhy}) {
  ProgramCreator programCreator = new ProgramCreator(createWhy: includeWhy);
  programCreator.path.add("startSymbol");
  data["startSymbol"]!.accept(programCreator);
  if (includeWhy) {
    return "${programCreator.sb.toString()}"
        "\n\n\n\n"
        "${programCreator.sb.toStringWhy()}";
  } else {
    return programCreator.sb.toString();
  }
}

void postParse() {
  EntryChecker entryChecker = new EntryChecker();
  for (MapEntry<String, Node> entry in data.entries) {
    entryChecker.parent = entry.key;
    entry.value.accept(entryChecker);
  }
  DepthMarker depthMarker = new DepthMarker();
  for (int i = 0; i < 2; i++) {
    for (MapEntry<String, Node> entry in data.entries) {
      entry.value.accept(depthMarker);
    }
    depthMarker.recurse = true;
  }
  SanityChecker sanityChecker = new SanityChecker();
  for (MapEntry<String, Node> entry in data.entries) {
    entry.value.accept(sanityChecker);
  }
}

void parseDartG(Uri dartG) {
  File f = new File.fromUri(dartG);
  List<int> input = f.readAsBytesSync();
  List<Token> tokens = tokenize(input);

  Token? currentToken = tokens.first;
  while (currentToken != null) {
    currentToken = parseDef(currentToken);
  }
  // Attempt to have less exotic identifiers and types etc.
  data["identifier"] = new Literal("foo");
  data["typeIdentifier"] = new Literal("foo");
  data["typeNotVoid"] = new Literal("foo");
  data["singleLineString"] = new Literal("'ssls'"); // small single line string
  data["argument"] = new Literal("42");
}

class StringBufferWrapper {
  final bool createWhy;
  final StringBuffer sb = new StringBuffer();
  final StringBuffer sbWhy = new StringBuffer();
  int get length => sb.length;
  final ProgramCreator parent;
  int currentNewlines = 1;
  String prev = "";

  StringBufferWrapper(this.createWhy, this.parent);

  void addNewline() {
    if (parent.singleLineStringDepth > 0) return;
    if (parent.numericLiteralDepth > 0) return;
    if (currentNewlines >= 2) return;
    sb.writeln();
    if (createWhy) {
      sbWhy.writeln();
    }
    currentNewlines++;
  }

  void write(String s, String why) {
    if (currentNewlines > 0 || parent.numericLiteralDepth > 0) {
      // No space
    } else if (prev == "" || prev == "@" || prev == "." || prev == "(") {
      // No space.
    } else if (s == "." || s == "," || s == "(" || s == ")" || s == ";") {
      // No space.
    } else {
      sb.write(" ");
    }
    currentNewlines = 0;
    prev = s;
    sb.write(s);
    if (createWhy) {
      sbWhy.writeln("$s: ${parent.path.join("/")}");
    }
  }

  void writeCharCode(int charCode, String why) {
    write(new String.fromCharCode(charCode), why);
  }

  @override
  String toString() => sb.toString();
  String toStringWhy() => sbWhy.toString();
}

class WrappedRandom {
  final Random random = new Random.secure();

  int nextInt(int max) {
    int result = random.nextInt(max);
    return result;
  }

  bool nextBool() {
    bool result = random.nextBool();
    return result;
  }
}

class ProgramCreator implements Visitor {
  final WrappedRandom random = new WrappedRandom();
  late final StringBufferWrapper sb;
  int depth = 0;
  int? currentExpressionStart;
  int? currentTopLevelStart;
  int singleLineStringDepth = 0;
  int numericLiteralDepth = 0;
  final List<String> path = [];

  bool isDepthHigh() => depth > 1000;
  bool isOutputLarge() =>
      sb.length > 14000 ||
      (currentTopLevelStart != null &&
          (sb.length - currentTopLevelStart!) > 700);
  bool isBigExpression() =>
      currentExpressionStart != null &&
      (sb.length - currentExpressionStart!) >= 20;

  ProgramCreator({required bool createWhy}) {
    sb = new StringBufferWrapper(createWhy, this);
  }

  @override
  void defaultNode(Node node) {
    throw "Should never get to defaultNode";
  }

  @override
  void visitAnyCharNode(AnyCharNode node) {
    int from = $SPACE;
    int to = $z;
    sb.writeCharCode(random.nextInt(to - from + 1) + from, "visitAnyCharNode");
  }

  @override
  void visitDummyNode(DummyNode node) {
    throw "Should never get to visitDummyNode";
  }

  @override
  void visitEmpty(Empty node) {
    // do nothing
  }

  @override
  void visitEndOfFileNode(EndOfFileNode node) {
    // do nothing
  }

  @override
  void visitLeaf(Leaf node) {
    depth++;
    final String what = node.token.value;
    path.add(what);
    if (what == "singleLineString") {
      singleLineStringDepth++;
    } else if (what == "numericLiteral") {
      numericLiteralDepth++;
    }
    int? oldExpressionStart = currentExpressionStart;
    if (what == "expression" && oldExpressionStart == null) {
      // Only write if it's not already set.
      currentExpressionStart = sb.length;
    }
    int? oldTopLevelStart = currentTopLevelStart;
    if (what == "topLevelDefinition" && oldTopLevelStart == null) {
      // Only write if it's not already set.
      currentTopLevelStart = sb.length;
    }

    const newLinesAround = {
      "topLevelDefinition",
      "libraryName",
      "partDirective",
    };
    const newLinesAfter = {"metadatum"};
    bool addNewlinesAround = newLinesAround.contains(what);
    bool addNewlinesAfter = newLinesAfter.contains(what);

    if (addNewlinesAround) {
      sb.addNewline();
    }

    Node linked = data[what]!;
    linked.accept(this);

    if (addNewlinesAround || addNewlinesAfter) {
      sb.addNewline();
    }

    currentExpressionStart = oldExpressionStart;
    currentTopLevelStart = oldTopLevelStart;

    if (what == "singleLineString") {
      singleLineStringDepth--;
    } else if (what == "numericLiteral") {
      numericLiteralDepth--;
    }

    if (path.removeLast() != what) throw "Bad remove!";
    depth--;
  }

  @override
  void visitLiteral(Literal node) {
    sb.write(node.content, "visitLiteral");
  }

  @override
  void visitOneOrMore(OneOrMore node) {
    depth++;
    int count = random.nextInt(3) + 1;
    if (isDepthHigh() || isOutputLarge() || isBigExpression()) count = 1;
    for (int i = 0; i < count; i++) {
      node.visitChildren(this);
    }
    depth--;
  }

  @override
  void visitOptional(Optional node) {
    if (isDepthHigh() || isOutputLarge() || isBigExpression()) return;

    depth++;
    if (random.nextInt(10) < 2) {
      node.visitChildren(this);
    }
    depth--;
  }

  @override
  void visitOrNode(OrNode node) {
    depth++;
    List<Node> nodes = node.nodesFiltered;
    if (nodes.length == 1) {
      nodes[0].accept(this);
    } else {
      // In practise some should be more likely than others.
      if (nodes.length == 2 &&
          nodes[0] is Leaf &&
          (nodes[0] as Leaf).token.value == "libraryDeclaration" &&
          nodes[1] is Leaf &&
          (nodes[1] as Leaf).token.value == "partDeclaration") {
        // libraryDeclaration should be more likely.
        if (random.nextInt(100) < 95) {
          nodes[0].accept(this);
        } else {
          nodes[1].accept(this);
        }
      } else {
        Node? chosen;
        bool pickSmallestDepth = false;
        if (isBigExpression() || isDepthHigh() || isOutputLarge()) {
          // Choose the one with the smallest depth.
          pickSmallestDepth = true;
        } else if (random.nextBool() &&
            1 + 1 == 3 /* i.e. currently disabled */ ) {
          // If depth and length is not too big yet, and if several nodes has
          // depth <= 10, choose randomly among those.
          List<Node> smallDepthNodes = [];
          for (Node childNode in nodes) {
            if (childNode.depth! > 0 && (childNode.depth! <= 10)) {
              smallDepthNodes.add(childNode);
            }
          }
          if (smallDepthNodes.isNotEmpty) {
            chosen = smallDepthNodes[random.nextInt(smallDepthNodes.length)];
          }
        }

        if (pickSmallestDepth) {
          chosen = nodes[0];
          for (Node childNode in nodes) {
            if (childNode.depth! > 0 &&
                (childNode.depth! < chosen!.depth! || chosen.depth! < 0)) {
              chosen = childNode;
            }
          }
          if (chosen!.depth! < 0) {
            throw "Not good";
          }
        }
        if (chosen == null) {
          chosen = nodes[random.nextInt(nodes.length)];
        }

        chosen.accept(this);
      }
    }
    depth--;
  }

  @override
  void visitRangeNode(RangeNode node) {
    String a = node.a.content;
    String b = node.b.content;
    if (a.length != 1 || b.length != 1) {
      throw "Unexpected range: $node ('$a' '$b')";
    }
    int from = a.codeUnitAt(0);
    int to = b.codeUnitAt(0);
    sb.writeCharCode(random.nextInt(to - from + 1) + from, "visitRangeNode");
  }

  @override
  void visitSequence(Sequence node) {
    depth++;
    node.visitChildren(this);
    if (node.nodes.isNotEmpty) {
      Node last = node.nodes.last;
      if (last is Literal && last.content == ";") {
        sb.addNewline();
      }
    }
    depth--;
  }

  @override
  void visitTildeNode(TildeNode node) {
    Set<int> no = {};
    List<Node> getNodes(Node node) {
      List<Node> result = [];
      if (node is Sequence) {
        for (Node childNode in node.nodes) {
          result.addAll(getNodes(childNode));
        }
      } else if (node is OrNode) {
        for (Node childNode in node.nodes) {
          result.addAll(getNodes(childNode));
        }
      } else if (node is Literal) {
        result.add(node);
      } else {
        throw "Can't get nodes of ${node} (${node.runtimeType})";
      }
      return result;
    }

    List<Node> nodes = getNodes(node.a);
    for (Node childNode in nodes) {
      if (childNode is! Literal) {
        throw "Not a literal...: ${childNode.runtimeType}: $node";
      }
      Literal literal = childNode;
      String s = literal.content;
      for (int i = 0; i < s.length; i++) {
        no.add(s.codeUnitAt(i));
      }
    }

    int from = $SPACE;
    int to = $z;
    int charCode = random.nextInt(to - from + 1) + from;
    while (no.contains(charCode)) {
      charCode = random.nextInt(to - from + 1) + from;
    }
    sb.writeCharCode(charCode, "visitTildeNode");
  }

  @override
  void visitZeroOrMore(ZeroOrMore node) {
    depth++;
    int count = random.nextInt(3);
    if (node.a is Sequence &&
        (node.a as Sequence).nodes
            .where(
              (Node e) => e is Leaf && e.token.value == "topLevelDefinition",
            )
            .isNotEmpty) {
      // We likely want more top level definitions.
      count = random.nextInt(20);
    } else if (node.a is Sequence &&
        (node.a as Sequence).nodes
            .where((Node e) => e is Leaf && e.token.value == "metadatum")
            .isNotEmpty) {
      // We likely don't want too many metadata entries...
      if (random.nextInt(100) < 90) {
        count = 0;
      }
    }
    if (isDepthHigh() || isOutputLarge() || isBigExpression()) {
      count = 0;
    }
    for (int i = 0; i < count; i++) {
      node.visitChildren(this);

      if (isBigExpression()) {
        break;
      }
    }
    depth--;
  }
}

class SanityChecker extends Visitor {
  ProgramCreator programCreator = new ProgramCreator(createWhy: false);

  @override
  void defaultNode(Node node) {
    if (node.depth == null) throw "$node (${node.runtimeType}) has null depth";
    if (node is TildeNode) {
      programCreator.visitTildeNode(node);
    }
    super.defaultNode(node);
  }
}

class DepthMarker implements Visitor {
  bool recurse = false;

  @override
  void defaultNode(Node node) {
    throw "Should never get here.";
  }

  @override
  void visitAnyCharNode(AnyCharNode node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitDummyNode(DummyNode node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitEmpty(Empty node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitEndOfFileNode(EndOfFileNode node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitLeaf(Leaf node) {
    Node linked = data[node.token.value]!;
    if (linked.depth != null && linked.depth! > 0) {
      node.depth = linked.depth! + 1;
    } else if (node.depth == null) {
      node.depth = -1;
      linked.accept(this);
      if (linked.depth! > 0) {
        node.depth = linked.depth! + 1;
      } else {
        // Recursive... Keep the -1 depth and see that as "infinite".
      }
    } else {
      // Recursive... Keep the -1 depth and see that as "infinite".
    }
  }

  @override
  void visitLiteral(Literal node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitOneOrMore(OneOrMore node) {
    node.visitChildren(this);
    node.depth = node.a.depth! + 1;
  }

  @override
  void visitOptional(Optional node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitOrNode(OrNode node) {
    node.visitChildren(this);
    int min = node.nodes.first.depth!;
    for (Node node in node.nodes) {
      if (node.depth! > 0 && (node.depth! < min || min < 0)) min = node.depth!;
    }
    node.depth = min + 1;
  }

  @override
  void visitRangeNode(RangeNode node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitSequence(Sequence node) {
    node.visitChildren(this);
    int max = node.nodes.first.depth!;
    for (Node childNode in node.nodes) {
      if (childNode.depth! > max) max = childNode.depth!;
      if (childNode.depth == -1) max = -1;
      if (max == -1) {
        node.depth = -1;
        return;
      }
    }
    node.depth = max + 1;
  }

  @override
  void visitTildeNode(TildeNode node) {
    // Naively assume that this is true.
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }

  @override
  void visitZeroOrMore(ZeroOrMore node) {
    node.depth = 1;
    if (recurse) node.visitChildren(this);
  }
}

class EntryChecker extends Visitor {
  String? parent;

  @override
  void visitLeaf(Leaf node) {
    if (!data.containsKey(node.token.value)) {
      throw "Reference to unknown entry '${node.token.value}' from '$parent'";
    }
  }
}

Token? parseDef(Token token) {
  if (token.value == "grammar" &&
      token.next?.next?.value == ";" &&
      token.next?.next?.next != null) {
    // Skip something like 'grammar Dart;'.
    token = token.next!.next!.next!;
  }
  if (token.value == "fragment") {
    // Skip 'fragment'.
    token = token.next!;
  }
  while (token.value == "@") {
    // Skip injected java code.
    while (token.value != "{") {
      token = token.next!;
    }
    int count = 1;
    token = token.next!;
    while (count > 0) {
      if (token.value == "{") {
        count++;
      } else if (token.value == "}") {
        count--;
      }
      token = token.next!;
      if (count == 0) {
        break;
      }
    }
  }
  Token name = token;
  token = token.next!;
  if (token.value != ":") throw "Expected ':' at around ${token.offset}";
  token = token.next!;
  token = parseContent(token, depth: 1);
  if (token.value != ";") throw "Expected ';' at around offset ${token.offset}";

  data[name.value] = stack.removeLast();
  if (stack.isNotEmpty) throw "Expected stack to be empty";

  return token.next;
}

void join() {
  if (stack.length > 1) {
    List<Node> sequenceList = [];
    for (Node node in stack) {
      if (node is! DummyNode) sequenceList.add(node);
    }
    if (sequenceList.length > 1) {
      // If something like "'a' .. 'z'" make that into a RangeNode.
      if (sequenceList.length == 3 &&
          sequenceList[0] is Literal &&
          sequenceList[1] is Leaf &&
          (sequenceList[1] as Leaf).token.value == ".." &&
          sequenceList[2] is Literal) {
        RangeNode range = new RangeNode(
          sequenceList[0] as Literal,
          sequenceList[2] as Literal,
        );
        stack = [range];
      } else {
        Sequence sequence = new Sequence(sequenceList);
        stack = [sequence];
      }
    } else {
      stack = sequenceList;
    }
  }
}

Token parseContent(Token token, {required int depth}) {
  Token originalToken = token;
  try {
    while (token.value != ";" && token.value != ")") {
      if (token.value == "|" && stack.isEmpty) {
        stderr.writeln("Warning: Seemingly stray '|' at ${token.offset}");
        token = token.next!;
      }
      if (token.value == "|") {
        if (token != originalToken && depth > 1) break;
        join();
        Node a = stack.removeLast();
        token = parseContent(token.next!, depth: depth + 1);
        Node b = stack.removeLast();
        OrNode orNode = new OrNode();
        if (a is OrNode) {
          orNode.nodes.addAll(a.nodes);
        } else {
          orNode.nodes.add(a);
        }
        if (b is OrNode) {
          orNode.nodes.addAll(b.nodes);
        } else {
          orNode.nodes.add(b);
        }
        stack.add(orNode);
      } else if (token.value == "(") {
        List<Node> savedStack = stack;
        stack = [];
        token = parseContent(token.next!, depth: 1);
        if (token.value != ")") throw "Expected ')'";
        if (stack.isEmpty) {
          // ()
          stack.add(new Empty());
        }
        if (stack.length != 1) throw "Expected stack to have length 1.";
        savedStack.addAll(stack);
        stack = savedStack;
        token = token.next!;
      } else if (token.value == "{") {
        token = parseBrackets(token.next!);
      } else if (token.value == "'") {
        token = parseLiteral(token.next!);
      } else if (token.value == "?") {
        Node a = stack.removeLast();
        if (a is DummyNode) {
          stack.add(a);
        } else {
          stack.add(new Optional(a));
        }
        token = token.next!;
      } else if (token.value == "+") {
        Node a = stack.removeLast();
        stack.add(new OneOrMore(a));
        token = token.next!;
      } else if (token.value == "*") {
        Node a = stack.removeLast();
        stack.add(new ZeroOrMore(a));
        token = token.next!;
      } else if (token.value == "~") {
        token = parseContent(token.next!, depth: depth + 1);
        Node a = stack.removeLast();
        stack.add(new TildeNode(a));
      } else if (token.value == ".") {
        stack.add(new AnyCharNode(token));
        token = token.next!;
      } else if (token.value == "EOF") {
        stack.add(new EndOfFileNode(token));
        token = token.next!;
      } else {
        stack.add(new Leaf(token));
        token = token.next!;
      }
    }
    join();
  } catch (e, st) {
    print("Got error at around ${token.offset}: $st");
    rethrow;
  }
  return token;
}

Token parseBrackets(Token token) {
  while (token.value != "}") {
    token = token.next!;
  }
  stack.add(new DummyNode());
  return token.next!;
}

Token parseLiteral(Token token) {
  List<String> content = [];
  while (token.value != "'") {
    if (token.value == r"\" && token.next != null) {
      // Escape stuff...
      Token next = token.next!;
      if (next.value == '\'') {
        content.add(next.value);
        token = next.next!;
      } else if (next.value == '\\') {
        content.add("\\");
        token = next.next!;
      } else if (next.value == 'r') {
        content.add("\r");
        token = next.next!;
      } else if (next.value == 'n') {
        content.add("\n");
        token = next.next!;
      } else if (next.value == 'uFEFF') {
        content.add("\uFEFF");
        token = next.next!;
      } else if (next.value == 't') {
        content.add("\t");
        token = next.next!;
      } else {
        print(token.next!.value);
      }
    } else {
      content.add(token.value);
      token = token.next!;
    }
  }
  stack.add(new Literal(content.join()));
  return token.next!;
}

List<Token> tokenize(List<int> bytes) {
  List<int> tmp = [];
  int index = 0;
  bool inComment = false;
  bool inQuote = false;
  bool inEscaped = false;
  List<Token> tokens = [];

  void pushToken() {
    if (inComment) {
      tmp.clear();
    } else if (tmp.isNotEmpty) {
      String s = utf8.decode(tmp);
      if (s == "." && tokens.isNotEmpty && tokens.last.value == ".") {
        // Hack: Join them.
        Token last = tokens.removeLast();
        Token nextToken = new Token("..", last.offset);
        if (tokens.isNotEmpty) tokens.last.next = nextToken;
        tokens.add(nextToken);
      } else {
        Token nextToken = new Token(s, index);
        if (tokens.isNotEmpty) tokens.last.next = nextToken;
        tokens.add(nextToken);
      }
      tmp.clear();
    }
  }

  while (index < bytes.length) {
    int b = bytes[index++];
    if (b == $LF || b == $CR) {
      pushToken();
      inComment = false;
      inEscaped = false;
    } else if (inComment) {
      // ignore comments.
    } else if (!inQuote &&
        b == $SLASH &&
        index < bytes.length &&
        bytes[index] == $SLASH) {
      inComment = true;
    } else if (!inEscaped &&
        b == $BACKSLASH &&
        index < bytes.length &&
        ((bytes[index] == $SQ) || (bytes[index] == $BACKSLASH))) {
      // Escaped ' or escaped \.
      inEscaped = true;
      pushToken();
      tmp.add(b);
      pushToken();
    } else if (b == $SQ) {
      if (!inEscaped) {
        inQuote = !inQuote;
      }
      inEscaped = false;
      pushToken();
      tmp.add(b);
      pushToken();
    } else if (b == $SPACE && !inQuote) {
      pushToken();
      inEscaped = false;
    } else if ((b >= $0 && b <= $9) ||
        (b >= $a && b <= $z) ||
        (b >= $A && b <= $Z) ||
        b == $_) {
      tmp.add(b);
      inEscaped = false;
    } else {
      pushToken();
      tmp.add(b);
      pushToken();
      inEscaped = false;
    }
  }
  pushToken();

  return tokens;
}

class Token {
  final String value;
  final int offset;
  Token? next;

  Token(this.value, this.offset);

  @override
  String toString() => "$value";
}

abstract class Node {
  /// Not really depth,
  /// but minimum number of steps to the possibility of ending.
  int? depth;

  void accept(Visitor visitor);
  void visitChildren(Visitor visitor);
}

class DummyNode extends Node {
  @override
  void accept(Visitor visitor) {
    visitor.visitDummyNode(this);
  }

  @override
  void visitChildren(Visitor visitor) {}
}

class Empty extends Node {
  @override
  void accept(Visitor visitor) {
    visitor.visitEmpty(this);
  }

  @override
  void visitChildren(Visitor visitor) {}
}

class AnyCharNode extends Node {
  final Token token;

  AnyCharNode(this.token);

  @override
  String toString() => "$token";

  @override
  void accept(Visitor visitor) {
    visitor.visitAnyCharNode(this);
  }

  @override
  void visitChildren(Visitor visitor) {}
}

class EndOfFileNode extends Node {
  final Token token;

  EndOfFileNode(this.token);

  @override
  String toString() => "$token";

  @override
  void accept(Visitor visitor) {
    visitor.visitEndOfFileNode(this);
  }

  @override
  void visitChildren(Visitor visitor) {}
}

class Leaf extends Node {
  final Token token;

  Leaf(this.token);

  @override
  String toString() => "$token";

  @override
  void accept(Visitor visitor) {
    visitor.visitLeaf(this);
  }

  @override
  void visitChildren(Visitor visitor) {}
}

class Sequence extends Node {
  final List<Node> nodes;

  Sequence(this.nodes);

  @override
  String toString() => "$nodes";

  @override
  void accept(Visitor visitor) {
    visitor.visitSequence(this);
  }

  @override
  void visitChildren(Visitor visitor) {
    for (Node node in nodes) {
      node.accept(visitor);
    }
  }
}

class OrNode extends Node {
  List<Node> nodes = [];
  List<Node>? _nodesFiltered;

  List<Node> get nodesFiltered {
    return _nodesFiltered ??= _filterNodes();
  }

  List<Node> _filterNodes() {
    bool skipLeaf(Leaf leaf) {
      const Set<String> skip = {
        "functionType",
        "multiLineString",
        "SUPER",
        "awaitExpression",
        "functionExpression",
      };
      return skip.contains(leaf.token.value);
    }

    List<Node> result = [];
    for (Node node in nodes) {
      if (node is Sequence &&
          node.nodes
              .where((child) => child is Leaf && skipLeaf(child))
              .isNotEmpty) {
        // Skip
      } else if (node is Leaf && skipLeaf(node)) {
        // Skip
      } else {
        result.add(node);
      }
    }
    if (result.isEmpty) return nodes;
    return result;
  }

  @override
  String toString() => "${nodes.join(" | ")}";

  @override
  void accept(Visitor visitor) {
    visitor.visitOrNode(this);
  }

  @override
  void visitChildren(Visitor visitor) {
    for (Node node in nodes) {
      node.accept(visitor);
    }
  }
}

class RangeNode extends Node {
  final Literal a;
  final Literal b;

  RangeNode(this.a, this.b);

  @override
  String toString() => "$a .. $b";

  @override
  void accept(Visitor visitor) {
    visitor.visitRangeNode(this);
  }

  @override
  void visitChildren(Visitor visitor) {
    a.accept(visitor);
    b.accept(visitor);
  }
}

class Optional extends Node {
  final Node a;

  Optional(this.a);

  @override
  String toString() => "($a)?";

  @override
  void accept(Visitor visitor) {
    visitor.visitOptional(this);
  }

  @override
  void visitChildren(Visitor visitor) {
    a.accept(visitor);
  }
}

class OneOrMore extends Node {
  final Node a;

  OneOrMore(this.a);

  @override
  String toString() => "($a)+";

  @override
  void accept(Visitor visitor) {
    visitor.visitOneOrMore(this);
  }

  @override
  void visitChildren(Visitor visitor) {
    a.accept(visitor);
  }
}

class ZeroOrMore extends Node {
  final Node a;

  ZeroOrMore(this.a);

  @override
  String toString() => "($a)*";

  @override
  void accept(Visitor visitor) {
    visitor.visitZeroOrMore(this);
  }

  @override
  void visitChildren(Visitor visitor) {
    a.accept(visitor);
  }
}

class TildeNode extends Node {
  final Node a;

  TildeNode(this.a);

  @override
  String toString() => "~($a)";

  @override
  void accept(Visitor visitor) {
    visitor.visitTildeNode(this);
  }

  @override
  void visitChildren(Visitor visitor) {
    a.accept(visitor);
  }
}

class Literal extends Node {
  String content;

  Literal(this.content);

  @override
  String toString() => "'${content}'";

  @override
  void accept(Visitor visitor) {
    visitor.visitLiteral(this);
  }

  @override
  void visitChildren(Visitor visitor) {}
}

abstract class Visitor {
  void defaultNode(Node node) {
    node.visitChildren(this);
  }

  void visitDummyNode(DummyNode node) => defaultNode(node);
  void visitEmpty(Empty node) => defaultNode(node);
  void visitLeaf(Leaf node) => defaultNode(node);
  void visitAnyCharNode(AnyCharNode node) => defaultNode(node);
  void visitEndOfFileNode(EndOfFileNode node) => defaultNode(node);
  void visitSequence(Sequence node) => defaultNode(node);
  void visitOrNode(OrNode node) => defaultNode(node);
  void visitRangeNode(RangeNode node) => defaultNode(node);
  void visitOptional(Optional node) => defaultNode(node);
  void visitOneOrMore(OneOrMore node) => defaultNode(node);
  void visitZeroOrMore(ZeroOrMore node) => defaultNode(node);
  void visitTildeNode(TildeNode node) => defaultNode(node);
  void visitLiteral(Literal node) => defaultNode(node);
}
