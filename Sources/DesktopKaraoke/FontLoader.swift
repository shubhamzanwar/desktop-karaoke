import CoreText
import Foundation

enum FontLoader {
    static func registerBundledFonts() {
        guard let url = AppResources.url(forResource: "Fredoka", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
