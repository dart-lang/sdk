library dom_compat_test;

import 'dart:html';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

part '../dom_compat_test_definitions.dart';

main() {
  groupSep = ' - ';
  useHtmlConfiguration();

  registerDomCompatTests();
}
