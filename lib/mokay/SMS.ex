defmodule Mokay.SMS do
  def send(%{sid: sid, auth_token: auth_token, from: from, to: to}) do
    case HTTPoison.post(
           get_twilio_endpoint(sid),
           URI.encode_query(%{From: from, To: to, Body: "Coffee is ready dude!"}),
           [{"Content-Type", "application/x-www-form-urlencoded"}],
           hackney: [basic_auth: {sid, auth_token}]
         ) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        case Jason.decode(body) do
          {:ok, json} ->
            if Enum.member?([nil, "failed", "undelivered"], Map.get(json, "status")) do
              {:error, "Error sending sms, response body was:\n#{body}"}
            else
              {:ok, json}
            end

          {:error, _} ->
            {:error, "Error parsing json response"}
        end

      {:ok, %HTTPoison.Response{status_code: _, body: body}} ->
        {:error, "Error connecting to api, response body was:\n#{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp get_twilio_endpoint(sid) do
    "https://api.twilio.com/2010-04-01/Accounts/#{sid}/Messages.json"
  end
end
