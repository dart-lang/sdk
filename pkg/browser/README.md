This package contains dart.js, and previously contained interop.js

dart.js
=======

The dart.js file is used in Dart browser apps to check for native Dart support
and either (a) bootstrap Dartium or (b) load compiled JS instead.  Previously,
we've recommended that you add a script tag pointing the version of dart.js in
our repository.  This doesn't work offline and also results in slower startup
(see [dartbug.com/6723](http://dartbug.com/6723)).

Instead, we now recommend that you install dart.js via the following steps:

1. Add the following to your pubspec.yaml:
  dependencies:
    browser: any

2. Run pub install.

3. Use a relative script tag in your html to the installed version:

    `<script src="packages/browser/dart.js"></script>`

If you do not wish to use pub, you may host a copy of this file locally instead.
In this case, you will need to update it yourself as necessary.  We reserve the
right to move the old file in the repository, so we no longer recommend linking
to it directly.

interop.js
==========

This script was required for dart:js interop to work, but it is no longer
needed. The functionality is now supported by dart:js directly.

If you previously had a script such as this, please remove it:

```html
<script src="packages/browser/interop.js"></script>
```
