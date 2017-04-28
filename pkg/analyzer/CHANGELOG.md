## 0.30.0-alpha.0
* Changed the API for creating BazelWorkspace.  It should now be constructed using BazelWorkspace.find().  Note that this might return `null` in the event that the given path is not part of a BazelWorkspace.
* Added an AST structure to support asserts in constructor initializers (AssertInitializer).  AstVisitor classes must now implement visitAssertInitializer().
* Changed the API for creating PartOfDirective.  It now accepts a StringLiteral URI, to accommodate "part of" declarations with a URI string rather than a library name.
* Removed AST constructors.  AST nodes should now be created using `astFactory`, located in `package:analyzer/dart/ast/standard_ast_factory.dart`.

## 0.29.0-alpha.0
* Removed `Element.docRange`.

## 0.28.2-alpha.0
* Corresponds with the analyzer/server in the `1.20.0-dev.1.0 ` SDK.

## 0.28.0-alpha.2
* Fixed PubSummaryManager linking when a listed package does not have the unlinked bundle.

## 0.27.4-alpha.19
* Added support for running the dev compiler in the browser.

## 0.27.4-alpha.18
* Support for references to operators in doc comments (#26929).

## 0.27.4-alpha.17
* Support for trailing commas in parameter and argument lists (#26647).
* Strong mode breaking change: can now infer generic type arguments from the constructor invocation arguments (#25220).

## 0.27.4-alpha.16
* (Internal) Corresponds with the analyzer/server in the `1.18.0-dev.4.0` SDK.

## 0.27.4-alpha.9
* Restore EmbedderUriResolver API.

## 0.27.4-alpha.8
* Ignore processing performance improvements.
* EmbedderUriResolver API updates.

## 0.27.4

* Added support for 'analysis_options.yaml' files as an alternative to '.analysis_options' files.

## 0.27.1
* Moved the public and private API's for the element model into their proper places.
* Added back support for auto-processing of plugins.

## 0.27.0
* Support for DEP 37 (Assert with optional message).
* Lexical support for DEP 40 (Interface libraries). This does not include any semantic checking to ensure that the
  implementation libraries are compatible with the interface library.
* Cleaned up the initialization of plugins. Clients are now required to initialize plugins, possibly using the utility
  method AnalysisEngine.processRequiredPlugins().
* Removed the old task model and code that supported it. None of the removed code was intended to be public API, but
  might be in use anyway.
* Removed previously deprecated API's (marked with the @deprecated annotation).

## 0.26.4
* Options processing API updated to accept untyped options maps (#25126).

## 0.26.3
* (Internal) Support for `_embedder.yaml` discovery and processing.

## 0.26.2
* Add code generation utilities for use in both analyzer and analysis server.

## 0.26.1+17
* (Internal) Introduced context configuration logic (`configureContext()` extracted from server).

## 0.26.1+16
* (Internal) Options validation plugin API update.

## 0.26.1+15
* (Internal) Provisional options validation plugin API.

## 0.26.1+13
* (Internal) Plugin processing fixes.

## 0.26.1+11
* Fixes to address lint registry memory leaking.

## 0.26.1+10
* New `AnalysisContext` API for associating configuration data with contexts
  (`setConfigurationData()` and `getConfigurationData()`).

## 0.26.1+9
* `OptionsProcessor` extension point API changed to pass associated
  `AnalysisContext` instance into the `optionsProcessed` call-back.

## 0.26.1+6
* Provisional (internal) plugin manifest parsing.

## 0.26.1+5
* Plugin configuration `ErrorHandler` typedef API fix.

## 0.26.1+4
* Provisional (internal) support for plugin configuration via `.analysis_options`.

## 0.26.1+2

* Extension point for WorkManagerFactory(s).
* Resolve enum documentation comments.
* Fix display of parameter lists in servers Element structure (issue 24194)
* Band-aid fix for issue #24191.

## 0.26.1+1

* Removed a warning about importing unnamed libraries
* Fix handling of empty URIs in `.packages` files (issue 24126)

## 0.26.1

* Fix line starts in multiline comments (issue 23919).
* Various small fixes to Windows path handling.
* Update LineInfo computation during incremental resolution.
* Make exclude list apply to contexts (issue 23941).
* Fix type propagation for asynchronous for-in statements.
* Fix ToStringVisitor for external functions (issue 23968).
* Fix sorting of compilation unit members.
* Add forwarding for DefaultFormalParameter metadata.
* Fix most implementations of UriResolver.restoreAbsolute.
* Disable dart2js hints by default.
* Support older SDKs (Dart 1.11).

## 0.26.0

* Add hook for listening to implicitly analyzed files
* Add a PathFilter and AnalysisOptionsProvider utility classes to aid
  clients in excluding files from analysis when directed to do so by an
  options file.
* API change: `UriResolver.resolveUri(..)` now takes an optional `actualUri`.
* Change `ResolutionCopier.visitAwaitExpression` to copy *Type fields.
* Fix highlight range for missing enum constant in switch (issue 23904).
* Fix analyzer's treatment of `ClassName?.staticMember` to match spec.
* Implement DEP 34 (less restricted mixins).
* Fix some implementations of `UriResolver.resolveUri(..)` that did not
  properly handle the new `actualUri` argument.

## 0.25.2

* Requires Dart SDK 1.12-dev or greater
* Enable null-aware operators (DEP 9) by default.
* Generic method support in the element model.

## 0.25.2-alpha.1

* `dart:sdk` extension `.sdkext` changed to `_sdkext` (to play nicer with pub).

## 0.25.2-alpha.0

* Initial support for analyzing `dart:sdk` extensions from `.sdkext`.

## 0.25.1

* (Internal) code reorganization to address analysis warnings due to SDK reorg.
* First steps towards `.packages` support.

## 0.25.0

* Commandline interface moved to dedicated `analyzer_cli` package. Files moved:
  * `bin/analyzer.dart`
  * `lib/options.dart`
  * `lib/src/analyzer_impl.dart`
  * `lib/src/error_formatter.dart`
* Removed dependency on the `args` package.

## 0.22.1

* Changes in the async/await support.


## 0.22.0

  New API:

* `Source.uri` added.

  Breaking changes:

* `DartSdk.fromEncoding` replaced with `fromFileUri`.
* `Source.resolveRelative` replaced with `resolveRelativeUri`.
