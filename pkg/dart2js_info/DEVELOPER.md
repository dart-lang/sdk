# Notes for developers

## Developing locally together with dart2js:

* Use a path dependency on this repo to prepare changes.

## Submitting changes.

* Submit changes in this repo first.
* Update the sdk/DEPS and sdk/tools/deps/dartium.deps/DEPS to use the latest
  hash of this repo.
* Submit dart2js changes together with the roll in DEPS.

## Updating the dart2js\_info dart docs

We use `dartdoc` and host the generated documentation as a [github page][1] in
this repo. Here is how to update it:

* Make sure you have the dartdoc tool installed:

```
pub global activate dartdoc
```

* Run the dartdoc tool on the root of the repo in master, specify an out
  directory different than `doc`:

```sh
dartdoc --output _docs
```

* Switch to the `gh-pages` branch:

```
git checkout gh-pages
git pull
```

* Override the existing docs by hand:

```
rm -r doc/api
mv _docs doc/api
git diff # validate changes look right
git commit -a -m "Update documentation ... "
```

* Update the gh-pages branch in the server
```
git push origin gh-pages
```


[1]: http://dart-lang.github.io/dart2js_info/doc/api/dart2js_info.info/AllInfo-class.html
