# Feature tests for void

This directory was created in order to hold tests pertaining to the
Dart feature temporarily known as _generalized void_. This feature
allows the type `void` to occur in many locations where it was
previously a compile-time error, and it is intended to allow
developers to express the intent that the value of certain expressions
is of no interest, and help them to avoid using such values. For more
details, please check the
[feature specification](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/generalized-void.md).