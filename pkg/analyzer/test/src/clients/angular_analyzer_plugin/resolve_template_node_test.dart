// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/clients/angular_analyzer_plugin/angular_analyzer_plugin.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolveTemplateNodeTest);
  });
}

@reflectiveTest
class ResolveTemplateNodeTest extends DriverResolutionTest {
  test_asExpression() async {
    await assertNoErrorsInCode(r'''
class MyComponent {}
''');

    var source = findElement.unitElement.source;
    var errorListener = RecordingErrorListener();

    var template = _parseTemplate('var x = 0 as int;');
    var node = template.findNode.variableDeclaration('x = ').initializer;

    var overrideAsExpressionInvoked = false;

    resolveTemplateNode(
      componentClass: findElement.class_('MyComponent'),
      templateSource: source,
      localVariables: [],
      node: node,
      errorListener: errorListener,
      errorReporter: ErrorReporter(errorListener, source),
      overrideAsExpression: ({node, invokeSuper}) {
        overrideAsExpressionInvoked = true;
        expect(invokeSuper, isNotNull);
      },
    );

    expect(overrideAsExpressionInvoked, isTrue);
  }

  test_references() async {
    await assertNoErrorsInCode(r'''
class MyComponent {
  void someContext() {
    // ignore:unused_local_variable
    var foo = 0;
  }

  void bar(int a) {}
}
''');

    var source = findElement.unitElement.source;
    var errorListener = RecordingErrorListener();

    var template = _parseTemplate('var x = bar(foo);');
    var node = template.findNode.variableDeclaration('x = ').initializer;
    assertElementNull(template.findNode.simple('foo'));
    assertElementNull(template.findNode.methodInvocation('bar'));

    resolveTemplateNode(
      componentClass: findElement.class_('MyComponent'),
      templateSource: source,
      localVariables: [
        findElement.localVar('foo'),
      ],
      node: node,
      errorListener: errorListener,
      errorReporter: ErrorReporter(errorListener, source),
    );

    assertElement(
      template.findNode.simple('foo'),
      findElement.localVar('foo'),
    );

    assertElement(
      template.findNode.methodInvocation('bar'),
      findElement.method('bar'),
    );
  }

  _ParsedTemplate _parseTemplate(String templateCode) {
    var templateUnit = parseString(
      content: templateCode,
      featureSet: result.unit.featureSet,
    ).unit;

    return _ParsedTemplate(
      content: templateCode,
      unit: templateUnit,
      findNode: FindNode(templateCode, templateUnit),
    );
  }
}

class _ParsedTemplate {
  final String content;
  final CompilationUnit unit;
  final FindNode findNode;

  _ParsedTemplate({
    @required this.content,
    @required this.unit,
    @required this.findNode,
  });
}
