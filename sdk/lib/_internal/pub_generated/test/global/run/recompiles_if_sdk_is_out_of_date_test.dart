import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('recompiles a script if the SDK version is out-of-date', () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok');")])]);
    });
    schedulePub(args: ["global", "activate", "foo"]);
    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.dir(
                        'foo',
                        [d.dir('bin', [d.outOfDateSnapshot('script.dart.snapshot')])])])]).create();
    var pub = pubRun(global: true, args: ["foo:script"]);
    pub.stdout.expect("Precompiling executables...");
    pub.stdout.expect(consumeThrough("ok"));
    pub.shouldExit();
    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.dir(
                        'foo',
                        [
                            d.dir(
                                'bin',
                                [d.matcherFile('script.dart.snapshot', contains('ok'))])])])]).validate();
  });
}
