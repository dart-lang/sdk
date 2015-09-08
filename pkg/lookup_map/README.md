# Lookup maps

This package contains the definition of `LookupMap`: a simple, but very
restricted map. The map can only hold constant keys and the only way to use the
map is to retrieve values with a key you already have.  Except for lookup, any
other operation in `Map` (like forEach, keys, values, length, etc) is not
available.

Constant `LookupMap`s are understood by dart2js and can be tree-shaken
internally: if a key is not used elsewhere in the program, its entry can be
deleted from the map during compilation without changing the program's behavior.
Currently dart2js supports tree-shaking keys that are Type literals, and any
const expression that can only be created with a const constructor. This means
that primitives, Strings, and constant objects that override the `==` operator
cannot be tree-shaken.

**Note**: this feature is currently experimental in dart2js, we recommend trying
other alternatives before relying on this feature.

## Examples

`LookupMap` is unlikely going to be useful for individual developers writing
code by hand. It is mainly intended as a helper utility for frameworks that need
to autogenerate data and associate it with a type in the program. For example,
this can be used by a dependency injection system to record how to create
instances of a given type. A dependency injection framework can store in a
`LookupMap` all the information it needs for every injectable type in every
library and package.  When compiling a specific application, dart2js can
tree-shake the data of types that are not used by the application. Similarly,
this can also be used by serialization/deserialization packages that can store
in a `LookupMap` the deserialization logic for a given type.
