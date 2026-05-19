# `ExtractResult.reverse_domain_name` emits a leading dot when the public suffix is empty

## Description

When a URL or hostname does not match any entry in the Public Suffix List — i.e. the `suffix` attribute of the returned `ExtractResult` is the empty string — the `reverse_domain_name` property produces a result that begins with a stray leading dot.

### Minimal reproduction

```python
import tldextract
extract = tldextract.TLDExtract(suffix_list_urls=())  # offline, no PSL fetch
result = extract('google.faketld')

print(result.suffix)               # ''
print(result.reverse_domain_name)  # '.faketld.google'   <-- has a leading dot
```

## Expected behaviour

When `suffix` is the empty string, `reverse_domain_name` should not emit a leading separator. The result should be composed of just `domain` and any reversed subdomain labels, joined by `.`.

For the example above we would expect:

```
result.reverse_domain_name == 'faketld.google'
```

Additional expected outputs:

| Input | Current (buggy) output | Expected output |
|-------|------------------------|-----------------|
| `'faketld'` (single label, no suffix) | `'.faketld'` | `'faketld'` |
| `'a.b.faketld'` | `'.faketld.b.a'` | `'faketld.b.a'` |
| `'www.example.com'` (suffix present) | `'com.example.www'` | `'com.example.www'` *(unchanged)* |

## Root cause hint

`ExtractResult.reverse_domain_name` is implemented roughly as:

```python
stack = [self.suffix, self.domain]
if self.subdomain:
    stack.extend(reversed(self.subdomain.split(".")))
return ".".join(stack)
```

When `self.suffix == ''`, the empty string is included as the first element of `stack`, and `'.'.join(['', 'faketld', ...])` yields a leading `'.'`. The fix should ensure empty components are skipped (or equivalently, that the stack is only constructed from non-empty parts).

## Constraints

- Existing behaviour for non-empty suffixes (e.g. `'www.example.com'` → `'com.example.www'`, `'theregister.co.uk'` → `'co.uk.theregister'`) **must be preserved**. The repo's existing `test_reverse_domain_name_notation` test exercises this.
- No new external dependencies.
- Do not modify any tests; the fix must keep all current tests passing.
