# PyDuckling

[![Project License - MIT](https://img.shields.io/pypi/l/pyduckling-native.svg)](https://raw.githubusercontent.com/zhulinchng/pyduckling-native/master/LICENSE)
[![pypi version](https://img.shields.io/pypi/v/pyduckling-native-zhulinchng.svg)](https://pypi.org/project/pyduckling-native-zhulinchng/)
[![Downloads](https://pepy.tech/badge/pyduckling-native-zhulinchng)](https://pepy.tech/project/pyduckling-native-zhulinchng)
[![PyPI status](https://img.shields.io/pypi/status/pyduckling-native-zhulinchng.svg)](https://github.com/zhulinchng/pyduckling)
![Linux Tests](https://github.com/zhulinchng/pyduckling/actions/workflows/build.yml/badge.svg?branch=master)

*Copyright © 2020– Treble.ai*

> ℹ️ This is a fork of the original pyduckling-native library. There are differences to the original:
>
> * Build against the latest version of [Duckling](https://github.com/facebook/duckling)
> * Supported Python versions range from 3.8 to 3.12
> * **Cross-platform support**: Linux (x86_64) and macOS (Intel & Apple Silicon)

## Overview

This package provides native bindings for Facebook's [Duckling](https://github.com/facebook/duckling) in Python. This package supports all dimensions and languages available on the original library, and it does not require to spawn a Haskell server and does not use HTTP to call the Duckling API.

> ℹ️ This package is completely Haskell-less

## Installing

To install pyduckling, you can use both conda and pip package managers:

```bash
# Using pip
pip install pyduckling-native-zhulinchng
```

## Version Matrix

The following table shows which PyDuckling version corresponds to which Duckling version

| PyDuckling         | Duckling                                                          |
|--------------------|-------------------------------------------------------------------|
| 0.2.0              | v0.2.0.0 (commit [7520daa](https://github.com/facebook/duckling)) |
| 0.2.1 (unreleased) | v0.2.0.0 (commit [7520daa](https://github.com/facebook/duckling)) |

## Package usage

PyDuckling provides access to the parsing capabilities of Duckling used to extract structured data from text.

```python
# Core imports
from duckling import (load_time_zones, parse_ref_time,
                      parse_lang, default_locale_lang, parse_locale,
                      parse_dimensions, parse, Context)
# Install with pip install pendulum
import pendulum

# Load reference time for time parsing
time_zones = load_time_zones("/usr/share/zoneinfo") # "/var/db/timezone/zoneinfo" for MacOS
bog_now = pendulum.now('America/Bogota').replace(microsecond=0)
ref_time = parse_ref_time(
    time_zones, 'America/Bogota', bog_now.int_timestamp)

# Load language/locale information
lang_es = parse_lang('ES')
default_locale = default_locale_lang(lang_es)
locale = parse_locale('ES_CO', default_locale)

# Create parsing context with time and language information
context = Context(ref_time, locale)

# Define dimensions to look-up for
valid_dimensions = ["amount-of-money", "credit-card-number", "distance",
                    "duration", "email", "number", "ordinal",
                    "phone-number", "quantity", "temperature",
                    "time", "time-grain", "url", "volume"]

# Parse dimensions to use
output_dims = parse_dimensions(valid_dimensions)

# Parse a phrase
result = parse('En dos semanas', context, output_dims, False)
```

This wrapper allows access to all the dimensions and languages available on Duckling:

| Dimension | Example input | Example value output |
| --------- | ------------- | -------------------- |
| `amount-of-money` | "42€" | `{"value":42,"type":"value","unit":"EUR"}` |
| `credit-card-number` | "4111-1111-1111-1111" | `{"value":"4111111111111111","issuer":"visa"}` |
| `distance` | "6 miles" | `{"value":6,"type":"value","unit":"mile"}` |
| `duration` | "3 mins" | `{"value":3,"minute":3,"unit":"minute","normalized":{"value":180,"unit":"second"}}` |
| `email` | "<duckling-team@fb.com>" | `{"value":"duckling-team@fb.com"}` |
| `number` | "eighty eight" | `{"value":88,"type":"value"}` |
| `ordinal` | "33rd" | `{"value":33,"type":"value"}` |
| `phone-number` | "+1 (650) 123-4567" | `{"value":"(+1) 6501234567"}` |
| `quantity` | "3 cups of sugar" | `{"value":3,"type":"value","product":"sugar","unit":"cup"}` |
| `temperature` | "80F" | `{"value":80,"type":"value","unit":"fahrenheit"}` |
| `time` | "today at 9am" | `{"values":[{"value":"2016-12-14T09:00:00.000-08:00","grain":"hour","type":"value"}],"value":"2016-12-14T09:00:00.000-08:00","grain":"hour","type":"value"}` |
| `url` | "<https://api.wit.ai/message?q=hi>" | `{"value":"https://api.wit.ai/message?q=hi","domain":"api.wit.ai"}` |
| `volume` | "4 gallons" | `{"value":4,"type":"value","unit":"gallon"}` |

## Dependencies

To compile pyduckling, you will require the latest nightly release of [Rust](https://rustup.rs/), alongside [Cargo](https://crates.io/). Also, it requires a Python distribution with its corresponding development headers. Finally, this project depends on the following Cargo crates:

* [PyO3](https://github.com/PyO3/pyo3): Library used to produce Python bindings from Rust code.
* [Maturin](https://github.com/PyO3/maturin): Build system to build and publish Rust-based Python packages

Additionally, this package depends on [Duckling-FFI](https://github.com/treble-ai/duckling-ffi), used to compile the native interface to Duckling on Haskell. In order to compile Duckling-FFI, you will require the [Stack](https://haskell-lang.org/get-started) Haskell manager.

## Installing locally

### Cross-Platform Support

This project now supports both Linux and macOS! See [CROSS_PLATFORM.md](CROSS_PLATFORM.md) for detailed build instructions and configuration options.

### Linux (via Docker)

The only thing you need is a running [Docker](https://docs.docker.com/engine/install/) daemon
and permission to run `docker build` and `docker run`.
Then just run

```shell
./build.sh
```

### macOS (via Homebrew)

For macOS users, we provide a dedicated build script that handles all dependencies via Homebrew:

```shell
./build-macos.sh
```

This script will:

* Install required dependencies (PCRE, GMP, Haskell Stack, GHC) via Homebrew
* Detect your architecture (Intel vs Apple Silicon) and set appropriate paths
* Build the Haskell FFI library
* Compile the Python extension
* Run tests to verify the build

**Prerequisites for macOS:**

* [Homebrew](https://brew.sh/) package manager
* [Rust](https://rustup.rs/) toolchain
* Xcode Command Line Tools: `xcode-select --install`

All build dependencies are already installed in container images. The build script will get them and start
containers for building the Haskell lib and the Python lib. The directories `.cache`, `duckling-ffi/.stack-work`
and `target` will appear. The first two are for accelerating future builds and the last one will contain your final
build result.

After the `build.sh` completed successfully, you can find wheel files (binary distributions of the library) inside `target/wheels`.
The Python version (e.g. Python 3.11 = `cp311`), the libc variant
(`manylinux` or `musllinux`, if you are unsure you probably need manylinux) and the CPU architecture
(currently only `x86_64`) are encoded in the file name. Just pick the file matching to your system and install it with:

```shell
pip install -U target/wheels/<myfile>.whl
```

### Manually

Besides Rust and Stack, you will require the latest version of maturin installed to compile this project locally:

```bash
pip install maturin toml
```

First, you will need to compile Duckling-FFI in order to produce the shared library ``libducklingffi``, to do so, you can use the git submodule found at the root of this repository:

```bash
cd duckling-ffi
stack build
```

Then, you will need to move the resulting binary ``libducklingffi.a`` to the ``ext_lib`` folder:

```bash
cp duckling-ffi/libducklingffi.a ext_lib
```

After completing this procedure, it is possible to execute the following command to compile pyduckling:

```bash
maturin develop
```

In order to produce wheels, ``maturin build`` can be used instead. This project supports [PEP517](https://www.python.org/dev/peps/pep-0517/), thus pip can be used to install this package as well:

```bash
pip install -U .
```

## Running tests

We use pytest to run tests as it follows (after calling ``maturin develop``):

```bash
pytest -v duckling/tests
```

## Changelog

Please see our [CHANGELOG](https://github.com/zhulinchng/pyduckling/blob/master/CHANGELOG.md) file to learn more about our new features and improvements.

## Contribution guidelines

We follow PEP8 and PEP257 for pure python packages and Rust to compile extensions. We use MyPy type annotations for all functions and classes declared on this package. Feel free to send a PR or create an issue if you have any problem/question.
