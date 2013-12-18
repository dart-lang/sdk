# changelog

This file contains highlights of what changes on each version of the polymer
package. We will also note important changes to the polyfill packages if they
impact polymer: custom_element, html_import, observe, shadow_dom,
and template_binding.

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
