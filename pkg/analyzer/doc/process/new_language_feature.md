# Implementing a new language feature

When a new language feature is approved, a tracking issue will be created in
order to track the work required in the `analyzer` package. Separate issues are
created to track the work in the `analysis_server`, `dartdoc`, and `linter`
packages.

Below is a template for the list of analyzer features that need to be reviewed
to see whether they need to be enhanced in order to work correctly with the new
feature. In almost all cases new tests will need to be written to ensure that
the feature isn't broken when run over code that uses the new language feature.
In some cases, new support will need to be added.

## Add an experiment flag

New language features are always implemented behind an experiment flag.

If the experiment flag hasn't already been created, add it.

In the analyzer packages we almost always immediately enable the experiment flag
for all of our tests. This allows us to ensure that existing functionality isn't
broken by the implementation of the new feature. The exception to this rule is
when there's a language feature that is breaking enough in semantics that the
meaning of existing tests would change as a result, in which case we usually
have to take a different approach (not described here).

The list of enabled features is maintained in the file
`pkg/analyzer_utilities/lib/test/experiments/experiments.dart`.

## Template

The following is a list of the individual features that need to be considered.
The features are listed roughly in dependency order.

- [ ] If needed, add an experiment flag
- [ ] AST enhancements (`AstBuilder`)
- [ ] Resolution of directives
- [ ] Element model
- [ ] Type system updates
- [ ] Summary support
- [ ] Resolution
  - [ ] `ResolutionVisitor` (resolve types)
  - [ ] `ScopeResolverVisitor` (resolve simple identifiers by scope)
  - [ ] `ResolverVisitor` (type-based resolution)
- [ ] Constant evaluation
- [ ] Index and search
- [ ] Warnings (annotation-based, unused\*, strict-mode-based, a few others)
  - [ ] `OverrideVerifier` and `InheritanceOverrideVerifier` (report errors and warnings related to overrides)
  - [ ] `ErrorVerifier` (report other errors and warnings)
  - [ ] `FfiVerifier` (report errors and warnings related to FFI)
  - [ ] Unused elements warnings
- [ ] ExitDetector
- [ ] NodeLintRegistry
