import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("cleans entire build directory before a build", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir('example', [d.file('file.txt', 'example')]),
            d.dir('test', [d.file('file.txt', 'test')])]).create();
    schedulePub(
        args: ["build", "example"],
        output: new RegExp(r'Built 1 file to "build".'));
    schedulePub(
        args: ["build", "test"],
        output: new RegExp(r'Built 1 file to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.nothing('example'),
                    d.dir('test', [d.file('file.txt', 'test')])])]).validate();
  });
}
