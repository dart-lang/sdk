// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library repositories;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:observatory/allocation_profile.dart';
import 'package:observatory/sample_profile.dart';
import 'package:observatory/heap_snapshot.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart' as S;
import 'package:observatory/service_common.dart' as SC;
import 'package:observatory/service_html.dart' as SH;

part 'src/repositories/allocation_profile.dart';
part 'src/repositories/breakpoint.dart';
part 'src/repositories/class.dart';
part 'src/repositories/context.dart';
part 'src/repositories/editor.dart';
part 'src/repositories/eval.dart';
part 'src/repositories/event.dart';
part 'src/repositories/field.dart';
part 'src/repositories/flag.dart';
part 'src/repositories/function.dart';
part 'src/repositories/heap_snapshot.dart';
part 'src/repositories/icdata.dart';
part 'src/repositories/inbound_references.dart';
part 'src/repositories/instance.dart';
part 'src/repositories/isolate.dart';
part 'src/repositories/library.dart';
part 'src/repositories/megamorphiccache.dart';
part 'src/repositories/metric.dart';
part 'src/repositories/notification.dart';
part 'src/repositories/object.dart';
part 'src/repositories/objectpool.dart';
part 'src/repositories/objectstore.dart';
part 'src/repositories/persistent_handles.dart';
part 'src/repositories/ports.dart';
part 'src/repositories/reachable_size.dart';
part 'src/repositories/retained_size.dart';
part 'src/repositories/retaining_path.dart';
part 'src/repositories/sample_profile.dart';
part 'src/repositories/script.dart';
part 'src/repositories/settings.dart';
part 'src/repositories/single_target_cache.dart';
part 'src/repositories/strongly_reachable_instances.dart';
part 'src/repositories/subtype_test_cache.dart';
part 'src/repositories/target.dart';
part 'src/repositories/timeline.dart';
part 'src/repositories/top_retaining_instances.dart';
part 'src/repositories/type_arguments.dart';
part 'src/repositories/unlinked_call.dart';
part 'src/repositories/vm.dart';
