## 1.0.1
* Updated `@factory` to allow statics and methods returning `null`.

## 1.0.0
* First stable API release.

## 0.12.2
* Updated `@protected` to include implemented interfaces (linter#252).

## 0.12.1
* Fixed markdown in dartdocs.

## 0.12.0
* Introduce `@optionalTypeArgs` annotation for classes whose type arguments are to be treated as optional.

## 0.11.0
* Added new `Required` constructor with a means to specify a reason to explain why a parameter is required.

## 0.10.0
* Introduce `@factory` annotation for methods that must either be abstract or
must return a newly allocated object.
* Introduce `@literal` annotation that indicates that any invocation of a
constructor must use the keyword `const` unless one or more of the
arguments to the constructor is not a compile-time constant.

## 0.9.0
* Introduce `@protected` annotation for members that must only be called from
instance members of subclasses.
* Introduce `@required` annotation for optional parameters that should be treated
as required.
* Introduce `@mustCallSuper` annotation for methods that must be invoked by all
overriding methods.
