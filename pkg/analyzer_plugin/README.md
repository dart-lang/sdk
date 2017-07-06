# analyzer_plugin

A framework for building plugins for the analysis server.

## Usage

**Note:** The plugin support is not currently available for general use.

Plugins are written in Dart and are run in the same VM as the analysis server.
The analysis server runs each plugin in a separate isolate and communicates with
the plugin using a [plugin API][pluginapi]. This API is similar to the API used
by the analysis server to communicate with clients.

Plugins are automatically discovered and run by the analysis server.

This package contains support code to make it easier to write a plugin. There is
a [tutorial][tutorial] describing how to use the support in this package.

## Support

Post issues and feature requests on the [issue tracker][issues].

Questions and discussions are welcome at the
[Dart Analyzer Discussion Group][list].

## License

See the [LICENSE] file.

[issues]: https://github.com/dart-lang/sdk/issues
[LICENSE]: https://github.com/dart-lang/sdk/blob/master/pkg/analyzer/LICENSE
[list]: https://groups.google.com/a/dartlang.org/forum/#!forum/analyzer-discuss
[pluginapi]: https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/master/pkg/analyzer_plugin/doc/api.html
[tutorial]: doc/tutorial/tutorial.md
