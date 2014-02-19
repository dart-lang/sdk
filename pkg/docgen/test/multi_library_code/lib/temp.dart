library testLib;
import 'temp2.dart';
import 'temp3.dart';
export 'temp2.dart';
export 'temp3.dart';

/**
 * Doc comment for class [A].
 *
 * Multiline Test
 */
/*
 * Normal comment for class A.
 */
class A {

  int _someNumber;

  A() {
    _someNumber = 12;
  }

  A.customConstructor();

  /**
   * Test for linking to parameter [A]
   */
  void doThis(int A) {
    print(A);
  }
}

// A trivial use of `B` and `C` to eliminate import warnings
B sampleMethod(C cInstance) {
  throw new UnimplementedError();
}
