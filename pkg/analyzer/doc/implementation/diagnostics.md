# Adding a new diagnostic

This document describes the process of adding a new (non-lint) diagnostic to the
analyzer.

## Define the diagnostic code

The first step is to define the code(s) associated with the diagnostic.

The codes are defined in the file `analyzer/messages.yaml`. There's a comment at
the top of the file describing the structure of the file.

Every diagnostic has at least one code associated with it. A code defines the
problem and correction messages that will be shown to users.

For most diagnostics, a single message (code) is sufficient. But sometimes it's
useful to tailor the message based on the context in which the problem occurs or
because the message can be made more clear. For example, it's an error to
declare two or more constructors with the same name. That's true whether the
name is explicit or implicit (the default constructor). In order for the message
to match the user's model of the language, we define two messages for this one
problem: one that refers to the constructors by their name, and one that refers
to the constructors as "unnamed". The way we define two messages is by defining
two codes.

Each code has a unique name (the key used in the map in `messages.yaml`) and can
optionally define a shared name that links all the codes for a single diagnostic
together. It is the shared name that is displayed to users. If a shared name
isn't explicitly provided, it will default to being the same as the unique name.

After every edit to the `messages.yaml` file, you will need to run the utility
`analyzer/tool/messages/generate.dart` to update the generated files.

You also need to manually add the name of the code to the list of codes in two
files:
- `analyzer/lib/error/error.dart`
- `analysis_server/lib/src/services/correction/error_fix_status.yaml`

In the status file, the code should have the line
```yaml
  status: needsEvaluation
```
nested under the name of the code.

## Write tests

We recommend writing the tests for a diagnostic before writing the code to
generate the diagnostic. Doing so helps you think about the specific cases that
the implementation code needs to handle, which can result in cleaner
implementation code and fewer bugs.

The tests for each diagnostic code (or set of codes that have the same shared
name) are in a separate file in the directory `analyzer/test/src/diagnostics`.
Looking at the implementation of tests in a few of the other files can help you
see the basic pattern, but all the tests essentially work by setting up the code
to be analyzed, then assert that either the expected diagnostic has been
produced in the expected locations or that there are no diagnostics being
generated. (It's often valuable to test that the diagnostic doesn't have any
false positives.)

## Report the diagnostic

The last step is to write the code to report the diagnostic. Where that code
lives depends on the kind of diagnostic you're adding. If you're adding a
diagnostic that's defined by the language specification (with a severity of
'error'), then the best place to implement it will usually be in one of the
`<node class>Resolver` classes. If you're adding a warning, then the class
`BestPracticesVerifier` is usually the best place for it.