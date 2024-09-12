#define BOOST_BIND_GLOBAL_PLACEHOLDERS

#include <boost/algorithm/algorithm.hpp>
#include <boost/any.hpp>
#include <boost/array.hpp>
#include <boost/bind.hpp>
#include <boost/callable_traits.hpp>
#include <boost/config.hpp>
#include <boost/crc.hpp>
#include <boost/date_time.hpp>
#include <boost/hana.hpp>
#include <boost/multi_array.hpp>
#include <boost/numeric/odeint.hpp>
#include <boost/pfr.hpp>
#include <boost/safe_numerics/safe_integer.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/signals2.hpp>
#include <boost/stacktrace.hpp>
#include <boost/type_index.hpp>
#include <boost/unordered/unordered_flat_map.hpp>
#include <boost/unordered_map.hpp>
#include <boost/unordered_set.hpp>
#include <boost/uuid.hpp>
#include <boost/variant.hpp>
#include <boost/variant2.hpp>
#include <boost/version.hpp>

#include <iostream>

using namespace boost;

void testVariants();
void testCRC();
void testSafeIntegers();
void testHana();
void testMultiArray();
void testSignals2();
void testPFR();
void testUnordered();
void testDateTime();
void testOdeInt();
void testCallableTraits();
void testStackTrace();

int main() {
  std::cout << "Boost version " << BOOST_VERSION / 100000 << "."
            << BOOST_VERSION / 100 % 1000 << "." << BOOST_VERSION % 100 << "\n";

  testCRC();
  testSafeIntegers();
  testVariants();
  testHana();
  testMultiArray();
  testSignals2();
  testPFR();
  testUnordered();
  testDateTime();
  testCallableTraits();
  testOdeInt();
  testStackTrace();

  return 0;
}

void testSafeIntegers() {

  safe_numerics::safe<int> x(10);
  safe_numerics::safe<int> y(20);

  // addition
  auto sum = x + y;
  std::cout << "Safe addition: " << sum << "\n";

  // subtraction
  auto difference = y - x;
  std::cout << "Safe subtraction: " << difference << "\n";

  // multiplication
  auto product = x * y;
  std::cout << "Safe multiplication: " << product << "\n";

  // division
  auto quotient = y / x;
  std::cout << "Safe division: " << quotient << "\n";

  // Overflow detection
  try {
    safe_numerics::safe<int8_t> small_int = 100;
    small_int *= 2;
  } catch (const std::exception &e) {
    std::cout << "Overflow detected: " << e.what() << "\n";
  }

  // Underflow detection
  try {
    safe_numerics::safe<uint8_t> unsigned_int = 0;
    unsigned_int--;
  } catch (const std::exception &e) {
    std::cout << "Underflow detected: " << e.what() << "\n";
  }
}

void testCRC() {
  // Sample data
  const char *data = "Hello, Boost CRC!";
  std::size_t len = std::strlen(data);

  // Create a CRC-32 object
  crc_32_type crc;

  // Process the data
  crc.process_bytes(data, len);

  // Get the CRC checksum
  uint32_t checksum = crc.checksum();

  std::cout << "CRC-32 checksum: 0x" << std::hex << std::uppercase << checksum
            << "\n";

  // Reset the CRC object for reuse
  crc.reset();

  // Process data in chunks
  crc.process_bytes(data, 5);
  crc.process_bytes(data + 5, len - 5);

  // Get the new checksum
  uint32_t new_checksum = crc.checksum();

  std::cout << "CRC-32 checksum (chunked): 0x" << std::hex << std::uppercase
            << new_checksum << "\n";

  // Verify that both methods produce the same result
  if (checksum == new_checksum) {
    std::cout << "Checksums match!" << "\n";
  } else {
    std::cout << "Checksums do not match!" << "\n";
  }
}

void testVariants() {
  variant<int, std::string, double> v;

  v = 42;
  std::cout << "Variant contains int: " << get<int>(v) << "\n";

  v = "Hello, Boost!";
  std::cout << "Variant contains string: " << get<std::string>(v) << "\n";

  v = 3.14;
  std::cout << "Variant contains double: " << get<double>(v) << "\n";

  // Using a visitor
  struct visitor : public static_visitor<void> {
    void operator()(int i) const { std::cout << "Visited int: " << i << "\n"; }
    void operator()(const std::string &s) const {
      std::cout << "Visited string: " << s << "\n";
    }
    void operator()(double d) const {
      std::cout << "Visited double: " << d << "\n";
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
      std::cout << "\n";
    }
    std::cout << "\n";
  }

  // Demonstrate slicing
  typedef array_type::index_range range;
  array_type::array_view<2>::type myview = A[indices[1][range()][range()]];

  std::cout << "View of the second 'layer' of the 3D array:" << "\n";
  for (int j = 0; j < 4; ++j) {
    for (int k = 0; k < 2; ++k) {
      std::cout << myview[j][k] << " ";
    }
    std::cout << "\n";
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
    std::cout << "Member value: " << member << "\n";
  });

  // Use Hana's type-level computations
  auto types = hana::tuple_t<int, char, double, float>;

  std::cout << "Number of types: " << hana::length(types) << "\n";

  // Check if int is among the types
  constexpr auto has_int = hana::contains(types, hana::type_c<int>);
  std::cout << "Contains int: " << has_int << "\n";

  // Transform the tuple of types
  auto sizes = hana::transform(types, [](auto t) { return hana::sizeof_(t); });

  std::cout << "Sizes of types: ";
  hana::for_each(sizes, [](auto size) { std::cout << size << " "; });
  std::cout << "\n";
}

void testSignals2() {
  // Define a signal with two parameters
  signals2::signal<void(int, const std::string &)> sig;

  // Define some slot functions
  auto slot1 = [](int n, const std::string &str) {
    std::cout << "Slot 1: " << n << ", " << str << "\n";
  };

  auto slot2 = [](int n, const std::string &str) {
    std::cout << "Slot 2: " << n << ", " << str << "\n";
  };

  // Connect the slots to the signal
  sig.connect(slot1);
  sig.connect(slot2);

  // Emit the signal
  std::cout << "Emitting signal:" << "\n";
  sig(42, "Hello, Boost.Signals2!");

  // Disconnect slot1
  sig.disconnect(slot1);

  // Emit the signal again
  std::cout << "Emitting signal after disconnecting slot1:" << "\n";
  sig(100, "Signal emitted again");

  // Use scoped_connection for automatic disconnection
  {
    signals2::scoped_connection conn =
        sig.connect([](int n, const std::string &str) {
          std::cout << "Temporary slot: " << n << ", " << str << "\n";
        });

    std::cout << "Emitting signal with temporary slot:" << "\n";
    sig(200, "Temporary connection");
  } // conn goes out of scope here and disconnects

  // Emit signal one last time
  std::cout << "Final signal emission:" << "\n";
  sig(300, "Final emission");
}

void testPFR() {
  struct Person {
    std::string name;
    int age;
    double height;
  };

  Person person{"John Doe", 30, 1.75};

  // iterate over the struct's fields
  std::cout << "Person details:" << "\n";
  pfr::for_each_field(person, [](const auto &field, std::size_t idx) {
    std::cout << "Field " << idx << ": " << field << "\n";
  });

  // get the number of fields
  std::cout << "Number of fields: " << pfr::tuple_size<Person>::value << "\n";

  // access fields by index
  std::cout << "Name: " << pfr::get<0>(person) << "\n";
  std::cout << "Age: " << pfr::get<1>(person) << "\n";
  std::cout << "Height: " << pfr::get<2>(person) << "\n";

  // compare structs
  Person person2{"John Doe", 30, 1.75};
  Person person3{"Jane Doe", 28, 1.70};

  std::cout << "person == person2: " << std::boolalpha
            << pfr::eq(person, person2) << "\n";
  std::cout << "person == person3: " << std::boolalpha
            << pfr::eq(person, person3) << "\n";

  // create a tuple from a struct
  auto tuple = pfr::structure_to_tuple(person);
  std::cout << "First element of tuple: " << std::get<0>(tuple) << "\n";
}

void testUnordered() {
  unordered::unordered_flat_map<std::string, int> map;

  // Insert some key-value pairs
  map["apple"] = 5;
  map["banana"] = 3;
  map["cherry"] = 7;

  // Access and print elements
  std::cout << "apple: " << map["apple"] << "\n";
  std::cout << "banana: " << map["banana"] << "\n";

  // Check if a key exists
  if (map.contains("cherry")) {
    std::cout << "cherry is in the map" << "\n";
  }

  // Iterate over the map
  for (const auto &[key, value] : map) {
    std::cout << key << ": " << value << "\n";
  }

  // Erase an element
  map.erase("banana");

  // Print the size of the map
  std::cout << "Map size: " << map.size() << "\n";
}

void testDateTime() {
  gregorian::date today = gregorian::day_clock::local_day();
  std::cout << "Today's date: " << today << "\n";

  gregorian::date future_date(2025, gregorian::Jan, 1);
  gregorian::days days_until = future_date - today;
  std::cout << "Days until 2025-01-01: " << days_until.days() << "\n";

  posix_time::ptime now = posix_time::second_clock::local_time();
  std::cout << "Current time: " << now << "\n";

  posix_time::ptime future_time = now + posix_time::hours(24);
  std::cout << "Time in 24 hours: " << future_time << "\n";
  posix_time::time_duration duration = future_time - now;
  std::cout << "Duration until 24 hours: " << duration << "\n";
}

void testCallableTraits() {
  // Define a lambda function
  auto lambda = [](int x, double y) -> float {
    return static_cast<float>(x + y);
  };

  // Use callable_traits to get information about the lambda
  using args = callable_traits::args_t<decltype(lambda)>;
  using return_type = callable_traits::return_type_t<decltype(lambda)>;

  // Use type_index to print the types
  std::cout << "Lambda argument types: "
            << typeindex::type_id<args>().pretty_name() << "\n";
  std::cout << "Lambda return type: "
            << typeindex::type_id<return_type>().pretty_name() << "\n";

  // Define a member function
  struct Foo {
    void bar(int, std::string) {}
  };

  // Use callable_traits to get information about the member function
  using member_args = callable_traits::args_t<decltype(&Foo::bar)>;
  using member_return = callable_traits::return_type_t<decltype(&Foo::bar)>;

  // Print member function information
  std::cout << "Member function argument types: "
            << typeindex::type_id<member_args>().pretty_name() << "\n";
  std::cout << "Member function return type: "
            << typeindex::type_id<member_return>().pretty_name() << "\n";
}

void testOdeInt() {
  // Define the system of ODEs (harmonic oscillator)
  auto harmonic_oscillator = [](const std::vector<double> &x,
                                std::vector<double> &dxdt, double t) {
    dxdt[0] = x[1];
    dxdt[1] = -x[0];
  };

  // Initial conditions
  std::vector<double> x = {1.0, 0.0};

  // Create a stepper
  using namespace numeric::odeint;
  runge_kutta4<std::vector<double>> stepper;

  // Integrate and print results
  std::cout << "Time\tPosition\tVelocity" << "\n";
  for (double t = 0.0; t < 10.0; t += 0.1) {
    std::cout << t << "\t" << x[0] << "\t" << x[1] << "\n";
    stepper.do_step(harmonic_oscillator, x, t, 0.1);
  }
}

void testStackTrace() {
  // Print the current stack trace
  std::cout << "Current stack trace:" << "\n";
  std::cout << stacktrace::stacktrace() << "\n";

  // Define a nested function to demonstrate stack depth
  auto nestedFunction = []() {
    std::cout << "Nested function stack trace:" << "\n";
    std::cout << stacktrace::stacktrace() << "\n";
  };

  // Call the nested function
  nestedFunction();

  // Demonstrate how to save a stack trace to a string
  std::stringstream ss;
  ss << stacktrace::stacktrace();
  std::string stackTraceString = ss.str();
  std::cout << "Stack trace saved to string:" << "\n";
  std::cout << stackTraceString << "\n";

  // Show how to get specific frame information
  stacktrace::stacktrace trace = stacktrace::stacktrace();
  if (trace.size() > 0) {
    std::cout << "First frame information:" << "\n";
    std::cout << "Frame address: " << trace[0].address() << "\n";
    std::cout << "Frame name: " << trace[0].name() << "\n";
    std::cout << "Frame source file: " << trace[0].source_file() << "\n";
    std::cout << "Frame source line: " << trace[0].source_line() << "\n";
  }
}