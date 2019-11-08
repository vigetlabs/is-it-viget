import UIKit

class LaunchScreenManager {

    // MARK: - Properties

    static let instance = LaunchScreenManager(animationDurationBase: 1.3)

    var view: UIView?
    var parentView: UIView?

    let animationDurationBase: Double

    let logoQuestionMarkViewTag = 100
    let logoIsItViewTag = 101
    let logoVigetViewTag = 102


    // MARK: - Lifecycle

    init(animationDurationBase: Double) {
        self.animationDurationBase = animationDurationBase
    }


    // MARK: - Animate

    func animateAfterLaunch(_ parentViewPassedIn: UIView) {
        parentView = parentViewPassedIn
        view = loadView()

        fillParentViewWithView()

        hideLogo()
        hideRingSegments()
    }

    func loadView() -> UIView {
        return UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

    func fillParentViewWithView() {
        parentView!.addSubview(view!)

        view!.frame = parentView!.bounds
        view!.center = parentView!.center
    }

    func hideLogo() {
        let logoQuestionMark = view!.viewWithTag(logoQuestionMarkViewTag)!
        let logoIsIt = view!.viewWithTag(logoIsItViewTag)!
        let logoViget = view!.viewWithTag(logoVigetViewTag)!

        UIView.animate(
            withDuration: animationDurationBase / 3,
            delay: self.animationDurationBase / 6,
            options: .curveEaseOut,
            animations: {
                logoIsIt.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: self.animationDurationBase / 6,
                    delay: 0,
                    options: .curveEaseIn,
                    animations: {
                        logoIsIt.alpha = 0
                        logoIsIt.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    }
                )
            }
        )

        UIView.animate(
            withDuration: animationDurationBase / 4,
            delay: animationDurationBase / 3,
            options: .curveEaseOut,
            animations: {
                logoViget.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: self.animationDurationBase / 6,
                    delay: 0,
                    options: .curveEaseIn,
                    animations: {
                        logoViget.alpha = 0
                        logoViget.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    }
                )
            }
        )

        UIView.animate(
            withDuration: animationDurationBase / 4,
            delay: animationDurationBase / 2,
            options: .curveEaseIn,
            animations: {
                logoQuestionMark.alpha = 0
                logoQuestionMark.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        )
    }

    func hideRingSegments() {
        let distanceToMove = parentView!.frame.size.height * 1.75

        for number in 1...12 {
            let ringSegment = view!.viewWithTag(number)!

            // Get the degrees we want to move to
            let degrees = 360 - (number * 30) + 15

            // Convert to float
            let angle = CGFloat(degrees)

            // Convert to radians
            let radians = angle * (CGFloat.pi / 180)

            // Calculate the final X value from this angle and the total distance.
            // See https://academo.org/demos/rotation-about-point/ for more.
            let translationX = (cos(radians) * distanceToMove)
            let translationY = (sin(radians) * distanceToMove) * -1

            UIView.animate(
                withDuration: animationDurationBase * 1.75,
                delay: animationDurationBase / 1.5,
                options: .curveLinear,
                animations: {
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: translationX, y: translationY)

                    // This rotation accounts for the curve in the segment images.
                    // I just eyeballed it; different curves will require tweaks.
                    transform = transform.rotated(by: -1.95)

                    ringSegment.transform = transform
                }
            )

            // When segments are very curved, sometimes pieces of them reappear on-screen
            // before the animation finishes. This timer stops the animation early and removes
            // the entire view.
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDurationBase * 1.25) {
                self.view!.removeFromSuperview()
            }

            /*
                // Uncomment this code (and comment the above code)
                // to "freeze" the ring animation for easier visual debugging
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                    let pausedTime: CFTimeInterval = ringSegment.layer.convertTime(CACurrentMediaTime(), from: nil)
                    ringSegment.layer.timeOffset = pausedTime
                    ringSegment.layer.speed = 0.0
                }
            */

        }
    }
}
