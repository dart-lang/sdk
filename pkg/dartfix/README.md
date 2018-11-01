# dartfix

dartfix is a tool for migrating Dart source to newer versions of the Dart SDK,
and fixing common issues.

## Usage

To activate the package
```
  pub global activate dartfix
```

Once activated, dart fix can be run using
```
  pub global run dartfix:fix <target directory>
```
or if you have
[setup your path](https://www.dartlang.org/tools/pub/cmd/pub-global#running-a-script-from-your-path)
to include the pub bin directory, then simply
```
  dartfix <target directory>
```
