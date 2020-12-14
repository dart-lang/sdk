# Front end for Dart

This package provides a low-level API for use by compiler back ends that wish to
implement the Dart language.  It is intended for eventual use by dev_compiler,
dart2js, and the Dart VM.  In addition, it will share implementation details
with the analyzer package--this will be accomplished by having the analyzer
package import (and re-export) parts of this package's private implementation.

End-users should use the [`dart analyze`](https://dart.dev/tools/dart-tool)
command-line tool to analyze their Dart code.

Integrators that want to write tools that analyze Dart code should use the
[analyzer](https://pub.dev/packages/analyzer) package.

_Note:_ A previous version of this package was published on pub.dev. It has now
been marked DISCONTINUED as it is not intended for direct consumption, as per
the notes above.
