#include <boost/algorithm/algorithm.hpp>
#include <boost/any.hpp>
#include <boost/array.hpp>
#include <boost/asio.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/bind.hpp>
#include <boost/config.hpp>
#include <boost/hana.hpp>
#include <boost/multi_array.hpp>
#include <boost/pfr.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/unordered_map.hpp>
#include <boost/unordered_set.hpp>
#include <boost/variant.hpp>
#include <boost/version.hpp>

#include <iostream>

using namespace boost;

int main() {
  std::cout << "Boost version " << BOOST_VERSION / 100000 << "."
            << BOOST_VERSION / 100 % 1000 << "." << BOOST_VERSION % 100
            << std::endl;

  asio::io_context io_service;

  // Example using boost::variant
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

  return 0;
}