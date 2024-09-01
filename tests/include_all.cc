#include <boost/algorithm/algorithm.hpp>
#include <boost/any.hpp>
#include <boost/array.hpp>
#include <boost/asio.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/bind.hpp>
#include <boost/cobalt.hpp>
#include <boost/config.hpp>
#include <boost/crc.hpp>
#include <boost/filesystem.hpp>
#include <boost/hana.hpp>
#include <boost/multi_array.hpp>
#include <boost/pfr.hpp>
#include <boost/process.hpp>
#include <boost/safe_numerics/safe_integer.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/signals2.hpp>
#include <boost/unordered_map.hpp>
#include <boost/unordered_set.hpp>
#include <boost/variant.hpp>
#include <boost/version.hpp>

#include <iostream>

using namespace boost;

void testVariants();
void testCRC();
void testSafeIntegers();
void testHana();
void testMultiArray();
void testSignals2();

int main() {
  std::cout << "Boost version " << BOOST_VERSION / 100000 << "."
            << BOOST_VERSION / 100 % 1000 << "." << BOOST_VERSION % 100
            << std::endl;

  asio::io_context io_service;

  testCRC();
  testSafeIntegers();
  testVariants();
  testHana();
  testMultiArray();
  testSignals2();

  return 0;
}

void testSafeIntegers() {

  safe_numerics::safe<int> x(10);
  safe_numerics::safe<int> y(20);

  // addition
  auto sum = x + y;
  std::cout << "Safe addition: " << sum << std::endl;

  // subtraction
  auto difference = y - x;
  std::cout << "Safe subtraction: " << difference << std::endl;

  // multiplication
  auto product = x * y;
  std::cout << "Safe multiplication: " << product << std::endl;

  // division
  auto quotient = y / x;
  std::cout << "Safe division: " << quotient << std::endl;

  // Overflow detection
  try {
    safe_numerics::safe<int8_t> small_int = 100;
    small_int *= 2;
  } catch (const std::exception &e) {
    std::cout << "Overflow detected: " << e.what() << std::endl;
  }

  // Underflow detection
  try {
    safe_numerics::safe<uint8_t> unsigned_int = 0;
    unsigned_int--;
  } catch (const std::exception &e) {
    std::cout << "Underflow detected: " << e.what() << std::endl;
  }
}

void testCRC() {
  // Sample data
  const char *data = "Hello, Boost CRC!";
  std::size_t len = std::strlen(data);

  // Create a CRC-32 object
  boost::crc_32_type crc;

  // Process the data
  crc.process_bytes(data, len);

  // Get the CRC checksum
  uint32_t checksum = crc.checksum();

  std::cout << "CRC-32 checksum: 0x" << std::hex << std::uppercase << checksum
            << std::endl;

  // Reset the CRC object for reuse
  crc.reset();

  // Process data in chunks
  crc.process_bytes(data, 5);
  crc.process_bytes(data + 5, len - 5);

  // Get the new checksum
  uint32_t new_checksum = crc.checksum();

  std::cout << "CRC-32 checksum (chunked): 0x" << std::hex << std::uppercase
            << new_checksum << std::endl;

  // Verify that both methods produce the same result
  if (checksum == new_checksum) {
    std::cout << "Checksums match!" << std::endl;
  } else {
    std::cout << "Checksums do not match!" << std::endl;
  }
}

void testVariants() {
  variant<int, std::string, double> v;

  v = 42;
  std::cout << "Variant contains int: " << get<int>(v) << std::endl;

  v = "Hello, Boost!";
  std::cout << "Variant contains string: " << get<std::string>(v) << std::endl;

  v = 3.14;
  std::cout << "Variant contains double: " << get<double>(v) << std::endl;

  // Using a visitor
  struct visitor : public static_visitor<void> {
    void operator()(int i) const {
      std::cout << "Visited int: " << i << std::endl;
    }
    void operator()(const std::string &s) const {
      std::cout << "Visited string: " << s << std::endl;
    }
    void operator()(double d) const {
      std::cout << "Visited double: " << d << std::endl;
    }
  };

  v = 100;
  apply_visitor(visitor(), v);

  v = "Boost Variant";
  apply_visitor(visitor(), v);

  v = 2.718;
  apply_visitor(visitor(), v);
}

void testMultiArray() {
  // Define a 3D array with dimensions 3x4x2
  typedef multi_array<int, 3> array_type;
  array_type A(extents[3][4][2]);

  // Fill the array with some values
  int value = 0;
  for (int i = 0; i < 3; ++i)
    for (int j = 0; j < 4; ++j)
      for (int k = 0; k < 2; ++k)
        A[i][j][k] = value++;

  // Print the array
  for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 4; ++j) {
      for (int k = 0; k < 2; ++k) {
        std::cout << A[i][j][k] << " ";
      }
      std::cout << std::endl;
    }
    std::cout << std::endl;
  }

  // Demonstrate slicing
  typedef array_type::index_range range;
  array_type::array_view<2>::type myview =
      A[boost::indices[1][range()][range()]];

  std::cout << "View of the second 'layer' of the 3D array:" << std::endl;
  for (int j = 0; j < 4; ++j) {
    for (int k = 0; k < 2; ++k) {
      std::cout << myview[j][k] << " ";
    }
    std::cout << std::endl;
  }
}

void testHana() {
  struct Person {
    BOOST_HANA_DEFINE_STRUCT(Person, (std::string, name), (int, age));
  };

  // Create an instance of Person
  auto person = Person{"Alice", 30};

  // Use Hana to iterate over the struct members
  hana::for_each(hana::members(person), [](auto member) {
    std::cout << "Member value: " << member << std::endl;
  });

  // Use Hana's type-level computations
  auto types = hana::tuple_t<int, char, double, float>;

  std::cout << "Number of types: " << hana::length(types) << std::endl;

  // Check if int is among the types
  constexpr auto has_int = hana::contains(types, hana::type_c<int>);
  std::cout << "Contains int: " << has_int << std::endl;

  // Transform the tuple of types
  auto sizes = hana::transform(types, [](auto t) { return hana::sizeof_(t); });

  std::cout << "Sizes of types: ";
  hana::for_each(sizes, [](auto size) { std::cout << size << " "; });
  std::cout << std::endl;
}

void testSignals2() {
  // Define a signal with two parameters
  signals2::signal<void(int, const std::string &)> sig;

  // Define some slot functions
  auto slot1 = [](int n, const std::string &str) {
    std::cout << "Slot 1: " << n << ", " << str << std::endl;
  };

  auto slot2 = [](int n, const std::string &str) {
    std::cout << "Slot 2: " << n << ", " << str << std::endl;
  };

  // Connect the slots to the signal
  sig.connect(slot1);
  sig.connect(slot2);

  // Emit the signal
  std::cout << "Emitting signal:" << std::endl;
  sig(42, "Hello, Boost.Signals2!");

  // Disconnect slot1
  sig.disconnect(slot1);

  // Emit the signal again
  std::cout << "Emitting signal after disconnecting slot1:" << std::endl;
  sig(100, "Signal emitted again");

  // Use scoped_connection for automatic disconnection
  {
    signals2::scoped_connection conn =
        sig.connect([](int n, const std::string &str) {
          std::cout << "Temporary slot: " << n << ", " << str << std::endl;
        });

    std::cout << "Emitting signal with temporary slot:" << std::endl;
    sig(200, "Temporary connection");
  } // conn goes out of scope here and disconnects

  // Emit signal one last time
  std::cout << "Final signal emission:" << std::endl;
  sig(300, "Final emission");
}