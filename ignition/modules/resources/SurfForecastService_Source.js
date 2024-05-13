//Hardcoded for Narrabeen
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

const waveHeightAvg = calculateAverage(
  forecastResponse.data.hourly.wave_height
);
const waveDirectionAvg = calculateAverage(
  forecastResponse.data.hourly.wave_direction
);
const wavePeriodAvg = calculateAverage(
  forecastResponse.data.hourly.wave_period
);

const scoreFromSwellDirection = scoreFromDegree(waveDirectionAvg);
waveConditions.waveCapacity = Math.trunc(scoreFromSwellDirection);
waveConditions.waveMaxLength = Math.trunc(
  wavePeriodAvg * scoreFromSwellDirection
);
waveConditions.wavePower = Math.trunc(waveHeightAvg * scoreFromSwellDirection);
waveConditions.waveSpeed = Math.trunc(scoreFromSwellDirection * 3);

let waveConditionsFormatted = "";
for (let key in waveConditions) {
  let currentValue = waveConditions[key].toString();
  waveConditionsFormatted += currentValue.length + currentValue;
}

return Functions.encodeString(waveConditionsFormatted);

function calculateAverage(arr) {
  return (
    arr.reduce((accumulator, currentValue) => accumulator + currentValue, 0) /
    arr.length
  );
}

function scoreFromDegree(degree) {
  const normalizedDegree = ((degree % 360) + 360) % 360;

  const difference = Math.min(
    Math.abs(normalizedDegree - 180),
    360 - Math.abs(normalizedDegree - 180)
  );

  const spread = 60;
  const peakValue = 5;
  const minValue = 1;

  const score =
    peakValue * Math.exp(-Math.pow(difference, 2) / (2 * Math.pow(spread, 2)));

  return Math.max(minValue, Math.round(score));
}
