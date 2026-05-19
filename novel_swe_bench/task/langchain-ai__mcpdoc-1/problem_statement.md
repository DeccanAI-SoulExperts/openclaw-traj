# mcpdoc silently drops invalid documentation sources at startup

## Description

The server starts successfully with no output. Querying the server via
list_doc_sources returns only the valid sources; any invalid or unreachable
URL is excluded with no warning or error.

## Expected behaviour

The server should emit a warning or raise a ValueError for each URL that
cannot be fetched or validated at startup, so the operator knows a source
was skipped.

## Steps to reproduce

1. Run: mcpdoc --urls invalid-url https://valid-source.com/llms.txt
2. Server starts without error or output
3. list_doc_sources returns only the valid source

## Constraints

- Do not modify or remove any existing tests.
- Do not introduce new external dependencies.
- Preserve the existing public API.
- The fix must keep the current test suite green.
