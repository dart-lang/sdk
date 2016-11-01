import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('compile empty function', () {
    return check("main() {}");
  });
}
