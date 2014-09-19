#### 0.14.3-dev
  * Don't start moving elements from head to body until we find the first
    import, [20826](http://dartbug.com/20826).
  * Add option to not inject platform.js in the build output
    [20865](http://dartbug.com/20865). To use, set `inject_platform_js` to
    false in the polymer transformer config section of your pubspec.yaml:

        transformers:
        - polymer:
            inject_platform_js: false
            ...

#### 0.14.2+1
  * Fix findController function for js or dart wrapped elements. This fixes
    event bindings when using paper-dialog and probably some other cases,
    [20931](http://dartbug.com/20931).

#### 0.14.2
  * Polymer will now create helpful index pages in all folders containing entry
    points and in their parent folders, in debug mode only
    [20963](http://dartbug.com/20963).

#### 0.14.1
  * The build.dart file no longer requires a list of entry points, and you can
    replace the entire file with `export 'package:polymer/default_build.dart';`
    [20396](http://dartbug.com/20396).
  * Inlined imports from the head of the document now get inserted inside a
    hidden div, similar to the js vulcanizer [20943](http://dartbug.com/20943).

#### 0.14.0+1
  * Small style improvements on error/warnings page.

#### 0.14.0
  * Upgraded to polymer 0.4.0 ([polymer-dev#d66a86e][d66a86e]).
  * The platform.js script is no longer required in Chrome or Dartium
    (version 36). You can now remove this from your projects for development,
    and it will be injected when running pub build or pub serve. If you would
    like the option to not inject platform.js at all in the built output (if you
    are deploying to chrome exclusively), please star this bug
    http://dartbug.com/20865.
  * Fixed invalid linter warning when using event handlers inside an
    `auto-binding-dart` template, [20913](http://dartbug.com/20913).

#### 0.13.1
  * Upgraded error messages to have a unique and stable identifier. This
    requires a version of `code_transformers` newer than `0.2.3`.
  * Upgraded minimum version constraint on `args` to `0.11.0`.

#### 0.13.0+3
  * Added a warning about flashes of unstyled content if we can detect a
    situation that would cause it [20751](http://dartbug.com/20751).

#### 0.13.0+2
  * Update internal transformers to delete .concat.js and .map files when in
    release mode, saving about 1MB of space in the built output.

#### 0.13.0+1
  * Bug fix for http://dartbug.com/18171. Elements that extend other elements
    but don't have a template will still inherit styles from those elements.
  * Bug fix for http://dartbug.com/20544. Better runtime logging when attributes
    are defined on an element but have no corresponding property on the class.

#### 0.13.0
  * Update to match polymer 0.3.5 ([polymer-dev#5d00e4b][5d00e4b]). There was a
    breaking change in the web_components package where selecting non-rendered 
    elements doesn't work, but it shouldn't affect most people. See 
    https://github.com/Polymer/ShadowDOM/issues/495.

#### 0.12.2+1
  * Small bug fix for `polymer:new_element`

#### 0.12.2
  * Fix for [20539](http://dartbug.com/20539). Log widget will now html escape
    messages.
  * Fix for [20538](http://dartbug.com/20538). Log widget will now surface lint
    logs from imported files.
  * Backward compatible change to prepare for upcoming change of the user agent
    in Dartium.
  * `pub run polymer:new_element` now supports specifying a base class.
    **Note**: only native DOM types and custom elements written in Dart can be
    extended. Elements adapted from Javascript (like core- and paper- elements)
    cannot be extended.
  * other bug fixes in `polymer:new_entry`.

#### 0.12.1
  * **New**: When running in pub-serve, any warnings and errors detected by the
    polymer transformers will be displayed in the lower-right corner of your
    entrypoint page. You can opt-out by adding this option to your pubspec:

        transformers:
        - polymer:
            ...
            inject_build_logs_in_output: false

  * **New**: there are now two template generators in the polymer package! On
    any project that depends on polymer, you can create template files for a new
    custom element by invoking:

        pub run polymer:new_element element-name [-o output_dir]

    And, if you invoke:

        pub run polymer:new_entry web/index.html

    we will create a new entry-point file and add it to your pubspec for you.

  * Added the ability to override the stylesheet inlining behavior. There is now
    an option exposed in the pubspec.yaml called `inline_stylesheets`. There are
    two possible values, a boolean or a map. If only a boolean is supplied then
    that will set the global default behavior. If a map is supplied, then the
    keys should be file paths, and the value is a boolean. You can use the
    special key 'default' to set the default value.

    For example, the following would change the default to not inline any
    styles, except for the foo.css file in your web folder and the bar.css file
    under the foo packages lib directory:

        transformers:
        - polymer:
            ...
            inline_stylesheets:
                default: false
                web/foo.css: true
                packages/foo/bar.css: true

    
  * Bug fix for http://dartbug.com/20286. Bindings in url attributes will no
    longer throw an error.


#### 0.12.0+7
  * Widen the constraint on `unittest`.

#### 0.12.0+6
  * Widen the constraint on analyzer.
  * Support for `_src` and similar attributes in polymer transformers.

#### 0.12.0+5
  * Raise the lower bound on the source_maps constraint to exclude incompatible
    versions.

#### 0.12.0+4
  * Widen the constraint on source_maps.

#### 0.12.0+3
  * Fix a final use of `getLocationMessage`.

#### 0.12.0+2
  * Widen the constraint on barback.

#### 0.12.0+1
  * Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan`
    class.

#### 0.12.0
 * Updated to match polymer 0.3.4 ([polymer-dev#6ad2d61][6ad2d61]), this
   includes the following changes:
     * added @ComputedProperty
     * @published can now be written using the readValue/writeValue helper
       methods to match the same timing semantics as Javscript properties.
     * underlying packages are also updated. Some noticeable changes are:
       * observe: path-observers syntax is slightly different
       * polymer_expressions: updating the value of an expression will issue a
         notification.
       * template_binding: better NodeBind interop support (for
         two-way bindings with JS polymer elements).
 * Several fixes for CSP, including a cherry-pick from polymer.js
   [commit#3b690ad][3b690ad].
 * Fix for [17596](https://code.google.com/p/dart/issues/detail?id=17596)
 * Fix for [19770](https://code.google.com/p/dart/issues/detail?id=19770)

#### 0.11.0+5
  * fixes web_components version in dependencies

#### 0.11.0+4
  * workaround for bug
    [19653](https://code.google.com/p/dart/issues/detail?id=19653)

#### 0.11.0+3
  * update readme

#### 0.11.0+2
  * bug fix: event listeners were not in the dirty-checking zone
  * bug fix: dispatch event in auto-binding

#### 0.11.0+1
  * Added a workaround for bug in HTML imports (issue
    [19650](https://code.google.com/p/dart/issues/detail?id=19650)).

#### 0.11.0
  * **breaking change**: platform.js and dart_support.js must be specified in
    your entry points at the beginning of `<head>`.
  * **breaking change**: polymer.html is not required in entrypoints, but it is
    required from files that use `<polymer-element>`.
  * **breaking change**: enteredView/leftView were renamed to attached/detached.
    The old lifecycle methods will not be invoked.
  * **breaking change**: Event bindings with `@` are no longer supported.
  * **breaking change**: `@published` by default is no longer reflected as an
    attribute by default. This might break if you try to use the attribute in
    places like CSS selectors. To make it reflected back to an attribute use
    `@PublishedProperty(reflect: true)`.

#### 0.10.1
  * Reduce the analyzer work by mocking a small subset of the core libraries.

#### 0.10.0+1
  * Better error message on failures in pub-serve/pub-build when pubspec.yaml
    is missing or has a wrong configuration for the polymer transformers.

#### 0.10.0
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

#### 0.9.5
  * Improvements on how to handle cross-package HTML imports.

#### 0.9.4
  * Removes unused dependency on csslib.

#### 0.9.3+3
  * Removes workaround now that mirrors implement a missing feature. Requires
    SDK >= 1.1.0-dev.5.0.

#### 0.9.3+2
  * Fix rare canonicalization bug
    [15694](https://code.google.com/p/dart/issues/detail?id=15694)

#### 0.9.3+1
  * Fix type error in runner.dart
    [15649](https://code.google.com/p/dart/issues/detail?id=15649).

#### 0.9.3
  * pub-build now runs the linter automatically

#### 0.9.2+4
  * fix linter on SVG and MathML tags with XML namespaces

#### 0.9.2+3
  * fix [15574](https://code.google.com/p/dart/issues/detail?id=15574),
    event bindings in dart2js, by working around issue
    [15573](https://code.google.com/p/dart/issues/detail?id=15573)

#### 0.9.2+2
  * fix enteredView in dart2js, by using custom_element >= 0.9.1+1

[6ad2d61]:https://github.com/Polymer/polymer-dev/commit/6a3e1b0e2a0bbe546f6896b3f4f064950d7aee8f
[3b690ad]:https://github.com/Polymer/polymer-dev/commit/3b690ad0d995a7ea339ed601075de2f84d92bafd
