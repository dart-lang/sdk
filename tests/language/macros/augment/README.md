# Macro "Augment" Tests

These tests (will) cover the "write" half of the macro API, the augmentation of
code of every supported type in every supported place.

See: `package:_fe_analyzer_shared/lib/src/macros/api/macros.dart`

For every macro interface, a file `impl/<macro_interface_name>.dart` defines
one macro for each augmentation method on that macro interface's builder type.
Arguments to the macro match that builder method, and are passed through.

For example, for `ClassDeclarationsMacro#declareInType`, the macro
`ClassDeclarationsDeclareInType` is defined in
`impl/class_declarations_macro.dart`.

`Identifier` arguments are passed as `String`, and will be resolved in the
current library. `Code` arguments are also passed as `String`, in these strings
Identifiers to resolve must be enclosed in backticks. They will be resolved in
`dart:core` so that you can refer to, for example, `int`.

The tests are likewise named by the macro interface they test, for example
`class_declarations_macro_test.dart`.
