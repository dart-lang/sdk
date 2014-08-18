# changelog

This file contains highlights of what changes on each version of the
template_binding package.

#### Pub version 0.12.1
  * Up to date with [TemplateBinding#6a2808][6a2808] (release 0.3.5)

#### Pub version 0.12.0+3
  * fix bug in interop layer to ensure callbacks are run in the dirty-checking
    zone (this only affected running code directly in Dartium without running
    pub-build or pub-serve)

#### Pub version 0.12.0
  * NodeBind interop support. This allows elements such as Polymer's
    core-elements and paper-elements to work properly with Dart binding paths,
    including using Elements and functions as values, and two-way bindings.
  * NodeBind is no longer ported. It now comes from
    packages/web_components/platform.js
  * Up to date with [TemplateBinding#d9f4543][d9f4543] (release 0.3.4)

#### Pub version 0.11.0
  * Ported up to commit [TemplateBinding#5b9a3b][5b9a3b] and
    [NodeBind#c47bc1][c47bc1].

#### Pub version 0.10.0
  * Applied patch to throw errors asynchronously if property path evaluation
    fails.
  * Applied patch matching commit [51df59][] (fix parser to avoid allocating
    PropertyPath if there is a non-null delegateFn).
  * Ported up to commit [TemplateBinding#99e52d][99e52d] and
    [NodeBind#f7cc76][f7cc76].

[d9f4543]: https://github.com/Polymer/TemplateBinding/commit/d9f4543dc06935824bfd43564c442b0897ce1c54
[5b9a3b]: https://github.com/Polymer/TemplateBinding/commit/5b9a3be40682e1ccd5e6c0b04fbe2c54d74b5d1e
[c47bc1]: https://github.com/Polymer/NodeBind/commit/c47bc1b40d1cf0123b29620820a7111471e83ff3
[51df59]: https://github.com/Polymer/TemplateBinding/commit/51df59c16e0922dec041cfe604016aac00918d5d
[99e52d]: https://github.com/Polymer/TemplateBinding/commit/99e52dd7fbaefdaee9807648d1d6097eb3e99eda
[f7cc76]: https://github.com/Polymer/NodeBind/commit/f7cc76749e509e06fa7cbc9ba970f87f5fe33b5c
