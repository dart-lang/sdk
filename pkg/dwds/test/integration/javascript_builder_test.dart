// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/src/services/javascript_builder.dart';
import 'package:test/test.dart';

void main() async {
  group('JavaScriptBuilder |', () {
    test('write', () async {
      expect((JsBuilder()..write('Hello')).build(), 'Hello');
    });

    test('writeLine', () async {
      expect((JsBuilder()..writeLine('Hello')).build(), 'Hello\n');
    });

    test('writeAll with separator', () async {
      expect(
        (JsBuilder()..writeAll(['Hello', 'World'], ' ')).build(),
        'Hello World',
      );
    });

    test('writeAll with default separator', () async {
      expect((JsBuilder()..writeAll(['Hello', 'World'])).build(), 'HelloWorld');
    });

    test('writeWithIndent', () async {
      expect((JsBuilder()..writeWithIndent('Hello')).build(), 'Hello');
    });

    test('writeWithIndent', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.increaseIndent();
      jsBuilder.writeWithIndent('Hello');
      jsBuilder.decreaseIndent();
      jsBuilder.writeWithIndent('World');
      expect(jsBuilder.build(), '  HelloWorld');
    });

    test('writeLineWithIndent', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.increaseIndent();
      jsBuilder.writeLineWithIndent('Hello');
      jsBuilder.decreaseIndent();
      jsBuilder.writeLineWithIndent('World');
      expect(jsBuilder.build(), '  Hello\nWorld\n');
    });

    test('writeAllLinesWithIndent', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.increaseIndent();
      jsBuilder.writeMultiLineExpression(['Hello', 'World']);
      jsBuilder.decreaseIndent();
      jsBuilder.writeMultiLineExpression(['Hello', 'World']);
      expect(jsBuilder.build(), 'Hello\n  WorldHello\nWorld');
    });

    test('writeCallExpression', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.writeCallExpression(['a1', 'a2'], () => jsBuilder.write('foo'));
      expect(jsBuilder.build(), 'foo(a1, a2)');
    });

    test('writeTryCatchExpression', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.writeTryCatchExpression(() => jsBuilder.write('x'));
      expect(
        jsBuilder.build(),
        'try {\n'
        '  x\n'
        '} catch (error) {\n'
        '  error.name + ": " + error.message;\n'
        '}',
      );
    });

    test('writeTryCatchStatement', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.writeTryCatchStatement(
        () => jsBuilder.writeReturnStatement(() => jsBuilder.write('x')),
      );
      expect(
        jsBuilder.build(),
        'try {\n'
        '  return x;\n'
        '} catch (error) {\n'
        '  return error.name + ": " + error.message;\n'
        '}',
      );
    });

    test('writeReturnStatement', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.writeReturnStatement(() => jsBuilder.write('x'));
      expect(jsBuilder.build(), 'return x;');
    });

    test('writeFunctionDefinition', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.writeFunctionDefinition(
        ['a1', 'a2'],
        () => jsBuilder.writeReturnStatement(() => jsBuilder.write('a1 + a2')),
      );
      expect(
        jsBuilder.build(),
        'function (a1, a2) {\n'
        '  return a1 + a2;\n'
        '}',
      );
    });

    test('writeBindExpression', () async {
      final jsBuilder = JsBuilder();
      jsBuilder.writeBindExpression(
        'x',
        () => jsBuilder.writeFunctionDefinition(
          [],
          () => jsBuilder.writeReturnStatement(() => jsBuilder.write('this.a')),
        ),
      );
      expect(
        jsBuilder.build(),
        'function () {\n'
        '  return this.a;\n'
        '}.bind(x)',
      );
    });

    test('createEvalExpression', () async {
      final expression = JsBuilder.createEvalExpression([
        'var e = 1;',
        'return e',
      ]);
      expect(
        expression,
        'try {\n'
        '  var e = 1;\n'
        '  return e;\n'
        '} catch (error) {\n'
        '  error.name + ": " + error.message;\n'
        '}',
      );
    });

    test('createEvalStaticFunction', () async {
      final function = JsBuilder.createEvalStaticFunction(
        ['function(e, e2) {', '  return e;', '}'],
        ['e', 'e2'],
      );
      expect(
        function,
        'function (e, e2) {\n'
        '  try {\n'
        '    return function(e, e2) {\n'
        '      return e;\n'
        '    }(e, e2);\n'
        '  } catch (error) {\n'
        '    return error.name + ": " + error.message;\n'
        '  }\n'
        '}',
      );
    });

    test('createEvalBoundFunction', () async {
      final function = JsBuilder.createEvalBoundFunction(
        ['function(e, e2) {', '  return e;', '}'],
        ['e', 'e2'],
      );
      expect(
        function,
        'function (e, e2, __t\$this) {\n'
        '  try {\n'
        '    return function (e, e2) {\n'
        '      return function(e, e2) {\n'
        '        return e;\n'
        '      }(e, e2);\n'
        '    }.bind(__t\$this)(e, e2);\n'
        '  } catch (error) {\n'
        '    return error.name + ": " + error.message;\n'
        '  }\n'
        '}',
      );
    });
  });
}
