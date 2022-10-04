class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(: int as):
      break;
  }
}
