> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

# Who is this article for?

If you are writing tests of core parts of the Dart SDK, there are special
tools to run these tests on browsers. If you are writing tests for a package
that is not part of the Dart SDK distribution, then
[package:test](http://github.com/dart-lang/test/blob/master/README.md),
previously called "unittest", is the best way for you to write your unit tests
for browsers and the standalone Dart vm.  Published Dart packages are
automatically tested using [Drone.io](http://readme.drone.io/pub/overview).

The remainder of this article is about the browser test infrastructure for
core Dart libraries and tools in the Dart repository. These test suites
are run by the tools/test.py tool,
and can be run on web browsers as well as the standalone Dart vm.
In the most common case, Dart scripts are wrapped in an automatically-created
HTML wrapper page, and compiled to JS using dart2js, to run on web browsers.

Usually, this is the best way to test dart:html or other web features,
but a few complex cases require us to write a custom html file, rather
than using the HTML wrapper file.


# Details

A test script testing Dart's web libraries, for example a test in
tests/html, will create the DOM elements it needs to test in the test
script itself.  WebPlatformTest tests in the test/co19 test suite will
add HTML or DOM elements to the document, and then operate on them.
This is the best way to create and test a web page.  For example, the
test
WebPlatformTest/html/semantics/tabular-data/the-table-element/insertRow-method\_t01.dart
contains the following Dart code:

```dart
const String htmlEL = r'''
<div id="test">
<table>
<tr>
<td>
</table>
</div>
''';

void main() {
  document.body.appendHtml(htmlEL);
  ...
}
```

## Running Tests

When a test is run on a browser, the wrapper HTML file, and the
modified or compiled Dart scripts are put into a directory called
generated\_tests, under the build directory that the Dart executable
and SDK are built in.  The test server runs a local HTTP server, that
serves files from the build directory, and also from the Dart
repository root, and starts a browser that runs the tests fetched from
this server.  To debug a test, you can start this HTTP server, and
then open the test's web page manually in a browser.  The output of
test.py includes the command lines necessary to do this.

## Custom HTML Tests

If a test requires a custom HTML file, and cannot be written by adding
DOM elements to a page after it is loaded, then the test scripts allow
you to write the HTML file separately, and use it instead.  There are
two systems for doing this.  The first system adds a custom HTML file
to the test called foo\_test.dart by putting an HTML file called
foo\_test.html in the same directory.  The second system creates a
test from any file ending in `_htmltest.html` in that directory, like
bar\_htmltest.html.

### `_test.html` custom HTML files

To be filled in

### `_htmltest.html` tests

An HTML file with a name that ends in `_htmltest.html` will be read by
the test infrastructure, and metadata about what scripts are used and
what messages the test should post to the document window is read from
an annotation in that file.

The annotation is a JSON dictionary, embedded between two delimiters,
and it can be put inside an HTML comment so that the unprocessed page
looks like valid HTML:

```html
<!--
START_HTML_DART_TEST
{
  "scripts": ["scripts_test_dart.dart", "scripts_test_js.js"],
  "expectedMessages": ["crab", "fish", "squid", "sea urchin"]
}
END_HTML_DART_TEST
-->
```

The test will pass if the web page posts all the strings in the
expectedMessages property to its top-level window, for example by
executing lines like

```javascript
window.postMessage('squid', '*');
```

Scripts in the 'scripts' property of the annotation will be
automatically copied from the test directory to the generated-test
directory, and compiled from dart to js if necessary.  The script tags
using Dart scripts should be written exactly like

```html
<script src="foo.dart" type="application/dart"></script>
```
in order for the test generation to find and modify them.

In order for the test framework to catch all errors in this HTML test,
the first script that executes on this page must be:

```html
<script>window.parent.dispatchEvent(new Event('detect_errors'));</script>
```
 This allows the test framework
to attach an error handler to the window at the first opportunity,
before the scripts being tested have run.
