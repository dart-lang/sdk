# Package validation

The packages in `pkg/` are automatically validated on the LUCI CI bots. The
validation is largely done by the `tools/package_deps` package; it can be tested
locally via:

```
dart tools/package_deps/bin/package_deps.dart
```

## Packages which are published

There are several packages developed in `pkg/` which are published to pub.
Validation of these packages is particularly important because the pub tools are
not used for these packages during development; we get our dependency versions
from the DEPS file. Its very easy for the dependencies specified in a package's
pubspec file to get out of date wrt the packages and versions actually used.

In order to better ensure we're publishing correct packages, we validate some
properties of the pubspec files on our CI system. These validations include:

- that the dependencies listed in the pubspec are used in the package
- that all the packages used by the source are listed in the pubspec
- that we don't use relative path deps to pkg/ or third_party/ packages

## Packages which are not published

For packages in pkg/ which we do not intend to be published, we put the
following comment in the pubspec.yaml file:

```
# This package is not intended for consumption on pub.dev. DO NOT publish.
publish_to: none
```

These pubspecs are still validated by the package validation tool. The contents
are more informational as the pubspecs for these packages are not consumed by
the pub tool or ecosystem.

We validate:
- that the dependencies listed in the pubspec are used in the package
- that all the packages used by the source are listed in the pubspec
- that a reference to a pkg/ package is done via a relative path dependency
