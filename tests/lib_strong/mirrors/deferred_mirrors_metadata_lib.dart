library lib;

import "deferred_mirrors_metadata_test.dart";
@MirrorsUsed(
    targets: const ["main", "main.A", "main.B", "main.C", "main.D", "lib.E"])
import "dart:mirrors";

class H {
  const H();
}

class F {
  @H()
  final int f;
}

@C()
class E {
  @D()
  var f;
}

String foo() {
  String c = reflectClass(E).metadata[0].invoke(#toString, []).reflectee;
  String d = reflectClass(E)
      .declarations[#f]
      .metadata[0]
      .invoke(#toString, []).reflectee;
  InstanceMirror i = currentMirrorSystem().findLibrary(#main).metadata[0];
  String a = i.invoke(#toString, []).reflectee;
  String b = i.getField(#b).invoke(#toString, []).reflectee;
  return a + b + c + d;
}
