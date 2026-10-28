# Granularity of operations

__It's better to have fine-grained operations that can be chained by users than
to have course-grained operations that can't be applied in smaller increments.__

This principle doesn't apply to functionality that is supported by an explicit
LSP protocol. In those cases the definition of the protocol dictates the
behavior that needs to be supported. This applies in cases where we are
designing an operation (such as a code action).

While it would sometimes be convenient to have a single operation that makes
multiple smaller changes, providing finer grained operations provides users with
more flexibility.

For example, we provide an operation to convert an in-body constructor into a
primary constructor. That operation could have been designed to also convert all
of the eligible parameters to be declaring parameters. But it isn't necessary
for them to be converted, and it would make the operation unusable in situations
where a developer doesn't want all of the parameters to be converted.

## Why not both?

We could choose to have both fine-grained and course-grained operations, but
there are two reasons not to do so:

- the number of possible combinations of fine-grained operations can be quite
  large

- there's a limit to how much code we can maintain
