# changelog

This file contains highlights of what changes on each version of the polymer
package. We will also note important changes to the polyfill packages (observe,
web_components, and template_binding) if they impact polymer.

#### Pub version 0.12.0-pre.1.dev
 * Updated to match polymer 0.3.4 ([polymer-dev#6ad2d61][6ad2d61]), this
   includes the following changes:
     * added @ComputedProperty
     * @published can now be written using the readValue/writeValue helper
       methods to match the same timing semantics as Javscript properties.
     * underlying packages are also updated. Noticable changes are that
       path-observers syntax is slightly different. See the `observe` package
       for details.
  * Patched polymer.js to include also a cherry-pick of
    [commit#3b690ad][3b690ad], which fixes CSP.

#### Pub version 0.12.0-dev
 * Polymer Expressions had a breaking change so we also bumped the version on
   this package.
 * Fix for [17596](https://code.google.com/p/dart/issues/detail?id=17596)

#### Pub version 0.11.1-dev
 * Use the latest template_binding with better NodeBind interop support (for
   two-way bindings with JS polymer elements).
 * Fix for [19770](https://code.google.com/p/dart/issues/detail?id=19770)

#### Pub version 0.11.0+5
  * fixes web_components version in dependencies

#### Pub version 0.11.0+4
  * workaround for bug
    [19653](https://code.google.com/p/dart/issues/detail?id=19653)

#### Pub version 0.11.0+3
  * update readme

#### Pub version 0.11.0+2
  * bug fix: event listeners were not in the dirty-checking zone
  * bug fix: dispatch event in auto-binding

#### Pub version 0.11.0+1
  * Added a workaround for bug in HTML imports (issue
    [19650](https://code.google.com/p/dart/issues/detail?id=19650)).

#### Pub version 0.11.0
  * **breaking change**: platform.js and dart_support.js must be specified in
    your entry points at the beginning of `<head>`.
  * **breaking change**: polymer.html is not required in entrypoints, but it is
    required from files that use `<polymer-element>`.
  * **breaking change**: enteredView/leftView were renamed to attached/detached.
    The old lifecycle methods will not be invoked.
  * **breaking change**: Event bindings with `@` are no longer supported.

#### Pub version 0.10.1
  * Reduce the analyzer work by mocking a small subset of the core libraries.

#### Pub version 0.10.0+1
  * Better error message on failures in pub-serve/pub-build when pubspec.yaml
    is missing or has a wrong configuration for the polymer transformers.

#### Pub version 0.10.0
  * Interop with polymer-js elements now works.
  * Polymer polyfills are now consolidated in package:web_components, which is
    identical to platform.js from http://polymer-project.org.
  * The output of pub-build no longer uses mirrors. We replace all uses of
    mirrors with code generation.
  * **breaking change**: Declaring a polymer app requires an extra import to
    `<link rel="import" href="packages/polymer/polymer.html">`
  * **breaking change**: "noscript" polymer-elements are created by polymer.js,
    and therefore cannot be extended (subtyped) in Dart. They can still be used
    by Dart elements or applications, however.
  * New feature: `@ObserveProperty('foo bar.baz') myMethod() {...}` will cause
    myMethod to be called when "foo" or "bar.baz" changes.
  * Updated for 0.10.0-dev package:observe and package:template_binding changes.
  * **breaking change**: @initMethod and @CustomTag are only supported on
    public classes/methods.

#### Pub version 0.9.5
  * Improvements on how to handle cross-package HTML imports.

#### Pub version 0.9.4
  * Removes unused dependency on csslib.

#### Pub version 0.9.3+3
  * Removes workaround now that mirrors implement a missing feature. Requires
    SDK >= 1.1.0-dev.5.0.

#### Pub version 0.9.3+2
  * Fix rare canonicalization bug
    [15694](https://code.google.com/p/dart/issues/detail?id=15694)

#### Pub version 0.9.3+1
  * Fix type error in runner.dart
    [15649](https://code.google.com/p/dart/issues/detail?id=15649).

#### Pub version 0.9.3
  * pub-build now runs the linter automatically

#### Pub version 0.9.2+4
  * fix linter on SVG and MathML tags with XML namespaces

#### Pub version 0.9.2+3
  * fix [15574](https://code.google.com/p/dart/issues/detail?id=15574),
    event bindings in dart2js, by working around issue
    [15573](https://code.google.com/p/dart/issues/detail?id=15573)

#### Pub version 0.9.2+2
  * fix enteredView in dart2js, by using custom_element >= 0.9.1+1

[6ad2d61]:https://github.com/Polymer/polymer-dev/commit/6a3e1b0e2a0bbe546f6896b3f4f064950d7aee8f
[3b690ad]:https://github.com/Polymer/polymer-dev/commit/3b690ad0d995a7ea339ed601075de2f84d92bafd
