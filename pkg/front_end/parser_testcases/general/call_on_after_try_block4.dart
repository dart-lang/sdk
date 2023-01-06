void main(int on) {
  try {
    ;
  } catch (e) {
    ;
  } on Foo {
    ;
  }

  // With records everything called on after a try is an on clause.
  // See https://github.com/dart-lang/language/blob/master/accepted/future-releases/records/records-feature-specification.md#ambiguity-with-on-clauses
  on = 42;
}

