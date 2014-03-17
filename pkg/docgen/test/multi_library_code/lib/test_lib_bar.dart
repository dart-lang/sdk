library test_lib.bar;

import 'test_lib.dart';

/*
 * Normal comment for class C.
 */
class C {
}

/// [input] is of type [C] returns an [A].
A generateFoo(C input) {
  throw 'noop';
}

/// Processes a [C] instance for testing.
///
/// To eliminate import warnings for [A] and to test typedefs.
typedef A AnATransformer(C other);
