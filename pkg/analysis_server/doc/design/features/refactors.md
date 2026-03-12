# Refactors

    LSP:    [textDocument_codeActions][] request
    Legacy: `edit.getAssists`, `edit.getAvailableRefactorings`, `edit.getFixes`,
            and `edit.getRefactoring` requests

Refactors are actions that users can select that make changes to their code.

## Kinds

While users tend to think of all refactors as essentially being the same,
internally we divide them into three kinds. This is in part due to
implementation considerations, but more importantly because there are
implications in terms of the UX.

The kinds are based on two characteristics of the refactor:

<dl>
  <dt>scope</dt>
  <dd>
  A local refactor is limited to making changes within the library in which the
  refactor is invoked. A global refactor can make changes in any of the
  libraries that are in the IDE's workspace.
  </dd>
  <dt>availability</dt>
  <dd>
  Some refactors are only available when there is a diagnostic indicating a
  problem. Others are available whenever the editor's selection is on the
  appropriate tokens.
  </dd>
</dl>

The three kinds are described below.

### Fixes

Fixes are code changes that are designed to resolve a problem in the code that
is indicated by a diagnostic. The changes are always local in scope.

Fixes can be initiated to
- fix a single diagnostic at a single location
- fix all of the locations of a single diagnostic in a single file
- fix all of the locations of all diagnostics (via `dart fix` and in LSP-based
  IDEs)

### Assists

Assists are code changes that are available even when there is no diagnostic.
The changes are always local in scope.

Assists can only be initiated at a single location.

### Global Refactors

Global refactors are code changes that might involve changes to multiple
libraries and possibly across multiple packages, when those packages are all
open in the IDE's workspace.

Global refactors can only be initiated at a single location.

Note that in many contexts (such as the issue tracker) we use the term
'refactor' to sometimes mean any kind of refactor and sometimes to mean a global
refactor. In this document we'll use the longer name for clarity.

## Preserving semantics

There is no rule against refactors that change the semantics of the code. Some
refactors are only useful _because_ they change the semantics. It could be
argued that most of the fixes are semantics changing: taking the code from being
broken to being compilable. This section discusses the criteria we use to decide
when it's appropriate for a refactor to be semantic preserving and when it's
reasonable for it to change the semantics.

### User expectations

One question that should be asked is how likely it is that a user would
reasonably expect the semantics to be preserved. For example, it's reasonable
for a user to assume that a refactor that converts a switch statement into a
switch expression would preserve the semantics of the switch. On the other hand,
it's reasonable for a user to expect that a refactor that changes a method to be
marked as `async` and changes the return type to be a `Future` would change the
semantics of the code by doing so.

### Subtle vs. obvious changes

If a refactor is going to change the semantics of the code then it ought to be
obvious to the user that the semantics have changed. The more subtle the change
to the semantics, the less appropriate it is for the semantics to change. For
example, the assist that converts a method to be marked as `async` changes the
semantics, but the change is easy to see because the return type is changed and
a new keyword is added. On the other hand, a change that impacts the lookup
scope in such a way that some identifiers are resolved to different targets
without any indication that this is the case is probably too subtle.

If a fix is being applied at a single location, then the semantic changes will
generally be more obvious. If a fix is being applied across a large code base,
then the semantic changes might easily not be noticed because the affected files
might not be open.

## Producing broken code

There are few, if any, valid reasons for a refactor to produce code that doesn't
compile. Some refactors will work on code that is already broken, in which case
it's reasonable for the result to also be broken, as long as it isn't broken
worse. But it usually isn't reasonable for a refactor to introduce new
diagnostics into the code.

[textDocument_codeActions]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeActions
