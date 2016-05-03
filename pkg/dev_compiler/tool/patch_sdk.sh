#!/bin/bash
set -e

dart -c tool/patch_sdk.dart tool/input_sdk tool/generated_sdk
