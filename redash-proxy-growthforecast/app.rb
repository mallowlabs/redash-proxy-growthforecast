require 'httparty'
require 'active_support'
require 'active_support/core_ext'
require 'json'
require 'base64'

def lambda_handler(event:, context:)
  growth_forecast_root = ENV['GROWTH_FORECAST_ROOT']
  growth_forecast_username = ENV['GROWTH_FORECAST_USERNAME']
  growth_forecast_password = ENV['GROWTH_FORECAST_PASSWORD']

  # basic auth
  unless auth?(event, growth_forecast_username, growth_forecast_password)
    return {
      headers: {'WWW-Authenticate': "Basic realm=\"Secret Zone\""},
      statusCode: 401,
      body: {ok: false}.to_json
    }
  end

  begin
    service_name = event['pathParameters']['service_name']
    section_name = event['pathParameters']['section_name']
    graph_name = event['pathParameters']['graph_name']
    query = event['queryStringParameters'] || {}
    url = "#{growth_forecast_root}/xport/#{service_name}/#{section_name}/#{graph_name}?#{query.to_query}"

    response = HTTParty.get(url, {basic_auth: {username: growth_forecast_username, password: growth_forecast_password}})

    json = JSON.parse(response.body)
    body = convert(json)
    {
      statusCode: response.code,
      body: body.to_json
    }
  rescue HTTParty::Error => error
    puts error.inspect
    raise error
  end
end

def auth?(event, growth_forecast_username, growth_forecast_password)
  authorization = event['headers']['Authorization'] || ''
  authorization.gsub(/Basic\s+/, '').strip ==
    Base64.encode64("#{growth_forecast_username}:#{growth_forecast_password}").strip
end

def convert(json)
  column_names = json['column_names']
  rows = json['rows']
  start_timestamp = json['start_timestamp']
  step = json['step']

  # columns
  redash_columns = [
    {
      name: "date",
      type: "date",
      friendly_name: "date"
    }
  ].concat(column_names.map { |c|
    {
      name: c,
      type: "integer",
      friendly_name: c
    }
  })

  # rows
  redash_rows = rows.map { |cells|
    hash = {}
    hash['date'] = Time.at(start_timestamp).strftime('%Y-%m-%d %H:%M:%S')
    cells.each_with_index { |c, i|
      hash[column_names[i]] = c
    }
    start_timestamp += step
    hash
  }

  # body
  {
    columns: redash_columns,
    rows: redash_rows
  }
end
