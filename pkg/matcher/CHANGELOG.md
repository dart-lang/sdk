## 0.11.1+1

* Refactored libraries and tests.

* Fixed spelling mistake.

## 0.11.1

* Added `isNaN` and `isNotNaN` matchers.

## 0.11.0

* Removed deprecated matchers.

## 0.10.1+1

* Get the tests passing when run on dart2js in minified mode.

## 0.10.1

* Compare sets order-independently when using `equals()`.

## 0.10.0+3

* Removed `@deprecated` annotation on matchers due to 
[Issue 19173](https://code.google.com/p/dart/issues/detail?id=19173)

## 0.10.0+2

* Added types to a number of constants.

## 0.10.0+1

* Matchers related to bad language use have been removed. These represent code
structure that should rarely or never be validated in tests.
    * `isAbstractClassInstantiationError`
    * `throwsAbstractClassInstantiationError`
    * `isFallThroughError`
    * `throwsFallThroughError`

* Added types to a number of method arguments.

* The structure of the library and test code has been updated.
