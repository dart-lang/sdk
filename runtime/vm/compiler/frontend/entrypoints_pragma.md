# Pragma for testing multiple entrypoints

Example:

```dart
void hook(String functionName, int entryPointId) {
  // ...
}

class C<T> {
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", hook)
  void foo(T x) {
    // ...
  }
}
```

When `foo` is invoked, `hook` will be called in `foo`'s prologue if `foo` was
compiled with multiple entrypoints. `hook` will be passed the name of the
function it was called for and the ID of the entrypoint used for the invocation:

- 0: Normal entry.

- 1: Unchecked entry: prologue was short so separate prologues for normal and
  unchecked entry were compiled.

- 2: Unchecked shared entry: prologue was long, so normal and unchecked entry
  set a temporary and type-checks are predicated on the temporary.
