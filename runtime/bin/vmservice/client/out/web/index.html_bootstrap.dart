library app_bootstrap;

import 'package:polymer/polymer.dart';
import 'dart:mirrors' show currentMirrorSystem;

import 'package:observatory/src/observatory_elements/observatory_element.dart' as i0;
import 'package:observatory/src/observatory_elements/collapsible_content.dart' as i1;
import 'package:observatory/src/observatory_elements/error_view.dart' as i2;
import 'package:observatory/src/observatory_elements/isolate_summary.dart' as i3;
import 'package:observatory/src/observatory_elements/isolate_list.dart' as i4;
import 'package:observatory/src/observatory_elements/json_view.dart' as i5;
import 'package:observatory/src/observatory_elements/stack_trace.dart' as i6;
import 'package:observatory/src/observatory_elements/message_viewer.dart' as i7;
import 'package:observatory/src/observatory_elements/navigation_bar.dart' as i8;
import 'package:observatory/src/observatory_elements/response_viewer.dart' as i9;
import 'package:observatory/src/observatory_elements/observatory_application.dart' as i10;
import 'observatory_main.dart' as i11;

void main() {
  initPolymer([
      'package:observatory/src/observatory_elements/observatory_element.dart',
      'package:observatory/src/observatory_elements/collapsible_content.dart',
      'package:observatory/src/observatory_elements/error_view.dart',
      'package:observatory/src/observatory_elements/isolate_summary.dart',
      'package:observatory/src/observatory_elements/isolate_list.dart',
      'package:observatory/src/observatory_elements/json_view.dart',
      'package:observatory/src/observatory_elements/stack_trace.dart',
      'package:observatory/src/observatory_elements/message_viewer.dart',
      'package:observatory/src/observatory_elements/navigation_bar.dart',
      'package:observatory/src/observatory_elements/response_viewer.dart',
      'package:observatory/src/observatory_elements/observatory_application.dart',
      'observatory_main.dart',
    ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
}
