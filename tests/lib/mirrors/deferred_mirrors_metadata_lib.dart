library lib;

import "deferred_mirrors_metadata_test.dart";
@MirrorsUsed(targets: const ["main", "main.A", "main.B", "main.C", "lib.D"])
import "dart:mirrors";

@C() class D {}

String foo() {
  String c = reflectClass(D).metadata[0].invoke(#toString, []).reflectee;
  InstanceMirror i = currentMirrorSystem().findLibrary(#main).metadata[0];
  String a = i.invoke(#toString, []).reflectee;
  String b = i.getField(#b).invoke(#toString, []).reflectee;
  return a + b + c;
}

