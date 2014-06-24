# changelog

This file contains highlights of what changes on each version of the
template_binding package.

#### Pub version 0.11.0
  * Ported up to commit [TemplateBinding#1cee02][5b9a3b] and
    [NodeBind#c47bc1][c47bc1].

#### Pub version 0.10.0
  * Applied patch to throw errors asycnhronously if property path evaluation
    fails.
  * Applied patch matching commit [51df59][] (fix parser to avoid allocating
    PropertyPath if there is a non-null delegateFn).
  * Ported up to commit [TemplateBinding#99e52d][99e52d] and
    [NodeBind#f7cc76][f7cc76].

[1cee02]: https://github.com/Polymer/TemplateBinding/commit/5b9a3be40682e1ccd5e6c0b04fbe2c54d74b5d1e
[c47bc1]: https://github.com/Polymer/NodeBind/commit/c47bc1b40d1cf0123b29620820a7111471e83ff3
[51df59]: https://github.com/Polymer/TemplateBinding/commit/51df59c16e0922dec041cfe604016aac00918d5d
[99e52d]: https://github.com/Polymer/TemplateBinding/commit/99e52dd7fbaefdaee9807648d1d6097eb3e99eda
[f7cc76]: https://github.com/Polymer/NodeBind/commit/f7cc76749e509e06fa7cbc9ba970f87f5fe33b5c
