String g() {
  return bField.a("a") + (bField.b ?? "c");
}

class B {
  dynamic a;
  dynamic b;
  B({this.a});
}

var bField = B(a: (String s) => "$s");
