import Foundation

/// Resolves bundled resources across both run modes: the plain SPM executable (dev builds,
/// `swift run`) where `Bundle.module` finds the SPM resource bundle next to the binary, and a
/// packaged `.app` where that resource bundle can't live at the app root — codesign refuses to
/// seal an `.app` with anything unexpected there — so packaging copies resource files directly
/// into `Contents/Resources` instead, and this falls back to `Bundle.main` for them.
enum AppResources {
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        let resourceBundleName = "DesktopKaraoke_DesktopKaraoke.bundle"
        let resourceBundleURL = Bundle.main.bundleURL.appendingPathComponent(resourceBundleName)
        if FileManager.default.fileExists(atPath: resourceBundleURL.path),
           let bundle = Bundle(url: resourceBundleURL) {
            return bundle.url(forResource: name, withExtension: ext)
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }
}
