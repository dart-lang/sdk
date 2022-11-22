# Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
FROM launcher.gcr.io/google/debian11:latest
ARG depot_tools
RUN apt-get update \
  && apt-get install -y build-essential debhelper git python3 \
  && rm -rf /var/lib/apt/lists/*
ENV PATH="$depot_tools:${PATH}"
ENTRYPOINT python3 tools/linux_dist_support/linux_distribution_support.py