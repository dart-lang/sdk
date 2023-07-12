// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Command {
  static const initialize = 'initialize';
  static const configurationDone = 'configurationDone';
  static const attach = 'attach';
  static const createVariableForInstance = r'$/createVariableForInstance';
  static const getVariablesInstanceId = r'$/getVariablesInstanceId';
}

class ErrorMessageType {
  static const general = 1;
}

class Parameters {
  static const isolateId = 'isolateId';
  static const instanceId = 'instanceId';
  static const variablesReference = 'variablesReference';
}
