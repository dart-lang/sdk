class C<T> {}
test(dynamic x) {
  switch (x) {
    case C<int>():
      break;
  }
}
