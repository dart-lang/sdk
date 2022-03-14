void main() {
  a();
  b();
  c(42);
  d(42);
}

void a() {
  try {
    ;
  } catch (e) {
    ;
  } on Foo {
    ;
  }

  on();
}

void b() {
  try {
    ;
  } catch (e) {
    ;
  } on Foo {
    ;
  }

  onX(e) {
    ;
  }
  onX("");
}

void c(int on) {
  try {
    ;
  } catch (e) {
    ;
  } on Foo {
    ;
  }
  on = 42;
}

void d(int on) {
  try {
    ;
  } catch (e) {
    ;
  } on Foo {
    ;
  }
  on.toString();
}

void on() {}

class Foo {}