#!/bin/sh
# The message_extraction_test.dart test uses a temporary directory and spawns 
# separate processes for each step. This can make it very painful to debug the
# steps. 
# This script runs the steps individually, putting the files in the current
# directory. You can run the script to run the test locally, or use this to
# run individual steps or create them as launches in the editor.
dart ../../bin/extract_to_arb.dart sample_with_messages.dart \
part_of_sample_with_messages.dart
dart make_hardcoded_translation.dart intl_messages.arb
dart ../../bin/generate_from_arb.dart --generated-file-prefix=foo_ \
sample_with_messages.dart part_of_sample_with_messages.dart \
translation_fr.arb translation_de_DE.arb
