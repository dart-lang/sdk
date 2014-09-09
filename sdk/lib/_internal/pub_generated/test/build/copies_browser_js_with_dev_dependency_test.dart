import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "compiles dart.js and interop.js next to entrypoints when "
          "browser is a dev dependency",
      () {
    currentSchedule.timeout *= 3;
    serveBrowserPackage();
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "browser": "any"
        }
      }),
          d.dir(
              'web',
              [d.file('file.dart', 'void main() => print("hello");')])]).create();
    pubGet();
    schedulePub(
        args: ["build", "--all"],
        output: new RegExp(r'Built 4 files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'web',
                        [
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
