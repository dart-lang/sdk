void method(o) {
  switch (o) {
    case X1(
        :var s,
        :var i,
        :var d,
      ):
      print("hello X1($s, $i, $d)");
    case X2(
        :var s2,
        :var i,
        :var d,
      ):
      print("hello X2($s2, $i, $d)");
  }
}

class X1 {
  String? s;
  int? i;
  double? d;
}

class X2 {
  String? s2;
  int? i;
  double? d;
}
