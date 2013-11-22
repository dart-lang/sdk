Barback is an asset build system. It is the library underlying
[pub](http://pub.dartlang.org/doc/)'s asset transformers in `pub build` and
`pub serve`.

Given a set of input files and a set of transformations (think compilers,
preprocessors and the like), it will automatically apply the appropriate
transforms and generate output files. When inputs are modified, it automatically
runs the transforms that are affected.

To learn more, see [here][].

[here]: http://pub.dartlang.org/doc/assets-and-transformers.html
