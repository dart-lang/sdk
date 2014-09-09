import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("copies non-Dart files to build/", () {
    servePackages((builder) => builder.serve("browser", "1.0.0"));
    d.dir(appPath, [d.appPubspec({
        "browser": "1.0.0"
      }),
          d.dir(
              'web',
              [
                  d.file('file.txt', 'contents'),
                  d.dir('subdir', [d.file('subfile.txt', 'subcontents')])])]).create();
    schedulePub(
        args: ["build"],
        output: new RegExp(r'Built 2 files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'web',
                        [
                            d.nothing('packages'),
                            d.file('file.txt', 'contents'),
                            d.dir('subdir', [d.file('subfile.txt', 'subcontents')])])])]).validate();
  });
}
