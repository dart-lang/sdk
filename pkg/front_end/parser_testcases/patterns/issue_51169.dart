class Class {
  dynamic field;
  Class(this.field);
}

test(a) {
  switch (a) {
    case (foo: int b) when b != 2:
      print(b);
    case (foo: (int, int) b) when b != (2, 3):
      print(b);
    case Class(field: int b) when b != 2:
      print(b);
    case Class(field: (int, int) b) when b != (2, 3):
      print(b);
  }
}

testNullable(a) {
  switch (a) {
    case (foo: (int, int)? b) when b != (2, 3):
      print(b);
    case Class(field: (int, int)? b) when b != (2, 3):
      print(b);
  }
}
