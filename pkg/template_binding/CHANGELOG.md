#### Pub version 0.14.0
  * Up to date with release 0.5.1 ([TemplateBinding#d2bddc4][d2bddc4]).
  * The `js/patches_mdv.js` file is now named `js/flush.js`.

#### Pub version 0.13.1
  * Up to date with release 0.4.2 ([TemplateBinding#35b7880][35b7880]).
  * Widen web_components version constraint to include 0.9.0.

#### Pub version 0.13.0+1
  * Widen web_components version constraint.

#### Pub version 0.13.0
  * Up to date with [TemplateBinding#41e95ea][41e95ea] (release 0.4.0)
  * Using this package now requires some additional javascript polyfills, that
    were moved out of platform.js. These files are listed under lib/js, and all
    are required in addition to platform.js from the web_components package.

#### Pub version 0.12.1
  * Up to date with [TemplateBinding#6a2808c][6a2808c] (release 0.3.5)

#### Pub version 0.12.0+4
  * Widen the dependency constraint on `observe`.

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

[41e95ea]: https://github.com/Polymer/TemplateBinding/commit/41e95ea0e4b45543a29ea5240cd4f0defc7208c1
[35b7880]: https://github.com/Polymer/TemplateBinding/commit/35b78809b80b65f96466e30e8853b944b545303f
[d9f4543]: https://github.com/Polymer/TemplateBinding/commit/d9f4543dc06935824bfd43564c442b0897ce1c54
[5b9a3b]: https://github.com/Polymer/TemplateBinding/commit/5b9a3be40682e1ccd5e6c0b04fbe2c54d74b5d1e
[c47bc1]: https://github.com/Polymer/NodeBind/commit/c47bc1b40d1cf0123b29620820a7111471e83ff3
[51df59]: https://github.com/Polymer/TemplateBinding/commit/51df59c16e0922dec041cfe604016aac00918d5d
[99e52d]: https://github.com/Polymer/TemplateBinding/commit/99e52dd7fbaefdaee9807648d1d6097eb3e99eda
[f7cc76]: https://github.com/Polymer/NodeBind/commit/f7cc76749e509e06fa7cbc9ba970f87f5fe33b5c
