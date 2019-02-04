# Dart 2 function return checking

**Owner**: leafp@google.com

**Status**: This document is now background material.
For normative text, please consult the language specification.

**Note: Also see alternative presentation at the bottom for a dual presentation
of these rules in terms of which things are errors, rather than which things are
valid*.*


## Errors for sync and async function return values in Dart 2

### Expression bodied functions


An asynchronous expression bodied function with return type `T` and body `exp`
has a valid return if:
  * `flatten(T)` is `void`
  * or `return exp;` is a valid return for an equivalent block bodied function
  with return type `T` as defined below.

A synchronous expression bodied function with return type `T` and body `exp` has
a valid return if:
  * `T` is `void`
  * or `return exp;` is a valid return for an equivalent block bodied function
  with return type `T` as defined below.

### Block bodied functions

#### Synchronous functions

The rules for a synchronous non-generator function with declared return type `T`
are:

* `return;` is a valid return if any of the following are true:
  * `T` is `void`
  * `T` is `dynamic`
  * `T` is `Null`.

* `return exp;` where `exp` has static type `S` is a valid return if:
  * `S` is `void`
  * and `T` is `void` or `dynamic` or `Null`

* `return exp;` where `exp` has static type `S` is a valid return if:
  * `T` is `void`
  * and `S` is `void` or `dynamic` or `Null`

* `return exp;` where `exp` has static type `S` is a valid return if:
  * `T` is not `void`
  * and `S` is not `void`
  * and `S` is assignable to `T`

#### Asynchronous functions

The rules for an asynchronous non-generator function with declared return type
`T` are:

* `return;` is a valid return if any of the following are true:
  * `flatten(T)` is `void`
  * `flatten(T)` is `dynamic`
  * `flatten(T)` is `Null`.

* `return exp;` where `exp` has static type `S` is a valid return if:
  * `flatten(S)` is `void`
  * and `flatten(T)` is `void`, `dynamic` or `Null`

* `return exp;` where `exp` has static type `S` is a valid return if:
  * `flatten(T)` is `void`
  * and `flatten(S)` is `void`, `dynamic` or `Null`

* `return exp;` where `exp` has static type `S` is a valid return if:
  * `T` is not `void`
  * and `flatten(S)` is not `void`
  * and `Future<flatten(S)>` is assignable to `T`


## Errors for sync and async function return values in Dart 2: Alternative presentation in terms of which things *are* errors

### Expression bodied functions


It is an error if an asynchronous expression bodied function with return type
`T` has body `exp` and both:
  * `flatten(T)` is not `void`
  * `return exp;` would be an error in an equivalent block bodied function
  with return type `T` as defined below.

It is an error if a synchronous expression bodied function with return type `T`
has body `exp` and both:
  * `T` is not `void`
  * `return exp;` would be an error in an equivalent block bodied function
  with return type `T` as defined below.

### Block bodied functions

#### Synchronous functions

The rules for a synchronous non-generator function with declared return type `T`
are:

* `return;` is an error if `T` is not `void`, `dynamic`, or `Null`

* `return exp;` where `exp` has static type `S` is an error if `T` is `void` and
  `S` is not `void`, `dynamic`, or `Null`

* `return exp;` where `exp` has static type `S` is an error if `S` is `void` and
  `T` is not `void`, or `dynamic` or `Null`.

* `return exp;` where `exp` has static type `S` is an error if `S` is not
  assignable to `T`.

#### Asynchronous functions

The rules for an asynchronous non-generator function with declared return type
`T` are:

* `return;` is an error if `flatten(T)` is not `void`, `dynamic`, or `Null`

* `return exp;` where `exp` has static type `S` is an error if `T` is
  `void` and `flatten(S)` is not `void`, `dynamic`, or `Null`

* `return exp;` where `exp` has static type `S` is an error if `flatten(S)` is
  `void` and `flatten(T)` is not `void`, `dynamic`, or `Null`.

* `return exp;` where `exp` has static type `S` is an error if
  `Future<flatten(S)>` is not assignable to `T`.
