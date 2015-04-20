// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.plugin.engine_plugin;

import 'package:analyzer/plugin/plugin.dart';
import 'package:analyzer/plugin/task.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * A plugin that defines the extension points and extensions that are inherently
 * defined by the analysis engine.
 */
class EnginePlugin implements Plugin {
  /**
   * The simple identifier of the extension point that allows plugins to
   * register new analysis tasks with the analysis engine.
   */
  static const String TASK_EXTENSION_POINT = 'task';

  /**
   * The unique identifier of this plugin.
   */
  static const String UNIQUE_IDENTIFIER = 'analysis_engine.core';

  /**
   * The extension point that allows plugins to register new analysis tasks with
   * the analysis engine.
   */
  ExtensionPoint taskExtensionPoint;

  /**
   * Initialize a newly created plugin.
   */
  EnginePlugin();

  /**
   * Return a list containing all of the task descriptors that were contributed.
   */
  List<TaskDescriptor> get taskDescriptors => taskExtensionPoint.extensions;

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    taskExtensionPoint =
        registerExtensionPoint(TASK_EXTENSION_POINT, _validateTaskExtension);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    String taskId = TASK_EXTENSION_POINT_ID;
    //
    // Register general tasks.
    //
    registerExtension(taskId, GetContentTask.DESCRIPTOR);
    //
    // Register Dart tasks.
    //
    registerExtension(taskId, BuildClassConstructorsTask.DESCRIPTOR);
    registerExtension(taskId, BuildCompilationUnitElementTask.DESCRIPTOR);
    registerExtension(taskId, BuildDirectiveElementsTask.DESCRIPTOR);
    registerExtension(taskId, BuildEnumMemberElementsTask.DESCRIPTOR);
    registerExtension(taskId, BuildExportNamespaceTask.DESCRIPTOR);
    registerExtension(taskId, BuildFunctionTypeAliasesTask.DESCRIPTOR);
    registerExtension(taskId, BuildLibraryConstructorsTask.DESCRIPTOR);
    registerExtension(taskId, BuildLibraryElementTask.DESCRIPTOR);
    registerExtension(taskId, BuildPublicNamespaceTask.DESCRIPTOR);
    registerExtension(taskId, BuildSourceClosuresTask.DESCRIPTOR);
    registerExtension(taskId, BuildTypeProviderTask.DESCRIPTOR);
    registerExtension(taskId, GatherUsedImportedElementsTask.DESCRIPTOR);
    registerExtension(taskId, GatherUsedLocalElementsTask.DESCRIPTOR);
    registerExtension(taskId, GenerateHintsTask.DESCRIPTOR);
    registerExtension(taskId, ParseDartTask.DESCRIPTOR);
    registerExtension(taskId, ResolveLibraryTypeNamesTask.DESCRIPTOR);
    registerExtension(taskId, ResolveReferencesTask.DESCRIPTOR);
    registerExtension(taskId, ResolveUnitTypeNamesTask.DESCRIPTOR);
    registerExtension(taskId, ResolveVariableReferencesTask.DESCRIPTOR);
    registerExtension(taskId, ScanDartTask.DESCRIPTOR);
    registerExtension(taskId, VerifyUnitTask.DESCRIPTOR);
    //
    // Register HTML tasks.
    //
  }

  /**
   * Validate the given extension by throwing an [ExtensionError] if it is not a
   * valid domain.
   */
  void _validateTaskExtension(Object extension) {
    if (extension is! TaskDescriptor) {
      String id = taskExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must be a TaskDescriptor');
    }
  }
}
