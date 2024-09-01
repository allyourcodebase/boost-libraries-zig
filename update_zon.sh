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
  "git+https://github.com/boostorg/multi_array#$BOOST_VERSION"
  "git+https://github.com/boostorg/integer#$BOOST_VERSION"
  "git+https://github.com/boostorg/array#$BOOST_VERSION"
  "git+https://github.com/boostorg/safe_numerics#$BOOST_VERSION"
  "git+https://github.com/boostorg/filesystem#$BOOST_VERSION"
  "git+https://github.com/boostorg/compute#$BOOST_VERSION"
  "git+https://github.com/boostorg/mysql#$BOOST_VERSION"
  "git+https://github.com/boostorg/sort#$BOOST_VERSION"
  "git+https://github.com/boostorg/stacktrace#$BOOST_VERSION"
  "git+https://github.com/boostorg/signals2#$BOOST_VERSION"
  "git+https://github.com/boostorg/interprocess#$BOOST_VERSION"
  "git+https://github.com/boostorg/context#$BOOST_VERSION"
  "git+https://github.com/boostorg/timer#$BOOST_VERSION"
  "git+https://github.com/boostorg/wave#$BOOST_VERSION"
  "git+https://github.com/boostorg/atomic#$BOOST_VERSION"
  "git+https://github.com/boostorg/scope#$BOOST_VERSION"
  "git+https://github.com/boostorg/process#$BOOST_VERSION"
  "git+https://github.com/boostorg/fusion#$BOOST_VERSION"
  "git+https://github.com/boostorg/function#$BOOST_VERSION"
  "git+https://github.com/boostorg/spirit#$BOOST_VERSION"
  "git+https://github.com/boostorg/cobalt#$BOOST_VERSION"
  "git+https://github.com/boostorg/phoenix#$BOOST_VERSION"
  "git+https://github.com/boostorg/locale#$BOOST_VERSION"
  "git+https://github.com/boostorg/uuid#$BOOST_VERSION"
  "git+https://github.com/boostorg/nowide#$BOOST_VERSION"
  "git+https://github.com/boostorg/circular_buffer#$BOOST_VERSION"
  "git+https://github.com/boostorg/leaf#$BOOST_VERSION"
  "git+https://github.com/boostorg/lockfree#$BOOST_VERSION"
  "git+https://github.com/boostorg/redis#$BOOST_VERSION"
  "git+https://github.com/boostorg/geometry#$BOOST_VERSION"
  "git+https://github.com/boostorg/crc#$BOOST_VERSION"
  "git+https://github.com/boostorg/compat#$BOOST_VERSION"
  "git+https://github.com/boostorg/bimap#$BOOST_VERSION"
  "git+https://github.com/boostorg/tokenizer#$BOOST_VERSION"
  "git+https://github.com/boostorg/parameter#$BOOST_VERSION"
  "git+https://github.com/boostorg/callable_traits#$BOOST_VERSION"
  "git+https://github.com/boostorg/odeint#$BOOST_VERSION"
  "git+https://github.com/boostorg/ublas#$BOOST_VERSION"
  "git+https://github.com/boostorg/serialization#$BOOST_VERSION"
  "git+https://github.com/boostorg/iostreams#$BOOST_VERSION"
  "git+https://github.com/boostorg/type_erasure#$BOOST_VERSION"
  "git+https://github.com/boostorg/typeof#$BOOST_VERSION"
  "git+https://github.com/boostorg/units#$BOOST_VERSION"
  "git+https://github.com/boostorg/function_types#$BOOST_VERSION"

  ## Add more URLs here
)

# Loop through each URL
for GIT_URL in "${GIT_URLS[@]}"; do
  # Extract the package name from the URL
  PKG_NAME=$(basename "$GIT_URL" | sed 's/#.*//')

  # Use zig fetch with the package name and URL
  zig fetch --save="$PKG_NAME" "$GIT_URL"
done
