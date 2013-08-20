Polymer.dart
============

Polymer is a new type of library for the web, built on top of Web Components,
and designed to leverage the evolving web platform on modern browsers.

Polymer.dart is a Dart port of Polymer created and maintained by the Dart team.
The Dart team is collaborating with the Polymer team to ensure that polymer.dart
elements and polyfills are fully compatible with Polymer.

For more information about Polymer, see <http://www.polymer-project.org/>.
For more information about Dart, see <http://www.dartlang.org/>.

Try It Now
-----------
Add the polymer.dart package to your pubspec.yaml file:

```yaml
dependencies:
  polymer: any
```

Instead of using `any`, we recommend using version ranges to avoid getting your
project broken on each release. Using a version range lets you upgrade your
package at your own pace. You can find the latest version number at
<https://pub.dartlang.org/packages/polymer>.


Learn More
----------

**Note**: these documents are currently out of date.

* [Read an overview][overview]
* [Setup your tools][tools]
* [Browse the features][features]
* [Dive into the specification][spec]

See our [TodoMVC][] example by opening up the Dart Editor's Welcome Page and
selecting "TodoMVC".

Running Tests
-------------

Dependencies are installed using the [Pub Package Manager][pub].
```bash
pub install

# Run command line tests and automated end-to-end tests. It needs two
# executables on your path: `dart` and `content_shell` (see below
# for links to download `content_shell`)
test/run.sh
```
Note: to run browser tests you will need to have [content_shell][cs],
which can be downloaded prebuilt for [Ubuntu Lucid][cs_lucid],
[Windows][cs_win], or [Mac][cs_mac]. You can also build it from the
[Dartium and content_shell sources][dartium_src].

For Linux users all the necessary fonts must be installed see
<https://code.google.com/p/chromium/wiki/LayoutTestsLinux>.

Contacting Us
-------------

Please file issues in our [Issue Tracker][issues] or contact us on the
[Dart Web UI mailing list][mailinglist].

We also have the [Web UI development list][devlist] for discussions about
internals of the code, code reviews, etc.

[wc]: http://dvcs.w3.org/hg/webcomponents/raw-file/tip/explainer/index.html
[pub]: http://www.dartlang.org/docs/pub-package-manager/
[cs]: http://www.chromium.org/developers/testing/webkit-layout-tests
[cs_lucid]: http://gsdview.appspot.com/dartium-archive/continuous/drt-lucid64.zip
[cs_mac]: http://gsdview.appspot.com/dartium-archive/continuous/drt-mac.zip
[cs_win]: http://gsdview.appspot.com/dartium-archive/continuous/drt-win.zip
[dartium_src]: http://code.google.com/p/dart/wiki/BuildingDartium
[TodoMVC]: http://addyosmani.github.com/todomvc/
[issues]: http://dartbug.com/new
[mailinglist]: https://groups.google.com/a/dartlang.org/forum/?fromgroups#!forum/web-ui
[devlist]: https://groups.google.com/a/dartlang.org/forum/?fromgroups#!forum/web-ui-dev
[overview]: http://www.dartlang.org/articles/dart-web-components/
[tools]: https://www.dartlang.org/articles/dart-web-components/tools.html
[spec]: https://www.dartlang.org/articles/dart-web-components/spec.html
[features]: https://www.dartlang.org/articles/dart-web-components/summary.html
