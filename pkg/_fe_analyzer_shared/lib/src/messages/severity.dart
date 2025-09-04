// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.messages.severity;

enum CfeSeverity { context, error, ignored, internalProblem, warning, info }

const Map<String, CfeSeverity> severityEnumValues = const <String, CfeSeverity>{
  'CONTEXT': CfeSeverity.context,
  'ERROR': CfeSeverity.error,
  'IGNORED': CfeSeverity.ignored,
  'INTERNAL_PROBLEM': CfeSeverity.internalProblem,
  'WARNING': CfeSeverity.warning,
  'INFO': CfeSeverity.info,
};

const Map<CfeSeverity, String> severityPrefixes = const <CfeSeverity, String>{
  CfeSeverity.error: "Error",
  CfeSeverity.internalProblem: "Internal problem",
  CfeSeverity.warning: "Warning",
  CfeSeverity.context: "Context",
  CfeSeverity.info: "Info",
};

const Map<CfeSeverity, String> severityTexts = const <CfeSeverity, String>{
  CfeSeverity.error: "error",
  CfeSeverity.internalProblem: "internal problem",
  CfeSeverity.warning: "warning",
  CfeSeverity.context: "context",
  CfeSeverity.info: "info",
};
