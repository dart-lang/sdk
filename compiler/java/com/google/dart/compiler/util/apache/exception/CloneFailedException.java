// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.google.dart.compiler.util.apache.exception;

/**
 * Exception thrown when a clone cannot be created. In contrast to
 * {@link CloneNotSupportedException} this is a {@link RuntimeException}.
 * <p>
 * NOTICE: This file is modified copy of its original Apache library.
 * It was moved to the different package, and changed to reduce number of dependencies.
 * 
 * @since 3.0
 */
public class CloneFailedException extends RuntimeException {
    // ~ Static fields/initializers ---------------------------------------------

    private static final long serialVersionUID = 20091223L;

    // ~ Constructors -----------------------------------------------------------

    /**
     * Constructs a CloneFailedException.
     * 
     * @param message description of the exception
     * @since upcoming
     */
    public CloneFailedException(final String message) {
        super(message);
    }

    /**
     * Constructs a CloneFailedException.
     * 
     * @param cause cause of the exception
     * @since upcoming
     */
    public CloneFailedException(final Throwable cause) {
        super(cause);
    }

    /**
     * Constructs a CloneFailedException.
     * 
     * @param message description of the exception
     * @param cause cause of the exception
     * @since upcoming
     */
    public CloneFailedException(final String message, final Throwable cause) {
        super(message, cause);
    }
}
