# Shadow DOM polyfill

Shadow DOM is designed to provide encapsulation by hiding DOM subtrees under
shadow roots. It provides a method of establishing and maintaining functional
boundaries between DOM trees and how these trees interact with each other within
a document, thus enabling better functional encapsulation within the DOM. See
the
[W3C specification](https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html)
for details.

## Getting started

Include the polyfill in your HTML `<head>` to enable Shadow DOM:

```html
    <script src="packages/shadow_dom/shadow_dom.debug.js"></script>
```

You can also use a minified version for deployment:

```html
    <script src="packages/shadow_dom/shadow_dom.min.js"></script>
```

Because it does extensive DOM patching, it should be included **before** other
script tags.

## Useful Resources

- [What the Heck is Shadow DOM?](http://glazkov.com/2011/01/14/what-the-heck-is-shadow-dom/)
- [Web Components Explained - Shadow DOM](https://dvcs.w3.org/hg/webcomponents/raw-file/57f8cfc4a7dc/explainer/index.html#shadow-dom-section)
- [HTML5Rocks - Shadow DOM 101](http://www.html5rocks.com/tutorials/webcomponents/shadowdom/)
- [HTML5Rocks - Shadow DOM 201: CSS and Styling](http://www.html5rocks.com/tutorials/webcomponents/shadowdom-201/)
- [HTML5Rocks - Shadow DOM 301: Advanced Concepts & DOM APIs](http://www.html5rocks.com/tutorials/webcomponents/shadowdom-301/)

## Learn the tech

### Basic usage

```dart
var el = new DivElement();
var shadow = el.createShadowRoot();
shadow.innerHtml = '<content select="h1"></content>';
```

### Shadow DOM subtrees

Shadow DOM allows a single node to express three subtrees: _light DOM_, _shadow DOM_, and _composed DOM_.

A component user supplies the light DOM; the node has a (hidden) shadow DOM; and the composed DOM is what is actually rendered in the browser. At render time, the light DOM is merged with the shadow DOM to produce the composed DOM. For example:

**Light DOM**

```html
<my-custom-element>
  <!-- everything in here is my-custom-element's light DOM -->
  <q>Hello World</q>
</my-custom-element>
```

**Shadow DOM**

```html
<!-- shadow-root is attached to my-custom-element, but is not a child -->
<shadow-root>
  <!-- everything in here is my-custom-element's shadow DOM -->
  <span>People say: <content></content></span>
</shadow-root>
```

**Composed (rendered) DOM**

```html
<!-- rendered DOM -->
<my-custom-element>
  <span>People say: <q>Hello World</q></span>
</my-custom-element>
```

The following is true about this example:

* The light DOM that belongs to `<my-custom-element>` is visible to the user as its normal subtree. It can expressed by `.childNodes`, `.nodes`, `.innerHtml` or any other property or method that gives you information about a node's subtree.
* Nodes in light DOM or shadow DOM express parent and sibling relationships that match their respective tree structures; the relationships that exist in the rendered tree are not expressed anywhere in DOM.

So, while in the final rendered tree `<span>` is a child of `<my-custom-element>` and the parent of `<q>`, interrogating those nodes will tell you that the `<span>` is a child of `<shadow-root>` and `<q>` is a child of `<my-custom-element>`, and that those two nodes are unrelated.

In this way, the user can manipulate light DOM or shadow DOM directly as regular DOM subtrees, and let the system take care of keeping the render tree synchronized.

## Polyfill details

You can read more about how the polyfill is implemented in JavaScript here:
<https://github.com/polymer/ShadowDOM#polyfill-details>.

## Getting the source code

This package is built from:
<https://github.com/dart-lang/ShadowDOM/tree/conditional_shadowdom>

You'll need [node.js](http://nodejs.org) to rebuild the JS file. Use `npm install` to
get dependencies and `grunt` to build.
