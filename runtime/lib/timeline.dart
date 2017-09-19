// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@patch
bool _isDartStreamEnabled() native "Timeline_isDartStreamEnabled";

@patch
int _getTraceClock() native "Timeline_getTraceClock";

@patch
int _getThreadCpuClock() native "Timeline_getThreadCpuClock";

@patch
int _getNextAsyncId() native "Timeline_getNextAsyncId";

@patch
void _reportTaskEvent(int start, int taskId, String phase, String category,
    String name, String argumentsAsJson) native "Timeline_reportTaskEvent";

@patch
void _reportCompleteEvent(int start, int startCpu, String category, String name,
    String argumentsAsJson) native "Timeline_reportCompleteEvent";

@patch
void _reportFlowEvent(int start, int startCpu, String category, String name,
    int type, int id, String argumentsAsJson) native "Timeline_reportFlowEvent";

@patch
void _reportInstantEvent(int start, String category, String name,
    String argumentsAsJson) native "Timeline_reportInstantEvent";
