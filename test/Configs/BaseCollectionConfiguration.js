const { stringToBytes32 } = require("./CommonPreparation.js");

/**
 *
 * Define collection traits
 *
 */
async function setupCharacterAttributes(collectionInstance) {
  let armsPinkSVG =
    "<g class='monster-left-arm'> <path id='Shape' d='M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z' transform='translate(-114.73)' style='fill: #df4d60' /></g><g class='monster-right-arm'> <path id='Shape-2' data-name='Shape' d='M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z' transform='translate(-114.73)' style='fill: #df4d60' /></g>";

  let armsYellowSVG =
    "<g class='monster-left-arm-yellow'> <path id='Shape' d='M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z' transform='translate(-114.73)' style='fill: #df4d60' /></g><g class='monster-right-arm'> <path id='Shape-2' data-name='Shape' d='M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z' transform='translate(-114.73)' style='fill: #df4d60' /></g>";
  // Numerical attributes with rarity
  await collectionInstance.addNumberTrait(
    stringToBytes32("Strength"),
    100,
    0,
    100
  );
  await collectionInstance.addNumberTrait(
    stringToBytes32("Dexterty"),
    1,
    0,
    100
  );

  await collectionInstance.addOptionsWithImageTrait(
    stringToBytes32("Arms"),
    100,
    [
      stringToBytes32("Pink"),
      stringToBytes32("Grey"),
      stringToBytes32("Yellow"),
      stringToBytes32("Red"),
      stringToBytes32("Blue"),
    ],
    [10, 20, 30, 20, 20],
    [armsPinkSVG, armsPinkSVG, armsYellowSVG, armsPinkSVG, armsPinkSVG]
  );

  await collectionInstance.addOptionsTrait(
    stringToBytes32("Weapon"),
    100,
    [
      stringToBytes32("Sword"),
      stringToBytes32("Axe"),
      stringToBytes32("Bow"),
      stringToBytes32("Knife"),
      stringToBytes32("Fork"),
    ],
    [10, 20, 30, 20, 20]
  );

  await collectionInstance.addTextTrait(
    stringToBytes32("TextTrait"),
    100,
    stringToBytes32("Default Value")
  );
}

/**
 *
 * Define collection traits
 *
 */
async function setupBoardAttributes(collectionInstance) {
  await collectionInstance.addNumberTrait(
    stringToBytes32("Speed"),
    100,
    20,
    100
  );
}

module.exports = {
  setupCharacterAttributes,
  setupBoardAttributes,
};
