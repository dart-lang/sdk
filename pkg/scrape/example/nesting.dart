// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'package:scrape/scrape.dart';

/// The paths to each build() method and its maximum nesting level.
final buildMethods = <String, int>{};

bool simplifyNames = false;

void main(List<String> arguments) {
  arguments = arguments.toList();
  simplifyNames = arguments.remove('--simplify');
  var allCode = arguments.remove('--all');

  Scrape()
    // The number of levels of nesting active when each argument appears.
    ..addHistogram('Nesting depth')
    // The number of levels of nesting active when each argument appears without
    // counting lists.
    ..addHistogram('Ignoring lists')
    // The number of levels of "child" or "children" named parameter nesting
    // when each argument appears.
    ..addHistogram('Child nesting depth')
    ..addHistogram('Argument names')
    // Strings that describe the structure of each nested argument.
    ..addHistogram('Argument nesting')
    ..addVisitor(() => NestingVisitor(allCode: allCode))
    ..runCommandLine(arguments);

  var methods = buildMethods.keys.toList();
  methods.sort((a, b) => buildMethods[b].compareTo(buildMethods[a]));
  for (var method in methods) {
    print('${buildMethods[method].toString().padLeft(3)}: $method');
  }
  print('${buildMethods.length} build() methods');
}

class NestingVisitor extends ScrapeVisitor {
  final List<String> _stack = [];

  final bool _allCode;
  bool _pushed = false;
  int _deepestNesting = 0;

  NestingVisitor({bool allCode}) : _allCode = allCode ?? false;

  @override
  void beforeVisitBuildMethod(Declaration node) {
    _deepestNesting = 0;
  }

  @override
  void afterVisitBuildMethod(Declaration node) {
    var startLine = lineInfo.getLocation(node.offset).lineNumber;
    buildMethods['$path:$startLine'] = _deepestNesting;
  }

  @override
  void visitArgumentList(ArgumentList node) {
    // Only argument lists with trailing commas get indentation.
    if (node.arguments.isNotEmpty &&
        node.arguments.last.endToken.next.type == TokenType.COMMA) {
      String name;
      var parent = node.parent;
      if (parent is MethodInvocation) {
        name = parent.methodName.name;
      } else if (parent is InstanceCreationExpression) {
        name = parent.constructorName.toString();
      } else if (parent is SuperConstructorInvocation) {
        name = 'super.${parent.constructorName}';
      } else {
        name = '?(${parent.runtimeType})?';
      }

      if (simplifyNames) {
        name = '';
      }

      for (var argument in node.arguments) {
        var argName =
            argument is NamedExpression ? argument.name.label.name : '';

        if (_allCode || isInFlutterBuildMethod) {
          record('Argument names', argName);
        }

        if (simplifyNames && argName != 'child' && argName != 'children') {
          argName = '_';
        }

        _push('$name($argName:');
        argument.accept(this);
        _pop();
      }
    } else {
      node.visitChildren(this);
    }
  }

  @override
  void visitBlock(Block node) {
    var isFunction = node.parent is BlockFunctionBody;
    if (!isFunction) _push('{');
    node.visitChildren(this);
    if (!isFunction) _pop();
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _push('=>');
    node.visitChildren(this);
    _pop();
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var isDeclaration = node.parent is FunctionDeclaration;
    if (!isDeclaration) _push('(){');
    node.visitChildren(this);
    if (!isDeclaration) _pop();
  }

  @override
  void visitListLiteral(ListLiteral node) {
    for (var element in node.elements) {
      _push('[');
      element.accept(this);
      _pop();
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    for (var element in node.elements) {
      _push('{');
      element.accept(this);
      _pop();
    }
  }

  void _push(String string) {
    _stack.add(string);
    _pushed = true;
    _deepestNesting = math.max(_deepestNesting, _stack.length);
  }

  void _pop() {
    if (_pushed && (_allCode || isInFlutterBuildMethod)) {
      record('Argument nesting', _stack.join(' '));
      record('Nesting depth', _stack.length);
      record('Ignoring lists', _stack.where((s) => s != '[').length);
      record('Child nesting depth',
          _stack.where((s) => s.contains('child')).length);
    }
    _pushed = false;
    _stack.removeLast();
  }
}
