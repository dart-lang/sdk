// @dart = 2.9

import 'package:dev_compiler/src/js_ast/js_ast.dart';
import 'package:test/test.dart';

final _prenumberedPlaceholders = RegExp(r'#\d+');

MiniJsParser _parser(String src) =>
    MiniJsParser(src.replaceAll(_prenumberedPlaceholders, '#'));

void _check(Node node, String expected) =>
    expect(node.toString(), 'js_ast `$expected`');

void _checkStatement(String src) => _check(_parser(src).parseStatement(), src);

void _checkExpression(String src) =>
    _check(_parser(src).parseExpression(), src);

void main() {
  group('MiniJsParser', () {
    // TODO(ochafik): Add more coverage.
    test('parses classes with complex members', () {
      _checkExpression('class Foo {\n'
          '  [foo](...args) {}\n'
          '  [#0](x) {}\n'
          '  static [foo](...args) {}\n'
          '  static [#1](x) {}\n'
          '  get [foo]() {}\n'
          '  get [#2]() {}\n'
          '  static get [foo]() {}\n'
          '  static get [#3]() {}\n'
          '  set [foo](v) {}\n'
          '  set [#4](v) {}\n'
          '  static set [foo](v) {}\n'
          '  static set [#5](v) {}\n'
          '}');
    });
    test('parses statements', () {
      _checkStatement('for (let i = 0; i < 10; i++) {\n}\n');
      _checkStatement('for (let i = 0, j = 1; i < 10; i++) {\n}\n');
      _checkStatement('var [x, y = []] = list;\n');
      _checkStatement('var {x, y = {x: y}} = obj;\n');
    });
  });
}
