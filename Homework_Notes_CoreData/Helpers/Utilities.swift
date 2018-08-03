
import UIKit

func showAlert(title: String, message: String, in presentingController: UIViewController?, handler: @escaping () -> Void) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
        handler()
    }
    alertController.addAction(okAction)
    presentingController?.present(alertController, animated: true, completion: nil)
}

func showError(_ message: String, in presentingController: UIViewController?) {
    showAlert(title: "Error", message: message, in: presentingController) { }
}

func showFatalError(_ message: String, in presentingController: UIViewController? = UIApplication.shared.topMostViewController) {
    showAlert(title: "Fatal Error", message: message, in: presentingController) { fatalError(message) }
}

extension UIViewController { @objc var topmostViewController: UIViewController? { return presentedViewController?.topmostViewController ?? self } }

extension UINavigationController { @objc override var topmostViewController: UIViewController? { return visibleViewController?.topmostViewController } }

extension UIApplication { var topMostViewController: UIViewController? { return self.keyWindow?.rootViewController?.topmostViewController } }
