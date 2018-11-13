# Feature tests for instantiation to bounds, and super-bounded types

This directory was created in order to hold tests pertaining to the
Dart feature _instantiate to bound_, which provides inference of
default values for omitted type arguments. In order to handle
F-bounded type parameters without introducing infinite types, this
feature relies on another feature, _super-bounded types_, which is
therefore also in focus for tests in this directory. For more details,
please check the feature specifications on
[super-bounded types](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/super-bounded-types.md)
and on
[instantiate to bound](https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md).