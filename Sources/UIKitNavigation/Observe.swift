import UIKit

extension NSObject {
  @discardableResult
  @MainActor
  public func observe(
    _ apply: @escaping @MainActor @Sendable (UITransaction) -> Void
  ) -> ObservationToken {
    let token = UIKitNavigation.observe { transaction in
      if transaction.disablesAnimations {
        UIView.performWithoutAnimation { apply(transaction) }
        for completion in transaction.animationCompletions {
          completion(true)
        }
      } else if let animation = transaction.animation {
        return animation.perform(
          { apply(transaction) },
          completion: transaction.animationCompletions.isEmpty
            ? nil
            : {
              for completion in transaction.animationCompletions {
                completion($0)
              }
            }
        )
      } else {
        apply(transaction)
        for completion in transaction.animationCompletions {
          completion(true)
        }
      }
    }
    tokens.insert(token)
    return token
  }

  @discardableResult
  @MainActor
  public func observe(_ apply: @escaping @MainActor @Sendable () -> Void) -> ObservationToken {
    observe { _ in apply() }
  }

  fileprivate var tokens: Set<ObservationToken> {
    get {
      objc_getAssociatedObject(self, tokensKey) as? Set<ObservationToken> ?? []
    }
    set {
      objc_setAssociatedObject(self, tokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

private let tokensKey = malloc(1)!
