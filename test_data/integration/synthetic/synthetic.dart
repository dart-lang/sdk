// Verifies that synthetic nodes don't get lints.
// The simple identifier synthesized after `XXX` below triggers the
// `non_constant_identifier_names` lint.
// See: https://github.com/dart-lang/linter/issues/193
class C <E>{ }
C<int>;
