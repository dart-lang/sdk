# Feature tests for starting async methods without suspending

This directory was created in order to hold tests pertaining to the Dart
feature which makes methods marked as `async` start executing the body
immediately, rather than returning a `Future` and suspending. For more
details, please check the
[language specification update](https://github.com/dart-lang/sdk/commit/2170830a9e41fa5b4067fde7bd44b76f5128c502).
