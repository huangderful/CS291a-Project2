# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def main(event:, context:)
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
  if event["path"] == '/auth/token'
    if event["httpMethod"] != "POST"
      return { statusCode: 405 }
    end

    headers = event["headers"].transform_keys(&:downcase)
    if headers["content-type"] != "application/json"
      return { statusCode: 415 }
    end

    begin
      if event["body"].nil?
        return response(status: 422)
      end
      parsed_body = JSON.parse(event["body"])
      payload = {
        data: parsed_body,
        exp: Time.now.to_i + 5,
        nbf: Time.now.to_i + 2
      }
      token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
      resp = {"token" => token}
      return response(body: resp, status: 201)
    rescue JSON::ParserError
      return response(status: 422)
    end
    


  elsif event["path"] == '/'
    begin 
      if event["httpMethod"] != "GET"
        return { statusCode: 405 }
      end
      begin 
        headers = event["headers"].transform_keys(&:downcase)
        authorization_header = headers["authorization"]
        # Split the string
        bearer = authorization_header[0, 7] 
        if bearer != "Bearer "
          return response(body: "BEARER1", status: 403)
        end
      rescue
        return response(body: "BEARER", status: 403)
      end
      token = authorization_header[7..-1]
      begin
        decoded = JWT.decode token, ENV['JWT_SECRET'], true, {algorithm: 'HS256'}
        decoded_payload = decoded[0]
      rescue JWT::ImmatureSignature
        return response(status: 401)
      rescue JWT::ExpiredSignature
        return response(status: 401)
      rescue JWT::DecodeError => e
        return response(body: "DECODING", status: 403)
      end
      resp = decoded_payload["data"]
      return response(body: resp, status: 200)
    rescue
      # MINE
      return response(status: 425)
    end
    else 
      return response(status: 404)
    end
end

def response(body: nil, status: 200)
  # check if this gives an error
  {
    body: body ? body.to_json + "\n" : '',
    statusCode: status
  }
end

if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  # Call your function and get the response
  response = main(context: {}, event: {
    'body' => '{"cool": "123"}',
    'headers' => { 'ConteNt-Type' => 'application/json' },
    'httpMethod' => 'POST',
    'path' => '/auth/token'
  })

  token = response[:body]

  json_object = JSON.parse(token)

  # Now you can use json_object as a hash
  puts json_object["token"]
  # # Generate a token
  # payload = {
  #   data: { user_id: 128 },
  #   exp: Time.now.to_i + 1,
  #   nbf: Time.now.to_i
  # }
  # token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  # # # # Call /
  PP.pp main(context: {}, event: {
               'headers' => { 'Content-Type' => 'application/json',
              'AuthorizaTion' => "Bearer #{json_object['token']}" },
               'httpMethod' => 'GET',
               'path' => '/'
             })
end
