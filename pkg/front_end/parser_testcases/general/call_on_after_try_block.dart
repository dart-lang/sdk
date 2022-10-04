void main() {
  try {
    ;
  } catch (e) {
    ;
  } on Foo {
    ;
  }

  // With records "on()"  is no longer a call after a try block, but a on clause
  // where the type is the empty record.
  // See https://github.com/dart-lang/language/blob/master/accepted/future-releases/records/records-feature-specification.md#ambiguity-with-on-clauses
  // This is a call though as (x) isn't a valid record type.
  on(42);
}

void on(e) {}
