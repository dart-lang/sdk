# Publish instructions for Dart Dev Compiler

There are the steps for developers on the Dart Dev Compiler team to publish a new version to pub.  The edit steps can be done directly on github if preferred.

## Obtain permission

If you have not uploaded before, you may need to ask [an existing uploader](https://pub.dartlang.org/packages/dev_compiler) to grant you permission.  They'll need to run:

```
> pub uploader add <your-email-address>
```

## Update the version number

Update the following files with the new version number:

  - [pubspec.yaml](https://github.com/dart-lang/dev_compiler/blob/master/pubspec.yaml)
  - [package.json](https://github.com/dart-lang/dev_compiler/blob/master/package.json)
  - [lib/devc.dart](https://github.com/dart-lang/dev_compiler/blob/master/lib/devc.dart) (see the devCompilerVersion constant)

## Update the Changelog

Update [CHANGELOG.md](https://github.com/dart-lang/dev_compiler/blob/master/CHANGELOG.md) with notable changes since the last release.

## Update your local master

Make sure the above is committed to github master.  Make sure you have those updates in your local master:

```
> git pull
```

## Tag the new version locally

```
> git tag <new-version-number> # E.g., git tag 0.1.14
```

## Push the tag

```
> git push --tags
```

Check the [github site](https://github.com/dart-lang/dev_compiler) to make sure the tag appears there under the `Branch` button.

## Publish the new version to pub

```
> pub lish
```

Check [pub.dartlang.org](https://pub.dartlang.org/packages/dev_compiler) to ensure the latest DDC is there.
