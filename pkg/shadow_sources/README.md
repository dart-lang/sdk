This package contains a source transformer that shadows unexposed host
dependencies for Dart Dynamic Modules (DDM).

When a dynamic module depends on packages present in the host application but
not exposed in `dynamic_interface.yaml`, this tool rewrites directives and
produces shadowed sources in an overlay directory so they can be compiled into
the module without failing dynamic module interface validation.

## Status: experimental

**NOTE**: This package is currently experimental and not published or included
in the SDK.

Do not take a dependency on this package unless you are prepared for breaking
changes and possible removal of this code at any point in time.

## Library-level shadowing

Shadowing operates strictly at the library/file level:

-   If a library is partially exposed in `dynamic_interface.yaml` (e.g. exposing
    only a specific class via `class: 'Bar'` in `package:foo/bar.dart`), the
    entire library is considered exposed and is not shadowed.
-   Consequently, unexposed elements in that library (such as a sibling `class
    Baz`) cannot be used by the dynamic module, as they are neither exposed by
    the host outline nor copied into the shadowed sources overlay.
