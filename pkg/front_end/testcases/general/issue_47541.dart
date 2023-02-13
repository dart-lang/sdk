void notMain() {
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

  // With records this is no longer a call after a try block, but a on clause
  // where the type is the empty record.
  on () {
    ;
  }

  // This is a call though.
  on(42);
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

void on(e) {}

class Foo {}