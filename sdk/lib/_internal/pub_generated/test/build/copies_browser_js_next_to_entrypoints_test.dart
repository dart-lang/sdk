import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("compiles dart.js and interop.js next to entrypoints", () {
    currentSchedule.timeout *= 3;
    serveBrowserPackage();
    d.dir(appPath, [d.appPubspec({
        "browser": "1.0.0"
      }),
          d.dir(
              'foo',
              [
                  d.file('file.dart', 'void main() => print("hello");'),
                  d.dir(
                      'subdir',
                      [d.file('subfile.dart', 'void main() => print("subhello");')])]),
          d.dir(
              'web',
              [
                  d.file('file.dart', 'void main() => print("hello");'),
                  d.dir(
                      'subweb',
                      [d.file('subfile.dart', 'void main() => print("subhello");')])])]).create();
    pubGet();
    schedulePub(
        args: ["build", "foo", "web"],
        output: new RegExp(r'Built 16 files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'foo',
                        [
                            d.matcherFile('file.dart.js', isNot(isEmpty)),
                            d.matcherFile('file.dart.precompiled.js', isNot(isEmpty)),
                            d.dir(
                                'packages',
                                [
                                    d.dir(
                                        'browser',
                                        [
                                            d.file('dart.js', 'contents of dart.js'),
                                            d.file('interop.js', 'contents of interop.js')])]),
                            d.dir(
                                'subdir',
                                [
                                    d.dir(
                                        'packages',
                                        [
                                            d.dir(
                                                'browser',
                                                [
                                                    d.file('dart.js', 'contents of dart.js'),
                                                    d.file('interop.js', 'contents of interop.js')])]),
                                    d.matcherFile('subfile.dart.js', isNot(isEmpty)),
                                    d.matcherFile('subfile.dart.precompiled.js', isNot(isEmpty))])]),
                    d.dir(
                        'web',
                        [
                            d.matcherFile('file.dart.js', isNot(isEmpty)),
                            d.matcherFile('file.dart.precompiled.js', isNot(isEmpty)),
                            d.dir(
                                'packages',
                                [
                                    d.dir(
                                        'browser',
                                        [
                                            d.file('dart.js', 'contents of dart.js'),
                                            d.file('interop.js', 'contents of interop.js')])]),
                            d.dir(
                                'subweb',
                                [
                                    d.dir(
                                        'packages',
                                        [
                                            d.dir(
                                                'browser',
                                                [
                                                    d.file('dart.js', 'contents of dart.js'),
                                                    d.file('interop.js', 'contents of interop.js')])]),
                                    d.matcherFile('subfile.dart.js', isNot(isEmpty)),
                                    d.matcherFile('subfile.dart.precompiled.js', isNot(isEmpty))])])])]).validate();
  });
}
