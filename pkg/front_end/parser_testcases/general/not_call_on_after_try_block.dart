void main() {
  try {
    ;
  } catch (e) {
    ;
  } on Foo {
    ;
  }

  // With records this is no longer a call after a try block, but a on clause
  // where the type is the empty record.
  // See https://github.com/dart-lang/language/blob/master/accepted/future-releases/records/records-feature-specification.md#ambiguity-with-on-clauses
  on() {
    ;
  } on(a, b) {
    ;
  } on(a, b, c) {
    ;
  }
}

void on([a, b, c]) {}
