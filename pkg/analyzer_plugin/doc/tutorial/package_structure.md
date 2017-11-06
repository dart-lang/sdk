# Package Structure

Plugins are used by tools that want to allow external contributions to the
results being produced by that tool. At the moment, the analysis server is the
only tool that supports plugins, but we intend to add plugin support to the
command-line analyzer and possibly other tools as well. For that reason,
throughout this document we will generically refer to the tool running the
plugins as simply the _tool_.

In order to describe the way tools use plugins, we need to refer to four
different packages. In order to keep the discussion clear, we will refer to
those packages as the target package, the host package, the bootstrap package,
and the plugin package. (If you're not familiar will packages, you should read
about the Dart [package manager][pub].)

The _target package_ is the package for which the tool is producing analysis
results. If the tool is the analysis server, this is a package that the user has
opened in the client and is actively developing.

The _host package_ is a package that contains the information necessary to find
and run the plugin. Specifically, the host package contains the bootstrap
package. In order for the tool to find and use the host package, the target
package must have a dependency on the host package. This can be either a normal
dependency or a dev dependency.

The _bootstrap package_ is a small package embedded within the host package that
is used to load the plugin package.

The _plugin package_ is the package that contains the actual implementation of
the plugin.

While you could technically merge the bootstrap and plugin packages, we
recommend this structure because it minimizes the number of additional files
that need to be downloaded by users who do not choose to enable the hosted
plugin.

As a concrete example, the angular package has a plugin associated with it. In
order to implement this, the angular package has a bootstrap package embedded
within it. When a target package (a package implementing a web app) has a
dependency on the angular package, it can list 'angular' as an approved host
package and the angular plugin will be run.

## Plugin Discovery

Plugins are used by a tool to analyze the target package only if the tool is
explicitly told to run them. Tools look for a list of approved host packages in
the analysis options file (`analysis_options.yaml`) associated with the target
package. The list has the form:

```yaml
analyzer:
  plugins:
    - host_package_1
    - host_package_2
```

If a listed host package can be found (via the `.packages` file associated with
the target package), then the tool looks in the host package for the folder
`<host_package>/tools/analysis_plugin`. If that directory exists and contains a
valid bootstrap package, then the bootstrap package is run as a plugin.

## Bootstrap Package Structure

The other packages described above can have any valid package structure, but the
bootstrap package is required to have two specific files.

First, it must have a file named `tools/analyzer_plugin/pubspec.yaml` that can
be used by the [`pub`][pub] command to produce a `.packages` file describing how
to resolve the `package:` URIs found in it. Typically, the only dependency that
needs to be included is a dependency on the plugin package.

Second, it must have a file named `tools/analyzer_plugin/bin/plugin.dart` that
contains the entry point for the plugin. Every plugin will be run in a separate
isolate. As a result, the entry point must have the following signature:

```dart
void main(List<String> args, SendPort sendPort) {
  // Invoke the real main method in the plugin package. 
}
```

The body of `main` should typically be a single line that invokes a method or
function within the plugin package that will create and start the plugin.

## Plugin Execution

When a bootstrap package is to be run, the contents of the directory containing
the bootstrap package are copied to a temporary directory, the [`pub`][pub]
command is run in that directory to produce a `.packages` file for the bootstrap
package, and the file `tools/analysis_plugin/bin/plugin.dart` is run in its own
isolate.

[pub]:https://www.dartlang.org/tools/pub/get-started
