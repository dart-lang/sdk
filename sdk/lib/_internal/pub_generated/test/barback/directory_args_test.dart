import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  setUp(() {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir('bar', [d.file('file.txt', 'bar')]),
            d.dir('foo', [d.file('file.txt', 'foo')]),
            d.dir('test', [d.file('file.txt', 'test')]),
            d.dir('web', [d.file('file.txt', 'web')])]).create();
  });
  integration("builds only the given directories", () {
    schedulePub(
        args: ["build", "foo", "bar"],
        output: new RegExp(r'Built 2 files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir('bar', [d.file('file.txt', 'bar')]),
                    d.dir('foo', [d.file('file.txt', 'foo')]),
                    d.nothing('test'),
                    d.nothing('web')])]).validate();
  });
  integration("serves only the given directories", () {
    pubServe(args: ["foo", "bar"]);
    requestShouldSucceed("file.txt", "bar", root: "bar");
    requestShouldSucceed("file.txt", "foo", root: "foo");
    expectNotServed("test");
    expectNotServed("web");
    endPubServe();
  });
}
