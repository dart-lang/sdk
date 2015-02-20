dart-dev-compiler
=================

This is an experimental Dart->JS compiler designed to create idiomatic,
readable JS output. We're investigating this because we want to enable
easy debugging of Dart applications on all supported browsers.

The initial target for this work is Chrome, which is why there's an ES6
backend. Longer term, we plan to target all browsers that Dart supports.
