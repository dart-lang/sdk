import 'nonexisting.dart' if (dart.library.io) 'exists.dart';
export 'nonexisting.dart'
    if (dart.library.html) 'exists2.dart'
    if (dart.library.io) 'exists.dart';

Foo x() {
  return new Foo();
}
