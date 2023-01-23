class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: int as):
      break;
  }
}
