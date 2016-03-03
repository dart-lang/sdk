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
