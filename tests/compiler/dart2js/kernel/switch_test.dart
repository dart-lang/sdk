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
    return check(code, useKernelInSsa: true);
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
    return check(code, useKernelInSsa: true);
  });

  test('switch with labeled continue', () {
    String code = '''
main() {
    int x = 1;
  switch(x) {
    case 1:
      print('spider');
      continue world;
    case 5:
      print('beetle');
      break;
    world:
    case 6:
      print('cricket');
      break;
    default:
      print('bat');
  }
}''';
    return check(code, useKernelInSsa: true);
  });

  test('switch with continue to fall through', () {
    String code = '''
main() {
    int x = 1;
  switch(x) {
    case 1:
      print('spider');
      continue world;
    world:
    case 5:
      print('beetle');
      break;
    case 6:
      print('cricket');
      break;
    default:
      print('bat');
  }
}''';
    return check(code, useKernelInSsa: true);
  });

  test('switch with continue without default case', () {
    String code = '''
main() {
    int x = 1;
  switch(x) {
    case 1:
      print('spider');
      continue world;
    world:
    case 5:
      print('beetle');
      break;
    case 6:
      print('cricket');
      break;
  }
}''';
    return check(code, useKernelInSsa: true);
  });

  test('switch with continue without default case and no matching case', () {
    String code = '''
main() {
    int x = 8;
  switch(x) {
    case 1:
      print('spider');
      continue world;
    world:
    case 5:
      print('beetle');
      break;
    case 6:
      print('cricket');
      break;
  }
}''';
    return check(code, useKernelInSsa: true);
  });
}
