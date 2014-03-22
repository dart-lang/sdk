# changelog

This file contains highlights of what changes on each version of the
polymer_expressions package.

#### Pub version 0.10.0-dev
  * package:polymer_expressions no longer declares @MirrosUsed. The package uses
    mirrors at development time, but assumes frameworks like polymer will
    generate code that replaces the use of mirrors. If you use this directly,
    you might need to do code generation as well, or add the @MirrorsUsed
    declaration. This can be done either explicitly or by importing the old
    settings from 'package:observe/mirrors_used.dart' (which include
    @reflectable and @observable by default).

  * Errors that occur within bindings are now thrown asycnhronously. We used to
    trap some errors and report them in a Logger, and we would let other errors
    halt the rendering process. Now all errors are caught, but they are reported
    asynchornously so they are visible even when logging is not set up.
