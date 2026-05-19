# AdaptiveETA uses hasattr-based lazy init; replace with explicit __init__ and __slots__

## Description

`progressbar.widgets.AdaptiveETA._update_samples` decides whether to
initialise the `samples` list by calling `hasattr(self, 'samples')`
on every invocation. As a consequence:
  - `samples` does not exist as an attribute until the widget has
    been update()-d at least once. Code/tests that introspect the
    widget at construction time crash with AttributeError.
  - The base class `Timer` declares `__slots__`, but `AdaptiveETA`
    inherits those slots without declaring `'samples'`, silently
    forcing the instance to carry a `__dict__` (memory regression
    and breaks the slots contract).
  - The `_update_samples` method is doing two unrelated things
    (initialization + append/pop), making the buffer mechanism
    harder to reason about and test.

## Expected behaviour

`AdaptiveETA` must:
  - Define an `__init__` that calls `super().__init__()` and creates
    the `samples` buffer with `NUM_SAMPLES + 1` seed entries set to
    `(0, 0)`.
  - Declare `__slots__ = ('samples',)` so the slots contract is
    preserved.
  - `_update_samples` must contain only the sliding-window logic
    (append + pop), no lazy-init branch.
  - Behaviour of `update(pbar)` against a populated `pbar` must be
    bit-identical to the old implementation once samples reach
    steady state.

## Steps to reproduce

1. from progressbar.widgets import AdaptiveETA
2. eta = AdaptiveETA()
3. hasattr(eta, 'samples')   # currently False on base — should be True
4. eta.__slots__              # 'samples' missing on base
5. type(eta).__dict__.get('__dict__')  # base has __dict__, should not

## Constraints

- Do not modify or remove any existing tests.
- Do not introduce new external dependencies.
- Preserve the existing public API.
- The fix must keep the current test suite green.
