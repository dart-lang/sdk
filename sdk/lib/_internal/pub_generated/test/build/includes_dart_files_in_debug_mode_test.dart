import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("includes Dart files in debug mode", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                'web',
                [
                    d.file('file1.dart', 'var main = () => print("hello");'),
                    d.file('file2.dart', 'void main(arg1, arg2, arg3) => print("hello");'),
                    d.file('file3.dart', 'class Foo { void main() => print("hello"); }'),
                    d.file('file4.dart', 'var foo;')])]).create();
    schedulePub(
        args: ["build", "--mode", "debug"],
        output: new RegExp(r'Built \d+ files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'web',
                        [
                            d.nothing('file1.dart.js'),
                            d.matcherFile('file1.dart', isNot(isEmpty)),
                            d.nothing('file2.dart.js'),
                            d.matcherFile('file2.dart', isNot(isEmpty)),
                            d.nothing('file3.dart.js'),
                            d.matcherFile('file3.dart', isNot(isEmpty)),
                            d.nothing('file4.dart.js'),
                            d.matcherFile('file4.dart', isNot(isEmpty))])])]).validate();
  });
}
