const fs = require("fs-extra")

const annotations = []

const getCoordinate = (coordinateString, key) => {
  const regex = new RegExp(`${key}(\\d+)`)
  const value = parseInt(coordinateString.match(regex)[1], 10)

  if (value === null || isNaN(value)) {
    throw `${key} parameter not found in ${coordinateString}`
  }

  return value
}

fs.readdir("../object_data", function(error, filenames) {
  filenames
    .filter(name => name.match(/\.jpe?g$/) !== null)
    .forEach(filename => {
      const imageData = {
        image: filename,
        annotations: [],
      }

      filename.replace(/.*_/, "").replace(/\.jpe?g$/, "").split("-").forEach(coordinateString => {
        imageData.annotations.push({
          "label": "VigetLogo",
          "coordinates": {
            "x": getCoordinate(coordinateString, "x"),
            "y": getCoordinate(coordinateString, "y"),
            "width": getCoordinate(coordinateString, "w"),
            "height": getCoordinate(coordinateString, "h"),
          }
        })
      })

      annotations.push(imageData)
    })

  fs.writeFileSync("../object_data/annotations.json", JSON.stringify(annotations, null, 2))
});
