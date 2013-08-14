library dom_compat_test;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:html5lib/dom.dart';

part 'dom_compat_test_definitions.dart';

main() {
  useCompactVMConfiguration();

  registerDomCompatTests();

  test('content_shell', () {
    _runDrt('test/browser/browser_test.html');
  });
}

void _runDrt(String htmlFile) {
  final allPassedRegExp = new RegExp('All \\d+ tests passed');

  final future = Process.run('content_shell', ['--dump-render-tree', htmlFile])
    .then((ProcessResult pr) {
      expect(pr.exitCode, 0);
      expect(pr.stdout, matches(allPassedRegExp), reason: pr.stdout);
    });

  expect(future, completion(isNull));
}
