import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('simple switch statement', () {
    String code = '''
main() {
  int x = 2;
  switch(x) {
    case 1:
      print('spider');
      break;
    case 2:
      print('grasshopper');
      break;
  }
}''';
    return check(code);
  });

  test('switch with default', () {
    String code = '''
main() {
  int x = 5;
  switch(x) {
    case 1:
      print('spider');
      break;
    case 2:
      print('grasshopper');
      break;
    default:
      print('ladybug');
  }
}''';
    return check(code);
  });

/*
  // TODO(efortuna): Uncomment. Because of patch file weirdness, the original
  // SSA vs the Kernel version is instantiating a subclass of the
  // FallThroughError, so it produces slightly different code. Fix that.
  test('switch with fall through error', () {
    String code = '''
main() {
  int x = 2;
  switch(x) {
    case 1:
      print('spider');
      break;
    case 2:
      print('grasshopper');
    case 3:
      print('ant');
      break;
    default:
      print('ladybug');
  }
}''';
    return check(code);
  });
*/
  test('switch with multi-case branch', () {
    String code = '''
main() {
  int x = 3;
  switch(x) {
    case 1:
      print('spider');
      break;
    case 2:
    case 3:
    case 4:
      print('grasshopper');
      print('ant');
      break;
  }
}''';
    return check(code);
  });

  test('switch with weird fall-through end case', () {
    String code = '''
main() {
    int x = 6;
  switch(x) {
    case 1:
      print('spider');
      break;
    case 5:
      print('beetle');
      break;
    case 6:
  }
}''';
    return check(code);
  });
}
