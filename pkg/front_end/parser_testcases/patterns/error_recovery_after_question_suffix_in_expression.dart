f() {
  try {
    true ?  : 2;
  } catch (e) {}
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);
  }

  test_extractor_pattern_inside_cast() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1) as Object:
      break;
  }
}
