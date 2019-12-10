#!/usr/bin/env bash
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

TRIAL_MIGRATION=`dirname "$0"`/trial_migration.dart

# The current "official" set of parameters for the trial_migration script.
exec dart --enable-asserts ${TRIAL_MIGRATION} -p charcode,collection,logging,meta,path,term_glyph,typed_data,async,source_span,stack_trace,matcher,stream_channel,boolean_selector,test/pkgs/test_api "$@"
