library app_bootstrap;

import 'package:polymer/polymer.dart';

import 'package:observatory/src/observatory_elements/observatory_element.dart' as i0;
import 'package:observatory/src/observatory_elements/class_view.dart' as i1;
import 'package:observatory/src/observatory_elements/disassembly_entry.dart' as i2;
import 'package:observatory/src/observatory_elements/code_view.dart' as i3;
import 'package:observatory/src/observatory_elements/collapsible_content.dart' as i4;
import 'package:observatory/src/observatory_elements/error_view.dart' as i5;
import 'package:observatory/src/observatory_elements/field_view.dart' as i6;
import 'package:observatory/src/observatory_elements/function_view.dart' as i7;
import 'package:observatory/src/observatory_elements/isolate_summary.dart' as i8;
import 'package:observatory/src/observatory_elements/isolate_list.dart' as i9;
import 'package:observatory/src/observatory_elements/json_view.dart' as i10;
import 'package:observatory/src/observatory_elements/library_view.dart' as i11;
import 'package:observatory/src/observatory_elements/stack_trace.dart' as i12;
import 'package:observatory/src/observatory_elements/message_viewer.dart' as i13;
import 'package:observatory/src/observatory_elements/navigation_bar.dart' as i14;
import 'package:observatory/src/observatory_elements/response_viewer.dart' as i15;
import 'package:observatory/src/observatory_elements/observatory_application.dart' as i16;
import 'index.html.0.dart' as i17;

void main() {
  configureForDeployment([
      'package:observatory/src/observatory_elements/observatory_element.dart',
      'package:observatory/src/observatory_elements/class_view.dart',
      'package:observatory/src/observatory_elements/disassembly_entry.dart',
      'package:observatory/src/observatory_elements/code_view.dart',
      'package:observatory/src/observatory_elements/collapsible_content.dart',
      'package:observatory/src/observatory_elements/error_view.dart',
      'package:observatory/src/observatory_elements/field_view.dart',
      'package:observatory/src/observatory_elements/function_view.dart',
      'package:observatory/src/observatory_elements/isolate_summary.dart',
      'package:observatory/src/observatory_elements/isolate_list.dart',
      'package:observatory/src/observatory_elements/json_view.dart',
      'package:observatory/src/observatory_elements/library_view.dart',
      'package:observatory/src/observatory_elements/stack_trace.dart',
      'package:observatory/src/observatory_elements/message_viewer.dart',
      'package:observatory/src/observatory_elements/navigation_bar.dart',
      'package:observatory/src/observatory_elements/response_viewer.dart',
      'package:observatory/src/observatory_elements/observatory_application.dart',
      'index.html.0.dart',
    ]);
  i17.main();
}
