<div style="text-align: center">
  <img src="./docs/iiv__demo.gif" />
</div>

Is It Viget is a demo project created for a [Viget.com article](https://www.viget.com/articles/animated-ios-launch-screen). It's *also* a machine-learning-trained app that detects the Viget logo with your phone's camera.

This readme covers managing and updating the ML app. **If you're just following the viget.com tutorial, ignore this readme for now!**

1. [Development](#development)
1. [The Model](#the-model)
1. [Design Notes](#design-notes)

---

# Development

Open the `/ios` directory in Xcode to work on the app.

---

# The Model

## Training

- Open Xcode, then go to Xcode > Open Developer Tool > Create ML
- Inside Create ML, open `model/VigetLogoClassifier.mlproj`
- Click "Add"
- Set your new classifier's input to `model/data`
- Click "Train"
- Once finished:
  - Drag the file from "Output" out onto your Desktop
  - Rename it to `VigetLogoClassifier.mlmodel`
  - Import it into Xcode, replacing the existing model

If you want to test your model _before_ adding it to the app, do the following after the "Add" step:

- Before dragging `/models/data` over, remove ~30 images from each directory and move them to a `data-testing` folder with the same structure.
- Select this folder as your "Test Data"
- Continue the training steps

## Updating the training data

Images are scaled down significantly when training, so you can safely shrink them _before_ this step to save on file size. This requires installing `imagemagick` on your computer.

To add data to the training set, do the following:

- Add your photos to `model/data/VigetLogo` or `model/data/NotViget`
- Run `./bin/resize-model-images`. This does two things:
  - Resizes all images to rectangles measuring 299px on the smallest side, and if not already a JPG, saves a new copy as a JPG
  - Deletes all non-JPG files from the directory.

Note that images imported into the Create ML project are automatically cropped to square — your logo _must_ be in the center square of the image. To quickly check that your images are correct:

- Run `./bin/test-model-image-crop`
- Open the `./model/data-cropped/VigetLogo` folder and visually review images. This folder is gitignored and replaced each time you run the command, so don't worry about deleting it after.

---

# Design notes

## Files and exports

The design file `design/IsItViget.afdesign` can be opened with [Affinity Designer](https://affinity.serif.com/en-us/designer/).

All artboards have been exported to `design/exports` as PDFs, and slices should already be set up with the correct configs.

## Fonts

The three fonts used are:

- [Yesteryear](https://fonts.google.com/specimen/Yesteryear) (Google)
- [Ansley](https://befonts.com/ansley-display.html) (Behance, via Kady Jesko)
- [Built Titling](https://www.dafont.com/built-titling.font) (Typodermic Fonts)

You'll need to install these before opening the `.afdesign` file.

## App Icon

Export the AppIcon slice from Affinity Designer (1024x1024, JPG) and use https://appicon.co to generate the app icon.

- Uncheck everything except "iPhone" and "iPad"
- Upload the icon
- Click "Generate"
- Open the ZIP to find the `AppIcon.appiconset` folder
- In Xcode, open the `Assets.xcassets` folder and delete the existing `AppIcon`.
- Drag the `AppIcon.appiconset` folder into your assets.
