const latitude = "33.7223";
const longitude = "151.2984";

const forecastRequest = Functions.makeHttpRequest({
  url: `https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/rest/ForecastService/GetWeatherForecast`,
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

const waveConditions = {
  waveMaxLength: 0,
  wavePower: 0,
  waveSpeed: 0,
  waveCapacity: 0,
};

function calculateAverage(arr) {
  return (
    arr.reduce((accumulator, currentValue) => accumulator + currentValue, 0) /
    arr.length
  );
}

const waveHeightAvg = calculateAverage(
  forecastResponse.data.hourly.wave_height
);
const waveDirectionAvg = calculateAverage(
  forecastResponse.data.hourly.wave_direction
);
const wavePeriodAvg = calculateAverage(
  forecastResponse.data.hourly.wave_period
);

return Functions.encodeString("25525023012");
