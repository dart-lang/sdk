# Code Editing Features

This document discusses some design and implementation considerations that are
common to the code editing features of the analysis server. Internally we
distinguish between three kinds of code editing features:

- a [quick fix](quick_fix.md) is a code edit that is associated with a
  diagnostic. They are only available when an associated diagnostic has been
  produced. They are required to be local in scope.

- a [quick assist](quick_assist.md) is a code edit that is both local in scope
  and doesn't require any user input. They are available when the selection is
  within the assist's [available range](#choosing-an-available-range).

- a [refactoring]() is a code edit that is either non-local in scope or that
  requires user input. They are available when the selection is within the
  assist's [available range](#choosing-an-available-range).

## Scope

An edit is local in scope if the implementation of the edit only needs
information from the local library (the library in which it is invoked) and will
only make changes to the local library.

For example, an edit to convert a `for`-each loop to a normal `for` loop can't
require changes outside the function containing the loop, and is hence local in
scope. An edit to change the nullability of a function parameter's type requires
updating all the call sites, some of which might be outside the library in which
the function is declared, making it non-local in scope.

## Choosing an available range

Every code edit is available within some range of text. In order to have a more
consistent UX, we have some guidelines that we use to help decide what that
range of text should be.

For a quick fix, the range is anywhere on any lines containing the highlight
range of the diagnostic being fixed. This is done by the framework, so no effort
is required on the part of a fix author.

For quick assists and refactorings, the selection range is passed to the code
computing the edit and is used to determine whether the edit is offered. Hence,
there's a bit more effort required from the author of the edit. Below are the
conventions we've adopted.

- Edits that effect a whole declaration (converting from one kind to another,
  moving the declaration to another location, etc.) should be offered if the
  selection is contained within the name of the declaration.

## Creating the edits

In all three cases, a `ChangeBuilder` will be passed to the method that creates
the code edit. You should familiarize yourself with
[how to use `ChangeBuilders`](../../../analyzer_plugin/doc/tutorial/creating_edits.md).