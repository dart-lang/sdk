Helper libraries for working with collections.

The `collection` package contains a number of separate libraries
with utility functions and classes that makes working with collections easier.

## Using

The `collection` package can be imported as separate libraries, or
in totality:

    import 'package:collection/equality.dart';
    import 'package:collection/algorithms.dart';
    import 'package:collection/wrappers.dart';

or

    import 'package:collection/collection.dart';

## Equality

The equality library gives a way to specify equality of elements and
collections.

Collections in Dart have no inherent equality. Two sets are not equal, even
if they contain exactly the same objects as elements.

The equality library provides a way to say define such an equality. In this
case, for example, `const SetEquality(const IdentityEquality())` is an equality
that considers two sets equal exactly if they contain identical elements.

The library provides ways to define equalities on `Iterable`s, `List`s, `Set`s, and
`Map`s, as well as combinations of these, such as:

    const MapEquality(const IdentityEquality(), const ListEquality());

This equality considers maps equal if they have identical keys, and the corresponding values are lists with equal (`operator==`) values.

## Algorithms

The algorithms library contains functions that operate on lists.

It contains ways to shuffle a `List`, do binary search on a sorted `List`, and
some different sorting algorithms.


## Wrappers

The wrappers library contains classes that "wrap" a collection.

A wrapper class contains an object of the same type, and it forwards all
methods to the wrapped object.

Wrapper classes can be used in various ways, for example to restrict the type
of an object to that of a supertype, or to change the behavior of selected
functions on an existing object.
