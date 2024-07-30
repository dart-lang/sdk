> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

We have several tools, compilers, and runtimes that implement Dart in some way. We must test all of them thoroughly. We'd also like to reuse tests across as many of those tools as we can. The primary challenge is that these tools sometimes vary in their behavior deliberately. For example:

```dart
main() {
  Expect.notEquals(1.0, 1);
}
```

On the web, we represent all numbers using JavaScript numbers, which don't distinguish between integers and floating point numbers of the same value. So in dart2js and DDC, this test "fails". But that is the behavior we *intend* it to have, so this failure doesn't indicate a bug in the tool.

Other times, behavior varies across different configurations of a single tool. A test of the `assert()` statement will produce a different outcome in debug versus release mode. To manage this, we need a mechanism to define which tests are considered meaningful for which configurations.

Currently, we mostly express this in the status files. There are status file entries that mark tests as being `SkipByDesign` on some configurations. That means "this test specifies the wrong behavior for this configuration, so don't use it". We'd like to move away from status files over time.

There is now a new system called "requirements" which is used for testing NNBD but could be extended for other needs. It works like this:

## Test Requirements

A test can have a comment line starting with `Requirements=` followed by a comma-separated list of identifiers. Each identifier is the name of a "feature" that a Dart tool may support. For example:

```dart
// Requirements=nnbd
main() {
  late var i = 3;
  Expect.equals(3, i);
}
```

The full set of features is defined [here][features]. For any given configuration, the test runner knows which features that configuration supports. When it is determining which tests to run, if a test requires a feature that the configuration does not support, the test is automatically skipped.

[features]: https://github.com/dart-lang/sdk/blob/main/pkg/test_runner/lib/src/feature.dart
