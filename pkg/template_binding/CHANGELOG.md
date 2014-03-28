# changelog

This file contains highlights of what changes on each version of the
template_binding package.

#### Pub version 0.10.0-pre.1.dev
  * Applied patch to throw errors asycnhronously if property path evaluation
    fails.
  * Applied patch matching commit [51df59][] (fix parser to avoid allocating
    PropertyPath if there is a non-null delegateFn).

#### Pub version 0.10.0-pre.0
  * Ported JS code as of commit [fcb7a5][] 

[fcb7a5]: https://github.com/Polymer/TemplateBinding/commit/fcb7a502794f19544f2d4b77c96eebb70830591d
[51df59]: https://github.com/Polymer/TemplateBinding/commit/51df59c16e0922dec041cfe604016aac00918d5d
