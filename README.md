# ini-reader
Reads INI file and outputs a section or the value of a key in a section.

### Build

```sh
zig build
```

### HOW-TO-USE

List keys and values of a section
```sh
ini-reader <path-to-ini-file> <section-name>
```

Get the value of a key
```sh
ini-reader <path-to-ini-file> <section-name> <key>
```
