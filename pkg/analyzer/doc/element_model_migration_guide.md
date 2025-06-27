# Migration guide

The purpose of this migration guide is to help clients of the analyzer package
migrate to version 7.4.

The biggest change in version 7.4 is the introduction of the new element model
API. Unfortunately, it isn’t possible to automate the migration, so we wanted to
make the process as easy as possible by explaining why we made the changes, what
changes were made, and what you need to do in order to migrate your code.

## The reason for the change

The changes to the element model were necessary in order for the analyzer to
support both the [enhanced parts][enhanced_parts] and
[augmentations][augmentations] language features, both of which extend the
semantics of the language in significant ways.

[augmentations]: https://github.com/dart-lang/language/blob/main/working/augmentation-libraries/feature-specification.md
[enhanced_parts]: https://github.com/dart-lang/language/blob/main/working/augmentation-libraries/parts_with_imports.md

There are also a few small syntactic changes as a result of these features, but
the changes to the AST structure are all experimental and don’t require any
migration work at this point, so we won’t discuss them here.

### Overview of the language features

While you should probably read the details of the language features before you
attempt to support them, this section attempts to describe the aspects of those
features that impact the element model API. Note that it is not necessary for
you to support the new language features in order to migrate to the new element
model APIs. In fact, given that the analyzer package doesn’t yet support the
augmentations feature you probably can’t support it yet even if you want to.

As you know, the element model describes the semantic (as opposed to syntactic)
structure of Dart code. Generally speaking, an element represents something that
is defined in the code, such as a class, method, or variable. That hasn't
changed, but there are two things that have changed.

It has always been possible to break a library into multiple files (the
"defining" compilation unit and zero or more "parts"). The old model represented
these parts as a list. The enhanced_parts feature makes it possible for parts to
have not only their own imports but also sub-parts. A list is no longer
sufficient to represent the semantics, so in the new model these parts are
represented as a tree.

It used to be the case that every element was fully defined by a single lexical
declaration. With the introduction of augmentations, some elements can now be
defined by multiple declarations, and those declarations can be located in one
or more parts, with each part in the library contributing zero, one, or many
pieces of the element's definition. This has led to the need to represent both
the individual declarations as well as the element that is defined by those
declarations.

## Changes to the element model

This section describes some of the changes made to the element model in order to
accommodate these language features. It is not intended to be comprehensive.

### Name changes

In order to make it easier to incrementally migrate code we have made it
possible to have both the old and new APIs imported into a single library
without conflict. We did this by changing the names of the classes in the new
API. In most cases we did this by appending the digit `2` to the end of the name
of the corresponding class in the old API. For example, the class
`LibraryElement` has been replaced by the class `LibraryElement2`,
`ClassElement` by `ClassElement2`, etc. There are a couple of exceptions,
described in the section below titled “Specific model changes”.

To make the implementation of the new model easier we also changed the names of
the members of those classes whose signature changed. Most of the time this
follows the same pattern of adding a digit to the old name, but in a few cases
we made a more comprehensive change to the name in order to end up with a more
consistent API.

Additional details of the name changes are available in the `@deprecated`
annotations. It might be worthwhile migrating to version 7.4 in order to have
those annotations available during the migration.

### Introduction of fragments

Some information that used to be associated with an element, specifically
information related to the single declaration site, no longer makes sense to
have on the elements because there are now potentially multiple declaration
sites. For example, every element used to know the offset of the element's name
in the declaration, but with multiple declaration sites the name can now appear
at multiple offsets in multiple files.

Instead, we have introduced a new set of classes, rooted at `Fragment`, to
represent the information related to a single declaration site. For consistency,
every element has one or more fragments associated with it, even if that
particular kind of element, such as a local variable, can never have multiple
declaration sites. Information that isn't specific to a declaration site is
still accessed through the element.

Just as elements exist in a hierarchy, the corresponding fragments also form a
parallel hierarchy. For example, just as every method element is a child of a
class-like element (class, mixin, etc.), every method fragment is a child of a
class-like fragment.

Some information is available through both the element and the fragments, but
with slightly different semantics. For example, you can ask a class fragment
(representing a single class declaration) for the member fragments contained in
it, but you can also ask a class element for all of the member elements defined
for it and get the results of merging all of the member fragments from all of
the declaration sites.

### Compilation units

A `CompilationUnitElement` is no longer an element. It's now a fragment and its
name has changed to `LibraryFragment` to reflect this change. That means that,
for example, a class element is now contained in a library, not in a compilation
unit. But, as expected, a class fragment _is_ contained in a library fragment.

Libraries have always been the merge of the declarations in all of the parts,
this just makes the treatment of parts be consistent with the way the rest of
the declarations are now handled. In other words, just as one or more
`ClassFragment`s are merged to define a class, one or more `LibraryFragment`s
are merged to define a library.

And, as noted above, `LibraryFragment`s form a tree structure.

### Getters and setters

The class `PropertyAccessorElement` has been replaced by the classes
`GetterElement` and `SetterElement`.

Getters and setters are different enough that it makes sense for them to have
different APIs, so we decided to have different classes to represent them.

### Formal parameters

Rather than rename `ParameterElement` to `ParameterElement2`, we renamed it to
`FormalParameterElement`. We did this to make a more clear distinction between
_formal_ parameters associated with functions and methods (appearing between
`(` and `)`) and _type_ parameters associated with generic declarations
(appearing between `<` and `>`).

### Functions

The class `FunctionElement` has been replaced by the classes
`TopLevelFunctionElement` and `LocalFunctionElement`.

Top-level functions can have multiple declarations, but local functions can’t.

### Local declarations

Unlike most other elements, the elements representing local declarations (local
variables, local functions, and statement labels) can only ever have a single
declaration site (that is, a single fragment).

While it makes sense to ask a method element for the class-like element that
it’s defined in, it doesn’t make sense to ask a local variable element for the
method element it’s defined in, nor does it make sense to ask a method element
for all of the local variables in all of the method’s fragments. Therefore, if
you ask a local variable element for its enclosing element it will return
`null`. You can, however, ask a local variable fragment for its enclosing
fragment.

### Directives

In the old model there were subclasses of `Element` providing information about
the directives in a library. In the new model there are similar classes, but
they are no longer subclasses of `Element` because directives don’t define
anything that can be referenced. (Import directives can include the declaration
of an import prefix, and an import prefix is still represented as an element,
but the import containing the prefix declaration isn’t an element.)

### Class member changes

Some members of the element classes have been removed because they no longer
make sense to have on the element. Those members have been moved to the
corresponding fragment.

### Accessing metadata

In the old API you could ask any element for its `metadata` and get back a list
of the annotations associated with the declaration and there were a number of
helper getters of the form `hasSomeAnnotation` for annotations defined in the
SDK or the `meta` package.

In the new API you can ask either a fragment or an element for `metadata2` to
get an instance of `Metadata`. That instance can be used to access the list, and
it’s also where the helper getters are now defined. It adds a level of
indirection, but by reducing the number of getters defined on `Element` we hope
to have made it easier to discover other more commonly used members.

## Changes outside the element model

The APIs used to access the element model haven't changed significantly in most
cases. The names of the members used to access the new element model are, by
necessity, different from the deprecated methods used to access the old model,
usually by adding a `2` at the end of the name (though in some cases we already
had a `2` at the end of the name, so in those cases we used a different digit).

There are a few places where we made a more significant change. For example, it
used to be possible to ask some AST nodes for the `staticElement` associated
with them, but to access the element from the new model you should use
`element`. In some cases the name change is a reflection of the fact that the
member returns a fragment rather than an element, as is the case for declaration
nodes where the getter `declaredElement` has been replaced by
`declaredFragment`.

## Migrating from the old element model

The most difficult part of migrating code to the new element model is deciding
whether an element was being used in order to get information about the full
definition of the element or whether it was being used to access information
about a single declaration site. It is, of course, possible that the answer is
"both".

As you've probably already figured out, the question is important because it
tells you whether you need to use the element, the fragment, or both after the
migration.

After you’ve figured out where the information you need lives in the new model
it should generally be fairly easy to figure out how to access it.

If you aren’t attempting to support augmentations as part of this migration
(which is our recommendation), then anywhere you need to access information that
has moved from the element to a fragment, you can use `Element.firstFragment` to
get to the information. That’s because, until the experiment is enabled, every
element will have exactly one fragment.

## Migration examples

Let's look at two examples of migrating some code. The examples are taken from
the analysis_server package, so they’re real code, and should be fairly
representative without being overly complex.

### Add missing enum case clauses

This is a fix that will add case clauses to a switch over an enumerated type. It
uses the element model in a couple of ways.

To start, we need to understand how the code works, which we’ll do by looking at
the pre-migrated code. It starts by getting the type of the value being switched
over. If the type is an `InterfaceType` then it gets the element associated with
the type.

```dart
var enumElement = expressionType.element;
```

It then checks to see whether the element is an `EnumElement`.

```dart
if (enumElement is EnumElement) {
  // ...
}
```

If it is, the list of enum constants is iterated over and each constant is added
to a collection.

It then iterates over the list of switch cases in the switch statement (or
expression), getting the elements associated with each switch case and removing
those elements from the collection.

```dart
var element = expression.staticElement;
if (element is PropertyAccessorElement) {
  unhandledEnumCases.remove(element.name);
}
```

At the end, the collection contains a list of the missing constants and new
switch cases are added for those constants.

Now let's look at what we need to do to translate the fix.

When it's getting the list of constants it's fairly clear that we want all of
the constants, no matter where they're declared. That means we want the merged
view, so we need the new element, an `EnumElement2`, and we can get that by
using a different getter.

```dart
var enumElement = expressionType.element3;
```

We also need to update the condition that tests the type to use the type from
the new model.

```dart
if (enumElement is EnumElement2) {
  // ...
}
```

When we ask the element for the constants we'll get back instances of
`FieldElement2`. That means that when we're iterating over the switch cases we
need to also get the elements, which we can do by rewriting the code to the
following:

```dart
var element = expression.element;
if (element is GetterElement) {
  unhandledEnumCases.remove(element.name);
}
```

There are a couple of other places where the names of types or members need to
be updated, and the import needs to be changed to include
`package:analyzer/dart/element/element2` rather than
`package:analyzer/dart/element/element`, but that’s the majority of the changes.

### Add enum constant

This is a fix that will add a declaration of an enum constant to an existing
enum.

It works by first getting the element associated with the name of the enum.

```dart
var targetElement = target.staticElement;
```

It then checks to make sure that the `targetElement` exists and that it isn’t
defined in the SDK.

```dart
if (targetElement == null) return;
if (targetElement.library?.isInSdk == true) return;
```

Then it finds the declaration to which the constant will be added.

```dart
var targetDeclarationResult =
    await sessionHelper.getElementDeclaration(targetElement);
```

It then figures out which file the declaration is in.

```dart
var targetSource = targetElement.source;
```

And the rest is using the AST to figure out where to insert the new declaration,
so that part doesn’t need to change (and we’ll ignore it for the sake of
brevity).

Now let's look at what we need to do to translate the fix.

It will still need to get the element associated with the name of the enum
(because no other information is available), so we’ll use the new API to do
that.

```dart
var targetElement = target.element;
```

We’ll update the way it validates that we have a good enum to work with. By
testing the type we’re doing a null check and we’re also promoting the variable.

```dart
if (targetElement is! EnumElement2) return;
if (targetElement.library2.isInSdk) return;
```

We’ll need to update the way we get the declaration result, because declarations
are associated with fragments, not with elements. For the purposes of the
migration, we’ll just use the first fragment.

```dart
var targetFragment = targetElement.firstFragment;
var targetDeclarationResult = await sessionHelper.getFragmentDeclaration(
  targetFragment,
);
```

Finally, it needs to use the fragment, rather than the element, in order to find
out which file to update

```dart
var targetSource = targetFragment.libraryFragment.source;
```

And that’s pretty much it.

Note that this has the same behavior it had before, but doesn’t support
augmentations. If we wanted to support augmentations we’d need to ask if and how
having multiple declarations should impact the behavior of the fix.
