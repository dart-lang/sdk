Smoke (and mirrors)
===================

Smoke is a package that exposes a reduced reflective system API. This API
includes accessing objects in a dynamic fashion (read properties, write
properties, and call methods), inspecting types (for example, whether a
method exists), and symbol/string convertion.

The package provides a default implementation of this API that uses the system's
mirrors, but additionally provides mechanisms for statically generating code
that can replace the mirror-based implementation.

The intention of this package is to allow frameworks to use mirrors in a way
that will not impose on their users. The idea is that users will not worry about
how to preserve symbols when compiling with dart2js (for instance, using the
[MirrorsUsed][] annotation). Instead, this package provides the building
blocks to autogenerate whatever is needed for dart2js to be happy and to
generate reasonable code.

Note this package alone doesn't know how to generate everything, but it provides
a simple API that different frameworks can use to define what needs to be
generated.


Smoke reflective API
====================

Use `package:smoke/smoke.dart` in your framework to read and write objects and
to inspect type information. Read the Dart-docs for more details.

Code Generation
===============

TBD. We envision we'll have a base transformer class that can be tailored to
create a transformer for your framework.

[MirrorsUsed]: https://api.dartlang.org/apidocs/channels/stable/#dart-mirrors.MirrorsUsed
