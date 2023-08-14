# Enhancing data-driven fixes

This document describes how to enhance the data-driven fixes support to handle
new kinds of API changes.

## Overview

Data-driven fixes are a mechanism to allow package authors to specify changes to
the package's APIs with enough detail (the data) that the analysis server can
migrate a user's code from an old API a new API (the fixes). In other words,
they are a way of allowing a package author to specify API-specific quick fixes.

Before you read this you should be familiar with both
- [Writing a quick fix](quick_fix.md), and
- [Data-driven Fixes](https://github.com/flutter/flutter/wiki/Data-driven-Fixes).

## How data-driven fixes work

We'll start with a high-level overview, then dive into more detail in the
subsections.

The fixes are produced by the class `DataDriven`, which is a subclass of
`MultiCorrectionProducer`. When the class is asked for fix producers, it looks
for any transforms that might apply, and then returns an instance of the class
`DataDrivenFix` for that transform. How transforms are found is described in
"Finding the transforms".

When a `DataDrivenFix` is asked to `compute` a fix, it asks the changes in the
transform to `validate` that the change can be applied. If all of the changes
are valid, then it asks each change to `apply` itself, which causes the change
to add edits to the `ChangeBuilder`.

### Finding the transforms

When an instance of `DataDriven` looks for the transforms that might apply,
it starts by looking at the imports in the compilation unit containing the
diagnostic. The imports are used to identify the packages that might define the
element (API) that is, or was, associated with the diagnostic.

We can't just look at the static element in the AST to determine which package
it's implemented in because we want these fixes to continue to work even after
the element has been removed, at which point the reference to the element will
be unresolved.

We're making an assumption here that the file contains an import for a library
in the element's defining package. That isn't necessarily true, and we might
consider looking at all of the packages that are directly or indirectly depended
on, but (a) that would have performance implications that haven't been assessed,
and (b) we don't have any reports that this limitation is causing problems.

For each imported package, it asks the `TransformSetManager` for the
`TransformSet` associated with the package. The transform manager is responsible
for building a transform set from the data file(s) in the package. For the sake
of performance, the transform sets are cached. The process of building a
transform set is described, at least in part, in "Parse the change".

If there are any transform sets, the instance of `DataDriven` will ask the class
`ElementMatcher` to build one of more instances of itself based on the location
of the diagnostic. If the AST node has been resolved (because the element is
only deprecated), a single element matcher can be returned. If the AST node
can't be resolved (because the element has been removed) then the structure of
the AST is used to build element matchers for every kind of element that would
be valid to reference in that location.

The transform sets are then asked to find any transforms that apply to an
element that matches any of the element matchers. An instance of `DataDrivenFix`
is created for each transform that is found.

## Implementing a new change

This section describes what's involved in supporting a new kind of change. The
same steps apply to extending an existing change, except that in a few places
where the instructions are to create something new (such as a class or method),
you would instead modify something that already exists.

### Design the change

The first step is to design the changes to the data-file format that will allow
users to specify the change. Follow the design principles outlined in the
Overview in
[Data-driven Fixes](https://github.com/flutter/flutter/wiki/Data-driven-Fixes).

In addition, look at the existing changes to ensure that a new kind of change is
required. It might make more sense to extend an existing change rather than to
write a new change.

### Represent the change

When you have a design, the next step is to create a new subclass of `Change`
that holds all of the data the user can express in the data file.

### Parse the change

When you have a representation of the change, the next step is to update the
parser to recognize the new syntax and to create the change. The parser is
implemented by the class `TransformSetParser`. In particular, you will need to
update `_translateChange` to recognize the new key and invoke a new
`_translateX` method to parse the new syntax and return an instance of the new
subclass of `Change`.

Tests of the parser are in the class `TransformSetParserTest`.

If it is possible for the user to have a syntactically valid change that isn't
semantically valid, then the parser should produce diagnostics. (By
syntactically valid we mean that what was written in the file matches the valid
YAML structure defined for the change.) The diagnostics are just like any other
diagnostic, and are defined in the class `TransformSetErrorCode`.

Most of the diagnostics that you're likely to need are already implemented (and
are easily caught by the parser using some utility methods). This includes
diagnostics reporting that there's an invalid key in the map representing the
change, or that there's a missing key, or that the value isn't of the right
format.

If you need to add more diagnostics you can add a static field to the class
`TransformSetErrorCode` and pass it to `_reportError`. The tests for the
diagnostics are in the directory
`test/src/services/correction/fix/data_driven/diagnostics`.

### Versioning the data file format

We don't currently need to worry about this, but this section contains some
forward pointers that might become important.

Changing the data-file format, even to add a new capability, is a breaking
change. In the past we've safely ignored this because we were only concerned
about supporting Flutter and we controlled which version of Flutter would be
used with which version of the data-driven fix support. As more package authors
start to use this feature we'll need to be more careful. The data-file format
includes a version number to help support this process.

When we do get to the point where we need to version the data file format we'll
need to extend the parser to understand the different supported versions.

### Implement the change

The last step is to implement the change by providing implementations of the
`validate` and `apply` methods. The `validate` method will be invoked first. It
should check the AST to ensure that the change has the information it needs in
order to apply an edit. It should return either an object, if the change can be
applied, or `null` if the change can't be applied at the current location.

The returned object is used to reduce duplication and hence improve performance.
It should contain any data that was checked during validation that will also be
used when applying the change.

The `apply` method will only be invoked if the `validate` method returns a
non-`null` value. The `apply` method is required to add consistent changes to
the change builder (possibly none if there are no required changes). Unlike a
typical fix processor, not modifying the change builder won't cancel the change,
that's accomplished by returning `null` from `validate`.

The tests for individual changes are in the directory
`test/src/services/correction/fix/data_driven`. These tests don't need to test
the parser, but should test any cases that should create edits to the file and
any cases that should fail validation.

During this phase you might discover that either the change needs additional
information or that some of the information you thought you'd need isn't
actually being used. You can iterate on the design at this point.

### Add completion support

After the change is working as intended and you don't anticipate any need to
alter the design, you should add code completion support for the new change.
Code completion support is implemented by extending the producers in
`FixDataGenerator`.

The tests for code completion are in the class `FixDataGeneratorTest`.
