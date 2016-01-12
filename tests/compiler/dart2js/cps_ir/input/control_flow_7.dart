foo() { print('2'); return 2; }
main() {
  if (foo()) {
    print('bad');
  } else {
    print('good');
  }
}
