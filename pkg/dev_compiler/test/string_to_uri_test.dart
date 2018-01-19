import 'dart:io';
import 'package:expect/minitest.dart';
import 'package:dev_compiler/src/kernel/command.dart';

main(List<String> args) {
  // Various URL schemes
  expect(stringToUri("dart:io").toString(), "dart:io");
  expect(stringToUri("package:expect/minitest.dart").toString(),
      "package:expect/minitest.dart");
  expect(stringToUri("foobar:whatnot").toString(), "foobar:whatnot");

  // Full Windows path
  expect(stringToUri("C:\\full\\windows\\path.foo", windows: true).toString(),
      "file:///C:/full/windows/path.foo");
  expect(stringToUri("C:/full/windows/path.foo", windows: true).toString(),
      "file:///C:/full/windows/path.foo");

  // Get current dir, making sure we use "/" and start with "/".
  String currentDir = Directory.current.path.replaceAll(r'\', r'/');
  if (!currentDir.startsWith(r'/')) currentDir = "/$currentDir";

  // Relative Windows path
  expect(stringToUri("partial\\windows\\path.foo", windows: true).toString(),
      "file://$currentDir/partial/windows/path.foo");

  // Full Unix path
  expect(stringToUri("/full/path/to/foo.bar", windows: false).toString(),
      "file:///full/path/to/foo.bar");

  // Relative Unix path
  expect(stringToUri("partial/path/to/foo.bar", windows: false).toString(),
      "file://$currentDir/partial/path/to/foo.bar");
}
