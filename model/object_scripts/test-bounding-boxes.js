const fs = require("fs-extra")
const gm = require("gm").subClass({ imageMagick: true })

const getCoordinate = (coordinateString, key) => {
  const regex = new RegExp(`${key}(\\d+)`)
  const value = parseInt(coordinateString.match(regex)[1], 10)

  if (value === null || isNaN(value)) {
    throw `${key} parameter not found in ${coordinateString}`
  }

  return value
}

fs.ensureDir("../object_data_bounding_boxes", () => {
  fs.emptyDir("../object_data_bounding_boxes", () => {
    fs.readdir("../object_data", function(error, filenames) {
      filenames
        .filter(name => name.match(/\.jpe?g$/) !== null)
        .forEach(filename => {
          console.log(filename);

          const filenameBase = filename.match(/.*_/)[0]
          filename.replace(/.*_/, "").replace(/\.jpe?g$/, "").split("-").forEach(coordinateString => {
            const x = getCoordinate(coordinateString, "x")
            const y = getCoordinate(coordinateString, "y")
            const w = getCoordinate(coordinateString, "w")
            const h = getCoordinate(coordinateString, "h")

            gm(`../object_data/${filename}`)
              .crop(w, h, x, y)
              .write(`../object_data_bounding_boxes/${filenameBase}${coordinateString}.jpg`, () => {})
          })
        })
    })
  })
})
