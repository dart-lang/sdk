# changelog

This file contains highlights of what changes on each version of the polymer
package. We will also note important changes to the polyfill packages if they
impact polymer: custom_element, html_import, observe, shadow_dom,
and template_binding.

#### Pub version 0.10.0-dev
  * Polymer polyfills are now consolidated in package:web_components, which is
    identical to platform.js from http://polymer-project.org. This enables
    interop with elements built in polymer.js.
  * New feature: `@ObserveProperty('foo bar.baz') myMethod() {...}` will cause
    myMethod to be called when "foo" or "bar.baz" changes.
  * Updated for 0.10.0-dev package:observe and package:template_binding changes.
  * Deploy step removes use of mirrors to initialize polymer elements. Mirrors
    are still used for @published and for polymer-expressions.
    **breaking change**: @initMethod and @CustomTag are only supported on
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
