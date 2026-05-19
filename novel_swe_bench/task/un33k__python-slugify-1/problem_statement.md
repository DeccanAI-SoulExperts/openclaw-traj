# Replacements list in slugify() is applied twice and corrupts output

## Description

The replacements list in slugify() is applied once on the raw input
(lines 109–111) and then again on the already-processed slug
(lines 186–188). If any replacement old value happens to match a
substring in the final slug, it silently corrupts the output.
For example, slugify("10 | 20", replacements=[["or", "pipe"]])
produces "10-pipe-20" instead of "10-or-20".

## Expected behaviour

Replacements should only be applied once on the raw input (lines 109–111).
The second replacements pass at lines 186–188 should not exist.
slugify("10 | 20", replacements=[["or", "pipe"]]) should return "10-or-20".

## Steps to reproduce

1. pip install -e .
2. python -c \"from slugify import slugify; print(slugify('10 | 20', replacements=[['or', 'pipe']]))\"
3. Observe output is '10-pipe-20' instead of expected '10-or-20'

## Constraints

- Do not modify or remove any existing tests.
- Do not introduce new external dependencies.
- Preserve the existing public API.
- The fix must keep the current test suite green.
