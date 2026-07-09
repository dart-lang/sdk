// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:web/web.dart';

import '../../../models.dart' as M;
import '../class_ref.dart';
import '../code_ref.dart';
import '../context_ref.dart';
import '../error_ref.dart';
import '../field_ref.dart';
import '../function_ref.dart';
import 'rendering_scheduler.dart';
import 'uris.dart';
import '../icdata_ref.dart';
import '../instance_ref.dart';
import '../library_ref.dart';
import '../local_var_descriptors_ref.dart';
import '../megamorphiccache_ref.dart';
import '../objectpool_ref.dart';
import '../pc_descriptors_ref.dart';
import '../script_ref.dart';
import '../sentinel_value.dart';
import '../singletargetcache_ref.dart';
import '../subtypetestcache_ref.dart';
import '../type_arguments_ref.dart';
import '../unknown_ref.dart';
import '../unlinkedcall_ref.dart';

HTMLElement anyRef(
  M.IsolateRef isolate,
  ref,
  M.ObjectRepository objects, {
  RenderingQueue? queue,
  bool expandable = true,
}) {
  if (ref == null) {
    return new HTMLSpanElement()..textContent = "???";
  }
  if (ref is M.Guarded) {
    if (ref.isSentinel) {
      return anyRef(
        isolate,
        ref.asSentinel,
        objects,
        queue: queue,
        expandable: expandable,
      );
    } else {
      return anyRef(
        isolate,
        ref.asValue,
        objects,
        queue: queue,
        expandable: expandable,
      );
    }
  } else if (ref is M.ObjectRef) {
    if (ref is M.ClassRef) {
      return new ClassRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.CodeRef) {
      return new CodeRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.ContextRef) {
      return new ContextRefElement(
        isolate,
        ref,
        objects,
        queue: queue,
        expandable: expandable,
      ).element;
    } else if (ref is M.Error) {
      return new ErrorRefElement(ref, queue: queue).element;
    } else if (ref is M.FieldRef) {
      return new FieldRefElement(
        isolate,
        ref,
        objects,
        queue: queue,
        expandable: expandable,
      ).element;
    } else if (ref is M.FunctionRef) {
      return new FunctionRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.ICDataRef) {
      return new ICDataRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.InstanceRef) {
      return new InstanceRefElement(
        isolate,
        ref,
        objects,
        queue: queue,
        expandable: expandable,
      ).element;
    } else if (ref is M.LibraryRef) {
      return new LibraryRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.LocalVarDescriptorsRef) {
      return new LocalVarDescriptorsRefElement(
        isolate,
        ref,
        queue: queue,
      ).element;
    } else if (ref is M.MegamorphicCacheRef) {
      return new MegamorphicCacheRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.ObjectPoolRef) {
      return new ObjectPoolRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.PcDescriptorsRef) {
      return new PcDescriptorsRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.ScriptRef) {
      return new ScriptRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.SingleTargetCacheRef) {
      return new SingleTargetCacheRefElement(
        isolate,
        ref,
        queue: queue,
      ).element;
    } else if (ref is M.SubtypeTestCacheRef) {
      return new SubtypeTestCacheRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.TypeArgumentsRef) {
      return new TypeArgumentsRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.UnknownObjectRef) {
      return new UnknownObjectRefElement(isolate, ref, queue: queue).element;
    } else if (ref is M.UnlinkedCallRef) {
      return new UnlinkedCallRefElement(isolate, ref, queue: queue).element;
    } else {
      return new HTMLAnchorElement()
        ..href = Uris.inspect(isolate, object: ref)
        ..text = 'object';
    }
  } else if (ref is M.Sentinel) {
    return new SentinelValueElement(ref, queue: queue).element;
  } else if (ref is num || ref is String) {
    return new HTMLSpanElement()..textContent = ref.toString();
  }
  throw new Exception('Unknown ref type (${ref.runtimeType})');
}
