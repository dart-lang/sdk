This example shows how to write a lazy transformer.

This lazy tranformer implements a ROT13 converter. ROT13 (ROTate 13)
is a classic substitution cipher which replaces each letter in the source
file with the corresponding letter 13 places later in the alphabet.
The source file should have a ".txt" extension and the converted file
is created with a ".shhhh" extension.

Generally, only transformers that take a long time to run should be made lazy.
This transformer is not particularly slow, but imagine that it might be used
to convert the entire library of congress&ndash;laziness would then be a virtue.

For more information, see Writing a Lazy Transformer at:
https://www.dartlang.org/tools/pub/transformers/lazy-transformer.html
