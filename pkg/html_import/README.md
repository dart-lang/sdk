# HTML Imports polyfill

[HTML Imports][1] are a way to include and reuse HTML documents in other HTML
documents. As `<script>` tags let authors include external Javascript in their
pages, imports let authors load full HTML resources.  In particular, imports let
authors include [Custom Element](https://github.com/Polymer/CustomElements)
definitions from external URLs.


## Getting Started

Include the `html_import.debug.js` or `html_import.min.js` (minified) file in
your project.

    <script src="packages/html_import/html_import.debug.js"></script>

`html_import.debug.js` is the debug loader and uses `document.write` to load
additional modules.

Use the minified version (`html_import.min.js`) if you need to load the file
dynamically.

## Basic usage

For HTML imports use the `import` relation on a standard `<link>` tag, for
example:

    <link rel="import" href="import-file.html">

## Polyfill details

You can read more about how the polyfill is implemented in JavaScript here:
<https://github.com/Polymer/HTMLImports/tree/master#polyfill-details>

## Getting the source code

This package is built from:
<https://github.com/Polymer/HTMLImports/tree/master>

You'll need [node.js](http://nodejs.org) to rebuild the JS file. Use
`npm install` to get dependencies and `grunt` to build.

[1]: https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/imports/index.html
