☠☠ **Warning: This package is experimental and may be removed in a future
version of Dart.** ☠☠

This package is not intended for wide use. It provides a temporary API to
solve the problem: "Given an object some generic type A, how do I construct an
instance of generic type B with the same type argument(s)?"

This is necessary in a few rare places in order to migrate existing code to
Dart 2's stronger type system. Eventually, the hope is to have direct
language support for solving this problem but we don't have time to get that
into 2.0, so this package is provided as a temporary workaround.

We will very likely remove support for this in a later version of Dart. Please
avoid using this if you can. If you feel you *do* need to use it, please reach
out to @munificent or @leafpetersen and let us know.
