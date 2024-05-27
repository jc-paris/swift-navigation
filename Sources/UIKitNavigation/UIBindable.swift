import Perception

#if canImport(Observation)
  import Observation
#endif

/// A property wrapper type that supports creating bindings to the mutable properties of observable
/// objects.
///
/// Like SwiftUI's `Bindable`, but for UIKit and other paradigms.
///
/// Use this property wrapper to create bindings to mutable properties of a data model object that
/// conforms to the `Observable` or `Perceptible` protocols. For example, the following code wraps
/// the book input with `@UIBindable`. Then it uses a `UITextField` to change the title property of
/// a book, and a `UISwitch` to change the `isAvailable` property, using the `$` syntax to pass a
/// binding for each property to those controls.
///
/// ```swift
/// @Observable
/// class Book: Identifiable {
///   var title = "Sample Book Title"
///   var isAvailable = true
/// }
///
///
/// final class BookEditViewController: UIViewController {
///   @Bindable var book: Book
///
///   // ...
///
///   func viewDidLoad() {
///     super.viewDidLoad()
///
///     let titleTextField = UITextField(text: $book.title)
///     let isAvailableSwitch = UISwitch(isOn: $book.isAvailable)
///
///     // Configure and add subviews...
///   }
/// }
/// ```
///
/// You can use the `UIBindable` property wrapper on properties and variables to an `Observable` (or
/// `Perceptible`) object. This includes global variables, properties that exists outside of SwiftUI
/// types, or even local variables.
@dynamicMemberLookup
@propertyWrapper
@MainActor
public struct UIBindable<Value>: Sendable {
  private let objectIdentifier: ObjectIdentifier

  public var wrappedValue: Value

  init(objectIdentifier: ObjectIdentifier, wrappedValue: Value) {
    self.objectIdentifier = objectIdentifier
    self.wrappedValue = wrappedValue
  }

  /// Creates a bindable object from a perceptible object.
  ///
  /// This initializer is equivalent to `init(wrappedValue:)`, but is more succinct when when
  /// creating bindable objects nested within other expressions.
  @_disfavoredOverload
  public init(_ wrappedValue: Value) where Value: AnyObject & Perceptible {
    self.init(objectIdentifier: ObjectIdentifier(wrappedValue), wrappedValue: wrappedValue)
  }

  /// Creates a bindable object from a perceptible object.
  ///
  /// You should not call this initializer directly. Instead, declare a property with the
  /// `@UIBindable` attribute, and provide an initial value.
  @_disfavoredOverload
  public init(wrappedValue: Value) where Value: AnyObject & Perceptible {
    self.init(objectIdentifier: ObjectIdentifier(wrappedValue), wrappedValue: wrappedValue)
  }

  /// Creates a bindable from the value of another bindable.
  public init(projectedValue: Self) {
    self = projectedValue
  }

  /// The bindable wrapper for the object that creates bindings to its properties using dynamic
  /// member lookup.
  public var projectedValue: Self {
    self
  }

  /// Returns a binding to the value of a given key path.
  public subscript<Member>(
    dynamicMember keyPath: ReferenceWritableKeyPath<Value, Member>
  ) -> UIBinding<Member> where Value: AnyObject {
    UIBinding(root: wrappedValue, keyPath: keyPath, transaction: UITransaction())
  }
}

#if canImport(Observation)
  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  extension UIBindable where Value: AnyObject & Observable {
    /// Creates a bindable object from an observable object.
    ///
    /// This initializer is equivalent to `init(wrappedValue:)`, but is more succinct when when
    /// creating bindable objects nested within other expressions.
    public init(_ wrappedValue: Value) {
      self.init(objectIdentifier: ObjectIdentifier(wrappedValue), wrappedValue: wrappedValue)
    }

    /// Creates a bindable object from an observable object.
    ///
    /// You should not call this initializer directly. Instead, declare a property with the
    /// `@UIBindable` attribute, and provide an initial value.
    public init(wrappedValue: Value) {
      self.init(objectIdentifier: ObjectIdentifier(wrappedValue), wrappedValue: wrappedValue)
    }
  }
#endif

extension UIBindable: Equatable {
  nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.objectIdentifier == rhs.objectIdentifier
  }
}

extension UIBindable: Hashable {
  nonisolated public func hash(into hasher: inout Hasher) {
    hasher.combine(objectIdentifier)
  }
}

extension UIBindable: Identifiable {
  public struct ID: Hashable {
    fileprivate let rawValue: ObjectIdentifier
  }

  nonisolated public var id: ID {
    ID(rawValue: objectIdentifier)
  }
}
