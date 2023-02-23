# frozen_string_literal: true

require 'minitest/autorun'
require 'webmock/minitest'

require_relative '../../app.rb'

class AppTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def test_without_auth
    e = {
      'headers' => {}
    }

    expected_result = {
      headers: {"WWW-Authenticate": "Basic realm=\"Secret Zone\""},
      statusCode: 401,
      body: JSON.generate(ok: false)
    }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

  def test_with_auth
    ENV['GROWTH_FORECAST_ROOT'] = 'http://localhost:5125'
    ENV['GROWTH_FORECAST_USERNAME'] = 'user'
    ENV['GROWTH_FORECAST_PASSWORD'] = 'password'

    e = {
      'headers' => {
        'Authorization' => 'Basic dXNlcjpwYXNzd29yZA=='
      },
      'pathParameters' => {
        'service_name' =>'service',
        'section_name' => 'section',
        'graph_name' => 'graph',
      }
    }

    stub_request(:get, 'http://localhost:5125/xport/service/section/graph').
      to_return(status: 200, body: {
        "column_names" => ["graph"],
        "rows" => [[nil],[10],[15]],
        "step" => 600,
        "columns" => 1,
        "start_timestamp" => 1677037800,
        "end_timestamp" => 1677156600
      }.to_json, headers: { }
    )

    expected_result = { statusCode: 200, body: JSON.generate({
      "columns" => [
        {
          "name" => "date",
          "type" => "date",
          "friendly_name" => "date"
        },
        {
          "name" => "graph",
          "type" => "integer",
          "friendly_name" => "graph"
        }
      ],
      "rows" => [
        {"date" => "2023-02-22 12:50:00", "graph" => nil},
        {"date" => "2023-02-22 13:00:00", "graph" => 10},
        {"date" => "2023-02-22 13:10:00", "graph" => 15}
      ]
      })
    }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

end
