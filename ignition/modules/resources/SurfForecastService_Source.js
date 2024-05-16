//Hardcoded for Narrabeen
const latitude = "33.7223";
const longitude = "151.2984";

const forecastRequest = Functions.makeHttpRequest({
  url: `https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/rest/ForecastService/GetWeatherForecastPrepared`,
  headers: {
    "Content-Type": "application/json",
    API_KEY: secrets.apiKey,
  },
  method: "GET",
  params: {
    Latitude: latitude,
    Longitude: longitude,
  },
});

const forecastResponse = await forecastRequest;

if (forecastResponse.error) {
  console.log(forecastResponse.message);
}

return Functions.encodeString(forecastResponse.data.toString());
