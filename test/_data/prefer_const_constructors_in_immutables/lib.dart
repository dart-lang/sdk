import 'package:meta/meta.dart';

@immutable
class D {
  D.c1(a) : assert(a.toString() != null);  // OK
  D.c2(a) : assert(a != null);  // LINT
}
