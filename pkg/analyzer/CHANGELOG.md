## 0.38.5-dev
* Added the interface `PromotableElement`, which representing
  variables that can be type promoted (local variables and parameters,
  but not fields).

## 0.38.4
* Bug fixes: #33300, #38484, #38505.

## 0.38.3
* Deprecated the following codes from `StaticWarningCode`.  Please use the
  corresponding error codes from `CompileTimeErrorCode` instead:
  * `EXTRA_POSITIONAL_ARGUMENTS`
  * `EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED`
  * `IMPORT_OF_NON_LIBRARY`
  * `NOT_ENOUGH_REQUIRED_ARGUMENTS`
  * `REDIRECT_TO_MISSING_CONSTRUCTOR`
  * `REDIRECT_TO_NON_CLASS`
  * `UNDEFINED_CLASS`
  * `UNDEFINED_NAMED_PARAMETER`
* Bug fixes: #33749, #35985, #37708, #37857, #37858, #37859, #37945, #38022,
  #38057, #38071, #38091, #38095, #38105, #38113, #38198, #38202, #38203,
  #38261, #38282, #38365, #38417, #38448, #38449.

## 0.38.2
* The type of `FunctionTypeAlias.declaredElement` has been refined to
  `FunctionTypeAliasElement`.  Since the new type is a refinement of
  the old one, the only effect on clients should be to make certain
  casts unnecessary.
* Deprecated `HintCode.INVALID_REQUIRED_PARAM` and replaced it with more
  specific hints, `HintCode.INVALID_REQUIRED_NAMED_PARAM`,
  `HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM`, and
  `HintCode.INVALID_REQUIRED_POSITIONAL_PARAM` to address #36966.
* Deprecated `CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS`.  It
  has been renamed to
  `CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS`.

## 0.38.1
* LinterVistor support for extension method AST nodes.

## 0.38.0
* The deprecated method `AstFactory.compilationUnit2` has been removed.  Clients
  should switch back to `AstFactory.compilationUnit`.
* Removed the deprecated constructor `ParsedLibraryResultImpl.tmp` and the
  deprecated method `ResolvedLibraryResultImpl.tmp`.  Please use
  `AnalysisSession.getParsedLibraryByElement` and
  `AnalysisSession.getResolvedLibraryByElement` instead.
* Removed `MethodElement.getReifiedType`.
* The return type of `ClassMemberElement.enclosingElement` was changed from
  `ClassElement` to `Element`.

## 0.37.1+1
* Reverted an unintentional breaking API change (the return type of
  `ClassMemberElement.enclosingElement` was changed from `ClassElement` to
  `Element`).  This change will be postponed until 0.38.0.

## 0.37.1
* Added the getters `isDartCoreList`, `isDartCoreMap`, `isDartCoreNum`,
  `isDartCoreSet`, `isDartCoreSymbol`, and `isDartCoreObject` to `DartType`.
* Added the method `DartObject.toFunctionValue`.
* Deprecated the `isEquivalentTo(DartType)` method of `DartType`.
  The operator `==` now correctly considers two types equal if and
  only if they represent the same type as defined by the spec.
* Deprecated the `isMoreSpecificThan(DartType)` method of `DartType`.
  Deprecated the `isMoreSpecificThan(DartType)` method of `TypeSystem`.
  Deprecated the `isSupertypeOf(DartType)` method of `TypeSystem`.
  Use `TypeSystem.isSubtypeOf(DartType)` instead.
* Deprecated methods `flattenFutures`, `isAssignableTo` of `DartType`.
  Use `TypeSystem.flatten()` and `TypeSystem.isAssignableTo` instead.
* Deprecated InheritanceManager2, and replaced with InheritanceManager3.
  InheritanceManager3 returns ExecutableElements, not FunctionType(s).
* Added the optional parameter `path` to `parseString`.
* Changed `TypeSystem.resolveToBound(DartType)` implementation to do
  what its documentation says.
* This version of the analyzer should contain all the necessary parsing support
  and AST data structures for the experimental "extension-methods" feature.
  Further element model improvements needed to support extension methods will be
  published in 0.38.x.
* Deprecated `InterfaceType.isDirectSupertypeOf`.  There is no replacement; this
  method was not intended to be used outside of the analyzer.

## 0.37.0
* Removed deprecated getter `DartType.isUndefined`.
* Removed deprecated class `SdkLibrariesReader`.
* Removed deprecated method `InstanceCreationExpressionImpl.canBeConst`.
* The `AstFactory.compilationUnit` method now uses named parameters.  Clients
  that prepared for this change by switching to `AstFactory.compilationUnit2`
  should now switch back to `AstFactory.compilationUnit`.
* Removed `AstNode.getAncestor`.  Please use `AstNode.thisOrAncestorMatching` or
  `AstNode.thisOrAncestorOfType`.
* Removed deprecated getter `TypeSystem.isStrong`, and its override
  `Dart2TypeSystem.isStrong`.
* Removed the deprecated getter `AnalysisError.isStaticOnly` and the deprecated
  setters `AnalysisError.isStaticOnly` and `AnalysisError.offset`.
* Removed the `abstract` setter in `ClassElementImpl`, `EnumElementImpl`,
  `MethodElementImpl`, and `PropertyAccessorElementImpl`.  `isAbstract` should
  be used instead.
* Removed methods `AstVisitor.ForStatement2`, `ListLiteral.elements2`,
  `SetOrMapLiteral.elements2`, `AstFactory.forStatement2`, and
  `NodeLintRegistry.addForStatement2`, as well as class `ForStatement2`.  Use
  the variants with out the "2" suffix instead.
* Changed the signature and behavior of `parseFile` to match `parseFile2`.
  Clients that switched to using `parseFile2` when `parseFile` was deprecated
  should now switch back to `parseFile`.
* Removed Parser setters `enableControlFlowCollections`, `enableNonNullable`,
  `enableSpreadCollections`, and `enableTripleShift`, and the method
  `configureFeatures`.  Made the `featureSet` parameter of the Parser
  constructor a required parameter.

## 0.36.4
* Deprecated the `isNonNullableUnit` parameter of the `TypeResolverVisitor`
  constructor.  TypeResolverVisitor should now be configured using the
  `featureSet` parameter.
* Refined the return type of the getter `TypeParameter.declaredElement`.  It is
  always guaranteed to return a `TypeParameterElement`.
* Deprecated the `abstract` setter in `ClassElementImpl`, `EnumElementImpl`,
  `MethodElementImpl`, and `PropertyAccessorElementImpl`.  `isAbstract` should
  be used instead.
* Changed the way function types are displayed from e.g. `(int) -> void` to
  `void Function(int)`. This is more consistent with the syntax of Dart, and it
  will avoid ambiguities when nullability is added to the type system. This
  impacts to value returned by `FunctionType.displayName` and
  `FunctionType.toString` and `ExecutableElement.toString`. Client code might be
  broken if it depends on the content of the returned value.
* Introduced the function `parseString` to the public API.  This can be used in
  place of the deprecated functions `parseCompilationUnit` and
  `parseDirectives`.  Note that there is no option to parse only directives,
  since this functionality is broken anyway (`parseDirectives`, despite its
  name, parses the entire compilation unit).
* Changed the return type of `ClassTypeAlias.declaredElement` to `ClassElement`.
  There is no functional change; it has always returned an instance of
  `ClassElement`.
* Deprecated `parseFile`.  Please use `parseFile2` instead--in addition to
  supporting the same `featureSet` and `throwIfDiagnostics` parameters as
  `parseString`, it is much more efficient than `parseFile`.
* Added more specific deprecation notices to `package:analyzer/analyzer.dart` to
  direct clients to suitable replacements.
* Deprecated the enable flags `bogus-disabled` and `bogus-enabled`.  Clients
  should not be relying on the presence of these flags.
* Deprecated the constructor parameter
  ConstantEvaluationEngine.forAnalysisDriver, which no longer has any effect.
* Deprecated ElementImpl.RIGHT_ARROW.

## 0.36.3
* Deprecated `AstFactory.compilationUnit`.  In a future analyzer release, this
  method will be changed so that all its parameters are named parameters.
  Clients wishing to prepare for this should switch to using
  `AstFactory.compilationUnit2`.
* Deprecated Parser setters `enableControlFlowCollections`, `enableNonNullable`,
  `enableSpreadCollections`, and `enableTripleShift`, as well as the
  recently-introduced method `configureFeatures`.  Parsers should now be
  configured by passing a FeatureSet object to the Parser constructor.
* Deprecated `AnalysisError.isStaticOnly`.
* Deprecated `AnalysisError.offset` setter.
* Added method `LinterContext.canBeConstConstructor`.
* Bug fixes: #36732, #36775.

## 0.36.2
* Bug fixes: #36724.

## 0.36.1
* Deprecated `DartType.isUndefined`, and now it always returns `false`.
* The "UI as code" features (control_flow_collections and spread_collections)
  are now enabled.
* Bug fixes: #32918, #36262, #36380, #36439, #36492, #36529, #36576, #36667,
  #36678, #36691.

## 0.36.0
* Changed the return type of `Expression.precendence` to `Precedence`.  Clients
  that prepared for this change by switching to `Expression.precedence2` should
  now return to using `Expression.precedence`.
* AST cleanup related to the "UI as code" feature:
  * Removed the following AST node types:
    * `ForEachStatement` (use `ForStatement` instead)
    * `MapLiteral` and `MapLiteral2` (use `SetOrMapLiteral` instead)
    * `SetLiteral` and `SetLiteral2` (use `SetOrMapLiteral` instead)
    * `ListLiteral2` (use `ListLiteral` instead)
  * Deprecated `ForStatement2` (use `ForStatement` instead)
  * Removed the following visit methods:
    * `visitForEachStatement` (override `visitForStatement` instead)
    * `visitMapLiteral` and `visitMapLiteral2` (override `visitSetOrMapLiteral`
      instead)
    * `visitSetLiteral` and `visitSetLiteral2` (override `visitSetOrMapLiteral`
      instead)
    * `visitListLiteral2` (override `visitListLiteral` instead)
  * Deprecated the `visitForStatement2` visit method (use `VisitForStatement`
    instead)
  * Removed the following AstFactory methods:
    * `mapLiteral` and `mapLiteral2` (use `setOrMapLiteral` instead)
    * `setLiteral` and `setLiteral2` (use `setOrMapLiteral` instead)
    * `listLiteral2` (use `listLiteral` instead)
  * Deprecated `AstFactory.forStatement2`, and introduced
    `AstFactory.forStatement` to replace it
  * Changed the type of the getter `ListLiteral.elements` to
    `NodeList<CollectionElement>`
  * Deprecated `ListLiteral.elements2` (use `ListLiteral.elements` instead)
  * Deprecated `SetOrMapLiteral.elements2`, and introduced
    `SetOrMapLiteral.elements` to replace it
  * Deprecated `NodeLintRegistry.addForStatement2` (use
    `NodeLintRegistry.addForStatement` instead)
* Bug fixes: #36158, #36212, #36255

## 0.35.4
* Deprecated AST structures that will no longer be used after the
  control_flow_collections and spread_collections experiments are enabled.  The
  following AST node types are deprecated:
  * `ForEachStatement` (use `ForStatement2` instead)
  * `ForStatement` (use `ForStatement2` instead)
  * `MapLiteral` (use `SetOrMapLiteral` instead)
  * `SetLiteral` (use `SetOrMapLiteral` instead)
* Deprecated visit methods that will no longer be used after the
  control_flow_collections and spread_collections experiments are enabled.  The
  following visit methods are deprecated:
  * `visitForEachStatement` (override `visitForStatement2` instead)
  * `visitForStatement` (override `visitForStatement2` instead)
  * `visitMapLiteral` (override `visitSetOrMapLiteral` instead)
  * `visitSetLiteral` (override `visitSetOrMapLiteral` instead)
* Deprecated ASTFactory methods that will no longer be available after the
  control_flow_collections and spread_collections experiments are enabled.  The
  following factory methods are deprecated:
  * `mapLiteral` and `mapLiteral2` (use `setOrMapLiteral` instead)
  * `setLiteral` and `setLiteral2` (use `setOrMapLiteral` instead)
* Bug fixes: #33119, #33241, #35747, #35900, #36048, #36129
* The analyzer no longer uses `package:html` (see #35802)

## 0.35.3
* Further updates to the AST structure for the control_flow_collections and
  spread_collections experiments.  The following AST node types will be
  deprecated soon:
  * `ForEachStatement` (use `ForStatement2` instead)
  * `ForStatement` (use `ForStatement2` instead)
  * `MapLiteral` (use `SetOrMapLiteral` instead)
  * `SetLiteral` (use `SetOrMapLiteral` instead)
* Deprecated `Expression.precedence`.  In analyzer version 0.36.0, its return
  type will be changed to `Precedence`.  Clients that wish to prepare for the
  change can switch to `Expression.precedence2`.
* Bug fixes: #35908, #35993 (workaround).

## 0.35.2
* Updated support in the AST structure for the control_flow_collections and
  spread_collections experiments.  The following methods are now deprecated:
  * `AstFactory.mapLiteral2` and `AstFactory.setLiteral2` (replaced by
    `AstFactory.setOrMapLiteral`).
  * `AstVisitor.visitListLiteral2` (clients should not need to override this
    anymore).
  * `AstVisitor.visitMapLiteral2 and AstVisitor.visitSetLiteral2` (replaced by
    `AstVisitor.visitSetOrMapLiteral`).
* Started to add support for strict-inference as an analysis option.
* Bug fixes: #35870, #35922, #35936, #35940,
  https://github.com/flutter/flutter-intellij/issues/3204

## 0.35.1
* The new "set literals" language feature is now enabled by default.
* The dev_dependency analysis_tool was created so that clients do not have to
  depend on code that is used internally in the analyzer at development time.
* The `InheritanceManager` class is now deprecated.  The new
  `InheritanceManager2` class now supports accessing inherited interface/class
  maps.
* Added quick assists to support set literals.
* Added the ability for linter tests to drive the analyzer using custom analysis
  options.
* Updated support in the AST structure for the control_flow_collections and
  spread_collections experiments.  The new AST structures are still in
  development.
* Bug fixes: #34437, #35127, #35141, #35306, #35621.

## 0.35.0
* Added support in the AST structure for the control_flow_collections and
  spread_collections experiments. This includes adding new visitor methods to
  `AstVisitor`, which will need to be implemented by any classes that implement
  `AstVisitor` directly. Concrete implementations were added to other visitor
  classes (such as `RecursiveAstVisitor`) so that clients that extend those
  other classes will not be impacted.
* Removed `EMPTY_LIST` constants.  Please use `const <...>[]` instead.
* Disabled support for the task model.  Please use the new `AnalysisSession`
  API.
* Removed `StrongTypeSystemImpl`.  Please use `Dart2TypeSystem` instead.
* Made ERROR the default severity for StaticWarningCode.  We no longer need to
  promote warnings to errors in "strong mode" because strong mode is the only
  mode.
* Added exact type analysis for set literals (#35742).
* Bug fixes: #35305, #35750.

## 0.34.3
* Non-breaking AST changes in support for the control_flow_collections and
  spread_collections experiments.  Clients who wish to begin adding support for
  these experiments can depend on this release of the analyzer and begin writing
  visit methods.  The visit methods won't be added to the AstVisitor base class
  until 0.35.0.
* Bug fixes: #35551, #35708, #35723.

## 0.34.2
* Removed support for the `@checked` annotation.  Please use the `covariant`
  keyword instead (#28797).
* Did additional work on the new set_literals and constant_update_2018 features.
* Began adding a string representation of initializer expressions to summaries
  (#35418).
* Added a pub aware workspace so that pub packages can be handled properly.
* Added logging in an effort to track down #35551.
* Split off DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE from DEPRECATED_MEMBER_USE
  (#30084).
* Removed the unused hint code INVALID_ASSIGNMENT.
* Added a hint enforcing the contract of `@literal`:
  NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR.
* Added a hint INVALID_LITERAL_ANNOTATION (#34259).
* Fixed handling of @immutable on mixins.
* Did work on @sealed annotation for classes and mixins.
* Bug fixes: #25860, #29394, #33930, #35090, #35441, #35458, #35467, #35548.

## 0.34.1
* Added logic to report a hint if a deprecated lint is specified in the user's
  analysis_options.yaml file, or if a lint is specified twice.
* Added a note to the `UriResolver` documentation alerting clients of an
  upcoming breaking change.
* Improved parser recovery.
* Speculative work on fine-grained dependency tracking (not yet enabled).
* Initial support for new language features set_literals and
  constant_update_2018.
* Early speculative work on non-nullable types.
* Added AnalysisDriver.resetUriResolution().
* Deprecated TypeSystem.isStrong.
* Added WorkspacePackage classes, for determining whether two files are in the
  "same package."
* Added a public API for the TypeSystem class.
* Bug fixes: #33946, #35151, #35223, #35241, #35438.

## 0.34.0
* Support for `declarations-casts` has been removed and the `implicit-casts`
  option now has the combined semantics of both options. This means that users
  that disable `implicit-casts` might now see errors that were not previously
  being reported.
* Minor changes to the AnalysisSession and AnalysisDriver APIs to make it easier
  for clients to transition away from using the task model.
* Minor changes to the linter API to make it easier for lint rules to define
  their own lint codes.
* Add a version of getAncestor that matches by type without a closure.
* Add an AST structure for set literals.
* Bug fixes: #35162, #35230, #34733, #34741, #33553, #35090, #32815, #34387,
  #34495, #35043, #33553, #34906, #34489.

## 0.33.6+1
* Added a note to the `UriResolver` documentation alerting clients of an
  upcoming breaking change.

## 0.33.6
* Deprecated `AstNode.getAncestor` and introduced
  `AstNode.thisOrAncestorMatching` as its replacement.

## 0.33.5
* Add AnalysisSession.getResolvedLibrary()/ByElement() APIs.

## 0.33.4
* Add a hint when either Future or Stream are imported from dart:core in a package that is expected to work with an SDK before 2.1 where they were required to be imported from dart:async.
* Add a new "deprecated" maturity for lints
* Don't report DEPRECATED_MEMBER_USE for deprecated mixins, top-level variables, and class fields.
* Various bug fixes.

## 0.33.3+2
* Update SDK requirement to 2.1.0-dev.5.0.  From now on, the analyzer may import
  Future from dart:core. (#35158)

## 0.33.3+1
* Fix missing import of dart:async. (#35158)

## 0.33.3
* Backport Parsed/ResolvedLibraryResultImpl and ElementDeclarationResult.

## 0.33.2
* Protect against self-referencing classes in InheritanceManager2. (#34333)
* Introduce API so that the linter can be migrated away from Element.context.

## 0.33.1
* Fix circular typedef stack overflow. (#33599)
* Check that the implemented member is a valid override of the member from
  the super constraint. (#34693)
* Begin replacing InheritanceManager with InheritanceManager2 and
  deprecate older members.
* Performance fixups with Analysis Driver.
* Verify the superconstraint signature invoked by a mixin. (#34896)
* In_matchInterfaceSubtypeOf, account for mixins having null. (#34907)

## 0.33.0
* Support handling 'class C with M', with extends missing.
* Report ABSTRACT_SUPER_MEMBER_REFERENCE as an error.
* Further support and bugfixes for Dart 2.1-style mixin declarations.
* Fixes for int2double support.
* Performance improvements for analysis and summary generation.
* Allow "yield" as a label, and "operator" as a static method name (#33672,
  #33673)

## 0.33.0-alpha.0
* Switch to using the parser from front_end.
* Start implementing the new mixin syntax.

## 0.32.4
* Updated SDK constraint to <3.0.0.
* Updated to be compatible with Dart 2 void usage semantics.
* Deprecate the `AnalysisOptions.strongMode` flag. This is now hard-coded to
  always return true.

## 0.32.3
* Pull fix in kernel package where non-executable util.dart was moved out of bin/.

## 0.32.2

* Improved const evaluation analysis (new errors for `const A(B())` if `B` is non-const).
* Parser recovery improvements.

## 0.32.1

* The Parser() class now by default will parse with optional new or const. This
  affects many APIs, for instance, `analyzer.dart`'s `parseCompilationUnit()`.
* Add the ability to specify a pathContext when creating a ContextRoot (not part
  of the officially supported API, but needed by some clients).
* AnalysisSession now exports resourceProvider.
* Function type parameters are now invariant. (#29014)
* New logic to find source files generated by package:build when that build
  system is detected.
* Data stored by FileDataStore is now checked using CRC32.
* Add ability for the angular plugin to set ErrorVerifier.enclosingClass.

## 0.32.0

* Allow annotations on enum constants.
* Analyzer fully supports being run on the VM with --preview-dart-2.
* Fix heap usage regression by not storing bytes in the file cache.
* Add AnalysisSessionHelper.getTopLevelPropertyAccessor().
* Don't infer types when there's an irreconcilable type mismatch (#32305)
* Many fasta parser improvements.
* Use @isTest and @isTestGroup to understand executable element as a
  test/group.  To use, add `@isTest` annotations (from package:meta)
  to the methods in their package which define a test.
```dart
@isTest
void myMagicTest(String name, FutureOr Function() body) {
  test(name, body);
}
```
  When subscribed to [notifications for outlines of a test file](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/master/pkg/analysis_server/doc/api.html#notification_analysis.outline),
  they will include elements for UNIT_TEST_GROUP and UNIT_TEST_TEST.
* Improve guess for type name identifier. (#32765)
* Fix LineInfo.getOffsetOfLineAfter().
* Remove some flutter specific analysis code.
* Fix resolution tests when run locally.

## 0.31.2-alpha.2

* Refactoring to make element model logic sharable with
  linker. (#32525, #32674)
* Gracefully handle an invalid packages file. (#32560)
* Fix silent inconsistency in top level inference. (#32394)
* Fix test to determine whether a library is in the SDK. (#32707)
* Fix for type inference from instance creation arguments.
* Make GenericFunctionTypeElementForLink implement
  GenericFunctionTypeElementImpl (#32708)
* Check for missing required libraries dart:core and dart:async. (#32686)
* Add callable object support. (#32156, #32157, #32426)
* Avoid putting libraries of all analyzed units in the current
  session. (too expensive)
* Deprecate the option to enable using a URI in a part-of directive.
* Support implicit call() invocation in top-level inference. (#32740)
* Don't emit errors for lint rule names.
* Allow empty flutter: sections in pubspec files.
* Remove the special casing of 'packages' files from the analyzer and analysis
  server.
* Initial implementation of API to build analysis contexts (replacing
  ContextLocator.locateContexts).
* Fix regression in Analyzer callable function support. (#32769)
* Several performance enhancements, including:
  * Add a shared cache of FileState contents (making flutter repo analysis
    ~12% faster).
  * Replace SourceFactory.resolveUri() with resolveRelativeUri() in
    resynthesizer.  (10% faster flutter repo analysis)
  * Optimize computing exported namespaces in FileState.
  * Optimize computing exported namespaces in prelinker. (8% faster
    flutter repo analysis)
  * Add NodeLintRule and UnitLintRule that replace AstVisitor in lints.
    (6% faster flutter repo analysis)
* Remove fuzzy arrow support from analyzer. (#31637)
* More fixes for running the analyzer with Dart 2.
* Add isXYZ accessors to ParameterElementForLink_VariableSetter. (#32896)
* Demote IMPORT_DUPLICATED_LIBRARY_NAMED to a warning.
* Deprecated/removed some unused classes and libraries from the public API.
* Instantiate bounds to bounds.
* Use package:path instead of AbsolutePathContext.
* Check that argument is assignable to parameter in call() (#27098)
* preview-dart-2 is now the default for the command line analyzer, also
  implying strong.  Use --no-strong and --no-preview-dart-2 to handle
  Dart 1 code.
* Export SyntheticBeginToken and SyntheticToken from the analyzer for
  angular_analyzer_plugin.
* Improve error messages for annotations involving undefined names (#27788)
* Add support for getting parse results synchronously.
* Change linter subscriptions from functions to AstVisitor(s).

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
