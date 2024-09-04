#include <boost/asio/as_tuple.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/beast.hpp>
#include <boost/cobalt.hpp>
#include <boost/cobalt/main.hpp>
#include <iostream>

namespace async = boost::cobalt;
using boost::asio::ip::tcp;
using tcp_acceptor = async::use_op_t::as_default_on_t<tcp::acceptor>;
using tcp_socket = async::use_op_t::as_default_on_t<tcp::socket>;
namespace this_coro = boost::cobalt::this_coro;
namespace beast = boost::beast;
namespace http = beast::http;

async::promise<void> handle_request(tcp_socket socket) {
  try {
    beast::flat_buffer buffer;
    http::request<http::string_body> request;

    co_await http::async_read(socket, buffer, request,
                              boost::asio::as_tuple(async::use_op));

    http::response<http::string_body> response(http::status::ok,
                                               request.version());
    response.set(http::field::server, "Boost/AsyncHTTPServer");

    // Extract the requested path from the HTTP request.
    std::string_view path = request.target();

    // Define different routes and their corresponding responses.
    if (path == "/") {
      response.body() = "Welcome to the root route!";
    } else if (path == "/hello") {
      response.body() = "Hello, World!";
    } else {
      response = http::response<http::string_body>(http::status::not_found,
                                                   request.version());
      response.body() = "404 Not Found";
    }

    response.prepare_payload();
    co_await http::async_write(socket, response,
                               boost::asio::as_tuple(async::use_op));
  } catch (std::exception &e) {
    std::cerr << "HTTP Request Handling Exception: " << e.what() << std::endl;
  }
}

async::generator<tcp_socket> listen() {
  tcp_acceptor acceptor({co_await this_coro::executor}, {tcp::v4(), 8080});

  for (;;) {
    co_yield co_await acceptor.async_accept();
  }
}

async::promise<void> run_server(async::wait_group &workers) {
  auto l = listen();

  while (true) {
    if (workers.size() < 10u)
      workers.push_back(handle_request(co_await l));
    else
      co_await workers.wait_one();
  }
}

async::main co_main(int argc, char **argv) {
  co_await async::with(async::wait_group(), &run_server);
  co_return 0u;
}