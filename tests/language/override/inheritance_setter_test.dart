main() {
  new C();
}

class A {
  void set setter1(num x) {} //# 001: compile-time error
  void set setter2(num x) {} //# 002: compile-time error
  void set setter3(num x) {} //# 003: ok
  void set setter4(num x) {} //# 004: compile-time error
  void set setter5(num x) {} //# 005: ok
  void set setter6(num x) {} //# 006: compile-time error
  void set setter7(num x) {} //# 007: compile-time error
}

class B extends A {
  void set setter1(covariant dynamic x) {} //# 001: continued
  void set setter2(int x) {} //# 002: continued
  void set setter3(covariant dynamic x) {} //# 003: continued
  void set setter4(dynamic x) {} //# 004: continued
  void set setter5(covariant dynamic x) {} //# 005: continued
  covariant dynamic setter6; //# 006: continued
  covariant dynamic setter7; //# 007: continued
}

class C extends B {
  void set setter1(String x) {} //# 001: continued
  void set setter3(num x) {} //# 003: continued
  void set setter4(int x) {} //# 004: continued
  void set setter5(int x) {} //# 005: continued
  void set setter6(String x) {} //# 006: continued
  void set setter7(int x) {} //# 007: continued
}
