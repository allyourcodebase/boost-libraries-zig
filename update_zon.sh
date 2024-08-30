#!/bin/bash

BOOST_VERSION="boost-1.86.0"

# Array of git URLs
GIT_URLS=(
  "git+https://github.com/boostorg/algorithm#$BOOST_VERSION"
  "git+https://github.com/boostorg/asio#$BOOST_VERSION"
  "git+https://github.com/boostorg/assert#$BOOST_VERSION"
  "git+https://github.com/boostorg/bind#$BOOST_VERSION"
  "git+https://github.com/boostorg/config#$BOOST_VERSION"
  "git+https://github.com/boostorg/container#$BOOST_VERSION"
  "git+https://github.com/boostorg/core#$BOOST_VERSION"
  "git+https://github.com/boostorg/detail#$BOOST_VERSION"
  "git+https://github.com/boostorg/describe#$BOOST_VERSION"
  "git+https://github.com/boostorg/endian#$BOOST_VERSION"
  "git+https://github.com/boostorg/container_hash#$BOOST_VERSION"
  "git+https://github.com/boostorg/iterator#$BOOST_VERSION"
  "git+https://github.com/boostorg/intrusive#$BOOST_VERSION"
  "git+https://github.com/boostorg/logic#$BOOST_VERSION"
  "git+https://github.com/boostorg/mp11#$BOOST_VERSION"
  "git+https://github.com/boostorg/mpl#$BOOST_VERSION"
  "git+https://github.com/boostorg/optional#$BOOST_VERSION"
  "git+https://github.com/boostorg/smart_ptr#$BOOST_VERSION"
  "git+https://github.com/boostorg/move#$BOOST_VERSION"
  "git+https://github.com/boostorg/static_assert#$BOOST_VERSION"
  "git+https://github.com/boostorg/static_string#$BOOST_VERSION"
  "git+https://github.com/boostorg/system#$BOOST_VERSION"
  "git+https://github.com/boostorg/throw_exception#$BOOST_VERSION"
  "git+https://github.com/boostorg/tuple#$BOOST_VERSION"
  "git+https://github.com/boostorg/type_traits#$BOOST_VERSION"
  "git+https://github.com/boostorg/utility#$BOOST_VERSION"
  "git+https://github.com/boostorg/winapi#$BOOST_VERSION"
  "git+https://github.com/boostorg/functional#$BOOST_VERSION"
  "git+https://github.com/boostorg/json#$BOOST_VERSION"
  "git+https://github.com/boostorg/io#$BOOST_VERSION"
  "git+https://github.com/boostorg/range#$BOOST_VERSION"
  "git+https://github.com/boostorg/regex#$BOOST_VERSION"
  "git+https://github.com/boostorg/variant#$BOOST_VERSION"
  "git+https://github.com/boostorg/variant2#$BOOST_VERSION"
  "git+https://github.com/boostorg/date_time#$BOOST_VERSION"
  "git+https://github.com/boostorg/outcome#$BOOST_VERSION"
  "git+https://github.com/boostorg/hana#$BOOST_VERSION"
  "git+https://github.com/boostorg/numeric_conversion#$BOOST_VERSION"
  "git+https://github.com/boostorg/concept_check#$BOOST_VERSION"
  "git+https://github.com/boostorg/predef#$BOOST_VERSION"
  "git+https://github.com/boostorg/preprocessor#$BOOST_VERSION"
  "git+https://github.com/boostorg/align#$BOOST_VERSION"
  "git+https://github.com/boostorg/graph#$BOOST_VERSION"
  "git+https://github.com/boostorg/pfr#$BOOST_VERSION"
  "git+https://github.com/boostorg/math#$BOOST_VERSION"
  "git+https://github.com/boostorg/lexical_cast#$BOOST_VERSION"
  "git+https://github.com/boostorg/type_index#$BOOST_VERSION"
  "git+https://github.com/boostorg/beast#$BOOST_VERSION"
  "git+https://github.com/boostorg/chrono#$BOOST_VERSION"
  "git+https://github.com/boostorg/unordered#$BOOST_VERSION"
  "git+https://github.com/boostorg/any#$BOOST_VERSION"
  "git+https://github.com/boostorg/url#$BOOST_VERSION"

  ## Add more URLs here
)

# Loop through each URL
for GIT_URL in "${GIT_URLS[@]}"; do
  # Extract the package name from the URL
  PKG_NAME=$(basename "$GIT_URL" | sed 's/#.*//')

  # Use zig fetch with the package name and URL
  zig fetch --save="$PKG_NAME" "$GIT_URL"
done
