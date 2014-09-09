import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('errors if the constraint matches no versions', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.0.1");
    });
    schedulePub(args: ["global", "activate", "foo", ">1.1.0"], error: """
            Package foo has no versions that match >1.1.0 derived from:
            - pub global activate depends on version >1.1.0""",
        exitCode: exit_codes.DATA);
  });
}
