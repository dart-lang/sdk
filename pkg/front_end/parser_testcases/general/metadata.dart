// These 10 should be OK.
@abstract
@foo.abstract
@foo.bar.abstract
@foo("hello")
@foo.abstract("hello")
@foo.bar.abstract("hello")
@foo<int>("hello")
@foo<int>.abstract("hello")
@foo.bar<int>("hello")
@foo.bar<int>.abstract("hello")
class X {}

// They should also be OK in various places for instance:
typedef F<@abstract T> = int Function<@abstract X>(@abstract int);
typedef F<@foo.abstract T> = int Function<@foo.abstract X>(@foo.abstract int);
typedef F<@foo.bar.abstract T> = int Function<@foo.bar.abstract X>(@foo.bar.abstract int);
typedef F<@foo("hello") T> = int Function<@foo("hello") X>(@foo("hello") int);
typedef F<@foo.abstract("hello") T> = int Function<@foo.abstract("hello") X>(@foo.abstract("hello") int);
typedef F<@foo.bar.abstract("hello") T> = int Function<@foo.bar.abstract("hello") X>(@foo.bar.abstract("hello") int);
typedef F<@foo<int>("hello") T> = int Function<@foo<int>("hello") X>(@foo<int>("hello") int);
typedef F<@foo<int>.abstract("hello") T> = int Function<@foo<int>.abstract("hello") X>(@foo<int>.abstract("hello") int);
typedef F<@foo.bar<int>("hello") T> = int Function<@foo.bar<int>("hello") X>(@foo.bar<int>("hello") int);
typedef F<@foo.bar<int>.abstract("hello") T> = int Function<@foo.bar<int>.abstract("hello") X>(@foo.bar<int>.abstract("hello") int);

// These 9 should fail because they start with a built in which is an
// identifier but not a typeIdentifier.
// We don't necessarily expect that parser to give the error though, the further
// pipeline will give an error because there's no class, variable etc with that
// name.
@abstract.abstract
@abstract.bar.abstract
@abstract("hello")
@abstract.abstract("hello")
@abstract.bar.abstract("hello")
@abstract<int>("hello")
@abstract<int>.abstract("hello")
@abstract.bar<int>("hello")
@abstract.bar<int>.abstract("hello")
class Y {}