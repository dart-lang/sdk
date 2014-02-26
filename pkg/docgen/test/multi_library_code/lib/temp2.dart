library testLib2.foo;
import 'temp.dart';

/**
 * Doc comment for class [B].
 *
 * Multiline Test
 */

/*
 * Normal comment for class B.
 */
class B extends A {

  B();
  B.fooBar();

  /**
   * Test for linking to super
   */
  int doElse(int b) {
    print(b);
    return b;
  }

  /**
   * Test for linking to parameter [c]
   */
  void doThis(int c) {
    print(c);
  }
}

int testFunc(int a) {
  return a;
}
