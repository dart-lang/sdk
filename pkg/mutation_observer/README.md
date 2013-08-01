# Mutation Observers polyfill

Mutation Observers provide a way to react to changes in the DOM. This is needed
on IE versions 9 and 10, see <http://caniuse.com/mutationobserver>.

## More information

* [API documentation](http://api.dartlang.org/docs/bleeding_edge/dart_html/MutationObserver.html)
* [Mozilla Developer Network page](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver)
* [Specification](https://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#mutation-observers)

## Getting started

Include the polyfill in your HTML `<head>`:

```html
    <script src="packages/mutation_observer/mutation_observer.js"></script>
```

You can also use a minified version for deployment:

```html
    <script src="packages/mutation_observer/mutation_observer.min.js"></script>
```

## Getting the source code

The source for this package is at:
<https://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/pkg/mutation_observer/>

The original source of the JavaScript code is at:
<https://github.com/Polymer/MutationObservers/tree/master>

## Building

The minified version is produced with:

```bash
    uglifyjs mutation_observer.js -o mutation_observer.min.js
```

See <https://github.com/mishoo/UglifyJS2> for usage of UglifyJS.
