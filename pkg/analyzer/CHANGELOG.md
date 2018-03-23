## 0.31.2-alpha.1

* Don't expect type arguments for class type parameters of static methods.
  (#32396)
* Beginnings of changes to make analyzer code --preview-dart-2 safe, though
  this version is not vetted for that.
* Infer type arguments in constructor redirections (#30855)
* Report errors on "as void" and "is void".
* Fix instantiating typedefs to bounds (#32114)
* preview-dart-2 implies strong-mode now and other preview-dart-2 fixes.
* Store method invocation arguments in summaries when needed for inference (partial fix for #32394)
* Fix top-level inference and implicit creation (#32397)
* Do not hint when only a responsive asset exists (#32250)
* Do not hint when using a deprecated parameter in the defining function
  (#32468)
* Fix parsing of super expressions (#32393)
* Disable conflicting generics test in the task model (#32421)
* Change how we find analysis roots (#31343, #31344)
* Fix problem with AST re-writing interacting poorly with inference (#32342)
* Disallow if a class inconsistently implements a generic interface.
* Infer void for operator[]= return in task mode for DDC (#32241)
* Finish and improve mixin type inference in the analyzer (#32146, #32353, #32372)
* Many enhancements to getElementDeclarations() (#29510, #32495)
* Remove hint when there's no return from a Future<void> and async method.
* Add a code range to ElementDeclaration (#29510)
* Many, many fasta parser changes and improvements.
* Add missing void annotation (#32161)
* Add more null-aware hints (#32239)
* Fix implicit new/const computation (#32221)
* Treat invocations on dynamic as unknown, except for return type of == (#32173)
* Fix crash in generic function type argument of unresolved class (#32162)
* Fix path formatting on windows (#32095)
* front_end implementation of mixin type inference (#31984)
* analysis_options no longer breaks some properties (#31345)

## 0.31.2-alpha.0

* front_end handling of callable classes (#32064)
* Improve fasta parser error reporting.
* Check for unresolved imports to improve handling of optional new/const (#32150).
* Changes to front_end handling of callable classes.
* Normalize Windows drive letters to uppercase for analysis (#32095, #32042, #28895).
* Relax void errors: no error assigning void to void variable.
* Keep unresolved import/export directives for task based analysis
  (dart-lang/angular#801).
* Promote `TOP_LEVEL_CYCLE` to an error.
* Code cleanups.

## 0.31.1

* Update to reflect that `_InternalLinkedHashMap` is not a subtype of `HashMap`
  in sdk 2.0.0-dev.22.0.

## 0.31.0+1

* Update SDK constraint to require Dart v2-dev release.

## 0.31.0

* **NOTE** This release was pulled from the package site due to an invalid SDK
  constraint that was fixed in `0.31.0+1`.

* A number of updates, including support for the new Function syntax.

## 0.30.0-alpha.0
* Changed the API for creating BazelWorkspace.  It should now be constructed using BazelWorkspace.find().  Note that this might return `null` in the event that the given path is not part of a BazelWorkspace.
* Added an AST structure to support asserts in constructor initializers (AssertInitializer).  AstVisitor classes must now implement visitAssertInitializer().
* Changed the API for creating PartOfDirective.  It now accepts a StringLiteral URI, to accommodate "part of" declarations with a URI string rather than a library name.
* Removed AST constructors.  AST nodes should now be created using `astFactory`, located in `package:analyzer/dart/ast/standard_ast_factory.dart`.

## 0.29.0-alpha.0
* Removed `Element.docRange`.

## 0.28.2-alpha.0
* Corresponds with the analyzer/server in the `1.20.0-dev.1.0` SDK.

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
