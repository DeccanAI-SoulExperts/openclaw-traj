# extract_urllib mishandles parsed URLs with port, userinfo, or IPv6 host

## Description

`extract_urllib()` gives the wrong result for some URLs that were already
parsed with `urllib.parse.urlsplit()`.
For example, this URL works correctly when passed as a normal string: `http://www.example.com:8080/path`
But when the same URL is passed through `urlsplit()` first, the port can be
treated like part of the domain. Similar problems happen with URLs that have
username/password info, and with IPv6 URLs that include a port.

## Expected behaviour

`extract_urllib()` should give the same result as normal string extraction
for the same URL. It should ignore ports, ignore username/password info, and still detect IPv6
hosts correctly. This should be fixed without changing the public API.

## Steps to reproduce

1. Create a `TLDExtract` instance.
2. Call `extract_urllib(urlsplit('http://www.example.com:8080/path'))`.
3. Compare it with extracting from the same URL as a string.
4. Try the same check with a URL containing userinfo and an IPv6 URL with a port.

## Constraints

- Do not modify or remove any existing tests.
- Do not introduce new external dependencies.
- Preserve the existing public API.
- The fix must keep the current test suite green.
