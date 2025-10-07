# analysis\_server\_plugin package

This package offers support for writing Dart analysis server plugins.

Analysis server plugins empower developers to contribute their own Dart static
analysis in IDEs and at the command line via `dart analyze` and `flutter
analyze`. Analysis server plugins can offer the following static analyses:

* analysis rules, which report diagnostics in the IDE, and at the command line
* IDE quick fixes, which are local refactorings offered to users to correct a
  given diagnostic
* IDE quick assists, which are local refactorings that are offered at specific
  syntax nodes in code, but do not necessarily correct a static code issue

Review the following documents for how to write and how to use analysis server
plugins:

* [Writing a plugin][]
  * [Writing rules][]
  * [Testing rules][]
  * [Writing fixes][]
  * [Writing assists][]
* [Using plugins][]

[Writing a plugin]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md
[Writing rules]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server_plugin/doc/writing_rules.md
[Testing rules]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server_plugin/doc/testing_rules.md
[Writing fixes]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server_plugin/doc/writing_fixes.md
[Writing assists]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server_plugin/doc/writing_assists.md
[Using plugins]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server_plugin/doc/using_plugins.md
