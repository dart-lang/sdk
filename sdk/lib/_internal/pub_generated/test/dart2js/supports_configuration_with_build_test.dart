import 'dart:convert';
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration(
      "compiles dart.js and interop.js next to entrypoints when "
          "dartjs is explicitly configured",
      () {
    currentSchedule.timeout *= 3;
    serve([d.dir('api', [d.dir('packages', [d.file('browser', JSON.encode({
            'versions': [packageVersionApiMap(packageMap('browser', '1.0.0'))]
          })),
              d.dir(
                  'browser',
                  [
                      d.dir(
                          'versions',
                          [
                              d.file(
                                  '1.0.0',
                                  JSON.encode(
                                      packageVersionApiMap(packageMap('browser', '1.0.0'), full: true)))])])])]),
              d.dir(
                  'packages',
                  [
                      d.dir(
                          'browser',
                          [
                              d.dir(
                                  'versions',
                                  [
                                      d.tar(
                                          '1.0.0.tar.gz',
                                          [
                                              d.file('pubspec.yaml', yaml(packageMap("browser", "1.0.0"))),
                                              d.dir(
                                                  'lib',
                                                  [
                                                      d.file('dart.js', 'contents of dart.js'),
                                                      d.file('interop.js', 'contents of interop.js')])])])])])]);
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "browser": "1.0.0"
        },
        "transformers": [{
            "\$dart2js": {
              "minify": true
            }
          }]
      }),
          d.dir(
              'web',
              [d.file('file.dart', 'void main() => print("hello");')])]).create();
    pubGet();
    schedulePub(
        args: ["build"],
        output: new RegExp(r'Built 4 files to "build".'),
        exitCode: 0);
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'web',
                        [
                            d.matcherFile('file.dart.js', isMinifiedDart2JSOutput),
                            d.matcherFile('file.dart.precompiled.js', isNot(isEmpty)),
                            d.dir(
                                'packages',
                                [
                                    d.dir(
                                        'browser',
                                        [
                                            d.file('dart.js', 'contents of dart.js'),
                                            d.file('interop.js', 'contents of interop.js')])])])])]).validate();
  });
}
