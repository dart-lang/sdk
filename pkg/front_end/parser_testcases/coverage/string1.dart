String foo(dynamic bar) {
  return "æble $bar";
}

String bar() {
  return "æble
}

String baz() {
  return "$1"
}

String qux() {
  return r"æble$"
}

String quux() {
  return r"æble$
}

String corge() {
  // Ends in eof.
  return r"æble