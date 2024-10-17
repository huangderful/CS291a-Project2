# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def main(event:, context:)
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
  response(body: event, status: 200)
end

def response(body: nil, status: 200)
  # check if this gives an error
  begin
    JSON.parse(body.to_json)
  rescue JSON::ParserError
    return { statusCode: 422 }
  end

  if body["path"] == '/token'
    if body["httpMethod"] != "POST"
      return { statusCode: 405 }
    end
    if body["headers"]["Content-Type"] != "application/json"
      return  {
        statusCode: 415,
      }
    end
    # Generate a token
    payload = {
      data: body["body"],
      exp: Time.now.to_i + 5,
      nbf: Time.now.to_i + 2
    }
    token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
    return {
      body: body ? body.to_json + "\n" : '',
      statusCode: 201,
      token: token
    }
  elsif body["path"] == '/'
    if body["httpMethod"] != "GET"
      return { statusCode: 405 }
    end
    authorization_header = body["headers"]["Authorization"]
    # Split the string
    bearer = authorization_header[0, 7] 
    token = authorization_header[7..-1]
    if bearer != "Bearer "
      return { statusCode: 403 }
    end
    decoded = JWT.decode token, ENV['JWT_SECRET'], 'HS256'
    decoded_payload = decoded[0]  # Access the first element (the payload)
    if Time.now.to_i >= decoded_payload["exp"] or Time.now.to_i < decoded_payload["nbf"]
      return { statusCode: 401 }
    end 
    return {
      body: decoded_payload["data"] ? decoded_payload["data"].to_json + "\n" : '',
      statusCode: 200
    }
  else 
    return { statusCode: 404 }
  end
end

if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  PP.pp main(context: {}, event: {
               'body' => '{"name": "bboe"}',
               'headers' => { 'Content-Type' => 'application/json' },
               'httpMethod' => 'POST',
               'path' => '/token'
             })

  # Generate a token
  payload = {
    data: { user_id: 128 },
    exp: Time.now.to_i + 1,
    nbf: Time.now.to_i
  }
  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  # Call /
  PP.pp main(context: {}, event: {
               'headers' => { 'Authorization' => "Bearer #{token}",
                              'Content-Type' => 'application/json' },
               'httpMethod' => 'GET',
               'path' => '/'
             })
end
