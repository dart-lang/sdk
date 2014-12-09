class A {}

class B {
  B();
}

class C {
  C.named();
}

class C2 extends C {
  C2.named() : super.named();
}

class D {
  D();

  D.named();
}

class E {
  String name;

  E(this.name);
}

class F extends E {
  F(String name) : super(name);
}

class G {
  // default parameters not implemented
  G([String p1]);
}

class H {
  // default parameters not implemented
  H({String p1});
}

class I {
  String name;

  I() : name = 'default';

  I.named(this.name);
}

class J {
  int nonInitialized;
  bool initialized;

  J() : initialized = true;
}

class K {
  String s = 'a';

  K();

  K.withS(this.s);
}
