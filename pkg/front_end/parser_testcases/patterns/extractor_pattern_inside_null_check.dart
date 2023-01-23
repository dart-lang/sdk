class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1)?:
      break;
  }
}
