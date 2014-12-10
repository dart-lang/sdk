# Web Components

This package has the polyfills for
[Shadow DOM](http://www.polymer-project.org/platform/shadow-dom.html),
[Custom Elements](http://www.polymer-project.org/platform/custom-elements.html),
and [HTML Imports](http://www.polymer-project.org/platform/html-imports.html).

These features exist in dart:html, for example
[Element.reateShadowRoot](https://api.dartlang.org/apidocs/channels/stable/#dart-dom-html.Element@id_createShadowRoot)
and [Document.register](https://api.dartlang.org/apidocs/channels/stable/#dart-dom-html.HtmlDocument@id_register).
However those APIs are not supported on all browsers yet unless you
load the polyfills, as indicated below.

## Getting started

Include the polyfills in your HTML `<head>` to enable Shadow DOM:

```html
<script src="packages/web_components/webcomponents.min.js"></script>
<script src="packages/web_components/dart_support.js"></script>
```

You can also use an unminified version for development:

```html
<script src="packages/web_components/webcomponents.js"></script>
<script src="packages/web_components/dart_support.js"></script>
```

Because the Shadow DOM polyfill does extensive DOM patching, webcomponents.js
should be included **before** other script tags. Be sure to include
dart_support.js too, it is required for the Shadow DOM polyfill to work with
[dart2js](https://www.dartlang.org/docs/dart-up-and-running/contents/ch04-tools-dart2js.html).

## Custom Elements

Custom Elements let authors define their own elements. Authors associate
JavaScript or Dart code with custom tag names, and then use those custom tag
names as they would any standard tag.

For example, after registering a special kind of button called `super-button`,
use the super button just like this:

```html
<super-button></super-button>
```

Custom elements are still elements. We can create, use, manipulate, and compose
them just as easily as any standard `<div>` or `<span>` today.

See the Polymer [Custom Elements page](http://www.polymer-project.org/platform/custom-elements.html)
for more information.

## Shadow DOM

Shadow DOM is designed to provide encapsulation by hiding DOM subtrees under
shadow roots. It provides a method of establishing and maintaining functional
boundaries between DOM trees and how these trees interact with each other within
a document, thus enabling better functional encapsulation within the DOM.

See the Polymer [Shadow DOM page](http://www.polymer-project.org/platform/shadow-dom.html)
for more information.


## Hacking on this package

The `webcomponents.*` files in this package are developed 
[here](https://github.com/Polymer/webcomponentsjs). Follow the instructions
there for how to build a new release and then copy the files into this package.
