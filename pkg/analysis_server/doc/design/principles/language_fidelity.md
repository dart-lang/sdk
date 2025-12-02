# Language Fidelity

[Dart Language Specification]: https://storage.googleapis.com/dart-specification/DartLangSpecDraft.pdf

__The tooling should never mislead the user about the syntax or semantics of
the language.__

That probably sounds obvious, at least on the surface. But you might be
surprised by how often we receive requests for changes that would violate that
principle.

The syntax and semantics of Dart are non-trivial, and some of those requests are
probably a result of misunderstandings about the language. In this document
we'll look at some of the complexities of the language and how that impacts the
design of the UX.

## Syntax

Dart's syntax is fairly straightforward, but there are a few places where it can
impact the user experience.

### Reserved words, build-in identifiers, and positionally significant identifiers

Dart has three categories of identifiers with special semantics:

<dl>
<dt>Reserved words</dt>
<dd>
Identifiers that can only be used in specified places in the grammar. They
can't be used in any kind of declaration.
</dd>
<p></p>
<dd>
Examples include `class` and `if`. The complete list is in the
[Dart Language Specification][] in section 21.1.1.
</dd>
<dt>Build-in identifiers</dt>
<dd>
Identifiers that are used as keywords in Dart, but are not reserved words. A
built-in identifier may not be used to name a class or type, but can be used in
other declarations.
</dd>
<p></p>
<dd>
Examples include `import` and `extension`. The complete list is in the
[Dart Language Specification][] in section 17.38.
</dd>
<dt>Positionally significant identifiers</dt>
<dd>
Identifiers that can be used for any kind of declaration but which have a
special meaning when used in certain locations.
</dd>
<p></p>
<dd>
Examples include `show` and `on`. The complete list is in the
[Dart Language Specification][] in section 17.38.
</dd>
</dl>

The question is whether to explicitly represent these three categories of
identifiers or whether to ignore the distinctions. It could be argued that
ignoring the distinction would violate this design principle. It could also be
argued that making the distinction might be confusing for the user.

In the end, we decided that the better interpretation of the language spec is
that there are two important categories: identifiers that are functioning as a
keyword and identifiers that are not.

This has implications for
- Semantic highlighting
- Code completion

## The type system

For the purposes of this document, we'll classify the types in Dart's type
system into three categories:

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

Two nominal types are the same if they are introduced by the same unwrapped
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
following record-typed variables
```dart
({int x, int y}) point = (x: 1, y: 2);
({int x, int y}) pair = (x: 3, y: 4);
```
the record assigned to `point` and the record assigned to `pair` have the same
type.

Nominal types are only equal to other nominal types, structural types are only
equal to other structural types, and each of the other types are only equal to
themselves.

The differences between the different kinds of types impacts many features,
including occurrences and navigation.

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
structural types led us to not support navigation from references to a member of
a structural type and the declaration(s) of the member.

## Elements without a declaration

There are some elements that exist in the element model for which there is no
explicit declaration. These cases are listed below.

In all such cases the principle of language fidelity dictates that the tools
shouldn't pretend that there is a declaration.

For example, go-to-declaration isn't available for references to these elements.

### Default constructors

If a class does not have any explicit constructor declarations, then there is an
implicit unnamed constructor, sometimes refered to as the "default" constructor.

### Enums

In addition to the possible default constructor, an enum declaration has an
implicit static member named `values`.

### Built-in types

Several of the types don't have a declaration. These include types such as
`void` and `dynamic`.

## Multiple elements from a single declaration

A single declaration can sometimes give rise to more than one element.
That means that that a single name can refer to semantically distinct elements
at different points in the code. The kinds of declarations for which this is
true are given below.

This has implications for features like occurences and navigation.

### Fields, getters, and setters

Every field declaration generates two or three separate elements:
- the field itself,
- the induced getter used to access the field, and
- the induced setter used to assign to the field, as long as the field is
  neither `final` nor `const`.

A field cannot be overridden, but getters and setters _can_ be overridden,
either by an explicit getter or setter or by the getter and setter induced by
another field declaration.

In most places, a reference to a field is actually a reference to either the
getter or the setter. The only places where a field can actually be referenced
are in the parameter list or initializer list of a constructor.

### Declaring parameters

A declaring parameter (found in a primary constructor) introduces a parameter,
a field, and the getter and setter induced by that field.

### Object patterns with a matching pattern variable

An object pattern specifies a list of properties and patterns to be matched to
each listed property. But if the pattern is a variable pattern and the name of
the variable is the same as the name of the property, then the name of the
property can be omitted. This leads to the name of the variable playing two
roles and raising questions about how to reconcile them.

## A single element from multiple declarations

A single element can sometimes be composed from multiple declarations.

This has implications for features like navigation.

### Primary constructors

The parameters for a primary constructor are declared in the header of the
class (or enum), but the body of the constructor can be provided in the list of
members.

### Augmentations

Augmentations allow some or all of any member declaration to be in a separate
declaration, and that declaration can be in either the same part of the library
or in a different part.

### Pattern variables in switch statements

When there are multiple cases that share a body, or when there's an or-pattern,
if any of those cases (or operands) define a pattern variable, then every case
(and operand) must define a pattern variable with the same name.

There's only one variable with that name in the case body, but the declaration
is split across all of the cases (or operands).
