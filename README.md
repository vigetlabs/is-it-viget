![demo](./docs/iiv__demo.gif)

Is It Viget is a demo project created for a [Viget.com article](https://www.viget.com/articles/animated-ios-launch-screen). It's *also* a machine-learning-trained app that detects the Viget logo with your phone's camera.

This readme covers managing and updating the ML app. **If you're just following the viget.com tutorial, ignore this readme for now!**

1. [Development](#development)
1. [The Model](#the-model)
1. [Design Notes](#design-notes)
1. [Distribution (Internal)](#distribution)

---

# Development

Open the `/ios` directory in Xcode to work on the app.

---

# The Model

## Training

- Open Xcode, then go to Xcode > Open Developer Tool > Create ML
- Inside Create ML, open `model/VigetLogoDetector.mlproj`
- Click "Add"
- Set your new classifier's input to `model/object_data`
- Set "maximum iterations" to at least 2500
- Click "Train", and wait...for a while
- Once finished:
  - Drag the file from "Output" out onto your Desktop
  - Rename it to `VigetLogoLogoDetector.mlmodel`
  - Import it into Xcode, replacing the existing model

If you want to test your model _before_ adding it to the app, do the following after the "Add" step:

- Before dragging `/models/object_data` over, and move ~30 images from each directory and into a `object_data_testing` folder with the same structure.
- Select this folder as your "Test Data"
- Continue the training steps

## Updating the training data

Object detection requires a lot of manual work, so there are a few scripts in IIV to help you out. The steps for adding new data:

- CD into `model/object_scripts` and `yarn install`
- Convert any `.heic` files to `.jpgs` with this bash command: `find -E ../object_data -iregex '.*\.heic$' -exec mogrify -format jpg -quality 100 {} +`
- Delete leftover `.heic` files with `find -E ../object_data -iregex '.*\.heic$' -exec rm {} +`
- Examine the image you want to add, and note the Y/X/width/height pixels of any Viget logos
- Rename the file from `{{filename}}.jpg` to `{{filename}}_x50y100w100h100-x60y100w100h100`, where each value matches the pixel coordinates from the image, and each logo position is separated by a dash.
- Run `yarn run remove-rotation` to fix any EXIF rotation issues
- Run `yarn run annotate` to generate the `annotations.json` file required by Create ML
- To check your work, run `yarn run test-bounding-boxes`. This will create a `model/object_data_bounding_boxes` folder with cropped images representing each logo. You should be able to visually scan them as thumbnails.

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

---

# Distribution

## Setup Fastlane

- `bundle update`
- `bundle exec fastlane match appstore`

## Sending to TestFlight

In Xcode, update both the version and build number in Targets > Is It Viget.

Then, run `bundle exec fastlane release`. This will build the app and send it to TestFlight.

Once everything is finished, commit your change and push it to the `release` branch.

After your build finishes processing, you'll need to submit it to Apple.

- Open https://appstoreconnect.apple.com/apps/1486984018/testflight/groups/22f7f008-52b1-4ebd-9c1f-a14568e0eb47
- Go down to Build and click the + icon
- Select the newest build, click "Next"
- Put "Version bump, no new functionality." or something similar into "What to test", and submit

Apple should review the app within a few days, and it'll appear in TestFlight after they approve it.
