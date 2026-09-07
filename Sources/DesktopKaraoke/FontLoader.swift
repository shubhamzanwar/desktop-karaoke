import CoreText
import Foundation

enum FontLoader {
    static func registerBundledFonts() {
        guard let url = Bundle.module.url(forResource: "Fredoka", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
