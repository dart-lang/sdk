# Consistency

__The tooling should be consistent, both with itself and with similar tooling
for other languages.__

## Self consistency

When we say that the tooling should be self consistent, we mean that the
behavior of each feature should be consistent with behavior of all of the other
features. Users should be able to predict the behavior of each feature based on
their understanding of the language and the behavior of other features. This
manifests itself in several ways, which we'll explore below.

A failure to be self consistent can make the tools difficult to understand and
hard to use, and can result in a loss of trust.

### Consistency between language constructs

The same feature, when applied to semantically similar pieces of code, should
work the same way.

For example, asking for references to a class declaration should work the same
way as asking for references to a mixin declaration. It shouldn't be the case
that for mixins the tool reports references in a `with` clause but that for
classes it doesn't report such references.

This begs the question of when two pieces of code are _similar_ in the sense
intended by this principle. There is no simple answer to the question; it
depends on the language construct and the feature. But one way to answer that
question is to think about whether the differences between the two constructs
are important enough to justify a difference in the behavior of the feature.

### Consistency within a feature

When a feature is applied multiple times, the results should be consistent.

For example, if an invocation of a static method is highlighted a certain way in
one place, then the same highlighting should be used everywhere a static method
is invoked.

### Consistency between features

Individual features that are related to each other should work in a consistent
way.

For example, go-to-declaration and go-to-references are effectively inverses of
each other. It should be the case that if a user can navigate from a reference
to its definition, then from the definition the user should be able to navigate
to that reference.

## Consistency with other languages

When we say that the tooling should be consistent with similar tooling for other
languages, we mean that we should be aware that the user might have expectations
of how a feature will work based on their familiarity with other languages.
Being consistent with other languages makes it easier for users to transfer
their knowledge of an IDE or other tool when using Dart.

There are times when the semantics of Dart might require that a feature work
differently than it does for other languages. In those cases fidelity with the
language is more important than consistency with other languages, but these
exceptions should be rare and well motivated.

Of course, it isn't the case that the tools for other languages are consistent
with each other. We need to look at the way multiple other languages implement a
feature and use that information to inform our decisions, guided by our
expectations of which other languages our users are most likely to be familiar
with and which are most compliant with the expectations of the client.
