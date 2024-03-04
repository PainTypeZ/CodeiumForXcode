import AIModel
import Configs
import Foundation

public protocol UserDefaultsType {
    func value(forKey: String) -> Any?
    func set(_ value: Any?, forKey: String)
}

public extension UserDefaults {
    static var shared = UserDefaults(suiteName: userDefaultSuiteName)!

    static func setupDefaultSettings() {
        shared.setupDefaultValue(for: \.quitXPCServiceOnXcodeAndAppQuit)
        shared.setupDefaultValue(for: \.realtimeSuggestionToggle)
        shared.setupDefaultValue(for: \.realtimeSuggestionDebounce)
        shared.setupDefaultValue(for: \.automaticallyCheckForUpdate)
        shared.setupDefaultValue(for: \.suggestionPresentationMode)
        shared.setupDefaultValue(for: \.widgetColorScheme)
        shared.setupDefaultValue(for: \.customCommands)
        shared.setupDefaultValue(for: \.runNodeWith, defaultValue: .env)
        shared.setupDefaultValue(for: \.chatModels)
        shared.setupDefaultValue(for: \.embeddingModels)
        shared.setupDefaultValue(
            for: \.suggestionFeatureProvider,
            defaultValue: .builtIn(shared.deprecatedValue(for: \.oldSuggestionFeatureProvider))
        )
    }
}

extension UserDefaults: UserDefaultsType {}

public protocol UserDefaultsStorable {}

extension Int: UserDefaultsStorable {}
extension Double: UserDefaultsStorable {}
extension Bool: UserDefaultsStorable {}
extension String: UserDefaultsStorable {}
extension Data: UserDefaultsStorable {}
extension URL: UserDefaultsStorable {}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

public extension UserDefaultsType {
    // MARK: Normal Types

    func value<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) -> K.Value where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        return (value(forKey: key.key) as? K.Value) ?? key.defaultValue
    }

    func set<K: UserDefaultPreferenceKey>(
        _ value: K.Value,
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        set(value, forKey: key.key)
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(key.defaultValue, forKey: key.key)
        }
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>,
        defaultValue: K.Value
    ) where K.Value: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(defaultValue, forKey: key.key)
        }
    }

    // MARK: Raw Representable

    func value<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) -> K.Value where K.Value: RawRepresentable, K.Value.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? String else {
            return key.defaultValue
        }
        return K.Value(rawValue: rawValue) ?? key.defaultValue
    }

    func value<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) -> K.Value where K.Value: RawRepresentable, K.Value.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? Int else {
            return key.defaultValue
        }
        return K.Value(rawValue: rawValue) ?? key.defaultValue
    }

    func set<K: UserDefaultPreferenceKey>(
        _ value: K.Value,
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: RawRepresentable, K.Value.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        set(value.rawValue, forKey: key.key)
    }

    func set<K: UserDefaultPreferenceKey>(
        _ value: K.Value,
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>
    ) where K.Value: RawRepresentable, K.Value.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        set(value.rawValue, forKey: key.key)
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>,
        defaultValue: K.Value? = nil
    ) where K.Value: RawRepresentable, K.Value.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(defaultValue?.rawValue ?? key.defaultValue.rawValue, forKey: key.key)
        }
    }

    func setupDefaultValue<K: UserDefaultPreferenceKey>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, K>,
        defaultValue: K.Value? = nil
    ) where K.Value: RawRepresentable, K.Value.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        if value(forKey: key.key) == nil {
            set(defaultValue?.rawValue ?? key.defaultValue.rawValue, forKey: key.key)
        }
    }
}

// MARK: - Deprecated Key Accessor

public extension UserDefaultsType {
    // MARK: Normal Types

    func deprecatedValue<K>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, DeprecatedPreferenceKey<K>>
    ) -> K where K: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        return (value(forKey: key.key) as? K) ?? key.defaultValue
    }

    // MARK: Raw Representable

    func deprecatedValue<K>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, DeprecatedPreferenceKey<K>>
    ) -> K where K: RawRepresentable, K.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? String else {
            return key.defaultValue
        }
        return K(rawValue: rawValue) ?? key.defaultValue
    }

    func deprecatedValue<K>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, DeprecatedPreferenceKey<K>>
    ) -> K where K: RawRepresentable, K.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? Int else {
            return key.defaultValue
        }
        return K(rawValue: rawValue) ?? key.defaultValue
    }
}

public extension UserDefaultsType {
    @available(*, deprecated, message: "This preference key is deprecated.")
    func value<K>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, DeprecatedPreferenceKey<K>>
    ) -> K where K: UserDefaultsStorable {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        return (value(forKey: key.key) as? K) ?? key.defaultValue
    }

    @available(*, deprecated, message: "This preference key is deprecated.")
    func value<K>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, DeprecatedPreferenceKey<K>>
    ) -> K where K: RawRepresentable, K.RawValue == String {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? String else {
            return key.defaultValue
        }
        return K(rawValue: rawValue) ?? key.defaultValue
    }

    @available(*, deprecated, message: "This preference key is deprecated.")
    func value<K>(
        for keyPath: KeyPath<UserDefaultPreferenceKeys, DeprecatedPreferenceKey<K>>
    ) -> K where K: RawRepresentable, K.RawValue == Int {
        let key = UserDefaultPreferenceKeys()[keyPath: keyPath]
        guard let rawValue = value(forKey: key.key) as? Int else {
            return key.defaultValue
        }
        return K(rawValue: rawValue) ?? key.defaultValue
    }
}

