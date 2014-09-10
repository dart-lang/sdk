import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("compiles Dart entrypoints in root package to JS", () {
    currentSchedule.timeout *= 3;
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                'benchmark',
                [
                    d.file('file.dart', 'void main() => print("hello");'),
                    d.file('lib.dart', 'void foo() => print("hello");'),
                    d.dir('subdir', [d.file('subfile.dart', 'void main() => print("ping");')])]),
            d.dir(
                'foo',
                [
                    d.file('file.dart', 'void main() => print("hello");'),
                    d.file('lib.dart', 'void foo() => print("hello");'),
                    d.dir('subdir', [d.file('subfile.dart', 'void main() => print("ping");')])]),
            d.dir(
                'web',
                [
                    d.file('file.dart', 'void main() => print("hello");'),
                    d.file('lib.dart', 'void foo() => print("hello");'),
                    d.dir(
                        'subdir',
                        [d.file('subfile.dart', 'void main() => print("ping");')])])]).create();
    schedulePub(
        args: ["build", "benchmark", "foo", "web"],
        output: new RegExp(r'Built 12 files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'benchmark',
                        [
                            d.matcherFile('file.dart.js', isNot(isEmpty)),
                            d.matcherFile('file.dart.precompiled.js', isNot(isEmpty)),
                            d.nothing('file.dart'),
                            d.nothing('lib.dart'),
                            d.dir(
                                'subdir',
                                [
                                    d.matcherFile('subfile.dart.js', isNot(isEmpty)),
                                    d.matcherFile('subfile.dart.precompiled.js', isNot(isEmpty)),
                                    d.nothing('subfile.dart')])]),
                    d.dir(
                        'foo',
                        [
                            d.matcherFile('file.dart.js', isNot(isEmpty)),
                            d.matcherFile('file.dart.precompiled.js', isNot(isEmpty)),
                            d.nothing('file.dart'),
                            d.nothing('lib.dart'),
                            d.dir(
                                'subdir',
                                [
                                    d.matcherFile('subfile.dart.js', isNot(isEmpty)),
                                    d.matcherFile('subfile.dart.precompiled.js', isNot(isEmpty)),
                                    d.nothing('subfile.dart')])]),
                    d.dir(
                        'web',
                        [
                            d.matcherFile('file.dart.js', isNot(isEmpty)),
                            d.matcherFile('file.dart.precompiled.js', isNot(isEmpty)),
                            d.nothing('file.dart'),
                            d.nothing('lib.dart'),
                            d.dir(
                                'subdir',
                                [
                                    d.matcherFile('subfile.dart.js', isNot(isEmpty)),
                                    d.matcherFile('subfile.dart.precompiled.js', isNot(isEmpty)),
                                    d.nothing('subfile.dart')])])])]).validate();
  });
}
