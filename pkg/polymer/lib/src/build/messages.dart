// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains all error and warning messages produced by polymer.
library polymer.src.build.messages;

import 'package:code_transformers/messages/messages.dart';
import 'constants.dart';

const IMPORT_NOT_FOUND = const MessageTemplate(
    const MessageId('polymer', 1),
    'couldn\'t find imported asset "%-path-%" in package "%-package-%".',
    'Import not found',
    '''
An HTML import seems to be broken. This could be because the file doesn't exist
or because the link URL is incorrect.
''');

const DUPLICATE_DEFINITION = const MessageTemplate(
    const MessageId('polymer', 2),
    'duplicate definition for custom tag "%-name-%".%-second-%',
    'Duplicate definition',
    '''
Custom element names are global and can only be defined once. Some common
reasons why you might get two definitions:

  * Two different elements are declared with the same name.
  * A single HTML file defining an element, has been imported using two different
    URLs.
''');

const USE_POLYMER_HTML = const MessageTemplate(
    const MessageId('polymer', 3),
      'Missing definition for <polymer-element>, please add the following '
      'HTML import at the top of this file: <link rel="import" '
      'href="%-reachOutPrefix-%packages/polymer/polymer.html">.',
      'Missing import to polymer.html',
      '''
Starting with polymer 0.11.0, each file that uses the definition
of polymer-element must import it either directly or transitively.
''');

const NO_IMPORT_WITHIN_ELEMENT = const MessageTemplate(
    const MessageId('polymer', 4),
    'Polymer.dart\'s implementation of '
    'HTML imports are not supported within polymer element definitions, yet. '
    'Please move the import out of this <polymer-element>.',
    'Invalid import inside <polymer-element>',
    '''
HTML imports are expected at the top of each document, outside of any
polymer-element definitions. The polymer build process combines all your HTML
files together so you can deploy a single HTML file with your application. This
build process ignores imports that appear to be in the wrong location.
''');

const MISSING_INIT_POLYMER = const MessageTemplate(
    const MessageId('polymer', 5),
    'To run a polymer application, you need to call `initPolymer()`. You can '
    'either include a generic script tag that does this for you:'
    '\'<script type="application/dart">export "package:polymer/init.dart";'
    '</script>\' or add your own script tag and call that function. '
    'Make sure the script tag is placed after all HTML imports.',
    'Missing call to `initPolymer()`',
    '''
Your application entry point didn't have any Dart script tags, so it's missing
some initialization needed for polymer.dart.
''');

const NO_DART_SCRIPT_AND_EXPERIMENTAL = const MessageTemplate(
    const MessageId('polymer', 6),
    'The experimental bootstrap feature doesn\'t support script tags on '
    'the main document (for now).',
    'Script tags with experimental bootstrap',
    'This experimental feature is no longer supported.');

const ONLY_ONE_TAG = const MessageTemplate(
    const MessageId('polymer', 7),
    'Only one "application/dart" script tag per document is allowed.',
    'Multiple Dart script tags per document',
    '''
Dartium currently allows only one script tag per document. Any
additional script tags might be ignored or result in an error. This will
likely change in the future, but for now, combine the script tags together into
a single Dart library.
''');

const MOVE_IMPORTS_UP = const MessageTemplate(
    const MessageId('polymer', 8),
    'Move HTML imports above your Dart script tag.',
    'Imports before script tags',
    '''
It is good practice to put all your HTML imports at the beginning of the
document, above any Dart script tags. Today, the execution of Dart script tags
is not synchronous in Dartium, so the difference is not noticeable. However,
Dartium that will eventually change and make the timing of script tags execution
match how they are in JavaScript. At that point the order of your imports with
respect to script tags will be important. Following the practice of putting
imports first protects your app from a future breaking change in this respect.
''');

const MISSING_HREF = const MessageTemplate(
    const MessageId('polymer', 9),
    'link rel="%-rel-%" missing href.',
    'Missing href on a `<link>` tag',
    'All `<link>` tags should have a valid URL to a resource.');

const ELEMENT_DEPRECATED_EONS_AGO = const MessageTemplate(
    const MessageId('polymer', 10),
    '<element> elements are not supported, use <polymer-element> instead.',
    '`<element>` is deprecated',
    '''
Long ago `<polymer-element>` used to be called `<element>`. You probably ran
into this error if you were migrating code that was written on a very early
version of polymer.
''');

// TODO(jmesserly): this warning is wrong if someone is using raw custom
// elements. Is there another way we can handle this warning that won't
// generate false positives?
const CUSTOM_ELEMENT_NOT_FOUND = const MessageTemplate(
    const MessageId('polymer', 11),
    'custom element with name "%-tag-%" not found.',
    'Definition of a custom element not found',
    '''
The polymer build was not able to find the definition of a custom element. This
can happen if an element is defined with a `<polymer-element>` tag, but you are
missing an HTML import or the import link is incorrect.

This warning can also be a false alarm. For instance, when an element is defined
programatically using `document.registerElement`. In that case the polymer build
will not be able to see the definition and will produce this warning.
''');

const SCRIPT_TAG_SEEMS_EMPTY = const MessageTemplate(
    const MessageId('polymer', 12),
    'script tag seems empty.',
    'Empty script tag',
    'Script tags should either have a `src` attribute or a non-empty body.');

const EXPECTED_DART_MIME_TYPE = const MessageTemplate(
    const MessageId('polymer', 13),
    'Wrong script type, expected type="application/dart".',
    'Expected Dart mime-type',
'''
You seem to have a `.dart` extension on a script tag, but the mime-type
doesn't match `application/dart`.
''');

const EXPECTED_DART_EXTENSION = const MessageTemplate(
    const MessageId('polymer', 14),
    '"application/dart" scripts should use the .dart file extension.',
    'Expected Dart file extension',
'''
You are using the `application/dart` mime-type on a script tag, so
the URL to the script source URL should have a `.dart` extension.
''');

const FOUND_BOTH_SCRIPT_SRC_AND_TEXT = const MessageTemplate(
    const MessageId('polymer', 15),
    'script tag has "src" attribute and also has script text.',
    'Script with both src and inline text',
'''
You have a script tag that includes both a `src` attribute and inline script
text. You must choose one or the other.
''');

const BAD_INSTANTIATION_MISSING_BASE_TAG = const MessageTemplate(
    const MessageId('polymer', 16),
    'custom element "%-tag-%" extends from "%-base-%", but '
    'this tag will not include the default properties of "%-base-%". '
    'To fix this, either write this tag as <%-base-% '
    'is="%-tag-%"> or remove the "extends" attribute from '
    'the custom element declaration.',
    'Incorrect instantiation: missing base tag in instantiation',
    '''
When you declare that a custom element extends from a base tag, for example:

    <polymer-element name="my-example" extends="ul">

or:

    <polymer-element name="my-example2" extends="ul">
    <polymer-element name="my-example" extends="my-example2">

You should instantiate `my-example` by using this syntax:

    <ul is="my-example">

And not:

    <my-example>

Only elements that don't extend from existing HTML elements are created using
the latter form.

This is because browsers first create the base element, and then upgrade it to
have the extra functionality of your custom element. In the example above, using
`<ul>` tells the browser which base type it must create before
doing the upgrade.
''');

const BAD_INSTANTIATION_BOGUS_BASE_TAG = const MessageTemplate(
    const MessageId('polymer', 17),
    'custom element "%-tag-%" doesn\'t declare any type '
    'extensions. To fix this, either rewrite this tag as '
    '<%-tag-%> or add \'extends="%-base-%"\' to '
    'the custom element declaration.',

    'Incorrect instantiation: extra `is` attribute or missing `extends` '
    'in declaration',
    '''
Creating a custom element using the syntax:

    <ul is="my-example">

means that the declaration of `my-example` extends transitively from `ul`. This
error message is shown if the definition of `my-example` doesn't declare this
extension. It might be that you no longer extend from the base element, in which
case the fix is to change the instantiation to:

    <my-example>

Another possibility is that the declaration needs to be fixed to include the
`extends` attribute, for example:

    <polymer-element name="my-example" extends="ul">
''');

const BAD_INSTANTIATION_WRONG_BASE_TAG = const MessageTemplate(
    const MessageId('polymer', 18),
    'custom element "%-tag-%" extends from "%-base-%". '
    'Did you mean to write <%-base-% is="%-tag-%">?',
    'Incorrect instantiation: base tag seems wrong',
    '''
It seems you have a declaration like:

    <polymer-element name="my-example" extends="div">

but an instantiation like:

    <span is="my-example">

Both the declaration and the instantiation need to match on the base type. So
either the instantiation needs to be fixed to be more like:

    <span is="my-example">

or the declaration should be fixed to be like:

    <polymer-element name="my-example" extends="span">
''');

const NO_DASHES_IN_CUSTOM_ATTRIBUTES = const MessageTemplate(
    const MessageId('polymer', 19),
    'PolymerElement no longer recognizes attribute names with '
    'dashes such as "%-name-%". Use %-alternative-% '
    'instead (both forms are equivalent in HTML).',
    'No dashes allowed in custom attributes',
    '''
Polymer used to recognize attributes with dashes like `my-name` and convert them
to match properties where dashes were removed, and words follow the camelCase
style (for example `myName`). This feature is no longer available. Now simply
use the same name as the property.

Because HTML attributes are case-insensitive, you can also write the name of
your property entirely in lowercase. Just be sure that your custom-elements
don't declare two properties with the same name but different capitalization.
''');


const EVENT_HANDLERS_ONLY_WITHIN_POLYMER = const MessageTemplate(
    const MessageId('polymer', 20),
    'Inline event handlers are only supported inside '
    'declarations of <polymer-element>.',
    'Event handlers not supported here',
    '''
Bindings of the form `{{ }}` are supported inside `<template>` nodes, even outside
of `<polymer-element>` declarations. However, those bindings only support binding
values into the content of a node or an attribute.

Inline event handlers of the form `on-click="{{method}}"` are a special feature
of polymer elements, so they are only supported inside `<polymer-element>`
definitions.
''');

const INVALID_EVENT_HANDLER_BODY = const MessageTemplate(
    const MessageId('polymer', 21),
    'Invalid event handler body "%-value-%". Declare a method '
    'in your custom element "void handlerName(event, detail, target)" '
    'and use the form %-name-%="{{handlerName}}".',
    'No expressions allowed in event handler bindings',
    '''
Unlike data bindings, event handler bindings of the form `on-click="{{method}}"`
are not evaluated as expressions. They are meant to just contain a simple name
that resolves to a method in your polymer element's class definition.
''');

const NESTED_POLYMER_ELEMENT = const MessageTemplate(
    const MessageId('polymer', 22),
    'Nested polymer element definitions are not allowed.',
    'Nested polymer element definitions not allowed',
    '''
Because custom element names are global, there is no need to have a
`<polymer-element>` definition nested within a `<polymer-element>`. If you have
a definition inside another, move the second definition out.

You might see this error if you have an HTML import within a polymer element.
You should be able to move the import out of the element definition.
''');

const MISSING_TAG_NAME = const MessageTemplate(
    const MessageId('polymer', 23),
    'Missing tag name of the custom element. Please include an '
    'attribute like \'name="your-tag-name"\'.',
    'Polymer element definitions without a name',
    '''
Polymer element definitions must have a name. You can include a name by using
the `name` attribute in `<polymer-element>` for example:

    <polymer-element name="my-example">
''');

final INVALID_TAG_NAME = new MessageTemplate(
    const MessageId('polymer', 24),
    'Invalid name "%-name-%". Custom element names must have '
    'at least one dash (-) and can\'t be any of the following names: '
    '${invalidTagNames.keys.join(", ")}.',
    'Custom element name missing a dash',
    '''
Custom element names must have a dash (`-`) and can\'t be any of the following
reserved names:

${invalidTagNames.keys.map((e) => '  * `$e`\n').join('')}

''');

const INLINE_IMPORT_FAIL = const MessageTemplate(
    const MessageId('polymer', 25),
    'Failed to inline HTML import: %-error-%',
    'Error while inlining an import',
    '''
An error occurred while inlining an import in the polymer build. This is often
the result of a broken HTML import.
''');

const INLINE_STYLE_FAIL = const MessageTemplate(
    const MessageId('polymer', 26),
    'Failed to inline stylesheet: %-error-%',
    'Error while inlining a stylesheet',
    '''
An error occurred while inlining a stylesheet in the polymer build. This is
often the result of a broken URL in a `<link rel="stylesheet" href="...">`.
''');

const SCRIPT_FILE_NOT_FOUND = const MessageTemplate(
    const MessageId('polymer', 27),
    'Script file at "%-url-%" not found.',
    'URL to a script file might be incorrect',
    '''
An error occurred trying to read a script tag on a given URL. This is often the
result of a broken URL in a `<script src="...">`.
''');

const USE_UNDERSCORE_PREFIX = const MessageTemplate(
    const MessageId('polymer', 28),
    'When using bindings with the "%-name-%" attribute you may '
    'experience errors in certain browsers. Please use the '
    '"_%-name-%" attribute instead.',
    'Attribute missing "_" prefix',
    '''
Not all browsers support bindings to certain attributes, especially URL
attributes. Some browsers might sanitize attributes and result in an
incorrect value. For this reason polymer provides a special set of attributes
that let you bypass any browser internal attribute validation. The name of the
attribute is the same as the original attribute, but with a leading underscore.
For example, instead of writing:

    <img src="{{binding}}">

you can write:

    <img _src="{{binding}}">

For more information, see <http://goo.gl/5av8cU>.
''');

const DONT_USE_UNDERSCORE_PREFIX = const MessageTemplate(
    const MessageId('polymer', 29),
    'The "_%-name-%" attribute is only supported when using bindings. '
    'Please change to the "%-name-%" attribute.',
    'Attribute with extra "_" prefix',
    '''
A special attribute exists to support bindings on URL attributes. For example,
this correctly binds the `src` attribute in an image:

    <img _src="{{binding}}">

However, this special `_src` attribute is only available for bindings. If you
just have a URL, use the normal `src` attribute instead.
''');

const INTERNAL_ERROR_DONT_KNOW_HOW_TO_IMPORT = const MessageTemplate(
    const MessageId('polymer', 30),
    "internal error: don't know how to include %-target-% from"
    " %-source-%.%-extra-%",
    "Internal error: don't know how to include a URL",
    '''
Sorry, you just ran into a bug in the polymer transformer code. Please file a
bug at <http://dartbug.com/new> including, if possible, some example code that
can help the team reproduce the issue.
''');

const INTERNAL_ERROR_UNEXPECTED_SCRIPT = const MessageTemplate(
    const MessageId('polymer', 31),
    'unexpected script. The ScriptCompactor transformer should run after '
    'running the ImportInliner',
    'Internal error: phases run out of order',
    '''
Sorry, you just ran into a bug in the polymer transformer code. Please file a
bug at <http://dartbug.com/new> including, if possible, some example code that
can help the team reproduce the issue.
''');

const PRIVATE_CUSTOM_TAG = const MessageTemplate(
    const MessageId('polymer', 32),
    '@CustomTag is not currently supported on private classes:'
    ' %-name-%. Consider making this class public, or create a '
    'public initialization method marked with `@initMethod` that calls '
    '`Polymer.register(%-name-%, %-className-%)`.',
    '`@CustomTag` used on a private class',
    '''
The `@CustomTag` annotation is currently only supported on public classes. If
you need to register a custom element whose implementation is a private class
(that is, a class whose name starts with `_`), you can still do so by invoking
`Polymer.register` within a public method marked with `@initMethod`.
''');

const PRIVATE_INIT_METHOD = const MessageTemplate(
    const MessageId('polymer', 33),
    '@initMethod is no longer supported on private functions: %-name-%',
    '`@initMethod` is on a private function',
    '''
The `@initMethod` annotation is currently only supported on public top-level
functions.
''');

const MISSING_ANNOTATION_ARGUMENT = const MessageTemplate(
    const MessageId('polymer', 34),
    'Missing argument in @%-name-% annotation',
    'Missing argument in annotation',
    'The annotation expects one argument, but the argument was not provided.');

const INVALID_ANNOTATION_ARGUMENT = const MessageTemplate(
    const MessageId('polymer', 35),
    'The parameter to @%-name-% seems to be invalid.',
    'Invalid argument in annotation',
    '''
The polymer transformer was not able to extract a constant value for the
annotation argument. This can happen if your code is currently in a state that
can't be analyzed (for example, it has parse errors) or if the expression passed
as an argument is invalid (for example, it is not a compile-time constant).
''');


const NO_INITIALIZATION = const MessageTemplate(
    const MessageId('polymer', 36),
    'No polymer initializers were found. Make sure to either '
    'annotate your polymer elements with @CustomTag or include a '
    'top level method annotated with @initMethod that registers your '
    'elements. Both annotations are defined in the polymer library ('
    'package:polymer/polymer.dart).',
    'No polymer initializers found',
    '''
No polymer initializers were found. Make sure to either 
annotate your polymer elements with @CustomTag or include a 
top level method annotated with @initMethod that registers your 
elements. Both annotations are defined in the polymer library (
package:polymer/polymer.dart).
''');

const AT_EXPRESSION_REMOVED = const MessageTemplate(
    const MessageId('polymer', 37),
    'event bindings with @ are no longer supported',
    'Event bindings with @ are no longer supported',
    '''
For a while there was an undocumented feature that allowed users to include
expressions in event bindings using the `@` prefix, for example:

    <div on-click="{{@a.b.c}}">
    
This feature is no longer supported.
''');

const NO_PRIVATE_EVENT_HANDLERS = const MessageTemplate(
    const MessageId('polymer', 38),
    'private symbols cannot be used in event handlers',
    'Private symbol in event handler',
    '''
Currently private members can't be used in event handler bindings. So you can't
write:

    <div on-click="{{_method}}">

This restriction might be removed in the future, but for now, you need to make
your event handlers public.
''');

const NO_PRIVATE_SYMBOLS_IN_BINDINGS = const MessageTemplate(
    const MessageId('polymer', 39),
    'private symbols are not supported',
    'Private symbol in binding expression',
    '''
Private members can't be used in binding expressions. For example, you can't
write:

    <div>{{a.b._c}}</div>
''');

const HTML5_WARNING = const MessageTemplate(
    const MessageId('polymer', 40),
    '(from html5lib) %-message-%',
    'A warning was found while parsing the HTML document',
    '''
The polymer transformer uses a parser that implements the HTML5 spec
(`html5lib`). This message reports a
warning that the parser detected.
''');

const POSSIBLE_FUOC = const MessageTemplate(
    const MessageId('polymer', 41),
    'Custom element found in document body without an '
    '"unresolved" attribute on it or one of its parents. This means '
    'your app probably has a flash of unstyled content before it '
    'finishes loading.',
    'Possible flash of unstyled content',
    '''
Custom element found in document body without an "unresolved" attribute on it or
one of its parents. This means your app probably has a flash of unstyled content
before it finishes loading. See <http://goo.gl/iN03Pj> for more info.
''');

const CSS_FILE_INLINED_MULTIPLE_TIMES = const MessageTemplate(
    const MessageId('polymer', 42),
    'The css file %-url-% was inlined multiple times.',
    'A css file was inlined multiple times.',
    '''
Css files are inlined by default, but if you import the same one in multiple
places you probably want to override this behavior to prevent duplicate code.
To do this, use the following pattern to update your pubspec.yaml:

    transformers:
    - polymer:
      inline_stylesheets:
        web/my_file.css: false

If you would like to hide this warning and keep it inlined, do the same thing
but assign the value to true.
'''
);

const DART_SUPPORT_NO_LONGER_REQUIRED = const MessageTemplate(
    const MessageId('polymer', 43),
    'No need to include "dart_support.js" by hand anymore.',
    '"dart_support.js" not necessary',
    '''
The script `packages/web_components/dart_support.js` is still used, but you no
longer need to put it in your application's entrypoint.

In the past this file served two purposes:

  * to make dart2js work well with the platform polyfills, and
  * to support registering Dart APIs for JavaScript custom elements.

Now, the code from `dart_support.js` is split in two halves. The half for
dart2js is now injected by the polymer transformers automatically during `pub
build`. The `web_components` package provides an HTML file containing the other
half.  Developers of packages that wrap JavaScript custom elements (like
`core_elements` and `paper_elements`) will import that file directly, so
application developers don't have to worry about it anymore.
'''
);
