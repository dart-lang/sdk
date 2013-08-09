import "message_extraction_test.dart";
import "dart:io";
import "package:unittest/unittest.dart";

main() {
  run(null, ["extract_to_json.dart",
      "sample_with_messages.dart", "part_of_sample_with_messages.dart"])
    .then((ProcessResult result) {
      expect(result.exitCode, 0);
  });
  run(null, ["extract_to_json.dart", "--warnings-are-errors",
      "sample_with_messages.dart", "part_of_sample_with_messages.dart"])
    .then((ProcessResult result) {
      expect(result.exitCode, 1);
    });
}