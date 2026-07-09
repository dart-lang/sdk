class C<T> {
  T? f;
}
test(dynamic x) {
  switch (x) {
    case C<int>(f: 1)!:
      break;
  }
}
