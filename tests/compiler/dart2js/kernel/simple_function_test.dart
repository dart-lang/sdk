import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('compile function that returns a constant', () {
    return check("main() { return 1; }");
  });
}
