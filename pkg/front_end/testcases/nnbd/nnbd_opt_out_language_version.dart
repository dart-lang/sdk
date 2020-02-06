// @dart=2.4

class late {
  int get g => 1;
}

class required {
  int get g => 2;
}

class C {
  late l = late();
  required r = required();
}

main() {
  if (new C().l.g != 1) throw "Expected 1";
  if (new C().r.g != 2) throw "Expected 2";
}
