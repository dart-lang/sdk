# Type Testing Stubs

This page describes how type testing stubs (TTS) are implemented.

### Type Tests

Explicit `<obj> as <desination-type>` checks in Dart code (also generated implicitly in CFE) compile
in the Dart VM's IL to the `AssertAssignable` instruction.

### Type Testing Stubs

A type testing stub is a piece of generated machine code, specialized for a type.
The `RawAbstractType` has pointer to the entry of this machine code in `type_test_stub_entry_point_`
(as well as to the corresponding `RawCode`, but that is actually not required for the operation of the stub)

The specialized machine code is self-contained and doesn't need/have an object pool.
The stub will not setup a frame: In the fast case it will perform the type check and return.

The TTS has a special calling convention which accepts:
   * the `<obj>` to perform the type test against
   * the `<destination-type>` to perform the test against
   * the instantiator type argument vector (if the destination type is not instantiated)
   * the function type argument vector (if the `<destination-type>` is not instantiated)
   * a loaded slot from the caller's object pool (which is lazily populated by runtime to contain a `RawSubtypeTestCache` if the TTS was unable to handle the type test).

This calling convention is the same as for the SubtypeTestCache-based implementation.

We distuinguish between different type tests (based on the `<destination-type>`):

#### Simple Subtype ClassId-based range checks

Types of the form `<obj> as Foo<T1, ..., Tn>` where `T1` .. `Tn` are all top-types are performed
by loading the class id of `<obj>` and checking whether it is contained in the set of all class-id ranges of
classes directly or transitively extending/implementing `Foo`.

In AOT mode in particular this is very fast because we perform a depth-first preorder numbering of classes, which
means we have a single range for `as Foo` if `Foo` is not implemented. Otherwise we might have multiple ranges.

This test is exhaustive.

#### Complex Subclass ClassId-based range checks

Types of the form `<obj> as Foo<T1, ..., Tn>` where at least one `Ti` is not a top type are performed by loading the class id of `<obj>` and checking whether it lies inside the subclass ranges. Since we check for direct/indirect subclasses and not implementors (this test is non-exhaustive) we know at which offset the type argument vector is.

We then load the instance type arguments vector `<obj>.<tav>` and perform a type check for each `Ti`. Notice these "inner type checks" are different from the original check: Instead of checking `<some-obj> as <type>` we now have to check whether `<some-type> is <other-type>`. This asymmetry is also the reason why a TTS cannot call other TTS.

For each `Ti` we perform now a check of the form `<obj>.tav[i]` is <Ti>` as follows:

* If `Tx` is an instantiated type of the form `Bar<H1, ..., Hn>` where all `H1`..`Hn` are top-types we perform the same ClassId-based range check as above in the simple case (this test is exhaustive)

* If `Tx` is a type parameter we will load its value (i.e. instantiate it) via the instantiator/function type argument vector and compare `<obj>.tav[i] == <Ti>.value` (this test is non-exhaustive)

#### Fallbacks

If the TTS performed the type test and it succeeded, it will return immediately (fast case). If the type test failed or the TTS was non-exhaustive it will do a tail-call to a `SlowTypeTestStub` which will examine the test to be done and call the much slower SubtypeTestCache based implementation. It will, based on the STC's return value either return successfully or go to runtime to either lazily create/update a SubtypeTestCache or throw an exception.

## AssertAssignable via Type Testing Stubs

The implementation of `AssertAssignable` will perform an in-line ClassId-based range check (based on code size heuristics). If such an inline check fails or the check would be too big, we will do an actual call.

Currently this call always uses TTS in AOT mode (and in JIT mode if the destination type is either a type parameter or an instantiated interface type). To perform the call it will ensure the arguments to the TTS are in the right registers.

If `<destination-type>` is a type parameter we will load its value and call its TTS instead.

## JIT mode

In JIT mode we build the TTS lazily on first involcation (the TTS of types will be initialized to the `LazySpecializeTypeTest` stub). If later on more classes get loaded and the TTS fast path starts failing we re-build the TTS.

After a hot-reload we reset all types to the lazy specialize TTS.

## AOT mode

In AOT mode we try to guess for which types we might need a TTS. For every `AssertAssignable` we remember its `<destination-type>`. If it was a type parameter `T` we also try to see (in a limited way) what can flow into `T` and mark such types for needing a TTS.
