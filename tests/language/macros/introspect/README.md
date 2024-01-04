# Macro "Introspect" Tests

These tests (will) cover the "read" half of the macro API, the introspection
of source during macro execution.

The macros under `impl` accept an introspection target library and type name.
They do all the introspection possible, convert the results to primitives then
compare with expectations also passed as an argument to the macro.
