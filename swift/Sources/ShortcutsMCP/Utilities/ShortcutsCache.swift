import Foundation

/// Thread-safe cache for shortcuts data with 24-hour expiration.
///
/// This actor provides caching for expensive operations like fetching
/// the shortcuts list from the system CLI.
actor ShortcutsCache {
    /// Cached shortcuts list entry
    private struct CacheEntry: Sendable {
        let shortcuts: [ShortcutInfo]
        let timestamp: Date
    }

    /// Information about a single shortcut
    struct ShortcutInfo: Sendable, Codable {
        let name: String
        let identifier: String
    }

    /// The cache timeout duration (24 hours)
    private static let cacheTimeout: TimeInterval = 24 * 60 * 60

    /// Shared instance for global access
    static let shared = ShortcutsCache()

    /// Cached shortcuts list
    private var cachedList: CacheEntry?

    /// Check if the cache is still valid
    private func isCacheValid() -> Bool {
        guard let entry = cachedList else { return false }
        return Date().timeIntervalSince(entry.timestamp) < Self.cacheTimeout
    }

    /// Get shortcuts from cache if valid, otherwise returns nil
    func getCachedShortcuts() -> [ShortcutInfo]? {
        guard isCacheValid() else { return nil }
        return cachedList?.shortcuts
    }

    /// Store shortcuts in cache
    func cacheShortcuts(_ shortcuts: [ShortcutInfo]) {
        cachedList = CacheEntry(shortcuts: shortcuts, timestamp: Date())
    }

    /// Invalidate the cache
    func invalidateCache() {
        cachedList = nil
    }

    /// Get the cache timestamp if available
    func cacheTimestamp() -> Date? {
        cachedList?.timestamp
    }
}
