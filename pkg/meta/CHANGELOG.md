## 0.9.0
* Introduce `@protected` annotation for members that must only be called from
instance members of subclasses.
* Introduce `@required` annotation for optional parameters that should be treated
as required.
* Introduce `@mustCallSuper` annotation for methods that must be invoked by all
overriding methods.
