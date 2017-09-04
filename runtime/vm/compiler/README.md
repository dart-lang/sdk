# Dart VM Compilation Pipeline

This folder contains Dart VM compilation pipeline.

Compilation pipeline is mainly responsible for converting AST or Kernel AST
into IL flow graphs and then generating native code from IL.

It has the following structure:

| Directory     | What goes there                                             |
| ------------- |-------------------------------------------------------------|
| `assembler/`  | Assemblers and disassemblers                                |
| `backend/`    | IL based compilation backend: optimization passes and architecture specific code generation rules |
| `frontend/`   | Frontends responsible for converting AST into IL            |
| `jit/`        | JIT specific passes and compilation pipeline entry points   |
| `aot/`        | AOT specific passes and compilation pipeline entry points   |
| `.`           | Shared code or code without clear designation.              |

Currently there are no layering restrictions and components from different subfolders can reference each other.
