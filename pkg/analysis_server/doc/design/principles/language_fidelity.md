# Language Fidelity

__The tooling should never mislead the user about the syntax or semantics of
the language.__

That probably sounds obvious, at least on the surface. But you might be
surprised by how often we receive requests for changes that would violate that
principle.

The syntax and semantics of Dart are non-trivial, and some of those requests are
probably a result of misunderstandings about the language. In this document
we'll look at some of the complexities of the language and how that impacts the
design of the UX.

## Reserved words, build-in identifiers, and positionally significant identifiers

Dart has three categories of identifiers with special semantics:

<dl>
<dt>Reserved words</dt>
<dd>
Identifiers that can only be used in specified places in the grammar. They
can't be used in any declaration.
</dd>
<dt>Build-in identifiers</dt>
<dd>
Identifiers that are used as keywords in Dart, but are not reserved words. A
built-in identifier may not be used to name a class or type, but can be used in
other declarations.
</dd>
<dt>Significant identifiers</dt>
<dd>
Identifiers that can be used for any kind of declaration but which have a
special meaning when used in certain locations.
</dd>
</dl>

### Semantic highlighting

We needed to decide whether to explicitly represent these three categories of
identifiers or whether to ignore the distinctions. It could be argued that
ignoring the distinction would violate this design principle. It could also be
argued that making the distinction might be confusing for the user.

In the end, we decided that the better interpretation of the language spec is
that there are two important categories: identifiers that are functioning as a
keyword and identifiers that are not. As a result, we treat all of these as
keywords whenever they serve the function of a keyword, and treat them as
identifiers when they don't.

### Code completion

This also impacts code completion in that it needs to be careful about where
each kind of identifier is suggested. There is support for suggesting names in
certain declarations, but some identifiers can't be used, depending on the kind
of declaration.

## The type system

For the purposes of this document, Dart's type system has three categories of
types:

<dl>
<dt>Nominal types</dt>
<dd>
A nominal type is a type with a name, such as the type introduced by a class,
enum, mixin, or extension type declaration.
</dd>
<dt>Structural types</dt>
<dd>
A structural type is a type identified only by the structure of the type. This
includes both function types (such as `int Function(int, int)`) and record types
(such as `({int x, int y})`).
</dd>
<dt>Other types</dt>
<dd>
These are the types that don't fit into the other two categories. They include,
but are not limited to, types like `dynamic`, `void`, `Never`, and `FutureOr`.
</dd>
</dl>

One of the questions we think about when designing features related to a type is
whether two types are equal.

Types introduced by a `typedef` have names, but when we talk about the equality
of two types, if either or both of those types are introduced by a typedef then
we "unwrap" the type until we get to a type that is not introduced by a
`typedef`. The fact that a `typedef` introduces a name does _not_ make the type
a nominal type.

Two nominal types are the same if they are introduced by the same
(non-`typedef`) declaration. Given the following class declarations
```dart
class Point {
  final int x;
  final int y;
}

class Pair {
  final int x;
  final int y;
}
```
an instance of class `Point` (which has the type `Point`) and an instance of
class `Pair`, have different types, despite the fact that both have the same
number of fields, with the same types and names.

Two structural types are the same if they have the same structure. Given the
following record declarations
```dart
({int x, int y}) point = (x: 1, y: 2);
({int x, int y}) pair = (x: 3, y: 4);
```
the record assigned to `point` and the record assigned to `pair` have the same
type.

Nominal types are only equal to other nominal types, structural types are only
equal to other structural types, and the other types are only equal to
themselves.

### Occurences

The occurrences feature highlights all references to the same declaration as is
being referenced at the insertion point.

In the case of nominal types, we decided to highlight all references to a member
of a nominal type. In the case of a field, all references to the getter and/or
setter associated with the field are highlighted. We think that matches both the
semantics of the language as well as the user's expectations for this feature.

In the case of structural types, we decided that it would be misleading to
highlight all references to a field of a record just because the field has the
same name and the two record types happen to be equal. The equality of two
record types doesn't imply that the two types represent the same thing. (See the
example above about the `point` and `pair` variables.) The same is true of
parameters in a function type.

But what about cases where we know that it's the same field because it's the
same variable, and hence the types are not just equal, but are more
fundamentally the same? For example, consider
```dart
void f(({String latitude, String longitude}) coordinate) {
  print(coordinate.latitude);
  print(coordinate.latitude);
}
```

The problem is that while human readers understand what we mean by "the same",
the language spec doesn't define that concept. The type is the same, and hence
equal to itself, but not any more equal than the types of `point` and `pair`
above. And because there's no definition of the concept, there's no reliable way
to confirm whether two identifiers should be considered to refer to the same
declaration.

And that's the root of the problem. Because this is a structural type there is
no single declaration; there are potentially multiple declarations of the "same"
field (or parameter). When there's an expression of the form `o.m`, where the
type of `o` is a nominal type, the analyzer can match `m` to a single
declaration. When the type of `o` is a structural type, the analyzer can't.

Occurrences are discovered by finding references to a declaration, so in the
case of a structural type the server doesn't have the information it needs. It
_could_ do something beyond what the language specifies, and it kind of seems
reasonable in this case, but it can't support every case where a user would know
that the fields are the same.

So, we're left with a decision: either we don't highlight occurrences of members
of structural types, or we have a feature that is inconsistent, highlighting
some cases and missing others (and possibly incorrectly highlighting places that
a human reader would know to _not_ be the same).

Combining the principle that the tools shouldn't misrepresent the language
semantics and the principle that the tools should be self-consistent, we decided
to not highlight occurrences of members of structural types.

### Go to declaration

The same reasoning that led us to not highlight occurrences of members of
structural types led us to not support navigation from references to a member
and the declaration(s) of the member.

## Multiple elements from a single declaration

TBD

### Fields, getters, and setters

TBD

### Declaring parameters

TBD

## A single element from multiple declarations

TBD

### Augmentations

TBD

### Primary constructors

TBD
