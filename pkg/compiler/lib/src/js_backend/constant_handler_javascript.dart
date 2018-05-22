// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compile_time_constants.dart';
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constant_system_dart.dart';
import '../elements/entities.dart';
import 'constant_system_javascript.dart';

/// [ConstantCompilerTask] for compilation of constants for the JavaScript
/// backend.
///
/// Since this task needs to distinguish between frontend and backend constants
/// the actual compilation of the constants is forwarded to a
/// [DartConstantCompiler] for the frontend interpretation of the constants and
/// to a [JavaScriptConstantCompiler] for the backend interpretation.
class JavaScriptConstantTask extends ConstantCompilerTask {
  ConstantSystem dartConstantSystem;
  JavaScriptConstantCompiler jsConstantCompiler;

  JavaScriptConstantTask(Compiler compiler)
      : this.dartConstantSystem = const DartConstantSystem(),
        this.jsConstantCompiler = new JavaScriptConstantCompiler(),
        super(compiler.measurer);

  String get name => 'ConstantHandler';

  @override
  ConstantSystem get constantSystem => dartConstantSystem;
}

/**
 * The [JavaScriptConstantCompiler] is used to keep track of compile-time
 * constants, initializations of global and static fields, and default values of
 * optional parameters for the JavaScript interpretation of constants.
 */
class JavaScriptConstantCompiler implements BackendConstantEnvironment {
  // TODO(johnniwinther): Move this to the backend constant handler.
  /** Caches the statics where the initial value cannot be eagerly compiled. */
  final Set<FieldEntity> lazyStatics = new Set<FieldEntity>();

  JavaScriptConstantCompiler();

  ConstantSystem get constantSystem => JAVA_SCRIPT_CONSTANT_SYSTEM;

  @override
  void registerLazyStatic(FieldEntity element) {
    lazyStatics.add(element);
  }

  List<FieldEntity> getLazilyInitializedFieldsForEmission() {
    return new List<FieldEntity>.from(lazyStatics);
  }
}
