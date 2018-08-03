library main;

// Test that the library-mirrors are updated after loading a deferred library.

@MirrorsUsed(targets: "D")
import "dart:mirrors";

import "deferred_mirrors_update_lib.dart" deferred as l;

class D {}

void main() {
  print(reflectClass(D).owner);
  l.loadLibrary().then((_) {
    l.foo();
  });
}
