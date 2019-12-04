const fs = require("fs-extra")
const gm = require("gm").subClass({ imageMagick: true })

fs.readdir("../object_data", function(error, filenames) {
  filenames
    .filter(name => name.match(/\.jpe?g$/) !== null)
    .forEach(filename => {
        gm(`../object_data/${filename}`)
          .autoOrient()
          .write(`../object_data/${filename}`, () => {})
    })
})
