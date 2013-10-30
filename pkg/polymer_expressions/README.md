polymer_expressions
===================


Polymer expressions are an expressive syntax that can be used in HTML templates
with Dart.

Templates are one feature of Polymer.dart, which is a set of comprehensive UI
and utility components for building web applications.
This package is automatically included with the
[Polymer](https://pub.dartlang.org/packages/polymer) package
because Polymer expressions are the default expression syntax
in Polymer Dart apps.
The [Polymer.dart homepage][home_page]
contains a list of features, project status,
installation instructions, tips for upgrading from Web UI,
and links to other documentation.


## Overview

Polymer expressions allow you to write complex binding expressions, with
property access, function invocation, list/map indexing, and two-way filtering
like:

```html
    {{ person.title + " " + person.getFullName() | upppercase }}
```

### Model-Driven Views (MDV)
[MDV][mdv] allows you to define templates directly in HTML that are rendered by
the browser into the DOM. Templates are bound to a data model, and changes to
the data are automatically reflected in the DOM, and changes in HTML inputs are
assigned back into the model. The template and model are bound together via
binding expressions that are evaluated against the model. These binding
expressions are placed in double-curly-braces, or "mustaches".

Example:

```html
    <template>
      <p>Hello {{ person.name }}</p>
    </template>
```

MDV includes a very basic binding syntax which only allows a series of
dot-separate property names.

[mdv]: http://www.polymer-project.org/platform/mdv.html

### Custom binding syntaxes with binding delegate

While MDV's built-in syntax is very basic, it does allow custom syntaxes called
"binding delegates" to be installed and used. A binding delegate can interpret
the contents of mustaches however it likes. PolymerExpressions is such a
binding delegate.

Example:

```html
    <template bind>
      <p>Hello {{ person.title + " " + person.getFullName() | uppercase }}</p>
    </template>
```

## Usage

### Installing from Pub

Add the following to your pubspec.yaml file:

```yaml
    dependencies:
      polymer_expressions: any
```

Hint: check https://pub.dartlang.org/packages/polymer_expressions for the latest
version number.

Then import polymer_expressions.dart:

    import 'package:polymer_expressions/polymer_expressions.dart';

### Registering a binding delegate

**Polymer Expressions are now the default syntax for `<polymer-element>` custom
elements.**

You do not need to manually register the bindingDelegate if your bindings are
inside a custom element. However, if you want to use polymer_expressions outside
a custom element, read on:

Binding delegates must be installed on a template before they can be used.
For example, set the bindingDelegate property of your template
elements to an instance of PolymerExpressions. The templates will then use the
PolymerExpressions instance to interpret
binding expressions.

```dart
    import 'dart:html';
    import 'package:polymer_expressions/polymer_expressions.dart';

    main() {
      var template = query('#my_template');
      template.bindingDelegate = new PolymerExpressions();
    }
```

### Registering top-level variables

Before a top-level variable can be used, it must be registered. The
PolymerExpressions constructor takes a map of named values to use as variables.

```dart
    main() {
      var globals = {
        'uppercase': (String v) => v.toUpperCase(),
        'app_id': 'my_app_123',
      };
      var template = query('#my_template');
      template.bindingDelegate = new PolymerExpressions(globals: globals);
    }
```

## Features

### The model and scope

Polymer Expressions allow binding to more than just the model assigned to a
template instance. Top-level variables can be defined so that you can use
filters, global variables and constants, functions, etc. These variables and the
model are held together in a container called a Scope. Scopes can be nested,
which happens when template tags are nested.

### Two-way bindings

Bindings can be used to modify the data model based on events in the DOM. The
most common case is to bind an &lt;input&gt; element's value field to a model
property and have the property update when the input changes. For this to work,
the binding expression must be "assignable". Only a subset of expressions are
assignable. Assignable expressions cannot contain function calls, operators, and
any index operator must have a literal argument. Assignable expressions can
contain filter operators as long as all the filters are two-way transformers.

Some restrictions may be relaxed further as allowed.

Assignable Expressions:

 * `foo`
 * `foo.bar`
 * `items[0].description`
 * `people['john'].name`
 * `product.cost | convertCurrency('ZWD')` where `convertCurrency` evaluates to
   a Tranformer object.

Non-Assignable Expressions:

 * `a + 1`
 * `!c`
 * `foo()`
 * `person.lastName | uppercase` where `uppercase` is a filter function.

### Null-Safety

Expressions are generally null-safe. If an intermediate expression yields `null`
the entire expression will return null, rather than throwing an exception.
Property access, method invocation and operators are null-safe. Passing null to
a function that doesn't handle null will not be null safe.

### Streams

Polymer Expressions have experimental support for binding to streams, and when
new values are passed to the stream, the template updates. The feature is not
fully implemented yet.

See the examples in /example/streams for more details.

## Syntax

### Property access

Properties on the model and in the scope are looked up via simple property
names, like `foo`. Property names are looked up first in the top-level
variables, next in the model, then recursively in parent scopes. Properties on
objects can be access with dot notation like `foo.bar`.

The keyword `this` always refers to the model if there is one, otherwise `this`
is `null`. If you have model properties and top-level variables with the same
name, you can use `this` to refer to the model property.

### Literals

Polymer Expressions support number, boolean, string, and map literals. Strings
can use either single or double quotes.

 * Numbers: `1`, `1.0`
 * Booleans: `true`, `false`
 * Strings: `'abc'`, `"xyz"`
 * Maps: `{ 'a': 1, 'b': 2 }`

List literals are planned, see [issue 9](https://github.com/dart-lang/polymer_expressions/issues/9)

### Functions and methods

If a property is a function in the scope, a method on the model, or a method on
an object, it can be invoked with standard function syntax. Functions and
Methods can take arguments. Named arguments are not supported. Arguments can be
literals or variables.

Examples:

 * Top-level function: `myFunction()`
 * Top-level function with arguments: `myFunction(a, b, 42)`
 * Model method: `aMethod()`
 * Method on nested-property: `a.b.anotherMethod()`

### Operators

Polymer Expressions supports the following binary and unary operators:

 * Arithmetic operators: +, -, *, /, %, unary + and -
 * Comparison operators: ==, !=, <=, <, >, >=
 * Boolean operators: &&, ||, unary !

Expressions do not support bitwise operators such as &, |, << and >>, or increment/decrement operators (++ and --)

### List and Map indexing

List and Map like objects can be accessed via the index operator: []

Examples:

 * `items[2]`
 * `people['john']`

Unlike JavaScript, list and map contents are not generally available via
property access. That is, the previous examples are not equivalent to `items.2`
and `people.john`. This ensures that access to properties and methods on Lists
and Maps is preserved.

### Filters and transformers

A filter is a function that transforms a value into another, used via the pipe
syntax: `value | filter` Any function that takes exactly one argument can be
used as a filter.

Example:

If `person.name` is "John", and a top-level function named `uppercase` has been
registered, then `person.name | uppercase` will have the value "JOHN".

The pipe syntax is used rather than a regular function call so that we can
support two-way bindings through transformers. A transformer is a filter that
has an inverse function. Transformers must extend or implement the `Transformer`
class, which has `forward()` and `reverse()` methods.

### Repeating templates

A template can be repeated by using the "repeat" attribute with a binding. The
binding can either evaluate to an Iterable, in which case the template is
instantiated for each item in the iterable and the model of the instance is
set to the item, or the binding can be a "in" iterator expression, in which
case a new variable is added to each scope.

The following examples produce the same output.

Evaluate to an iterable:

```html
    <template repeat="{{ items }}">
      <div>{{ }}</div>
    </template>
```

"in" expression:

```html
    <template repeat="{{ item in items }}">
      <div>{{ item }}</div>
    </template>
```

## Status

The syntax implemented is experimental and subject to change, in fact, it
**will** change soon. The goal is to be compatible with Polymer's binding
syntax. We will announce breaking changes on the
[web-ui@dartlang.org mailing list][web-ui-list].

Please [file issues on Dart project page](http://dartbug.com/new)
for any bugs you find or for feature requests. Make a note that it applies to
"package:polymer_expressions"

You can discuss Polymer Expressions on the
[web-ui@dartlang.org mailing list][web-ui-list].

[web-ui-list]: https://groups.google.com/a/dartlang.org/forum/#!forum/web-ui
