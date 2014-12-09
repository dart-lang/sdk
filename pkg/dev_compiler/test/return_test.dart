dynamic a = 42;

// This requires a check / unbox.
int get b => a;

// This requires a type check.
String c() => a;

d() {
  return a;
}

// This requires a type check.
String e() {
  return a;
}

class A {
  A.named();

  factory A() => a;
}

void main() {
  print(a);
  print(b);
  a = "Hello";
  print(c());
  print(d());
  print(e());
  a = new A.named();
  print(new A());
}
