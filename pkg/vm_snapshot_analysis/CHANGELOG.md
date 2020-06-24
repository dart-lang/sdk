# Changelog

## 0.2.0

- Update CLI help message to avoid referring to a snapshot created by pub as the
name of the script.
- Fix owner computation code for V8 profiles: the size of a snapshot node
which corresponds to a `ProgramInfoNode` should be attributed to that
`ProgramInfoNode` and not to its parent. For example `Function` node corresponds
to `ProgramInfoNode` of type `functionNode`, previously the size of `Function`
node would be attributed to the parent of this `ProgramInfoNode`, but it
should be attributed to the node itself.
- Update `README.md` to include more information on how to pass flags to
Dart AOT compiler.
- Add `ProgramInfoNode.size` documentation to clarify the meaning of the member.

## 0.1.0

- Initial release
