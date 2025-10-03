This package defines control flow graph (CFG) intermediate representation of
Dart programs and optimization passes performed on CFG.

This package is intended to be used only by Dart compiler(s) in the Dart SDK.

Structure of the package:
```
  front_end/  # Translation from kernel AST to CFG.
  ir/         # CFG/SSA IR and computation of its properties.
  passes/     # Optimization passes.
  utils/      # General-purpose utilities.
```

## Status: experimental

**NOTE**: This package is currently experimental and not published or
included in the SDK.

Do not take dependency on this package unless you are prepared for
breaking changes and possibly removal of this code at any point in time.
