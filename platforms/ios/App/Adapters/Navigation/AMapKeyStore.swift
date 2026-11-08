import Foundation
import Security

/// The runtime key stays on this device. It is never written to preferences or logs.
@MainActor final class AMapKeyStore {
    private let ephemeral: Bool
    private var temporary: String?
    private let service = "ink.yhm.MotoNav.amap"
    init(ephemeral: Bool = false) { self.ephemeral = ephemeral }
    static func isValid(_ value: String) -> Bool {
        value.range(of: "^[A-Za-z0-9_-]{16,128}$",options: .regularExpression) != nil
    }
    func load() -> String? {
        if ephemeral { return temporary }
        var query = base
        query[kSecReturnData as String] = true; query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary,&result) == errSecSuccess,
              let data = result as? Data, let value = String(data: data,encoding: .utf8),Self.isValid(value) else { return nil }
        return value
    }
    func save(_ value: String) throws {
        guard Self.isValid(value) else { throw KeyError.invalid }
        if ephemeral { temporary = value; return }
        let attributes: [String: Any] = [kSecValueData as String: Data(value.utf8)]
        let result = SecItemUpdate(base as CFDictionary,attributes as CFDictionary)
        if result == errSecItemNotFound {
            var query = base; query[kSecValueData as String] = Data(value.utf8)
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(query as CFDictionary,nil) == errSecSuccess else { throw KeyError.storage }
        } else if result != errSecSuccess { throw KeyError.storage }
    }
    private var base: [String: Any] {
        [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:"ios-key"]
    }
    enum KeyError: LocalizedError {
        case invalid, storage
        var errorDescription: String? { self == .invalid ? "Key 格式不正确，请粘贴高德控制台中的 iOS Key" : "无法保存到本机钥匙串，请稍后重试" }
    }
}
