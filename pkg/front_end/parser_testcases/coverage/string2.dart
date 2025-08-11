void foo(dynamic bar) {
  return """æbler$bar"""
}

void bar() {
  return """æbler"""
}

void baz() {
  return r"""hello"""
}

void qux() {
  return """
æbler
"""
}

void quux() {
  // ends in eof.
  return """æbler\