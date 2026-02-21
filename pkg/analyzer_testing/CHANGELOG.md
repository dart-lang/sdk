## 0.2.1

- Require version `10.2.0` of the `analyzer` package.

## 0.2.0

- Remove deprecated mock APIs: `MockPackagesMixin.addAngularMeta`
  `MockPackagesMixin.addFlutterTest` `MockPackagesMixin.addJs`
  `MockPackagesMixin.addKernel` `MockPackagesMixin.pedantic` and
  `MockPackagesMixin.addUI`.
- Require version `10.1.0` of the `analyzer` package.

## 0.1.10

- A stub Flutter package can be added in tests by overriding the
  `addFlutterPackageDep` getter to return `true`. This API existed before but is
  now functional; same with `addFixnumPackageDep`, `addMetaPackageDep`, and
  `addTestReflectiveLoaderPackageDep`.
- Require version `10.0.2` of the `analyzer` package.

## 0.1.9

- Deprecate `MockPackagesMixin.addUI`; This is replaced by `addSkyEngine`.
- Deprecate `MockPackagesMixin.addFlutterTest`. A mock `flutter_test` package
  can still be written with `PubPackageResolutionTest.newPackage`.
- Require version `10.0.1` of the `analyzer` package.

## 0.1.8

- Require version `10.0.0` of the `analyzer` package.
- Change the behavior of `analysisOptionsContent` so that by default, the
  analysis options file used in testing specifies a `true` value for
  `propagate-linter-exceptions`. This ensures that when tests are run,
  exceptions that occur while processing lint rules will cause the test to fail.
- Deprecate `MockPackagesMixin.addAngularMeta`. A mock `angular_meta` package
  can still be written with `PubPackageResolutionTest.newPackage`.
- Deprecate `MockPackagesMixin.addJs` and
  `PubPackageResolutionTest.addJsPackageDep`. A mock js package can still be
  written with `PubPackageResolutionTest.newPackage`.
- Deprecate `MockPackagesMixin.addKernel` and
  `PubPackageResolutionTest.addKernelPackageDep`. A mock kernel
  package can still be written with `PubPackageResolutionTest.newPackage`.
- Deprecate `MockPackagesMixin.addPedantic`. A mock pedantic package can still
  be written with `PubPackageResolutionTest.newPackage`.

## 0.1.7

- Deprecate `AnalysisRuleTest.analysisRule`; instead of implementing this
  getter, set the `rule` field in the `setUp` method, before calling
  `super.setUp`. For example, when testing an analysis rule, `MyRule`, call
  `rule = MyRule()` in `setUp`.

## 0.1.6

- Require version `9.0.0` of the `analyzer` package.

## 0.1.5

- Require version `8.4.0` of the `analyzer` package.

## 0.1.4

- Require version `8.3.0` of the `analyzer` package.
- Improve error message when trying to use any of the built-in mock libraries
  from a test outside of the Dart SDK.

## 0.1.3

- Require version `8.2.0` of the `analyzer` package.
- Require Dart SDK `^3.9.0`.

## 0.1.2

- Require version `8.1.1` of the `analyzer` package.

## 0.1.1

- Require version `^8.1.0` of the `analyzer` package.

## 0.1.0

- Initial release
