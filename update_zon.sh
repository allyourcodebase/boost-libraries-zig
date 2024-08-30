#!/bin/bash

# Array of git URLs
GIT_URLS=(
    "git+https://github.com/boostorg/asio"
    "git+https://github.com/boostorg/assert"
    "git+https://github.com/boostorg/bind"
    "git+https://github.com/boostorg/config"
    "git+https://github.com/boostorg/container"
    "git+https://github.com/boostorg/core"
    "git+https://github.com/boostorg/endian"
    "git+https://github.com/boostorg/intrusive"
    "git+https://github.com/boostorg/logic"
    "git+https://github.com/boostorg/mp11"
    "git+https://github.com/boostorg/optional"
    "git+https://github.com/boostorg/smart_ptr"
    "git+https://github.com/boostorg/static_assert"
    "git+https://github.com/boostorg/static_string"
    "git+https://github.com/boostorg/system"
    "git+https://github.com/boostorg/throw_exception"
    "git+https://github.com/boostorg/type_traits"
    "git+https://github.com/boostorg/utility"
    "git+https://github.com/boostorg/winapi"
    "git+https://github.com/boostorg/json"
    "git+https://github.com/boostorg/io"
    "git+https://github.com/boostorg/range"
    "git+https://github.com/boostorg/regex"
    "git+https://github.com/boostorg/variant2"
    "git+https://github.com/boostorg/date_time"
    "git+https://github.com/boostorg/outcome"
    "git+https://github.com/boostorg/hana"
    "git+https://github.com/boostorg/numeric_conversion"
    "git+https://github.com/boostorg/concept_check"
    "git+https://github.com/boostorg/predef"
    "git+https://github.com/boostorg/preprocessor"
    "git+https://github.com/boostorg/align"
)

# Loop through each URL
for GIT_URL in "${GIT_URLS[@]}"
do
  # Extract the package name from the URL
  PKG_NAME=$(basename "$GIT_URL")

  # Use zig fetch with the package name and URL
  zig fetch --save="$PKG_NAME" "$GIT_URL"
done
