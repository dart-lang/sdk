import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  group('compile function that returns a value', () {
    test('constant int', () {
      return check('main() { return 1; }');
    });

    test('constant double', () {
      return check('main() { return 1.0; }');
    });

    test('constant string', () {
      return check('main() { return "hello"; }');
    });

    test('constant bool', () {
      return check('main() { return true; }');
    });

    test('constant symbol', () {
      return check('main() { return #hello; }');
    });

    test('null', () {
      return check('main() { return null; }');
    });
  });

  test('compile function that returns its argument', () {
    String code = '''
      foo(x) {
        return x;
      }

      main() {
        foo(1);
      }''';
    return check(code, entry: 'foo');
  });
}
