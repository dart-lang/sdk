import 'a.dart' if (dart.library.html) 'b.dart' if (dart.library.io) 'c.dart';
export 'a2.dart'
    if (dart.library.html) 'b2.dart'
    if (dart.library.io) 'c2.dart';

Foo x() {
  return new Foo();
}
